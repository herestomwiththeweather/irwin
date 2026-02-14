class ActivityPub::Activity::Move < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__}"

    MoveJob.perform_later(@account.id, @recipient_account.id, @json['object'], @json['target'], @json['id'])

    202
  end
end
