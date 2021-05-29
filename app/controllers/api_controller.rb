class ApiController < ActionController::API
  include ExceptionHandler
  include Response
  include CanCan::ControllerAdditions
  respond_to :json

  rescue_from CanCan::AccessDenied do |exception|
    render json: { message: exception.message }, status: 403
  end
end
