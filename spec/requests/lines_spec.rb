require 'rails_helper'

RSpec.describe 'lines API', type: :request do
  # initialize test data
  let!(:user) { create(:user)}
  let!(:lines) { create_list(:line, 10) }
  let(:line_id) { lines.first.id }

  # Test suite for GET /lines
  describe 'GET /lines' do
    # make HTTP get request before each example
    before { get '/api/lines', as: :json, headers: authenticated_header(user) }

    it 'returns lines' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json).not_to be_empty
      expect(json.size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /lines/:id
  describe 'GET api/lines/:id' do
    before { get "/api/lines/#{line_id}", as: :json, headers: authenticated_header(user) }
    context 'when the record exists' do
      it 'returns the line' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(line_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:line_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Line/)
      end
    end
  end

  # Test suite for POST /lines
  describe 'POST /lines' do
    # valid payload

    context 'when the request is valid' do

      it 'creates a line' do
        test_line = build(:line)
        valid_attributes = {
          line: {
            ana: test_line.ana,
            french_scene_id: test_line.french_scene.id,
            character_id: test_line.character.id,
            original_content: test_line.original_content,
          } }
        post '/api/lines', params: valid_attributes, as: :json, headers: authenticated_header(user)
        expect(json['character_id']).to eq(test_line.character.id)
      end
    end
  end

  # Test suite for PUT /lines/:id
  describe 'PUT /api/lines/:id' do

    context 'when the record exists' do

      it 'returns status code 200' do
        test_line = build(:line)
        valid_attributes = {
          line: {
              new_content: "new content",
            } }
          put "/api/lines/#{line_id}", params: valid_attributes, as: :json, headers: authenticated_header(user)
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /lines/:id
  describe 'DELETE /lines/:id' do
    before { delete "/api/lines/#{line_id}", as: :json, headers: authenticated_header(user) }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
