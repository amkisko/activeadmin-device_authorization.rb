# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveAdmin::DeviceAuthorization::Routes do
  class CaptureMapper
    attr_reader :posts, :gets

    def initialize
      @posts = []
      @gets = []
      @scope = []
    end

    def namespace(name, path:, &block)
      @scope.push([name, path])
      yield self
    ensure
      @scope.pop
    end

    def post(action, to:, **_opts)
      @posts << {action: action, to: to, scope: @scope.dup}
    end

    def get(path, to:, **_opts)
      @gets << {path: path, to: to, scope: @scope.dup}
    end
  end

  it "draws absolute oauth controller paths and ActiveAdmin page consent routes by default" do
    mapper = CaptureMapper.new
    described_class.draw(mapper)

    oauth_targets = mapper.posts.select { |row| row[:scope].any? }.map { |row| row[:to] }
    expect(oauth_targets).to eq([
      "/active_admin/device_authorization/device_authorizations#create",
      "/active_admin/device_authorization/tokens#create"
    ])

    consent_targets = (
      mapper.gets.map { |row| row[:to] } +
      mapper.posts.reject { |row| row[:scope].any? }.map { |row| row[:to] }
    )
    expect(consent_targets).to contain_exactly(
      "device_auth#show",
      "device_auth#approve",
      "device_auth#deny"
    )
  end

  it "draws absolute ConsentsController paths when consent: :controller" do
    mapper = CaptureMapper.new
    described_class.draw(mapper, consent: :controller)

    targets = mapper.posts.map { |row| row[:to] } + mapper.gets.map { |row| row[:to] }
    expect(targets).to include(
      "/active_admin/device_authorization/consents#show",
      "/active_admin/device_authorization/consents#approve",
      "/active_admin/device_authorization/consents#deny"
    )
  end
end
