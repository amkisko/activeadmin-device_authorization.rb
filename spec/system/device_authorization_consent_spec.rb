# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Device authorization consent", type: :system do
  let!(:admin) { create_admin_user! }
  let!(:client) { create_device_client! }

  def issue_challenge
    ActiveAdmin::DeviceAuthorization::DeviceAuthorizationRequest.new(
      client_id: client.client_id,
      scopes: ["api:read"],
      verification_base_url: "http://www.example.com"
    ).call
  end

  it "lets a signed-in admin approve a device challenge on the ActiveAdmin page" do
    challenge = issue_challenge

    visit new_admin_user_session_path
    fill_in "Email", with: admin.email
    fill_in "Password", with: "password123"
    find('input[type="submit"]').click

    visit "/admin/device_auth?user_code=#{CGI.escape(challenge.user_code)}"

    expect(page).to have_content(challenge.user_code)
    expect(page).to have_button(I18n.t("active_admin.device_authorization.approve"))
    click_button I18n.t("active_admin.device_authorization.approve")

    expect(page).to have_content(I18n.t("active_admin.device_authorization.approved"))
      .or have_content(challenge.user_code)

    grant = DeviceAuthorizationGrant.find_by!(user_code: challenge.user_code)
    expect(grant.status).to eq("approved")
    expect(grant.admin_user_id).to eq(admin.id)
  end

  it "rejects consent when the admin is not signed in" do
    challenge = issue_challenge
    visit "/admin/device_auth?user_code=#{CGI.escape(challenge.user_code)}"

    expect(page).to have_current_path(new_admin_user_session_path, ignore_query: true)
      .or have_content(/sign in|login|email/i)
    expect(DeviceAuthorizationGrant.find_by!(user_code: challenge.user_code).status).to eq("pending")
  end
end
