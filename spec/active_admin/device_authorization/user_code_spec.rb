# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveAdmin::DeviceAuthorization::UserCode do
  it "generates grouped codes from the alphabet" do
    code = described_class.generate
    expect(code).to match(/\A[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}\z/)
  end

  it "retries when the exists callback reports a collision" do
    calls = 0
    code = described_class.generate(
      exists: lambda { |_candidate|
        calls += 1
        calls == 1
      }
    )
    expect(calls).to eq(2)
    expect(code).to be_a(String)
  end
end
