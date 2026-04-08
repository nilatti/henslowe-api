module CoreModules::JsonWebToken
  require 'jwt'
  JWT_SECRET = Rails.application.secret_key_base

  ALGORITHM = 'HS256'

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, JWT_SECRET, ALGORITHM)
  end

  def self.decode(token)
    begin
      body = JWT.decode(token, JWT_SECRET, true, algorithms: [ALGORITHM])
      if body then HashWithIndifferentAccess.new body[0] else return false end
    rescue JWT::ExpiredSignature, JWT::VerificationError => e
      return false
    rescue JWT::DecodeError, JWT::VerificationError => e
      return false
    end
  end
end
