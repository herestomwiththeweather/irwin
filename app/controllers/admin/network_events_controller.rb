class Admin::NetworkEventsController < ApplicationController
  before_action :admin_login_required
  before_action :set_network_event, only: %i[ show edit update destroy ]

  # GET /admin/network_events or /admin/network_events.json
  def index
    @network_events = NetworkEvent.order('created_at DESC').page(params[:page])
  end

  # GET /admin/network_events/1 or /admin/network_events/1.json
  def show
  end

  # GET /admin/network_events/1/edit
  def edit
  end

  # PATCH/PUT /admin/network_events/1 or /admin/network_events/1.json
  def update
    respond_to do |format|
      if @network_event.update(network_event_params)
        format.html { redirect_to [:admin, @network_event], notice: "Network event was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @network_event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @network_event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/network_events/1 or /admin/network_events/1.json
  def destroy
    @network_event.destroy!

    respond_to do |format|
      format.html { redirect_to admin_network_events_path, notice: "Network event was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_network_event
      @network_event = NetworkEvent.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def network_event_params
      params.require(:network_event).permit(:host_id, :event_type, :message, :path, :backtrace)
    end
end
