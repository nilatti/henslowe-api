# spec/requests/plays_spec.rb
require 'rails_helper'

RSpec.describe 'Characters API' do
  # Initialize the test data

  let!(:author) { create(:author) }
  let!(:play) { create(:play, author_id: author.id) }
  let!(:id) { play.characters.first.id }
  let!(:user) { create(:user)}
  # Test suite for GET /plays/:play_id/characters
  describe 'GET api/plays/:play_id/characters' do
    before {
      get "/api/plays/#{play.id}/characters", params: {play_id: play.id}, headers: authenticated_header(user)
    }

    context 'when play exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all characters' do
        expect(json.size).to eq(3)
      end
    end
  end

  # Test suite for GET /plays/:play_id/characters/:id
  describe 'GET /plays/:play_id/characters/:id' do
    before { get "/api/plays/#{play.id}/characters/#{id}", headers: authenticated_header(user) }

    context 'when character exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the character' do
        expect(json['id']).to eq(id)
      end
    end

    context 'when character does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Character/)
      end
    end
  end

  # Test suite for PUT /plays/:play_id/characters
  describe 'POST /plays/:play_id/characters' do
    let(:valid_attributes) { { character: { name: 'Richard, Duke of Gloucester', play_id: play.id } } }

    context 'when request attributes are valid' do
      before { post "/api/plays/#{play.id}/characters", params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when an invalid request' do
      before { post "/api/plays/#{play.id}/characters", params: { character: { age: 'Baby', play_id: play.id } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expected_response = "{\"name\":[\"can't be blank\"]}"
        expect(response.body).to match(expected_response)
      end
    end
  end

  # Test suite for PUT /plays/:play_id/characters/:id
  describe 'PUT /api/plays/:play_id/characters/:id' do
    let(:valid_attributes) { { character: { name: 'Lady Elizabeth Grey' } } }

    before { put "/api/plays/#{play.id}/characters/#{id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

    context 'when character exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'updates the character' do
        updated_character = Character.find(id)
        expect(updated_character.name).to match(/Lady Elizabeth Grey/)
      end
    end

    context 'when the character does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Character/)
      end
    end
  end

  # Test suite for DELETE /characters/:id
  describe 'DELETE /characters/:id' do
    before { delete "/api/plays/#{play.id}/characters/#{id}", headers: authenticated_header(user) }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
