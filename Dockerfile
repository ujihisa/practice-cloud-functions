FROM ruby:3.0.0

RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 8080

CMD \
      bundle exec ruby -e 'p :ok'
