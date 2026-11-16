# frozen_string_literal: true

Rails.application.config.assets.paths << Rails.root.join("app/assets") if Rails.application.config.respond_to?(:assets)
