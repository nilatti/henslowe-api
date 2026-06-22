require 'rails_helper'

RSpec.describe 'lines API', type: :request do
  # initialize test data
  let!(:user) { create(:user)}
  let!(:french_scene) { create(:french_scene) }
  let!(:lines) { create_list(:line, 10, french_scene: french_scene) }
  let(:line_id) { lines.first.id }

  # Test suite for GET /french_scenes/:french_scene_id/lines
  describe 'GET /french_scenes/:french_scene_id/lines' do
    # make HTTP get request before each example
    before { get "/api/v1/french_scenes/#{french_scene.id}/lines", as: :json, headers: authenticated_header(user) }

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
    before { get "/api/v1/lines/#{line_id}", as: :json, headers: authenticated_header(user) }
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
        post "/api/v1/french_scenes/#{test_line.french_scene.id}/lines", params: valid_attributes, as: :json, headers: authenticated_header(user)
        expect(json['character_id']).to eq(test_line.character.id)
      end
    end
  end

  # Test suite for PUT /lines/:id
  describe 'PUT /api/lines/:id' do

    context 'when the record exists' do

      it 'returns status code 200 for a paid user' do
        paid_user = create(:user, :paid)
        valid_attributes = { line: { new_content: "new content" } }
        put "/api/v1/lines/#{line_id}", params: valid_attributes, as: :json, headers: authenticated_header(paid_user)
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'PUT /lines/:id — subscription gate' do
    let(:superadmin)  { create(:user, :superadmin) }
    let(:paid_user)   { create(:user, :paid) }
    let(:unpaid_user) { create(:user) }

    let(:canonical_play)     { create(:play, :with_full_structure, canonical: true) }
    let(:canonical_fs)       { canonical_play.acts.first.scenes.first.french_scenes.first }
    let(:canonical_line)     { create(:line, french_scene: canonical_fs) }

    let(:production_play)    { create(:play, :with_full_structure, canonical: false) }
    let(:production_fs)      { production_play.acts.first.scenes.first.french_scenes.first }
    let(:production_line)    { create(:line, french_scene: production_fs) }

    let(:update_params) { { line: { new_content: 'Cut.' } } }

    context 'canonical play lines' do
      it 'allows superadmin' do
        put "/api/v1/lines/#{canonical_line.id}", params: update_params, as: :json, headers: authenticated_header(superadmin)
        expect(response).to have_http_status(200)
      end

      it 'blocks a paid non-superadmin user' do
        put "/api/v1/lines/#{canonical_line.id}", params: update_params, as: :json, headers: authenticated_header(paid_user)
        expect(response).to have_http_status(403)
      end

      it 'blocks an unpaid user' do
        put "/api/v1/lines/#{canonical_line.id}", params: update_params, as: :json, headers: authenticated_header(unpaid_user)
        expect(response).to have_http_status(403)
      end
    end

    context 'non-canonical (production) play lines' do
      it 'allows a paid user' do
        put "/api/v1/lines/#{production_line.id}", params: update_params, as: :json, headers: authenticated_header(paid_user)
        expect(response).to have_http_status(200)
      end

      it 'allows superadmin' do
        put "/api/v1/lines/#{production_line.id}", params: update_params, as: :json, headers: authenticated_header(superadmin)
        expect(response).to have_http_status(200)
      end

      it 'blocks an unpaid user' do
        put "/api/v1/lines/#{production_line.id}", params: update_params, as: :json, headers: authenticated_header(unpaid_user)
        expect(response).to have_http_status(403)
      end
    end
  end

  # Test suite for DELETE /lines/:id
  describe 'DELETE /lines/:id' do
    before { delete "/api/v1/lines/#{line_id}", as: :json, headers: authenticated_header(user) }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
