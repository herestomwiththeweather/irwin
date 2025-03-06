class ActivityPub::Activity::Announce < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__}"
    AnnounceJob.perform_later(@json, @account.id)
    202
  end
end
