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
      get "/api/conflicts", params: { user_id: user.id}, as: :json, headers: authenticated_header(user)
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
      get "/api/conflicts", params: { space_id: space.id}, as: :json, headers: authenticated_header(user)
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
    before { get "/api/conflicts/#{id}", headers: authenticated_header(user) }

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
      before { post "/api/conflicts", params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when an invalid request' do
      before { post "/api/conflicts", params: { conflict: { age: 'Baby' } }, as: :json, headers: authenticated_header(user) }

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

    before { put "/api/conflicts/#{id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

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
    before { delete "/api/conflicts/#{id}", headers: authenticated_header(user) }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
