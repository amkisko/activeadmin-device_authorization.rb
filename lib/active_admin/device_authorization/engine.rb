# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    class Engine < ::Rails::Engine
      initializer "active_admin.device_authorization.locales" do |app|
        app.config.i18n.load_path += Dir[
          root.join("config/locales/*.{rb,yml}")
        ]
      end
    end
  end
end
