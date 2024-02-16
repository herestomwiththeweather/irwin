class ActivityPub::Activity::Create < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__}"
    # since current account could be sending a received reply, we cannot assume current account created the status
    actor = @account
    if @json['actor'] != @account.identifier
      Rails.logger.info "#{self.class}##{__method__} validating signature for: #{@json['actor']}"
      account = Account.fetch_by_key(@json['signature']['creator'])
      if account.nil?
        Rails.logger.info "#{self.class}##{__method__} Error No account for #{@json['actor']}"
        return 400
      end

      return 400 unless account.verify_signature(@json)
      actor = account

      Rails.logger.info "#{self.class}##{__method__} *** signature verification succeeded *** for actor: #{actor.id}"
    end

    status = actor.create_status!(@json['object'])
    if !status
      Rails.logger.info "#{self.class}##{__method__} Error creating status id: #{@json['object']['id']} from account id: #{actor.id}"
    elsif status.thread.present? && status.thread.account.local?
      if !status.private_mention?
        DistributeRawReplyJob.perform_later(JSON.dump(@json), status.thread.account_id, actor.id)
      end
    end

    202
  end
end
