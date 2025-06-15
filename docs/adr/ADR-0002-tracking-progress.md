# ADR-0002: Modernization Progress Tracking via docs/metadata.md + ADRs

Date: 2025-06-15

## Status

Accepted

## Context

The modernization initiative spans multiple quarters and involves cross-functional teams. Without a central artefact, decisions and progress become fragmented across tickets, PR descriptions, and chat threads, risking misalignment and knowledge loss.

## Decision

- Use `docs/metadata.md` as the canonical living roadmap.
- All architectural or strategically significant decisions must be captured as an ADR in `docs/adr/`.
- `docs/adr/README.md` maintains an index of ADRs.
- CI fails if a PR modifies critical architecture files without updating metadata or adding an ADR (implemented via linter).

## Consequences

### Positive

- Single source of truth for newcomers and auditors.
- Enforces discipline in documenting decisions.

### Negative

- Slight overhead in writing ADRs and keeping metadata up-to-date.

## Alternatives Considered

- GitHub Projects board only – good for task tracking, poor for deep rationale.
- External wiki – risks drift from repository.
