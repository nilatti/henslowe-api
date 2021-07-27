require 'rails_helper'

RSpec.describe 'StageExits API', type: :request do
  # initialize test data
  let!(:production) { create(:production)}
  let!(:stage_exits) { create_list(:stage_exit, 4, production: production) }
  let(:stage_exit_id) { stage_exits.first.id }
  let!(:user) { create(:user)}
  # Test suite for GET /stage_exits
  describe 'GET /stage_exits' do
    # make HTTP get request before each example
    before { get "/api/productions/#{production.id}/stage_exits", headers: authenticated_header(user) }

    it 'returns stage_exits' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json).not_to be_empty
      expect(json.size).to eq(4)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /stage_exits/:id
  describe 'GET api/stage_exits/:id' do
    before { get "/api/stage_exits/#{stage_exit_id}", headers: authenticated_header(user) }
    context 'when the record exists' do
      it 'returns the stage_exit' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(stage_exit_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:stage_exit_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find StageExit/)
      end
    end
  end

  # Test suite for POST /stage_exits
  describe 'POST /stage_exits' do
    # valid payload
    let(:valid_attributes) { { stage_exit: {name: "up center", production_id: production.id}} }

    context 'when the request is valid' do
      before {
        post "/api/productions/#{production.id}/stage_exits", params: valid_attributes, as: :json, headers: authenticated_header(user)
      }

      it 'creates a stage_exit' do
        expect(json['name']).to be_truthy
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      before { post "/api/productions/#{production.id}/stage_exits", params: { stage_exit: { name: '' } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(response.body)
          .to match("{\"production\":[\"must exist\"],\"name\":[\"can't be blank\"]}")
      end
    end
  end

  # Test suite for PUT /stage_exits/:id
  describe 'PUT /api/productions/stage_exits/:id' do
    let(:valid_attributes) { { stage_exit: attributes_for(:stage_exit, name: "BE LOUDER") } }

    context 'when the record exists' do
      before { put "/api/stage_exits/#{stage_exit_id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /stage_exits/:id
  describe 'DELETE /stage_exits/:id' do
    before {
      delete "/api/stage_exits/#{stage_exit_id}", headers: authenticated_header(user)
    }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end

end
