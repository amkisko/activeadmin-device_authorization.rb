# AA4 consent markup and resource owner

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Require ActiveAdmin 4 only (`>= 4.0.0.beta19`, `< 5`); drop ActiveAdmin 3 support and dual-class markup.
- Consent uses `.attributes-table` wrapper, `.device-auth-verify` for the code-comparison prompt, and Approve/Deny submits inside `.formtastic`.
- `Configuration#resolve_current_resource_owner` uses `instance_exec` for zero-arity procs; arity-1 callables keep `call(controller)`.
- Document ActionPolicy page policy hooks `approve?`, `deny?`, and `step_up?` in the README.
- Pin CI/Appraisal graphs to ActiveAdmin `4.0.0.beta23` until a stable 4.0.0 ships.

## Effects

- Gemspec, Gemfile, Appraisals, consent partial, and standalone styles updated for AA4-only.
- Page and ConsentsController resolve the resource owner through the new helper.
- Specs cover private Devise helper resolution and AA4 markup contract.
- Dependency note recorded under `docs/dependencies/`.

## Next

- Cut a release after 0.1.3 once this branch merges.
- Hosts can remove local consent view overrides after upgrading.
- Revisit the ActiveAdmin pin when 4.0.0 stable is published.

## Source

- `docs/dependencies/20261028093636_aa4-consent-markup-and-resource-owner.md`
- ActiveAdmin 4 attributes table / formtastic theme selectors
