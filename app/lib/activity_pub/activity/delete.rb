class ActivityPub::Activity::Delete < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__}"
    202
  end
end
