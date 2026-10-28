# activeadmin-device_authorization

[![Test Status](https://github.com/amkisko/activeadmin-device_authorization.rb/actions/workflows/test.yml/badge.svg)](https://github.com/amkisko/activeadmin-device_authorization.rb/actions/workflows/test.yml)

RFC 8628-style device authorization for ActiveAdmin: public device/token endpoints, signed-in consent in the admin UI, and short-lived bearer access tokens.

## Requirements

- Ruby 3.4+
- Rails 7.2.3.2+
- ActiveAdmin 3.2+ (consent markup also targets ActiveAdmin 4 Tailwind class names)

## Install

From RubyGems after a release:

```ruby
# Gemfile
gem "activeadmin-device_authorization"
```

From git:

```ruby
# Gemfile
gem "activeadmin-device_authorization", github: "amkisko/activeadmin-device_authorization.rb"
```

Maintainers publish with `make release` (`usr/bin/release.rb`), which builds, pushes to RubyGems, tags the version, and creates a GitHub release.

## Why these settings are configurable

- `challenge_expires_in` (default 600s): RFC 8628 requires `expires_in` for device/user codes. The RFC example is 1800s; Doorkeeper device grant defaults to 300s. Always required; device codes must expire.
- `poll_interval` (default 5s): RFC 8628 `interval`; clients must use 5 when omitted.
- `slow_down_increment` (default 5s): RFC 8628 `slow_down` requires increasing the interval by 5s. Keep 5 unless you have a documented reason.
- `access_token_absolute_ttl` (default 4h): Absolute bearer cap (RFC 6819 short-lived access tokens). Set to `nil` to disable absolute expiry.
- `access_token_idle_ttl` (default 1h): Idle timeout after last successful use (common IdP pattern with an absolute max). Set to `nil` to disable idle expiry.
- `access_token_default_absolute_ttl` / min / max / `choices`: Consent UI lifetime picker and clamp so a client cannot ask for longer than the host allows.
- Both access TTLs `nil`: revoke-only. Allowed for low-risk hosts; not recommended for admin APIs that can read or act on customer data.
- `user_code_*`: RFC 8628 end-user code shape (default 8 characters in groups of 4; ambiguous I/O omitted).
- `grant_retention_period` / `token_retention_period`: Bounded cleanup of unused challenges and expired or revoked tokens.
- Model class names: host keeps its own ActiveRecord models; the gem drives protocol against them.
- Scope lists, labels, and audit callbacks: product-specific; stay in the host.
- Rate-limit procs: host wires abuse limits; both are required before routes can be drawn.

## Setup

```ruby
# config/initializers/active_admin_device_authorization.rb
ActiveAdmin::DeviceAuthorization.configure do |config|
  config.resource_owner_class_name = "AdminUser"
  config.client_class_name = "DeviceAuthorizationClient"
  config.grant_class_name = "DeviceAuthorizationGrant"
  config.access_token_class_name = "DeviceAuthorizationAccessToken"
  # Prefer zero-arity: the gem runs this with instance_exec on the controller.
  # Devise helpers are often private; do not call them with an explicit receiver.
  config.current_resource_owner = -> { current_admin_user }
  # Arity-1 form still works; use send when the helper is private:
  # config.current_resource_owner = ->(controller) { controller.send(:current_admin_user) }

  config.scopes = %w[api:read api:write]
  config.default_scopes = %w[api:read api:write]
  config.scope_labels = {
    "api:read" => "API read",
    "api:write" => "API write"
  }

  # Optional: disable idle expiry
  # config.access_token_idle_ttl = nil

  # Optional: never expire until revoke (not recommended for admin APIs)
  # config.access_token_absolute_ttl = nil
  # config.access_token_idle_ttl = nil

  config.on_consent_approved = ->(resource_owner:, grant:) { }
  config.on_token_issued = ->(resource_owner:, token:) { }

  # These host methods must return exactly true to admit the request. They may
  # render their own response and return anything else to stop processing.
  config.rate_limit_device_authorization = lambda { |controller|
    DeviceAuthorizationRateLimits.allow_challenge?(controller.request)
  }
  config.rate_limit_token = lambda { |controller|
    DeviceAuthorizationRateLimits.allow_poll?(controller.request)
  }
end
```

```ruby
# config/routes.rb (inside the admin namespace)
namespace :admin do
  ActiveAdmin::DeviceAuthorization::Routes.draw(self)
  # Optional: Routes.draw(self, consent: :controller) serves the code-entry and
  # consent pages from the gem instead of ActiveAdmin page actions.
end
```

OAuth controller paths are absolute (`/active_admin/device_authorization/...`) so nesting under `namespace :admin` does not invent `Admin::ActiveAdmin::...` constants. Consent defaults to the ActiveAdmin page (`device_auth#...`).

`access_token_absolute_ttl` is the hard ceiling. Consent `min` / `max` / `default` / `choices` must sit inside that ceiling; `clamp_absolute_ttl` uses `min(access_token_max_absolute_ttl, access_token_absolute_ttl)`.

Consent and token callbacks run after their database commit. A callback exception is reported through `Rails.error` and does not hide the committed decision or issued token from the caller. Use a durable host-side job or outbox when delivery must be retried.

RFC 8628 `slow_down` raises the required poll interval by `slow_down_increment` when the grant stores `poll_interval_seconds`. Without that column, the server still returns `slow_down` against the base `poll_interval` only.

### Host responsibilities

The gem does not replace host security controls. Before production traffic:

- Wire both `rate_limit_device_authorization` and `rate_limit_token`. Route mounting fails unless both are callable. Each request continues only when its limiter returns exactly `true`. Load-test the policies you choose.
- Set `verification_base_url` to the host's trusted HTTPS origin in production. When it is unset, verification links use `request.base_url`, so the host must enforce HTTPS and reject untrusted `Host` headers.
- Schedule `bundle exec rake active_admin:device_authorization:retention` at the cadence required by the host retention policy. Token retention deletes rows past `token_retention_period` after absolute expiry, revoke, or idle expiry (when idle TTL is enabled). Do not rely on absolute expiry alone when absolute TTL is nil (far-future sentinel).
- Implement host models and indexes that match the contract below, including uniqueness and foreign keys.
- Authenticate bearer tokens in the host API (see Bearer validation contract). The gem issues and expires tokens; it does not install API authentication middleware.
- When the host authorizes ActiveAdmin pages with ActionPolicy (or a similar adapter that maps actions to `action_name?` methods), define `approve?`, `deny?`, and `step_up?` on the page policy. Missing methods fail closed and Approve/Deny/step-up return unauthorized. `step_up?` is needed only when `on_approve_step_up` is configured.

```ruby
# Example ActionPolicy page policy hooks for Device Auth
class ActiveAdmin::PagePolicy < ApplicationPolicy
  def show?
    true
  end

  def approve?
    show?
  end

  def deny?
    show?
  end

  def step_up?
    show?
  end
end
```

### Host model contract

- Client: `enabled` scope, `find_by!(client_id:)`, `allows_scopes?(scopes)`
- Grant: `create!`, `exists?(user_code:)`, `lock.find_by(...)`, `pending?`, `mark_expired_if_needed!`, `requested_scopes` / `granted_scopes`, `last_poll_at`, optional `absolute_ttl_seconds`, optional `poll_interval_seconds` (raised after each `slow_down`), `has_one` access token
- Access token: `create!` with digest, scopes, `absolute_expires_at`, `last_used_at`; optional `revoked_at`
- Associations named from configured class names (`DeviceAuthorizationClient` -> `device_authorization_client`, and so on)
- Grant states `pending`, `approved`, `denied`, and `expired`; only `pending` may transition to a terminal state, and an approved grant may have at most one access token
- Unique indexes for client IDs, user codes, token digests, each client/device-code-digest pair, and the access token's grant foreign key; foreign keys for the grant, client, and resource owner associations
- Indexes that support expiry, revoke, idle-use, and challenge-retention queries

### Bearer validation contract

The gem issues and expires tokens, but it does not install authentication in the host API. For every protected request, the host must digest the presented bearer value with `ActiveAdmin::DeviceAuthorization.config.digest`, find the matching token through the allowed client or resource-owner relation, reject it when `AccessTokenExpiry#expired?` is true, enforce its scopes, and update `last_used_at` only after successful authentication. A missing, revoked, expired, or out-of-scope token must fail closed.

Register the ActiveAdmin page after configuration:

```ruby
ActiveAdmin::DeviceAuthorization::Page.register!
```

## Protocol

1. `POST /admin/oauth/device_authorization` with `client_id` and `scope`
2. Open `verification_uri` / `verification_uri_complete` while signed in as an admin user
3. Approve or deny (optional host `before_approve` / `on_approve_step_up` for step-up second factor before Approve; Deny is ungated)
4. Poll `POST /admin/oauth/token` with `grant_type=urn:ietf:params:oauth:grant-type:device_code`

## Development

```bash
bundle install
bundle exec appraisal install
make lint
make test
```

Matrixed Rails versions use [Appraisal](https://github.com/thoughtbot/appraisal): `gemfiles/rails72.gemfile`, `rails8ruby34.gemfile`, and `rails8ruby4.gemfile`. Run `bundle exec appraisal rspec` to execute RSpec in each gemfile context.

[Trunk](https://docs.trunk.io) config lives in `.trunk/`; CI can run `trunk` via `.github/workflows/_trunk_check.yml`. Releases: `make release` or `usr/bin/release.rb`.

## Security

Report vulnerabilities to security@kiskolabs.com. See [SECURITY.md](SECURITY.md).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/amkisko/activeadmin-device_authorization.rb

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.md).
