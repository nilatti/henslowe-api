class ApiController < ActionController::API
  include ActionController::RequestForgeryProtection
  include ActionController::Cookies
  include ExceptionHandler
  include Response
  include CanCan::ControllerAdditions
  # respond_to :json
  # skip_protect_from_forgery

  # before_action :authenticate_current_user
  rescue_from CanCan::AccessDenied do |exception|
    render json: { message: exception.message }, status: 403
  end
  helper_method :current_user
  def current_user
    token = cookies.signed[:jwt]
    decoded_token = CoreModules::JsonWebToken.decode(token)
    if decoded_token
      user = User.find_by(id: decoded_token["id"])
    end
    if user then return user else return false end
  end
  
  def authenticate_current_user
    if cookies.signed[:jwt]
      jwt = cookies.signed[:jwt]
      CoreModules::JsonWebToken.decode(jwt)
    end
  end
end
