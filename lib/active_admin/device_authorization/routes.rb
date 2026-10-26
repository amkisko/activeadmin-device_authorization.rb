# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    module Routes
      # Embed under the host admin namespace, for example:
      #
      #   namespace :admin do
      #     ActiveAdmin::DeviceAuthorization::Routes.draw(self)
      #   end
      #
      # OAuth JSON endpoints always use absolute gem controller paths so nesting
      # under `namespace :admin` does not invent `Admin::ActiveAdmin::...`.
      #
      # consent: :active_admin_page (default) routes show/approve/deny to the
      # ActiveAdmin "Device Auth" page controller (`device_auth#...`).
      # consent: :controller routes them to the gem ConsentsController instead.
      def self.draw(mapper, config: ActiveAdmin::DeviceAuthorization.config, consent: :active_admin_page)
        config.validate_rate_limits!
        oauth = config.oauth_path_prefix.to_s
        verification = config.verification_path.to_s

        mapper.namespace :oauth, path: oauth do
          mapper.post :device_authorization,
            to: "/active_admin/device_authorization/device_authorizations#create"
          mapper.post :token,
            to: "/active_admin/device_authorization/tokens#create"
        end

        case consent
        when :active_admin_page
          mapper.get "#{verification}/:user_code",
            to: "device_auth#show",
            as: :device_auth_grant
          mapper.post "#{verification}/:user_code/approve",
            to: "device_auth#approve",
            as: :approve_device_auth
          mapper.post "#{verification}/:user_code/deny",
            to: "device_auth#deny",
            as: :deny_device_auth
        when :controller
          mapper.get verification,
            to: "/active_admin/device_authorization/consents#index",
            as: :device_auth
          mapper.get "#{verification}/:user_code",
            to: "/active_admin/device_authorization/consents#show",
            as: :device_auth_grant
          mapper.post "#{verification}/:user_code/approve",
            to: "/active_admin/device_authorization/consents#approve",
            as: :approve_device_auth
          mapper.post "#{verification}/:user_code/deny",
            to: "/active_admin/device_authorization/consents#deny",
            as: :deny_device_auth
        else
          raise ArgumentError, "consent must be :active_admin_page or :controller (got #{consent.inspect})"
        end
      end
    end
  end
end
