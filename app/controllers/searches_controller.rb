class SearchesController < ApplicationController
  before_action :login_required

  def new
  end

  def create
    account = Account.fetch_and_create_mastodon_account_by_address(params[:webfinger])
    redirect_to account.present? ? account_path(account) : root_path
  end
end
