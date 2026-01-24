# Vigor – Repository Metadata

> **Single source of truth** for Vigor AI fitness platform. Concise, accurate, unambiguous.
> **Last Updated**: 2026-01-24 (Deployment Complete)

---

## 0. LIVE DEPLOYMENT

| Service          | URL                                                         |
| ---------------- | ----------------------------------------------------------- |
| **Frontend**     | https://vigor.vedprakash.net                                |
| **Backend API**  | https://vigor-functions.azurewebsites.net                   |
| **Health Check** | https://vigor-functions.azurewebsites.net/api/health-simple |

---

## 1. PROJECT OVERVIEW

**Vigor** is an AI-powered fitness coaching platform providing personalized workout generation, intelligent coaching conversations, and progress tracking.

| Attribute          | Value                                           |
| ------------------ | ----------------------------------------------- |
| **Domain**         | `vigor.vedprakash.net`                          |
| **AI Model**       | Azure OpenAI gpt-4o-mini (existing resource)    |
| **Authentication** | Microsoft Entra ID (default tenant, `common`)   |
| **Database**       | Azure Cosmos DB Serverless                      |
| **Backend**        | Azure Functions (Python 3.11, Flex Consumption) |
| **Frontend**       | React 19 + TypeScript + Chakra UI v3            |
| **Target Cost**    | ≤$50/month                                      |

---

## 2. CURRENT ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────┐
│                     vigor-rg (West US 2)                        │
├─────────────────────────────────────────────────────────────────┤
│  vigor.vedprakash.net ──► Azure Static Web App (React SPA)     │
│           │                                                     │
│           ▼                                                     │
│  vigor-functions ──────► Azure Functions (Python 3.11)         │
│           │                                                     │
│           ├──► Cosmos DB Serverless (vigor_db)                 │
│           │    └── users, workouts, workout_logs, ai_messages  │
│           │                                                     │
│           ├──► Azure OpenAI (aoai-vemishra-rag, gpt-4o-mini)   │
│           │                                                     │
│           └──► Key Vault (vigor-kv)                            │
│                                                                 │
│  Microsoft Entra ID (default tenant) ──► Authentication        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. KEY DECISIONS (Canonical)

| Decision           | Choice                             | Rationale                               |
| ------------------ | ---------------------------------- | --------------------------------------- |
| AI Model           | Azure OpenAI `gpt-4o-mini`         | Existing resource in rg-vemishra-rag    |
| Authentication     | Entra ID default tenant (`common`) | Any Microsoft account can use the app   |
| User Tier          | Free only (MVP)                    | Premium deferred to post-MVP            |
| Rate Limits        | 50/day (workouts), 50/day (chats)  | Generous for early adopters             |
| Rate Limit Storage | In-memory                          | Accept cold-start resets, no extra cost |
| Database           | Cosmos DB Serverless               | Pay-per-use, scales to zero             |
| Backend Tests      | Deferred                           | After successful initial user testing   |
| Frontend Domain    | `vigor.vedprakash.net`             | Production domain                       |

---

## 4. API ENDPOINTS

| Endpoint                      | Method      | Rate Limit       | Description                 |
| ----------------------------- | ----------- | ---------------- | --------------------------- |
| `/api/health`                 | GET         | None             | Full health check           |
| `/api/health-simple`          | GET         | None             | Simple liveness check       |
| `/api/auth/me`                | GET         | None             | Get current user from token |
| `/api/users/profile`          | GET, PUT    | 10/hour (update) | User profile management     |
| `/api/workouts/generate`      | POST        | **50/day**       | Generate AI workout         |
| `/api/workouts`               | GET         | None             | List user workouts          |
| `/api/workouts/{id}`          | GET, DELETE | None             | Get/delete specific workout |
| `/api/workouts/{id}/sessions` | POST        | None             | Log workout session         |
| `/api/workouts/history`       | GET         | None             | Get workout log history     |
| `/api/coach/chat`             | POST        | **50/day**       | AI coach chat               |
| `/api/coach/history`          | GET, DELETE | None             | Chat history management     |
| `/api/admin/ai/cost-metrics`  | GET         | Admin only       | Cost monitoring             |

