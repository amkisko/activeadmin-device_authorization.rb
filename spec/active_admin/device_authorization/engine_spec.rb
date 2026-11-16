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

  it "hooks Page.register! into ActiveAdmin.after_load only when auto-register is enabled" do
    hooks = []
    original_after_load = ActiveAdmin.method(:after_load) if ActiveAdmin.respond_to?(:after_load)
    original_application = ActiveAdmin.method(:application) if ActiveAdmin.respond_to?(:application)

    ActiveAdmin.define_singleton_method(:after_load) { |&block| hooks << block }
    aa_application = Object.new
    aa_application.define_singleton_method(:respond_to?) do |name, include_all = false|
      (name == :loaded?) ? false : Object.instance_method(:respond_to?).bind_call(self, name, include_all)
    end
    ActiveAdmin.define_singleton_method(:application) { aa_application }
    application = Struct.new(:config).new(Object.new)
    calls = 0
    page = ActiveAdmin::DeviceAuthorization::Page
    page.singleton_class.class_eval do
      alias_method :__original_register!, :register!
      define_method(:register!) { calls += 1 }
    end

    described_class.initializers.tsort_each do |initializer|
      initializer.run(application) if initializer.name == "active_admin.device_authorization.page"
    end

    expect(hooks.size).to eq(1)
    expect(hooks.first.source_location.first).to include("engine.rb")

    ActiveAdmin::DeviceAuthorization.config.register_active_admin_page = true
    hooks.first.call
    expect(calls).to eq(1)

    ActiveAdmin::DeviceAuthorization.config.register_active_admin_page = false
    hooks.first.call
    expect(calls).to eq(1)
  ensure
    page&.singleton_class&.class_eval do
      if method_defined?(:__original_register!) || private_method_defined?(:__original_register!)
        alias_method :register!, :__original_register!
        remove_method :__original_register!
      end
    end
    restore_active_admin_singleton!(:after_load, original_after_load)
    restore_active_admin_singleton!(:application, original_application)
  end

  def restore_active_admin_singleton!(name, original)
    if original
      ActiveAdmin.define_singleton_method(name) do |*args, **kwargs, &block|
        original.call(*args, **kwargs, &block)
      end
    elsif ActiveAdmin.singleton_class.method_defined?(name, false)
      ActiveAdmin.singleton_class.remove_method(name)
    end
  end
end
