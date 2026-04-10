module Api
  module V1
class EntranceExitsController < ApiController
  before_action :set_french_scene, except: [:show, :update, :destroy]
  before_action :set_entrance_exit, only: [:show, :update, :destroy]

  # GET /entrance_exits
  def index
    @entrance_exits = @french_scene.entrance_exits
    json_response(@entrance_exits.as_json(include: [:characters, :stage_exit]))
    # json_response(@entrance_exits.as_json(include: [:character, :stage_exit]))
  end

  # GET /entrance_exits/1
  def show
    render json: @entrance_exit
  end

  # POST /entrance_exits
  def create
    @entrance_exit = EntranceExit.new(entrance_exit_params)
    if @entrance_exit.save
      json_response(@entrance_exit.as_json(include: [:characters, :stage_exit]))
      # render json: @entrance_exit, status: :created, location: @entrance_exit
    else
      render json: @entrance_exit.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /entrance_exits/1
  def update
    if @entrance_exit.update(entrance_exit_params)
      json_response(@entrance_exit.as_json)
    else
      render json: @entrance_exit.errors, status: :unprocessable_entity
    end
  end

  # DELETE /entrance_exits/1
  def destroy
    @entrance_exit.destroy
  end

  private
    def set_french_scene
      @french_scene = FrenchScene.find(params[:french_scene_id])
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_entrance_exit
      @entrance_exit = EntranceExit.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def entrance_exit_params
      params.require(:entrance_exit).permit(
        :category,
        :french_scene_id,
        :line,
        :notes,
        :page,
        :stage_exit_id,
        character_ids: [],
      )
    end
end
  end
end
