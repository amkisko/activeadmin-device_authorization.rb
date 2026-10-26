# frozen_string_literal: true

require "action_controller/railtie"
require "rack/mock"
require "spec_helper"

require_relative "../../../app/controllers/active_admin/device_authorization/application_controller"
require_relative "../../../app/controllers/active_admin/device_authorization/consents_controller"

RSpec.describe ActiveAdmin::DeviceAuthorization::ConsentsController do
  around do |example|
    original = described_class.allow_forgery_protection
    described_class.allow_forgery_protection = true
    example.run
  ensure
    described_class.allow_forgery_protection = original
  end

  let(:routes) do
    ActionDispatch::Routing::RouteSet.new.tap do |route_set|
      route_set.draw do
        namespace :admin do
          ActiveAdmin::DeviceAuthorization::Routes.draw(self, consent: :controller)
        end
      end
    end
  end

  let(:client) { Struct.new(:name).new("Command-line client") }
  let(:grant) do
    Struct.new(:user_code, :status, :requested_scopes, :device_authorization_client) do
      def mark_expired_if_needed! = true
      def pending? = status == "pending"
    end.new("ABCD-2345", "pending", ["read"], client)
  end

  before do
    grant_record = grant
    stub_const("DeviceAuthorizationGrant", Class.new do
      define_singleton_method(:find_by!) do |user_code:|
        raise ActiveRecord::RecordNotFound unless user_code == grant_record.user_code

        grant_record
      end
    end)

    stub_const("DeviceAuthorizationClient", Class.new)
    ActiveAdmin::DeviceAuthorization.configure do |config|
      config.current_resource_owner = ->(_controller) { Object.new }
      config.rate_limit_device_authorization = ->(_controller) {}
      config.rate_limit_token = ->(_controller) {}
      config.scopes = ["read"]
      config.default_scopes = ["read"]
    end

    described_class.include(routes.url_helpers)
    described_class.prepend_view_path(File.expand_path("../../../app/views", __dir__))
    I18n.load_path.concat Dir[File.expand_path("../../../config/locales/*.yml", __dir__)]
  end

  it "serves the verification URI as a code-entry form" do
    response = get("/admin/device_auth")

    expect(response.status).to eq(200)
    expect(response.body).to include("Enter the user code")
    expect(response.body).to include('name="user_code"')
    expect(response.body).to include('action="/admin/device_auth"')
  end

  it "normalizes an entered code and opens its consent page" do
    response = get("/admin/device_auth?user_code=abcd%202345")

    expect(response.status).to eq(302)
    expect(response.headers["location"]).to end_with("/admin/device_auth/ABCD-2345")
  end

  it "renders the complete verification URI with a device-code comparison prompt" do
    response = get("/admin/device_auth/ABCD-2345")

    expect(response.status).to eq(200)
    expect(response.body).to include("<h1 class=\"panel-title\">Authorize device</h1>")
    expect(response.body).to include("Command-line client")
    expect(response.body).to include("ABCD-2345")
    expect(response.body).to include("Verify that this code matches the code shown on the device you are using")
    expect(response.body).to include("Approve")
  end

  it "rejects a consent decision without an authenticity token" do
    expect {
      request(:post, "/admin/device_auth/ABCD-2345/approve")
    }.to raise_error(ActionController::InvalidAuthenticityToken)
  end

  {
    fi: "Varmista, että tämä koodi vastaa käyttämäsi laitteen näyttämää koodia",
    sv: "Kontrollera att den här koden stämmer överens med koden som visas på enheten du använder"
  }.each do |locale, prompt|
    it "renders the code comparison prompt in #{locale}" do
      response = I18n.with_locale(locale) { get("/admin/device_auth/ABCD-2345") }

      expect(response.status).to eq(200)
      expect(response.body).to include(prompt)
    end
  end

  def get(path)
    request(:get, path)
  end

  def request(method, path)
    environment = Rack::MockRequest.env_for(path, method: method.to_s.upcase)
    if method == :post
      session = {}
      session.define_singleton_method(:enabled?) { true }
      environment["rack.session"] = session
      environment["rack.session.options"] = {id: "test-session"}
    end
    status, headers, body = routes.call(environment)
    response_body = +""
    body.each { |part| response_body << part }
    body.close if body.respond_to?(:close)

    Struct.new(:status, :headers, :body).new(status, headers, response_body)
  end
end
