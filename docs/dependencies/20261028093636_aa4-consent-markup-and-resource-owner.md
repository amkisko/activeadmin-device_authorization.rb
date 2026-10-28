# ActiveAdmin 4 consent markup and resource owner

## Participants

Andrei Makarov (@amkisko)

## Dependency

activeadmin-device_authorization ~> 0.1.3 (RubyGems 0.1.3); hosts that render consent under ActiveAdmin 4 Tailwind.

## Symptom

Consent under `/admin/device_auth/:user_code` shows broken spacing and unstyled Approve/Deny controls on ActiveAdmin 4. Gem partials used ActiveAdmin 3 class names (`attributes_table`, `flash flash_alert`) and placed submit controls outside `.formtastic`, so AA4 button rules did not apply.

Separately, hosts that authorize ActiveAdmin pages with ActionPolicy need `approve?` / `deny?` / `step_up?` on the page policy; missing methods fail closed. After that gate, `config.current_resource_owner = ->(c) { c.current_user }` raises because Devise marks `current_user` private when called with an explicit receiver.

## Evidence

- Gem `app/views/active_admin/device_authorization/_consent.html.erb` in 0.1.3 used `table.attributes_table`, `flash flash_alert`, and a `fieldset.actions` outside the approve `formtastic` form.
- ActiveAdmin 4 attributes table component adds `attributes-table` (hyphen) on a wrapper; Tailwind theme styles `.attributes-table` and `.formtastic [type=submit]`.
- Device Auth page actions `approve`, `deny`, and `step_up` are authorized as page actions; ActionPolicy adapters typically require matching `action_name?` methods.
- `lib/active_admin/device_authorization/page.rb` and `ConsentsController` called `config.current_resource_owner.call(self)`; README showed `controller.current_admin_user` without `send`.

## Suggested fix

Upstream (this repository): ship AA4-compatible consent markup (dual-class attributes table, verify prompt with self-contained styles, submits inside `.formtastic`), resolve zero-arity `current_resource_owner` via `instance_exec`, document arity-1 `send(:current_user)` and PagePolicy hooks for `approve?`, `deny?`, and `step_up?`.

Host workaround until upgrade: override `_consent.html.erb`, add those PagePolicy methods, and use `controller.send(:current_user)` or a zero-arity proc.

## Next

Release gem beyond 0.1.3; drop host view overrides after upgrade.

## Source

- Upstream ActiveAdmin 4 attributes table / formtastic Tailwind selectors
- Downstream: `app/views/active_admin/device_authorization/_consent.html.erb`, `lib/active_admin/device_authorization/configuration.rb`, `lib/active_admin/device_authorization/page.rb`, `README.md`
