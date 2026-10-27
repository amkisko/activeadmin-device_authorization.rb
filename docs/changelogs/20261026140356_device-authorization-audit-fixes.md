# Device authorization audit fixes

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Require both public OAuth endpoints to have a callable host rate limiter before routes are mounted. A limiter must return exactly true to continue.
- Keep authorization decisions and token creation as committed state even when an audit callback fails. Report callback failures through the Rails error reporter.
- Keep bearer authentication in the host application, and document the required lookup, expiry, revocation, scope, ownership, and last-use checks.
- Require Rails 7.2.3.2 or newer because the former Rails 7.1 minimum has no release that fixes the current advisory set.
- Exercise the declared minimum Ruby, Rails, and ActiveAdmin versions in a separate locked CI graph.

## Effects

- Unknown or client-disallowed scopes now return `invalid_scope` without creating a grant.
- Public-client failures now return HTTP 400, and OAuth JSON responses include both cache-prevention headers.
- Standalone consent mode now serves the code-entry and consent pages, verifies authenticity tokens on decisions, normalizes user-code punctuation, and asks the administrator to compare the displayed code with the device.
- Rails request logs now filter device-code, user-code, and access-token parameter names.
- The token-issued callback runs after commit. Callback failures no longer prevent delivery of a committed result.
- Expired grants and tokens can be removed with `active_admin:device_authorization:retention`.
- Dependency audit failures now fail the local audit command.
- Standalone consent pages ship document markup, a high-contrast code-comparison alert, monospace user codes, and stacked approve/deny actions under 40rem.
- README lists RubyGems and git install paths, `make release`, and a Host responsibilities section for rate limits, HTTPS/Host, retention, models, and bearer checks.
- Gemspec `allowed_push_host` is `https://rubygems.org` so `make release` can push.

## Next

- Spot-check the ActiveAdmin page theme (focus ring color, button contrast) inside a real host admin skin; standalone controller mode now ships its own narrow-layout styles.
- Configure production rate-limit policies and schedule the retention task in each host.

## Source

- [RFC 8628](https://www.rfc-editor.org/rfc/rfc8628)
- [RFC 6749](https://www.rfc-editor.org/rfc/rfc6749)
- `README.md`
- `CHANGELOG.md`
