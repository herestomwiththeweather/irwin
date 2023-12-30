class ApplicationController < ActionController::Base

  private

  def require_oauth_user_token
    authorization_header = request.headers['Authorization']
    Rails.logger.info "authorization header: #{authorization_header}"
    request_token = authorization_header.gsub(/^Bearer /,'')
    @current_token = AccessToken.where(token: request_token).first
    raise StandardError unless @current_token
    @current_user = @current_token.user
  end

  def login_required
    unless current_user
      store_location
      redirect_to login_url, notice: "Please sign in"
    end
  end

  def current_token
    @current_token
  end

  def current_user
    @current_user ||= (User.find(session[:user_id]) if session[:user_id])
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def global_prefs
    @global_prefs ||= Preference.first
  end

  helper_method :current_user
end
