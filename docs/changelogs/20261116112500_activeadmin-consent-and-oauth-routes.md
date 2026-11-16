# ActiveAdmin consent and OAuth routes

## Participants

Andrei Makarov

## Decisions

Adopt RFC-0002: consent on ActiveAdmin page_actions drawn by
`ActiveAdmin.routes`; public OAuth via one-line `Routes.draw` at routes root;
drop ConsentsController and path-shaped complete URIs.

## Effects

Consent auth follows `ActiveAdmin::BaseController`. Hosts declare only OAuth
routes. `verification_uri_complete` is query-shaped. Engine auto-registers the
page when `register_active_admin_page` is true.

## Next

Shipped as 0.3.0. Host cutovers update `routes.rb` and any clients that stored
path-shaped complete URIs.

## Source

- RFC-0002
- CHANGELOG Unreleased
