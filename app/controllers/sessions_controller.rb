# class SessionsController < ApplicationController
#   # If you're using a strategy that POSTs during callback, you'll need to skip the authenticity token check for the callback action only.
#   # skip_before_action :verify_authenticity_token
#   # respond_to :json
#   def create
#     @user = User.from_omniauth(auth_hash)
#     session[:user_id] = @user.id
#     render json: @user.as_json
#   end
#
#   protected
#
#   def auth_hash
#     request.env['omniauth.auth']
#   end
# end

class SessionsController  < ApiController
  before_action only: [:destroy] do
    authenticate_cookie
  end

  def destroy
    user = current_user
    if user
      cookies.delete(:jwt)
      render json: {status: 'OK', code: 200}
    else
      render json: {status: 'session not found', code: 404}
    end
  end

  def create
    user = User.from_omniauth(auth_hash)
    if user
      puts user.id
      created_jwt = CoreModules::JsonWebToken.encode({id: user.id})
      cookies.signed[:jwt] = {value:  created_jwt, httponly: true, expires: 1.hour.from_now}
      render json: {username: user.email}
    else
      render json: {status: 'incorrect email or password', code: 422}
    end
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end
