class Admin::DashboardController < ApplicationController
  before_action :admin_login_required

  def index
  end
end
