FROM ruby:@@RUBY_VERSION@@

RUN mkdir /src
WORKDIR /src

COPY Gemfile Gemfile
COPY conjur-cli.gemspec conjur-cli.gemspec
COPY lib/conjur/version.rb lib/conjur/version.rb

# Make sure only one version of bundler is available
RUN gem uninstall bundler -i /usr/local/lib/ruby/gems/2.1.0 bundler || true && \
  gem uninstall bundler -i /usr/local/lib/ruby/gems/2.2.0 bundler || true && \
  gem uninstall bundler -aIx && \
  gem install bundler -v 1.11.2 && \
  bundle install
