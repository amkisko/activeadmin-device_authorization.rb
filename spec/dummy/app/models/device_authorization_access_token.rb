# frozen_string_literal: true

class DeviceAuthorizationAccessToken < ApplicationRecord
  belongs_to :device_authorization_client
  belongs_to :admin_user
  belongs_to :device_authorization_grant

  serialize :scopes, type: Array, coder: YAML
end
