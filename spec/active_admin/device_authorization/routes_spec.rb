# frozen_string_literal: true

require "spec_helper"
require "action_controller"

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
    attr_reader :posts, :gets, :namespaces

    def initialize
      @posts = []
      @gets = []
      @namespaces = []
      @scope = []
    end

    def namespace(name, path: nil, **_opts, &block)
      entry = {name: name, path: path}
      @namespaces << entry
      @scope.push(entry)
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

  it "draws absolute oauth controller paths under the configured path namespace" do
    mapper = CaptureMapper.new
    described_class.draw(mapper)

    expect(mapper.namespaces.map { |row| row[:name] }).to eq([:admin, :oauth])
    expect(mapper.gets).to be_empty
    expect(mapper.posts.map { |row| row[:to] }).to eq([
      "/active_admin/device_authorization/device_authorizations#create",
      "/active_admin/device_authorization/tokens#create"
    ])
    expect(mapper.posts.map { |row| row[:action] }).to eq([:device_authorization, :token])
  end

  it "does not accept a consent mode keyword" do
    mapper = CaptureMapper.new
    expect {
      described_class.draw(mapper, consent: :controller)
    }.to raise_error(ArgumentError, /unknown keyword/i)
  end

  it "recognizes OAuth paths when drawn at the routes root" do
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      ActiveAdmin::DeviceAuthorization::Routes.draw(self)
    end

    expect(routes.recognize_path("/admin/oauth/device_authorization", method: :post)).to include(
      controller: "active_admin/device_authorization/device_authorizations",
      action: "create"
    )
    expect(routes.recognize_path("/admin/oauth/token", method: :post)).to include(
      controller: "active_admin/device_authorization/tokens",
      action: "create"
    )
  end
end
