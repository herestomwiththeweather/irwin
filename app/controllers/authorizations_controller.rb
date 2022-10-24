class AuthorizationsController < ApplicationController
  before_action :login_required
  before_action :validate_oauth_parameters, only: :new

  def new
    store_oauth_params

    @client = ClientApp::fetch(params[:client_id])

  rescue => e
    Rails.logger.info "authorizations#new Error: #{e.message}"
  end

  def create
    client_app = ClientApp.where(url: session[:client_id]).first
    code = current_user.authorization_codes.create!(client_app: client_app, pkce_challenge: session[:code_challenge], client_id: session[:client_id], redirect_uri: session[:redirect_uri], scope: session[:scope])
    oauth_params = {code: code.token, state: session[:state]}
    clear_oauth_params
    redirect_to "#{code.redirect_uri}?#{oauth_params.to_query}", allow_other_host: true
  end

  private

  def parameter_missing?
    params[:client_id].blank? || params[:redirect_uri].blank? || params[:scope].blank? || params[:state].blank?
  end

  def invalid_redirect_uri_host?
    URI(params[:client_id]).host != URI(params[:redirect_uri]).host
  end

  def validate_oauth_parameters
    unless params[:me].blank?
      if current_user.url != URI(params[:me]).normalize.to_s
        redirect_to root_url, notice: "Requested url #{params[:me]} does not match logged in user #{current_user.url}"
      end
    end

    if parameter_missing?
      redirect_to root_url, notice: "Missing required parameter"
    end

    if invalid_redirect_uri_host?
      redirect_to root_url, notice: "Invalid redirect_uri parameter"
    end
  end

  def store_oauth_params
    session[:client_id] = params[:client_id]
    session[:redirect_uri] = params[:redirect_uri]
    session[:scope] = params[:scope]
    session[:state] = params[:state]
    session[:code_challenge] = params[:code_challenge]
  end

  def clear_oauth_params
    session[:state] = nil
    session[:redirect_uri] = nil
    session[:scope] = nil
    session[:client_id] = nil
    session[:code_challenge] = nil
  end
end
