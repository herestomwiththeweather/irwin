class AccessToken < ApplicationRecord
  belongs_to :authorization_code
  belongs_to :user
  has_secure_token

  before_validation :setup, on: :create
  validates :expires_at, presence: true

  def expires_in
    (expires_at - Time.now.utc).to_i
  end

  def setup
    self.expires_at ||= 30.days.from_now
  end
end
