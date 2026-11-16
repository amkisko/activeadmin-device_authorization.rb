# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Device authorization to GraphQL bearer", type: :request do
  let!(:admin) { create_admin_user! }
  let!(:client) { create_device_client! }

  it "issues a bearer token after consent and authorizes ActiveAdmin GraphQL" do
    post_record = Post.create!(title: "Hello", body: "World")
    challenge = request_device_challenge!(client_id: client.client_id)
    grant = DeviceAuthorizationGrant.find_by!(user_code: challenge.fetch("user_code"))
    ActiveAdmin::DeviceAuthorization::Consent.new(
      grant: grant,
      resource_owner: admin,
      scopes: ["api:read"],
      absolute_ttl_seconds: 3600
    ).approve!

    token_body = poll_device_token!(
      client_id: client.client_id,
      device_code: challenge.fetch("device_code")
    )
    access_token = token_body.fetch("access_token")
    expect(access_token).to be_present

    post "/admin/graphql",
      params: {query: "{ posts { nodes { id title } } }"}.to_json,
      headers: {
        "Authorization" => "Bearer #{access_token}",
        "CONTENT_TYPE" => "application/json",
        "ACCEPT" => "application/json"
      }

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["errors"]).to be_nil
    titles = body.dig("data", "posts", "nodes")&.map { |row| row["title"] }
    expect(titles).to include(post_record.title)
  end

  it "rejects GraphQL without a bearer or session" do
    post "/admin/graphql",
      params: {query: "{ posts { nodes { id } } }"}.to_json,
      headers: {
        "CONTENT_TYPE" => "application/json",
        "ACCEPT" => "application/json"
      }

    expect(response).to have_http_status(:unauthorized)
  end
end
