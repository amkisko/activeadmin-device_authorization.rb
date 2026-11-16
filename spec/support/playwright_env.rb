# frozen_string_literal: true

require "open3"

module PlaywrightEnv
  module_function

  def cli_available?
    return @cli if defined?(@cli)

    @cli = detect
  end

  def hint
    "Playwright CLI not found. npm install playwright && npx playwright install chromium"
  end

  def detect
    if (path = ENV["PLAYWRIGHT_CLI_EXECUTABLE_PATH"].to_s.strip) && !path.empty?
      _out, status = Open3.capture2e(path, "--version")
      return true if status.success?
    end

    _out, status = Open3.capture2e("npx", "--yes", "playwright", "--version")
    return true if status.success?

    bin = File.expand_path("../../node_modules/.bin/playwright", __dir__)
    return false unless File.file?(bin)

    _out, status = Open3.capture2e(bin, "--version")
    status.success?
  rescue Errno::ENOENT
    false
  end
end
