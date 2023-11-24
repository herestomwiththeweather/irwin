class Like < ApplicationRecord
  belongs_to :account
  belongs_to :status

  validates :status, uniqueness: { scope: :account }
end
