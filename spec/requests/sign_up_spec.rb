require 'rails_helper'

RSpec.describe 'POST /sign_up', type: :request do
  let(:url) { '/api/users' }
  context 'when user is unauthenticated' do

    before {
      valid_attributes  = { user: attributes_for(:user) }
      post url, params: valid_attributes
    }

    it 'returns 200' do
      expect(response.status).to eq 200
    end

    it 'returns a new user' do
      resp = JSON.parse(response.body)
      expect(resp['email']).to be_truthy
    end
  end

  context 'when user already exists' do
    before do
      # valid_attributes = { user: attributes_for(:user) }
      create(:user, email: 'user@example.com')
      post url
    end

    it 'returns bad request status' do
      puts response.body
      expect(response.status).to eq 400
    end

    it 'returns validation errors' do
      json = ActiveSupport::JSON.decode(response.body)
      expect(json['errors'].first['title']).to eq('Bad Request')
    end

    it 'does not create that user' do
      expect(User.all.size).to eq(1)
    end
  end
end
