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
    puts "sessions create called with auth hash"
    puts (request.env['omniauth.auth'])
    puts "finding user"
    user = User.from_omniauth(auth_hash)
    if user
      created_jwt = CoreModules::JsonWebToken.encode({id: user.id})
      cookies.signed[:jwt] = {value:  created_jwt, httponly: true, expires: 1.hour.from_now}
      render json: {user: {
        email: user.email,
        first_name: user.first_name,
        id: user.id,
        last_name: user.last_name,
        preferred_name: user.preferred_name,
        program_name: user.program_name
      }}
    else
      render json: {status: 'incorrect email or password', code: 422}
    end
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end
