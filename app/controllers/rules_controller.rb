class RulesController < ApplicationController
  def index
    @rules = Rule.order(:priority, :id)
  end
end
