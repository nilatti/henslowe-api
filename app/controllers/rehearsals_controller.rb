class RehearsalsController < ApiController
  before_action :set_rehearsal, only: [:show, :update, :destroy]
  before_action :set_parent
  # GET /acts
  def index
    @rehearsals = @parent.rehearsals
    render json: @rehearsals.as_json(include: [:users, acts: {include: :scenes, methods: [:find_on_stages]},  french_scenes: {methods: [:pretty_name, :find_on_stages]}, scenes: {methods: [:pretty_name, :find_on_stages]}])
  end

  # GET /acts/1
  def show
    render json: @rehearsal.as_json(include: [:acts, :users, french_scenes: {methods: :pretty_name}, scenes: {methods: :pretty_name}])
  end

  # POST /acts
  def create
    @rehearsal = Rehearsal.new(rehearsal_params)
    if @rehearsal.save
      json_response(@rehearsal.as_json(include: [:users, acts: {include: :scenes, methods: [:find_on_stages]},  french_scenes: {methods: [:pretty_name, :find_on_stages]}, scenes: {methods: [:pretty_name, :find_on_stages]}]))
    else
      render json: @rehearsal.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /acts/1
  def update
    @rehearsal.update(rehearsal_params)
    json_response(@rehearsal.as_json(include: [:users, acts: {include: :scenes, methods: [:find_on_stages]},  french_scenes: {methods: [:pretty_name, :find_on_stages]}, scenes: {methods: [:pretty_name, :find_on_stages]}]))
  end

  # DELETE /acts/1
  def destroy
    @rehearsal.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_parent
      if params[:production_id]
        @parent = Production.find(params[:production_id])
        @parent_type = 'production'
      elsif params[:act_id]
        @parent = Act.find(params[:act_id])
        @parent_type = 'act'
      elsif params[:scene_id]
        @parent = Scene.find(params[:scene_id])
        @parent_type = 'scene'
      elsif params[:french_scene_id]
        @parent = FrenchScene.find(params[:french_scene_id])
        @parent_type = 'french_scene'
      end
    end

    def set_rehearsal
      @rehearsal = Rehearsal.includes(:acts, :french_scenes, :scenes).find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def rehearsal_params
      params.require(:rehearsal).permit(
        :end_time,
        :notes,
        :production_id,
        :space_id,
        :start_time,
        :text_unit,
        :title,
        act_ids: [],
        french_scene_ids: [],
        scene_ids: [],
        user_ids: [],
      )
    end
end
