# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveAdmin::DeviceAuthorization::Consent do
  let(:client) { double("client", allows_scopes?: true) }
  let(:grant) do
    double(
      "grant",
      pending?: true,
      mark_expired_if_needed!: false,
      status: "pending",
      requested_scopes: ["read"],
      device_authorization_client: client
    )
  end
  let(:resource_owner) { Object.new }

  before do
    allow(grant).to receive(:with_lock).and_yield
    allow(grant).to receive(:update!)
    ActiveAdmin::DeviceAuthorization.config.scopes = ["read"]
  end

  it "reports an approval callback failure without hiding committed consent" do
    callback_error = RuntimeError.new("audit unavailable")
    ActiveAdmin::DeviceAuthorization.config.on_consent_approved = ->(**) { raise callback_error }
    allow(Rails.error).to receive(:report)

    result = described_class.new(
      grant: grant,
      resource_owner: resource_owner,
      scopes: ["read"],
      absolute_ttl_seconds: nil
    ).approve!

    expect(result).to equal(grant)
    expect(Rails.error).to have_received(:report).with(callback_error, handled: true)
  end

  it "reports a denial callback failure without hiding committed consent" do
    callback_error = RuntimeError.new("audit unavailable")
    ActiveAdmin::DeviceAuthorization.config.on_consent_denied = ->(**) { raise callback_error }
    allow(Rails.error).to receive(:report)

    result = described_class.new(
      grant: grant,
      resource_owner: resource_owner,
      scopes: ["read"],
      absolute_ttl_seconds: nil
    ).deny!

    expect(result).to equal(grant)
    expect(Rails.error).to have_received(:report).with(callback_error, handled: true)
  end
end
