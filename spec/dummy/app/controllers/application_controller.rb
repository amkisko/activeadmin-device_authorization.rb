# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Session Devise auth for ActiveAdmin HTML, or Bearer device-authorization
  # token for GraphQL / JSON (host-shaped dual gate).
  def authenticate_admin_user!
    return if current_admin_user

    if request.format.html?
      redirect_to new_admin_user_session_path
    else
      head :unauthorized
    end
  end

  def current_admin_user
    @current_admin_user ||= begin
      warden_user = request.env["warden"]&.user(:admin_user)
      warden_user || admin_user_from_device_bearer
    end
  end
  helper_method :current_admin_user

  private

  def admin_user_from_device_bearer
    header = request.headers["Authorization"].to_s
    match = header.match(/\ABearer\s+(.+)\z/i)
    return unless match

    digest = ActiveAdmin::DeviceAuthorization.config.digest(match[1])
    token = DeviceAuthorizationAccessToken.find_by(token_digest: digest)
    return unless token

    expiry = ActiveAdmin::DeviceAuthorization::AccessTokenExpiry.new
    return if expiry.expired?(
      absolute_expires_at: token.absolute_expires_at,
      last_used_at: token.last_used_at,
      revoked_at: token.revoked_at
    )

    token.update_column(:last_used_at, Time.current)
    token.admin_user
  end
end
