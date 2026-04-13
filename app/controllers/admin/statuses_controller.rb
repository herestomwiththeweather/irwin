class Admin::StatusesController < ApplicationController
  before_action :admin_login_required
  before_action :set_status, only: %i[ destroy ]

  def index
    if params[:query].present? || params[:page].present?
      SearchJob.perform_later(current_user.id, params[:query]&.permit(:text, :language, :url), params[:page])
    end
  end

  def destroy
    @status.discard

    respond_to do |format|
      format.html { redirect_to admin_statuses_url, notice: "Status was successfully destroyed." }
    end
  end

  private
    def set_status
      @status = Status.find(params[:id])
    end
end
