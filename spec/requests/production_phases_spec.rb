require 'rails_helper'

RSpec.describe 'ProductionPhases API', type: :request do
  let!(:superadmin) { create(:user, role: 'superadmin') }
  let!(:theater) { create(:theater) }
  let!(:production) { create(:production, theater: theater) }
  let!(:phases) { create_list(:phase, 3) }

  # production admin: user with a production_admin specialization job on this production
  let!(:prod_admin_specialization) { create(:specialization, production_admin: true) }
  let!(:prod_admin_user) { create(:user, :paid) }
  let!(:prod_admin_job) do
    create(:job,
           user: prod_admin_user,
           production: production,
           theater: theater,
           specialization: prod_admin_specialization)
  end

  let!(:regular_user) { create(:user) }

  describe 'PUT /api/v1/productions/:production_id/production_phases/upsert' do
    let(:upsert_params) do
      {
        production_phases: [
          { phase_id: phases[0].id, start_date: '2026-01-01', end_date: '2026-02-01' },
          { phase_id: phases[1].id, start_date: '2026-02-01', end_date: '2026-03-01' }
        ]
      }
    end

    context 'as superadmin' do
      before do
        put "/api/v1/productions/#{production.id}/production_phases/upsert",
            params: upsert_params, as: :json,
            headers: authenticated_header(superadmin)
      end

      it 'returns status 200' do
        expect(response).to have_http_status(200)
      end

      it 'creates production phases' do
        expect(ProductionPhase.where(production: production).count).to eq(2)
      end
    end

    context 'as production admin' do
      before do
        put "/api/v1/productions/#{production.id}/production_phases/upsert",
            params: upsert_params, as: :json,
            headers: authenticated_header(prod_admin_user)
      end

      it 'returns status 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'as regular user' do
      before do
        put "/api/v1/productions/#{production.id}/production_phases/upsert",
            params: upsert_params, as: :json,
            headers: authenticated_header(regular_user)
      end

      it 'returns status 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'upsert updates existing records' do
      let!(:existing_pp) do
        create(:production_phase,
               production: production,
               phase: phases[0],
               start_date: '2025-01-01',
               end_date: '2025-06-01')
      end

      before do
        put "/api/v1/productions/#{production.id}/production_phases/upsert",
            params: {
              production_phases: [
                { phase_id: phases[0].id, start_date: '2026-03-01', end_date: '2026-04-01' }
              ]
            },
            as: :json,
            headers: authenticated_header(superadmin)
      end

      it 'updates rather than duplicates' do
        expect(ProductionPhase.where(production: production, phase: phases[0]).count).to eq(1)
        expect(existing_pp.reload.start_date.to_s).to eq('2026-03-01')
      end
    end
  end

  describe 'DELETE /api/v1/production_phases/:id' do
    let!(:production_phase) { create(:production_phase, production: production, phase: phases[0]) }

    context 'as superadmin' do
      before { delete "/api/v1/production_phases/#{production_phase.id}", headers: authenticated_header(superadmin) }

      it 'returns status 204' do
        expect(response).to have_http_status(204)
      end

      it 'removes the record' do
        expect(ProductionPhase.find_by(id: production_phase.id)).to be_nil
      end
    end

    context 'as production admin' do
      before { delete "/api/v1/production_phases/#{production_phase.id}", headers: authenticated_header(prod_admin_user) }

      it 'returns status 204' do
        expect(response).to have_http_status(204)
      end
    end

    context 'as regular user' do
      before { delete "/api/v1/production_phases/#{production_phase.id}", headers: authenticated_header(regular_user) }

      it 'returns status 403' do
        expect(response).to have_http_status(403)
      end
    end
  end
end
