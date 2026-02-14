class MoveJob < ApplicationJob
  queue_as :default

  def perform(account_id, recipient_account_id, move_object, target_url, activity_id)
    account = Account.find(account_id)
    recipient_account = Account.find(recipient_account_id)

    unless account.matches_activity_actor?(move_object)
      Rails.logger.info "#{self.class}##{__method__} Error. old account mismatch: #{move_object}"
      return
    end

    target = Account.fetch_and_create_or_update_mastodon_account(target_url)
    if target.nil?
      Rails.logger.info "#{self.class}##{__method__} Error. could not find move target: #{target_url}"
      return
    end

    account.moved_to_account = target
    account.save!

    if !target.also_known_as.include?(account.identifier)
      Rails.logger.info "#{self.class}##{__method__} Error. also_known_as not included for target: #{target_url}"
      return
    end

    old_follow = Follow.find_by(target_account: account, account: recipient_account)
    unless old_follow.present?
      Rails.logger.info "#{self.class}##{__method__} Error. missing old follow for account: #{recipient_account_id}, target: #{account_id}"
      return
    end

    new_follow = recipient_account.follow!(target, activity_id)
    unless new_follow.present?
      Rails.logger.info "#{self.class}##{__method__} Error. failed to create follow for account: #{recipient_account_id}, target: #{target.id}"
      return
    end
    
    old_follow.remove!
  end
end
