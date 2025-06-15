# ADR-0001: Adopt Clean / Hexagonal Architecture

Date: 2025-06-15

## Status

Accepted

## Context

The existing codebase lacks an explicit architectural structure. Business rules, infrastructure, and presentation logic are intermixed (e.g., `core/llm_orchestration/gateway.py` acts as a God-class). This causes:

- High cognitive load for new contributors.
- Low testability because side-effects and network calls are woven into domain logic.
- Difficult scalability and future service extraction.

A well-defined Clean (a.k.a. Hexagonal) architecture enforces separation between:

1. **Domain Layer** – Business rules and entities.
2. **Application Layer** – Use-cases orchestrating domain logic.
3. **Adapters (Interface) Layer** – Inbound (HTTP, CLI) and outbound (DB, Key Vault, LLM providers) ports.
4. **Infrastructure Layer** – Framework and SDK implementations.

## Decision

- Re-organise project into `domain/`, `application/`, `adapters/` and `infrastructure/` top-level packages.
- Each external system interaction is represented by a port interface; concrete implementations reside in `infrastructure`.
- Controllers (FastAPI routes) become thin inbound adapters delegating to application services.
- Cross-cutting concerns (logging, tracing, auth, caching) implemented via middleware/decorators.

## Consequences

### Positive

- Testability improves; pure domain/application layers can be unit-tested without DB or external APIs.
- Clear boundaries reduce coupling and facilitate parallel development.
- Paves the way for extracting micro-services if required.

### Negative

- Significant refactor effort; temporary decrease in velocity.
- File paths change, creating large PRs that may complicate code review history.

## Alternatives Considered

- Keep current structure and incrementally fix issues (ruled out due to compounding complexity).
- Adopt micro-services immediately (premature; higher ops overhead).

## References

- Uncle Bob Martin – Clean Architecture
- Alistair Cockburn – Hexagonal Architecture (Ports & Adapters)
