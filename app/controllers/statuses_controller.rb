class StatusesController < ApplicationController
  before_action :login_required, except: [:show]
  before_action :set_status, only: [:show]

  authorize_resource

  def index
    @statuses = current_user.feed
    @new_status = Status.new
  end

  def show
    # api access only allowed for statuses that were created by local users

    respond_to do |format|
      format.html do
        @new_status = Status.new
        @new_status.in_reply_to_id = @status.id
      end
      format.json do
        if @status.local?
          render json: @status, serializer: StatusSerializer, content_type: 'application/activity+json'
        else
          render json: {}, status: :unprocessable_entity
        end
      end
    end
  end

  def create
    @status = Status.new(status_params)
    Rails.logger.info "XXX create: #{@status.in_reply_to_id}"
    @status.account = current_user.account
    @status.language = 'en'

    if @status.save!
      NotifyFollowersJob.perform_later(@status.id)
      redirect_to root_url, notice: "Success!"
    end
  end

  private

  def set_status
    @status = Status.find(params[:id])
  end

  def status_params
    params.require(:status).permit(:text, :in_reply_to_id, :direct_recipient_id)
  end
end
