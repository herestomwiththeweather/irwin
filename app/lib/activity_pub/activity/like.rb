class ActivityPub::Activity::Like < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__}"
    like = @account.like!(@json['object'])
    like.nil? ? 500 : 202
  end
end
