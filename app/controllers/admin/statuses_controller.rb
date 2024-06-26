class Admin::StatusesController < ApplicationController
  before_action :admin_login_required
  before_action :set_status, only: %i[ destroy ]

  # GET /admin/statuses or /admin/statuses.json
  def index
    @query = Status.ransack_search(params[:query])
    @statuses = @query.result.page(params[:page])
  end

  # DELETE /admin/statuses/1 or /admin/statuses/1.json
  def destroy
    @status.destroy

    respond_to do |format|
      format.html { redirect_to admin_statuses_url, notice: "Status was successfully destroyed." }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_status
      @status = Status.find(params[:id])
    end
end
