class UpdateJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 0 

  def perform(json, account_id)
    account = Account.find(account_id)
    case json['object']['type']
    when 'Note'
      status = account.update_status!(json)
    when 'Person'
      account.update_profile!(json)
    else
      Rails.logger.info "Unsupported object type for update: #{json['object']['type']}"
    end
  end
end
