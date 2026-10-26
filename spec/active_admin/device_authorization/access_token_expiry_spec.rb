# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveAdmin::DeviceAuthorization::AccessTokenExpiry do
  let(:now) { Time.utc(2026, 10, 12, 12, 0, 0) }

  it "treats revoked tokens as expired" do
    expiry = described_class.new
    expect(
      expiry.expired?(
        absolute_expires_at: now + 3600,
        last_used_at: now,
        revoked_at: now,
        now: now
      )
    ).to be(true)
  end

  it "honors absolute expiry when enabled" do
    ActiveAdmin::DeviceAuthorization.configure do |config|
      config.access_token_absolute_ttl = 3600
      config.access_token_max_absolute_ttl = 3600
      config.access_token_min_absolute_ttl = 3600
      config.access_token_default_absolute_ttl = 3600
      config.access_token_absolute_ttl_choices = [3600]
      config.access_token_idle_ttl = nil
    end
    expiry = described_class.new
    expect(
      expiry.expired?(
        absolute_expires_at: now - 1,
        last_used_at: now,
        revoked_at: nil,
        now: now
      )
    ).to be(true)
  end

  it "honors idle expiry when enabled" do
    ActiveAdmin::DeviceAuthorization.configure do |config|
      config.access_token_absolute_ttl = nil
      config.access_token_idle_ttl = 3600
    end
    expiry = described_class.new
    expect(
      expiry.expired?(
        absolute_expires_at: nil,
        last_used_at: now - 3601,
        revoked_at: nil,
        now: now
      )
    ).to be(true)
  end

  it "never expires on time axes when both TTLs are nil" do
    ActiveAdmin::DeviceAuthorization.configure do |config|
      config.access_token_absolute_ttl = nil
      config.access_token_idle_ttl = nil
    end
    expiry = described_class.new
    expect(
      expiry.expired?(
        absolute_expires_at: now - 10_000,
        last_used_at: now - 10_000,
        revoked_at: nil,
        now: now
      )
    ).to be(false)
    expect(
      expiry.expires_in_seconds(
        absolute_expires_at: now + 60,
        last_used_at: now,
        now: now
      )
    ).to be_nil
  end

  it "returns the nearer of absolute and idle remaining lifetime" do
    ActiveAdmin::DeviceAuthorization.configure do |config|
      config.access_token_absolute_ttl = 4 * 3600
      config.access_token_idle_ttl = 3600
    end
    expiry = described_class.new
    expect(
      expiry.expires_in_seconds(
        absolute_expires_at: now + 7200,
        last_used_at: now,
        now: now
      )
    ).to eq(3600)
  end
end
