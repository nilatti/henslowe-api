require 'rails_helper'

RSpec.describe 'Specializations API', type: :request do
  # initialize test data
  let!(:user) { create(:user)}
  let!(:specializations) { create_list(:specialization, 4) }
  let(:specialization_id) { specializations.first.id }

  # Test suite for GET /specializations
  describe 'GET /specializations' do
    # make HTTP get request before each example
    before { get '/api/specializations', headers: authenticated_header(user) }

    it 'returns specializations' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json).not_to be_empty
      expect(json.size).to eq(4)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /specializations/:id
  describe 'GET api/specializations/:id' do
    before { get "/api/specializations/#{specialization_id}", headers: authenticated_header(user) }
    context 'when the record exists' do
      it 'returns the specialization' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(specialization_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:specialization_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Specialization/)
      end
    end
  end

  # Test suite for POST /specializations
  describe 'POST /specializations' do
    # valid payload
    let(:valid_attributes) { { specialization: { title: 'Chief Whimsey Officer' } } }

    context 'when the request is valid' do
      before { post '/api/specializations', params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'creates a specialization' do
        expect(json['title']).to eq('Chief Whimsey Officer')
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      before { post '/api/specializations', params: { specialization: { seating_capacity: 5 } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(response.body)
          .to match("{\"title\":[\"can't be blank\"]}")
      end
    end
  end

  # Test suite for PUT /specializations/:id
  describe 'PUT /api/specializations/:id' do
    let(:valid_attributes) { { specialization: { title: 'Grand Vizier' } } }

    context 'when the record exists' do
      before { put "/api/specializations/#{specialization_id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /specializations/:id
  describe 'DELETE /specializations/:id' do
    before {
      delete "/api/specializations/#{specialization_id}", headers: authenticated_header(user)
    }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
