# frozen_string_literal: true

module DeviceAuthE2eHelpers
  def create_admin_user!(email: "admin@example.com", password: "password123")
    AdminUser.create!(email: email, password: password, password_confirmation: password)
  end

  def create_device_client!(client_id: "e2e-client", scopes: %w[api:read])
    DeviceAuthorizationClient.create!(
      client_id: client_id,
      name: "E2E client",
      enabled: true,
      allowed_scopes: scopes
    )
  end

  def request_device_challenge!(client_id: "e2e-client", scope: "api:read")
    post "/admin/oauth/device_authorization",
      params: {client_id: client_id, scope: scope},
      as: :json
    expect(response).to have_http_status(:ok)
    JSON.parse(response.body)
  end

  def poll_device_token!(client_id:, device_code:)
    post "/admin/oauth/token",
      params: {
        client_id: client_id,
        device_code: device_code,
        grant_type: ActiveAdmin::DeviceAuthorization::TokenExchange::GRANT_TYPE
      },
      as: :json
    JSON.parse(response.body)
  end

  def sign_in_admin_via_ui!(email:, password:)
    visit new_admin_user_session_path
    fill_in "Email", with: email
    fill_in "Password", with: password
    click_button "Login"
  end
end
