# frozen_string_literal: true

require "spec_helper"
require "cgi"

RSpec.describe ActiveAdmin::DeviceAuthorization::DeviceAuthorizationRequest do
  let(:config) { ActiveAdmin::DeviceAuthorization.config }
  let(:client) { double("client", allows_scopes?: true) }
  let(:enabled_clients) { double("enabled clients", find_by!: client) }
  let(:client_class) { double("client class", enabled: enabled_clients) }
  let(:grant_class) { double("grant class", exists?: false, create!: true) }

  before do
    config.scopes = %w[read]
    config.verification_base_url = "https://admin.example"
    config.path_namespace = :admin
    config.verification_path = "device_auth"
    allow(config).to receive_messages(client_class: client_class, grant_class: grant_class)
    allow(ActiveAdmin::DeviceAuthorization::UserCode).to receive(:generate).and_return("ABCD-2345")
  end

  it "builds verification_uri_complete with a user_code query parameter" do
    result = described_class.new(
      client_id: "public-client",
      scopes: ["read"],
      verification_base_url: "https://ignored.example"
    ).call

    expect(result.verification_uri).to eq("https://admin.example/admin/device_auth")
    expect(result.verification_uri_complete).to eq(
      "https://admin.example/admin/device_auth?user_code=#{CGI.escape("ABCD-2345")}"
    )
  end
end
