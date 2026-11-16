# Dummy e2e with Playwright and GraphQL bearer

## Decisions

- Treat browser and request e2e as mandatory for this gem: consent is ActiveAdmin UI, token use is GraphQL bearer.
- Drive system specs with Capybara + `capybara-playwright-driver` and pin npm `playwright` to `Playwright::COMPATIBLE_PLAYWRIGHT_VERSION` (1.64.0).
- Host the flow in `spec/dummy` (Rails, ActiveAdmin 4, Devise, device models, activeadmin-graphql).
- Restore dummy Device Authorization config before each request/system example so unit `reset_config!` does not break OAuth draw or scopes.
- Restore stubbed `ActiveAdmin.application` / `after_load` / `register_page` after engine and page unit examples so the dummy app keeps working in a shared process.

## Effects

- `spec/system/device_authorization_consent_spec.rb` covers signed-in approve and unsigned redirect.
- `spec/requests/device_authorization_graphql_e2e_spec.rb` covers challenge, consent, token, and GraphQL bearer deny/allow.
- CI installs Node, npm Playwright, and Chromium; sets `PLAYWRIGHT_CLI_EXECUTABLE_PATH`.
- Observed: `bundle exec rspec` -> 73 examples, 0 failures; `bundle exec rspec spec/active_admin` -> 69 examples, 0 failures.

## Next

- Keep npm Playwright version aligned when upgrading `playwright-ruby-client`.
- No further release blocker; coverage shipped with 0.3.0.

## Source

- `spec/README.md`
- `spec/dummy/`
- `.github/workflows/test.yml`
- RFC-0002 consent and OAuth route split
