class Like < ApplicationRecord
  belongs_to :account
  belongs_to :status

  validates :status, uniqueness: { scope: :account }

  default_scope { order(created_at: :desc) }

  def local_uri
    Rails.application.routes.url_helpers.like_url(self, host: ENV['SERVER_NAME'], protocol: 'https')
  end

  def request!
    return false if account.mastodon?

    activity = {}
    activity['actor'] = account.user.actor_url
    activity['type'] = 'Like'
    activity['id'] = local_uri
    activity['object'] = status.uri
    account.user.post(status.account, activity)
  end

  def remove!
    return false if account.mastodon?

    activity = {}
    activity['id'] = local_uri
    activity['actor'] = account.user.actor_url
    activity['type'] = 'Undo'
    activity['object'] = {
      id: local_uri,
      type: "Like",
      actor: account.user.actor_url,
      object: status.uri
    }
    account.user.post(status.account, activity)
  end
end
