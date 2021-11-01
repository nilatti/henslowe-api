class OnStagesController < ApiController
  before_action :set_french_scene, only: [:index]
  before_action :set_on_stage, only: [:show, :update, :destroy]

  # GET /on_stages
  def index
    @on_stages = @french_scene.on_stages

    json_response(@on_stages.as_json(include: [:character, :character_group, :user]))
  end

  # GET /on_stages/1
  def show
    render json: @on_stage
  end

  # POST /on_stages
  def create
    @on_stage = OnStage.new(on_stage_params)

    if @on_stage.save
      json_response(@on_stage.as_json(include: [:character, :character_group, :user]))
    else
      render json: @on_stage.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /on_stages/1
  def update
    if @on_stage.update(on_stage_params)
      json_response(@on_stage.as_json(include: [:character, :character_group, :user]))
    else
      render json: @on_stage.errors, status: :unprocessable_entity
    end
  end

  # DELETE /on_stages/1
  def destroy
    @on_stage.destroy
    head :no_content
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_french_scene
      @french_scene = FrenchScene.find(params[:french_scene_id])
    end

    def set_on_stage
      @on_stage = OnStage.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def on_stage_params
      params.require(:on_stage).permit(
        :category,
        :character_id,
        :character_group_id,
        :description,
        :french_scene_id,
        :nonspeaking,
        :user_id,
      )
    end
end
