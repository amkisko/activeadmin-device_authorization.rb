# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    module Retention
      module_function

      # Deletes tokens that have been expired or revoked longer than token_retention_period.
      # Absolute, idle, and revoke axes are all covered so a far-future absolute sentinel
      # (absolute expiry disabled) cannot retain idle-expired rows for decades.
      def call(config: ActiveAdmin::DeviceAuthorization.config)
        token_cutoff = Time.current - config.token_retention_period.to_i
        predicates = ["absolute_expires_at < ?", "revoked_at < ?"]
        binds = [token_cutoff, token_cutoff]

        if config.idle_expiry_enabled?
          idle_cutoff = Time.current -
            config.access_token_idle_ttl.to_i -
            config.token_retention_period.to_i
          predicates << "last_used_at < ?"
          binds << idle_cutoff
        end

        config.access_token_class
          .where(predicates.join(" OR "), *binds)
          .in_batches(of: config.retention_batch_size)
          .delete_all

        grant_cutoff = Time.current - config.grant_retention_period.to_i
        token_assoc = config.access_token_class_name.underscore.to_sym
        config.grant_class
          .where(challenge_expires_at: ...grant_cutoff)
          .where.missing(token_assoc)
          .in_batches(of: config.retention_batch_size)
          .delete_all
      end
    end
  end
end
