class AnnounceJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 8.seconds, attempts: 3

  def perform(json, account_id)
    account = Account.find(account_id)
    status = account.create_boost!(json)
  end
end
