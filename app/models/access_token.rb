class AccessToken < ApplicationRecord
  belongs_to :authorization_code
  belongs_to :user
  has_secure_token

  scope :valid, -> { where('expires_at > ?', Time.now.utc) }

  before_validation :setup, on: :create
  validates :expires_at, presence: true

  def expires_in
    (expires_at - Time.now.utc).to_i
  end

  def expired?
    expires_at < Time.now.utc
  end

  def expire!
    self.expires_at = Time.now.utc
    self.save!
  end

  private

  def setup
    self.expires_at ||= 30.days.from_now
  end
end
