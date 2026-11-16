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

      # Register the consent page after ActiveAdmin loads admin files (RFC-0002).
      # Auto-register only when register_active_admin_page is true; hosts may still
      # call Page.register! manually when that flag is false.
      initializer "active_admin.device_authorization.page", after: :load_config_initializers do
        ActiveAdmin.after_load do
          if ActiveAdmin::DeviceAuthorization.config.register_active_admin_page
            ActiveAdmin::DeviceAuthorization::Page.register!
          end
        end

        if defined?(ActiveAdmin) &&
            ActiveAdmin.application.respond_to?(:loaded?) &&
            ActiveAdmin.application.loaded? &&
            ActiveAdmin::DeviceAuthorization.config.register_active_admin_page
          ActiveAdmin::DeviceAuthorization::Page.register!
        end
      end
    end
  end
end
