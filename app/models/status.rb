class Status < ApplicationRecord
  belongs_to :account
  belongs_to :thread, foreign_key: 'in_reply_to_id', class_name: 'Status', optional: true
  belongs_to :reblog, foreign_key: 'reblog_of_id', class_name: 'Status', optional: true

  has_many :replies, foreign_key: 'in_reply_to_id', class_name: 'Status', inverse_of: :thread

  validates :uri, uniqueness: true, presence: true, unless: :local?

  default_scope { order(created_at: :desc) }

  # returns JSON response or nil
  def self.fetch_remote_original_status(u)
    headers = {'Accept': 'application/json'}
    HttpClient.new(u, headers).get
  end

  def self.from_object_uri(uri)
    status = Status.find_by(uri: uri)
    return status unless status.nil?

    json_status = Status.fetch_remote_original_status(uri)
    if nil == json_status
      Rails.logger.info "#{__method__} error fetching status"
      return nil
    end
    if json_status['error'].present?
      Rails.logger.info "error fetching original status: #{json_status['error']}"
      return nil
    end

    original_actor_url = json_status['attributedTo']
    language = json_status['contentMap']&.keys&.first

    account = Account.fetch_and_create_mastodon_account(original_actor_url)
    if nil == account
      Rails.logger.info "#{__method__} error fetching actor"
      return nil
    end

    # XXX embedded self boost?

    status = Status.create!( account_id: account.id,
                             created_at: json_status['published']&.to_datetime,
                             language: language,
                             text: json_status['content'],
                             url: json_status['url'],
                             uri: json_status['id']
    )
  end

  def local_uri
    Rails.application.routes.url_helpers.status_url(self, host: URI(ENV['INDIEAUTH_HOST']).host)
  end

  def notify_cc
    recipients = account.account_followers
    if thread.present?
      recipients << thread.account unless recipients.include?(thread.account)
    end
    recipients.each do |follower|
      Rails.logger.info "#{__method__} sending to [#{follower.id}] #{follower.webfinger_to_s}"
      activity = {}
      activity['actor'] = account.user.actor_url
      activity['type'] = 'Create'
      activity['id'] =  local_uri
      activity['to'] = [
        "https://www.w3.org/ns/activitystreams#Public"
      ],
      activity['object'] = {
        "id" => local_uri,
        "type" => "Note",
        "published" => created_at.iso8601,
        "attributedTo" => account.user.actor_url,
        "content" => text,
        "to" => [
          "https://www.w3.org/ns/activitystreams#Public"
        ]
      }
      cc_list = [
        account.user.followers_url
      ]
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

      account.user.post(follower, activity)
    end

    true
  end

  def local?
    uri.nil?
  end

  def reblog?
    !reblog_of_id.nil?
  end
end
