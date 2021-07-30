class ApiController < ActionController::API
  include ExceptionHandler
  include Response
  include CanCan::ControllerAdditions
  respond_to :json
  before_action :doorkeeper_authorize!

  rescue_from CanCan::AccessDenied do |exception|
    render json: { message: exception.message }, status: 403
  end

  def current_user
    @current_user ||= User.find_by(id: doorkeeper_token[:resource_owner_id])
    puts (@current_user.email)
  end
#   def current_user
#
#   @current_user ||= if doorkeeper_token
#     User.find(doorkeeper_token.resource_owner_id)
#   else
#     warden.authenticate(scope: :user, store: false)
#   end
# end
end
