FROM ruby:2.7

RUN apt-get update -qq && apt-get install

RUN gem install bundler:2.2.3
# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 3001

CMD ["bash"]
