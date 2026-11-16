# Specs

## Layers

- `spec/active_admin/` - unit and isolated controller/route examples (no dummy app)
- `spec/requests/` - dummy Rails request e2e (OAuth JSON + ActiveAdmin GraphQL bearer)
- `spec/system/` - Capybara + Playwright browser e2e against `spec/dummy`
- `spec/dummy/` - minimal Rails + ActiveAdmin 4 + Devise + device auth models + GraphQL

## Playwright

System specs use `capybara-playwright-driver` and skip when the Playwright CLI is
missing (`PlaywrightEnv`). Pin the npm `playwright` package to
`Playwright::COMPATIBLE_PLAYWRIGHT_VERSION` from `playwright-ruby-client`
(currently `1.64.0`). A mismatched CLI yields driver errors such as
`timeout: expected float, got undefined`.

```bash
npm install
npx playwright install chromium
export PLAYWRIGHT_CLI_EXECUTABLE_PATH="$PWD/node_modules/.bin/playwright"
bundle exec rspec spec/system
```

Headful local debug: `HEADFUL=1 bundle exec rspec spec/system`.

## Commands

```bash
bundle exec rspec
bundle exec rspec spec/requests spec/system
bundle exec appraisal rspec
```
