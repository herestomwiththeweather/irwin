class FetchRepliesJob < ApplicationJob
  queue_as :default

  def perform(status_id)
    status = Status.find(status_id)
    status.fetch_replies
  end
end
