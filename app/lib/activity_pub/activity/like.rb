class ActivityPub::Activity::Like < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__}"
    return 202 if @recipient_account.remote?
    like = @account.like!(@json['object'])
    like.nil? ? 500 : 202
  end
end
