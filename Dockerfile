FROM ruby:3.3

RUN apt-get update -qq && apt-get install -y build-essential default-libmysqlclient-dev pkg-config

RUN gem install bundler:2.5.23
WORKDIR /app

COPY Gemfile ./
RUN bundle install

COPY . .

EXPOSE 3001

CMD ["bash"]
