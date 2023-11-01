class NotifyFollowersJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 0

  def perform(status_id)
    status = Status.find(status_id)
    status.notify_cc
  end
end
