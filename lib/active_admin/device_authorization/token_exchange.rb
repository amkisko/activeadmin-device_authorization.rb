# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    class TokenExchange
      class Error < StandardError
        attr_reader :code, :http_status

        def initialize(code, http_status: 400)
          @code = code
          @http_status = http_status
          super(code)
        end
      end

      GRANT_TYPE = "urn:ietf:params:oauth:grant-type:device_code"

      def initialize(client_id:, device_code:, config: ActiveAdmin::DeviceAuthorization.config)
        @client_id = client_id
        @device_code = device_code
        @config = config
        @expiry = AccessTokenExpiry.new(config: config)
      end

      def call
        client = @config.client_class.enabled.find_by(client_id: @client_id)
        raise Error.new("invalid_client") unless client

        result = @config.grant_class.transaction do
          grant = @config.grant_class.lock.find_by(
            client_association => client,
            :device_code_digest => @config.digest(@device_code)
          )
          raise Error.new("invalid_grant") unless grant

          grant.mark_expired_if_needed!
          grant.reload

          case grant.status
          when "pending"
            poll_error(grant)
          when "denied"
            raise Error.new("access_denied")
          when "expired"
            raise Error.new("expired_token")
          when "approved"
            issue_or_reject_already_delivered!(grant, client)
          else
            raise Error.new("invalid_grant")
          end
        end
        raise result if result.is_a?(Error)

        Callback.call(
          @config.on_token_issued,
          resource_owner: result.fetch(:token).public_send(resource_owner_association),
          token: result.fetch(:token)
        )
        result.fetch(:payload)
      end

      private

      def client_association
        @config.client_class_name.underscore.to_sym
      end

      def resource_owner_association
        @config.resource_owner_class_name.underscore.to_sym
      end

      def access_token_association
        # has_one name on grant; default DeviceAuthorizationGrant -> device_authorization_access_token
        @config.access_token_class_name.underscore.to_sym
      end

      def issue_or_reject_already_delivered!(grant, client)
        if grant.public_send(access_token_association).present?
          raise Error.new("invalid_grant")
        end

        plaintext = SecureRandom.urlsafe_base64(32)
        now = Time.current
        ttl = grant.try(:absolute_ttl_seconds)
        absolute_expires_at = @expiry.absolute_expires_at_for(ttl_seconds: ttl, now: now)
        # Column is NOT NULL in typical hosts; when absolute expiry is disabled,
        # store a far-future sentinel so ActiveRecord hosts stay compatible.
        absolute_expires_at ||= now + (100 * 365 * 24 * 60 * 60)

        token = @config.access_token_class.create!(
          client_association => client,
          resource_owner_association => grant.public_send(resource_owner_association),
          grant_association => grant,
          :token_digest => @config.digest(plaintext),
          :scopes => grant.granted_scopes,
          :absolute_expires_at => absolute_expires_at,
          :last_used_at => now
        )
        payload = {
          access_token: plaintext,
          token_type: "Bearer",
          scope: Array(token.scopes).join(" ")
        }
        expires_in = @expiry.expires_in_seconds(
          absolute_expires_at: token.absolute_expires_at,
          last_used_at: token.last_used_at,
          now: now
        )
        payload[:expires_in] = expires_in unless expires_in.nil?
        {payload: payload, token: token}
      end

      def grant_association
        @config.grant_class_name.underscore.to_sym
      end

      def poll_error(grant)
        required = required_poll_interval(grant)
        too_fast = grant.last_poll_at.present? && grant.last_poll_at > required.seconds.ago
        attrs = {last_poll_at: Time.current}
        if too_fast
          next_interval = required + @config.slow_down_increment.to_i
          if grant.respond_to?(:poll_interval_seconds=)
            attrs[:poll_interval_seconds] = next_interval
          end
        end
        grant.update!(attrs)
        Error.new(too_fast ? "slow_down" : "authorization_pending")
      end

      # Hosts may store the raised interval on the grant (poll_interval_seconds).
      # Without that column, slow_down still gates on the base poll_interval only.
      def required_poll_interval(grant)
        base = @config.poll_interval.to_i
        stored =
          if grant.respond_to?(:poll_interval_seconds)
            grant.poll_interval_seconds
          end
        value = stored.to_i
        value.positive? ? value : base
      end
    end
  end
end
