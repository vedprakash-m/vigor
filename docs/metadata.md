# Vigor – Repository Metadata (Source of Truth)

> This file condenses the operational and architectural knowledge previously scattered across helper guides, CI notes and ADRs. Treat it as the **living root reference**. When a decision materially affects the repo, update this file (or add a new ADR and link it here).

---

## 1. Architecture Snapshot

| Layer              | Purpose                                                   | Key Directories                              |
| ------------------ | --------------------------------------------------------- | -------------------------------------------- |
| **Domain**         | Pure business entities & rules (no I/O)                   | `backend/core/`, `backend/domain/`           |
| **Application**    | Use-case orchestration                                    | `backend/application/`                       |
| **Adapters**       | Inbound (FastAPI routes) & outbound ports                 | `backend/api/` (routes, schemas, services)   |
| **Infrastructure** | SDK / framework impl. (DB, Key Vault, LLM, Celery, Bicep) | `backend/infrastructure/`, `infrastructure/` |

_Governed by ADR-0001 (Clean / Hexagonal Architecture)._

---

## 2. Multi-Provider LLM Strategy

- OpenAI GPT-4 → Gemini Pro → Perplexity Pro → Local templates fallback.
- Orchestration entry-point: `backend/application/llm/facade.py` (`LLMGatewayFacade`).
- Budget enforcement via `AICostManager` (see Tech Spec §4). Decision enum `{OK, DOWNGRADE, DENY}` drives provider selection or degradation template.
- Free tier quotas (enforced monthly per user): **5 workout plans + 10 AI chats**.
- Admins can override quotas/budgets through `/admin/limits/override` (PRD §6.2.5).

---

## 3. CI/CD & Local Validation

Command `./scripts/local-ci-validate.sh` mirrors the GitHub Actions pipeline.

| Mode       | Flags          | What Runs                                                                                        |
| ---------- | -------------- | ------------------------------------------------------------------------------------------------ |
| Full       | _none_         | Backend lint/test/type-check, Frontend lint/test/build, security scans, Bicep compile, e2e tests |
| Pre-commit | `--pre-commit` | Fast linters & secret scan (no tests/build) – hooked by `scripts/setup-git-hooks.sh`             |

CI optimisations (see `ci_optimization_guide.md`): cache npm & pip, matrix builds, job dependency graph.

Workflow health is auto-checked daily by `workflow-health-check.yml` (lint YAML, check success rates, create issues, send Slack alert).

---

## 4. Secrets & Tokens

Best-practice guardrails (from `secrets_management_guide.md`):

1. **OIDC first** – prefer cloud-native OIDC (Azure) over static secrets.
2. `permissions:` least-privilege in every workflow.
3. Secret scanning: `gitleaks` & `trufflehog` on PRs.
4. Key rotation cron (`Rotate Secrets` workflow) monthly.

---

## 5. Branch / PR Automation

_Referencing `dev_pr_mgmt.md`_

| Feature                  | Mechanism                                                                                                       |
| ------------------------ | --------------------------------------------------------------------------------------------------------------- |
| **Short-lived branches** | `feature/*`, `hotfix/*`, `dependabot/*` – merge ≤ 3 days                                                        |
| **Auto-merge**           | `.github/workflows/auto-merge.yml` (labels + status gates)                                                      |
| **PR lifecycle**         | size check, stale bot, classifier labels                                                                        |
| **Override paths**       | Major Release / Security Fix – request template in `agent_communication_guide.md`; admin label triggers bypass. |

---

## 6. GitHub Action Quality Rules

- Based on `workflow_testing_guide.md` – local testing with `act`, actionlint, version pinning (SHA), job timeouts, circuit-breaker disable on flake.
- CI must keep **≥ 80 % workflow success rate** (health check opens issue otherwise).

---

## 7. Infrastructure State

| Concern             | Source                                                                        |
| ------------------- | ----------------------------------------------------------------------------- |
| **IaC**             | Bicep files under `infrastructure/bicep/` (Azure-only)                        |
| **Resource groups** | `vigor-rg` (compute, deletable), `vigor-db-rg` (persistent)                   |
| **Scripts**         | `infrastructure/bicep/deploy.sh` (dev/prod), plus local helpers in `scripts/` |

Terraform **not used** – any `.tf` remnants should be removed.

---

## 8. ADR Index

| ADR      | Decision                                     |
| -------- | -------------------------------------------- |
| ADR-0001 | Adopt Clean/Hexagonal Architecture           |
| ADR-0002 | Track progress via `docs/metadata.md` + ADRs |

New architectural decisions → add a numbered ADR under `docs/adr/` and update this table.

---

## 9. Contribution & Governance

- Use **semantic PR titles** (`feat:`, `fix:`, etc.).
- All critical file changes must update this metadata or add an ADR; CI linter enforces.
- Follow the license (MIT) and the etiquette in `CONTRIBUTING.md`.

---

## 10. Production Deployment Plan (2025-07-24)

### 10.1 Current Status: CI/CD Pipeline Preparation Phase

**Deployment Strategy**: CI/CD-First Approach (GitHub Actions → Azure)
**Timeline**: 5-8 days (Started: 2025-07-24)

| Phase       | Status         | Duration | Key Activities                            | Completion |
| ----------- | -------------- | -------- | ----------------------------------------- | ---------- |
| **Phase 1** | ✅ Completed   | 1-2 days | Local validation, CI/CD pipeline prep     | 100%       |
| **Phase 2** | 🔄 In Progress | 1-2 days | Azure setup, GitHub secrets configuration | 0%         |
| **Phase 3** | ⏳ Pending     | 1 day    | CI/CD deployment via GitHub Actions       | 0%         |
| **Phase 4** | ⏳ Pending     | 1-2 days | Post-deployment verification, monitoring  | 0%         |

### 10.2 Pre-Flight System Assessment

**Critical Dependencies Identified:**

- ✅ Azure CLI (v2.75.0) and Bicep (v0.36.177) - Ready
- ✅ Python 3.13.5 and Node.js 22.15.1 - Ready
- ✅ **RESOLVED**: All Python dependencies working (SQLAlchemy upgraded to 2.0.41 for Python 3.13 compatibility)
- ✅ Frontend dependencies installed and secured (npm audit fix applied)
- ⚠️ GitHub CLI not installed (needed for secrets management)
- ⚠️ Azure subscription and authentication setup required
- ⚠️ GitHub secrets configuration for CI/CD pipeline
- ⚠️ Database URL configuration (currently using SQLite fallback)
- ⚠️ Virtual environment activation needed for proper testing
- ⚠️ Test coverage improvement needed (Backend: 50%, Frontend: 31%)

**Risk Mitigation Strategy:**

- Dual resource group architecture maintains data persistence during compute pause/resume
- Multi-provider AI fallback ensures service continuity
- Clean architecture enables modular testing and deployment
- Comprehensive validation scripts mirror CI/CD pipeline

### 10.3 Decision Log

**2025-07-24**: Initiated systematic production deployment with metadata tracking
**2025-07-24**: Identified current system state - local validation required before cloud deployment  
**2025-07-24**: **DECISION**: Deploy via CI/CD pipeline (GitHub Actions) instead of direct deployment for safety and traceability
**2025-07-24**: Updated deployment strategy to CI/CD-first approach with comprehensive pipeline validation
**2025-07-24**: ✅ **Phase 1 COMPLETED**: Local environment fully validated - Python 3.13.5 with all dependencies working, frontend npm packages secured

---

_Last updated: 2025-07-24_
