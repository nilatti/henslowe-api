module Api
  module V1
    class SongsController < ApiController
      before_action :set_french_scene, only: [:index, :create]
      before_action :set_song, only: [:update, :destroy, :move]

      def index
        json_response(@french_scene.songs.as_json(include: [:characters, :character_groups]))
      end

      def create
        @song = @french_scene.songs.build(song_params)
        if @song.save
          json_response(@song.as_json(include: [:characters, :character_groups]), :created)
        else
          render json: @song.errors, status: :unprocessable_entity
        end
      end

      def update
        if @song.update(song_params)
          json_response(@song.as_json(include: [:characters, :character_groups]))
        else
          render json: @song.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @song.destroy
        head :no_content
      end

      def move
        case params[:direction]
        when 'up'   then @song.move_higher
        when 'down' then @song.move_lower
        else render json: { error: 'direction must be up or down' }, status: :unprocessable_entity and return
        end
        json_response(@song.french_scene.songs.as_json(include: [:characters, :character_groups]))
      end

      private

      def set_french_scene
        @french_scene = FrenchScene.find(params[:french_scene_id])
      end

      def set_song
        @song = Song.find(params[:id])
      end

      def song_params
        params.require(:song).permit(:title, character_ids: [], character_group_ids: [])
      end
    end
  end
end
