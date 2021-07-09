# frozen_string_literal: true

Doorkeeper.configure do
  orm :active_record

  resource_owner_from_credentials do |routes|
    email = "#{params[:email]}".downcase
    Rails.logger.info email
    puts(email)
    puts "Calling user search!"
    # return if email.blank?
    puts (User.find_by(email: email).id)
    user = User.find_by(email: email)
    puts(user)
    if user
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
