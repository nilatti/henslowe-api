# spec/requests/plays_spec.rb
require 'rails_helper'

RSpec.describe 'OnStages API' do
  # Initialize the test data
  let!(:user) { create(:user)}
  let!(:french_scene) { create(:french_scene) }
  let!(:french_scene_id) { french_scene.id}
  let!(:character) {create(:character)}
  let!(:on_stage) { create(:on_stage, french_scene: french_scene)}
  let!(:id) { on_stage.id }

  # Test suite for GET /french_scenes/:french_scene_id/on_stages
  describe 'GET api/french_scenes/:french_scene_id/on_stages' do
    before {
      get "/api/french_scenes/#{french_scene_id}/on_stages", params: {on_stage: {french_scene_id: french_scene_id, character_id: character.id}}, as: :json, headers: authenticated_header(user)
    }

    context 'when french_scene exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns character' do
        expect(json[0]['character']['id']).to be > 0
      end
    end
  end

  # Test suite for GET /french_scenes/:french_scene_id/on_stages/:id
  describe 'GET /french_scenes/:french_scene_id/on_stages/:id' do
    before {
      get "/api/french_scenes/#{french_scene_id}/on_stages/#{id}", as: :json, headers: authenticated_header(user)
    }

    context 'when entrance exit exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the entrance exit' do
        expect(json['id']).to eq(id)
      end
    end

    context 'when entrance exit does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find OnStage/)
      end
    end
  end

  # Test suite for POST /french_scenes/:french_scene_id/on_stages
  describe 'POST /french_scenes/:french_scene_id/on_stages' do
    let(:valid_attributes) {{ on_stage: { character_id: character.id, french_scene_id: french_scene_id } }}

    context 'when request attributes are valid' do
      before { post "/api/french_scenes/#{french_scene_id}/on_stages", params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    # context 'when an invalid request' do
    #   before {
    #     post "/api/french_scenes/#{french_scene_id}/on_stages",
    #     params: {
    #       on_stage: {
    #         french_scene_id: french_scene_id,
    #
    #         }
    #       },
    #     headers: authenticated_header(user)
    #   }
    #
    #   it 'returns status code 422' do
    #     puts(response.body)
    #     expect(response).to have_http_status(422)
    #   end
    #
    #   it 'returns a failure message' do
    #     expected_response = "{\"on_stage\":[\"Must have character or character group\"]}"
    #     expect(response.body).to match(expected_response)
    #   end
    # end
  end

  # Test suite for PUT /on_stages/:id
  describe 'PUT /api/on_stages/:id' do
    let(:valid_attributes) { { on_stage: { character_id: character.id } } }

    before { put "/api/on_stages/#{id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

    context 'when on_stages exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'updates the on_stages' do
        updated_on_stage = OnStage.find(id)
        expect(updated_on_stage.character.id).to match(character.id)
      end
    end

    context 'when the entrance exit does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find OnStage/)
      end
    end
  end

  # Test suite for DELETE /on_stages/:id
  describe 'DELETE /on_stages/:id' do
    before {
      delete "/api/on_stages/#{id}", as: :json, headers: authenticated_header(user)
    }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
