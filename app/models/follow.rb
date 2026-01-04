class Follow < ApplicationRecord
  belongs_to :account
  belongs_to :target_account, class_name: 'Account'

  validates :account, presence: true
  validates :target_account, presence: true, uniqueness: { scope: :account_id }

  before_create :generate_identifier

  class << self
    def add(source, target, object_uri = '')
      follow = nil
      raise StandardError if source.id == target.id
      if source.local?
        follow = create!(account: source, target_account: target)
        result = follow.request!
        if !result
          follow.destroy!
          follow = nil
        end
      else
        follow = create!(account: source, target_account: target, uri: object_uri)
      end

      follow
    rescue => e
      if ActiveRecord::RecordInvalid == e.class
        if "Validation failed: Target account has already been taken" == e.message
          follow = Follow.where(account: source, target_account: target).first
          follow.uri = object_uri
          follow.save!
        end
      end
      follow
    end
  end

  def generate_identifier
    self.identifier = SecureRandom.hex
  end

  def object_id_url
    # the activity id for either a follow request or an accept request
    "https://#{ENV['SERVER_NAME']}/activities/#{identifier}"
  end

  def undo_id_url
    "https://#{ENV['SERVER_NAME']}/activities/#{identifier}/undo"
  end

  def request!
    return false if account.remote?

    activity = {}
    activity['actor'] = account.user.actor_url
    activity['type'] = 'Follow'
    activity['id'] = object_id_url
    activity['object'] = target_account.identifier
    account.user.post(target_account, activity)
  end

  def confirm_accepted
    update_attribute(:accepted_at, Time.now) if accepted_at.nil?
  end

  def accept!
    if account.local?
      confirm_accepted
      return true
    end

    activity = {}
    activity['actor'] = target_account.user.actor_url
    activity['type'] = 'Accept'
    activity['id'] = object_id_url
    activity['object'] = {"id" => uri, "type" => "Follow", "actor" => account.identifier, "object" => target_account.user.actor_url}
    target_account.user.post(account, activity) && confirm_accepted
  end

  def remove!
    if target_account.remote?
      activity = {}
      activity['actor'] = account.user.actor_url
      activity['type'] = 'Undo'
      activity['id'] = undo_id_url
      activity['object'] = {"id" => object_id_url, "type" => "Follow", "actor" => account.user.actor_url, "object" => target_account.identifier}
      account.user.post(target_account, activity)
    end
    self.destroy!
  end
end
