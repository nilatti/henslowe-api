if Rails.env === 'production'
  Rails.application.config.session_store :cookie_store, key: '_henslowescloud', domain: 'henslowescloud.com'
else
  Rails.application.config.session_store :cookie_store, key: '_henslowescloud', domain: 'localhost'
end
