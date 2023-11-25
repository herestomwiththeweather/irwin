class AccountsController < ApplicationController
  before_action :set_target_account, only: [:inbox]
  before_action :set_account, only: [:show, :follow]
  skip_before_action :verify_authenticity_token, only: [:inbox]
  before_action :login_required, except: [:inbox]

  def followers
    @followers = current_user.account.account_followers
  end

  def api_followers
    render plain: '', status: 404
  end

  def following
    @follows = Follow.where(account: current_user.account)
  end

  def index
    @accounts = Account.all
  end

  def show
    @new_status = Status.new
  end

  def follow
    current_user.account.follow!(@account)
    respond_to do |format|
      format.html { redirect_to followers_path, notice: "Followed #{@account.webfinger_to_s}" }
    end
  end

  def inbox
    response_code = 200
    raise StandardError unless request.headers['Signature'].present?

    @body = request.body.string
    Rails.logger.info @body
    
    @json = JSON.parse(@body)

    Rails.logger.info "-> type: #{@json['type']}, actor: #{@json['actor']}, from: #{request.remote_ip}"

    case @json['type']
    when 'Collection', 'CollectionPage'
      #process_items @json['items']
    when 'OrderedCollection', 'OrderedCollectionPage'
      #process_items @json['orderedItems']
    when 'Follow', 'Undo', 'Accept', 'Create', 'Announce', 'Move', 'Like'
      if process_header
        Rails.logger.info "inbox: current mastodon account id: #{@current_mastodon_account.id}"
        response_code = process_item(@json)
      else
        Rails.logger.info "*** inbox: Error: signature validation failed. ***"
        response_code = 400
      end
    when 'Delete'
    else
      Rails.logger.info "no match: #{@json['type']}"
      #process_items [@json]
    end
    render plain: '', status: response_code
  end

  private

  def process_header
    Rails.logger.info "--- process_header ---"
    @current_mastodon_account = nil
    signature_header = request.headers['Signature'].split(',').map do |pair|
      pair.split('=', 2).map do |value|
        value.gsub(/\A"/, '').gsub(/"\z/, '') # "foo" -> foo
      end
    end.to_h

    key_id    = signature_header['keyId']
    headers   = signature_header['headers']
    signature = Base64.decode64(signature_header['signature'])

    Rails.logger.info "key_id: #{key_id}"
    Rails.logger.info "headers: #{headers}"
    Rails.logger.info "signature (base64 encoded): #{signature_header['signature']}"

    @current_mastodon_account = Account.fetch_by_key(key_id)

    return false if @current_mastodon_account.nil?

    comparison_string = "(request-target): post #{request.path}\nhost: #{request.headers['Host']}\ndate: #{request.headers['Date']}\ndigest: #{request.headers['Digest']}"
    if request.headers['Content-Type'].present? && headers.split.include?('content-type')
      Rails.logger.info "XXX including content type: #{request.headers['Content-Type']}"
      comparison_string << "\ncontent-type: #{request.headers['Content-Type']}"
    end

    key = OpenSSL::PKey::RSA.new(@current_mastodon_account.public_key)
    key.verify(OpenSSL::Digest::SHA256.new, signature, comparison_string)
  end

  def process_items(items)
    items.reverse_each.filter_map { |item| process_item(item) }
  end

  def validate_follow_params(item)
    # sanity check that target actor url specified in item['object'] matches actor in the endpoint request url 
    if !@target_user.matches_activity_target?(item['object'])
      Rails.logger.info "Error: incoming target object #{item['object']} does not match expected target user id #{@target_user.id}"
      raise StandardError
    end
    # sanity check that source actor url specified in item['actor'] matches actor making the request 
    if !@current_mastodon_account.matches_activity_actor?(item['actor'])
      raise StandardError
    end
  end

  def process_item(item)
    response_code = case item['type']
    when 'Follow'
      Rails.logger.info "process_item received a follow for #{item['object']} from account id: #{@current_mastodon_account.id}"
      validate_follow_params(item)
      follow = @current_mastodon_account.follow!(@target_account, item['id'])
      AcceptFollowJob.perform_later(follow.id)
      follow.nil? ? 500 : 202
    when 'Like'
      like = @current_mastodon_account.like!(item['object'])
      like.nil? ? 500 : 202
    when 'Move'
      return 401 unless @current_mastodon_account.matches_activity_actor?(item['object'])

      target = Account.fetch_and_create_or_update_mastodon_account(item['target'])
      return 500 if target.nil?

      @current_mastodon_account.moved_to_account = target
      @current_mastodon_account.save!

      return 403 if !target.also_known_as.include?(@current_mastodon_account.identifier)

      #
      # unfollow origin account
      #
      old_follow = Follow.find_by(target_account: @current_mastodon_account, account: @target_account)
      return 401 unless old_follow.present?

      old_follow.destroy!

      # follow target
      new_follow = @target_account.follow!(target, item['id'])

      202
    when 'Accept'
      Rails.logger.info "process_item received an accept"
      Rails.logger.info "    actor: #{item['actor']}" # actor accepting the follow
      Rails.logger.info "    follower: #{item['object']['actor']}"
      follower = User.by_actor(item['object']['actor']).account
      follow = Follow.where(target_account: @current_mastodon_account, account: follower).first
      follow.accept!
      200
    when 'Announce'
      status = @current_mastodon_account.create_boost!(item)
      202
    when 'Delete'
      202
    when 'Create'
      Rails.logger.info "process_item received a Create for type #{item['object']['type']} from account id: #{@current_mastodon_account.id}"
      status = @current_mastodon_account.create_status!(item['object'])
      # XXX if this status is a reply to a local account, broadcast it to local account's followers
      202
    when 'Undo'
      Rails.logger.info "process_item received an Undo for type #{item['object']['type']} from account id: #{@current_mastodon_account.id}"
      if 'Follow' == item['object']['type']
        target_account = User.by_actor(item['object']['object']).account
        Rails.logger.info "undo follow [#{@current_mastodon_account.id}, #{target_account.id}, #{item['object']['id']}]"
        follow = Follow.where(target_account: target_account, account: @current_mastodon_account).first
        if follow.present?
          Rails.logger.info "Deleting follow #{follow.id} [#{follow.account_id}, #{follow.target_account_id}, #{follow.created_at}, #{follow.uri}]"
          follow.destroy!
        else
          Rails.logger.info "Error. Undo: follow lookup failed."
        end
      elsif 'Like' == item['object']['type']
        Rails.logger.info "undo like [#{@current_mastodon_account.id}, #{item['object']['object']}]"
        status = Status.from_local_uri(item['object']['object'])
        like = Like.find_by(status: status, account: @current_mastodon_account)
        like.destroy!
      else
        Rails.logger.info "Error. Unsupported type for undo: #{item['object']['type']}"
      end
      202
    else
      Rails.logger.info "process_item does not support item type: #{item['type']}"
      404
    end
  end

  def set_target_account
    identifier = params[:id].gsub(/^@/,'')
    username, domain = identifier.split('@')
    @target_user = User.where(username: username, domain: domain).first
    @target_account = @target_user.account
    raise ActiveRecord::RecordNotFound if @target_user.nil?
  end

  def set_account
    @account = Account.find(params[:id])
  end
end
