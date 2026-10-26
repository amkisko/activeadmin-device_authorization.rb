# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    # Thin HTML consent actions when the host does not use the ActiveAdmin page.
    # Prefer ActiveAdmin::DeviceAuthorization::Page.register! for the AA layout.
    class ConsentsController < ApplicationController
      before_action :authenticate_resource_owner!
      before_action :load_grant!, except: :index

      def index
        user_code = UserCode.normalize(params[:user_code])
        if user_code.present?
          redirect_to send(
            :"#{ActiveAdmin::DeviceAuthorization.config.path_namespace}_device_auth_grant_path",
            user_code
          )
          return
        end

        render layout: false
      end

      def show
        @grant.mark_expired_if_needed!
        render layout: false
      end

      def approve
        config = ActiveAdmin::DeviceAuthorization.config
        if config.before_approve && !config.before_approve.call(self)
          return
        end

        Consent.new(
          grant: @grant,
          resource_owner: current_resource_owner,
          scopes: Array(params[:scopes]),
          absolute_ttl_seconds: params[:absolute_ttl_seconds]
        ).approve!
        redirect_to after_consent_path, notice: I18n.t("active_admin.device_authorization.approved")
      rescue Consent::Error => error
        redirect_to after_consent_path,
          alert: I18n.t("active_admin.device_authorization.error.#{error.message}", default: error.message)
      end

      def deny
        Consent.new(
          grant: @grant,
          resource_owner: current_resource_owner,
          scopes: @grant.requested_scopes,
          absolute_ttl_seconds: ActiveAdmin::DeviceAuthorization.config.access_token_default_absolute_ttl
        ).deny!
        redirect_to after_consent_path, notice: I18n.t("active_admin.device_authorization.denied")
      rescue Consent::Error => error
        redirect_to after_consent_path,
          alert: I18n.t("active_admin.device_authorization.error.#{error.message}", default: error.message)
      end

      private

      def authenticate_resource_owner!
        return if current_resource_owner

        head :unauthorized
      end

      def current_resource_owner
        @current_resource_owner ||= ActiveAdmin::DeviceAuthorization.config.current_resource_owner.call(self)
      end

      def load_grant!
        @grant = ActiveAdmin::DeviceAuthorization.config.grant_class
          .find_by!(user_code: UserCode.normalize(params[:user_code]))
      end

      def after_consent_path
        config = ActiveAdmin::DeviceAuthorization.config
        "/#{config.path_namespace}/#{config.verification_path}/#{@grant.user_code}"
      end
    end
  end
end
