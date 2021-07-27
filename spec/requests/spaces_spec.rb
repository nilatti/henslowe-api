require 'rails_helper'

RSpec.describe 'Spaces API', type: :request do
  # initialize test data
  let!(:spaces) { create_list(:space, 4, :has_theaters) }
  let(:space_id) { spaces.first.id }
  let!(:user) { create(:user)}

  # Test suite for GET /spaces
  describe 'GET /spaces' do
    # make HTTP get request before each example
    before { get '/api/spaces', headers: authenticated_header(user) }

    it 'returns spaces' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json).not_to be_empty
      expect(json.size).to eq(4)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /spaces/:id
  describe 'GET api/spaces/:id' do
    before { get "/api/spaces/#{space_id}", headers: authenticated_header(user) }
    context 'when the record exists' do
      it 'returns the space' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(space_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'includes theaters' do
        expect(json['theaters'].size).to eq(3)
      end
    end

    context 'when the record does not exist' do
      let(:space_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Space/)
      end
    end
  end

  # Test suite for POST /spaces
  describe 'POST /spaces' do
    # valid payload
    let(:valid_attributes) { { space: { name: 'The Vogelodeon' } } }

    context 'when the request is valid' do
      before { post '/api/spaces', params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'creates a space' do
        expect(json['name']).to eq('The Vogelodeon')
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      before { post '/api/spaces', params: { space: { seating_capacity: 5 } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(response.body)
          .to match("{\"name\":[\"can't be blank\"]}")
      end
    end
  end

  # Test suite for PUT /spaces/:id
  describe 'PUT /api/spaces/:id' do
    let(:valid_attributes) { { space: { name: 'Mandigo Arena' } } }

    context 'when the record exists' do
      before { put "/api/spaces/#{space_id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /spaces/:id
  describe 'DELETE /spaces/:id' do
    before {
      delete "/api/spaces/#{space_id}", headers: authenticated_header(user)
    }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end

  # Test suite for space_names
  describe 'GET /api/spaces/space_names' do
    before { get '/api/spaces/space_names', as: :json, headers: authenticated_header(user) }

    it 'returns spaces ONLY NAMES' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json.first['name']).not_to be_empty
      expect(json.first['seating_capacity']).to be_nil
      expect(json).not_to be_empty
      expect(json.size).to eq(4)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end
end
