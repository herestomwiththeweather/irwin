class ActivityPub::Activity::Reject < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__} actor: #{@json['actor']}"
    Rails.logger.info "#{self.class}##{__method__} follower: #{@json['object']['actor']}"
    follower = User.by_actor(@json['object']['actor'])&.account
    follow = ::Follow.find_by(target_account: @account, account: follower)
    if follow.present?
      follow.discard
      follower.user.reject_notifications.create(read_at: nil, account: @account, message: '')
    else
      Rails.logger.info "#{self.class}##{__method__} Error finding follow to reject for: #{@json['actor']}"
    end
    200
  end
end
