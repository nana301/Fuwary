# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.2.10
FROM ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Base packages for runtime
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libjemalloc2 \
      libvips \
      postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Build stage
FROM base AS build

# Packages needed for compiling gems / Node.js / Yarn
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      libyaml-dev \
      pkg-config \
      nodejs \
      curl \
      ruby-dev \
      make \
      g++ \
      libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Enable Yarn via corepack (Node.js に付属)
RUN corepack enable && corepack prepare yarn@stable --activate

# Copy Gemfiles and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set frozen false && bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

# Ensure asset files exist to avoid Sprockets errors
RUN mkdir -p app/assets/javascripts app/assets/stylesheets && \
    touch app/assets/javascripts/application.js app/assets/stylesheets/application.css

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]

# Final stage
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Create rails user
RUN useradd -m -s /bin/bash rails && chown -R rails:rails /rails
USER rails

# Entrypoint
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["./bin/rails", "server"]
