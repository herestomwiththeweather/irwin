class ActivityPub::Activity::Like < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__}"
    object_uri = @json['object'].is_a?(Hash) ? @json['object']['id'] : @json['object']
    return 202 unless URI(object_uri).host == ENV['SERVER_NAME']
    like = @account.like!(object_uri)
    like.nil? ? 500 : 202
  end
end
