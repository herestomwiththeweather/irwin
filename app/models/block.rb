class Block < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  default_scope -> { kept }
  belongs_to :account
  belongs_to :target_account, class_name: 'Account'

  validates :account, presence: true
  validates :target_account, presence: true, uniqueness: { scope: :account_id, conditions: -> { kept } }
end
