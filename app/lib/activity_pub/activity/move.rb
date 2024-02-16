class ActivityPub::Activity::Move < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__}"
    return 401 unless @account.matches_activity_actor?(@json['object'])

    target = Account.fetch_and_create_or_update_mastodon_account(@json['target'])
    return 500 if target.nil?

    @account.moved_to_account = target
    @account.save!

    return 403 if !target.also_known_as.include?(@account.identifier)

    #
    # unfollow origin account
    #
    old_follow = ::Follow.find_by(target_account: @account, account: @recipient_account)
    return 401 unless old_follow.present?

    old_follow.destroy!

    # follow target
    new_follow = @recipient_account.follow!(target, @json['id'])

    202
  end
end
