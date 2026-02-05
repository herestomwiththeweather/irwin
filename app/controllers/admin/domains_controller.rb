class Admin::DomainsController < ApplicationController
  before_action :admin_login_required

  def index
    domains = Account.group(:domain)
                     .count
                     .sort_by { |_, count| -count }
                     .map { |domain, count| { domain: domain, account_count: count } }
    @domains = Kaminari.paginate_array(domains).page(params[:page])
  end

  def show
    @domain = params[:id]
    Rails.logger.info "domain: #{@domain}"
    @accounts = Account.where(domain: @domain).order(:preferred_username).page(params[:page])
  end
end
