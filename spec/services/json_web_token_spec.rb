require 'rails_helper'

RSpec.describe JsonWebToken do
  let(:user_id) { 1 }
  let(:token) { JsonWebToken.encode(user_id: user_id) }

  describe '.encode' do
    it 'encodes a payload into a JWT token' do
      expect(token).to be_a(String)
    end
  end

  describe '.decode' do
    it 'decodes a valid token' do
      decoded = JsonWebToken.decode(token)
      expect(decoded[:user_id]).to eq(user_id)
    end

    it 'raises InvalidToken for an invalid token' do
      expect {
        JsonWebToken.decode('invalid.token.here')
      }.to raise_error(ExceptionHandler::InvalidToken)
    end

    it 'raises ExpiredSignature for an expired token' do
      expired_token = JsonWebToken.encode({ user_id: user_id }, 1.second.ago)
      expect {
        JsonWebToken.decode(expired_token)
      }.to raise_error(ExceptionHandler::ExpiredSignature)
    end
  end
end
