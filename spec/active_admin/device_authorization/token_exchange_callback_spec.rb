# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveAdmin::DeviceAuthorization::TokenExchange do
  class CallbackClient
    def self.enabled
      self
    end

    def self.find_by(*)
      new
    end
  end

  class CallbackGrantRecord
    attr_reader :callback_owner

    def initialize(callback_owner: Object.new)
      @callback_owner = callback_owner
    end

    def mark_expired_if_needed!
      false
    end

    def reload
      self
    end

    def status
      "approved"
    end

    def callback_access_token
      nil
    end

    def granted_scopes
      ["read"]
    end

    def absolute_ttl_seconds
      nil
    end
  end

  class CallbackGrantClass
    class << self
      attr_accessor :fail_commit, :grant, :transaction_open
    end

    def self.transaction
      self.transaction_open = true
      result = yield
      raise "commit failed" if fail_commit

      result
    ensure
      self.transaction_open = false
    end

    def self.lock
      self
    end

    def self.find_by(*)
      grant
    end
  end

  class CallbackAccessToken
    attr_reader :callback_owner, :absolute_expires_at, :last_used_at, :scopes

    def self.create!(attributes)
      new(attributes)
    end

    def initialize(attributes)
      @callback_owner = attributes.fetch(:callback_owner)
      @absolute_expires_at = attributes.fetch(:absolute_expires_at)
      @last_used_at = attributes.fetch(:last_used_at)
      @scopes = attributes.fetch(:scopes)
    end
  end

  before do
    stub_const("CallbackClient", CallbackClient)
    stub_const("CallbackGrant", CallbackGrantClass)
    stub_const("CallbackAccessToken", CallbackAccessToken)
    CallbackGrantClass.grant = CallbackGrantRecord.new
    CallbackGrantClass.fail_commit = false
    CallbackGrantClass.transaction_open = false

    ActiveAdmin::DeviceAuthorization.configure do |config|
      config.client_class_name = "CallbackClient"
      config.grant_class_name = "CallbackGrant"
      config.access_token_class_name = "CallbackAccessToken"
      config.resource_owner_class_name = "CallbackOwner"
    end
  end

  it "calls on_token_issued after committing the issued token" do
    transaction_states = []
    ActiveAdmin::DeviceAuthorization.config.on_token_issued = ->(**) {
      transaction_states << CallbackGrantClass.transaction_open
    }

    result = described_class.new(client_id: "client", device_code: "code").call

    expect(result).to include(token_type: "Bearer", scope: "read")
    expect(transaction_states).to eq([false])
  end

  it "does not call on_token_issued when the transaction cannot commit" do
    callback = spy("token callback")
    ActiveAdmin::DeviceAuthorization.config.on_token_issued = callback
    CallbackGrantClass.fail_commit = true

    expect {
      described_class.new(client_id: "client", device_code: "code").call
    }.to raise_error("commit failed")
    expect(callback).not_to have_received(:call)
  end

  it "reports a callback failure without hiding the committed token" do
    callback_error = RuntimeError.new("audit unavailable")
    ActiveAdmin::DeviceAuthorization.config.on_token_issued = ->(**) { raise callback_error }
    allow(Rails.error).to receive(:report)

    result = described_class.new(client_id: "client", device_code: "code").call

    expect(result).to include(token_type: "Bearer", scope: "read")
    expect(Rails.error).to have_received(:report).with(callback_error, handled: true)
  end
end
