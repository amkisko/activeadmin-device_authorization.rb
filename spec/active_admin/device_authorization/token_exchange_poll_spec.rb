# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveAdmin::DeviceAuthorization::TokenExchange do
  class GrantDouble
    attr_accessor :last_poll_at, :poll_interval_seconds, :status, :updates

    def initialize
      @status = "pending"
      @last_poll_at = nil
      @poll_interval_seconds = nil
      @updates = []
    end

    def mark_expired_if_needed!
      false
    end

    def reload
      self
    end

    def update!(attrs)
      @updates << attrs.dup
      attrs.each { |key, value| public_send(:"#{key}=", value) }
    end
  end

  class ClientDouble
    def self.enabled
      self
    end

    def self.find_by(*)
      new
    end
  end

  class GrantClassDouble
    class << self
      attr_accessor :grant
    end

    def self.transaction
      yield
    end

    def self.lock
      self
    end

    def self.find_by(*)
      grant
    end
  end

  def exchange_error(exchange)
    exchange.call
  rescue described_class::Error => error
    error
  end

  before do
    ActiveAdmin::DeviceAuthorization.configure do |config|
      config.poll_interval = 5
      config.slow_down_increment = 5
      config.client_class_name = "TokenExchangePollSpecClient"
      config.grant_class_name = "TokenExchangePollSpecGrant"
    end
    stub_const("TokenExchangePollSpecClient", ClientDouble)
    stub_const("TokenExchangePollSpecGrant", GrantClassDouble)
  end

  it "raises the required poll interval after each consecutive slow_down" do
    grant = GrantDouble.new
    GrantClassDouble.grant = grant
    exchange = described_class.new(client_id: "cli", device_code: "code")

    first = exchange_error(exchange)
    expect(first.code).to eq("authorization_pending")
    expect(grant.poll_interval_seconds).to be_nil

    second = exchange_error(exchange)
    expect(second.code).to eq("slow_down")
    expect(grant.poll_interval_seconds).to eq(10)

    third = exchange_error(exchange)
    expect(third.code).to eq("slow_down")
    expect(grant.poll_interval_seconds).to eq(15)
  end

  it "still returns slow_down without raising the stored interval when the grant lacks the column" do
    grant = GrantDouble.new
    class << grant
      undef_method :poll_interval_seconds
      undef_method :poll_interval_seconds=
    end
    GrantClassDouble.grant = grant
    exchange = described_class.new(client_id: "cli", device_code: "code")

    exchange_error(exchange)
    error = exchange_error(exchange)
    expect(error.code).to eq("slow_down")
    expect(grant.updates.last.keys).to eq([:last_poll_at])
  end
end
