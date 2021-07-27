# spec/requests/plays_spec.rb
require 'rails_helper'

RSpec.describe 'Scenes API' do
  # Initialize the test data
  let!(:user) { create(:user)}
  let!(:play) { create(:play) }
  let!(:act_id) { play.acts.first.id }
  let!(:id) { play.acts.first.scenes.first.id }

  let!(:french_scene) { play.acts.first.scenes.first.french_scenes.first }
  let!(:sound_cues) {create_list(:sound_cue, 3, french_scene: french_scene)}
  let!(:lines) {create_list(:line, 10, french_scene: french_scene)}
  let!(:stage_directions) {create_list(:stage_direction, 9, french_scene: french_scene)}

  # Test suite for GET /acts/:act_id/scenes
  describe 'GET api/acts/:act_id/scenes' do
    before {
      get "/api/acts/#{act_id}/scenes", params: {act_id: act_id}, as: :json, headers: authenticated_header(user)
    }

    context 'when scene exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all scenes' do
        expect(json.size).to eq(3)
      end
    end
  end

  # Test suite for GET /acts/:act_id/scenes/:id
  describe 'GET /acts/:act_id/scenes/:id' do
    before {
      get "/api/acts/#{act_id}/scenes/#{id}", as: :json, headers: authenticated_header(user)
    }

    context 'when scene exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the scene' do
        expect(json['id']).to eq(id)
      end

      it 'has french scenes' do
        expect(json['french_scenes'].size).to eq(3)
      end
    end

    context 'when scene does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Scene/)
      end
    end
  end

  # Test suite for POST /acts/:act_id/scenes
  describe 'POST /acts/:act_id/scenes' do
    let(:valid_attributes) { { scene: { number: 1, act_id: act_id } } }

    context 'when request attributes are valid' do
      before { post "/api/acts/#{act_id}/scenes", params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when an invalid request' do
      before { post "/api/acts/#{act_id}/scenes", params: { scene: { summary: 'Baby', act_id: act_id } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expected_response = "{\"number\":[\"can't be blank\"]}"
        expect(response.body).to match(expected_response)
      end
    end
  end

  # Test suite for PUT /scenes/:id
  describe 'PUT /api/scenes/:id' do
    let(:valid_attributes) { { scene: { number: 2 } } }

    before { put "/api/scenes/#{id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

    context 'when scene exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'updates the scene' do
        updated_scene = Scene.find(id)
        expect(updated_scene.number).to match(2)
      end
    end

    context 'when the scene does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Scene/)
      end
    end
  end

  # Test suite for DELETE /scenes/:id
  describe 'DELETE /scenes/:id' do
    before {
      delete "/api/scenes/#{id}", headers: authenticated_header(user)
    }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
  describe 'gets scene script' do
    before { get "/api/scenes/#{id}/scene_script", params: {scene: id}, headers: authenticated_header(user) }
    it 'returns status 200' do
      expect(response).to have_http_status(200)
    end
    it 'returns all the info' do
      expect(json['french_scenes'].size).to eq(3)
      expect(json['french_scenes'][0]['id']).to eq(french_scene.id)
      expect(json['french_scenes'][0]['sound_cues'].size).to eq(3)
      expect(json['french_scenes'][0]['lines'].size).to eq(10)
      expect(json['french_scenes'][0]['stage_directions'].size).to eq(9)
      expect(json['french_scenes'][0]['lines'][0]['character']).not_to be_empty
    end
  end

  describe 'gets scene script' do
    before { get "/api/scenes/#{id}/scene_script", headers: authenticated_header(user)}
    it 'returns status 200' do
      expect(response).to have_http_status(200)
    end
    it 'returns all the french scenes' do
      expect(json['french_scenes'].size).to eq(3)
      expect(json['french_scenes'][0]['id']).to eq(french_scene.id)
      expect(json['french_scenes'][0]['sound_cues'].size).to eq(3)
      expect(json['french_scenes'][0]['lines'].size).to eq(10)
      expect(json['french_scenes'][0]['stage_directions'].size).to eq(9)
      expect(json['french_scenes'][0]['lines'][0]['character']).not_to be_empty
    end
  end
end
