# Vigor Modernization & Refactor Plan

_Last updated: 2025-06-15_

---

## 0. Overview

This document is the **single source of truth** for architectural decisions, phased roadmap, and task tracking for the Vigor modernization effort. It will be updated continuously as work progresses.

## 1. Architectural Vision

Adopt _Clean / Hexagonal Architecture_ principles to achieve: testability, scalability, clear domain boundaries, and future service extraction.

## 2. Decision Log

| ID       | Date       | Decision                                                                           | Rationale                                         |
| -------- | ---------- | ---------------------------------------------------------------------------------- | ------------------------------------------------- |
| ADR-0001 | 2025-06-15 | Adopt Clean Architecture with Domain, Application, Adapters, Infrastructure layers | Aligns with SOLID, DDD, enables modular growth    |
| ADR-0002 | 2025-06-15 | Track modernization via `docs/metadata.md` + ADRs                                  | Single, auditable trail of progress and decisions |

_(Add new rows at the top as decisions are made.)_

## 3. Phased Roadmap & Task Board

The board uses GitHub-style checkboxes so progress can be tracked directly in code reviews.

### Phase 0 – Governance & Quality Gates (Week 1)

- [x] **Create ADR framework** (`docs/adr/README.md`, template, ADR-0001 & ADR-0002)
- [x] **Enforce quality gates in CI** (lint, mypy, tests, coverage ≥ 80 %)
- [x] **Introduce pre-commit hooks** (black, ruff, isort, commitlint)

### Phase 1 – Core Extraction (Weeks 1-2)

- [x] `request_validator.py`
- [x] `routing_engine.py`
- [x] `budget_enforcer.py`
- [x] `response_recorder.py`
- [x] Provide thin façade `LLMGatewayFacade` that composes the above.
- [x] Add unit tests (≥ 90 % coverage) for each extracted component.

### Phase 2 – Data Layer Consolidation (Weeks 3-4)

- [x] Introduce `repositories/` package encapsulating SQLAlchemy.
- [x] Generate/aligned Pydantic schemas via `pydantic-sqlalchemy` or custom mappers.
- [x] Remove direct ORM access from FastAPI routes.

### Phase 3 – Observability & Resilience (Weeks 4-5)

- [x] Add OpenTelemetry tracing + structured logging middleware.
- [x] Extract health-check & analytics jobs into background-worker (Celery/RQ).
- [x] Integrate distributed cache (e.g., Redis) via adapter pattern.

### Phase 4 – Frontend Restructure (Weeks 5-6)

- [x] Reorganize `frontend/src` into feature-sliced folders.
- [x] Introduce Zustand (state) + Storybook (UI inventory).
- [ ] Increase component/unit test coverage to 80 %.

### Phase 5 – DevOps & Delivery (Weeks 6-7)

- [ ] Optimise Dockerfiles with multi-stage builds.
- [ ] Enable Dependabot + licence scanning.

---

## 4. Risks & Mitigations

| Risk                                     | Impact | Mitigation                           |
| ---------------------------------------- | ------ | ------------------------------------ |
| Large-scale refactor may break prod APIs | High   | Phase-wise releases + contract tests |
| Schema changes cause data loss           | High   | Write migration scripts + backups    |
| Incomplete test coverage                 | Medium | Enforce coverage gate in CI          |

---

## 5. Glossary

_ADR_ – Architecture Decision Record.
_Domain Layer_ – Core business rules independent of frameworks.
