# Engineering audit

## Decisions

The review covered every executable Ruby, ERB, Rake, shell, CI, and release path in the repository. It followed request data from the public device and token endpoints through host-owned models, consent, token issue, retention, logs, callbacks, packaging, and CI.

The review ran protocol and contract, security, privacy, availability and abuse, resource and budget, performance, product surface, HTTP identity, data isolation, lineage, supply chain and release, trace and identification, and external device/operator boundary checks. There is no learned system or physical actuator, so learned-system and physical-control checks do not apply.

Findings were fixed in iterations:

- High: standalone consent decisions accepted cross-site requests because the controller had no authenticity-token verification. `ApplicationController` now enables exception-mode forgery protection while the two machine OAuth controllers retain their explicit exemption.
- Medium: public OAuth endpoints could allocate records and lock grants without a configured abuse limit. Route mounting now requires both host limiters, and each request fails closed unless its limiter returns exactly true.
- Medium: unknown requested scopes were silently removed. A request containing any unknown or client-disallowed scope now returns `invalid_scope` before a grant write.
- Medium: controller consent mode had no base verification route and no complete templates. It now serves code entry and consent review, normalizes user input, and prompts code comparison with the device.
- Medium: token audit callbacks ran inside the issuing transaction, while callback failures after commit could hide committed state. Consent and token callbacks now run after commit; failures go to `Rails.error` without changing the protocol result.
- Medium: Rails 7.1.6 matched current Rails security advisories and has no fixed release in its series. The runtime floor is now Rails 7.2.3.2 and the minimum graph also pins ActiveAdmin 3.2.x.
- Medium: unexpected `ArgumentError` messages from server configuration or host code could become public OAuth error values. The controller now serializes only the request service's typed protocol error.
- Medium: device and user codes could appear in Rails parameter logs. The engine now filters `device_code`, `user_code`, and `access_token` parameter names.
- Low: user-code collision retries were unbounded. Generation now stops after 100 attempts with an explicit internal error.
- Low: token responses lacked the required legacy cache-prevention header, unknown public clients returned an authentication status intended for header-authenticated clients, retention had no schedulable entry point, and local dependency audit failures were ignored. These contracts and pipeline paths are corrected.

The host owns bearer authentication and database schema. `README.md` now makes expiry, revocation, scope, ownership, last-use, finite grant states, uniqueness, foreign-key, retention-index, trusted HTTPS origin, and Host-header requirements explicit.

## Effects

- Focused test-first runs demonstrated failures before each protocol, callback, controller, CSRF, error-boundary, log-filter, and collision-budget correction.
- `make test` completed with 63 examples across five worker processes, no failures, 37 Ruby files with no RuboCop offenses, valid RBS, and locale parity across 25 keys. The LOC check reports the existing cohesive configuration file at 229 lines as a warning below its 300-line failure limit.
- Direct RSpec runs completed with 63 examples and no failures in each locked Rails 7.2/ActiveAdmin 3.2 and Rails 8 graph under the local Ruby 4.0.2 interpreter. CI defines the Ruby 3.2, 3.4, and 4.0 interpreter matrix; those remote jobs were not observed in this session.
- `make audit` found no advisories in `Gemfile.lock` or any of the three supported appraisal locks after ruby-advisory-db was updated to commit `03da937a9e171e3fedebde6620e203559b7a60c0`.
- The built gem is 23,552 bytes. Executable and packaged source under `app`, `config`, `lib`, and `sig` totals 47,431 bytes. The package contains the controllers, standalone views, locales, callback handling, bounded code generation, retention task, and type signature.
- The controller-mode HTML has one top-level heading, labelled code input, keyboard-operable forms, explicit approve and deny actions, and an adjacent code-comparison warning.
- A later pass replaced Tailwind utility action rows with formtastic action lists, wrapped standalone pages in document markup with narrow-layout styles, raised contrast on the comparison prompt via `flash flash_alert`, and marked user codes as monospace. Visual assessment (source-level): one composition per page, labelled controls, stacked actions on narrow viewports, visible focus outlines in standalone mode. Live ActiveAdmin host theme colors and screenshots remain for a human.

No confirmed high- or medium-severity repository finding remains open after the final pass.

## Next

- Spot-check the ActiveAdmin page theme in a real host admin skin. Standalone consent mode now uses document markup, a comparison alert, monospace user codes, stacked actions under 40rem, and visible focus outlines. Host theme colors for the ActiveAdmin page path still need a live screenshot.
- Configure and load-test each host's rate-limit policies, trusted HTTPS verification origin, model constraints, bearer middleware, and retention schedule before deployment. README now groups these under Host responsibilities.
- Treat callback reporting as best effort. Use a durable host outbox when an audit event must be delivered exactly once or retried.

## Source

- [RFC 8628](https://www.rfc-editor.org/rfc/rfc8628)
- [RFC 6749](https://www.rfc-editor.org/rfc/rfc6749)
- `README.md`
- `CHANGELOG.md`
- `docs/dependencies/20261026140645_rails-7-1-security-advisories.md`
- `spec/active_admin/device_authorization/oauth_requests_spec.rb`
- `spec/active_admin/device_authorization/consents_controller_spec.rb`
- `spec/active_admin/device_authorization/token_exchange_callback_spec.rb`
