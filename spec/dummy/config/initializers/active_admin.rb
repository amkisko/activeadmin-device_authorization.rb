# frozen_string_literal: true

ActiveAdmin.setup do |config|
  config.load_paths = [
    Rails.root.join("config/active_admin").to_s,
    Rails.root.join("app/admin").to_s
  ]
  config.default_namespace = :admin
  config.authentication_method = :authenticate_admin_user!
  config.current_user_method = :current_admin_user
  config.site_title = "Device Auth Dummy"
  config.logout_link_path = :destroy_admin_user_session_path
  config.batch_actions = true
end
