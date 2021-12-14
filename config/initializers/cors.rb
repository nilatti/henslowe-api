Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ['localhost:3000', 'henslowescloud.com', 'api.henslowescloud.com', 'www.henslowescloud.com', 'https://henslowescloud.com']
    resource '*',
      headers: :any,
      methods: [:get, :post, :delete, :put, :patch, :options, :head],
      credentials: true
  end
end
