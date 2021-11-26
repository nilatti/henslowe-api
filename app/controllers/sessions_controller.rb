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
      created_jwt = CoreModules::JsonWebToken.encode({id: user.id})
      cookies.signed[:jwt] = {value: created_jwt, httponly: true, expires: 1.month.from_now}
      json_response(user.as_json(
        only: [
          :email,
          :first_name,
          :id,
          :last_name,
          :preferred_name,
          :program_name,
          :subscription_end_date,
          :subscription_status
        ]
      ))
    else
      render json: {status: 'incorrect email or password', code: 422}
    end
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end
