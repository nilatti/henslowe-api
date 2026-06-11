module Api
  module V1
    class SongsController < ApiController
      before_action :set_french_scene, only: [:index, :create]
      before_action :set_song, only: [:update, :destroy]

      def index
        json_response(@french_scene.songs.as_json(include: :characters))
      end

      def create
        @song = @french_scene.songs.build(song_params)
        if @song.save
          json_response(@song.as_json(include: :characters), :created)
        else
          render json: @song.errors, status: :unprocessable_entity
        end
      end

      def update
        if @song.update(song_params)
          json_response(@song.as_json(include: :characters))
        else
          render json: @song.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @song.destroy
        head :no_content
      end

      private

      def set_french_scene
        @french_scene = FrenchScene.find(params[:french_scene_id])
      end

      def set_song
        @song = Song.find(params[:id])
      end

      def song_params
        params.require(:song).permit(:title, character_ids: [])
      end
    end
  end
end
