# Architecture Decision Records (ADR)

This directory stores **Architecture Decision Records** that capture important architectural and technical decisions for the Vigor project.

## Why ADRs?

- Provide a historical context and rationale for major changes.
- Enable onboarding engineers to understand "why" behind architecture.
- Encourage thoughtful design discussions and peer reviews.

## Process

1. Copy `_adr_template.md` to a new file named `ADR-XXXX-title.md`, where `XXXX` is the next sequential number.
2. Fill in the template sections.
3. Submit a pull-request for review marked with the `adr` label.
4. Link the ADR number in relevant tickets / documentation.
5. Update `docs/metadata.md` decision log table.

## Index

The following ADRs have been recorded (newest on top):

- ADR-0002 – Tracking modernization progress via `docs/metadata.md` + ADRs
- ADR-0001 – Adopt Clean Architecture with explicit layers

Update this list when adding new ADRs.
