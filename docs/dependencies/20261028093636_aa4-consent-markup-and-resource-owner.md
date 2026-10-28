# AA4 consent markup and resource owner

## Participants

Andrei Makarov (@amkisko)

## Dependency

activeadmin-device_authorization ~> 0.1.3 (RubyGems 0.1.3) depended on activeadmin >= 3.2. This change raises the floor to ActiveAdmin 4 (`>= 4.0.0.beta19`, `< 5`), pinned in CI to `4.0.0.beta23`.

## Symptom

Consent under `/admin/device_auth/:user_code` shows broken spacing and unstyled Approve/Deny controls on ActiveAdmin 4. Gem 0.1.3 partials used ActiveAdmin 3 class names (`attributes_table`, `flash flash_alert`) and placed submit controls outside `.formtastic`, so AA4 button rules did not apply.

Separately, hosts that authorize ActiveAdmin pages with ActionPolicy need `approve?` / `deny?` / `step_up?` on the page policy; missing methods fail closed. After that gate, `config.current_resource_owner = ->(c) { c.current_user }` raises because Devise marks `current_user` private when called with an explicit receiver.

## Evidence

- Gem `app/views/active_admin/device_authorization/_consent.html.erb` in 0.1.3 used `table.attributes_table`, `flash flash_alert`, and a `fieldset.actions` outside the approve `formtastic` form.
- ActiveAdmin 4 attributes table component adds `attributes-table` (hyphen) on a wrapper; Tailwind theme styles `.attributes-table` and `.formtastic [type=submit]`.
- Device Auth page actions `approve`, `deny`, and `step_up` are authorized as page actions; ActionPolicy adapters typically require matching `action_name?` methods.
- `lib/active_admin/device_authorization/page.rb` and `ConsentsController` called `config.current_resource_owner.call(self)`; README showed `controller.current_admin_user` without `send`.

## Suggested fix

Require ActiveAdmin 4 only. Ship AA4 consent markup (`.attributes-table`, self-contained verify prompt, submits inside `.formtastic`), resolve zero-arity `current_resource_owner` via `instance_exec`, and document arity-1 `send(:current_user)` plus PagePolicy hooks for `approve?`, `deny?`, and `step_up?`.

Host workaround until upgrade: override `_consent.html.erb`, add those PagePolicy methods, and use `controller.send(:current_user)` or a zero-arity proc.

## Next

Release gem beyond 0.1.3; drop host view overrides after upgrade; loosen the beta pin when ActiveAdmin 4.0.0 stable ships.

## Source

- Upstream ActiveAdmin 4 attributes table / formtastic Tailwind selectors; RubyGems `activeadmin` 4.0.0.beta23
- Downstream: gemspec, Appraisals, `app/views/active_admin/device_authorization/_consent.html.erb`, `lib/active_admin/device_authorization/configuration.rb`, `lib/active_admin/device_authorization/page.rb`, `README.md`
