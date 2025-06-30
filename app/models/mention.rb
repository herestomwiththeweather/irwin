class Mention < ApplicationRecord
  belongs_to :account
  belongs_to :status

  validates :account, uniqueness: { scope: :status }

  default_scope { order(created_at: :desc) }

  after_create :create_notifications_for_local_account

  def create_notifications_for_local_account
    if account.local?
      if account_id != status.account_id
        account.user.mention_notifications.create(read_at: nil, account: status.account, status: status, message: '')
      end
    end
  end
end
