class ScenesController < ApiController
  before_action :set_scene, only: [:show, :update, :destroy, :scene_script]
  before_action :set_act

  # GET /scenes
  def index
    @scenes = Scene.play_order(@act.scenes)

    render json: @scenes
  end

  # GET /scenes/1
  def show
    json_response(@scene.as_json(include: { french_scenes: {include: [:entrance_exits, :on_stages]}}))
  end

  # POST /scenes
  def create
    @scene = Scene.new(scene_params)

    if @scene.save
      render json: @scene.as_json(methods: :pretty_name, include: :french_scenes), status: :created, location: @scene
    else
      render json: @scene.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /scenes/1
  def update
    if @scene.update(scene_params)
      json_response(@scene.as_json(methods: :pretty_name, include: { french_scenes: {include: [:entrance_exits, :on_stages]}}))
    else
      render json: @scene.errors, status: :unprocessable_entity
    end
  end

  # DELETE /scenes/1
  def destroy
    @scene.destroy
  end

  def scene_script
    render json: @scene.as_json(include:
      [
          french_scenes: {
            include: [
              :stage_directions,
              :sound_cues,
              lines: {
                include: [:character, :words]
              }
            ]
          }
        ],
        methods: :pretty_name
      )
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_act
      if params[:act_id]
        @act = Act.find(params[:act_id])
      end
    end

    def set_scene
      @scene = Scene.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def scene_params
      params.require(:scene).permit(:act_id, :end_page, :number, :start_page, :summary)
    end
end
