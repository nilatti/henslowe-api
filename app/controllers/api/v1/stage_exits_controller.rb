module Api
  module V1
class StageExitsController < ApiController
  before_action :set_production, except: [:show, :update, :destroy]
  before_action :set_stage_exit, only: [:show, :update, :destroy]

  # GET /stage_exits
  def index
    @stage_exits = @production.stage_exits
    render json: @stage_exits
  end

  # GET /stage_exits/1
  def show
    json_response(@stage_exit.as_json)
  end

  # POST /stage_exits
  def create
    @stage_exit = StageExit.new(stage_exit_params)

    if @stage_exit.save
      render json: @stage_exit, status: :created
    else
      render json: @stage_exit.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /stage_exits/1
  def update
    if @stage_exit.update(stage_exit_params)
      json_response(@stage_exit.as_json)
    else
      render json: @stage_exit.errors, status: :unprocessable_entity
    end
  end

  # DELETE /stage_exits/1
  def destroy
    @stage_exit.destroy
  end

  private
    def set_production
      @production = Production.find(params[:production_id])
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_stage_exit
      @stage_exit = StageExit.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def stage_exit_params
      params.require(:stage_exit).permit(:name, :production_id)
    end
end
  end
end
