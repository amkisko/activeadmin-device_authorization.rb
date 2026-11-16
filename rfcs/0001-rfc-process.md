# RFC 0001: RFC process

- Type: Procedural
- Status: Stable
- Created: 2026-11-16
- Author: Andrei Makarov

## Summary

Record significant public contract changes as numbered RFCs before
implementation.

## Motivation

This gem needs a stable place to specify public behavior and link
implementation evidence.

## Guide-level explanation

Claim `rfcs/ids/NNNN` with the document's kebab-case slug, copy
`rfcs/0000-template.md`, and write `rfcs/NNNN-slug.md`. Describe the design,
alternatives, effects, and unresolved questions. Implementation changes cite
the RFC.

## Reference-level explanation

Identifiers are sequential and stay assigned after retirement. Required header
fields are Type, Status, Created, and Author. Required sections are Summary,
Motivation, Guide-level explanation, and Unresolved questions. Product RFCs
also specify reference behavior, drawbacks, rationale and alternatives, and
prior art.

Types are Standards Track, Informational, Historical, and Procedural. Statuses
are Draft, Experimental, Proposed, Stable, Final, Deferred, Rejected,
Superseded, and Obsolete. Proposed changes use a two-week review period. A
maintainer records acceptance as Stable; shipped behavior can be specified as
Stable immediately. Final marks a deployed contract whose breaking changes need
another RFC.

Keep documents below 150 lines when one concern fits. Repository paths are
allowed. Skip RFCs for bug fixes, typos, and refactors that preserve public
contracts.

## Unresolved questions

None for the initial process adoption.
