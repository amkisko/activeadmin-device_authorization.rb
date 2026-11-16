# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "fileutils"
require_relative "spec_helper"

require_relative "dummy/config/environment"

DUMMY_ROOT = Rails.root unless defined?(DUMMY_ROOT)
FileUtils.mkdir_p(DUMMY_ROOT.join("tmp"))
FileUtils.mkdir_p(DUMMY_ROOT.join("storage"))

ActiveRecord::Base.connection_pool.with_connection do |connection|
  unless connection.table_exists?(:admin_users)
    ActiveRecord::Migration.verbose = false
    load DUMMY_ROOT.join("db/schema.rb").to_s
  end
end

require "rspec/rails"
require "capybara/rails"
require "capybara/rspec"
require "capybara-playwright-driver"
require "database_cleaner/active_record"

require_relative "support/playwright_env"
require_relative "support/capybara_playwright"
require_relative "support/device_auth_e2e_helpers"
require_relative "support/dummy_device_authorization_config"

Capybara.server = :puma, {Silent: true}

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include DeviceAuthE2eHelpers, type: :request
  config.include DeviceAuthE2eHelpers, type: :system
  config.include Capybara::DSL, type: :system

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end

  config.append_after do
    DatabaseCleaner.clean
  end

  config.before(:each, type: :request) do
    DummyDeviceAuthorizationConfig.apply!
  end

  config.before(:each, type: :system) do
    DummyDeviceAuthorizationConfig.apply!

    unless PlaywrightEnv.cli_available?
      skip PlaywrightEnv.hint
    end

    driven_by :playwright
  end
end

Rails.application.reload_routes!
ActiveAdmin.application.load! unless ActiveAdmin.application.loaded?
