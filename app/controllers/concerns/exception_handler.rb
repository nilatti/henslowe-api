module ExceptionHandler
  extend ActiveSupport::Concern

  class InvalidToken < StandardError; end
  class ExpiredSignature < StandardError; end
  class MissingToken < StandardError; end

  included do
    rescue_from ExceptionHandler::InvalidToken, with: :unauthorized
    rescue_from ExceptionHandler::ExpiredSignature, with: :unauthorized
    rescue_from ExceptionHandler::MissingToken, with: :unauthorized
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :bad_request
    rescue_from CanCan::AccessDenied, with: :forbidden
  end

  private

  def unauthorized(e)
    render json: { error: e.message }, status: :unauthorized
  end

  def not_found(e)
    render json: { error: e.message }, status: :not_found
  end

  def bad_request(e)
    render json: { errors: [{ title: 'Bad Request' }] }, status: :bad_request
  end

  def forbidden(e)
    render json: { error: e.message }, status: :forbidden
  end

  def unprocessable_entity(e)
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
