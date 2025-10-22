class ActivityPub::Activity::Follow < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__}"
    target_object_id = @json['object'].is_a?(Hash) ? @json['object']['id'] : @json['object']
    @target_account = Account.find_by(identifier: target_object_id)
    return 500 if @target_account.user.nil?

    # check that recipient_account and target_account are the same
    if @recipient_account.id != @target_account.id
      Rails.logger.info "#{self.class}##{__method__} Error. recipient account #{@account.id} does not match #{@json['object']}"
      raise StandardError
    end

    # sanity check that source actor url specified in @json['actor'] matches actor making the request 
    if !@account.matches_activity_actor?(@json['actor'])
      Rails.logger.info "#{self.class}##{__method__} Error. current account #{@account.id} does not match #{@json['actor']}"
      raise StandardError
    end

    follow = @account.follow!(@target_account, @json['id'])
    @target_account.user.follow_notifications.create(read_at: nil, account: @account, message: '') if follow.present?
    AcceptFollowJob.perform_later(follow.id)
    follow.nil? ? 500 : 202
  end
end
