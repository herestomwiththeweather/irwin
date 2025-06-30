class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :account, optional: true
  belongs_to :status, optional: true

  default_scope { order(created_at: :desc) }

  after_create_commit {
    broadcast_replace_to( [self.user], target: "notification_count", partial: "layouts/notification_count", locals: { user: self.user } )
  }
end
