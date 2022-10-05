class User < ApplicationRecord
  has_secure_password
  has_many :authorization_codes
  has_many :access_tokens

  attr_accessor :auth_endpoint_host
  attr_accessor :token_endpoint_host

  before_validation :discover_indieauth

  # INDIEAUTH_HOST env var
  # e.g. https://heydude.example.com
  VALID_AUTH_HOSTS = [
    URI(ENV['INDIEAUTH_HOST']).host
  ].freeze

  VALID_TOKEN_HOSTS = [
    URI(ENV['INDIEAUTH_HOST']).host
  ].freeze

  validates :auth_endpoint_host, inclusion: { in: VALID_AUTH_HOSTS, message: "%{value} does not match the domain of this server." }
  validates :token_endpoint_host, inclusion: { in: VALID_TOKEN_HOSTS, message: "%{value} does not match the domain of this server." }

  def discover_indieauth
    self.url = URI(url).normalize.to_s
    discovery_response = IndieWeb::Endpoints.get(url)
    self.auth_endpoint_host = URI(discovery_response[:authorization_endpoint]).host
    self.token_endpoint_host = URI(discovery_response[:token_endpoint]).host
  end
end
