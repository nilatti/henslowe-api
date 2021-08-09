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
    config.to_prepare do
      DeviseController.respond_to :html, :json
    end
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', :headers => :any, :methods => [:get, :post, :options]
      end
    end
    config.after_initialize do

    require 'custom_token_response'

end
    config.middleware.use Rack::MethodOverride
    config.middleware.use ActionDispatch::Flash
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore
    config.app_generators.scaffold_controller = :scaffold_controller
    config.x.cors_allowed_origins
    config.hosts = ['localhost', 'www.example.com', 'henslowescloud.com', 'api.henslowescloud.com']
    # config.hosts = 'henslowescloud.com'
    config.api_only = true
    config.active_job.queue_adapter = :sidekiq

  end
end
