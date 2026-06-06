require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe 'Authorization' do
  let!(:theater)          { create(:theater) }
  let!(:production)       { create(:production, theater: theater) }
  let!(:superadmin)       { create(:user, :superadmin) }
  let!(:theater_admin)    { create(:user) }
  let!(:production_admin) { create(:user) }
  let!(:member)           { create(:user) }
  let!(:visitor)          { create(:user) }

  before do
    admin_spec = create(:specialization, :artistic_director)
    prod_spec  = create(:specialization, :director)
    actor_spec = create(:specialization, :actor)

    create(:job, user: theater_admin,    theater: theater, production: nil,       specialization: admin_spec, start_date: 1.year.ago, end_date: 1.year.from_now)
    create(:job, user: production_admin, theater: theater, production: production, specialization: prod_spec,  start_date: 1.year.ago, end_date: 1.year.from_now)
    create(:job, user: member,           theater: theater, production: production, specialization: actor_spec, start_date: 1.year.ago, end_date: 1.year.from_now)
  end

  # ── Productions ───────────────────────────────────────────────────────────

  describe 'DELETE /api/v1/productions/:id' do
    context 'when unauthenticated' do
      it 'returns 401' do
        delete "/api/v1/productions/#{production.id}", as: :json
        expect(response).to have_http_status(401)
      end
    end

    context 'when visitor' do
      it 'returns 403' do
        delete "/api/v1/productions/#{production.id}", as: :json,
               headers: authenticated_header(visitor)
        expect(response).to have_http_status(403)
      end
    end

    context 'when production member' do
      it 'returns 403' do
        delete "/api/v1/productions/#{production.id}", as: :json,
               headers: authenticated_header(member)
        expect(response).to have_http_status(403)
      end
    end

    context 'when production admin' do
      it 'returns 204' do
        delete "/api/v1/productions/#{production.id}", as: :json,
               headers: authenticated_header(production_admin)
        expect(response).to have_http_status(204)
      end
    end

    context 'when theater admin' do
      it 'returns 204' do
        prod = create(:production, theater: theater)
        delete "/api/v1/productions/#{prod.id}", as: :json,
               headers: authenticated_header(theater_admin)
        expect(response).to have_http_status(204)
      end
    end

    context 'when superadmin' do
      it 'returns 204' do
        prod = create(:production, theater: theater)
        delete "/api/v1/productions/#{prod.id}", as: :json,
               headers: authenticated_header(superadmin)
        expect(response).to have_http_status(204)
      end
    end
  end

  describe 'PUT /api/v1/productions/:id' do
    let(:valid_attributes) { { production: { notes: 'Updated' } } }

    context 'when visitor' do
      it 'returns 403' do
        put "/api/v1/productions/#{production.id}", params: valid_attributes,
            as: :json, headers: authenticated_header(visitor)
        expect(response).to have_http_status(403)
      end
    end

    context 'when production admin' do
      it 'returns 200' do
        put "/api/v1/productions/#{production.id}", params: valid_attributes,
            as: :json, headers: authenticated_header(production_admin)
        expect(response).to have_http_status(200)
      end
    end

    context 'when theater admin' do
      it 'returns 200' do
        put "/api/v1/productions/#{production.id}", params: valid_attributes,
            as: :json, headers: authenticated_header(theater_admin)
        expect(response).to have_http_status(200)
      end
    end

    context 'when superadmin' do
      it 'returns 200' do
        put "/api/v1/productions/#{production.id}", params: valid_attributes,
            as: :json, headers: authenticated_header(superadmin)
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'POST /api/v1/productions (with theater_id)' do
    let(:play) { create(:play) }

    context 'when visitor (no theater relationship)' do
      it 'returns 403' do
        post '/api/v1/productions',
             params: { production: { theater_id: theater.id, play_id: play.id, start_date: 1.month.from_now, end_date: 6.months.from_now } },
             as: :json, headers: authenticated_header(visitor)
        expect(response).to have_http_status(403)
      end
    end

    context 'when theater admin' do
      it 'returns 201' do
        post '/api/v1/productions',
             params: { production: { theater_id: theater.id, play_id: play.id, start_date: 1.month.from_now, end_date: 6.months.from_now } },
             as: :json, headers: authenticated_header(theater_admin)
        expect(response).to have_http_status(201)
      end
    end
  end

  # ── Theaters ──────────────────────────────────────────────────────────────

  describe 'PUT /api/v1/theaters/:id' do
    let(:valid_attributes) { { theater: { name: 'Renamed Theater' } } }

    context 'when unauthenticated' do
      it 'returns 401' do
        put "/api/v1/theaters/#{theater.id}", params: valid_attributes, as: :json
        expect(response).to have_http_status(401)
      end
    end

    context 'when visitor' do
      it 'returns 403' do
        put "/api/v1/theaters/#{theater.id}", params: valid_attributes,
            as: :json, headers: authenticated_header(visitor)
        expect(response).to have_http_status(403)
      end
    end

    context 'when production member' do
      it 'returns 403' do
        put "/api/v1/theaters/#{theater.id}", params: valid_attributes,
            as: :json, headers: authenticated_header(member)
        expect(response).to have_http_status(403)
      end
    end

    context 'when theater admin' do
      it 'returns 200' do
        put "/api/v1/theaters/#{theater.id}", params: valid_attributes,
            as: :json, headers: authenticated_header(theater_admin)
        expect(response).to have_http_status(200)
      end
    end

    context 'when superadmin' do
      it 'returns 200' do
        put "/api/v1/theaters/#{theater.id}", params: valid_attributes,
            as: :json, headers: authenticated_header(superadmin)
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'DELETE /api/v1/theaters/:id' do
    context 'when visitor' do
      it 'returns 403' do
        t = create(:theater)
        delete "/api/v1/theaters/#{t.id}", as: :json,
               headers: authenticated_header(visitor)
        expect(response).to have_http_status(403)
      end
    end

    context 'when theater admin' do
      it 'returns 204' do
        t = create(:theater)
        create(:job, user: theater_admin, theater: t, production: nil,
               specialization: create(:specialization, :theater_admin),
               start_date: 1.year.ago, end_date: 1.year.from_now)
        delete "/api/v1/theaters/#{t.id}", as: :json,
               headers: authenticated_header(theater_admin)
        expect(response).to have_http_status(204)
      end
    end

    context 'when superadmin' do
      it 'returns 204' do
        t = create(:theater)
        delete "/api/v1/theaters/#{t.id}", as: :json,
               headers: authenticated_header(superadmin)
        expect(response).to have_http_status(204)
      end
    end
  end

  # ── Users ─────────────────────────────────────────────────────────────────

  describe 'DELETE /api/v1/users/:id' do
    context 'when deleting own account' do
      it 'returns 204' do
        delete "/api/v1/users/#{visitor.id}", as: :json,
               headers: authenticated_header(visitor)
        expect(response).to have_http_status(204)
      end
    end

    context 'when deleting another user without superadmin' do
      it 'returns 403' do
        delete "/api/v1/users/#{member.id}", as: :json,
               headers: authenticated_header(visitor)
        expect(response).to have_http_status(403)
      end
    end

    context 'when superadmin deletes any user' do
      it 'returns 204' do
        u = create(:user)
        delete "/api/v1/users/#{u.id}", as: :json,
               headers: authenticated_header(superadmin)
        expect(response).to have_http_status(204)
      end
    end
  end

  # ── Plays (canonical) ─────────────────────────────────────────────────────

  describe 'DELETE /api/v1/plays/:id (canonical)' do
    let!(:author) { create(:author) }
    let!(:play)   { create(:play, canonical: true, author: author) }

    context 'when regular user' do
      it 'returns 403' do
        delete "/api/v1/plays/#{play.id}", as: :json,
               headers: authenticated_header(visitor)
        expect(response).to have_http_status(403)
      end
    end

    context 'when superadmin' do
      it 'returns 204' do
        delete "/api/v1/plays/#{play.id}", as: :json,
               headers: authenticated_header(superadmin)
        expect(response).to have_http_status(204)
      end
    end
  end

  # ── Specializations ───────────────────────────────────────────────────────

  describe 'POST /api/v1/specializations' do
    context 'when regular user' do
      it 'returns 403' do
        post '/api/v1/specializations',
             params: { specialization: { title: 'New Role' } },
             as: :json, headers: authenticated_header(visitor)
        expect(response).to have_http_status(403)
      end
    end

    context 'when superadmin' do
      it 'returns 201' do
        post '/api/v1/specializations',
             params: { specialization: { title: 'New Role' } },
             as: :json, headers: authenticated_header(superadmin)
        expect(response).to have_http_status(201)
      end
    end
  end
end
