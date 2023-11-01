class UsersController < ApplicationController
  before_action :set_user, only: [:actor]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to root_url, notice: "Registration success!"
    else
      render 'new'
    end
  end

  def actor
    respond_to do |format|
      format.html do
        @account = @target_user.account
        render 'accounts/show'
      end
      format.all do
        render json: @target_user, serializer: UserSerializer, content_type: 'application/activity+json'
      end
    end
  end

  def activity
    raise StandardError
  end

  def webfinger
    Rails.logger.info "webfinger: #{params[:resource]}"
    identifier = params[:resource].sub('acct:','')
    username, domain = identifier.split('@')
    # domain will be this server
    @target_user = User.find_by(username: username)
    Rails.logger.info "user id: #{@target_user.id}"
    render json: @target_user, serializer: WebfingerSerializer, content_type: 'application/jrd+json'
  rescue => e
    Rails.logger.info "#{__method__} error: #{e.class} : #{e.message}"
    render json: {}, status: 404
  end

  private

  def set_user
    identifier = params[:id].gsub(/^@/,'')
    username, domain = identifier.split('@')
    @target_user = User.where(username: username, domain: domain).first
    raise ActiveRecord::RecordNotFound if @target_user.nil?
  end

  def user_params
    params.require(:user).permit(:email, :url, :password, :password_confirmation, :username)
  end
end
