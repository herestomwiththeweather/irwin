class ActivityPub::Activity::Create < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__}"

    status = @account.create_status!(@json['object'])
    if !status
      Rails.logger.info "#{self.class}##{__method__} Error creating status id: #{@json['object']['id']} from account id: #{@account.id}"
    elsif status.thread.present? && status.thread.account.local?
      if !status.private_mention?
        DistributeRawReplyJob.perform_later(JSON.dump(@json), status.thread.account_id, @account.id)
      end
    end

    202
  end
end
