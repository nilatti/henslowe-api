require 'rails_helper'
describe SessionsController, type: :request do
  let!(:user) { create(:user)}
    context 'When logging in and out' do
      before do
        login(user)
      end
      it 'returns 200' do
        expect(response.status).to eq(200)
      end
      it 'returns access tokens and userId' do
        res = JSON.parse(response.body)
        expect(res['access_token']).to be_present

        @token = JSON.parse(response.body)['access_token']
        expect(res['refresh_token']).to be_present
        expect(res['userId']).to be_present
        expect(res['userId']).to be_an(Integer)
      end
    end
    context 'When logging out' do
      before do
        login(user)
        @token = JSON.parse(response.body)['access_token']
      end
    it 'logs out' do
      logout(@token)
      expect(response).to have_http_status(200)
      sql = "SELECT revoked_at from oauth_access_tokens where token = '#{@token}'"
      result = ActiveRecord::Base.connection.execute(sql)
      expect(result).to be_present
    end
  end
end
