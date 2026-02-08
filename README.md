# 👻 The Ghost - Invisible Fitness System

> **"The best fitness app is the one you never have to open."**
>
> An AI fitness system that operates through your calendar, not an app interface. Apple Watch required.

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)
[![Swift 5.9](https://img.shields.io/badge/swift-5.9-orange.svg)](https://swift.org/)
[![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)](https://developer.apple.com/ios/)
[![watchOS 10+](https://img.shields.io/badge/watchOS-10+-green.svg)](https://developer.apple.com/watchos/)
[![Azure Functions](https://img.shields.io/badge/Azure%20Functions-Serverless-green.svg)](https://azure.microsoft.com/en-us/services/functions/)

---

## 🎯 The Vision

**The Ghost** is an invisible fitness coach that lives in your calendar. Unlike traditional fitness apps that require constant engagement, The Ghost:

- **Places workouts directly in your calendar** as time blocks
- **Operates through silent notifications** (max 1/day)
- **Learns your patterns** to predict when you'll skip
- **Transforms your schedule** to prevent missed workouts
- **Requires Apple Watch** for automatic workout detection

### Core Philosophy

> "Weekly structure, not daily nagging."

The system earns trust progressively, graduating from suggestions to autonomous scheduling as you demonstrate consistency.

---

## 🌐 Status

| Platform          | Status        | Purpose                                    |
| ----------------- | ------------- | ------------------------------------------ |
| **iOS App**       | ✅ Production | Primary Ghost interface (calendar-centric) |
| **watchOS**       | ✅ Production | Workout tracking & complications           |
| **Backend**       | ✅ Production | Ghost API, Silent Push, AI                 |
| **Web Dashboard** | ✅ Production | Admin dashboard & Ghost operations         |

---

## 🔐 Admin Dashboard

The web dashboard provides administrative control over Ghost operations:

### Features

| Feature             | Description                                         |
| ------------------- | --------------------------------------------------- |
| **Ghost Health**    | Monitor AI model, Phenome stores, component health  |
| **User Management** | View users with Trust phase, score, Watch status    |
| **AI Pipeline**     | Configure gpt-5-mini Structured Outputs settings    |
| **Decision Audit**  | Review Decision Receipts with alternatives/outcomes |
| **Safety Breakers** | Monitor and manage trust downgrades                 |
| **Analytics**       | Ghost operations metrics and Trust distribution     |

### Access Control

Admin access is controlled via email whitelist:

- **Frontend**: `frontend/src/config/adminConfig.ts`
- **Backend**: `functions-modernized/shared/auth.py`

### Ghost-Specific Admin API Endpoints

| Method  | Endpoint                              | Description                   |
| ------- | ------------------------------------- | ----------------------------- |
| GET     | `/api/admin/ghost/health`             | Ghost system health metrics   |
| GET     | `/api/admin/ghost/trust-distribution` | User Trust phase distribution |
| GET     | `/api/admin/ghost/users`              | Users with Ghost fields       |
| GET     | `/api/admin/ghost/decision-receipts`  | Decision receipts for audit   |
| GET     | `/api/admin/ghost/safety-breakers`    | Safety breaker events         |
| GET     | `/api/admin/ghost/analytics`          | Ghost analytics for period    |
| GET     | `/api/admin/ai/cost-metrics`          | AI cost & budget metrics      |
| GET/PUT | `/api/admin/ai-pipeline-config`       | AI pipeline configuration     |

---

## ✨ Key Features

### 🗓️ Calendar-Centric UX

- Training blocks appear as real calendar events
- Read ALL calendars, write to local "Vigor Training" calendar only
- Shadow sync to work calendar ("Busy" blocks via MS Graph)

### 🤖 Ghost Intelligence

- **Skip Predictor**: Anticipates when you'll bail (6 weighted factors)
- **Recovery Analyzer**: HRV + sleep + strain composite scoring
- **Optimal Window Finder**: Best workout times from patterns
- **Pattern Detector**: Learns your behavioral rhythms

### 🔒 Trust State Machine

5-phase progression with capabilities unlocking at each level:

| Phase          | Capability                  | Confidence |
| -------------- | --------------------------- | ---------- |
| Observer       | Suggestions only            | 0-25%      |
| Scheduler      | Create blocks with approval | 25-50%     |
| Auto-Scheduler | Create blocks autonomously  | 50-70%     |
| Transformer    | Move/reschedule blocks      | 70-85%     |
| Full Ghost     | Transform week structure    | 85-100%    |

**Safety Breaker**: 3 consecutive block deletes → immediate downgrade

### ⌚ Apple Watch Integration

- Mandatory hardware (not optional accessory)
- Automatic workout detection with HKWorkoutSession
- Complications for at-a-glance status
- Watch = Authority for workouts, Phone = Authority for scheduling

### 📊 Phenome Architecture

3-store edge-first data model:

- **RawSignalStore**: HealthKit data (sleep, HRV, workouts)
- **DerivedStateStore**: Computed metrics with versioning
- **BehavioralMemoryStore**: Preferences, patterns, sacred times

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         THE GHOST                            │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   iPhone    │  │ Apple Watch │  │   Azure Backend     │  │
│  │  SwiftUI    │◄─┤  watchOS    │  │  Functions + Cosmos │  │
│  │  iOS 17+    │  │  10+        │  │  Silent Push (P0)   │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
│         │                │                     │             │
│         ▼                ▼                     ▼             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              Phenome (Core Data + CloudKit)             ││
│  │  RawSignalStore │ DerivedStateStore │ BehavioralMemory  ││
│  └─────────────────────────────────────────────────────────┘│
│         │                                                    │
│         ▼                                                    │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              Calendar Integration (EventKit)            ││
│  │    Read ALL calendars │ Write "Vigor Training" only     ││
│  │              Shadow Sync via MS Graph API               ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Tech Stack

| Layer        | Technology                                            |
| ------------ | ----------------------------------------------------- |
| **iOS App**  | Swift 5.9, SwiftUI, iOS 17+                           |
| **watchOS**  | SwiftUI, HealthKit, watchOS 10+                       |
| **Health**   | HealthKit (sleep, HRV, workouts, steps)               |
| **Calendar** | EventKit + MS Graph API                               |
| **Storage**  | Core Data + CloudKit                                  |
| **Auth**     | Microsoft Entra ID (MSAL)                             |
| **Backend**  | Azure Functions v2 (Python 3.11, Blueprints)          |
| **Database** | Azure Cosmos DB Serverless (10 containers)            |
| **AI**       | Azure OpenAI gpt-5-mini (Structured Outputs)          |
| **Push**     | APNs Silent Push (P0 for Ghost survival)              |
| **Frontend** | React 19, TypeScript 5.8 (strict), Vite, Chakra UI v3 |
| **IaC**      | Bicep                                                 |

---

## 🏗️ Architecture

### Single Resource Group (vigor-rg, West US 2)

```
vigor-rg (West US 2)
├── vigor-functions          # Azure Functions (Flex Consumption)
├── vigor-frontend           # Static Web App
├── vigor-cosmos             # Cosmos DB Serverless
├── (external)               # Azure OpenAI (gpt-5-mini via AI Foundry)
├── vigor-kv                 # Key Vault (secrets)
├── vigor-insights           # Application Insights
├── vigor-logs               # Log Analytics
└── vigorsa                  # Storage Account
```

### Database Schema (Cosmos DB)

| Container           | Partition Key | Purpose                             | TTL    |
| ------------------- | ------------- | ----------------------------------- | ------ |
| `users`             | `/userId`     | User profiles and preferences       | —      |
| `workouts`          | `/userId`     | AI-generated workout plans          | —      |
| `workout_logs`      | `/userId`     | Exercise completion tracking        | —      |
| `ai_coach_messages` | `/userId`     | Chat history                        | 30 day |
| `ghost_actions`     | `/userId`     | Ghost autonomous actions log        | —      |
| `trust_states`      | `/userId`     | Trust phase transitions & scores    | —      |
| `training_blocks`   | `/userId`     | Calendar training block definitions | —      |
| `phenome`           | `/userId`     | Phenome store sync (3-store model)  | —      |
| `decision_receipts` | `/userId`     | Decision Receipts for audit         | 90 day |
| `push_queue`        | `/userId`     | Silent push delivery queue          | 7 day  |

---

## 📁 Project Structure

```
vigor/
├── ios/                         # Native iOS/watchOS apps
│   ├── Vigor/                   # iPhone app
│   │   ├── App/                 # Entry point, AppDelegate
│   │   ├── Core/                # Ghost Engine, Trust, Phenome, ML
│   │   │   ├── GhostEngine/     # Central orchestration
│   │   │   ├── Trust/           # 5-phase state machine
│   │   │   ├── Phenome/         # 3-store data architecture
│   │   │   ├── ML/              # Skip prediction, recovery analysis
│   │   │   └── Auth/            # MSAL integration
│   │   ├── Data/                # HealthKit, Calendar, API clients
│   │   ├── UI/                  # SwiftUI views
│   │   ├── Background/          # BGTaskScheduler, Silent Push
│   │   └── Notifications/       # Notification orchestration
│   │
│   ├── VigorWatch/              # Apple Watch app
│   │   ├── App/                 # Watch entry point
│   │   ├── Views/               # Today, Active Workout views
│   │   ├── Workout/             # HKWorkoutSession manager
│   │   ├── Sync/                # Phone sync via WCSession
│   │   └── Complications/       # Watch face complications
│   │
│   ├── Shared/                  # Shared code
│   │   ├── Models/              # Common data models
│   │   ├── WatchConnectivity/   # WCSession wrapper
│   │   └── Sync/                # Authority conflict resolution
│   │
│   └── VigorTests/              # Test suites
│       └── Trust/               # Trust state machine tests
│
├── functions-modernized/        # Azure Functions Python backend
│   ├── function_app.py          # Entry point (~60 lines, 8 blueprint registrations)
│   ├── blueprints/              # Route modules (8 blueprints)
│   │   ├── auth_bp.py           # Authentication & user profile
│   │   ├── workouts_bp.py       # Workout CRUD, training blocks & session logging
│   │   ├── coach_bp.py          # AI coach chat, recommendations & recovery
│   │   ├── ghost_bp.py          # Ghost Engine APIs + timer triggers
│   │   ├── admin_bp.py          # Admin dashboard & AI pipeline config
│   │   ├── health_bp.py         # Health check endpoints
│   │   ├── trust_bp.py          # Trust event recording & history
│   │   └── devices_bp.py        # Device registration & push tokens
│   ├── shared/                  # Auth, Cosmos, OpenAI, helpers
│   └── tests/                   # pytest suite (107 tests)
│
├── frontend/                    # Web dashboard (React/TypeScript, strict mode)
│   ├── src/                     # Admin dashboard & Ghost operations
│   │   ├── components/          # Ghost health, audit, LLM config, user mgmt
│   │   ├── pages/               # Lazy-loaded via React.lazy() code-splitting
│   │   ├── services/            # Admin API client (dev-only mock fallbacks)
│   │   └── config/              # Admin config, tier pricing
│   └── ...                      # Vite, Chakra UI v3, MSAL
│
├── infrastructure/bicep/        # Azure Bicep IaC
│
├── docs/                        # PRD, Tech Spec, UX Spec
│
└── .archive/                    # Archived legacy user-facing pages
    └── frontend-web-app/        # Original user pages (replaced by iOS)
```

---

## 🚀 Quick Start

### Prerequisites

- Xcode 15.2+ with iOS 17 SDK
- Apple Developer Account (for HealthKit, Push)
- Azure Functions Core Tools v4
- Python 3.11+

### iOS Development

```bash
# Open Xcode project
cd ios
open Vigor.xcodeproj

# Build and run on device (Simulator won't have HealthKit)
# Requires physical iPhone + Apple Watch for full testing
```

### Backend Development

```bash
cd functions-modernized
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Configure local settings
cp local.settings.json.example local.settings.json
# Edit with your Azure OpenAI credentials

func start  # http://localhost:7071
```

### Web Dashboard Development

```bash
cd frontend
npm install
echo "VITE_API_URL=http://localhost:7071" > .env.local
npm run dev  # http://localhost:5173
```

---

## 🔌 API Endpoints

### Core APIs

| Method  | Endpoint                  | Description                    |
| ------- | ------------------------- | ------------------------------ |
| GET     | `/api/auth/me`            | Get current user profile       |
| GET/PUT | `/api/user/profile`       | Get or update user profile     |
| POST    | `/api/workouts/generate`  | Generate AI workout plan       |
| POST    | `/api/workouts`           | Record completed workout       |
| GET     | `/api/workouts`           | List user's workouts           |
| GET     | `/api/workouts/{id}`      | Get single workout             |
| GET     | `/api/workouts/history`   | Get workout logs history       |
| POST    | `/api/blocks/sync`        | Sync training blocks           |
| POST    | `/api/blocks/outcome`     | Record training block outcome  |
| POST    | `/api/coach/chat`         | Chat with AI coach             |
| GET     | `/api/coach/history`      | Get coach conversation history |
| POST    | `/api/coach/recommend`    | Get AI workout recommendation  |
| GET     | `/api/coach/recovery`     | Get recovery assessment        |
| POST    | `/api/trust/event`        | Record trust event             |
| GET     | `/api/trust/history`      | Get trust score history        |
| POST    | `/api/devices/register`   | Register device                |
| POST    | `/api/devices/push-token` | Register APNs push token       |
| GET     | `/api/health`             | Health check                   |

### Ghost APIs

| Method | Endpoint                      | Description               |
| ------ | ----------------------------- | ------------------------- |
| POST   | `/api/ghost/silent-push`      | Silent push trigger (P0)  |
| GET    | `/api/ghost/trust`            | Get user trust state      |
| POST   | `/api/ghost/sync`             | Ghost state sync (iOS)    |
| POST   | `/api/ghost/schedule`         | Sync training schedule    |
| POST   | `/api/ghost/phenome/sync`     | Sync Phenome stores       |
| POST   | `/api/ghost/decision-receipt` | Record a Decision Receipt |

---

## 🧪 Testing

```bash
# Backend tests (107 tests — endpoints, auth, trust, helpers)
cd functions-modernized
source .venv/bin/activate
pytest tests/ -v

# Frontend type-check (strict mode)
cd frontend
npx tsc --noEmit

# Frontend build
npm run build

# iOS tests (run from Xcode)
# Cmd+U to run test suite

# Trust state machine tests
# ios/VigorTests/Trust/
```

---

## ☁️ Deployment

### Infrastructure (Bicep)

```bash
cd infrastructure/bicep
az login
az group create --name vigor-rg --location "West US 2"
./deploy-modernized.sh
```

### Deploy Functions

```bash
cd functions-modernized
func azure functionapp publish vigor-functions --python
```

### iOS App Store

```bash
# Archive from Xcode
# Product → Archive → Distribute App → App Store Connect
```

---

## 💰 Pricing & Cost Estimates

### Subscription Tiers

| Tier        | Price     | Features                                    |
| ----------- | --------- | ------------------------------------------- |
| **Free**    | $0/month  | Observer phase only, 30-day Phenome storage |
| **Premium** | $49/month | Full Ghost (5 phases), Apple Watch required |
| **Premium** | $499/year | Annual (~15% savings)                       |

### Infrastructure Costs

| Resource        | Tier              | Monthly Cost     |
| --------------- | ----------------- | ---------------- |
| Azure Functions | Flex Consumption  | $5-15            |
| Cosmos DB       | Serverless        | $5-20            |
| Azure OpenAI    | Pay-per-token     | $5-15            |
| APNs            | Free              | $0               |
| Apple Developer | Annual ($99/year) | ~$8              |
| **Total**       |                   | **$23-58/month** |

_Target: ≤$50/month for early adopter usage_

---

## 🔐 Authentication

- **Provider**: Microsoft Entra ID (default tenant `common`)
- **Flow**: MSAL iOS SDK with token caching
- **Scopes**: Calendar.ReadWrite, User.Read (for Shadow Sync)

---

## 📄 License

GNU Affero General Public License v3.0 - see [LICENSE](LICENSE).

---

**👻 The Ghost: The fitness app you never have to open.**
