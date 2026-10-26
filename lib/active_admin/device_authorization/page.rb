# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    # Registers the ActiveAdmin consent page. Call after ActiveAdmin.load! setup,
    # typically from config/initializers/active_admin_device_authorization.rb once
    # host scopes and model class names are configured.
    module Page
      module_function

      def register!
        config = ActiveAdmin::DeviceAuthorization.config
        return unless config.register_active_admin_page

        menu_label = config.menu_label || -> { I18n.t("active_admin.device_authorization.menu") }
        verification = config.verification_path

        ActiveAdmin.register_page "Device Auth" do
          menu parent: config.menu_parent,
            priority: config.menu_priority,
            label: menu_label

          controller do
            helper_method :device_auth_grant

            define_method(:index) do
              user_code = ActiveAdmin::DeviceAuthorization::UserCode.normalize(params[:user_code])
              if user_code.present?
                redirect_to send(:"#{config.path_namespace}_device_auth_grant_path", user_code)
                return
              end

              @page_title = I18n.t("active_admin.device_authorization.enter_code")
              super()
            end

            define_method(:show) do
              load_grant!
              @grant.mark_expired_if_needed!
              @page_title = I18n.t("active_admin.device_authorization.title")
              render "active_admin/page/index"
            end

            define_method(:approve) do
              load_grant!
              if config.before_approve && !config.before_approve.call(self)
                return
              end

              ActiveAdmin::DeviceAuthorization::Consent.new(
                grant: @grant,
                resource_owner: config.current_resource_owner.call(self),
                scopes: Array(params[:scopes]),
                absolute_ttl_seconds: params[:absolute_ttl_seconds]
              ).approve!
              redirect_to send(:"#{config.path_namespace}_device_auth_grant_path", @grant.user_code),
                notice: I18n.t("active_admin.device_authorization.approved")
            rescue ActiveAdmin::DeviceAuthorization::Consent::Error => error
              redirect_to send(:"#{config.path_namespace}_device_auth_grant_path", @grant.user_code),
                alert: I18n.t(
                  "active_admin.device_authorization.error.#{error.message}",
                  default: error.message
                )
            end

            define_method(:deny) do
              load_grant!
              ActiveAdmin::DeviceAuthorization::Consent.new(
                grant: @grant,
                resource_owner: config.current_resource_owner.call(self),
                scopes: @grant.requested_scopes,
                absolute_ttl_seconds: config.access_token_default_absolute_ttl
              ).deny!
              redirect_to send(:"#{config.path_namespace}_device_auth_grant_path", @grant.user_code),
                notice: I18n.t("active_admin.device_authorization.denied")
            rescue ActiveAdmin::DeviceAuthorization::Consent::Error => error
              redirect_to send(:"#{config.path_namespace}_device_auth_grant_path", @grant.user_code),
                alert: I18n.t(
                  "active_admin.device_authorization.error.#{error.message}",
                  default: error.message
                )
            end

            define_method(:device_auth_grant) { @grant }

            define_method(:page_presenter) do
              if action_name == "show"
                active_admin_config.get_page_presenter(:index)
              else
                super()
              end
            end

            private

            define_method(:load_grant!) do
              user_code = ActiveAdmin::DeviceAuthorization::UserCode.normalize(params[:user_code])
              @grant = config.grant_class.find_by!(user_code: user_code)
            end
          end

          page_action :step_up, method: [:get, :post] do
            handler = ActiveAdmin::DeviceAuthorization.config.on_approve_step_up
            if handler
              handler.call(self)
            else
              redirect_to send(:"#{ActiveAdmin::DeviceAuthorization.config.path_namespace}_device_auth_path")
            end
          end

          content title: proc { I18n.t("active_admin.device_authorization.title") } do
            if device_auth_grant
              render partial: "active_admin/device_authorization/consent",
                locals: {grant: device_auth_grant}
            else
              render partial: "active_admin/device_authorization/enter_code"
            end
          end
        end

        # Host must also route show/approve/deny; Page only registers the AA index shell.
        verification
      end
    end
  end
end
