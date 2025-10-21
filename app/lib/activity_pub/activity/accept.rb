class ActivityPub::Activity::Accept < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__}"
    Rails.logger.info "#{self.class}##{__method__} actor: #{@json['actor']}" # actor accepting the follow
    Rails.logger.info "#{self.class}##{__method__} follower: #{@json['object']['actor']}"
    follower = User.by_actor(@json['object']['actor'])&.account
    follow = ::Follow.find_by(target_account: @account, account: follower)
    if follow.present?
      follow.accept!
    else
      Rails.logger.info "#{self.class}##{__method__} Error finding follow to accept for: #{@json['actor']}"
    end
    200
  end
end
