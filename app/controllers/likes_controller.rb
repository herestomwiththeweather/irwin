class LikesController < ApplicationController
  before_action :login_required, except: [:show]

  def create
    status = Status.find(params[:status_id])
    @like = Like.new(status: status, account: current_user.account)
    
    respond_to do |format|
      format.html do
        if @like.save
          result = @like.request!
          if !result
            @like.destroy
          end
          render partial: status, locals: { child_view: false }
        else
          Rails.logger.info "Error saving like. status #{params[:status_id]} account #{current_user.account_id}"
          render partial: status, locals: { child_view: false }
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render json: {} }
    end
  end

  def destroy
    @like = Like.find(params[:id])
    status = @like.status
    result = @like.remove!
    @like.destroy

    respond_to do |format|
      format.html { render partial: status, locals: { child_view: false } }
    end
  end
end
