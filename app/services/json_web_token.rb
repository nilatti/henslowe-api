class JsonWebToken
  SECRET = Rails.application.secret_key_base

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET, 'HS256')
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET, true, { algorithm: 'HS256' })[0]
    HashWithIndifferentAccess.new(decoded)
  # ORDER MATTERS: JWT::ExpiredSignature is a subclass of JWT::DecodeError,
  # so it must be rescued first or it will be caught by the DecodeError clause.
  rescue JWT::ExpiredSignature
    raise ExceptionHandler::ExpiredSignature, 'Token has expired'
  rescue JWT::DecodeError => e
    raise ExceptionHandler::InvalidToken, e.message
  end
end
