require 'net/https'

class User < ApplicationRecord
  has_secure_password
  has_many :authorization_codes
  has_many :access_tokens
  has_many :notifications
  has_many :like_notifications
  has_many :mention_notifications
  has_many :follow_notifications
  has_many :reject_notifications

  belongs_to :account, optional: true

  validates :public_key, uniqueness: true

  validates :domain, presence: true
  validates :url, presence: true, uniqueness: true

  attr_accessor :auth_endpoint_host
  attr_accessor :token_endpoint_host
  attr_accessor :current_page

  before_validation :generate_keys, on: :create
  before_validation :discover_indieauth
  before_validation :set_domain, on: :create

  validate :unique_preferred_username

  VALID_AUTH_HOSTS = [
    ENV['SERVER_NAME']
  ].freeze

  VALID_TOKEN_HOSTS = [
    ENV['SERVER_NAME']
  ].freeze

  validates :auth_endpoint_host, inclusion: { in: VALID_AUTH_HOSTS, message: "%{value} does not match the domain of this server." }
  validates :token_endpoint_host, inclusion: { in: VALID_TOKEN_HOSTS, message: "%{value} does not match the domain of this server." }

  def self.ransackable_attributes(auth_object = nil)
    ["email"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.by_actor(target_uri)
    uri = URI.parse(target_uri)
    path = uri.request_uri
    identifier = path.gsub(/^\/actor\//,'')
    Rails.logger.info "by_actor target identifier: #{identifier}"
    username, domain = identifier.split('@')
    by_username(username)
  end

  def self.by_username(username)
    User.includes(:account).where(accounts: { preferred_username: username }).first
  end

  def self.representative
    Preference.first.user || User.first
  end

  def unique_preferred_username
    if account.present?
      candidate_username = account.preferred_username
      users = User.includes(:account).where(accounts: { preferred_username: candidate_username }).where.not(id: id)
      if users.length > 0
        errors.add(:account, "another user has an account with that preferred_username")
      end
    end
  end

  def set_domain
    self.domain = URI.parse(url).hostname
  end

  def feed
    status_ids = Mention.where(account: self.account).map {|m| m.status.id}
    # anyone mentioned in a direct message may see it
    Status.kept.where(direct_recipient: nil, account_id: self.account.active_relationships.select(:target_account_id)).or(Status.where(direct_recipient: nil, account_id: self.account.id)).or(Status.where(id: status_ids))
  end

  def get(url)
    HttpClient.new(url, main_key_url, private_key).get
  end

  def post(receiver, body)
    if receiver.local?
      Rails.logger.info "#{self.class}##{__method__} receiver is local: [#{receiver.id}] #{receiver.webfinger_to_s}"
      return true
    end

    body["@context"] = ["https://www.w3.org/ns/activitystreams"]

    if 'Create' == body['type'] && body['signature'].present?
      json_signature = account.sign_json(body)
      Rails.logger.info "#{__method__} user id: #{id} json_signature: #{json_signature}"
      body['signature']['signatureValue'] = json_signature
    end

    json_response = HttpClient.new(receiver.inbox, main_key_url, private_key, body.to_json).post
    if nil == json_response
      return false
    end
    if json_response['error'].present?
      Rails.logger.info "User#post error: #{json_response['error']}"
      return false
    end

    true
  end

  def actor_url
    "https://#{ENV['SERVER_NAME']}/actor/#{to_short_webfinger_s}"
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
    account&.webfinger_to_s
  end

  def discover_indieauth
    self.url = URI(url).normalize.to_s
    discovery_response = IndieWeb::Endpoints.get(url)
    if nil != discovery_response[:authorization_endpoint]
      self.auth_endpoint_host = URI(discovery_response[:authorization_endpoint]).host
    end
    if nil != discovery_response[:token_endpoint]
      self.token_endpoint_host = URI(discovery_response[:token_endpoint]).host
    end
  rescue IndieWeb::Endpoints::HttpError => e
    Rails.logger.info "#{self.class}##{__method__} IndieWeb::Endpoints::HttpError exception: #{e.message}"
    errors.add(:url, "Error: #{e.message}")
    throw :abort
  end
end
