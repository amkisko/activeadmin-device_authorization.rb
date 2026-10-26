#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"

root = Pathname(__dir__).join("../..").expand_path
warn_limit = 150
fail_limit = 300
status = 0

paths = [
  root.join("lib"),
  root.join("app"),
  root.join("usr/bin"),
  root.join("usr/lib")
].select(&:directory?)

files = paths.flat_map do |dir|
  Dir.glob(dir.join("**/*.{rb,erb,rake}")).map { |path| Pathname(path) }
end.sort

files.each do |path|
  lines = path.each_line.count
  relative = path.relative_path_from(root)
  if lines > fail_limit
    warn "LOC fail: #{relative} has #{lines} lines (maximum #{fail_limit})"
    status = 1
  elsif lines >= warn_limit
    warn "LOC warning: #{relative} has #{lines} lines (target below #{warn_limit})"
  end
end

exit status
