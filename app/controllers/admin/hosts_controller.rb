class Admin::HostsController < ApplicationController
  before_action :admin_login_required
  before_action :set_host, only: %i[ show ]

  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_host
      @host = Host.find(params[:id])
    end
end
