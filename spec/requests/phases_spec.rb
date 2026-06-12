require 'rails_helper'

RSpec.describe 'Phases API', type: :request do
  let!(:superadmin) { create(:user, role: 'superadmin') }
  let!(:regular_user) { create(:user) }
  let!(:phases) { create_list(:phase, 3) }
  let(:phase_id) { phases.first.id }

  describe 'GET /api/v1/phases' do
    context 'as any authenticated user' do
      before { get '/api/v1/phases', headers: authenticated_header(regular_user) }

      it 'returns status 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all phases' do
        expect(json.size).to eq(3)
      end
    end
  end

  describe 'GET /api/v1/phases/:id' do
    before { get "/api/v1/phases/#{phase_id}", headers: authenticated_header(regular_user) }

    it 'returns the phase' do
      expect(json['id']).to eq(phase_id)
    end

    it 'returns status 200' do
      expect(response).to have_http_status(200)
    end

    context 'when not found' do
      let(:phase_id) { 0 }

      it 'returns status 404' do
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'POST /api/v1/phases' do
    context 'as superadmin' do
      before do
        post '/api/v1/phases',
             params: { phase: { name: 'Preproduction', position: 1 } },
             as: :json,
             headers: authenticated_header(superadmin)
      end

      it 'creates the phase' do
        expect(json['name']).to eq('Preproduction')
        expect(json['position']).to eq(1)
      end

      it 'returns status 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'as regular user' do
      before do
        post '/api/v1/phases',
             params: { phase: { name: 'Nope' } },
             as: :json,
             headers: authenticated_header(regular_user)
      end

      it 'returns status 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'with invalid attributes' do
      before do
        post '/api/v1/phases',
             params: { phase: { name: '' } },
             as: :json,
             headers: authenticated_header(superadmin)
      end

      it 'returns status 422' do
        expect(response).to have_http_status(422)
      end
    end
  end

  describe 'PUT /api/v1/phases/:id' do
    context 'as superadmin' do
      before do
        put "/api/v1/phases/#{phase_id}",
            params: { phase: { name: 'Updated Name', position: 5 } },
            as: :json,
            headers: authenticated_header(superadmin)
      end

      it 'updates the phase' do
        expect(json['name']).to eq('Updated Name')
        expect(json['position']).to eq(5)
      end

      it 'returns status 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'as regular user' do
      before do
        put "/api/v1/phases/#{phase_id}",
            params: { phase: { name: 'Nope' } },
            as: :json,
            headers: authenticated_header(regular_user)
      end

      it 'returns status 403' do
        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'DELETE /api/v1/phases/:id' do
    context 'as superadmin' do
      before { delete "/api/v1/phases/#{phase_id}", headers: authenticated_header(superadmin) }

      it 'returns status 204' do
        expect(response).to have_http_status(204)
      end

      it 'removes the phase' do
        expect(Phase.find_by(id: phase_id)).to be_nil
      end
    end

    context 'as regular user' do
      before { delete "/api/v1/phases/#{phase_id}", headers: authenticated_header(regular_user) }

      it 'returns status 403' do
        expect(response).to have_http_status(403)
      end
    end
  end
end
