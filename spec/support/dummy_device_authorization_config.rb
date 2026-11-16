# frozen_string_literal: true

module DummyDeviceAuthorizationConfig
  module_function

  # Unit examples call reset_config! and mutate the shared singleton. Restore the
  # dummy host knobs before each request/system example so OAuth draw and scopes
  # match the initializer under spec/dummy.
  def apply!
    ActiveAdmin::DeviceAuthorization.configure do |config|
      config.resource_owner_class_name = "AdminUser"
      config.client_class_name = "DeviceAuthorizationClient"
      config.grant_class_name = "DeviceAuthorizationGrant"
      config.access_token_class_name = "DeviceAuthorizationAccessToken"
      config.current_resource_owner = -> { current_admin_user }
      config.scopes = %w[api:read]
      config.default_scopes = %w[api:read]
      config.scope_labels = {"api:read" => "API read"}
      config.verification_base_url = "http://www.example.com"
      config.rate_limit_device_authorization = ->(_controller) { true }
      config.rate_limit_token = ->(_controller) { true }
      config.register_active_admin_page = true
      config.menu_parent = nil
    end
  end
end
