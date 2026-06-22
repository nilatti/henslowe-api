module Api
  module V1
class StageDirectionsController < ApiController
  before_action :set_stage_direction, only: [:show, :update, :destroy]

  # GET /stage_directions
  # GET /stage_directions.json
  def index
    @stage_directions = StageDirection.all
    render json: @stage_directions
  end

  # GET /stage_directions/1
  # GET /stage_directions/1.json
  def show
    render json: @stage_direction
  end

  # POST /stage_directions
  # POST /stage_directions.json
  def create
    @stage_direction = StageDirection.new(stage_direction_params)

    if @stage_direction.save
      render json: @stage_direction, status: :created
    else
      render json: @stage_direction.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /stage_directions/1
  def update
    play = @stage_direction.french_scene&.scene&.act&.play
    if play&.canonical?
      unless @current_user.superadmin?
        render json: { error: 'Only superadmins can edit canonical play texts.' }, status: :forbidden
        return
      end
    elsif !@current_user.superadmin? && !@current_user.has_active_subscription?
      render json: { error: 'An active subscription is required to edit production scripts.' }, status: :forbidden
      return
    end

    if @stage_direction.update(stage_direction_params)
      json_response(@stage_direction.as_json)
    else
      render json: @stage_direction.errors, status: :unprocessable_entity
    end
  end

  # DELETE /stage_directions/1
  # DELETE /stage_directions/1.json
  def destroy
    @stage_direction.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_stage_direction
      @stage_direction = StageDirection.includes(french_scene: { scene: { act: :play } }).find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def stage_direction_params
      params.require(:stage_direction).permit(:french_scene_id, :number, :kind, :new_content, :original_content, :xml_id, :characters, :character_groups)
    end
end
  end
end
