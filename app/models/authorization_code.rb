class AuthorizationCode < ApplicationRecord
  belongs_to :user
  has_secure_token
  has_many :access_tokens

  before_validation :setup, on: :create

  validates :redirect_uri, presence: true
  validates :expires_at, presence: true
  validates :scope, presence: true
  validates :client_id, presence: true

  def self.verify(params)
    http_status = :bad_request
    message = ''
    authorization_code = nil
    access_token = nil

    begin
      message = 'unsupported_grant_type'
      break if params[:grant_type].present? && 'authorization_code' != params[:grant_type]
      message = 'invalid_request'
      break unless params[:code].present?
      break unless params[:client_id].present?
      break unless params[:redirect_uri].present?
      message = 'invalid_grant'
      authorization_code = self.where(token: params[:code]).first
      break unless authorization_code.present?
      break if authorization_code.expired?
      break unless authorization_code.redirect_uri == params[:redirect_uri]
      break unless authorization_code.client_id == params[:client_id]
      break unless authorization_code.pkce_valid?(params[:code_verifier])
      access_token = authorization_code.user.access_tokens.create(authorization_code: authorization_code) 
      http_status = :ok if access_token.valid?
    end until true

    if :ok == http_status
      [:ok, '', access_token.token, access_token.expires_in, authorization_code.user.url, authorization_code.scope]
    else
      [http_status, message, nil, nil, nil, nil]
    end
  end

  def setup
    self.expires_at ||= 1.minute.from_now
  end

  def expired?
    expires_at < Time.now.utc
  end

  def computed_pkce_challenge(code_verifier)
    hash = Digest::SHA256.digest(code_verifier)
    Base64.urlsafe_encode64(hash).tr('=', '')
  end

  def pkce_valid?(code_verifier)
    if code_verifier.present?
      Rails.logger.info "AuthorizationCode#pkce_valid? code_verifier: #{code_verifier}"
      pkce_challenge == computed_pkce_challenge(code_verifier)
    else
      true
    end
  end
end
