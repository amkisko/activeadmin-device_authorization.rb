#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require "set"
require "yaml"

root = Pathname(__dir__).join("../..").expand_path
locale_dir = root.join("config/locales")
files = locale_dir.glob("*.yml").sort
abort "No locale files in #{locale_dir}" if files.empty?

def flatten_keys(value, prefix = nil)
  case value
  when Hash
    value.flat_map { |key, child| flatten_keys(child, [prefix, key].compact.join(".")) }
  else
    [prefix]
  end
end

locales = files.to_h do |path|
  data = YAML.safe_load(path.read, aliases: true)
  abort "Locale root missing in #{path}" unless data.is_a?(Hash) && data.size == 1

  locale = data.keys.first.to_s
  keys = flatten_keys(data.fetch(locale)).to_set
  [locale, {path: path, keys: keys}]
end

base_locale = "en"
abort "Missing base locale en.yml" unless locales.key?(base_locale)

base_keys = locales.fetch(base_locale).fetch(:keys)
status = 0

locales.each do |locale, payload|
  missing = (base_keys - payload.fetch(:keys)).sort
  extra = (payload.fetch(:keys) - base_keys).sort
  next if missing.empty? && extra.empty?

  status = 1
  relative = payload.fetch(:path).relative_path_from(root)
  warn "Locale parity fail: #{relative} (locale=#{locale})"
  missing.each { |key| warn "  missing: #{key}" }
  extra.each { |key| warn "  extra: #{key}" }
end

if status.zero?
  puts "Locale parity ok: #{locales.keys.sort.join(", ")} (#{base_keys.size} keys)"
end

exit status
