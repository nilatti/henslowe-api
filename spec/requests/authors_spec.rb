require 'rails_helper'

RSpec.describe 'Authors API', type: :request do
  # initialize test data

  let!(:authors) { create_list(:author, 4) }
  let(:author_id) { authors.first.id }
  let!(:user) { create(:user)}
  # Test suite for GET /authors
  describe 'GET /authors' do
    # make HTTP get request before each example
    before { get '/api/authors', headers: authenticated_header(user) }

    it 'returns authors' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json).not_to be_empty
      expect(json.size).to eq(4)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /authors/:id
  describe 'GET api/authors/:id' do
    before { get "/api/authors/#{author_id}", headers: authenticated_header(user) }
    context 'when the record exists' do
      it 'returns the author' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(author_id)
        expect(json['plays'].size).to eq(3)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:author_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Author/)
      end
    end
  end

  # Test suite for POST /authors
  describe 'POST /authors' do
    # valid payload
    let(:valid_attributes) { { author: { first_name: 'Pam', last_name: 'Mandigo' } } }

    context 'when the request is valid' do
      before { post '/api/authors', params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'creates a author' do
        expect(json['last_name']).to eq('Mandigo')
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      before { post '/api/authors', params: { author: { first_name: 'Failure' } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(response.body)
          .to match(/Validation failed: Last name can't be blank/)
      end
    end
  end

  # Test suite for PUT /authors/:id
  describe 'PUT /api/authors/:id' do
    let(:valid_attributes) { { author: { first_name: 'Pam', last_name: 'Mandigo' } } }

    context 'when the record exists' do
      before { put "/api/authors/#{author_id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /authors/:id
  describe 'DELETE /authors/:id' do
    before {
      delete "/api/authors/#{author_id}", headers: authenticated_header(user)
    }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end

  # Test suite for author_names
  describe 'GET /api/authors/author_names' do
    before { get '/api/authors/author_names', headers: authenticated_header(user) }

    it 'returns authors ONLY NAMES' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json.first['first_name']).not_to be_empty
      expect(json.first['birthdate']).to be_nil
      expect(json).not_to be_empty
      expect(json.size).to eq(4)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end
end
