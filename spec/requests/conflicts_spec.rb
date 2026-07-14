# spec/requests/plays_spec.rb
require 'rails_helper'

RSpec.describe 'Conflicts API' do
  # Initialize the test data
  let!(:user) { create(:user)}
  let!(:space) { create(:space)}
  let!(:conflict) { create(:conflict, user: user)}
  let!(:conflicts) {create_list(:conflict, 3, user: user)}
  let!(:space_conflict) { create(:conflict, space: space, user: nil)}

  let!(:id) { conflict.id }
  # Test suite for GET /conflicts
  describe 'GET api/conflicts for user' do
    before {
      get "/api/v1/users/#{user.id}/conflicts", as: :json, headers: authenticated_header(user)
    }
    context 'when conflict exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all conflicts for user' do
        expect(json.size).to eq(4)
      end
    end
  end

  # Test suite for GET /conflicts
  describe 'GET api/conflicts for space' do
    before {
      get "/api/v1/spaces/#{space.id}/conflicts", as: :json, headers: authenticated_header(user)
    }
    context 'when conflict exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all conflicts for space' do
        expect(json.size).to eq(1)
      end
    end
  end

  # Test suite for GET /conflicts/:id
  describe 'GET /conflicts/:id' do
    before { get "/api/v1/conflicts/#{id}", headers: authenticated_header(user) }

    context 'when conflict exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the conflict' do
        expect(json['id']).to eq(id)
      end
    end

    context 'when conflict does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Conflict/)
      end
    end
  end

  # Test suite for PUT /conflicts
  describe 'POST /conflicts' do
    let(:valid_attributes) { { conflict: { user_id: user.id, start_time: Time.now, end_time: Time.now + 3.hours } } }

    context 'when request attributes are valid' do
      before { post "/api/v1/users/#{user.id}/conflicts", params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when an invalid request' do
      before { post "/api/v1/users/#{user.id}/conflicts", params: { conflict: { age: 'Baby' } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expected_response = "{\"conflict\":[\"Must have either user or space\"],\"start_time\":[\"can't be blank\"],\"end_time\":[\"can't be blank\"]}"
        expect(response.body).to match(expected_response)
      end
    end
  end

  # Test suite for PUT /conflicts/:id
  describe 'PUT /api/conflicts/:id' do
    let(:valid_attributes) { { conflict: { category: "Personal" } } }

    before { put "/api/v1/conflicts/#{id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

    context 'when conflict exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'updates the conflict' do
        updated_conflict = Conflict.find(id)
        expect(updated_conflict.category).to match(/Personal/)
      end
    end

    context 'when the conflict does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Conflict/)
      end
    end
  end

  # Test suite for DELETE /conflicts/:id
  describe 'DELETE /conflicts/:id' do
    before { delete "/api/v1/conflicts/#{id}", headers: authenticated_header(user) }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end

  describe 'POST /conflicts as a production admin acting on behalf of an actor' do
    let!(:production) { create(:production) }
    let!(:admin_user) { create(:user, :paid) }
    let!(:actor) { create(:user) }

    before do
      create(:job, production: production, theater: production.theater, user: admin_user, specialization: create(:specialization, :director))
      create(:job, production: production, theater: production.theater, user: actor, specialization: create(:specialization, :actor))
    end

    it 'allows creating a one-time conflict for the actor' do
      post "/api/v1/users/#{actor.id}/conflicts",
        params: { conflict: { user_id: actor.id, start_time: Time.now, end_time: Time.now + 1.hour } },
        as: :json, headers: authenticated_header(admin_user)

      expect(response).to have_http_status(201)
      expect(Conflict.where(user_id: actor.id).count).to eq(1)
    end

    it 'allows creating a recurring conflict pattern for the actor' do
      post "/api/v1/users/#{actor.id}/conflict_patterns",
        params: { conflict_pattern: { user_id: actor.id, start_date: Date.today, end_date: Date.today + 30, start_time: "05:00", end_time: "09:00", category: "rehearsal" } },
        as: :json, headers: authenticated_header(admin_user)

      expect(response).to have_http_status(201)
      expect(ConflictPattern.where(user_id: actor.id).count).to eq(1)
    end

    it 'denies creating a conflict for a user outside the admin\'s productions' do
      outsider = create(:user)

      post "/api/v1/users/#{outsider.id}/conflicts",
        params: { conflict: { user_id: outsider.id, start_time: Time.now, end_time: Time.now + 1.hour } },
        as: :json, headers: authenticated_header(admin_user)

      expect(response).to have_http_status(403)
    end
  end
end
