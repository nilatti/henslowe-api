module Api
  module V1
class CharactersController < ApiController
  before_action :set_character, only: [:show, :update, :destroy]
  before_action :set_play
  # GET /acts
  def index
    @characters = Character.where(play_id: @play.id)

    render json: @characters.as_json
  end

  # GET /acts/1
  def show
    render json: @character.as_json
  end

  # POST /acts
  def create
    @character = Character.new(character_params)

    if @character.save
      render json: @character, status: :created
    else
      render json: @character.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /acts/1
  def update
    if @character.update(character_params)
      render json: @character
    else
      render json: @character.errors, status: :unprocessable_entity
    end
  end

  # DELETE /acts/1
  def destroy
    @character.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_play
      if params[:play_id]
        @play = Play.find(params[:play_id])
      end
    end

    def set_character
      @character = Character.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def character_params
      params.require(:character).permit(:age, :description, :gender, :name, :play_id)
    end

end
  end
end
