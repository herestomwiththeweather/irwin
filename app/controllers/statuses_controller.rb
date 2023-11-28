class StatusesController < ApplicationController
  before_action :login_required, except: [:show]
  before_action :set_status, only: [:show, :boost]

  authorize_resource

  def index
    @statuses = current_user.feed
    @new_status = Status.new
  end

  def private_mentions
    @statuses = Status.where(direct_recipient: current_user.account).or(@current_user.account.statuses.where('direct_recipient_id IS NOT NULL'))
  end

  def boost
    respond_to do |format|
      format.html do
        @status.boost!(current_user.account)
        render @status
      end
    end
  end

  def show
    # api access only allowed for statuses that were created by local users

    respond_to do |format|
      format.html do
        @new_status = Status.new
        @new_status.in_reply_to_id = @status.id

        # XXX d'oh! what if recipient was only mentioned in a private mention and not the direct recipient?
        @direct_recipient_id = nil
        if @status.private_mention?
          @direct_recipient_id = @status.counterparty(current_user.account).id
        end
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
