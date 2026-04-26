class ApiController < ActionController::API
  include ExceptionHandler
  include Response

  before_action :authenticate_request

  private

  def authenticate_request
    token = request.headers['Authorization']&.split(' ')&.last
    raise ExceptionHandler::MissingToken, 'Missing token' unless token
    @decoded = JsonWebToken.decode(token)
    @current_user = User.find(@decoded[:user_id])
  end

  def current_user
    @current_user
  end
end
