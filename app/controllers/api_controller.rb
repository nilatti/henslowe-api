class ApiController < ActionController::API
  include ActionController::Cookies
  include ExceptionHandler
  include Response
  include CanCan::ControllerAdditions

  before_action :authenticate_request

  SENSITIVE_FIELDS = %w[
    encrypted_password
    reset_password_token
    reset_password_sent_at
    remember_created_at
    authentication_token
    authentication_token_created_at
  ].freeze

  private

  def authenticate_request
    token = cookies[:auth_token] || request.headers['Authorization']&.split(' ')&.last
    raise ExceptionHandler::MissingToken, 'Missing token' unless token
    @decoded = JsonWebToken.decode(token)
    @current_user = User.find(@decoded[:user_id])
  end

  def current_user
    @current_user
  end

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end

  def json_response(object, status = :ok)
    if object.is_a?(ActiveRecord::Base) || object.is_a?(ActiveRecord::Relation)
      render json: sanitize_response(object.as_json), status: status
    else
      render json: sanitize_response(object), status: status
    end
  end

  def sanitize_response(data)
    case data
    when Array
      data.map { |item| sanitize_response(item) }
    when Hash
      data.except(*SENSITIVE_FIELDS).transform_values { |v| sanitize_response(v) }
    else
      data
    end
  end

  def can_view_user_conflicts?(target_user_id)
    current_user.can_manage_conflicts_for?(User.find(target_user_id))
  end
end
