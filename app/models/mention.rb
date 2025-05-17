class Mention < ApplicationRecord
  belongs_to :account
  belongs_to :status

  validates :account, uniqueness: { scope: :status }

  default_scope { order(created_at: :desc) }
end
