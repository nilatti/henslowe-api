require 'rails_helper'

describe RegistrationsController, type: :request do
# ttktktktk change this a lot when finally get oauth with new user integrated, probably combine w/sign_up_spec
  let (:user){ build(:user) }
  let (:existing_user) { create(:user) }
  let (:signup_url) { '/api/sign_up' }

  context 'When creating a new user' do
    before do
      get signup_url, params: {
        user: {
          email: user.email,
          password: user.password
        }
      }
    end

    it 'returns 200' do
      expect(response.status).to eq(200)
    end

    it 'returns a token' do
      expect(response.headers['Authorization']).to be_present
    end

    it 'returns the user email' do
      expect(json['data']).to have_attribute(:email).with_value(user.email)
    end
  end

  context 'When an email already exists' do
    before do
      post signup_url, params: {
        user: {
          email: existing_user.email,
          password: existing_user.password
        }
      }
    end

    it 'returns 400' do
      expect(response.status).to eq(400)
    end
  end

end
