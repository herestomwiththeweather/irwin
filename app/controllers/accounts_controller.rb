class AccountsController < ApplicationController
  before_action :set_target_account, only: [:inbox]
  before_action :set_account, only: [:show, :edit, :update, :follow]
  skip_before_action :verify_authenticity_token, only: [:inbox]
  before_action :login_required, except: [:inbox]

  authorize_resource

  ACTIVITIES = ['Follow', 'Undo', 'Accept', 'Create', 'Announce', 'Move', 'Like']

  def followers
    @followers = current_user.account.account_followers.page(params[:page])
  end

  def following
    @follows = Follow.where(account: current_user.account).page(params[:page])
  end

  def index
    @accounts = Account.page(params[:page])
  end

  def show
    @new_status = Status.new
    @statuses = @account.statuses.page(params[:page])
  end

  def edit
  end

  def update
    respond_to do |format|
      if @account.update(account_params)
        format.html { redirect_to root_url, notice: "Account was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def follow
    respond_to do |format|
      if current_user.account.follow!(@account)
        format.html { redirect_to following_path, notice: "Followed #{@account.webfinger_to_s}" }
      else
        format.html { redirect_to following_path, notice: "Failed to follow #{@account.webfinger_to_s}" }
      end
    end
  end

  def inbox
    response_code = 200
    raise StandardError unless request.headers['Signature'].present?

    @body = request.body.string
    Rails.logger.info @body
    
    @json = JSON.parse(@body)

    Rails.logger.info "-> type: 😂#{@json['type']}😂, actor: #{@json['actor']}, from: #{request.remote_ip}"

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

  def capitalized(text)
    text.gsub(/(?:^|-)([a-z])/) { |m| m.upcase }
  end

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

    signed_headers_array = headers.split

    signed_components = signed_headers_array.map do |signed_header|
      if '(request-target)' == signed_header
        "(request-target): post #{request.path}"
      else
        "#{signed_header}: #{request.headers[capitalized(signed_header)]}"
      end
    end

    comparison_string = signed_components.join("\n")

    @current_mastodon_account.verify(signature, comparison_string)
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

  def log_item(item)
    if ACTIVITIES.include? item['type']
      info = case item['type']
      when 'Follow'
        "for #{item['object']}"
      when 'Create', 'Undo'
        "for type #{item['object']['type']}"
      else
        ""
      end
      Rails.logger.info "#{__method__} #{item['type']} #{info} from account id: #{@current_mastodon_account.id}"
    end
  end

  def process_item(item)
    log_item(item)

    response_code = case item['type']
    when 'Follow'
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
      Rails.logger.info "    actor: #{item['actor']}" # actor accepting the follow
      Rails.logger.info "    follower: #{item['object']['actor']}"
      follower = User.by_actor(item['object']['actor']).account
      follow = Follow.where(target_account: @current_mastodon_account, account: follower).first
      if follow.present?
        follow.accept!
      else
        Rails.logger.info "#{__method__} Error finding follow to accept for: #{item['actor']}"
      end
      200
    when 'Announce'
      status = @current_mastodon_account.create_boost!(item)
      202
    when 'Delete'
      202
    when 'Create'
      # since current account could be sending a received reply, we cannot assume current account created the status
      actor = @current_mastodon_account
      if item['actor'] != @current_mastodon_account.identifier
        Rails.logger.info "#{__method__} validating signature for: #{item['actor']}"
        account = Account.fetch_by_key(item['signature']['creator'])
        if account.nil?
          Rails.logger.info "#{self.class}##{__method__} Error No account for #{item['actor']}"
          return 400
        end

        return 400 unless account.verify_signature(item)
        actor = account

        Rails.logger.info "#{__method__} *** signature verification succeeded *** for actor: #{actor.id}"
      end

      status = actor.create_status!(item['object'])
      if !status
        Rails.logger.info "#{__method__} Error creating status id: #{item['object']['id']} from account id: #{actor.id}"
      elsif status.thread.present? && status.thread.account.local?
        if !status.private_mention?
          DistributeRawReplyJob.perform_later(JSON.dump(item), status.thread.account_id, actor.id)
        end
      end

      202
    when 'Undo'
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

  private

  def account_params
    params.require(:account).permit(:name, :summary, :url, :icon, :image)
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
