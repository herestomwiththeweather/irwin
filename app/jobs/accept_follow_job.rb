class AcceptFollowJob < ApplicationJob
  queue_as :default

  def perform(follow_id)
    follow = Follow.find(follow_id)
    follow.accept!
  end
end
