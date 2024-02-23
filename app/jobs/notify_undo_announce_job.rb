class NotifyUndoAnnounceJob < ApplicationJob
  queue_as :default

  def perform(status_id)
    status = Status.find(status_id)
    if status.reblog.present?
      status.notify_undo_announce
    end
  end
end
