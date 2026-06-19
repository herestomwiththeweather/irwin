class FetchQuotedStatusJobError < StandardError; end

class FetchQuotedStatusJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 5

  def perform(quote_id, quoted_uri, quote_authorization_uri = nil)
    quote = Quote.find(quote_id)

    if quote.quoted_status.nil?
      quoted_status = Status.from_object_uri(quoted_uri)
      raise FetchQuotedStatusJobError if quoted_status.nil?

      quote.quoted_status = quoted_status
      quote.quoted_account = quoted_status.account
      quote.save!
    end

    if quote_authorization_uri.present? && quote.approval_uri.blank?
      quote.update!(approval_uri: quote_authorization_uri)
      quote.verify!
    end
  end
end
