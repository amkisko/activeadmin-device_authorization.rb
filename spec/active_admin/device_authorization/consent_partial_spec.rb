# frozen_string_literal: true

require "spec_helper"
require "action_view"
require "action_controller"

RSpec.describe "consent partial" do
  let(:config) { ActiveAdmin::DeviceAuthorization.config }
  let(:client) { Struct.new(:name).new("Command-line client") }
  let(:grant) do
    Struct.new(:user_code, :status, :requested_scopes, :device_authorization_client) do
      def pending? = status == "pending"
    end.new("ABCD-2345", "pending", ["read"], client)
  end

  let(:view) do
    Class.new(ActionView::Base) do
      include ActionView::Helpers::FormTagHelper
      include ActionView::Helpers::FormHelper
      include ActionView::Helpers::UrlHelper
      include ActionView::Context

      def protect_against_forgery? = false

      def form_authenticity_token(**) = "token"

      def polymorphic_path(*) = "/admin/device_auth/approve"

      def url_for(options = {})
        return options if options.is_a?(String)

        action = options[:action]
        return "/admin/device_auth/#{action}" if action

        "/admin/device_auth"
      end
    end.with_empty_template_cache.new(
      ActionView::LookupContext.new([File.expand_path("../../../app/views", __dir__)]),
      {},
      nil
    )
  end

  before do
    ActiveAdmin::DeviceAuthorization.configure do |cfg|
      cfg.scopes = ["read"]
      cfg.default_scopes = ["read"]
      cfg.rate_limit_device_authorization = ->(_) { true }
      cfg.rate_limit_token = ->(_) { true }
      cfg.current_resource_owner = -> { Object.new }
    end
    I18n.load_path.concat Dir[File.expand_path("../../../config/locales/*.yml", __dir__)]
    I18n.backend.reload!
  end

  it "posts approve and deny to page_action paths with user_code in the form body" do
    html = view.render(
      partial: "active_admin/device_authorization/consent",
      locals: {grant: grant}
    )

    expect(html).to include('action="/admin/device_auth/approve"')
    expect(html).to include('action="/admin/device_auth/deny"')
    expect(html).to include('name="user_code"')
    expect(html).to include("ABCD-2345")
    expect(html).to include('class="attributes-table"')
    expect(html).to include('class="device-auth-verify"')
    expect(html).to match(%r{class="formtastic"[^>]*>[\s\S]*?type="submit"[\s\S]*?Approve}i)
    expect(html).to match(%r{class="formtastic"[^>]*>[\s\S]*?type="submit"[\s\S]*?Deny}i)
  end

  {
    fi: "Varmista, että tämä koodi vastaa käyttämäsi laitteen näyttämää koodia",
    sv: "Kontrollera att den här koden stämmer överens med koden som visas på enheten du använder"
  }.each do |locale, prompt|
    it "renders the code comparison prompt in #{locale}" do
      html = I18n.with_locale(locale) {
        view.render(
          partial: "active_admin/device_authorization/consent",
          locals: {grant: grant}
        )
      }
      expect(html).to include(prompt)
    end
  end
end
