# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
require "importmap-rails"

if Rails.env.test?
  Bundler.require(:default, :test, :development)
else
  Bundler.require(*Rails.groups)
end

require "devise"
require "activeadmin"
require "active_admin/device_authorization"
require "active_admin/device_authorization/engine"
require "activeadmin/graphql"

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path("..", __dir__)
    config.load_defaults "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}"
    config.eager_load = false
    config.secret_key_base = "x" * 64
    config.api_only = false
    config.active_record.maintain_test_schema = false
    gem_root = File.expand_path("../../..", __dir__)
    config.i18n.load_path += Dir[File.join(gem_root, "config/locales/*.yml")]
  end
end
