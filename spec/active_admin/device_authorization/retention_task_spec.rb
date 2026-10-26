# frozen_string_literal: true

require "rake"
require "spec_helper"

RSpec.describe "active_admin:device_authorization:retention" do
  task_name = "active_admin:device_authorization:retention"

  around do |example|
    original_application = Rake.application
    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load File.expand_path("../../../lib/tasks/active_admin_device_authorization.rake", __dir__)
    example.run
  ensure
    Rake.application = original_application
  end

  it "runs the configured retention cleanup" do
    allow(ActiveAdmin::DeviceAuthorization::Retention).to receive(:call)

    Rake::Task[task_name].invoke

    expect(ActiveAdmin::DeviceAuthorization::Retention).to have_received(:call).once
  end
end
