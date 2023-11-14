class Account < ApplicationRecord
  has_many :active_relationships, class_name: 'Follow', foreign_key: 'account_id', dependent: :destroy
  has_many :account_following, -> { order('follows.id desc') }, through: :active_relationships, source: :target_account

  has_many :passive_relationships, class_name: 'Follow', foreign_key: 'target_account_id', dependent: :destroy
  has_many :account_followers, -> { order('follows.id desc') }, through: :passive_relationships, source: :account

  has_many :statuses, dependent: :destroy

  has_one :user

  belongs_to :moved_to_account, class_name: 'Account', optional: true
=begin
  validates :identifier, uniqueness: true
  validates :following, uniqueness: true
  validates :followers, uniqueness: true
  validates :inbox, uniqueness: true
  validates :outbox, uniqueness: true
  validates :url, uniqueness: true
=end

  def self.fetch_by_key(key_url)
    account = nil
    Rails.logger.info "Account#fetch_by_key request url: #{key_url}"
    uri = URI.parse(key_url)
    mastodon_identifier = key_url.sub(uri.fragment,'').chomp('#')
    account = Account.fetch_and_create_mastodon_account(mastodon_identifier)

    account
  end

  def self.fetch_and_create_mastodon_account(actor_url)
    account = find_by(identifier: actor_url)
    return account if account.present?

    actor = fetch_mastodon_account(actor_url)

    Account.create_mastodon_account(actor)
  end

  def self.fetch_and_create_mastodon_account_by_address(address)
    preferred_username, domain = address.split('@')
    account = Account.find_by(preferred_username: preferred_username, domain: domain)
    return account if account.present?

    result = WebFinger.discover! "acct:#{address}"
    actor_url = result['links'].select {|link| link['rel'] == 'self'}.first['href']

    actor = fetch_mastodon_account(actor_url)

    Account.create_mastodon_account(actor)
  end

  def self.fetch_and_create_or_update_mastodon_account(actor_url)
    account = find_by(identifier: actor_url)

    actor = fetch_mastodon_account(actor_url)

    if account.present?
      account.update_mastodon_account(actor)
      account.save!
    else
      account = Account.create_mastodon_account(actor)
    end

    account
  end

  def self.fetch_mastodon_account(actor_url)
    headers = {'Accept': 'application/json'}
    actor = HttpClient.new(actor_url, headers).get
    if nil == actor
      Rails.logger.info "#{__method__} error fetching actor"
      return nil
    end

    if actor['error'].present?
      Rails.logger.info "#{__method__} error: #{actor['error']}"
      return nil
    end

    log_json(actor)
    actor
  end

  def self.log_json(actor)
    Rails.logger.info "mastodon_identifier: #{actor['id']}"
    Rails.logger.info "also_known_as: #{actor['alsoKnownAs']}"
    Rails.logger.info "following: #{actor['following']}"
    Rails.logger.info "followers: #{actor['followers']}"
    Rails.logger.info "inbox: #{actor['inbox']}"
    Rails.logger.info "outbox: #{actor['outbox']}"
    Rails.logger.info "preferred_username: #{actor['preferredUsername']}"
    Rails.logger.info "name: #{actor['name']}"
    Rails.logger.info "summary: #{actor['summary']}"
    Rails.logger.info "mastodon_url: #{actor['url']}"
    Rails.logger.info "icon_url: #{actor['icon']['url']}" if actor['icon'].present?
    Rails.logger.info "public_key: #{actor['publicKey']['publicKeyPem']}"
  end

  def self.create_mastodon_account(actor)
    account = Account.new
    account.update_mastodon_account(actor)
    account.save!
    account
  end

  def update_mastodon_account(actor)
    self.public_key = actor['publicKey']['publicKeyPem']
    self.identifier = actor['id']
    self.domain = URI.parse(identifier).hostname
    self.preferred_username = actor['preferredUsername']
    self.name = actor['name']
    self.also_known_as = actor['alsoKnownAs']

    self.following = actor['following']
    self.followers = actor['followers']
    self.inbox = actor['inbox']
    self.outbox = actor['outbox']
    self.url = actor['url']
    self.icon = actor['icon']['url'] if actor['icon'].present?

    self.summary = actor['summary']
  end

  def also_known_as
    self[:also_known_as] || []
  end

  def icon_url_or_default
    icon.present? ? icon : 'indieweb_400x400.jpg'
  end

  def follows?(account)
    account_following.include?(account)
  end

  def mastodon?
    user.nil?
  end

  def local?
    user.present?
  end

  def webfinger_to_s
    "#{username}@#{domain}"
  end

  def username
    local? ? user.username : preferred_username
  end

  def follow!(target_account, object_uri = '')
    Follow.add(self, target_account, object_uri)
  end

  def create_status!(status_object)
    Rails.logger.info "#{__method__} id: #{status_object['id']}"
    mentions = []
    language = status_object['contentMap']&.keys&.first
    thread = nil
    if status_object['inReplyTo'].present?
      thread = Status.find_by(uri: status_object['inReplyTo'])
    end

    if status_object['tag'].present?
      status_object['tag'].each do |tag|
        if 'Mention' == tag['type']
          Rails.logger.info "XXX mention: looking up #{tag['name']} : #{tag['href']}"
          account = Account.fetch_and_create_mastodon_account(tag['href'])
          if account.present?
            mentions << Mention.new(account: account, silent: false)
          end
        end
      end
    end

    # if inReplyTo is present but there is no status with a matching uri, then we can use in_reply_to_uri to assign thread later

    status = self.statuses.create!( created_at: status_object['published']&.to_datetime,
                                    language: language,
                                    thread: thread,
                                    in_reply_to_uri: status_object['inReplyTo'],
                                    text: status_object['content'],
                                    uri: status_object['id'],
                                    url: status_object['url']
    )

    mentions.each do |m|
      m.status = status
      m.save
    end

    if status_object['inReplyTo'].present?
      if nil == thread
        FetchThreadJob.perform_later(status.id)
      else
        Rails.logger.info "#{__method__} thread #{thread.id} already exists locally"
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.info "#{self.class}##{__method__} exception: #{e.message}"
    nil
  end

  def create_boost!(item)
    original_status = Status.from_object_uri(item['object'])
    # boost not expected to have a url
    status = self.statuses.create!( created_at: item['published']&.to_datetime,
                                    reblog: original_status,
                                    uri: item['id']
    )
  end

  def matches_activity_actor?(actor_identifier)
    self.identifier == actor_identifier
  end

end
