class ApplicationController < ActionController::Base

  private

  def login_required
    unless current_user
      store_location
      redirect_to login_url, notice: "Please sign in"
    end
  end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  helper_method :current_user
end
