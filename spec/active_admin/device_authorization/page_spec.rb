# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveAdmin::DeviceAuthorization::Page do
  let(:page_actions) { [] }
  let(:controller_blocks) { [] }
  let(:content_titles) { [] }

  before do
    I18n.load_path.concat Dir[File.expand_path("../../../config/locales/*.yml", __dir__)]
    I18n.backend.reload!
    page_actions_ref = page_actions
    controller_blocks_ref = controller_blocks
    content_titles_ref = content_titles
    @original_register_page = ActiveAdmin.method(:register_page) if ActiveAdmin.respond_to?(:register_page)
    ActiveAdmin.define_singleton_method(:register_page) do |_name, &block|
      dsl = Object.new
      dsl.define_singleton_method(:menu) { |**| }
      dsl.define_singleton_method(:controller) { |&blk| controller_blocks_ref << blk }
      dsl.define_singleton_method(:page_action) do |name, **opts, &blk|
        page_actions_ref << {name: name, options: opts, block: blk}
      end
      dsl.define_singleton_method(:content) do |**opts, &blk|
        content_titles_ref << opts[:title]
      end
      dsl.instance_eval(&block)
    end
  end

  after do
    original = @original_register_page
    if original
      ActiveAdmin.define_singleton_method(:register_page) do |*args, **kwargs, &block|
        original.call(*args, **kwargs, &block)
      end
    elsif ActiveAdmin.singleton_class.instance_methods(false).include?(:register_page)
      ActiveAdmin.singleton_class.remove_method(:register_page)
    end
  end

  it "registers approve and deny as page_actions" do
    described_class.register!

    expect(page_actions.map { |row| row[:name] }).to include(:approve, :deny, :step_up)
    expect(page_actions.find { |row| row[:name] == :approve }[:options][:method]).to eq(:post)
    expect(page_actions.find { |row| row[:name] == :deny }[:options][:method]).to eq(:post)
    expect(controller_blocks).not_to be_empty
  end

  it "still registers when register_active_admin_page is false so hosts can call register! manually" do
    ActiveAdmin::DeviceAuthorization.config.register_active_admin_page = false
    described_class.register!
    expect(page_actions.map { |row| row[:name] }).to include(:approve, :deny)
  end

  it "titles the page from grant presence, not a fixed authorize string" do
    described_class.register!
    title = content_titles.first
    expect(title).to respond_to(:call)

    with_grant = Object.new
    with_grant.define_singleton_method(:device_auth_grant) { Object.new }
    expect(with_grant.instance_exec(&title)).to eq(I18n.t("active_admin.device_authorization.title"))

    without_grant = Object.new
    without_grant.define_singleton_method(:device_auth_grant) { nil }
    expect(without_grant.instance_exec(&title)).to eq(I18n.t("active_admin.device_authorization.enter_code"))
  end
end
