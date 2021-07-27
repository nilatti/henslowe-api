module OmniauthMacros

  def login(user)
    if Rails.env.test?
         OmniAuth.config.test_mode = true
         application = create(:application)
         # uid = client_id and secret = client_secret.
    login_params = {
        grant_type: 'password',
        email: user.email,
        password: user.password,
        client_id: application.uid,
        client_secret: application.secret
      }
     post '/oauth/token', params: login_params, as: :json
   end
  end
  def logout(token)
    logout_params = {
      client_id: application.uid,
      client_secret: application.secret,
      token: token
    }
    post 'oauth/revoke', params: logout_params, as: :json
  end
end
