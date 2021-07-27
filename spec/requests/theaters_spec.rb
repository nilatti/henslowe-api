require 'rails_helper'

RSpec.describe 'theaters API', type: :request do
  # initialize test data
  let!(:theaters) { create_list(:theater, 10, :has_spaces) }
  let(:theater_id) { theaters.first.id }
  let!(:user) { create(:user)}
  # Test suite for GET /theaters
  describe 'GET /theaters' do
    # make HTTP get request before each example
    before { get '/api/theaters', headers: authenticated_header(user) }

    it 'returns theaters' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json).not_to be_empty
      expect(json.size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /theaters/:id
  describe 'GET api/theaters/:id' do
    before { get "/api/theaters/#{theater_id}", headers: authenticated_header(user) }
    context 'when the record exists' do
      it 'returns the theater' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(theater_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'includes spaces' do
        expect(json['spaces'].size).to eq(3)
      end
    end

    context 'when the record does not exist' do
      let(:theater_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Theater/)
      end
    end
  end

  # Test suite for POST /theaters
  describe 'POST /theaters' do
    # valid payload
    let(:valid_attributes) { { theater: { name: 'The Great American Theater Company' } } }

    context 'when the request is valid' do
      before { post '/api/theaters', params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'creates a theater' do
        expect(json['name']).to eq('The Great American Theater Company')
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      before { post '/api/theaters', params: { theater: { address: 'Failure' } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(response.body)
          .to match(/Validation failed: Name can't be blank/)
      end
    end
  end

  # Test suite for PUT /theaters/:id
  describe 'PUT /api/theaters/:id' do
    let(:valid_attributes) { { theater: { name: 'The Great American Theater Company' } } }

    context 'when the record exists' do
      before { put "/api/theaters/#{theater_id}", params: valid_attributes, as: :json, headers: authenticated_header(user)}

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /theaters/:id
  describe 'DELETE /theaters/:id' do
    before { delete "/api/theaters/#{theater_id}", headers: authenticated_header(user) }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end

  # Test suite for theater_names
  describe 'GET /api/theaters/theater_names' do
    before { get '/api/theaters/theater_names', headers: authenticated_header(user) }

    it 'returns theaters ONLY NAMES' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json.first['name']).not_to be_empty
      expect(json.first['address']).to be_nil
      expect(json).not_to be_empty
      expect(json.size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end
end
