from ruby:2.7-alpine3.12

RUN addgroup -g 1001 search \
    && adduser -u 1001 -G search -s /bin/sh -D search \
    && mkdir /srv/search \
    && apk add --no-cache \
    bash gcc make cmake build-base postgresql-dev nodejs tzdata

WORKDIR /srv/search

COPY Gemfile* /srv/search/

RUN BUNDLE_VERSION=`cat Gemfile.lock | grep -A1 'BUNDLED WITH' | tail -n1` && \
    gem install bundler --version $BUNDLE_VERSION
RUN bundle install --path=vendor/bundle

COPY --chown=search:search . /srv/search
ENV RAILS_ENV=production
ENV SECRET_KEY_BASE=1
RUN bundle exec rake assets:precompile
CMD ["bundle", "exec", "rails", "s", "-p", "3000"]