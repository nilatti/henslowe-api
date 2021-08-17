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
