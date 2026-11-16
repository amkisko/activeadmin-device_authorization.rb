# frozen_string_literal: true

Capybara.register_driver :playwright do |app|
  cli = ENV["PLAYWRIGHT_CLI_EXECUTABLE_PATH"].presence ||
    File.expand_path("../../node_modules/.bin/playwright", __dir__)

  Capybara::Playwright::Driver.new(
    app,
    browser_type: :chromium,
    headless: ENV["HEADFUL"].to_s.empty?,
    playwright_cli_executable_path: cli
  )
end

Capybara.save_path = "tmp/capybara"
Capybara.default_max_wait_time = 5
