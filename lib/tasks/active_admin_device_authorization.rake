# frozen_string_literal: true

namespace :active_admin do
  namespace :device_authorization do
    desc "Delete expired device authorization records"
    task retention: :environment do
      ActiveAdmin::DeviceAuthorization::Retention.call
    end
  end
end
