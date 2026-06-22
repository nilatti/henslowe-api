require 'rails_helper'

RSpec.describe 'StageDirections API', type: :request do
  let!(:user)             { create(:user) }
  let!(:stage_directions) { create_list(:stage_direction, 4) }
  let(:stage_direction_id) { stage_directions.first.id }

  describe 'GET /stage_directions' do
    before { get '/api/v1/stage_directions', headers: authenticated_header(user) }

    it 'returns stage directions' do
      expect(json).not_to be_empty
      expect(json.size).to eq(4)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /stage_directions/:id' do
    before { get "/api/v1/stage_directions/#{stage_direction_id}", headers: authenticated_header(user) }

    context 'when the record exists' do
      it 'returns the stage direction' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(stage_direction_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:stage_direction_id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'POST /stage_directions' do
    context 'when the request is valid' do
      it 'creates a stage direction' do
        sd = build(:stage_direction)
        post '/api/v1/stage_directions',
             params: { stage_direction: { french_scene_id: sd.french_scene.id, original_content: sd.original_content, kind: sd.kind } },
             as: :json, headers: authenticated_header(user)
        expect(json['french_scene_id']).to eq(sd.french_scene.id)
      end
    end
  end

  describe 'PUT /stage_directions/:id — subscription gate' do
    let(:superadmin)  { create(:user, :superadmin) }
    let(:paid_user)   { create(:user, :paid) }
    let(:unpaid_user) { create(:user) }

    let(:canonical_play)  { create(:play, :with_full_structure, canonical: true) }
    let(:canonical_fs)    { canonical_play.acts.first.scenes.first.french_scenes.first }
    let(:canonical_sd)    { create(:stage_direction, french_scene: canonical_fs) }

    let(:production_play) { create(:play, :with_full_structure, canonical: false) }
    let(:production_fs)   { production_play.acts.first.scenes.first.french_scenes.first }
    let(:production_sd)   { create(:stage_direction, french_scene: production_fs) }

    let(:update_params) { { stage_direction: { new_content: 'Exit, pursued by a bear.' } } }

    context 'canonical play stage directions' do
      it 'allows superadmin' do
        put "/api/v1/stage_directions/#{canonical_sd.id}", params: update_params, as: :json, headers: authenticated_header(superadmin)
        expect(response).to have_http_status(200)
      end

      it 'blocks a paid non-superadmin user' do
        put "/api/v1/stage_directions/#{canonical_sd.id}", params: update_params, as: :json, headers: authenticated_header(paid_user)
        expect(response).to have_http_status(403)
      end

      it 'blocks an unpaid user' do
        put "/api/v1/stage_directions/#{canonical_sd.id}", params: update_params, as: :json, headers: authenticated_header(unpaid_user)
        expect(response).to have_http_status(403)
      end
    end

    context 'non-canonical (production) stage directions' do
      it 'allows a paid user' do
        put "/api/v1/stage_directions/#{production_sd.id}", params: update_params, as: :json, headers: authenticated_header(paid_user)
        expect(response).to have_http_status(200)
      end

      it 'allows superadmin' do
        put "/api/v1/stage_directions/#{production_sd.id}", params: update_params, as: :json, headers: authenticated_header(superadmin)
        expect(response).to have_http_status(200)
      end

      it 'blocks an unpaid user' do
        put "/api/v1/stage_directions/#{production_sd.id}", params: update_params, as: :json, headers: authenticated_header(unpaid_user)
        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'DELETE /stage_directions/:id' do
    before { delete "/api/v1/stage_directions/#{stage_direction_id}", headers: authenticated_header(user) }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
