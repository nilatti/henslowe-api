FROM ruby:2.7

RUN apt-get update -qq && apt-get install
# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ENTRYPOINT ["./entrypoint.sh"]
EXPOSE 3001

# Start the main process.
CMD ["rails", "server", "-b", "0.0.0.0"]
