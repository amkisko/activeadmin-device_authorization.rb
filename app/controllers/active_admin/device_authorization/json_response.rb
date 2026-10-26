# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    module JsonResponse
      extend ActiveSupport::Concern

      included do
        rescue_from ActionController::ParameterMissing, with: :respond_with_invalid_request
      end

      private

      def respond_with_invalid_request(_error)
        render_oauth_json({error: "invalid_request"}, status: :bad_request)
      end

      def render_oauth_json(payload, status:)
        response.set_header("Cache-Control", "no-store")
        response.set_header("Pragma", "no-cache")
        render json: payload, status: status
      end
    end
  end
end
