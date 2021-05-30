Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, Rails.application.secrets.google_client_id, Rails.application.secrets.google_client_secret, { provider_ignores_state: true}
end
# OmniAuth.config.provider_ignores_state = true
OmniAuth.config.allowed_request_methods = %i[get]
