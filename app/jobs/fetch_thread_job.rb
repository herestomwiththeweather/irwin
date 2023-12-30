class FetchThreadJobError < StandardError; end

class FetchThreadJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 2

  def perform(status_id)
    status = Status.find(status_id)
    return if nil != status.thread

    thread = Status.from_object_uri(status.in_reply_to_uri)
    raise FetchThreadJobError if thread.nil?

    status.thread = thread

    status.save!
  end
end
