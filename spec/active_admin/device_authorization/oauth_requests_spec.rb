# frozen_string_literal: true

require "spec_helper"
require "action_controller"
require "action_dispatch/testing/integration"
require "active_record"
require_relative "../../../app/controllers/active_admin/device_authorization/application_controller"
require_relative "../../../app/controllers/active_admin/device_authorization/json_response"
require_relative "../../../app/controllers/active_admin/device_authorization/device_authorizations_controller"
require_relative "../../../app/controllers/active_admin/device_authorization/tokens_controller"

RSpec.describe "OAuth requests" do
  let(:config) { ActiveAdmin::DeviceAuthorization.config }
  let(:client) { double("client", allows_scopes?: true) }
  let(:enabled_clients) { double("enabled clients", find_by!: client, find_by: client) }
  let(:client_class) { double("client class", enabled: enabled_clients) }
  let(:grant_class) { double("grant class", exists?: false, create!: true) }
  let(:routes) do
    ActionDispatch::Routing::RouteSet.new.tap do |route_set|
      route_set.draw do
        namespace :admin do
          ActiveAdmin::DeviceAuthorization::Routes.draw(self)
        end
      end
    end
  end
  let(:session) { ActionDispatch::Integration::Session.new(routes) }

  before do
    config.scopes = %w[read write]
    config.rate_limit_device_authorization = ->(_controller) { true }
    config.rate_limit_token = ->(_controller) { true }
    allow(config).to receive_messages(client_class: client_class, grant_class: grant_class)
  end

  def authorize(scope: "read")
    session.post "/admin/oauth/device_authorization", params: {client_id: "public-client", scope: scope}
  end

  it "issues a challenge with both cache prevention headers" do
    authorize
    expect(session.response.status).to eq(200)
    expect(session.response.parsed_body).to include("device_code", "user_code")
    expect(session.response.headers["Cache-Control"]).to eq("no-store")
    expect(session.response.headers["Pragma"]).to eq("no-cache")
  end

  it "rejects a mixed known and unknown scope request before writing a grant" do
    expect(grant_class).not_to receive(:create!)
    authorize(scope: "read unknown")
    expect(session.response.status).to eq(400)
    expect(session.response.parsed_body).to eq("error" => "invalid_scope")
  end

  it "reports a client-disallowed scope with the protocol error" do
    allow(client).to receive(:allows_scopes?).and_return(false)
    expect(grant_class).not_to receive(:create!)
    authorize
    expect(session.response.status).to eq(400)
    expect(session.response.parsed_body).to eq("error" => "invalid_scope")
  end

  it "does not expose an unexpected argument error as a protocol response" do
    config.user_code_alphabet = []

    expect { authorize }.to raise_error(ArgumentError, "user_code_alphabet must not be empty")
  end

  it "returns 400 for an unknown public client at the device authorization endpoint" do
    allow(enabled_clients).to receive(:find_by!).and_raise(ActiveRecord::RecordNotFound)

    authorize

    expect(session.response.status).to eq(400)
    expect(session.response.parsed_body).to eq("error" => "invalid_client")
  end

  it "returns 400 for an unknown public client at the token endpoint" do
    allow(enabled_clients).to receive(:find_by).and_return(nil)

    session.post "/admin/oauth/token", params: {
      client_id: "unknown", device_code: "device-code",
      grant_type: ActiveAdmin::DeviceAuthorization::TokenExchange::GRANT_TYPE
    }

    expect(session.response.status).to eq(400)
    expect(session.response.parsed_body).to eq("error" => "invalid_client")
  end

  it "does not filter repeated supported scopes into an invalid request" do
    expect(grant_class).to receive(:create!).with(hash_including(requested_scopes: %w[read write]))
    authorize(scope: "read write read")
    expect(session.response.status).to eq(200)
  end

  {
    device_authorization: :rate_limit_device_authorization,
    token: :rate_limit_token
  }.each do |endpoint, setting|
    [false, nil, "allowed"].each do |result|
      it "returns 429 for #{endpoint} when its limiter returns #{result.inspect}" do
        config.public_send("#{setting}=", ->(_controller) { result })
        expect(grant_class).not_to receive(:create!)
        expect(ActiveAdmin::DeviceAuthorization::TokenExchange).not_to receive(:new)
        session.post "/admin/oauth/#{endpoint}", params: {
          client_id: "public-client", scope: "read", device_code: "device-code",
          grant_type: ActiveAdmin::DeviceAuthorization::TokenExchange::GRANT_TYPE
        }
        expect(session.response.status).to eq(429)
        expect(session.response.parsed_body).to eq("error" => "slow_down")
        expect(session.response.headers["Cache-Control"]).to eq("no-store")
        expect(session.response.headers["Pragma"]).to eq("no-cache")
      end
    end

    it "keeps the host limiter response for #{endpoint}" do
      config.public_send("#{setting}=", ->(controller) { controller.head :too_many_requests })
      session.post "/admin/oauth/#{endpoint}"
      expect(session.response.status).to eq(429)
      expect(session.response.body).to be_empty
    end

    it "rejects #{endpoint} if its limiter is removed after route initialization" do
      session
      config.public_send("#{setting}=", nil)
      session.post "/admin/oauth/#{endpoint}"
      expect(session.response.status).to eq(429)
    end
  end

  it "returns a token with both cache prevention headers" do
    exchange = double(call: {access_token: "test-token", token_type: "Bearer"})
    allow(ActiveAdmin::DeviceAuthorization::TokenExchange).to receive(:new).and_return(exchange)
    session.post "/admin/oauth/token", params: {
      client_id: "public-client", device_code: "device-code",
      grant_type: ActiveAdmin::DeviceAuthorization::TokenExchange::GRANT_TYPE
    }
    expect(session.response.status).to eq(200)
    expect(session.response.parsed_body).to include("token_type" => "Bearer")
    expect(session.response.headers["Cache-Control"]).to eq("no-store")
    expect(session.response.headers["Pragma"]).to eq("no-cache")
  end
end
