# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    class DeviceAuthorizationRequest
      Result = Data.define(
        :device_code,
        :user_code,
        :verification_uri,
        :verification_uri_complete,
        :expires_in,
        :interval
      )

      def initialize(client_id:, scopes:, verification_base_url:, config: ActiveAdmin::DeviceAuthorization.config)
        @client_id = client_id
        @scopes = config.normalize_scopes(scopes)
        @verification_base_url = verification_base_url
        @config = config
      end

      def call
        client = @config.client_class.enabled.find_by!(client_id: @client_id)
        raise ArgumentError, "invalid_scope" if @scopes.empty?
        raise ArgumentError, "unsupported_scope" unless client.allows_scopes?(@scopes)

        device_code = SecureRandom.urlsafe_base64(32)
        user_code = UserCode.generate(
          config: @config,
          exists: ->(code) { @config.grant_class.exists?(user_code: code) }
        )

        @config.grant_class.create!(
          client_association_name => client,
          device_code_digest: @config.digest(device_code),
          user_code: user_code,
          requested_scopes: @scopes,
          status: "pending",
          challenge_expires_at: Time.current + @config.challenge_expires_in.to_i
        )

        verification_uri = build_verification_uri
        Result.new(
          device_code: device_code,
          user_code: user_code,
          verification_uri: verification_uri,
          verification_uri_complete: "#{verification_uri}/#{user_code}",
          expires_in: @config.challenge_expires_in.to_i,
          interval: @config.poll_interval.to_i
        )
      end

      private

      def client_association_name
        @config.client_class_name.underscore.to_sym
      end

      def build_verification_uri
        base = (@config.verification_base_url.presence || @verification_base_url).to_s.chomp("/")
        path = [@config.path_namespace, @config.verification_path].compact.join("/")
        File.join(base, path)
      end
    end
  end
end
