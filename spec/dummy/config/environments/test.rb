# frozen_string_literal: true

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = false
  config.public_file_server.enabled = true
  config.consider_all_requests_local = true
  config.cache_store = :null_store
  config.action_dispatch.show_exceptions = :rescuable
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = {host: "www.example.com"}
  config.active_support.deprecation = :stderr
  config.active_record.maintain_test_schema = false
  config.assets.compile = true if config.respond_to?(:assets)
end
