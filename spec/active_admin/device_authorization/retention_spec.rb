# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveAdmin::DeviceAuthorization::Retention do
  class TokenRelationSpy
    attr_reader :sql, :binds, :deleted

    def initialize
      @deleted = 0
    end

    def where(sql, *binds)
      @sql = sql
      @binds = binds
      self
    end

    def in_batches(of:)
      self
    end

    def delete_all
      @deleted += 1
      1
    end
  end

  class GrantRelationSpy
    attr_reader :deleted, :missing_assoc

    def initialize
      @deleted = 0
    end

    def where(*args)
      self
    end

    def missing(assoc)
      @missing_assoc = assoc
      self
    end

    def in_batches(of:)
      self
    end

    def delete_all
      @deleted += 1
      1
    end
  end

  def configure_models!(token_relation:, grant_relation:)
    token_class = Class.new
    grant_class = Class.new
    token_class.define_singleton_method(:where) { |*args| token_relation.where(*args) }
    grant_class.define_singleton_method(:where) { |*args| grant_relation.where(*args) }
    stub_const("RetentionSpecToken", token_class)
    stub_const("RetentionSpecGrant", grant_class)

    ActiveAdmin::DeviceAuthorization.configure do |config|
      config.access_token_class_name = "RetentionSpecToken"
      config.grant_class_name = "RetentionSpecGrant"
      yield config if block_given?
    end
  end

  it "deletes by absolute and revoked when idle expiry is off" do
    tokens = TokenRelationSpy.new
    grants = GrantRelationSpy.new
    configure_models!(token_relation: tokens, grant_relation: grants) do |config|
      config.access_token_absolute_ttl = 3600
      config.access_token_max_absolute_ttl = 3600
      config.access_token_min_absolute_ttl = 3600
      config.access_token_default_absolute_ttl = 3600
      config.access_token_absolute_ttl_choices = [3600]
      config.access_token_idle_ttl = nil
      config.token_retention_period = 30 * 24 * 60 * 60
    end

    described_class.call

    expect(tokens.sql).to eq("absolute_expires_at < ? OR revoked_at < ?")
    expect(tokens.binds.size).to eq(2)
    expect(tokens.deleted).to eq(1)
    expect(grants.deleted).to eq(1)
  end

  it "includes idle cutoff when idle expiry is on" do
    tokens = TokenRelationSpy.new
    grants = GrantRelationSpy.new
    configure_models!(token_relation: tokens, grant_relation: grants) do |config|
      config.access_token_absolute_ttl = nil
      config.access_token_idle_ttl = 3600
      config.token_retention_period = 30 * 24 * 60 * 60
    end

    described_class.call

    expect(tokens.sql).to eq("absolute_expires_at < ? OR revoked_at < ? OR last_used_at < ?")
    expect(tokens.binds.size).to eq(3)
    expect(tokens.deleted).to eq(1)
  end

  it "keeps idle in the predicate when both absolute and idle are on" do
    tokens = TokenRelationSpy.new
    grants = GrantRelationSpy.new
    configure_models!(token_relation: tokens, grant_relation: grants) do |config|
      config.access_token_absolute_ttl = 4 * 3600
      config.access_token_idle_ttl = 3600
    end

    described_class.call

    expect(tokens.sql).to include("last_used_at < ?")
    expect(tokens.binds.size).to eq(3)
  end

  it "omits idle when both TTLs are nil (revoke-only)" do
    tokens = TokenRelationSpy.new
    grants = GrantRelationSpy.new
    configure_models!(token_relation: tokens, grant_relation: grants) do |config|
      config.access_token_absolute_ttl = nil
      config.access_token_idle_ttl = nil
    end

    described_class.call

    expect(tokens.sql).to eq("absolute_expires_at < ? OR revoked_at < ?")
    expect(tokens.binds.size).to eq(2)
  end
end
