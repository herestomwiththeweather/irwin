class SearchesController < ApplicationController
  before_action :login_required

  def new
  end

  def create
    account = Account.fetch_and_create_mastodon_account_by_address(params[:webfinger])
    redirect_to account_path account
  end
end
