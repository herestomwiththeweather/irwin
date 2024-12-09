class Admin::AccountsController < ApplicationController
  before_action :admin_login_required

  # GET /admin/accounts or /admin/accounts.json
  def index
    @query = Account.ransack(params[:query])
    @admin_accounts = @query.result.page(params[:page])
  end
end
