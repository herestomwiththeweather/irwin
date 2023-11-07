class Mention < ApplicationRecord
  belongs_to :account
  belongs_to :status

  validates :account, uniqueness: { scope: :status }
end
