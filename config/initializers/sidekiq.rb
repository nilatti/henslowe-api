# sidekiq_config = { url: ENV['REDIS_URL'] }
# Sidekiq.configure_server do |config|
#   config.redis = sidekiq_config
# end
#
# Sidekiq.configure_client do |config|
#   config.redis = sidekiq_config
# end


Sidekiq.configure_server do |config|
  config.redis = {
    host: ENV['REDIS_HOST'],
    port: ENV['REDIS_PORT'] || '6379'
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    host: ENV['REDIS_HOST'],
    port: ENV['REDIS_PORT'] || '6379'
  }
end
