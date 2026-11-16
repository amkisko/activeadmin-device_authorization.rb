# CHANGELOG

## 0.3.0 (2026-11-16)

- BREAKING: Consent UI is only the ActiveAdmin Device Auth page (`ActiveAdmin.routes`); remove `consent: :controller` and ConsentsController
- BREAKING: `Routes.draw` draws public OAuth endpoints only and applies `path_namespace` itself (one line at routes root; do not wrap in `namespace :admin`)
- BREAKING: `verification_uri_complete` uses a `user_code` query parameter instead of a path suffix
- Register the Device Auth page from `ActiveAdmin.after_load` when `register_active_admin_page` is true
- Allow manual `Page.register!` when `register_active_admin_page` is false (engine auto-register stays gated)
- Show the enter-code title on Device Auth when no grant is loaded
- Document the ActiveAdmin consent vs explicit OAuth split as RFC-0002

## 0.2.0 (2026-10-28)

- BREAKING: Require ActiveAdmin 4 (`>= 4.0.0.beta19`); drop ActiveAdmin 3 support
- Ship ActiveAdmin 4 consent markup: `.attributes-table`, self-contained verify prompt, Approve/Deny submits inside `.formtastic`
- Resolve `current_resource_owner` with `instance_exec` for zero-arity procs so private authentication helpers work
- Document page policy hooks `approve?` / `deny?` / `step_up?`

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
