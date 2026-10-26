## Dependency

rails `~> 7.1.0` (resolved `7.1.6` via a temporary `rails71` Appraisal lockfile)

## Symptom

`make audit` / `bundler-audit` fails on `gemfiles/rails71.gemfile.lock` with multiple Action View, Active Storage, and Active Support advisories. Published fixes point at Rails 7.2.3+, 8.0.4+, or 8.1.2+ lines; there is no patched 7.1 release for these advisories.

## Evidence

- Observed while wiring Appraisal lockfiles for this gem.
- `bundler-audit check --gemfile-lock gemfiles/rails71.gemfile.lock` reported CVE-2026-33168, CVE-2026-33173, CVE-2026-33174, CVE-2026-33195, CVE-2026-33202, CVE-2026-33658, CVE-2026-66066, CVE-2026-33169, CVE-2026-33170, CVE-2026-33176 against rails 7.1.6 components.
- Advisory solutions name `~> 7.2.3, >= 7.2.3.1` (and later 7.2.3.2 / 8.x floors), not a 7.1 patch.

## Suggested fix

Raise the supported Rails floor to `>= 7.2` with Appraisal matrices starting at `rails72` (`~> 7.2`, `>= 7.2.3.2`), matching sibling ActiveAdmin gems. Do not keep an unpatched 7.1 lockfile in CI.

## Effects

- Gemspec runtime dependency moved from `rails >= 7.1` to `rails >= 7.2`.
- `rails71` Appraisal and lockfile removed.
- CI matrix and release Appraisal list start at `rails72`.

## Source

- Upstream advisories linked from bundler-audit output (Rails security advisories / CVE records cited above)
- Downstream: `Appraisals`, `activeadmin-device_authorization.gemspec`, `.github/workflows/test.yml`, `README.md`
