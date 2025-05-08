class UpdateJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 0 

  def perform(json, account_id)
    account = Account.find(account_id)
    status = account.update_status!(json)
  end
end
