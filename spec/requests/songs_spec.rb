require 'rails_helper'

RSpec.describe 'Songs API' do
  let!(:user) { create(:user) }
  let!(:french_scene) { create(:french_scene) }
  let!(:french_scene_id) { french_scene.id }
  let!(:character) { create(:character) }
  let!(:song) { create(:song, french_scene: french_scene) }
  let!(:id) { song.id }

  describe 'GET /api/v1/french_scenes/:french_scene_id/songs' do
    before { get "/api/v1/french_scenes/#{french_scene_id}/songs", as: :json, headers: authenticated_header(user) }

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end

    it 'returns all songs for the french scene' do
      expect(json.length).to eq(1)
      expect(json[0]['id']).to eq(id)
    end

    it 'includes characters in the response' do
      expect(json[0]).to have_key('characters')
    end
  end

  describe 'POST /api/v1/french_scenes/:french_scene_id/songs' do
    let(:valid_attributes) { { song: { title: 'Consider Yourself', character_ids: [character.id] } } }

    context 'when request attributes are valid' do
      before { post "/api/v1/french_scenes/#{french_scene_id}/songs", params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'returns the created song with title' do
        expect(json['title']).to eq('Consider Yourself')
      end

      it 'returns the song with its characters' do
        expect(json['characters'].map { |c| c['id'] }).to include(character.id)
      end
    end

    context 'when title is missing' do
      before { post "/api/v1/french_scenes/#{french_scene_id}/songs", params: { song: { title: '' } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end
    end
  end

  describe 'PUT /api/v1/songs/:id' do
    context 'when the song exists' do
      before { put "/api/v1/songs/#{id}", params: { song: { title: 'Food, Glorious Food' } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'updates the title' do
        expect(Song.find(id).title).to eq('Food, Glorious Food')
      end
    end

    context 'when updating characters' do
      before { put "/api/v1/songs/#{id}", params: { song: { character_ids: [character.id] } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'assigns the characters' do
        expect(Song.find(id).characters).to include(character)
      end
    end

    context 'when the song does not exist' do
      before { put "/api/v1/songs/0", params: { song: { title: 'Test' } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'DELETE /api/v1/songs/:id' do
    before { delete "/api/v1/songs/#{id}", as: :json, headers: authenticated_header(user) }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end

    it 'removes the song' do
      expect(Song.exists?(id)).to be false
    end
  end
end
