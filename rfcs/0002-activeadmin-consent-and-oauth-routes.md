# RFC 0002: ActiveAdmin consent and OAuth routes

- Type: Standards Track
- Status: Stable
- Created: 2026-11-16
- Author: Andrei Makarov
- Feature Name: activeadmin-consent-and-oauth-routes

## Summary

Consent UI is owned by an ActiveAdmin page and page_actions drawn by
`ActiveAdmin.routes`. Public OAuth JSON endpoints stay on an explicit
one-line `Routes.draw` that namespaces under the configured path namespace.
Hosts do not declare consent routes.

## Motivation

Host `routes.rb` previously drew consent paths next to or under admin
namespaces. Mapper placement does not inherit ActiveAdmin authentication.
A parallel `consent: :controller` mode used gem controllers outside
`ActiveAdmin::BaseController`. Operators need consent on the ActiveAdmin
authz contract with zero consent route lines, while RFC 8628 device and token
endpoints remain explicitly public.

## Guide-level explanation

After configure, register the page via `ActiveAdmin.after_load` when
`register_active_admin_page` is true (default). Host routes:

```ruby
ActiveAdmin.routes(self)
ActiveAdmin::DeviceAuthorization::Routes.draw(self)
```

Consent lives at `/admin/device_auth` (index; optional `user_code` query).
Approve and deny are page_actions at `/admin/device_auth/approve` and
`/admin/device_auth/deny`. OAuth stays at `/admin/oauth/device_authorization`
and `/admin/oauth/token`. `verification_uri_complete` is the verification URI
with a `user_code` query parameter.

## Reference-level explanation

1. Consent MUST use the ActiveAdmin "Device Auth" page controller
   (`ActiveAdmin::BaseController` authentication and authorization).
2. Index GET with `user_code` MUST load the grant and render consent content.
   Index GET without `user_code` MUST render code entry.
3. Approve and deny MUST be `page_action` POST routes under the page path.
4. `Routes.draw(mapper)` MUST draw only OAuth POSTs, MUST apply
   `namespace config.path_namespace`, MUST use absolute gem controller paths,
   and MUST call `validate_rate_limits!` before drawing. It MUST NOT accept a
   `consent:` mode.
5. OAuth controllers MUST NOT require an admin session.
6. `verification_uri_complete` MUST be
   `verification_uri + "?" + user_code query` (RFC 8628 complete URI).
7. Call `Routes.draw` at the routes root. Nesting under another
   `namespace :admin` double-prefixes the path.
8. When `register_active_admin_page` is false, the gem MUST NOT auto-register
   the page; the host MAY call `Page.register!`.

## Drawbacks

Hosts that bookmarked path-shaped complete URIs
(`/device_auth/:user_code`) must update clients. Hosts that used
`consent: :controller` must adopt the ActiveAdmin page.

## Rationale and alternatives

Reject nesting third-party routes inside `ActiveAdmin.routes` (no upstream
hook). Reject auto-drawing OAuth (public protocol must stay explicit). Reject
keeping ConsentsController (bypasses BaseController). Query-shaped complete
URIs match ActiveAdmin page index and RFC 8628.

## Prior art

ActiveAdmin `register_page` / `page_action` routing. RFC 8628
`verification_uri_complete`. Onni vanity draw documents controller-owned
auth next to `ActiveAdmin.routes`.

## Unresolved questions

None for this contract cut.
