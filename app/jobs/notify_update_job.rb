class NotifyUpdateJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 0

  def perform(account_id)
    account = Account.find(account_id)
    account.notify_update
  end
end
