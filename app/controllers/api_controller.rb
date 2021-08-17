class ApiController < ActionController::API
  include ActionController::RequestForgeryProtection
  include ActionController::Cookies
  include ExceptionHandler
  include Response
  include CanCan::ControllerAdditions
  # respond_to :json
  # skip_protect_from_forgery

  rescue_from CanCan::AccessDenied do |exception|
    render json: { message: exception.message }, status: 403
  end
  helper_method :current_user
  def current_user
    puts "looking for current user"
    puts session[:user_id]
    puts session['_henslowescloud']
    User.find(session[:user_id]) if session[:user_id]
  end
end
