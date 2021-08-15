Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ['localhost:3000', 'henslowescloud.com', 'api.henslowescloud.com', 'www.henslowescloud.com', 'hcapi-env.eba-epmrxskb.us-east-1.elasticbeanstalk.com', 'd1l9ilyerlyqvc.cloudfront.net']

    resource '/api',
      :headers => :any,
      :methods => [:post],
      :max_age => 0

    resource '*',
      :headers => :any,
      :methods => [:get, :post, :delete, :put, :patch, :options, :head],
      :max_age => 0
  end
end
