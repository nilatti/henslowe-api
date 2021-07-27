require 'rails_helper'

RSpec.describe 'SoundCues API', type: :request do
  # initialize test data
  let!(:sound_cues) { create_list(:sound_cue, 4) }
  let!(:french_scene) {create(:french_scene)}
  let(:sound_cue_id) { sound_cues.first.id }
  let!(:user) { create(:user)}
  # Test suite for GET /sound_cues
  describe 'GET /sound_cues' do
    # make HTTP get request before each example
    before { get '/api/sound_cues', headers: authenticated_header(user) }

    it 'returns sound_cues' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json).not_to be_empty
      expect(json.size).to eq(4)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /sound_cues/:id
  describe 'GET api/sound_cues/:id' do
    before { get "/api/sound_cues/#{sound_cue_id}", headers: authenticated_header(user) }
    context 'when the record exists' do
      it 'returns the sound_cue' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(sound_cue_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:sound_cue_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find SoundCue/)
      end
    end
  end

  describe 'POST /sound_cues' do
    # valid payload

    context 'when the request is valid' do

      it 'creates a sound_cue' do
        test_sound_cue = build(:sound_cue)
        valid_attributes = {
          sound_cue: {
            french_scene_id: test_sound_cue.french_scene.id,
            original_content: test_sound_cue.original_content,
          } }
        post '/api/sound_cues', params: valid_attributes, as: :json, headers: authenticated_header(user)
        expect(json['french_scene_id']).to eq(test_sound_cue.french_scene.id)
      end
    end

    # context 'when the request is invalid' do
    #   before { post '/api/sound_cues', params: { sound_cue: { first_name: 'Failure' } }, as: :json }
    #
    #   it 'returns status code 422' do
    #     expect(response).to have_http_status(422)
    #   end
    #
    #   it 'returns a validation failure message' do
    #     expect(response.body)
    #       .to match(/Validation failed: Last name can't be blank/)
    #   end
    # end
  end

  # Test suite for PUT /sound_cues/:id
  describe 'PUT /api/sound_cues/:id' do
    let(:valid_attributes) { { sound_cue: attributes_for(:sound_cue, original_content: "BE LOUDER") } }

    context 'when the record exists' do
      before { put "/api/sound_cues/#{sound_cue_id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /sound_cues/:id
  describe 'DELETE /sound_cues/:id' do
    before {
      delete "/api/sound_cues/#{sound_cue_id}", headers: authenticated_header(user)
    }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end

end
