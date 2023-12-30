require 'net/https'

class User < ApplicationRecord
  has_secure_password
  has_many :authorization_codes
  has_many :access_tokens


  belongs_to :account

  validates :public_key, uniqueness: true

  validates :username, presence: true
  validates :domain, presence: true

  attr_accessor :auth_endpoint_host
  attr_accessor :token_endpoint_host
  attr_accessor :current_page

  before_validation :generate_keys, on: :create
  before_validation :discover_indieauth, on: :create
  before_validation :set_domain, on: :create
  before_validation :assign_account, on: :create

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

  def self.by_actor(target_uri)
    uri = URI.parse(target_uri)
    path = uri.request_uri
    identifier = path.gsub(/^\/actor\//,'')
    Rails.logger.info "by_actor target identifier: #{identifier}"
    username, domain = identifier.split('@')
    User.where(username: username, domain: domain).first
  end

  def set_domain
    self.domain = URI.parse(url).hostname
  end

  def assign_account
    self.account = Account.create!(preferred_username: nil) if account.nil?
  end

  def feed
    status_ids = Mention.where(account: self.account).map {|m| m.status.id}
    # anyone mentioned in a direct message may see it
    Status.where(direct_recipient: nil, account_id: self.account.active_relationships.select(:target_account_id)).or(Status.where(direct_recipient: nil, account_id: self.account.id)).or(Status.where(id: status_ids))
  end

  def post(receiver, body)
    body["@context"] = ["https://www.w3.org/ns/activitystreams"]

    if 'Create' == body['type'] && body['signature'].present?
      json_signature = account.sign_json(body)
      Rails.logger.info "#{__method__} user id: #{id} json_signature: #{json_signature}"
      body['signature']['signatureValue'] = json_signature
    end

    activity = Activity.new(receiver.inbox, body.to_json, actor_url, private_key)
    json_response = HttpClient.new(receiver.inbox, activity.request_headers, body.to_json).post
    if nil == json_response
      return false
    end
    if json_response['error'].present?
      Rails.logger.info "User#post error: #{json_status['error']}"
      return false
    end

    true
  end

  def matches_activity_target?(target_uri)
    # look up target by "object":"https://irwin.ngrok.io/actor/tom@backpawn.com"
    uri = URI.parse(target_uri)
    path = uri.request_uri
    identifier = path.gsub(/^\/actor\//,'')
    Rails.logger.info "target identifier: #{identifier}"
    username, domain = identifier.split('@')
    self.username == username && self.domain == domain
  end

  def actor_url
    "#{ENV['INDIEAUTH_HOST']}/actor/#{to_short_webfinger_s}"
  end

  def main_key_url
    "#{actor_url}#main-key"
  end

  def followers_url
    "#{actor_url}/followers"
  end

  def generate_keys
    return unless private_key.blank? && public_key.blank?

    keypair = OpenSSL::PKey::RSA.new(2048)
    self.private_key = keypair.to_pem
    self.public_key = keypair.public_key.to_pem
  end

  def to_webfinger_s
    "acct:#{to_short_webfinger_s}"
  end

  def to_short_webfinger_s
    "#{username}@#{domain}"
  end

  def discover_indieauth
    self.url = URI(url).normalize.to_s
    discovery_response = IndieWeb::Endpoints.get(url)
    self.auth_endpoint_host = URI(discovery_response[:authorization_endpoint]).host
    self.token_endpoint_host = URI(discovery_response[:token_endpoint]).host
  end
end
