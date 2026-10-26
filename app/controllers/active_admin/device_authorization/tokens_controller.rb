# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    class TokensController < ApplicationController
      include JsonResponse

      skip_forgery_protection
      before_action :enforce_rate_limit

      def create
        return if performed?

        unless params[:grant_type].to_s == TokenExchange::GRANT_TYPE
          return render_oauth_json({error: "unsupported_grant_type"}, status: :bad_request)
        end

        payload = TokenExchange.new(
          client_id: params.require(:client_id),
          device_code: params.require(:device_code)
        ).call

        render_oauth_json(payload, status: :ok)
      rescue TokenExchange::Error => error
        render_oauth_json({error: error.code}, status: error.http_status)
      end

      private

      def enforce_rate_limit
        ActiveAdmin::DeviceAuthorization.config.rate_limit_token&.call(self)
      end
    end
  end
end
