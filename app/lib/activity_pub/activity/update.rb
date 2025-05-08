class ActivityPub::Activity::Update < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__}"
    UpdateJob.perform_later(@json, @account.id)
    202
  end
end
