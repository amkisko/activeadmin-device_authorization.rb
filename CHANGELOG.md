# CHANGELOG

## Unreleased

### Fixed

- Raise the Rails minimum to 7.2.3.2 so every supported dependency graph includes current Rails security fixes
- Require host rate limits before mounting the public OAuth endpoints, and fail closed when a limiter does not explicitly allow a request
- Reject unknown and client-disallowed scopes instead of silently narrowing the request
- Return protocol-correct errors and cache-prevention headers from the OAuth endpoints
- Protect standalone consent decisions from cross-site request forgery
- Filter device codes, user codes, and access-token parameters from Rails request logs
- Serve both standalone code-entry and consent pages, normalize entered user codes, and prompt the administrator to compare the device code
- Run consent and token callbacks after commit without letting callback failures hide committed results
- Make dependency audits fail when the scanner fails or finds an advisory
- Draw absolute controller paths so nesting under `namespace :admin` does not prefix `Admin::` onto gem controllers
- Clamp consent absolute TTL against `access_token_absolute_ttl`, and validate default/min/max/choices as one window
- Delete idle-expired tokens in retention (so a far-future absolute sentinel cannot keep them for decades)
- Raise the required poll interval by `slow_down_increment` when the grant stores `poll_interval_seconds`

### Added

- Add a schedulable retention task for expired authorization records
- Test the minimum supported Ruby, Rails, and ActiveAdmin versions in CI
- Initial local gem scaffold: configurable RFC 8628 device authorization, consent, token exchange, retention, and ActiveAdmin consent page helpers
- English, Finnish, and Swedish locale strings for the consent and code-entry UI
- Specs for routes, retention axes, and consecutive `slow_down` poll gating
