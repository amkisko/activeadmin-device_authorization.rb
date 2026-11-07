## Dependency

rails `~> 7.2` (resolved `7.2.4` via `gemfiles/rails72.gemfile.lock`)

## Symptom

`bundler-audit check --gemfile-lock gemfiles/rails72.gemfile.lock` fails after ruby-advisory-db picks up the November 2026 Action Pack / Action View / Active Storage / Active Support advisories. Published fixes name `~> 8.0.5, >= 8.0.5.2` or `>= 8.1.4.1` only; there is no patched 7.2 release for these advisories yet.

## Evidence

- `Gemfile.lock` / rails8 appraisals clear after bumping to rails `8.1.4.1`, nokogiri `1.19.7`, rack `3.2.8`, and rails-html-sanitizer `1.7.2`.
- rails72 remains on `7.2.4` (latest 7.2 on RubyGems) and still reports the GHSA set that only lists 8.x solutions.
- Quality `make audit` previously failed the whole job once any lockfile failed.

## Suggested fix

Keep rails72 in the test matrix for compatibility, but skip that lockfile in `make audit` until Rails ships a 7.2.x security release that covers these advisories. Re-enable the audit line when a patched 7.2 gem is published.

## Effects

- Root and rails8 lockfiles audited and green.
- rails72 lockfile excluded from `make audit` with an explicit skip message.
- Tests for rails72 continue to run.

## Source

- bundler-audit / ruby-advisory-db against `gemfiles/rails72.gemfile.lock`
- RubyGems `rails` 7.2 line (latest `7.2.4` at write time)
