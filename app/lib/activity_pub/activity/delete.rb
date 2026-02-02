class ActivityPub::Activity::Delete < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__}"

    object_uri = @json['object'].is_a?(Hash) ? @json['object']['id'] : @json['object']
    status = Status.find_by(uri: object_uri)

    return 202 if status.nil?

    return 401 unless status.account_id == @account.id

    status.discard unless status.discarded?
    202
  end
end
