# class SessionsController < Devise::SessionsController
#   include ActionController::RequestForgeryProtection
#   skip_before_action :verify_authenticity_token
#   respond_to :json
#   def googleAuth
#       # Get access tokens from the google server
#       access_token = request.env["omniauth.auth"]
#       user = User.from_omniauth(access_token)
#       log_in(user)
#       # Access_token is used to authenticate request made from the rails application to the google server
#       user.google_token = access_token.credentials.token
#       # Refresh_token to request new access_token
#       # Note: Refresh_token is only sent once during the first request
#       refresh_token = access_token.credentials.refresh_token
#       user.google_refresh_token = refresh_token if refresh_token.present?
#       user.save
#       redirect_to root_path
#     end
#  private
#  #
#  def respond_with(resource, _opts = {})
#    render json: resource
#  end
#
#  def respond_to_on_destroy
#    head :no_content
#  end
# end

# class SessionsController < ApplicationController
# # skip_before_action :verify_authenticity_token
# skip_forgery_protection
# # protect_from_forgery prepend: true, with: :null_session
# respond_to :json
#   def new
#
#   end
#
#   def create
#     puts "hit session controller"
#
#     user = User.from_omniauth(request.env["omniauth.auth"])
#
#     if user.save
#
#       session[:user_id] = user.id
#
#       redirect_to root_path
#
#     else
#
#       redirect_to new_session_path
#
#     end
#
#   end
#
#
#
#   def destroy
#
#     session[:user_id] = nil
#
#     redirect_to new_session_path
#
#   end
#  end
class SessionsController < ApplicationController
  # If you're using a strategy that POSTs during callback, you'll need to skip the authenticity token check for the callback action only.
  # skip_before_action :verify_authenticity_token
  # respond_to :json
  def create
    @user = User.from_omniauth(auth_hash)
    session[:user_id] = @user.id
    render json: @user.as_json
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end
