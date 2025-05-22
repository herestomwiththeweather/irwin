class ActivityPub::Activity::Update < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__}"
    actor = @account

    # since current account could be sending a received reply, we cannot assume current account created the status
    if ('Note' == @json['object']['type']) && (@json['actor'] != @account.identifier)
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

    UpdateJob.perform_later(@json, actor.id)
    202
  end
end
