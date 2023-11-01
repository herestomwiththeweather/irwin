class FollowsController < ApplicationController
  before_action :login_required
  before_action :set_follow, only: %i[ destroy ]

  def destroy
    account = @follow.target_account
    @follow.remove!
    respond_to do |format|
      format.html { redirect_to following_path, notice: "unfollowed #{account.webfinger_to_s}" }
    end
  end

  private

  def set_follow
    @follow = Follow.find(params[:id])
  end
end
