class IntentsController < ApplicationController
  before_action :login_required

  def follow
    Rails.logger.info "#{self.class}##{__method__} uri=#{params[:uri]}"

    actor = Account.fetch_actor(params[:uri])
    if actor.nil?
      redirect_to root_url, notice: "Sorry. That account is not available."
      return
    end

    canonical_actor_uri = actor['id']
    Rails.logger.info "#{self.class}##{__method__} canonical actor uri=#{canonical_actor_uri}"

    @account = Account.find_by(identifier: canonical_actor_uri) || Account.create_mastodon_account(actor)
    if @account.present?
      redirect_to @account
    else
      redirect_to root_url, notice: "Sorry. That account is not available."
    end
  end

  def like
    @status = Status.from_object_uri(params[:objectId])
    if @status.nil?
      redirect_to root_url, notice: "Sorry. That post is not available."
    else
      redirect_to @status
    end
  end
end
