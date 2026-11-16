# frozen_string_literal: true

class DeviceAuthorizationGrant < ApplicationRecord
  belongs_to :device_authorization_client
  belongs_to :admin_user, optional: true
  has_one :device_authorization_access_token, dependent: :destroy

  serialize :requested_scopes, type: Array, coder: YAML
  serialize :granted_scopes, type: Array, coder: YAML

  def pending?
    status == "pending"
  end

  def mark_expired_if_needed!
    return false if status != "pending"
    return false if challenge_expires_at.blank? || challenge_expires_at > Time.current

    update!(status: "expired")
    true
  end
end
