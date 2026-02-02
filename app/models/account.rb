class Account < ApplicationRecord
  include ERB::Util

  has_many :active_relationships, class_name: 'Follow', foreign_key: 'account_id', dependent: :destroy
  has_many :account_following, -> { order('follows.id desc') }, through: :active_relationships, source: :target_account

  has_many :passive_relationships, class_name: 'Follow', foreign_key: 'target_account_id', dependent: :destroy
  has_many :account_followers, -> { order('follows.id desc') }, through: :passive_relationships, source: :account

  has_many :statuses, -> { kept }, dependent: :destroy
  has_many :likes
  has_many :mentions

  has_one :user

  belongs_to :moved_to_account, class_name: 'Account', optional: true

  has_paper_trail on: [:update]
=begin
  validates :following, uniqueness: true
  validates :followers, uniqueness: true
  validates :inbox, uniqueness: true
  validates :outbox, uniqueness: true
=end
  before_validation :check_configuration, on: :create

  validates :identifier, uniqueness: true
  validates :url, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    ["name", "preferred_username", "domain"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  CONTEXT = 'https://w3id.org/identity/v1'

  def self.fetch_by_key(key_url)
    account = nil
    Rails.logger.info "Account#fetch_by_key request url: #{key_url}"
    uri = URI.parse(key_url)
    mastodon_identifier = uri.fragment.nil? ? key_url : key_url.sub(uri.fragment,'').chomp('#')
    account = Account.fetch_and_create_mastodon_account(mastodon_identifier)

    account
  end

  def self.fetch_and_create_mastodon_account(actor_url)
    if actor_url.blank?
      Rails.logger.info "#{__method__} Error. actor_url is nil"
      return nil
    end

    account = find_by(identifier: actor_url)
    return account if account.present?

    Rails.logger.info "#{__method__} fetching account: #{actor_url}"

    actor = strict_fetch_actor(actor_url)
    if nil == actor
      Rails.logger.info "#{__method__} error fetching actor #{actor_url}"
      return nil
    end

    # make a webfinger request to the activitypub server in case custom domain
    ap_server_domain = URI.parse(actor_url).hostname

    if actor['preferredUsername'].present?
      webfinger_address = "#{actor['preferredUsername']}@#{ap_server_domain}"
      begin
        result = WebFinger.discover! "acct:#{webfinger_address}"
      rescue WebFinger::NotFound => e
        Rails.logger.info "#{__method__} WebFinger unexpectedly not found for #{webfinger_address}: #{e.message}"
        return nil
      rescue WebFinger::BadRequest => e
        Rails.logger.info "#{__method__} Error: Bad request for webfinger: #{webfinger_address}: #{e.message}"
        return nil
      rescue NoMethodError => e
        Rails.logger.info "#{__method__} Error: Bad webfinger response: #{webfinger_address}: #{e.message}"
        return nil
      end
    else
      Rails.logger.info "#{__method__} Error: preferredUsername missing for actor url: #{actor_url}"
      return nil
    end

    webfinger_address_from_ap_server = result['subject']

    preferred_username, domain = webfinger_address_from_ap_server.split('@')

    if 0 != domain.casecmp(ap_server_domain)
      Rails.logger.info "#{__method__} verifying webfinger as #{domain} does not match #{ap_server_domain}"
      Rails.logger.info "#{__method__} sending webfinger request to #{webfinger_address_from_ap_server}"

      # check that custom domain agrees with activitypub server
      # but only log if there is a discrepancy
      begin
        result2 = WebFinger.discover! webfinger_address_from_ap_server
      rescue WebFinger::NotFound => e
        Rails.logger.info "#{__method__} WebFinger not found for #{webfinger_address_from_ap_server}: #{e.message}"
      rescue WebFinger::BadRequest => e
        # see https://github.com/swicg/activitypub-webfinger/issues/28
        Rails.logger.info "#{__method__} WebFinger verification failed. Server may only have host-meta: #{webfinger_address_from_ap_server}: #{e.message}"
      rescue WebFinger::Exception => e
        # e.g. "Failed to open TCP connection"
        Rails.logger.info "#{__method__} WebFinger exception for #{webfinger_address_from_ap_server}: #{e.message}"
      else
        authoritative_webfinger_subject = result2['subject']
        actor_url2 = result['links'].select {|link| link['rel'] == 'self'}.first['href']

        if 0 != authoritative_webfinger_subject.casecmp(webfinger_address_from_ap_server)
          Rails.logger.info "#{__method__} Error: subject #{authoritative_webfinger_subject} did not match #{webfinger_address_from_ap_server}"
        elsif actor_url2 != actor_url
          Rails.logger.info "#{__method__} Error: actor url #{actor_url2} did not match #{actor_url}"
        else
          Rails.logger.info "#{__method__} Verified custom domain for #{authoritative_webfinger_subject}"
          actor['domain'] = domain
        end
      ensure
        Rails.logger.info "#{__method__} finished webfinger verification"
      end
    end

    Account.create_mastodon_account(actor)
  end

  def self.fetch_and_create_mastodon_account_by_address(address)
    address&.strip!
    preferred_username, domain = address.split('@')
    account = Account.find_by(preferred_username: preferred_username, domain: domain)
    return account if account.present?

    full_address = "acct:#{address}"
    result = WebFinger.discover! full_address
    webfinger_subject = result['subject']
    if 0 != webfinger_subject.casecmp(full_address)
      # webfinger spec allows subject to be different
      Rails.logger.info "#{__method__} subject #{webfinger_subject} did not match forward #{full_address}"
    end

    actor_url = result['links'].select {|link| link['rel'] == 'self'}.first['href']

    actor = strict_fetch_actor(actor_url)
    if nil == actor
      Rails.logger.info "#{self.class}##{__method__} Error: Actor url for #{address} failed: #{actor_url}"
      return nil
    end
    ap_server_domain = URI.parse(actor['id']).hostname

    # domain is returned by webfinger server
    if 0 != domain.casecmp(ap_server_domain)
      Rails.logger.info "#{__method__} verifying webfinger as #{domain} does not match #{ap_server_domain}"
      result2 = WebFinger.discover! "acct:#{actor['preferredUsername']}@#{ap_server_domain}"

      final_webfinger_subject = result2['subject']
      if 0 != final_webfinger_subject.casecmp(webfinger_subject)
        Rails.logger.info "#{__method__} Error: subject #{final_webfinger_subject} did not match reverse #{webfinger_subject}"
      else
        # normally domain is not present unless domain is verified by webfinger to be different than activitypub server
        actor['domain'] = domain
      end
    end

    Account.create_mastodon_account(actor)
  rescue WebFinger::NotFound => e
    Rails.logger.info "#{self.class}##{__method__} WebFinger not found for #{address}: #{e.message}"
    nil
  end

  def self.fetch_and_create_or_update_mastodon_account(actor_url)
    account = find_by(identifier: actor_url)

    actor = strict_fetch_actor(actor_url)
    if nil == actor
      Rails.logger.info "#{__method__} error fetching actor #{actor_url}"
      return nil
    end

    if account.present?
      account.update_mastodon_account(actor)
      account.save!
    else
      account = Account.create_mastodon_account(actor)
    end

    account
  end

  def self.fetch_actor(actor_url)
    actor = User.representative.get(actor_url)
    if nil == actor
      Rails.logger.info "#{__method__} error fetching actor #{actor_url}"
      return nil
    end

    if actor['error'].present?
      Rails.logger.info "#{__method__} error message fetching actor #{actor_url}: #{actor['error']}"
      return nil
    end

    log_json(actor)
    actor
  end

  def self.strict_fetch_actor(actor_url)
    actor = fetch_actor(actor_url)
    if nil == actor
      return nil
    end

    if HttpClient.urls_equal?(actor['id'], actor_url)
      actor
    else
      Rails.logger.info "#{__method__} error actor id does not match requested url #{actor_url}: #{actor['id']}"
      nil
    end
  end

  def self.log_icon_and_image(actor)
    ['icon', 'image'].each do |i|
      if actor[i].present?
        if actor[i].is_a?(Hash)
          Rails.logger.info "#{i} url: #{actor[i]['url']}"
        elsif actor[i].is_a?(Array)
          actor[i].each do |icon_or_image|
            Rails.logger.info "#{i} url: #{icon_or_image['url']}"
          end
        end
      end
    end
  end

  def self.log_json(actor)
    if !actor.is_a?(Hash)
      Rails.logger.info "#{__method__} error not a hash"
      return
    end
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
    log_icon_and_image(actor)
    Rails.logger.info "public_key: #{actor['publicKey']['publicKeyPem']}" if actor['publicKey'].present?
  rescue TypeError => e
    Rails.logger.info "#{self.class}##{__method__} TypeError exception: #{e.message}"
  end

  def self.create_mastodon_account(actor)
    return nil if actor.nil?
    if actor['id'].blank?
      Rails.logger.info "#{__method__} error actor is not present"
      return nil
    end
    account = Account.new
    account.update_mastodon_account(actor)
    account.save!
    account
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.info "#{__method__} error actor exists: #{actor['id']}"
    find_by(identifier: actor['id'])
  end

  def check_configuration
    # just for creating this account for local users
    return if !local?

    result = WebFinger.discover! "acct:#{webfinger_to_s}"
    webfinger_actor_url = result['links'].select {|link| link['rel'] == 'self'}.first['href']
    if webfinger_actor_url != user.actor_url
      Rails.logger.info "#{self.class}##{__method__} Error unexpected webfinger actor_url: #{webfinger_actor_url}"
      errors.add :base, "Webfinger: Expected #{user.actor_url} but found #{webfinger_actor_url}"
      return
    end

    self.identifier = user.actor_url
    self.inbox = "#{user.actor_url}/inbox"
    self.outbox = "#{user.actor_url}/outbox"
    self.followers = "#{user.actor_url}/followers"
    self.following = "#{user.actor_url}/following"
  rescue WebFinger::NotFound => e
    Rails.logger.info "#{self.class}##{__method__} WebFinger::NotFound exception: #{e.message}"
    errors.add :base, "Webfinger: not found"
  end

  def likes_received
    Like.joins(status: :account).where(accounts: { id: id })
  end

  def verify(signature, comparison_string)
    Rails.logger.info "#{self.class}##{__method__}"

    key = OpenSSL::PKey::RSA.new(public_key)
    result = key.verify(OpenSSL::Digest::SHA256.new, signature, comparison_string)
    if !result
      Rails.logger.info "#{__method__} Error verifying signature for account: #{id}"
    end

    result
  end

  def verify_signature(json_obj)
    Rails.logger.info "#{self.class}##{__method__}"
    item = json_obj.with_indifferent_access

    if item['signature'].blank?
      Rails.logger.info "#{__method__} Error No signature for #{item['actor']}"
      return false
    end

    creator_uri = URI.parse(item['signature']['creator'])
    signature_creator = item['signature']['creator'].sub(creator_uri.fragment,'').chomp('#')
    if signature_creator != item['actor']
      Rails.logger.info "#{self.class}##{__method__} Error unexpected creator: #{item['signature']['creator']}"
      return false
    end

    if 'RsaSignature2017' != item['signature']['type']
      Rails.logger.info "#{__method__} Error Unknown signature type: #{item['signature']['type']}"
      return false
    end

    signature = Base64.decode64(item['signature']['signatureValue'])
    comparison_string = construct_comparison_string(item)
    verify(signature, comparison_string)

  rescue => e
    Rails.logger.info "#{__method__} Error: #{e.message}"
    false
  end

  def update_mastodon_account(actor)
    return if actor.nil?

    self.public_key = actor['publicKey']['publicKeyPem']
    self.identifier = actor['id']
    self.domain = actor['domain'].present? ? actor['domain'] : URI.parse(identifier).hostname
    self.preferred_username = actor['preferredUsername']
    self.name = actor['name']
    self.also_known_as = actor['alsoKnownAs']

    self.following = actor['following']
    self.followers = actor['followers']
    self.inbox = actor['inbox']
    self.outbox = actor['outbox']
    self.url = actor['url'].present? ? actor['url'] : actor['id']

    if actor['icon'].present?
      self.icon = actor['icon'].is_a?(Array) ? actor['icon'][0]['url'] : actor['icon']['url']
    end
    if actor['image'].present?
      self.image = actor['image'].is_a?(Array) ? actor['image'][0]['url'] : actor['image']['url']
    end
    self.summary = actor['summary']
  rescue TypeError => e
    Rails.logger.info "#{self.class}##{__method__} TypeError exception: #{e.message}"
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

  def has_a_local_follower?
    account_followers.merge(User.all.map(&:account)).any?
  end

  def remote?
    user.nil?
  end

  def local?
    user.present?
  end

  def bsky_url
    (JSON.parse(url).is_a?(Array) rescue false) ? JSON.parse(url)[0] : url
  end

  def bsky?
    "bsky.brid.gy" == domain
  end

  def webfinger_to_s
    "#{preferred_username}@#{domain}"
  end

  def follow!(target_account, object_uri = '')
    Follow.add(self, target_account, object_uri)
  end

  def like!(status_uri)
    status = Status.from_local_uri(status_uri)
    like = status.like!(self)
    status.account.user.like_notifications.create(read_at: nil, account: self, status: status, message: '')
    like
  end

  def create_status!(status_object, thread = nil)
    Rails.logger.info "#{__method__} id: #{status_object['id']}"
    mentions = []
    media_attachments = []
    direct_recipient = nil

    if status_object['to'].present?
      if status_object['to'].include?('https://www.w3.org/ns/activitystreams#Public')
        Rails.logger.info "#{__method__} received public post"
      else
        status_object['to'].each do |recipient|
          Rails.logger.info "#{__method__} to: recipient: #{recipient}"
          account = Account.find_by(identifier: recipient)
          direct_recipient = account if account.present? && account.local?
        end

        if direct_recipient.nil?
          Rails.logger.info "#{__method__} direct message recipient not found"
          status_object['cc'].each do |cc_recipient|
            Rails.logger.info "#{__method__} cc: recipient: #{cc_recipient}"
          end
        end
      end
    end

    language = status_object['contentMap']&.keys&.first

    if !thread.present? && status_object['inReplyTo'].present?
      in_reply_to_id = status_object['inReplyTo'].is_a?(Hash) ? status_object['inReplyTo']['id'] : status_object['inReplyTo']
      thread = Status.find_by(uri: in_reply_to_id)
    end

    if status_object['tag'].present?
      if status_object['tag'].is_a?(Hash)
        status_object['tag'] = [ status_object['tag'] ]
      end
      status_object['tag'].each do |tag|
        if 'Mention' == tag['type']
          Rails.logger.info "#{__method__} found mention: looking up #{tag['name']} : #{tag['href']}"
          account = Account.fetch_and_create_mastodon_account(tag['href'])
          if account.present?
            mentions << Mention.new(account: account, silent: false)
          end
        end
      end
    end
    if status_object['attachment'].present?
      if status_object['attachment'].is_a?(Hash)
        status_object['attachment'] = [ status_object['attachment'] ]
      end
      status_object['attachment'].each do |attachment|
        remote_url = attachment['url']
        content_type = attachment['mediaType']
        description = attachment['name']
        Rails.logger.info "#{__method__} found attachment (#{content_type}) url: #{remote_url}"
        media_attachments << MediaAttachment.new(account: self, content_type: content_type, remote_url: remote_url, description: description)
      end
    end

    # if inReplyTo is present but there is no status with a matching uri, then we can use in_reply_to_uri to assign thread later

    status = self.statuses.find_or_create_by(uri: status_object['id']) do |s|
      s.created_at = status_object['published']&.to_datetime
      s.language = language
      s.thread = thread
      s.in_reply_to_uri = status_object['inReplyTo']
      s.text = status_object['content'] || ''
      s.direct_recipient = direct_recipient
      s.url = status_object['url']
    end

    if status.errors.any?
      status.errors.full_messages.each do |m|
        Rails.logger.info "#{self.class}##{__method__} #{m}"
      end

      return nil
    end

    Rails.logger.info "#{self.class}##{__method__} created status #{status.id}"

    mentions.each do |m|
      m.status = status
      m.save
    end

    media_attachments.each do |a|
      a.status = status
      a.save
    end

    if status_object['inReplyTo'].present?
      if nil == thread
        FetchThreadJob.perform_later(status.id)
      else
        Rails.logger.info "#{__method__} thread #{thread.id} already exists locally"
      end
    end

    status

  rescue NoMethodError => e
    Rails.logger.info "#{self.class}##{__method__} NoMethod exception: #{e.message}"
    nil
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.info "#{self.class}##{__method__} exception: #{e.message}"
    nil
  end

  def create_boost!(item)
    original_url = item['object'].is_a?(Hash) ? item['object']['id'] : item['object']
    original_status = Status.from_object_uri(original_url)
    if nil == original_status
      err_msg = "#{self.class}##{__method__} error boosting: #{original_url}"
      Rails.logger.info err_msg
      raise StandardError, err_msg
    end
    # boost not expected to have a url
    status = self.statuses.create!( created_at: item['published']&.to_datetime,
                                    reblog: original_status,
                                    uri: item['id']
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.info "#{self.class}##{__method__} exception: #{e.message}"
    Status.find_by(uri: item['id'])
  end

  def update_status!(item)
    status_url = item['object']['id']
    status = Status.from_object_uri(status_url)
    if nil == status
      err_msg = "#{self.class}##{__method__} error updating: #{status_url}"
      Rails.logger.info err_msg
      raise StandardError, err_msg
    end

    if status.account_id != id
      err_msg = "#{self.class}##{__method__} error [id: #{id}] unauthorized update for: #{status_url}"
      Rails.logger.info err_msg
      raise StandardError, err_msg
    end

    status.text = item['object']['content']
    status.save!
  end

  def update_profile!(item)
    Rails.logger.info "#{self.class}##{__method__} id: #{id}"
    update_mastodon_account(item['object'])
    self.save!
  end

  def matches_activity_actor?(actor_identifier)
    self.identifier == actor_identifier
  end

  def sign_json(item)
    str = construct_comparison_string(item)
    keypair=OpenSSL::PKey::RSA.new(user.private_key)
    signature = Base64.strict_encode64(keypair.sign(OpenSSL::Digest::SHA256.new, str))
  end

  private

  def construct_comparison_string(item)
    options_hash   = sha256_hash(obj1(item))
    document_hash  = sha256_hash(obj2(item))
    options_hash + document_hash
  end

  def obj1(item)
    item['signature'].without('type', 'id', 'signatureValue').merge('@context' => CONTEXT)
  end

  def obj2(item)
    item.without('signature')
  end

  def sha256_hash(obj)
    Digest::SHA256.hexdigest(JsonHelper.canonicalize(obj))
  end
end
