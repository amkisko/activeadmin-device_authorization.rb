# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveAdmin::DeviceAuthorization::UserCode do
  describe ".normalize" do
    it "accepts case and punctuation differences in a generated code" do
      expect(described_class.normalize(" abcd 2345 ")).to eq("ABCD-2345")
    end

    it "leaves an incomplete code unable to match a generated code" do
      expect(described_class.normalize("ABCD-234")).to eq("ABCD-234")
    end
  end

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

  it "stops after a bounded number of collisions" do
    calls = 0
    collision = lambda do |_candidate|
      calls += 1
      true
    end

    expect {
      described_class.generate(exists: collision)
    }.to raise_error(ActiveAdmin::DeviceAuthorization::UserCode::GenerationExhausted)
    expect(calls).to eq(100)
  end
end
