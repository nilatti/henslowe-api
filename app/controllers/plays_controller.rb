class PlaysController < ApiController
  before_action :authenticate_user!
  before_action :set_author, only: [:index, :create]
  before_action :set_play, only: %i[
    show 
    update 
    destroy 
    play_script 
    play_skeleton 
    play_act_on_stages 
    play_french_scene_on_stages 
    play_on_stages
    play_scene_on_stages
  ]
  # GET /plays
  def index
    if @author
      render json: PlaySerializer.new(@author.plays).serializable_hash.to_json
    else
      render json: PlaySerializer.new(Play.all).serializable_hash.to_json
    end
  end

  # GET /plays/1
  def show
    render json: PlaySerializer.new(@play, include: [:acts, :author, :words, :characters]).serializable_hash.to_json
  end

  # POST /plays
  def create
    @play = Play.new(play_params)

    if @play.save
      render json: @play, status: :created, location: @author
    else
      render json: @play.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /plays/1
  def update
    @play.update(play_params)
    render json: @play.as_json(include:
      [
        :author,
        :characters,
        :character_groups,
        acts: {
          include: {
            scenes: {
              include: {
                french_scenes: {
                  include: [
                    :characters,
                    :character_groups,
                    entrance_exits: {
                      include: [
                          :stage_exit,
                          :characters,
                          :character_groups,
                        ]
                    },
                    on_stages: {
                      include: [:character, :character_group]
                    }
                  ]
                }
              }
            }
          }
        }
        ]
      )
  end

  # DELETE /plays/1
  def destroy
    @play.destroy
    head :no_content
  end

  def play_act_on_stages
    @acts = Act.play_order(@play.acts)
    render json: @acts.as_json(methods: :find_on_stages)
  end

  def play_french_scene_on_stages
    @french_scenes = FrenchScene.play_order(@play.french_scenes)
    render json: @french_scenes.as_json(include: :on_stages, methods: :pretty_name)
  end

  def play_on_stages
    render json: @play.as_json(methods: :find_on_stages)
  end

  def play_scene_on_stages
    @scenes = Scene.play_order(@play.scenes)
    render json: @scenes.as_json(methods: [:pretty_name, :find_on_stages])
  end

  def play_script
    render json: @play.as_json(include:
      [
        :characters,
        :character_groups,
        acts: {
          include: {
            scenes: {
              include: {
                french_scenes: {
                  include: [
                    :stage_directions,
                    :sound_cues,
                    lines: {
                      include: :character
                    }
                  ]
                }
              }
            }
          }
        }
        ]
      )
  end

  def play_skeleton
    render json: @play.as_json(include: {
      production: {only: [:lines_per_minute]},
      characters: {only: [:name, :id]},
      acts: {include: {scenes: {include: {french_scenes: {only: [:id, :number]}}, only: [:id, :number]}}, only: [:id, :number]}
      },
      only: [:canonical, :id, :title]
    )
  end

  def play_titles
    @plays = Play.where(canonical: true)
    render json: @plays.as_json(only: %i[id title])
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_author
    if params[:play][:author_id]
      puts('has play params with author id')
      @author = Author.find(params[:play][:author_id])
    elsif params[:author_id]
      puts('has author id')
      @author = Author.find(params[:author_id])
    end
  end

  def set_play
    if @author
      @play = @author.plays.find_by!(id: params[:id])
    else
      @play = Play.find(params[:id])
    end

  end

  # Only allow a trusted parameter "white list" through.
  def play_params
    params.require(:play).permit(
      :author_id,
      :canonical,
      :date,
      :synopsis,
      :text_notes,
      :title,
      genre: []
    )
  end
end
