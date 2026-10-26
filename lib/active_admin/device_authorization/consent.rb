# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    class Consent
      class Error < StandardError; end

      def initialize(grant:, resource_owner:, scopes:, absolute_ttl_seconds:, config: ActiveAdmin::DeviceAuthorization.config)
        @grant = grant
        @resource_owner = resource_owner
        @scopes = config.normalize_scopes(scopes)
        @absolute_ttl_seconds = config.clamp_absolute_ttl(absolute_ttl_seconds)
        @config = config
      end

      def approve!
        @grant.with_lock do
          raise Error, "not_pending" unless @grant.pending?
          raise Error, "expired" if @grant.mark_expired_if_needed!
          raise Error, "invalid_scope" if @scopes.empty?
          raise Error, "unsupported_scope" unless client.allows_scopes?(@scopes)
          raise Error, "scope_not_requested" unless (@scopes - @grant.requested_scopes).empty?
          if @resource_owner.respond_to?(:active_for_authentication?) && !@resource_owner.active_for_authentication?
            raise Error, "resource_owner_inactive"
          end

          attrs = {
            status: "approved",
            granted_scopes: @scopes
          }
          attrs[resource_owner_association] = @resource_owner
          attrs[:absolute_ttl_seconds] = @absolute_ttl_seconds if @grant.respond_to?(:absolute_ttl_seconds=)
          @grant.update!(attrs)
        end
        @config.on_consent_approved&.call(resource_owner: @resource_owner, grant: @grant)
        @grant
      end

      def deny!
        @grant.with_lock do
          raise Error, "not_pending" unless @grant.pending?
          @grant.mark_expired_if_needed!
          raise Error, "expired" if @grant.status == "expired"

          attrs = {status: "denied"}
          attrs[resource_owner_association] = @resource_owner
          @grant.update!(attrs)
        end
        @config.on_consent_denied&.call(resource_owner: @resource_owner, grant: @grant)
        @grant
      end

      private

      def client
        association = @config.client_class_name.underscore
        @grant.public_send(association)
      end

      def resource_owner_association
        @config.resource_owner_class_name.underscore.to_sym
      end
    end
  end
end
