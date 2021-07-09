class ActsController < ApiController
  before_action :set_act, only: [:show, :update, :destroy, :act_script]
  before_action :set_play
  # GET /acts
  def index
    if @play
      @acts = Act.where(play_id: @play.id).order('number')
    else
      @acts = Act.all
    end

    render json: @acts.as_json(include: %i[scenes])
  end

  # GET /acts/1
  def show
    render json: @act.as_json(include: {scenes: { include: :french_scenes } })
  end

  # POST /acts
  def create
    @act = Act.new(act_params)

    if @act.save
      render json: @act.as_json(include: :scenes), status: :created, location: @play
    else
      render json: @act.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /acts/1
  def update
    if @act.update(act_params)
      render json: @act
    else
      render json: @act.errors, status: :unprocessable_entity
    end
  end

  # DELETE /acts/1
  def destroy
    @act.destroy
  end

  def act_script
    render json: @act.as_json(include:
      [
        scenes: {
          include: [
            french_scenes: {
              include: [
                :stage_directions,
                :sound_cues,
                lines: {
                  include: [:character, :words]
                }
              ]
            }
          ]
        }
      ]
    )
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_play
      if params[:play_id]
        @play = Play.find(params[:play_id])
      end
    end

    def set_act
      @act = Act.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def act_params
      params.require(:act).permit(:number, :end_page, :play_id, :start_page, :summary)
    end

end
