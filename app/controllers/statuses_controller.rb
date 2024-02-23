class StatusesController < ApplicationController
  before_action :login_required, except: [:show, :replies]
  before_action :set_status, only: [:show, :boost, :unboost, :replies, :translate]

  authorize_resource

  def index
    @statuses = current_user.feed.page(params[:page])
    @new_status = Status.new
  end

  def translate
    @translation = DeepL.translate @status.text, @status.language.upcase, current_user.language.upcase
    Rails.logger.info "#{self.class}##{__method__} #{@translation.text}"
    @status.text = @translation.text
    render partial: @status, locals: { child_view: false }
  end

  def private_mentions
    @statuses = Status.where(direct_recipient: current_user.account).or(@current_user.account.statuses.where('direct_recipient_id IS NOT NULL'))
  end

  def mentions
    @mentions = current_user.account.mentions.page(params[:page])
  end

  def replies
    @status.current_replies_page = params[:page]
    respond_to do |format|
      format.all do
        if @status.local?
          render json: @status, serializer: RepliesSerializer, content_type: 'application/activity+json'
        else
          render json: {}, status: :unprocessable_entity
        end
      end
    end
  end

  def boost
    respond_to do |format|
      format.html do
        @status.boost!(current_user.account)
        render partial: @status, locals: { child_view: false }
      end
    end
  end

  def unboost
    respond_to do |format|
      format.html do
        @status.unboost!(current_user.account)
        render partial: @status, locals: { child_view: false }
      end
    end
  end

  def show
    # api access only allowed for statuses that were created by local users

    respond_to do |format|
      format.html do
        @new_status = Status.new
        @new_status.in_reply_to_id = @status.id

        @boosts = Status.where(reblog_of_id: @status.id)
        # XXX d'oh! what if recipient was only mentioned in a private mention and not the direct recipient?
        @direct_recipient_id = nil
        if @status.private_mention?
          @direct_recipient_id = @status.counterparty(current_user.account).id
        end
      end
      format.all do
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
    @status.language = current_user.language
    @status.media_attachments.each { |media_attachment| media_attachment.account = current_user.account }

    if @status.save!
      @status.update_attribute(:uri, @status.local_uri)
      NotifyFollowersJob.perform_later(@status.id)
      redirect_to root_url, notice: "Success!"
    end
  end

  private

  def set_status
    @status = Status.find(params[:id])
  end

  def status_params
    params.require(:status).permit(:text, :in_reply_to_id, :direct_recipient_id, media_attachments_attributes: [:file])
  end
end
