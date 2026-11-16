# frozen_string_literal: true

ActiveAdmin.after_load do |app|
  app.namespaces[:admin].graphql = true
  app.namespaces[:admin].graphql_visibility = {preload: false}
end

Rails.application.config.to_prepare do
  next unless defined?(ActiveAdmin::GraphqlController)

  ActiveAdmin::GraphqlController.class_eval do
    skip_forgery_protection if: -> {
      request.headers["Authorization"].to_s.match?(/\Abearer\s+/i)
    }
  end
end
