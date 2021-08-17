require_relative 'boot'

require "rails/all"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
# Dotenv::Railtie.load

module June20
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.

    config.load_defaults 6.0
    config.autoload_paths << "#{Rails.root}/lib"
    # config.to_prepare do
    #   DeviseController.respond_to :html, :json
    # end
    config.after_initialize do

    require 'custom_token_response'

end
    config.action_dispatch.cookies_same_site_protection = :lax
    config.action_controller.forgery_protection_origin_check = false
    config.middleware.use Rack::MethodOverride
    config.middleware.use ActionDispatch::Flash
    config.session_store :cookie_store, key: '_interslice_session'
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore, key: '_henslowe'
    config.middleware.insert_after(ActionDispatch::Cookies, ActionDispatch::Session::CookieStore, key: '_henslowe')
    config.app_generators.scaffold_controller = :scaffold_controller
    config.x.cors_allowed_origins
    config.hosts = ['localhost', 'henslowescloud.com', 'api.henslowescloud.com', 'www.henslowescloud.com']
    config.api_only = false
    config.active_job.queue_adapter = :sidekiq

  end
end
