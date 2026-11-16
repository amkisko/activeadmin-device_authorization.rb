# Routes and auth diff engineering audit

## Participants

Andrei Makarov

## Decisions

Audit the uncommitted RFC-0002 routes and consent cut. Pipeline: host
routes and ActiveAdmin page ingress, consent page_actions, public OAuth
controllers, no queue or worker change. Boundary mode: device consent UI and
public OAuth JSON. Resource and budget: no new hot-path allocation claim
beyond existing grant lookup. Trace: `user_code` moves from path to query on
complete URI; already in `filter_parameters`.

## Effects

### Findings fixed in this pass

1. High / contract / observed: `Page.register!` returned early when
   `register_active_admin_page` was false, so hosts could not register
   manually as RFC-0002 and README require. Flag gating moved to the engine
   auto-register path; `register!` always registers when called.
2. Medium / product-surface / observed: content title was always the authorize
   string on the enter-code screen. Title proc now follows grant presence.

### Accepted gaps

1. Medium / coverage / artifact-missing: no request-level CSRF example on the
   ActiveAdmin page_action approve path after ConsentsController removal.
   Forgery protection remains on `ActiveAdmin::BaseController` / Rails stack.
   Check that would close: host or dummy-app request that POSTs approve
   without a token and expects refusal.
2. Low / coverage / inference: index grant-load path is not executed in gem
   specs without a full ActiveAdmin router. Page registration and title
   contract are covered; host request specs remain the stronger gate.

### Modes skipped

Cache, queue, worker, learned systems, physical actuators: absent from this
diff.

## Next

Keep host cutover notes for query-shaped complete URIs and one-line OAuth
draw. Optional later: dummy-app CSRF request example.

## Source

- Working tree vs `main` for RFC-0002 routes and consent changes
- RFC-0002
