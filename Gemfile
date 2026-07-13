source 'https://rubygems.org'

ruby '~> 3.3'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0'
# Use mysql as the database for Active Record
gem 'mysql2', '~> 0.5'
# Use Puma as the app server
gem 'puma', '~> 7.0'
gem 'thin'
gem 'foreman'
gem 'jsonapi-serializer'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# Gems promoted out of Ruby stdlib in 3.1–3.4
gem 'base64'
gem 'bigdecimal'
gem 'mutex_m'
gem 'observer'
gem 'drb'
gem 'net-smtp'
# write word documents
gem 'caracal-rails'
# get line diffs
gem 'differ'
#Active Admin
gem 'omniauth-google-oauth2'
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem 'nio4r'#  , '=2.5.7'
gem 'sidekiq', '~> 7.0'
gem 'connection_pool', '~> 2.4'
gem 'activerecord-import'
# montrose provides recurrence logic
gem "montrose"
# build .ics calendar invites
gem "icalendar"
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
gem 'jwt', '~> 3.0'
gem 'acts_as_list'
gem 'stripe'
gem 'aws-sdk-s3', '~> 1', require: false
gem 'faker', '~> 3.0'

#configure request timeouts
# gem "rack-timeout"

group :development, :test do
  gem 'rspec-rails', '~> 6.0'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # gem 'dotenv-rails'
end

group :development do
  gem 'listen', '~> 3.9'
end

group :test do
  gem 'factory_bot_rails'
  gem 'shoulda-matchers', '> 3.1'
  gem 'database_cleaner'
  # gem 'selenium-webdriver'
  gem 'rspec-sidekiq'
end
