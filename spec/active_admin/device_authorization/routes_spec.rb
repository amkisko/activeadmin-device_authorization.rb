# frozen_string_literal: true

require "spec_helper"
require "action_controller"
require_relative "../../../app/controllers/active_admin/device_authorization/application_controller"
require_relative "../../../app/controllers/active_admin/device_authorization/consents_controller"

RSpec.describe ActiveAdmin::DeviceAuthorization::Routes do
  before do
    ActiveAdmin::DeviceAuthorization.config.rate_limit_device_authorization = ->(_controller) { true }
    ActiveAdmin::DeviceAuthorization.config.rate_limit_token = ->(_controller) { true }
  end

  [:rate_limit_device_authorization, :rate_limit_token].each do |setting|
    [nil, false, "limiter"].each do |invalid|
      it "refuses to mount OAuth routes when #{setting} is #{invalid.inspect}" do
        ActiveAdmin::DeviceAuthorization.config.public_send("#{setting}=", invalid)
        mapper = CaptureMapper.new
        expect { described_class.draw(mapper) }.to raise_error(ArgumentError, /#{setting}/)
        expect(mapper.posts).to be_empty
      end
    end
  end

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

  it "recognizes the controller verification URI and generates its named path" do
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      namespace :admin do
        ActiveAdmin::DeviceAuthorization::Routes.draw(self, consent: :controller)
      end
    end

    expect(routes.recognize_path("/admin/device_auth", method: :get)).to include(
      controller: "active_admin/device_authorization/consents", action: "index"
    )
    expect(routes.url_helpers.admin_device_auth_path).to eq("/admin/device_auth")
  end
end
