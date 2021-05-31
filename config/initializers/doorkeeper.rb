# frozen_string_literal: true

Doorkeeper.configure do
  orm :active_record

  resource_owner_from_credentials do |routes|
    email = "#{params[:email]}".downcase
    Rails.logger.info email
    return if email.blank?
    user = User.where('email = ?', email).first
    if user && user.authentication_token
      user
    else
      User.new
    end
  end
base_controller 'ApiController'
  use_refresh_token
  grant_flows %w[password]
  skip_authorization do
    true
  end
end
Doorkeeper::OAuth::TokenResponse.send :prepend, CustomTokenResponse