---

## 5. FILE STRUCTURE (Key Paths)

```
vigor/
├── .archive/                   # Legacy/redundant files (not deployed)
├── docs/
│   ├── PRD-Vigor.md            # Product requirements (source of truth)
│   ├── Tech_Spec_Vigor.md      # Technical spec (source of truth)
│   ├── User_Experience.md      # UX spec (source of truth)
│   └── metadata.md             # This file (operational reference)
├── frontend/
│   ├── src/
│   │   ├── App.tsx             # Route definitions + ErrorBoundary
│   │   ├── components/
│   │   │   ├── ErrorBoundary.tsx # Global error handling
│   │   │   ├── Layout.tsx      # App shell
│   │   │   └── ...
│   │   ├── pages/              # Route-level pages
│   │   ├── contexts/           # VedAuthContext (MSAL)
│   │   ├── services/api.ts     # API client
│   │   └── config/authConfig.ts# MSAL configuration
│   └── package.json
├── functions-modernized/
│   ├── function_app.py         # Azure Functions entry point
│   ├── shared/
│   │   ├── auth.py             # JWT/Entra ID validation
│   │   ├── cosmos_db.py        # Database client
│   │   ├── openai_client.py    # AI client
│   │   ├── rate_limiter.py     # In-memory rate limiting
│   │   ├── models.py           # Pydantic models
│   │   └── config.py           # Settings
│   └── requirements.txt
└── infrastructure/bicep/
    ├── main-modernized.bicep   # Main infrastructure
    └── deploy-modernized.sh    # Deployment script
```

---

## 6. REMEDIATION PLAN

### Phase 0: Critical Fixes ✅ COMPLETE (2026-01-23)

| Task               | Status | Description                                                       |
| ------------------ | ------ | ----------------------------------------------------------------- |
| Fix cosmos_db.py   | ✅     | Fixed corrupted docstring, added `CosmosHttpResponseError` import |
| Fix Layout.tsx     | ✅     | Updated navigation paths to `/app/*` routes                       |
| Update rate limits | ✅     | Changed to 50/day for workouts and chats                          |

### Phase 1: Backend Stabilization (Current)

| Task                    | Priority | Status | Description                                     |
| ----------------------- | -------- | ------ | ----------------------------------------------- |
| Deploy Azure OpenAI     | P0       | ⏳     | Deploy vigor-openai with gpt-5-mini in vigor-rg |
| Update openai_client.py | P0       | ✅     | Switched to AsyncAzureOpenAI client             |
| Update config.py        | P0       | ✅     | Added AZURE*OPENAI*\* environment variables     |
| Update Bicep templates  | P0       | ✅     | Added Azure OpenAI resource to main-modernized  |
| Validate all endpoints  | P0       | ⏳     | Test with real requests                         |
| Configure CORS          | P0       | ✅     | Added `vigor.vedprakash.net` everywhere         |
| Add request validation  | P1       | ✅     | Pydantic models already have proper validation  |
| Add structured logging  | P1       | ✅     | Application Insights configured in host.json    |
| Archive redundant files | P1       | ✅     | Moved legacy scripts/docs to .archive/          |

### Phase 2: Frontend Polish

| Task                      | Priority | Status | Description                          |
| ------------------------- | -------- | ------ | ------------------------------------ |
| Connect to production API | P0       | ⏳     | Update VITE_API_URL after deployment |
| Add loading states        | P1       | ✅     | Spinners in Dashboard, Coach, etc.   |
| Add error boundaries      | P1       | ✅     | ErrorBoundary.tsx wrapping App       |
| Mobile responsiveness     | P1       | ✅     | Mobile drawer, responsive layouts    |
| Configure custom domain   | P0       | ⏳     | `vigor.vedprakash.net`               |

