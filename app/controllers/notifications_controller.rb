class NotificationsController < ApplicationController
  before_action :login_required

  authorize_resource

  def index
    set_read_at_for_new_notifications
    @notifications = current_user.notifications.page(params[:page])
  end

  private

  def set_read_at_for_new_notifications
    current_user.notifications.where(read_at: nil).each do |n|
      n.update_attribute(:read_at, Time.now)
    end
  end
end
