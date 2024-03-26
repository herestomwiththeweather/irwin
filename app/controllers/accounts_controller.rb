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
    @accounts = Account.order('created_at DESC').page(params[:page])
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

    signed_components = headers.split.map do |signed_header|
      header_value = '(request-target)' == signed_header ? "post #{request.path}" : request.headers[capitalized(signed_header)]
      "#{signed_header}: #{header_value}"
    end

    comparison_string = signed_components.join("\n")

    @current_mastodon_account.verify(signature, comparison_string)
  end

  def process_items(items)
    items.reverse_each.filter_map { |item| process_item(item) }
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

    activity = ActivityPub::Activity.factory(item, @current_mastodon_account, @target_account)
    response_code = case item['type']
    when 'Follow', 'Like', 'Move', 'Accept', 'Announce', 'Create', 'Undo'
      activity&.perform
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
    if params[:username_with_domain].present?
      username, domain = params[:username_with_domain].split('@')
      @account = Account.find_by(preferred_username: username, domain: domain)
    else
      @account = Account.find(params[:id])
    end
  end
end
