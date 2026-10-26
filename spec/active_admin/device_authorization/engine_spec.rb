# frozen_string_literal: true

require "rails/engine"
require "spec_helper"
require_relative "../../../lib/active_admin/device_authorization/engine"

RSpec.describe ActiveAdmin::DeviceAuthorization::Engine do
  it "filters device authorization credentials from Rails parameter logs" do
    configuration = Struct.new(:filter_parameters).new([:password])
    application = Struct.new(:config).new(configuration)

    described_class.initializers.tsort_each do |initializer|
      initializer.run(application) if initializer.name == "active_admin.device_authorization.filter_parameters"
    end

    expect(application.config.filter_parameters).to include(:password, :device_code, :user_code, :access_token)
  end
end
