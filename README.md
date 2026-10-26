# activeadmin-device_authorization

[![Test Status](https://github.com/amkisko/activeadmin-device_authorization.rb/actions/workflows/test.yml/badge.svg)](https://github.com/amkisko/activeadmin-device_authorization.rb/actions/workflows/test.yml)

RFC 8628-style device authorization for ActiveAdmin: public device/token endpoints, signed-in consent in the admin UI, and short-lived bearer access tokens.

This gem is unpublished (`allowed_push_host` empty) while the repository is private. Host apps can link it with a git source once they have access.

## Requirements

- Ruby 3.2+
- Rails 7.1+
- ActiveAdmin 3.2+

## Install

```ruby
# Gemfile
gem "activeadmin-device_authorization", github: "amkisko/activeadmin-device_authorization.rb"
```

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
- Rate-limit procs: host wires abuse limits; the gem does not own a limiter.

## Setup

```ruby
# config/initializers/active_admin_device_authorization.rb
ActiveAdmin::DeviceAuthorization.configure do |config|
  config.resource_owner_class_name = "AdminUser"
  config.client_class_name = "DeviceAuthorizationClient"
  config.grant_class_name = "DeviceAuthorizationGrant"
  config.access_token_class_name = "DeviceAuthorizationAccessToken"
  config.current_resource_owner = ->(controller) { controller.current_admin_user }

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
  config.rate_limit_device_authorization = ->(controller) { }
  config.rate_limit_token = ->(controller) { }
end
```

```ruby
# config/routes.rb (inside the admin namespace)
namespace :admin do
  ActiveAdmin::DeviceAuthorization::Routes.draw(self)
  # Optional: Routes.draw(self, consent: :controller) for the gem ConsentsController
  # instead of ActiveAdmin page actions (device_auth#show/approve/deny).
end
```

OAuth controller paths are absolute (`/active_admin/device_authorization/...`) so nesting under `namespace :admin` does not invent `Admin::ActiveAdmin::...` constants. Consent defaults to the ActiveAdmin page (`device_auth#...`).

`access_token_absolute_ttl` is the hard ceiling. Consent `min` / `max` / `default` / `choices` must sit inside that ceiling; `clamp_absolute_ttl` uses `min(access_token_max_absolute_ttl, access_token_absolute_ttl)`.

Token retention deletes rows past `token_retention_period` after absolute expiry, revoke, or idle expiry (when idle TTL is enabled). Do not rely on absolute expiry alone when absolute TTL is nil (far-future sentinel).

RFC 8628 `slow_down` raises the required poll interval by `slow_down_increment` when the grant stores `poll_interval_seconds`. Without that column, the server still returns `slow_down` against the base `poll_interval` only.

### Host model contract

- Client: `enabled` scope, `find_by!(client_id:)`, `allows_scopes?(scopes)`
- Grant: `create!`, `exists?(user_code:)`, `lock.find_by(...)`, `pending?`, `mark_expired_if_needed!`, `requested_scopes` / `granted_scopes`, `last_poll_at`, optional `absolute_ttl_seconds`, optional `poll_interval_seconds` (raised after each `slow_down`), `has_one` access token
- Access token: `create!` with digest, scopes, `absolute_expires_at`, `last_used_at`; optional `revoked_at`
- Associations named from configured class names (`DeviceAuthorizationClient` -> `device_authorization_client`, and so on)

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
bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/amkisko/activeadmin-device_authorization.rb

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.md).
