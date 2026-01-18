class Admin::RulesController < ApplicationController
  before_action :admin_login_required
  before_action :set_rule, only: %i[ show edit update destroy ]

  # GET /admin/rules or /admin/rules.json
  def index
    @rules = Rule.all
  end

  # GET /admin/rules/1 or /admin/rules/1.json
  def show
  end

  # GET /admin/rules/new
  def new
    @rule = Rule.new
  end

  # GET /admin/rules/1/edit
  def edit
  end

  # POST /admin/rules or /admin/rules.json
  def create
    @rule = Rule.new(rule_params)

    respond_to do |format|
      if @rule.save
        format.html { redirect_to [:admin, @rule], notice: "Rule was successfully created." }
        format.json { render :show, status: :created, location: @rule }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @rule.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/rules/1 or /admin/rules/1.json
  def update
    respond_to do |format|
      if @rule.update(rule_params)
        format.html { redirect_to [:admin, @rule], notice: "Rule was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @rule }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @rule.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/rules/1 or /admin/rules/1.json
  def destroy
    @rule.destroy!

    respond_to do |format|
      format.html { redirect_to admin_rules_path, notice: "Rule was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_rule
      @rule = Rule.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def rule_params
      params.require(:rule).permit(:text, :priority)
    end
end
