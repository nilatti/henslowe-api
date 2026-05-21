Rails.application.config.middleware.use OmniAuth::Builder do
  # provider :developer unless Rails.env.production?
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], provider_ignores_state: true
end

# OmniAuth 2.x requires POST by default. Allow GET so the frontend's
# <a href="/auth/google_oauth2"> link works without a CSRF form.
OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true
