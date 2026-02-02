class Status < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  belongs_to :account
  belongs_to :direct_recipient, class_name: 'Account', optional: true
  belongs_to :thread, foreign_key: 'in_reply_to_id', class_name: 'Status', optional: true
  belongs_to :reblog, foreign_key: 'reblog_of_id', class_name: 'Status', optional: true

  has_many :replies, -> { kept }, foreign_key: 'in_reply_to_id', class_name: 'Status', inverse_of: :thread
  has_many :mentions, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :media_attachments, dependent: :destroy

  has_paper_trail on: [:update], only: [:text]

  accepts_nested_attributes_for :media_attachments, allow_destroy: true

  attr_accessor :current_replies_page

  validates :uri, uniqueness: true, presence: true, allow_nil: true

  default_scope { order(created_at: :desc) }

  after_create :create_mentions_for_local_account

  def self.ransackable_attributes(auth_object = nil)
    ["text", "language", "direct_recipient_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.ransack_search(query_params)
    permitted_params = query_params.permit(:text_i_cont, :language_eq) if query_params.present?
    ransack({direct_recipient_id_null: true}.merge(permitted_params || {}))
  end

  # languages supported by DeepL gem
  LANGUAGES = [
    ["Bulgarian", "bg"],
    ["Czech", "cs"],
    ["Danish", "da"],
    ["German", "de"],
    ["Greek", "el"],
    ["English", "en"],
    ["Spanish", "es"],
    ["Estonian", "et"],
    ["Finnish", "fi"],
    ["French", "fr"],
    ["Hungarian", "hu"],
    ["Indonesian", "id"],
    ["Italian", "it"],
    ["Japanese", "ja"],
    ["Korean", "ko"],
    ["Lithuanian", "lt"],
    ["Latvian", "lv"],
    ["Norwegian", "nb"],
    ["Dutch", "nl"],
    ["Polish", "pl"],
    ["Portuguese", "pt"],
    ["Romanian", "ro"],
    ["Russian", "ru"],
    ["Slovak", "sk"],
    ["Slovenian", "sl"],
    ["Swedish", "sv"],
    ["Turkish", "tr"],
    ["Ukrainian", "uk"],
    ["Chinese", "zh"]
  ]

  def self.from_local_uri(uri)
    status_uri = URI(uri)
    return nil unless ENV['SERVER_NAME'] == status_uri.host
    id = status_uri.path.split('/').last
    Status.find_by(id: id)
  end

  def self.from_object_uri(uri, thread = nil)
    status = Status.find_by(uri: uri)
    return status unless status.nil?

    Rails.logger.info "#{__method__} fetching status: #{uri}"
    json_status = User.representative.get(uri)
    if nil == json_status
      Rails.logger.info "#{__method__} error fetching status"
      return nil
    end
    if json_status['error'].present?
      Rails.logger.info "#{__method__} error fetching original status: #{json_status['error']}"
      return nil
    end

    original_actor_url = case json_status['attributedTo']
    when String
      json_status['attributedTo']
    when Array
      json_status['attributedTo'].select {|i| i['type'] == 'Person'}.first['id']
    when Hash
      json_status['attributedTo']['id']
    end

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

  def unboost!(account)
    Rails.logger.info "#{__method__} account #{account.id} unboosting #{id}"
    raise StandardError if account.user.nil?
    boost = Status.find_by(account: account, reblog_of_id: id)
    boost.update_attribute(:text, 'revoked')
    NotifyUndoAnnounceJob.perform_later(boost.id)
    boost
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
    Rails.application.routes.url_helpers.status_url(self, host: ENV['SERVER_NAME'], protocol: 'https')
  end

  def refresh_replies
    FetchRepliesJob.perform_later(self.id)
  end

  def fetch_replies
    json_status = User.representative.get(replies_uri)
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
      page_result = User.representative.get(current_page)
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

  def notify_undo_announce
    return false if (direct_recipient.present? || reblog.nil?)

    recipients = [ reblog.account ]
    recipients << account.account_followers
    recipients.flatten!

    cc_list = []
    cc_list << account.user.followers_url
    cc_list << reblog.account.identifier

    activity = {}
    activity['id'] = "#{account.user.actor_url}#announces/#{id}/undo"
    activity['actor'] = account.user.actor_url
    activity['type'] = 'Undo'
    activity['to'] = [
      "https://www.w3.org/ns/activitystreams#Public"
    ]
    activity['object'] = {
      "id" => local_uri,
      "type" => "Announce",
      "published" => created_at.iso8601,
      "actor" => account.identifier,
      "to" => [
        "https://www.w3.org/ns/activitystreams#Public"
      ],
      "cc" => cc_list,
      "object" => reblog.uri
    }

    recipients.each do |recipient|
      account.user.post(recipient, activity)
    end

    self.destroy!
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

    if thread.present? && (thread.account != account)
      recipients << thread.account unless recipients.include?(thread.account)
    end

    mentions.each do |mention|
      recipients << mention.account unless recipients.include?(mention.account)
    end

    marked_up_text = StatusPresenter.new(self, nil).marked_up_text

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
        "contentMap" => {
          language => marked_up_text
        },
        "content" => marked_up_text,
        "to" => [
          direct_recipient.present? ? direct_recipient.identifier : "https://www.w3.org/ns/activitystreams#Public"
        ]
      }
      attachments = []
      if media_attachments.present?
        media_attachments.each do |media_attachment|
          attachments << media_attachment.info
        end
        activity['object']['attachment'] = attachments
      end
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

  def doc
    # p tag to prevent more than 1 root element
    @doc ||= REXML::Document.new("<p>#{text}</p>")
  end

  def mention_anchors_found
    doc.elements.to_a('//a[contains(@class, "mention")]')
  end

  def text_with_modified_mentions
    mention_anchors_found.each do |mention|
      Rails.logger.info "#{__method__} status #{id}: #{mention.attributes['href']}"
      mention_to_replace = mentions.find_by(account: Account.find_by(url: mention.attributes['href']))
      if mention_to_replace
        mention.attributes['href'] = Rails.application.routes.url_helpers.account_url(mention_to_replace.account, host: ENV['SERVER_NAME'], protocol: 'https')
        mention.attributes['data-turbo-frame'] = '_top'
      end
    end

    doc.to_s
  rescue => e
    Rails.logger.info "#{self.class}##{__method__} rexml exception: #{e.message}"
    text
  end

  def local?
    account.user.present?
  end

  def reblog?
    !reblog_of_id.nil?
  end
end
