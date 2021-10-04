module ApiHelpers

  def json
    JSON.parse(response.body)
  end

  def login_user(user)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
        :provider => "google_oauth2",
        :uid => "123456789",
        :info => {
          :first_name => user.first_name,
          :last_name => user.last_name,
          :email => user.email
        },
        :credentials => {
          :token => "token",
          :refresh_token => "refresh token"
        }
      }
    )
    post "/auth/google_oauth2/callback"
    request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]
  end

  def authenticated_header(user)
      # login_user(user)
    headers = { 'Accept': 'application/json', 'Content-Type': 'application/json'}
  end

end
