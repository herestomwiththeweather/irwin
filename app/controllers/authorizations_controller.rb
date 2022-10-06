class AuthorizationsController < ApplicationController
  before_action :login_required

  def new
    unless params[:me].blank?
      if current_user.url != URI(params[:me]).normalize.to_s
        redirect_to root_url, notice: "Requested url #{params[:me]} does not match logged in user #{current_user.url}"
      end
    end

    @app_name = params[:client_id]
    @logo_url = ''
    store_oauth_params

    doc = Microformats.parse params[:client_id]
    h_app = doc['items'].select {|i| i['type'].include?('h-app')}
    @app_name = h_app.first['properties']['name'].first
    @logo_url = h_app.first['properties']['logo'].first
    Rails.logger.info "app name: #{@app_name}"
    Rails.logger.info "app logo url: #{@logo_url}"
  rescue => e
    Rails.logger.info "authorizations#new Error: #{e.message}"
  end

  def create
    code = current_user.authorization_codes.create!(client_id: session[:client_id], redirect_uri: session[:redirect_uri], scope: session[:scope])
    oauth_params = {code: code.token, state: session[:state]}
    clear_oauth_params
    redirect_to "#{code.redirect_uri}?#{oauth_params.to_query}", allow_other_host: true
  end

  private

  def store_oauth_params
    session[:client_id] = params[:client_id]
    session[:redirect_uri] = params[:redirect_uri]
    session[:scope] = params[:scope]
    session[:state] = params[:state]
  end

  def clear_oauth_params
    session[:state] = nil
    session[:redirect_uri] = nil
    session[:scope] = nil
    session[:client_id] = nil
  end
end
