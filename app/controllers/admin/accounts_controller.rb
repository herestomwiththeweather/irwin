class Admin::AccountsController < ApplicationController
  before_action :admin_login_required

  # GET /admin/accounts or /admin/accounts.json
  def index
    @query = Account.ransack(params[:query])
    @admin_accounts = @query.result.page(params[:page])
  end

  def different_domains
    @admin_accounts = Account.with_different_domains.order('created_at DESC').page(params[:page])
  end

  def custom_domains
    @admin_accounts = Account.with_different_domains.select { |a| a.custom_domain? }
  end
end
