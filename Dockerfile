FROM ruby:3.0.6
WORKDIR /app

COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install
COPY . .
EXPOSE 8080
CMD ["rackup","-p","8080","-o","0.0.0.0"]