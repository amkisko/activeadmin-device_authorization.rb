# CHANGELOG

## Unreleased

## 0.1.3 (2026-10-26)

- Add RFC 8628 device authorization with ActiveAdmin consent, token exchange, and retention helpers
- Add English, Finnish, and Swedish strings for the consent and code-entry UI
- Add a schedulable retention task for expired authorization records
- Require Rails 7.2.3.2 or newer
- Require host rate limits before mounting the public OAuth endpoints and fail closed unless a limiter returns true
- Reject unknown and client-disallowed scopes with `invalid_scope`
- Return protocol-correct OAuth errors and cache-prevention headers
- Protect standalone consent decisions from cross-site request forgery
- Filter `device_code`, `user_code`, and `access_token` from Rails request logs
- Serve standalone code-entry and consent pages, normalize entered user codes, and prompt code comparison with the device
- Run consent and token callbacks after commit without hiding committed results when a callback fails
- Draw absolute controller paths so nesting under `namespace :admin` does not prefix `Admin::` onto gem controllers
- Clamp consent absolute TTL against `access_token_absolute_ttl`
- Delete idle-expired tokens during retention
- Raise the required poll interval by `slow_down_increment` when the grant stores `poll_interval_seconds`
- Document public install from RubyGems or git, host rate-limit / HTTPS / Host / retention duties, and `make release`
- Improve standalone consent markup for narrow screens, contrast on the code-comparison prompt, and readable user codes
- Require Ruby 3.4 or newer (Rails 7.2 pulls `rdoc` 8 / `rbs` 4, which need Ruby 3.3+)
- Wire Polyrun coverage collection and CI coverage reporting so `coverage/merged.json` is produced
