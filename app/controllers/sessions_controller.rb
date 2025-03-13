class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by_email(params[:email])
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      if user.account.blank?
        session[:return_to] = authorizations_url
      end
      redirect_back_or_default root_url
    else
      redirect_to login_url, notice: "Login failed."
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url, notice: 'Logged out!'
  end

  def home
  end
end
