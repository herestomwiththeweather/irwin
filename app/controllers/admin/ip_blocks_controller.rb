class Admin::IpBlocksController < ApplicationController
  before_action :admin_login_required
  before_action :set_ip_block, only: %i[ show edit update destroy ]

  # GET /admin/ip_blocks or /admin/ip_blocks.json
  def index
    @ip_blocks = IpBlock.all
  end

  # GET /admin/ip_blocks/1 or /admin/ip_blocks/1.json
  def show
  end

  # GET /admin/ip_blocks/new
  def new
    @ip_block = IpBlock.new
  end

  # GET /admin/ip_blocks/1/edit
  def edit
  end

  # POST /admin/ip_blocks or /admin/ip_blocks.json
  def create
    @ip_block = IpBlock.new(ip_block_params)

    respond_to do |format|
      if @ip_block.save
        format.html { redirect_to [:admin, @ip_block], notice: "Ip block was successfully created." }
        format.json { render :show, status: :created, location: @ip_block }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ip_block.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/ip_blocks/1 or /admin/ip_blocks/1.json
  def update
    respond_to do |format|
      if @ip_block.update(ip_block_params)
        format.html { redirect_to [:admin, @ip_block], notice: "Ip block was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @ip_block }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ip_block.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/ip_blocks/1 or /admin/ip_blocks/1.json
  def destroy
    @ip_block.destroy!

    respond_to do |format|
      format.html { redirect_to admin_ip_blocks_path, notice: "Ip block was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ip_block
      @ip_block = IpBlock.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ip_block_params
      params.require(:ip_block).permit(:ip)
    end
end
