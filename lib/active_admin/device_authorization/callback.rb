# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    module Callback
      module_function

      def call(callback, **arguments)
        callback&.call(**arguments)
      rescue => error
        Rails.error.report(error, handled: true)
      end
    end
  end
end
