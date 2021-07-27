# spec/requests/productions_spec.rb
require 'rails_helper'

RSpec.describe 'Users API' do
  # Initialize the test data
  let!(:user) { create(:user) }
  let!(:users) {create_list(:user, 10)}
  let!(:id) { user.id }
#tktktktkt test user create https://rubyyagi.com/rails-api-authentication-devise-doorkeeper/
  # Test suite for GET /productions/:production_id/rehearsals
  describe 'GET api/users' do
    before {
      get "/api/users/", headers: authenticated_header(user)
    }

    context 'when users exist' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all users' do
        expect(json.size).to eq(12)
      end
    end
  end

  # Test suite for GET /users/:user_id/
  describe 'GET /users/:user_id/' do
    before { get "/api/users/#{id}/", headers: authenticated_header(user) }

    context 'when user exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the user' do
        expect(json['id']).to eq(user.id)
      end
    end

    context 'when user does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find User/)
      end
    end
  end
  describe 'put /api/users/:user_id/build_conflict_schedule' do
    before {
      conflict_schedule_pattern = {
          "category": "work",
          "days_of_week": ['Monday', 'Wednesday'],
          "end_date": "2020-03-20",
          "end_time": "17:00:00",
          "user_id": user.id,
          "start_date": "2020-02-20",
          "start_time": "12:00:00"}
      put "/api/users/#{user.id}/build_conflict_schedule", as: :json, params: {conflict_schedule_pattern: conflict_schedule_pattern}, headers: authenticated_header(user)
    }
    it 'returns 200' do
      puts response.body
      expect(response).to have_http_status(200)
    end
    it 'starts production build worker' do
      expect(BuildConflictsScheduleWorker.jobs.size).to eql(1)
      BuildConflictsScheduleWorker.drain
      expect(BuildConflictsScheduleWorker.jobs.size).to eql(0)
      expect(Conflict.all.size).to eq(8)
      expect(Conflict.all.first.user.id).to eq(user.id)
    end
  end

end
