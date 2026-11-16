# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    # Registers the ActiveAdmin consent page (RFC-0002). Always registers when
    # called. The engine auto-calls this from `ActiveAdmin.after_load` only when
    # `register_active_admin_page` is true; hosts may call `register!` themselves
    # when that flag is false.
    #
    # Consent auth and authorization stay on ActiveAdmin::BaseController via
    # `ActiveAdmin.routes`. Approve and deny are page_actions; index renders
    # consent when `user_code` is present.
    module Page
      module_function

      def register!
        config = ActiveAdmin::DeviceAuthorization.config
        menu_label = config.menu_label || -> { I18n.t("active_admin.device_authorization.menu") }

        ActiveAdmin.register_page "Device Auth" do
          menu parent: config.menu_parent,
            priority: config.menu_priority,
            label: menu_label

          controller do
            helper_method :device_auth_grant

            define_method(:index) do
              user_code = ActiveAdmin::DeviceAuthorization::UserCode.normalize(params[:user_code])
              if user_code.present?
                load_grant!
                @grant.mark_expired_if_needed!
                @page_title = I18n.t("active_admin.device_authorization.title")
              else
                @page_title = I18n.t("active_admin.device_authorization.enter_code")
              end
              super()
            end

            define_method(:device_auth_grant) { @grant }

            private

            define_method(:load_grant!) do
              user_code = ActiveAdmin::DeviceAuthorization::UserCode.normalize(params[:user_code])
              @grant = ActiveAdmin::DeviceAuthorization.config.grant_class
                .find_by!(user_code: user_code)
            end

            define_method(:consent_redirect_path) do
              send(
                :"#{ActiveAdmin::DeviceAuthorization.config.path_namespace}_device_auth_path",
                user_code: @grant.user_code
              )
            end
          end

          page_action :approve, method: :post do
            load_grant!
            config = ActiveAdmin::DeviceAuthorization.config
            if config.before_approve && !config.before_approve.call(self)
              return
            end

            ActiveAdmin::DeviceAuthorization::Consent.new(
              grant: @grant,
              resource_owner: config.resolve_current_resource_owner(self),
              scopes: Array(params[:scopes]),
              absolute_ttl_seconds: params[:absolute_ttl_seconds]
            ).approve!
            redirect_to consent_redirect_path,
              notice: I18n.t("active_admin.device_authorization.approved")
          rescue ActiveAdmin::DeviceAuthorization::Consent::Error => error
            redirect_to consent_redirect_path,
              alert: I18n.t(
                "active_admin.device_authorization.error.#{error.message}",
                default: error.message
              )
          end

          page_action :deny, method: :post do
            load_grant!
            config = ActiveAdmin::DeviceAuthorization.config
            ActiveAdmin::DeviceAuthorization::Consent.new(
              grant: @grant,
              resource_owner: config.resolve_current_resource_owner(self),
              scopes: @grant.requested_scopes,
              absolute_ttl_seconds: config.access_token_default_absolute_ttl
            ).deny!
            redirect_to consent_redirect_path,
              notice: I18n.t("active_admin.device_authorization.denied")
          rescue ActiveAdmin::DeviceAuthorization::Consent::Error => error
            redirect_to consent_redirect_path,
              alert: I18n.t(
                "active_admin.device_authorization.error.#{error.message}",
                default: error.message
              )
          end

          page_action :step_up, method: [:get, :post] do
            handler = ActiveAdmin::DeviceAuthorization.config.on_approve_step_up
            if handler
              handler.call(self)
            else
              redirect_to send(:"#{ActiveAdmin::DeviceAuthorization.config.path_namespace}_device_auth_path")
            end
          end

          content title: proc {
            if device_auth_grant
              I18n.t("active_admin.device_authorization.title")
            else
              I18n.t("active_admin.device_authorization.enter_code")
            end
          } do
            if device_auth_grant
              render partial: "active_admin/device_authorization/consent",
                locals: {grant: device_auth_grant}
            else
              render partial: "active_admin/device_authorization/enter_code"
            end
          end
        end
      end
    end
  end
end
