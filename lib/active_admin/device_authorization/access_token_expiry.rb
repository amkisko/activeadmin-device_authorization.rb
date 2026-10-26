# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    # Pure expiry policy for bearer access tokens.
    # absolute_expires_at and last_used_at are Time-like; config TTLs are seconds or nil.
    class AccessTokenExpiry
      def initialize(config: ActiveAdmin::DeviceAuthorization.config)
        @config = config
      end

      def expired?(absolute_expires_at:, last_used_at:, revoked_at:, now: Time.current)
        return true if revoked_at.present?
        if @config.absolute_expiry_enabled? && absolute_expires_at.present? && absolute_expires_at <= now
          return true
        end
        if @config.idle_expiry_enabled? && last_used_at.present? &&
            last_used_at <= now - @config.access_token_idle_ttl.to_i
          return true
        end

        false
      end

      def expires_in_seconds(absolute_expires_at:, last_used_at:, now: Time.current)
        candidates = []
        if @config.absolute_expiry_enabled? && absolute_expires_at.present?
          candidates << (absolute_expires_at - now).to_i
        end
        if @config.idle_expiry_enabled? && last_used_at.present?
          candidates << (last_used_at + @config.access_token_idle_ttl.to_i - now).to_i
        end
        return nil if candidates.empty?

        [candidates.min, 0].max
      end

      def absolute_expires_at_for(ttl_seconds:, now: Time.current)
        return nil unless @config.absolute_expiry_enabled?

        clamped = @config.clamp_absolute_ttl(ttl_seconds) || @config.access_token_default_absolute_ttl.to_i
        now + clamped
      end
    end
  end
end
