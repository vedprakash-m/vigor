# Vigor Modernization & Refactor Plan

_Last updated: 2025-06-16_

---

## 0. Overview

This document is the **single source of truth** for architectural decisions, phased roadmap, and task tracking for the Vigor modernization effort. It will be updated continuously as work progresses.

## 1. Architectural Vision

Adopt _Clean / Hexagonal Architecture_ principles to achieve: testability, scalability, clear domain boundaries, and future service extraction.

## 2. Decision Log

| ID       | Date       | Decision                                                                                                         | Rationale                                                  |
| -------- | ---------- | ---------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| ADR-0007 | 2025-06-16 | **Local Validation**: Enhanced E2E validation to match CI/CD pipeline requirements                               | Fix gap where local validation skipped E2E tests           |
| ADR-0001 | 2025-06-15 | Adopt Clean Architecture with Domain, Application, Adapters, Infrastructure layers                               | Aligns with SOLID, DDD, enables modular growth             |
| ADR-0002 | 2025-06-15 | Track modernization via `docs/metadata.md` + ADRs                                                                | Single, auditable trail of progress and decisions          |
| ADR-0003 | 2025-06-15 | **Infrastructure**: Use 2 Azure Resource Groups: `vigor-db-rg` (persistent) + `vigor-rg` (compute)               | Cost control, separation of concerns, idempotency          |
| ADR-0004 | 2025-06-15 | **Deployment**: Single environment, single slot, static naming for cost optimization                             | Keep monthly cost under $100, simplify operations          |
| ADR-0005 | 2025-06-15 | **Resources**: vigor-backend (App Service), vigor-db (PostgreSQL), vigor-kv (Key Vault), vigor-storage (Storage) | Simple, static names for idempotency and clarity           |
| ADR-0006 | 2025-06-15 | **CI/CD**: Unified DAG-based pipeline replacing separate workflows                                               | Proper orchestration, staging validation, failure handling |

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

## 5. Infrastructure Architecture (Final)

### **Resource Groups & Naming Convention**

#### **vigor-db-rg** (Persistent Layer)

- `vigor-db` - PostgreSQL Flexible Server (Basic tier)
- `vigor-kv` - Key Vault (Standard tier)
- `vigor-storage` - Storage Account (Standard LRS)

#### **vigor-rg** (Compute Layer)

- `vigor-backend` - App Service (Basic B1)
- `vigor-frontend` - Static Web App (Free tier)

### **Cost-Optimized Architecture**

```
Internet → Static Web App (Free) → App Service (Basic B1) → PostgreSQL (Basic)
                                         ↓
                                   Key Vault + Storage
```

### **Monthly Cost Estimate**

- App Service Basic B1: ~$13/month
- PostgreSQL Basic: ~$25/month
- Key Vault: ~$3/month
- Storage Account: ~$2/month
- Static Web App: Free
- **Total: ~$43/month**

### **Deployment Strategy**

- **Single Environment**: Production only (no staging)
- **Single Slot**: No deployment slots (cost savings)
- **Static Naming**: All resources use static names for idempotency
- **Blue-Green**: Not used (cost optimization)

### **Current Status** ✅

- Resource groups exist and deployed
- Backend returning 503 (needs deployment fix)
- Infrastructure ready, CI/CD gaps need fixing

---

## 6. Glossary

_ADR_ – Architecture Decision Record.
_Domain Layer_ – Core business rules independent of frameworks.
