class UsersController < ApplicationController
  before_action :set_user, only: [:actor, :followers, :following]

  def new
    if global_prefs.enable_registrations?
      @user = User.new
    else
      redirect_to login_url, notice: "Registrations are disabled."
    end
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to login_url, notice: "Registration success!"
    else
      render 'new'
    end
  rescue ActionController::ParameterMissing => e
    Rails.logger.info "#{self.class}##{__method__} ActionController::ParameterMissing exception: #{e.message}"
    redirect_to login_url
  end

  def actor
    respond_to do |format|
      format.html do
        if 'Bridgy Fed (https://fed.brid.gy/)' == request.user_agent
          render json: @target_user, serializer: UserSerializer, content_type: 'application/activity+json'
        else
          @account = @target_user.account
          if @account.url.present?
            redirect_to @account.url, allow_other_host: true
          else
            render 'accounts/show'
          end
        end
      end
      format.all do
        render json: @target_user, serializer: UserSerializer, content_type: 'application/activity+json'
      end
    end
  end

  def followers
    @target_user.current_page = params[:page]

    respond_to do |format|
      format.html do
      end
      format.all do
        render json: @target_user, serializer: ListSerializer, content_type: 'application/activity+json'
      end
    end
  end

  def following
    @target_user.current_page = params[:page]

    respond_to do |format|
      format.html do
      end
      format.all do
        render json: @target_user, serializer: ListSerializer, content_type: 'application/activity+json'
      end
    end
  end

  def activity
    raise StandardError
  end

  def webfinger
    match = request.query_string.match(/resource=([^&]*)/)
    raw_resource = match ? match[1] : ""
    # python testing framework does not encode forward slashes
    if params[:resource].present? && (params[:resource] =~ /\A[a-zA-Z]*:\/?\/?[a-zA-Z0-9._%+-]+@?[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/)
      raise StandardError if !(params[:resource] =~ /^acct:/)
      identifier = params[:resource].sub('acct:','')
      username, domain = identifier.split('@')
      # domain will be this server
      @target_user = User.find_by!(username: username)
      render json: @target_user, serializer: WebfingerSerializer, content_type: 'application/jrd+json'
    else
      Rails.logger.info "#{__method__} error raw resource: #{raw_resource}"
      render plain: '', status: 400
    end
  rescue => e
    Rails.logger.info "#{__method__} error: #{e.class} : #{e.message}"
    render json: {}, status: 404
  end

  private

  def set_user
    identifier = params[:id].gsub(/^@/,'')
    username, domain = identifier.split('@')
    @target_user = User.find_by(username: username, domain: domain)
    raise ActiveRecord::RecordNotFound if @target_user.nil?
  end

  def user_params
    params.require(:user).permit(:email, :url, :password, :password_confirmation, :username, :language)
  end
end
