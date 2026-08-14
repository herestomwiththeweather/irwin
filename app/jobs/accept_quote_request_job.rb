class AcceptQuoteRequestJob < ApplicationJob
  queue_as :default

  def perform(quoted_status_id, json)
    quoted_status = Status.find(quoted_status_id)

    status_uri = json['instrument'].is_a?(Hash) ? json['instrument']['id'] : json['instrument']
    status = Status.from_object_uri(status_uri)
    if status.nil?
      Rails.logger.info "#{self.class}##{__method__} Error. could not find status: #{status_uri}"
      return
    end

    quote = status.quote
    if quote.nil?
      Rails.logger.info "#{self.class}##{__method__} Error. could not find quote: #{status_uri}"
      return
    end

    if quote.accepted?
      Rails.logger.info "#{self.class}##{__method__} quote already accepted: #{status_uri}"
      return
    end

    quote.quote_request_uri = json['id']
    quote.quoted_status = quoted_status
    quote.quoted_account = quoted_status.account
    quote.save!

    quote.accept!

    quoted_status.account.user.quote_notifications.create(read_at: nil, status: status, account: status.account, message: "")
  end
end
