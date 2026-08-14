class ActivityPub::Activity::QuoteRequest < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__} id: #{@json['id']}"
    Rails.logger.info "#{self.class}##{__method__} actor: #{@json['actor']}"
    status_uri = @json['instrument'].is_a?(Hash) ? @json['instrument']['id'] : @json['instrument']
    Rails.logger.info "#{self.class}##{__method__} instrument: #{status_uri}"
    Rails.logger.info "#{self.class}##{__method__} quoted status: #{@json['object']}"

    quoted_status = Status.from_local_uri(@json['object'])
    if quoted_status.nil? || quoted_status.account_id != @recipient_account.id
      Rails.logger.info "#{self.class}##{__method__} Error: unexpected quoted status: #{@json['object']}"
      return 500
    end

    AcceptQuoteRequestJob.perform_later(quoted_status.id, @json)
    200
  end
end
