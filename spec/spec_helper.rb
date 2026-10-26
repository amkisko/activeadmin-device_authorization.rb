# frozen_string_literal: true

polyrun_cov_measure =
  ENV["POLYRUN_COVERAGE_DISABLE"] != "1" &&
  %w[1 true yes].include?(ENV["POLYRUN_COVERAGE"]&.to_s&.downcase)

if polyrun_cov_measure
  require "coverage"
  branch = %w[1 true yes].include?(ENV["POLYRUN_COVERAGE_BRANCHES"]&.to_s&.downcase)
  ::Coverage.start(lines: true, branches: branch)
end

if polyrun_cov_measure
  require "polyrun/coverage/rails"
  Polyrun::Coverage::Rails.start!(root: File.expand_path("..", __dir__))
end

require "active_admin/device_authorization"

unless defined?(Rails)
  module Rails
    class << self
      attr_accessor :error
    end
  end
end

Rails.error ||= Class.new do
  def report(*)
  end
end.new

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.order = :random

  config.before { ActiveAdmin::DeviceAuthorization.reset_config! }
end

require "polyrun/rspec"
Polyrun::RSpec.install_sharded_formatter_compat!
Polyrun::RSpec.install_failure_fragments!
Polyrun::RSpec.install_worker_ping!
Polyrun::RSpec.install_example_debug!
Polyrun::RSpec.install_example_rails_logging!
Polyrun::RSpec.install_example_timeout!
Polyrun::RSpec.install_example_prosopite!
if %w[1 true yes].include?(ENV["POLYRUN_SPEC_QUALITY"]&.to_s&.downcase)
  Polyrun::RSpec.install_spec_quality!
end
require_relative "support/junit_formatter"
