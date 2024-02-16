class ActivityPub::Activity::Announce < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__}"
    status = @account.create_boost!(@json)
    202
  end
end