### Phase 3: Production Launch

| Task                      | Priority | Status | Description                   |
| ------------------------- | -------- | ------ | ----------------------------- |
| Set up Azure alerts       | P0       | ⏳     | Budget, error rate, latency   |
| Smoke test all paths      | P0       | ⏳     | Verify critical user journeys |
| Create deployment runbook | P1       | ⏳     | Document deployment process   |

### Deferred (Post-MVP)

| Task                | Reason                     |
| ------------------- | -------------------------- |
| Premium tier        | After successful MVP       |
| Backend unit tests  | After initial user testing |
| PWA offline mode    | After core features stable |
| Email notifications | After core features stable |
| Push notifications  | After core features stable |

---

## 7. ENVIRONMENT CONFIGURATION

### Required Environment Variables (Backend)

```bash
# Cosmos DB
COSMOS_DB_ENDPOINT=https://vigor-cosmos.documents.azure.com:443/
COSMOS_DB_KEY=<from-key-vault>
COSMOS_DB_DATABASE=vigor_db

# Azure OpenAI
AZURE_OPENAI_ENDPOINT=https://vigor-openai.openai.azure.com/
AZURE_OPENAI_API_KEY=<from-key-vault>
AZURE_OPENAI_DEPLOYMENT=gpt-5-mini

# Authentication
AZURE_TENANT_ID=common
AZURE_CLIENT_ID=<app-registration-client-id>

# Application
ENVIRONMENT=production
LOG_LEVEL=INFO
```

### Required Environment Variables (Frontend)

```bash
VITE_API_URL=https://vigor-functions.azurewebsites.net
VITE_AZURE_CLIENT_ID=<app-registration-client-id>
VITE_REDIRECT_URI=https://vigor.vedprakash.net
```

---

## 8. QUICK REFERENCE

### Local Development

```bash
# Backend
cd functions-modernized
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
func start

# Frontend
cd frontend
npm install
npm run dev
```

### Deployment

```bash
# Deploy infrastructure
cd infrastructure/bicep
./deploy-modernized.sh

# Deploy functions
cd functions-modernized
func azure functionapp publish vigor-functions

# Deploy frontend (via GitHub Actions or Azure CLI)
az staticwebapp deploy --app-name vigor-frontend
```

### Key Vault Secrets

| Secret Name                | Description          |
| -------------------------- | -------------------- |
| `azure-openai-api-key`     | Azure OpenAI API key |
| `cosmos-connection-string` | Cosmos DB connection |
| `secret-key`               | JWT signing key      |

---

## 9. DECISION LOG

| Date       | Decision                                     | Context                                |
| ---------- | -------------------------------------------- | -------------------------------------- |
| 2026-01-23 | Azure OpenAI in vigor-rg (not direct OpenAI) | All resources in same RG, managed auth |
| 2026-01-23 | Rate limits: 50/day (not 5/month or 20/hour) | Generous for early adopters            |
| 2026-01-23 | In-memory rate limiting (accept cold starts) | Cost savings, simplicity               |
| 2026-01-23 | Defer backend tests                          | Until after initial user testing       |
| 2026-01-23 | No Premium tier for MVP                      | Focus on core experience first         |
| 2026-01-23 | Frontend domain: vigor.vedprakash.net        | Production deployment target           |
| 2026-01-23 | Microsoft Entra ID default tenant            | Any Microsoft account can authenticate |

---

## 10. SPEC REFERENCES

All architectural decisions must align with these primary specs:

1. **[PRD-Vigor.md](PRD-Vigor.md)** - Product requirements, features, success metrics
2. **[Tech_Spec_Vigor.md](Tech_Spec_Vigor.md)** - Technical architecture, API contracts
3. **[User_Experience.md](User_Experience.md)** - UX flows, page specifications

> **Rule**: If conflicts exist between documents, PRD → Tech Spec → UX Spec → metadata.md (in priority order)

---

_This file is the operational reference. For detailed specifications, see the primary spec files above._
