# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    class DeviceAuthorizationsController < ApplicationController
      include JsonResponse

      skip_forgery_protection
      before_action :enforce_rate_limit

      def create
        return if performed?

        config = ActiveAdmin::DeviceAuthorization.config
        base_url = config.verification_base_url.presence || request.base_url
        result = DeviceAuthorizationRequest.new(
          client_id: params.require(:client_id),
          scopes: params[:scope].to_s.split(/\s+/),
          verification_base_url: base_url,
          config: config
        ).call

        render_oauth_json(
          {
            device_code: result.device_code,
            user_code: result.user_code,
            verification_uri: result.verification_uri,
            verification_uri_complete: result.verification_uri_complete,
            expires_in: result.expires_in,
            interval: result.interval
          },
          status: :ok
        )
      rescue ActiveRecord::RecordNotFound
        render_oauth_json({error: "invalid_client"}, status: :bad_request)
      rescue DeviceAuthorizationRequest::Error => error
        render_oauth_json({error: error.message}, status: :bad_request)
      end

      private

      def enforce_rate_limit
        limiter = ActiveAdmin::DeviceAuthorization.config.rate_limit_device_authorization
        allowed = limiter.respond_to?(:call) && limiter.call(self) == true
        return if performed? || allowed

        render_oauth_json({error: "slow_down"}, status: :too_many_requests)
      end
    end
  end
end
