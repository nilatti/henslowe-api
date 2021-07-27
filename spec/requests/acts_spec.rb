# spec/requests/plays_spec.rb
require 'rails_helper'

RSpec.describe 'Acts API' do
  # Initialize the test data
  let!(:author) { create(:author) }
  let!(:play) { create(:play, author_id: author.id) }
  let!(:act) {play.acts.first}
  let!(:id) { act.id }

  let!(:user) { create(:user)}
  let!(:scene) { act.scenes.first }
  let!(:french_scene) { scene.french_scenes.first }
  let!(:sound_cues) {create_list(:sound_cue, 3, french_scene: french_scene)}
  let!(:lines) {create_list(:line, 10, french_scene: french_scene)}
  let!(:stage_directions) {create_list(:stage_direction, 9, french_scene: french_scene)}
  # Test suite for GET /plays/:play_id/characters
  describe 'GET api/plays/:play_id/acts' do
    before {
      get "/api/plays/#{play.id}/acts", params: {play_id: play.id}, headers: authenticated_header(user)
    }

    context 'when play exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all acts' do
        expect(json.size).to eq(3)
      end

    end
  end

  # Test suite for GET /plays/:play_id/acts/:id
  describe 'GET /acts/:id' do
    before {
      get "/api/acts/#{id}", headers: authenticated_header(user)
    }

    context 'when act exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the act' do
        expect(json['id']).to eq(id)
      end

      it 'has scenes, characters, and french scenes' do
        expect(json['scenes'].size).to eq(3)
        expect(json['scenes'][0]['french_scenes'].size).to eq(3)
      end
    end

    context 'when act does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Act/)
      end
    end
  end

  # Test suite for PUT /plays/:play_id/characters
  describe 'POST /plays/:play_id/acts' do
    let(:valid_attributes) { { number: 1, play_id: play.id } }

    context 'when request attributes are valid' do
      before {
        post "/api/plays/#{play.id}/acts", params: valid_attributes, as: :json, headers: authenticated_header(user)
      }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when an invalid request' do
      before { post "/api/plays/#{play.id}/acts", params: { act: { summary: 'Baby', play_id: play.id } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expected_response = "{\"number\":[\"can't be blank\"]}"
        expect(response.body).to match(expected_response)
      end
    end
  end

  # Test suite for PUT /plays/:play_id/characters/:id
  describe 'PUT /api/acts/:id' do
    let(:valid_attributes) { { "act"=>{"number"=>2, "play_id"=>play.id} } }

    before { put "/api/acts/#{id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

    context 'when act exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'updates the act' do
        updated_act = Act.find(id)
        expect(updated_act.number).to match(2)
      end
    end

    context 'when the character does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Act/)
      end
    end
  end

  # Test suite for DELETE /acts/:id
  describe 'DELETE /acts/:id' do
    before { delete "/api/acts/#{id}", headers: authenticated_header(user) }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end

  describe 'gets act script' do
    before { get "/api/acts/#{id}/act_script", headers: authenticated_header(user)}
    it 'returns status 200' do
      expect(response).to have_http_status(200)
    end
    it 'returns all the scenes' do
      expect(json['scenes'].size).to eq(3)
      scene = json['scenes'].first
      expect(scene['french_scenes'].size).to eq(3)
      expect(scene['french_scenes'][0]['id']).to eq(french_scene.id)
      expect(scene['french_scenes'][0]['sound_cues'].size).to eq(3)
      expect(scene['french_scenes'][0]['lines'].size).to eq(10)
      expect(scene['french_scenes'][0]['stage_directions'].size).to eq(9)
      expect(scene['french_scenes'][0]['lines'][0]['character']).not_to be_empty
    end
  end
end
