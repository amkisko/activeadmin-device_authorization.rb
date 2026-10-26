# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception
    end
  end
end
