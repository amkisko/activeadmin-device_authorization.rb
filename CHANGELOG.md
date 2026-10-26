# Changelog

## Unreleased

### Fixed

- Draw absolute controller paths so nesting under `namespace :admin` does not prefix `Admin::` onto gem controllers
- Clamp consent absolute TTL against `access_token_absolute_ttl`, and validate default/min/max/choices as one window
- Delete idle-expired tokens in retention (so a far-future absolute sentinel cannot keep them for decades)
- Raise the required poll interval by `slow_down_increment` when the grant stores `poll_interval_seconds`

### Added

- Initial local gem scaffold: configurable RFC 8628 device authorization, consent, token exchange, retention, and ActiveAdmin consent page helpers
- English, Finnish, and Swedish locale strings for the consent and code-entry UI
- Specs for routes, retention axes, and consecutive `slow_down` poll gating
