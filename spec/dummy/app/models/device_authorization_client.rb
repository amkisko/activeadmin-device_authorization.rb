# frozen_string_literal: true

class DeviceAuthorizationClient < ApplicationRecord
  has_many :device_authorization_grants, dependent: :destroy
  has_many :device_authorization_access_tokens, dependent: :destroy

  scope :enabled, -> { where(enabled: true) }

  serialize :allowed_scopes, type: Array, coder: YAML

  def allows_scopes?(scopes)
    (Array(scopes).map(&:to_s) - Array(allowed_scopes).map(&:to_s)).empty?
  end
end
