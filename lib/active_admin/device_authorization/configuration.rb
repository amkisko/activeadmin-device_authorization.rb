# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    # Host-facing knobs for RFC 8628 device authorization and bearer access tokens.
    #
    # Challenge lifetime and poll interval follow RFC 8628 (expires_in required;
    # interval defaults to 5 when omitted). Access-token absolute and idle TTLs
    # follow common OAuth practice (short-lived bearer; idle + absolute caps as
    # in major IdP refresh/access policies). Either access-token TTL may be nil
    # to disable that axis; both nil means revoke-only expiry.
    class Configuration
      DEFAULT_USER_CODE_ALPHABET = (
        ("A".."Z").to_a + ("2".."9").to_a - %w[I O]
      ).freeze

      attr_accessor :resource_owner_class_name,
        :client_class_name,
        :grant_class_name,
        :access_token_class_name,
        :current_resource_owner,
        :challenge_expires_in,
        :poll_interval,
        :slow_down_increment,
        :access_token_absolute_ttl,
        :access_token_idle_ttl,
        :access_token_default_absolute_ttl,
        :access_token_min_absolute_ttl,
        :access_token_max_absolute_ttl,
        :access_token_absolute_ttl_choices,
        :user_code_character_count,
        :user_code_group_size,
        :user_code_alphabet,
        :verification_path,
        :oauth_path_prefix,
        :path_namespace,
        :scopes,
        :default_scopes,
        :scope_labels,
        :grant_retention_period,
        :token_retention_period,
        :retention_batch_size,
        :token_digest,
        :on_consent_approved,
        :on_consent_denied,
        :on_token_issued,
        # Callable(controller) -> truthy to continue approve, falsy if the host
        # already redirected (step-up, etc.).
        :before_approve,
        # Callable(controller) for GET/POST step-up page_action when present.
        :on_approve_step_up,
        :rate_limit_device_authorization,
        :rate_limit_token,
        :register_active_admin_page,
        :menu_parent,
        :menu_priority,
        :menu_label,
        :verification_base_url

      def initialize
        @resource_owner_class_name = "AdminUser"
        @client_class_name = "DeviceAuthorizationClient"
        @grant_class_name = "DeviceAuthorizationGrant"
        @access_token_class_name = "DeviceAuthorizationAccessToken"
        @current_resource_owner = ->(controller) { controller.send(:current_admin_user) }

        # RFC 8628 example uses 1800s; Doorkeeper device grant defaults to 300s.
        # Ten minutes is a practical admin-consent window.
        @challenge_expires_in = 10 * 60
        @poll_interval = 5
        @slow_down_increment = 5

        @access_token_absolute_ttl = 4 * 60 * 60
        @access_token_idle_ttl = 60 * 60
        @access_token_default_absolute_ttl = 60 * 60
        @access_token_min_absolute_ttl = 60 * 60
        @access_token_max_absolute_ttl = 4 * 60 * 60
        @access_token_absolute_ttl_choices = [1, 2, 3, 4].map { |hours| hours * 60 * 60 }

        @user_code_character_count = 8
        @user_code_group_size = 4
        @user_code_alphabet = DEFAULT_USER_CODE_ALPHABET

        @verification_path = "device_auth"
        @oauth_path_prefix = "oauth"
        @path_namespace = :admin

        @scopes = []
        @default_scopes = []
        @scope_labels = {}

        @grant_retention_period = 3 * 24 * 60 * 60
        @token_retention_period = 30 * 24 * 60 * 60
        @retention_batch_size = 1000

        @token_digest = ->(plaintext) { Digest::SHA256.hexdigest(plaintext.to_s) }

        @on_consent_approved = nil
        @on_consent_denied = nil
        @on_token_issued = nil
        @before_approve = nil
        @on_approve_step_up = nil
        @rate_limit_device_authorization = nil
        @rate_limit_token = nil

        @register_active_admin_page = true
        @menu_parent = "Admin"
        @menu_priority = 91
        @menu_label = nil
        @verification_base_url = nil
      end

      def resource_owner_class
        resource_owner_class_name.constantize
      end

      def client_class
        client_class_name.constantize
      end

      def grant_class
        grant_class_name.constantize
      end

      def access_token_class
        access_token_class_name.constantize
      end

      def absolute_expiry_enabled?
        !access_token_absolute_ttl.nil?
      end

      def idle_expiry_enabled?
        !access_token_idle_ttl.nil?
      end

      def digest(plaintext)
        token_digest.call(plaintext)
      end

      def label_for_scope(scope)
        key = scope.to_s
        return scope_labels[key] if scope_labels.key?(key)
        return scope_labels[key.to_sym] if scope_labels.key?(key.to_sym)

        key
      end

      def normalize_scopes(requested)
        allowed = Array(scopes).map(&:to_s)
        Array(requested).flatten.compact.map(&:to_s).map(&:strip).uniq.select { |scope| allowed.include?(scope) }
      end

      def validate_rate_limits!
        [:rate_limit_device_authorization, :rate_limit_token].each do |setting|
          raise ArgumentError, "#{setting} must be callable" unless public_send(setting).respond_to?(:call)
        end
      end

      # Hard ceiling is access_token_absolute_ttl. Consent max cannot exceed it.
      def effective_max_absolute_ttl
        return nil unless absolute_expiry_enabled?

        [access_token_max_absolute_ttl.to_i, access_token_absolute_ttl.to_i].min
      end

      def clamp_absolute_ttl(seconds)
        return nil unless absolute_expiry_enabled?

        value = seconds.to_i
        value = access_token_default_absolute_ttl.to_i if value <= 0
        min = access_token_min_absolute_ttl.to_i
        max = effective_max_absolute_ttl
        value.clamp(min, max)
      end

      def validate!
        if challenge_expires_in.to_i <= 0
          raise ArgumentError, "challenge_expires_in must be a positive number of seconds (RFC 8628 expires_in)"
        end
        if poll_interval.to_i <= 0
          raise ArgumentError, "poll_interval must be a positive number of seconds (RFC 8628 interval)"
        end
        if slow_down_increment.to_i <= 0
          raise ArgumentError, "slow_down_increment must be a positive number of seconds (RFC 8628 slow_down)"
        end
        if absolute_expiry_enabled?
          validate_absolute_ttl_window!
        end
        if idle_expiry_enabled? && access_token_idle_ttl.to_i <= 0
          raise ArgumentError, "access_token_idle_ttl must be positive when set"
        end
        true
      end

      private

      def validate_absolute_ttl_window!
        abs = access_token_absolute_ttl.to_i
        min = access_token_min_absolute_ttl.to_i
        max = access_token_max_absolute_ttl.to_i
        default = access_token_default_absolute_ttl.to_i
        raise ArgumentError, "access_token_absolute_ttl must be positive when set" if abs <= 0
        raise ArgumentError, "access_token_min_absolute_ttl must be positive" if min <= 0
        raise ArgumentError, "access_token_max_absolute_ttl must be positive" if max <= 0
        raise ArgumentError, "access_token_default_absolute_ttl must be positive" if default <= 0
        if max > abs
          raise ArgumentError,
            "access_token_max_absolute_ttl (#{max}) cannot exceed access_token_absolute_ttl (#{abs})"
        end
        if min > max
          raise ArgumentError,
            "access_token_min_absolute_ttl (#{min}) cannot exceed access_token_max_absolute_ttl (#{max})"
        end
        if default < min || default > max
          raise ArgumentError,
            "access_token_default_absolute_ttl (#{default}) must be within min..max (#{min}..#{max})"
        end
        Array(access_token_absolute_ttl_choices).each do |choice|
          seconds = choice.to_i
          next if seconds.between?(min, max)

          raise ArgumentError,
            "access_token_absolute_ttl_choices entry #{seconds} must be within min..max (#{min}..#{max})"
        end
      end
    end
  end
end
