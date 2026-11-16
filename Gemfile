# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# Prerelease until ActiveAdmin 4.0.0 is stable; gemspec floor is >= 4.0.0.beta19.
gem "activeadmin", "4.0.0.beta23"

group :development, :test do
  gem "devise", ">= 4.9"
  gem "sqlite3", ">= 2.1"
  gem "sprockets-rails"
  gem "cssbundling-rails"
  gem "importmap-rails"
  gem "puma", ">= 5.0"
  gem "rspec-rails", ">= 6"
  gem "capybara", "~> 3.40"
  gem "capybara-playwright-driver", "~> 0.5"
  gem "database_cleaner-active_record", "~> 2.2"
  gem "activeadmin-graphql", ">= 0.4.1"
end
