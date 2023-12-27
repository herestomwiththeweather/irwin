class Status < ApplicationRecord
  belongs_to :account
  belongs_to :direct_recipient, class_name: 'Account', optional: true
  belongs_to :thread, foreign_key: 'in_reply_to_id', class_name: 'Status', optional: true
  belongs_to :reblog, foreign_key: 'reblog_of_id', class_name: 'Status', optional: true

  has_many :replies, foreign_key: 'in_reply_to_id', class_name: 'Status', inverse_of: :thread
  has_many :mentions, dependent: :destroy
  has_many :likes, dependent: :destroy

  attr_accessor :current_replies_page

  validates :uri, uniqueness: true, presence: true, allow_nil: true

  default_scope { order(created_at: :desc) }

  after_create :create_mentions_for_local_account

  def self.from_local_uri(uri)
    status_uri = URI(uri)
    return nil unless URI(ENV['INDIEAUTH_HOST']).host == status_uri.host
    id = status_uri.path.split('/').last
    # nil uri means the status was created locally
    Status.find_by(id: id, uri: nil)
  end

  def self.from_object_uri(uri, thread = nil)
    status = Status.find_by(uri: uri)
    return status unless status.nil?

    json_status = HttpClient.new(uri).get
    if nil == json_status
      Rails.logger.info "#{__method__} error fetching status"
      return nil
    end
    if json_status['error'].present?
      Rails.logger.info "error fetching original status: #{json_status['error']}"
      return nil
    end

    original_actor_url = json_status['attributedTo']

    if thread
      if json_status['inReplyTo'] != thread.uri
        Rails.logger.info "#{__method__} inReplyTo: #{json_status['inReplyTo']}"
        Rails.logger.info "#{__method__} thread.id: #{thread.uri}"
        raise "oops"
      end
    end

    account = Account.fetch_and_create_mastodon_account(original_actor_url)
    if nil == account
      Rails.logger.info "#{__method__} error fetching actor"
      return nil
    end

    # XXX embedded self boost?

    status = account.create_status!(json_status, thread)
  end

  def private_mention?
    direct_recipient.present?
  end

  def counterparty(current_account)
    return nil unless direct_recipient.present?
    (direct_recipient == current_account) ? account : direct_recipient
  end

  def like!(account)
    self.likes.create!(account: account)
  end

  def boost!(account)
    Rails.logger.info "#{__method__} account #{account.id} boosting #{id}"
    raise StandardError if account.user.nil?
    status = account.statuses.create!(reblog: self)
    NotifyFollowersJob.perform_later(status.id)
    status
  end

  def create_mentions_for_local_account
    if account.local?
      find_mentions.each do |mention|
        mention.status = self
        mention.save
      end
    end
  end

  def replies_uri
    "#{uri.nil? ? local_uri : uri}/replies"
  end

  def replies_first_page_uri
    "#{replies_uri}?page=1"
  end

  def local_uri
    Rails.application.routes.url_helpers.status_url(self, host: URI(ENV['INDIEAUTH_HOST']).host, protocol: 'https')
  end

  def refresh_replies
    FetchRepliesJob.perform_later(self.id)
  end

  def fetch_replies
    json_status = HttpClient.new(replies_uri).get
    if nil == json_status
      Rails.logger.info "#{__method__} error fetching replies"
      return nil
    end
    if json_status['error'].present?
      Rails.logger.info "error fetching replies: #{json_status['error']}"
      return nil
    end

    if 'Collection' != json_status['type']
      Rails.logger.info "#{__method__} [status #{id}] error type: #{json_status['type']}"
      return nil
    end

    first = json_status['first']

    if first['items'].length > 0
      first['items'].each do |item|
        Rails.logger.info "#{__method__} item: #{item}"
      end
      raise "items is not empty!"
    end

    return nil unless first['next'].present?

    i=0
    current_page = first['next']
    begin
      Rails.logger.info "#{__method__} [status #{id}] current page: #{current_page}"
      page_result = HttpClient.new(current_page).get
      page_result['items'].each do |item|
        item = item['id'] if item.is_a?(Hash)
        Rails.logger.info "#{__method__} [status #{id}] calling from_object_uri for: #{item}"
        status = Status.from_object_uri(item, self)
        if nil == status
          Rails.logger.info "#{__method__} [status #{id}] from_object_uri error for: #{item}"
        else
          FetchRepliesJob.perform_later(status.id)
        end
      end
      current_page = page_result['next']
      i += 1
    end until current_page.nil?
    Rails.logger.info "#{__method__} [status #{id}] fetched #{i} pages!"
    i # pages not replies
  end

  def notify_announce
    return false if (direct_recipient.present? || reblog.nil?)

    recipients = [ reblog.account ]
    recipients << account.account_followers
    recipients.flatten!

    cc_list = []
    cc_list << account.user.followers_url
    cc_list << reblog.account.identifier

    recipients.each do |recipient|
      Rails.logger.info "#{__method__} sending to [#{recipient.id}] #{recipient.webfinger_to_s}"
      activity = {}
      activity['actor'] = account.user.actor_url
      activity['type'] = 'Announce'
      activity['id'] =  local_uri
      activity['to'] = [
        "https://www.w3.org/ns/activitystreams#Public"
      ]
      activity['cc'] = cc_list
      activity['published'] =  created_at.iso8601

      activity['object'] = reblog.uri

      account.user.post(recipient, activity)
    end

    true
  end

  def notify_cc
    recipients = []

    if direct_recipient.present?
      recipients << direct_recipient
    else
      account.account_followers.each do |follower|
        recipients << follower
      end
    end

    if thread.present?
      recipients << thread.account unless recipients.include?(thread.account)
    end

    mentions.each do |mention|
      recipients << mention.account unless recipients.include?(mention.account)
    end

    recipients.each do |recipient|
      Rails.logger.info "#{__method__} sending to [#{recipient.id}] #{recipient.webfinger_to_s}"
      activity = {}
      activity['actor'] = account.user.actor_url
      activity['signature'] = {
        "type" => "RsaSignature2017",
        "created" => created_at.iso8601,
        "creator" => account.user.main_key_url
      }
      activity['type'] = 'Create'
      activity['id'] =  local_uri
      activity['to'] = [
        direct_recipient.present? ? direct_recipient.identifier : "https://www.w3.org/ns/activitystreams#Public"
      ]
      activity['object'] = {
        "id" => local_uri,
        "type" => "Note",
        "published" => created_at.iso8601,
        "attributedTo" => account.user.actor_url,
        "content" => text,
        "to" => [
          direct_recipient.present? ? direct_recipient.identifier : "https://www.w3.org/ns/activitystreams#Public"
        ]
      }
      cc_list = [
      ]
      cc_list << account.user.followers_url unless direct_recipient.present?

      tag_list = []

      mentions.each do |mention|
        cc_list << mention.account.identifier
        tag_list << {
          "name" => "@#{mention.account.webfinger_to_s}",
          "href" => mention.account.identifier,
          "type" => "Mention"
        }
      end

      if direct_recipient.present?
        tag_list << {
          "name" => "@#{direct_recipient.webfinger_to_s}",
          "href" => direct_recipient.identifier,
          "type" => "Mention"
        }
      end

      if thread.present?
        cc_list << thread.account.identifier
        thread_options = {
          "cc" => cc_list,
          "inReplyTo" => thread.uri
        }
        activity['object'].merge!(thread_options)
      else
        activity['object'].merge!("cc" => cc_list)
      end

      activity['object'].merge!("tag" => tag_list) unless tag_list.empty?

      account.user.post(recipient, activity)
    end

    true
  end

  def find_mentions
    new_mentions = []

    mentions_found.each do |mention|
      mention_account = Account.fetch_and_create_mastodon_account_by_address(mention)
      if mention_account.present?
        new_mentions << Mention.new(account: mention_account, silent: false)
      else
        Rails.logger.info "#{__method__} error retrieving account for #{mention}"
      end
    end

    new_mentions
  end

  def mentions_found
    email_regex = /\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b/

    matches = text.scan(email_regex)
  end

  def local?
    account.user.present?
  end

  def reblog?
    !reblog_of_id.nil?
  end
end
