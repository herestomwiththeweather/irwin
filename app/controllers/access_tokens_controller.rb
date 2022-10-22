class AccessTokensController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :require_oauth_user_token, except: [:create, :index]
  before_action :login_required, only: [:index]

  def validate
    Rails.logger.info "Verifying token for #{current_user.url}"
    oauth_params = {me: current_user.url, scope: current_token.authorization_code.scope, client_id: current_token.authorization_code.client_id}
    respond_to do |format|
      format.json { render json: oauth_params.to_query, status: :ok }
    end
  end

  def create
    http_status, message, access_token, expires_in, me, scope = AuthorizationCode.verify(params)

    respond_to do |format|
      if :ok == http_status
        format.json { render json: { access_token: access_token, expires_in: expires_in, me: me, scope: scope, token_type: 'Bearer'}, status: http_status }
      else
        format.json { render json: {error: message}, status: http_status}
      end
    end
  end

  def index
    @access_tokens = current_user.access_tokens.order('created_at DESC')
  end
end
