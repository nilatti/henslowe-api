source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.1'#, '>= 6.0.1'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.3.18', '< 0.6.0'
# Use Puma as the app server
gem 'puma', '~> 4.3'
gem 'thin'
gem 'foreman'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
gem 'jsonapi-serializer'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'
#Active Admin
gem 'devise'
gem 'devise-jwt', '~> 0.7.0'
gem 'omniauth-google-oauth2'
gem 'doorkeeper', '~> 5.4.0'
gem 'sidekiq'

gem 'activerecord-import'
# montrose provides recurrence logic
gem "montrose"
# Use Capistrano for deployment
gem 'capistrano-rails', group: :development
# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'
gem 'rubocop-rails'
gem 'rubocop-faker'
#syllable counter
gem 'syllabize'
#dependency for syllabize
gem 'numbers_and_words'
#manage who can see things
gem 'cancancan'
group :development, :test do
  gem 'rspec-rails'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # gem 'dotenv-rails'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '> 2.0.0'
end

group :test do
  gem 'factory_bot_rails'
  gem 'shoulda-matchers', '> 3.1'
  gem 'faker'
  gem 'database_cleaner'
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'selenium-webdriver'
  gem 'rspec-sidekiq'
end
