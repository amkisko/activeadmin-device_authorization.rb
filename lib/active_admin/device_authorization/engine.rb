# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    class Engine < ::Rails::Engine
      initializer "active_admin.device_authorization.locales" do |app|
        app.config.i18n.load_path += Dir[
          root.join("config/locales/*.{rb,yml}")
        ]
      end

      initializer "active_admin.device_authorization.filter_parameters" do |app|
        app.config.filter_parameters |= [:device_code, :user_code, :access_token]
      end
    end
  end
end
