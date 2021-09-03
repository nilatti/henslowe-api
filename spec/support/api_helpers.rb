module ApiHelpers

  def json
    JSON.parse(response.body)
  end

  def login_user(user)
    get "/auth/google_oauth2/callback"
    request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:google]
  end

  def authenticated_header(user)
    # login_user(user)
    headers = { 'Accept': 'application/json', 'Content-Type': 'application/json'}
  end

end
