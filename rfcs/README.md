# activeadmin-device_authorization RFCs

RFC-0001 defines the process. Claim an unused four-digit identifier in `ids/`
before adding its RFC. Identifiers are sequential; there are no numbering bands.
Repository-relative implementation references are allowed. There is no isolation
rule or separate RFC-only test suite.

- [RFC-0001: RFC process](0001-rfc-process.md)
- [RFC-0002: ActiveAdmin consent and OAuth routes](0002-activeadmin-consent-and-oauth-routes.md)

Use [the template](0000-template.md), omit unused sections, and preserve existing
identifiers. Implementation changes cite their RFC and prove behavior with specs.
