# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveAdmin::DeviceAuthorization::Configuration do
  subject(:config) { described_class.new }

  it "requires a positive challenge_expires_in" do
    config.challenge_expires_in = 0
    expect { config.validate! }.to raise_error(ArgumentError, /challenge_expires_in/)
  end

  it "allows disabling absolute and idle access-token expiry" do
    config.access_token_absolute_ttl = nil
    config.access_token_idle_ttl = nil
    expect(config.absolute_expiry_enabled?).to be(false)
    expect(config.idle_expiry_enabled?).to be(false)
    expect(config.validate!).to be(true)
  end

  it "clamps absolute ttl into the configured window" do
    expect(config.clamp_absolute_ttl(30)).to eq(config.access_token_min_absolute_ttl)
    expect(config.clamp_absolute_ttl(99_999)).to eq(config.access_token_max_absolute_ttl)
  end

  it "never clamps above access_token_absolute_ttl even when max is higher" do
    config.access_token_absolute_ttl = 3600
    config.access_token_max_absolute_ttl = 4 * 3600
    config.access_token_min_absolute_ttl = 3600
    config.access_token_default_absolute_ttl = 3600
    config.access_token_absolute_ttl_choices = [3600]

    expect(config.effective_max_absolute_ttl).to eq(3600)
    expect(config.clamp_absolute_ttl(4 * 3600)).to eq(3600)
  end

  it "rejects a consent max that exceeds the absolute ceiling" do
    config.access_token_absolute_ttl = 3600
    config.access_token_max_absolute_ttl = 4 * 3600
    expect { config.validate! }.to raise_error(ArgumentError, /cannot exceed access_token_absolute_ttl/)
  end

  it "rejects default or choices outside min..max" do
    config.access_token_min_absolute_ttl = 3600
    config.access_token_max_absolute_ttl = 2 * 3600
    config.access_token_absolute_ttl = 2 * 3600
    config.access_token_default_absolute_ttl = 4 * 3600
    expect { config.validate! }.to raise_error(ArgumentError, /default_absolute_ttl/)

    config.access_token_default_absolute_ttl = 3600
    config.access_token_absolute_ttl_choices = [3600, 99_999]
    expect { config.validate! }.to raise_error(ArgumentError, /choices entry/)
  end

  it "normalizes scopes against the allowlist" do
    config.scopes = %w[api:read api:write admin:export]
    expect(config.normalize_scopes(["api:read", "nope", "api:write"])).to eq(
      %w[api:read api:write]
    )
  end
end
