# spec/requests/plays_spec.rb
require 'rails_helper'

RSpec.describe 'EntranceExits API' do
  # Initialize the test data
  let!(:user) { create(:user)}
  let!(:french_scene) { create(:french_scene) }
  let!(:french_scene_id) { french_scene.id}
  let!(:stage_exit) {create(:stage_exit)}
  let!(:entrance_exit) { create(:entrance_exit, :with_character, french_scene: french_scene)}
  let!(:id) { entrance_exit.id }

  # Test suite for GET /french_scenes/:french_scene_id/entrance_exits
  describe 'GET api/scenes/:french_scene_id/entrance_exits' do
    before {
      get "/api/french_scenes/#{french_scene_id}/entrance_exits", params: {french_scene_id: french_scene_id}, as: :json, headers: authenticated_header(user)
    }

    context 'when french_scene exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns multiple characters' do
        expect(json[0]['characters'].size).to eq(3)
      end
    end
  end

  # Test suite for GET /french_scenes/:french_scene_id/entrance_exits/:id
  describe 'GET /french_scenes/:french_scene_id/entrance_exits/:id' do
    before {
      get "/api/french_scenes/#{french_scene_id}/entrance_exits/#{id}", headers: authenticated_header(user)
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
        expect(response.body).to match(/Couldn't find EntranceExit/)
      end
    end
  end

  # Test suite for POST /french_scenes/:french_scene_id/entrance_exits
  describe 'POST /french_scenes/:french_scene_id/entrance_exits' do
    let(:valid_attributes) { { entrance_exit: { page: 1, category: "entrance", stage_exit_id: stage_exit.id, french_scene_id: french_scene_id } } }

    context 'when request attributes are valid' do
      before { post "/api/french_scenes/#{french_scene_id}/entrance_exits", params: valid_attributes, as: :json, headers: authenticated_header(user)}

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    # context 'when an invalid request' do
    #   before { post "/api/french_scenes/#{french_scene_id}/entrance_exits", params: { entrance_exit: { page: 1, category: nil, stage_exit_id: nil, french_scene_id: french_scene_id } }, headers: authenticated_header(user) }
    #
    #   it 'returns status code 422' do
    #     expect(response).to have_http_status(422)
    #   end
    #
    #   it 'returns a failure message' do
    #     expected_response = "{\"stage_exit\":[\"must exist\",\"can't be blank\"],\"category\":[\"can't be blank\"]}"
    #     expect(response.body).to match(expected_response)
    #   end
    # end
  end

  # Test suite for PUT /entrance_exits/:id
  describe 'PUT /api/entrance_exits/:id' do
    let(:valid_attributes) { { entrance_exit: { page: 2 } } }

    before { put "/api/entrance_exits/#{id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

    context 'when entrance_exits exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'updates the entrance_exits' do
        updated_entrance_exit = EntranceExit.find(id)
        expect(updated_entrance_exit.page).to match(2)
      end
    end

    context 'when the entrance exit does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find EntranceExit/)
      end
    end
  end

  # Test suite for DELETE /entrance_exits/:id
  describe 'DELETE /entrance_exits/:id' do
    before {
      delete "/api/entrance_exits/#{id}", headers: authenticated_header(user)
    }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
