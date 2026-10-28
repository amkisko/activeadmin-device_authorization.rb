# ActiveAdmin 4 consent markup and resource owner

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Dual-class consent markup for ActiveAdmin 3 and 4: wrapper `attributes-table attributes_table`, table keeps `attributes_table` for standalone CSS.
- Approve and Deny submits stay inside `.formtastic` so AA4 Tailwind button rules apply.
- Code-comparison prompt uses `.device-auth-verify` with inline styles; keep `flash flash_alert` for AA3/standalone.
- `Configuration#resolve_current_resource_owner` uses `instance_exec` for zero-arity procs; arity-1 callables keep `call(controller)`.
- Document ActionPolicy page policy hooks `approve?`, `deny?`, and `step_up?` in the README.

## Effects

- Consent partial and standalone styles updated.
- Page and ConsentsController resolve the resource owner through the new helper.
- Specs cover private Devise helper resolution and AA4-oriented markup contract.
- Dependency note recorded under `docs/dependencies/`.

## Next

- Cut a release after 0.1.3 once this branch merges.
- Hosts can remove local consent view overrides after upgrading.

## Source

- `docs/dependencies/20261028093636_aa4-consent-markup-and-resource-owner.md`
- ActiveAdmin 4 attributes table / formtastic theme selectors
