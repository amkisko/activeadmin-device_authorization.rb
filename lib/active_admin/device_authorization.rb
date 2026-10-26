# frozen_string_literal: true

require "digest"
require "securerandom"
require "active_support"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/numeric/time"

require_relative "device_authorization/version"
require_relative "device_authorization/configuration"
require_relative "device_authorization/callback"
require_relative "device_authorization/user_code"
require_relative "device_authorization/access_token_expiry"
require_relative "device_authorization/device_authorization_request"
require_relative "device_authorization/consent"
require_relative "device_authorization/token_exchange"
require_relative "device_authorization/retention"
require_relative "device_authorization/routes"
require_relative "device_authorization/page"

module ActiveAdmin
  module DeviceAuthorization
    class << self
      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
        config.validate!
        config
      end

      def reset_config!
        @config = Configuration.new
      end
    end
  end
end

require_relative "device_authorization/engine" if defined?(Rails::Engine)
