# spec/requests/plays_spec.rb
require 'rails_helper'

RSpec.describe 'Words API' do
  before(:each) do
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]
    puts Rails.application.env_config["omniauth.auth"]
    get '/sessions/create'
  end
  # Initialize the test data
  let!(:play) { create(:play) }
  let!(:play_words) { create_list(:word, 10, play: play)}
  let!(:id) { play.words.first.id }

  let!(:user) { create(:user)}
  # Test suite for GET /plays/:play_id/charworders
  describe 'GET api/plays/:play_id/words' do
    before {
      get "/api/plays/#{play.id}/words", params: {play_id: play.id}, headers: authenticated_header(user)
    }

    context 'when play exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all words' do
        expect(json.size).to eq(10)
      end

    end
  end

  # Test suite for GET /plays/:play_id/words/:id
  describe 'GET /words/:id' do
    before {
      get "/api/plays/#{play.id}/words/#{id}", headers: authenticated_header(user)
    }

    context 'when word exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the word' do
        expect(json['id']).to eq(id)
      end
    end

    context 'when word does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Word/)
      end
    end
  end

  # Test suite for PUT /plays/:play_id/charworders
  describe 'POST /plays/:play_id/words' do
    let(:valid_attributes) { { line_number: "1", play_id: play.id } }

    context 'when request attributes are valid' do
      before {
        post "/api/plays/#{play.id}/words", params: valid_attributes, as: :json, headers: authenticated_header(user)
      }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    # context 'when an invalid request' do
    #   before { post "/api/plays/#{play.id}/words", params: { word: { line_number: nil, play_id: play.id } }, as: :json }
    #
    #   it 'returns status code 422' do
    #     expect(response).to have_http_status(422)
    #   end
    #
    #   it 'returns a failure message' do
    #     expected_response = "{\"line_number\":[\"can't be blank\"]}"
    #     expect(response.body).to match(expected_response)
    #   end
    # end
  end

  # Test suite for PUT /plays/:play_id/charworders/:id
  describe 'PUT /api/words/:id' do
    let(:valid_attributes) { { "word"=>{"line_number"=>"2", "play_id"=>play.id} } }

    before { put "/api/plays/#{play.id}/words/#{id}", params: valid_attributes, as: :json, headers: authenticated_header(user)  }

    context 'when word exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'updates the word' do
        updated_word = Word.find(id)
        expect(updated_word.line_number).to eq("2")
      end
    end

    context 'when the charworder does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Word/)
      end
    end
  end

  # Test suite for DELETE /words/:id
  describe 'DELETE /words/:id' do
    before { delete "/api/plays/#{play.id}/words/#{id}", headers: authenticated_header(user)  }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
