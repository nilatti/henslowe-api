# spec/requests/plays_spec.rb
require 'rails_helper'

RSpec.describe 'CharacterGroups API' do
  # Initialize the test data
  let!(:author) { create(:author) }
  let!(:play) { create(:play, author_id: author.id) }
  let!(:id) { play.character_groups.first.id }
  let!(:user) { create(:user)}
  # Test suite for GET /plays/:play_id/character_groups
  describe 'GET api/plays/:play_id/character_groups' do
    before {
      get "/api/plays/#{play.id}/character_groups", params: {play_id: play.id}, headers: authenticated_header(user)
    }

    context 'when play exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all character_groups' do
        expect(json.size).to eq(3)
      end
    end
  end

  # Test suite for GET /plays/:play_id/character_groups/:id
  describe 'GET /plays/:play_id/character_groups/:id' do
    before { get "/api/plays/#{play.id}/character_groups/#{id}", headers: authenticated_header(user) }

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

  # Test suite for PUT /plays/:play_id/character_groups
  describe 'POST /plays/:play_id/character_groups' do
    let(:valid_attributes) { { character_group: { name: 'Richard, Duke of Gloucester', play_id: play.id } } }

    context 'when request attributes are valid' do
      before {
        post "/api/plays/#{play.id}/character_groups",
        params: valid_attributes,
        as: :json, headers: authenticated_header(user)
      }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when an invalid request' do
      before { post "/api/plays/#{play.id}/character_groups", params: { character_group: { age: 'Baby', play_id: play.id } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 422' do
        puts response.body
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expected_response = "{\"name\":[\"can't be blank\"]}"
        expect(response.body).to match(expected_response)
      end
    end
  end

  # Test suite for PUT /plays/:play_id/character_groups/:id
  describe 'PUT /api/plays/:play_id/character_groups/:id' do
    let(:valid_attributes) { { character_group: { name: 'Lady Elizabeth Grey' } } }

    before { put "/api/plays/#{play.id}/character_groups/#{id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

    context 'when character exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'updates the character' do
        updated_character_group = CharacterGroup.find(id)
        expect(updated_character_group.name).to match(/Lady Elizabeth Grey/)
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

  # Test suite for DELETE /character_groups/:id
  describe 'DELETE /character_groups/:id' do
    before { delete "/api/plays/#{play.id}/character_groups/#{id}", headers: authenticated_header(user) }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
