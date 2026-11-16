# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    module Routes
      # Draw public OAuth JSON endpoints only (RFC-0002).
      #
      #   ActiveAdmin.routes(self)
      #   ActiveAdmin::DeviceAuthorization::Routes.draw(self)
      #
      # Call at the routes root. `draw` applies `config.path_namespace` itself;
      # nesting under another `namespace :admin` double-prefixes the path.
      # Consent UI is owned by the ActiveAdmin page (`Page.register!` /
      # `ActiveAdmin.routes`); do not declare consent routes here.
      #
      # OAuth controllers use absolute gem paths so the admin namespace does not
      # invent `Admin::ActiveAdmin::...` constants. They do not use the admin
      # session; rate-limit procs and protocol parameters gate access.
      def self.draw(mapper, config: ActiveAdmin::DeviceAuthorization.config)
        config.validate_rate_limits!
        oauth = config.oauth_path_prefix.to_s

        mapper.namespace config.path_namespace do
          mapper.namespace :oauth, path: oauth do
            mapper.post :device_authorization,
              to: "/active_admin/device_authorization/device_authorizations#create"
            mapper.post :token,
              to: "/active_admin/device_authorization/tokens#create"
          end
        end
      end
    end
  end
end
