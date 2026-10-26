# Rails 7.1 security advisories

## Dependency

- Rails was declared as `>= 7.1`.
- The minimum graph in `gemfiles/rails71.gemfile.lock` resolved Rails 7.1.6.

## Symptom

The current Ruby advisory database reports multiple Action View, Active Storage, and Active Support advisories against Rails 7.1.6. Their published fixed ranges start in Rails 7.2, so no Rails 7.1 release can form an advisory-clean supported graph.

## Evidence

After updating ruby-advisory-db to commit `03da937a9e171e3fedebde6620e203559b7a60c0`, `bundler-audit check --gemfile-lock gemfiles/rails71.gemfile.lock` failed. The results included CVE-2026-66066, whose first fixed Rails 7.2 version is 7.2.3.2, and CVE-2026-33168, whose first fixed Rails 7.2 version is 7.2.3.1.

## Suggested fix

Raise the runtime minimum to Rails 7.2.3.2. Lock the minimum CI graph to Rails 7.2.3.2 or newer and ActiveAdmin 3.2.x, then run the full test suite and advisory scan against that graph.

## Effects

- `activeadmin-device_authorization.gemspec` now requires Rails 7.2.3.2 or newer.
- `gemfiles/rails72.gemfile.lock` exercises Rails 7.2 with ActiveAdmin 3.2.x.
- The obsolete Rails 7.1 graph is no longer part of the test or audit matrix.

## Source

- [Rails advisory GHSA-xr9x-r78c-5hrm](https://github.com/rails/rails/security/advisories/GHSA-xr9x-r78c-5hrm)
- [Rails advisory GHSA-v55j-83pf-r9cq](https://github.com/rails/rails/security/advisories/GHSA-v55j-83pf-r9cq)
- `activeadmin-device_authorization.gemspec`
- `gemfiles/rails72.gemfile.lock`
