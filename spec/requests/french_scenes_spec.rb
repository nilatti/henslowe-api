# spec/requests/plays_spec.rb
require 'rails_helper'

RSpec.describe 'French Scenes API' do
  # Initialize the test data

  let!(:user) { create(:user)}
  let!(:author) { create(:author) }
  let!(:play) { create(:play, author_id: author.id) }
  let!(:scene_id) { play.acts.first.scenes.first.id }
  let!(:id) { play.acts.first.scenes.first.french_scenes.first.id }
  let!(:french_scene) { play.acts.first.scenes.first.french_scenes.first }
  let!(:character) {play.characters.first}
  let!(:character_group) {play.character_groups.first}
  let!(:on_stage) { create(:on_stage, french_scene: french_scene, character_id: character.id)}
  let!(:sound_cues) {create_list(:sound_cue, 3, french_scene: french_scene)}
  let!(:lines) {create_list(:line, 10, french_scene: french_scene)}
  let!(:stage_directions) {create_list(:stage_direction, 9, french_scene: french_scene)}
  # Test suite for GET /scenes/:scene_id/french_scenes
  describe 'GET api/scenes/:scene_id/french_scenes' do
    before {
      get "/api/scenes/#{scene_id}/french_scenes", params: {scene_id: scene_id}, as: :json, headers: authenticated_header(user)
    }

    context 'when scene exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all french_scenes' do
        expect(json.size).to eq(3)
      end
    end
  end

  # Test suite for GET /scenes/:scene_id/french_scenes/:id
  describe 'GET /scenes/:scene_id/french_scenes/:id' do
    before {
      get "/api/scenes/#{scene_id}/french_scenes/#{id}", as: :json, headers: authenticated_header(user)
    }

    context 'when french_scene exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the french scene' do
        expect(json['id']).to eq(id)
      end

      it 'returns characters' do
        expect(json['characters'].size).to eq(1)
      end

      it 'returns on_stages' do
        expect(json['on_stages'].size).to eq(1)
      end
    end

    context 'when french scene does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find FrenchScene/)
      end
    end
  end

  # Test suite for POST /scenes/:scene_id/french_scenes
  describe 'POST /scenes/:scene_id/french_scenes' do
    let(:valid_attributes) { { french_scene: { number: 1, scene_id: scene_id, character_ids: [ character.id ] } } }

    context 'when request attributes are valid' do
      before { post "/api/scenes/#{scene_id}/french_scenes", params: valid_attributes, as: :json, headers: authenticated_header(user)}

      it 'returns status code 201' do
        expect(response).to have_http_status(200)
      end
      it 'creates an on_stage for character' do
        french_scene = FrenchScene.find(json['id'])
        expect(french_scene.on_stages.size).to eq(1)
        expect(french_scene.on_stages.last.character.id).to eq(character.id)
      end
    end

    context 'when an invalid request' do
      before { post "/api/scenes/#{scene_id}/french_scenes", params: { french_scene: { summary: 'Baby', scene_id: scene_id } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expected_response = "{\"number\":[\"can't be blank\"]}"
        expect(response.body).to match(expected_response)
      end
    end
  end

  # Test suite for PUT /french_scenes/:id
  describe 'PUT /api/french_scenes/:id' do
    let(:valid_attributes) { { french_scene: { number: 'a', character_ids: [ character.id ], character_group_ids: [character_group.id] } } }

    before { put "/api/french_scenes/#{id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

    context 'when french_scene exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'updates the french scene' do
        updated_french_scene = FrenchScene.find(id)
        expect(updated_french_scene.number).to match('a')
        expect(updated_french_scene.characters.size).to eq(1)
        expect(updated_french_scene.character_groups.size).to eq(1)
      end

      it 'updates the french scene to delete a character' do
        put "/api/french_scenes/#{id}", params: { french_scene: { character_ids: [], character_group_ids: [character_group.id]}}, as: :json, headers: authenticated_header(user)
        updated_french_scene = FrenchScene.find(id)
        expect(updated_french_scene.characters).to be_empty
        expect(updated_french_scene.character_groups.size).to eq(1)
      end
    end

    context 'when the french scene does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find FrenchScene/)
      end
    end
  end

  # Test suite for DELETE /french_scenes/:id
  describe 'DELETE /french_scenes/:id' do
    before {
      delete "/api/french_scenes/#{id}", as: :json, headers: authenticated_header(user)
    }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end

  describe 'gets french scene script' do
    before { get "/api/french_scenes/#{id}/french_scene_script", headers: authenticated_header(user)}
    it 'returns status 200' do
      expect(response).to have_http_status(200)
    end
    it 'returns all the components' do
      expect(json['sound_cues'].size).to eq(3)
      expect(json['stage_directions'].size).to eq(9)
      expect(json['lines'].size).to eq(10)
      expect(json['lines'][0]['character']).not_to be_empty
    end
  end
end
