# Vigor - Technical Specification Document

**Version**: 2.6 (Scale Resilience)
**Date**: January 26, 2026
**Status**: Production Ready
**Document Owner**: Engineering Team
**Aligned with**: PRD-Vigor.md v5.0, User_Experience.md v1.0

---

## Changelog

### v2.6 (January 26, 2026) - Scale Resilience

Hardens Ghost for 500k+ users, 3 OS releases, enterprise MDMs, and 4 years of silent usage. Addresses systemic risks that would cause "fragile-brilliant" failures at scale: Phenome collapse, trust poisoning, device authority conflicts, generative variability, and invisible debugging.

| Issue                          | Risk                                                | Solution                                                                       |
| ------------------------------ | --------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Phenome Monolith**           | Schema migrations become existential events         | Decompose into 3 stores: RawSignal, DerivedState, BehavioralMemory (§2.4)      |
| **Trust Score Brittleness**    | Ambiguous signals slowly poison trust model         | Trust Attribution Layer: weight by confidence × ambiguity (§2.3)               |
| **Device Authority Conflicts** | Watch + Phone disagree → double-logging, stale data | Single-Writer Principle: Watch = workouts, Phone = planning/trust (§4.4.1)     |
| **Generative Safety Gaps**     | RAG/LLM can produce unsafe workouts at scale        | Workout Contracts: deterministic post-generation validator (§3.4)              |
| **Silent System Failures**     | Ghost keeps trying when things break → app deleted  | Global Ghost Health Monitor: auto-degrade, pause mutations (§2.4)              |
| **Invisible Debugging**        | Can't explain why Ghost made a decision             | Decision Receipt System: inputs, alternatives, confidence, trust impact (§2.4) |

### v2.5 (January 26, 2026) - Corporate Resilience

Hardens Ghost for the "Corporate Wild"—environments where MDM blocks shadow sync, assistants modify calendars, users charge watches overnight, and background processes compete for survival. Addresses edge cases that would erode trust in enterprise deployments.

| Issue                         | Risk                                            | Solution                                                                |
| ----------------------------- | ----------------------------------------------- | ----------------------------------------------------------------------- |
| **Calendar Collision**        | Corporate MDM blocks Exchange shadow sync       | Calendar Multiplexing: read many, write to Vigor calendar only (§2.6)   |
| **Delegate Confusion**        | Can't distinguish assistant cleanup from reject | Graph API `lastModifiedBy` detection for delegate actions (§2.6)        |
| **Morning Lag Race**          | Watch-first fails for "bathroom charger" users  | Hybrid Orchestration: iPhone Silent Push primary, Watch fallback (§4.5) |
| **Stale Watch Phenome**       | Watch computes with old data if sync failed     | 6-hour staleness check, Safe Mode fallback (§4.5)                       |
| **Insight Storage Bloat**     | Layer 3 insights accumulate without limit       | TTL-based Insight Lifecycle: type-specific expiration (§2.10)           |
| **Implicit Feedback Noise**   | Missed workout could mean "bad time" or "flu"   | One-Tap Triage: "Schedule issue or just life?" (§2.13)                  |
| **Trust Erosion Spiral**      | Auto-delete loop damages user relationship      | Safety Breaker: 3 consecutive deletes → immediate downgrade (§2.4)      |
| **Third-Party Battery Drain** | Strava mid-workout writes wake Ghost repeatedly | HKObserverQuery debouncing: 60s minimum, only ended workouts (§2.5)     |
| **Generic Templates**         | Static workouts feel repetitive by week 3       | Dynamic Skeletons: structure fixed, exercises vary from RAG (§3.4)      |

### v2.4 (January 26, 2026) - Health Platform Foundation

Elevates Vigor from "fitness app with features" to "health intelligence platform that compounds longitudinal signal over years." Addresses structural gaps that would require costly retrofits later.

| Issue                         | Risk                                           | Solution                                                               |
| ----------------------------- | ---------------------------------------------- | ---------------------------------------------------------------------- |
| **Flat Data Model**           | "Latest value" kills trend/volatility analysis | Three-Layer Data Model: Raw → Derived → Insight (§2.10)                |
| **Metric Recomputation Hell** | Formula changes require backfill nightmares    | Versioned Metrics with provenance and dependency graph (§2.11)         |
| **Generic Personalization**   | "AI coach" becomes noise after week 3          | User Health Profile State Machine: Baseline → Adapt → Maintain (§2.12) |
| **One-Way Recommendations**   | Models don't improve, trust doesn't increase   | Bidirectional Feedback Loops with micro-feedback (§2.13)               |
| **Explainability Gap**        | Users don't trust scores they can't understand | Every insight stores explanation chain (§2.10, §2.11)                  |
| **Runaway Compute Costs**     | Naive recomputation on high-volume health data | Three-tier computation: real-time, hourly, overnight-only (§2.11)      |

### v2.3 (January 26, 2026) - Platform Survival Hardening

Addresses the **Invisibility Paradox**: By succeeding at the product goal (user rarely opens app), we risk technical failure (OS terminates background tasks). These changes ensure Ghost survives iOS resource management.

| Issue                    | Risk                                          | Solution                                                 |
| ------------------------ | --------------------------------------------- | -------------------------------------------------------- |
| **Invisibility Paradox** | iOS throttles BGTaskScheduler for unused apps | Silent Push + Complication-Driven Wakes (§2.9)           |
| **Corporate MDM Block**  | Enterprise blocks Graph API calendar access   | Graceful degradation to local Overlay Calendar (§2.6)    |
| **Morning Lag**          | HealthKit batching delays 6 AM decisions      | Watch-Driven Morning Orchestration on wrist-raise (§4.5) |
| **Chaos Mode Latency**   | LLM for rescheduling adds 4s+ spinner         | Deterministic Slot-Finding Algorithm (§2.6)              |
| **Day 1 Import Kill**    | OS kills long-running background import       | Chunked import with savepoint/resume (§2.5)              |
| **Trust State Demotion** | Multi-device sync causes phase regression     | Highest-Trust-Wins CloudKit merge policy (§2.4)          |

### v2.2 (January 26, 2026) - Architectural Resilience

Based on comprehensive architectural review, the following resilience enhancements were implemented:

| Issue                           | Risk                                             | Solution                                             |
| ------------------------------- | ------------------------------------------------ | ---------------------------------------------------- |
| **Calendar Invisibility**       | Local-only blocks don't protect from colleagues  | Shadow Sync to Exchange/Outlook via MS Graph (§2.6)  |
| **Hard-Coded Heuristics**       | Can't iterate Ghost behavior without App Store   | Remote config from Azure Blob Storage (§2.8)         |
| **Watch Connectivity Fragile**  | WatchConnectivity unreliable for background sync | Watch autonomous with direct backend sync (§4.4)     |
| **Day 1 UI Hang Risk**          | Large HealthKit histories block onboarding       | Progressive import: 7-day instant + 90-day bg (§2.5) |
| **Trust State Loss on Restore** | Device restore resets Ghost to Observer          | CloudKit schema isolates Trust State (§2.4)          |

### v2.1 (January 26, 2026) - Defensive Architecture Hardening

Based on architectural review, the following defensive measures were implemented:

| Issue                       | Risk                                      | Solution                                     |
| --------------------------- | ----------------------------------------- | -------------------------------------------- |
| **Calendar Spam**           | Vigor blocks sync to corporate Exchange   | Local-only calendar source (§2.6)            |
| **Day 1 CPU Throttle**      | 90-day import triggers iOS watchdog kill  | Hierarchical analysis with aggregates (§2.5) |
| **Cold Start Latency**      | 8-12s spinner breaks concierge illusion   | Hybrid engine + streaming (§3.2-3.3)         |
| **RAG Over-Engineering**    | LLM call for every workout is slow/costly | Template engine for 90% of requests (§3.4)   |
| **Battery Drain**           | Background tasks drain battery            | Explicit battery budget (§8)                 |
| **All-Day Event Confusion** | "Mom's Birthday" blocks entire day        | Smart calendar filtering (§2.6)              |

### v2.0 (January 26, 2026) - Initial Progressive Edge-Cloud Architecture

- Native iOS/watchOS implementation (SwiftUI, HealthKit, EventKit)
- On-device Ghost Engine with Trust State Machine
- Azure backend with RAG-grounded workout generation
- Privacy-first Phenome storage with CloudKit E2E encryption

---

## Executive Summary

This Technical Specification implements the **Progressive Edge-Cloud Architecture** for Vigor—an invisible fitness system ("The Ghost") that operates in the background, making fitness inevitable through ambient intelligence and zero-input automation.

### Core Architectural Philosophy

> **"The best interface is no interface."**

Vigor is not a fitness app users interact with—it's infrastructure that works while users ignore it. This architecture prioritizes:

1. **On-Device Intelligence**: Personal patterns (Phenome) live locally using Apple's ML frameworks
2. **Silent Calendar Integration**: EventKit-native scheduling without user intervention
3. **Server-Augmented AI**: Azure OpenAI for high-quality workout generation with RAG grounding
4. **Trust-Based Autonomy**: Progressive permission escalation through the Trust Accrual Ladder

### Defensive Architecture Principles

> **"Build for chaos, not the happy path."**

This spec is hardened against real-world edge cases:

| Risk Vector                    | Defensive Measure                                                                |
| ------------------------------ | -------------------------------------------------------------------------------- |
| **Invisibility Paradox**       | Silent Push + Complication Wakes bypass iOS engagement throttling (§2.9)         |
| **Calendar Collision**         | Calendar Multiplexing: read many, write to dedicated Vigor calendar (§2.6)       |
| **Corporate MDM Block**        | Graceful degradation to local Overlay Calendar when Graph blocked (§2.6)         |
| **Delegate Confusion**         | Graph API `lastModifiedBy` distinguishes assistant actions from user (§2.6)      |
| **Morning Lag Race**           | Hybrid Orchestration: iPhone Silent Push primary, Watch fallback (§4.5)          |
| **Stale Watch Phenome**        | 6-hour staleness threshold triggers Safe Mode fallback (§4.5)                    |
| **Day 1 CPU Throttle**         | Chunked import with savepoint/resume survives OS task kills (§2.5)               |
| **Cold Start Latency**         | Hybrid engine: dynamic skeletons + streaming LLM for edge cases (§3.4)           |
| **Chaos Mode Latency**         | Deterministic slot-finder for rescheduling; LLM only for semantic changes        |
| **Battery Drain**              | Explicit battery budget with overnight-only deep processing (§8)                 |
| **Third-Party Battery Drain**  | HKObserverQuery debouncing: 60s minimum, only process ended workouts (§2.5)      |
| **Hard-Coded Heuristics Trap** | Remote config for Ghost logic enables iteration without App Store (§2.8)         |
| **Watch Connectivity Fragile** | Watch autonomous with direct backend sync + offline queue (§4.4)                 |
| **Trust State Demotion**       | Highest-Trust-Wins CloudKit merge policy prevents multi-device regression (§2.4) |
| **Trust Erosion Spiral**       | Safety Breaker: 3 consecutive auto-deletes → immediate downgrade (§2.4)          |
| **Implicit Feedback Noise**    | One-Tap Triage disambiguates "bad time slot" vs "life happened" (§2.13)          |
| **Insight Storage Bloat**      | TTL-based Insight Lifecycle with type-specific expiration policies (§2.10)       |
| **Generic Templates**          | Dynamic Skeletons: structure fixed, exercises vary from RAG pool (§3.4)          |
| **Phenome Monolith**           | Decomposed into 3 stores: RawSignal, DerivedState, BehavioralMemory (§2.4)       |
| **Trust Score Brittleness**    | Trust Attribution Layer weights updates by confidence × ambiguity (§2.3)         |
| **Device Authority Conflicts** | Single-Writer Principle: Watch = workouts, Phone = planning/trust (§4.4.1)       |
| **Generative Safety Gaps**     | Workout Contracts: deterministic post-generation validator (§3.4)                |
| **Silent System Failures**     | Global Ghost Health Monitor: auto-degrade, pause mutations, notify (§2.4)        |
| **Invisible Debugging**        | Decision Receipts: inputs, alternatives, confidence, trust impact (§2.4)         |

### Platform Architecture Principles

> **"Build a system that compounds, not an app with features."**

These foundations enable Vigor to still feel smart in 3+ years:

| Principle                      | Implementation                                                                   |
| ------------------------------ | -------------------------------------------------------------------------------- |
| **Data Immutability**          | Raw signals append-only; derived metrics versioned and recomputable (§2.10)      |
| **Metric Provenance**          | Every score stores inputs, version, time window, explanation (§2.10, §2.11)      |
| **Explainability by Contract** | Insights carry derivation chain even before UI displays it (§2.10)               |
| **Personalization as State**   | User Health Profile State Machine: Baseline → Adapt → Maintain → Regress (§2.12) |
| **Bidirectional Learning**     | Micro-feedback (implicit + 1-tap) feeds back into recommendation weights (§2.13) |
| **Computation Tiering**        | Real-time / hourly / overnight-only gates control cost and battery (§2.11)       |

### Key Architectural Decisions

| Decision                          | Rationale                                                                 |
| --------------------------------- | ------------------------------------------------------------------------- |
| **Native iOS/watchOS Required**   | Apple Watch mandatory for sensor fidelity (PRD §2.5)                      |
| **On-Device Phenome**             | Privacy-first pattern storage using Core Data + CloudKit encryption       |
| **Edge-First ML**                 | Core ML for instant pattern detection, skip prediction, recovery analysis |
| **Azure OpenAI (gpt-5-mini)**     | RAG-grounded workout generation for accuracy and quality                  |
| **Existing Azure Infrastructure** | Reuse vigor-rg resources (Functions, Cosmos DB, OpenAI, Storage)          |
| **Minimal Server Dependency**     | Ghost operates offline; server enhances, doesn't gate                     |

### Deployed Infrastructure (vigor-rg)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        vigor-rg (West US 2)                         │
├─────────────────────────────────────────────────────────────────────┤
│  vigor-cosmos-prod      │ Azure Cosmos DB      │ Phenome backup     │
│  vigor-frontend         │ Static Web App       │ Admin dashboard    │
│  vigor-functions        │ Function App         │ Ghost API          │
│  vigor-functions-plan   │ App Service Plan     │ Serverless compute │
│  vigor-insights         │ Application Insights │ Telemetry          │
│  vigor-kv-*             │ Key Vault            │ Secrets            │
│  vigor-logs             │ Log Analytics        │ Monitoring         │
│  vigor-openai           │ Foundry              │ AI Services        │
│  vigor-foundry          │ Foundry Project      │ RAG + Fine-tuning  │
│  vigorstorage*          │ Storage Account      │ Blobs + Queues     │
└─────────────────────────────────────────────────────────────────────┘
              Estimated Cost: ~$30-50/month (serverless scaling)
```

---

## 1. System Architecture Overview

### 1.1 Progressive Edge-Cloud Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           USER DEVICES (Edge)                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                        Apple Watch (Required)                       │    │
│  │  ┌──────────────────────────────────────────────────────────────┐  │    │
│  │  │  Workout Detection Engine                                     │  │    │
│  │  │  • HealthKit Workout Sessions (auto-detect)                   │  │    │
│  │  │  • Heart Rate + Motion Classifier (Core ML)                   │  │    │
│  │  │  • Complication: Next workout, streak, recovery status        │  │    │
│  │  │  • Background HRV/Sleep sampling                              │  │    │
│  │  └──────────────────────────────────────────────────────────────┘  │    │
│  │                              │ WatchConnectivity                    │    │
│  └──────────────────────────────┼─────────────────────────────────────┘    │
│                                 ▼                                           │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                         iPhone App (SwiftUI)                        │    │
│  │                                                                     │    │
│  │  ┌──────────────────────────────────────────────────────────────┐  │    │
│  │  │                    Ghost Engine (On-Device)                   │  │    │
│  │  │                                                               │  │    │
│  │  │  ┌─────────────────────────────────────────────────────────┐ │  │    │
│  │  │  │ DATA LAYER                                               │ │  │    │
│  │  │  │ • HealthKitObserver (sleep, HRV, steps, workouts)        │ │  │    │
│  │  │  │ • EventKitManager (calendar read/write)                  │ │  │    │
│  │  │  │ • PhenomeStore (Core Data + CloudKit sync)               │ │  │    │
│  │  │  │ • LocationManager (gym proximity, travel - optional)     │ │  │    │
│  │  │  └─────────────────────────────────────────────────────────┘ │  │    │
│  │  │                                                               │  │    │
│  │  │  ┌─────────────────────────────────────────────────────────┐ │  │    │
│  │  │  │ INTELLIGENCE LAYER (Core ML + Apple Intelligence)        │ │  │    │
│  │  │  │ • PatternDetector (sleep impact, recovery needs)         │ │  │    │
│  │  │  │ • SkipPredictor (meeting density + sleep → skip risk)    │ │  │    │
│  │  │  │ • RecoveryAnalyzer (HRV trends, strain accumulation)     │ │  │    │
│  │  │  │ • OptimalWindowFinder (best workout times)               │ │  │    │
│  │  │  │ • TrustStateMachine (5-phase progression)                │ │  │    │
│  │  │  │ • SacredTimeDetector (protected slots)                   │ │  │    │
│  │  │  └─────────────────────────────────────────────────────────┘ │  │    │
│  │  │                                                               │  │    │
│  │  │  ┌─────────────────────────────────────────────────────────┐ │  │    │
│  │  │  │ ACTION LAYER                                             │ │  │    │
│  │  │  │ • CalendarScheduler (silent block creation)              │ │  │    │
│  │  │  │ • NotificationOrchestrator (max 1/day, binary only)      │ │  │    │
│  │  │  │ • WorkoutLogger (passive acceptance model)               │ │  │    │
│  │  │  │ • BlockTransformer (Heavy → Recovery based on HRV)       │ │  │    │
│  │  │  │ • ValueReceiptGenerator (Sunday summary)                 │ │  │    │
│  │  │  └─────────────────────────────────────────────────────────┘ │  │    │
│  │  └──────────────────────────────────────────────────────────────┘  │    │
│  │                                 │                                   │    │
│  │  ┌──────────────────────────────┼──────────────────────────────┐   │    │
│  │  │              Cloud Sync Layer (Minimal)                      │   │    │
│  │  │  • CloudKit: E2E encrypted Phenome backup                    │   │    │
│  │  │  • API Client: Workout generation, model updates             │   │    │
│  │  │  • Background Fetch: Core ML model distribution              │   │    │
│  │  └──────────────────────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────┼───────────────────────────────────┘    │
└────────────────────────────────────┼────────────────────────────────────────┘
                                     │
            ┌────────────────────────┴────────────────────────┐
            │                                                  │
            ▼ E2E Encrypted                                    ▼ API Calls
┌───────────────────────────┐              ┌──────────────────────────────────┐
│       Apple CloudKit      │              │      Azure Backend (vigor-rg)    │
│  • Private Database       │              │                                  │
│  • Phenome Sync           │              │  ┌────────────────────────────┐ │
│  • Cross-device restore   │              │  │ Azure Functions (Python)   │ │
│  • Apple-managed keys     │              │  │ ┌────────────────────────┐ │ │
│  • Zero server knowledge  │              │  │ │ /api/workouts/generate │ │ │
│                           │              │  │ │ RAG-grounded generation│ │ │
└───────────────────────────┘              │  │ └────────────────────────┘ │ │
                                           │  │ ┌────────────────────────┐ │ │
                                           │  │ │ /api/ghost/sync        │ │ │
                                           │  │ │ Anonymized patterns    │ │ │
                                           │  │ └────────────────────────┘ │ │
                                           │  │ ┌────────────────────────┐ │ │
                                           │  │ │ /api/models/update     │ │ │
                                           │  │ │ Core ML distribution   │ │ │
                                           │  │ └────────────────────────┘ │ │
                                           │  └────────────────────────────┘ │
                                           │                                  │
                                           │  ┌────────────────────────────┐ │
                                           │  │ Azure OpenAI (gpt-5-mini)  │ │
                                           │  │ + RAG Knowledge Base       │ │
                                           │  │ + Exercise Database        │ │
                                           │  │ + Workout Templates        │ │
                                           │  └────────────────────────────┘ │
                                           │                                  │
                                           │  ┌────────────────────────────┐ │
                                           │  │ Cosmos DB                  │ │
                                           │  │ • User profiles            │ │
                                           │  │ • Workout library          │ │
                                           │  │ • Exercise knowledge base  │ │
                                           │  │ • Anonymized aggregates    │ │
                                           │  └────────────────────────────┘ │
                                           └──────────────────────────────────┘
```

### 1.2 Design Principles

| Principle                        | Implementation                                             |
| -------------------------------- | ---------------------------------------------------------- |
| **Never ask what can be sensed** | HealthKit imports sleep, HRV, workouts automatically       |
| **Magic in 5 minutes**           | Day 1: Import 90 days history, instant pattern detection   |
| **One decision, not ten**        | Binary notifications only; calendar blocks appear silently |
| **Phenome lives on device**      | Core Data + CloudKit; server never sees raw health data    |
| **Offline-first Ghost**          | All scheduling/detection works without connectivity        |
| **Grounded AI generation**       | RAG over exercise database for accurate, safe workouts     |

---

## 2. iOS/watchOS Native Architecture

### 2.1 Technology Stack (Native)

| Component               | Technology               | Purpose                                 |
| ----------------------- | ------------------------ | --------------------------------------- |
| **UI Framework**        | SwiftUI                  | Minimal UI (app should feel empty)      |
| **Watch Communication** | WatchConnectivity        | Real-time workout detection sync        |
| **Health Data**         | HealthKit                | Sleep, HRV, workouts, heart rate, steps |
| **Calendar**            | EventKit                 | Silent block scheduling                 |
| **Local ML**            | Core ML + Create ML      | Pattern detection, skip prediction      |
| **On-Device AI**        | Apple Intelligence       | Natural language workout parsing        |
| **Local Storage**       | Core Data                | Phenome store, workout cache            |
| **Cloud Sync**          | CloudKit                 | E2E encrypted Phenome backup            |
| **Background Tasks**    | BGTaskScheduler          | Morning/evening Ghost cycles            |
| **Siri Integration**    | App Intents + Shortcuts  | "I'm crashing" red button               |
| **Notifications**       | UNUserNotificationCenter | Max 1/day, binary actions               |

### 2.2 Ghost Engine Implementation

```swift
// GhostEngine.swift - Core orchestration layer
import Foundation
import HealthKit
import EventKit
import CoreML

@MainActor
final class GhostEngine: ObservableObject {

    // MARK: - Data Layer
    private let healthKitObserver: HealthKitObserver
    private let eventKitManager: EventKitManager
    private let phenomeStore: PhenomeStore
    private let locationManager: LocationManager?

    // MARK: - Intelligence Layer
    private let patternDetector: PatternDetector
    private let skipPredictor: SkipPredictor
    private let recoveryAnalyzer: RecoveryAnalyzer
    private let optimalWindowFinder: OptimalWindowFinder
    private let sacredTimeDetector: SacredTimeDetector

    // MARK: - State
    @Published private(set) var trustStateMachine: TrustStateMachine
    @Published private(set) var currentPhase: TrustPhase

    // MARK: - Action Layer
    private let calendarScheduler: CalendarScheduler
    private let notificationOrchestrator: NotificationOrchestrator
    private let workoutLogger: WorkoutLogger
    private let blockTransformer: BlockTransformer

    // MARK: - Cloud Layer (Minimal)
    private let apiClient: VigorAPIClient
    private let cloudKitSync: CloudKitSync

    init() {
        // Initialize all components
        self.healthKitObserver = HealthKitObserver()
        self.eventKitManager = EventKitManager()
        self.phenomeStore = PhenomeStore()
        self.locationManager = LocationManager()

        // Load Core ML models
        self.patternDetector = PatternDetector()
        self.skipPredictor = SkipPredictor()
        self.recoveryAnalyzer = RecoveryAnalyzer()
        self.optimalWindowFinder = OptimalWindowFinder()
        self.sacredTimeDetector = SacredTimeDetector()

        // Initialize trust state from stored Phenome
        self.trustStateMachine = TrustStateMachine(phenome: phenomeStore.currentPhenome)
        self.currentPhase = trustStateMachine.currentPhase

        // Initialize action components
        self.calendarScheduler = CalendarScheduler(eventStore: eventKitManager.store)
        self.notificationOrchestrator = NotificationOrchestrator()
        self.workoutLogger = WorkoutLogger(phenomeStore: phenomeStore)
        self.blockTransformer = BlockTransformer()

        // Cloud components
        self.apiClient = VigorAPIClient()
        self.cloudKitSync = CloudKitSync()
    }

    // MARK: - Daily Ghost Cycle

    /// Morning evaluation (runs via BGTaskScheduler ~6 AM)
    func runMorningCycle() async {
        // 1. Pull overnight sleep data
        let sleepData = await healthKitObserver.fetchOvernightSleep()

        // 2. Calculate recovery score
        let hrvData = await healthKitObserver.fetchMorningHRV()
        let recoveryScore = recoveryAnalyzer.calculateRecoveryScore(
            sleep: sleepData,
            hrv: hrvData,
            recentWorkouts: phenomeStore.recentWorkouts
        )

        // 3. Evaluate today's calendar
        let todayEvents = await eventKitManager.fetchTodayEvents()
        let calendarDensity = patternDetector.calculateDensity(events: todayEvents)

        // 4. Check scheduled training blocks
        let scheduledBlocks = await eventKitManager.fetchVigorBlocks(for: .today)

        // 5. Decision tree for block transformation
        for block in scheduledBlocks {
            let decision = blockTransformer.evaluate(
                block: block,
                recoveryScore: recoveryScore,
                sleepData: sleepData,
                calendarDensity: calendarDensity
            )

            switch decision {
            case .keep:
                continue
            case .transform(let newType):
                // Silently transform block (e.g., Heavy → Recovery)
                await calendarScheduler.transformBlock(block, to: newType)
            case .remove:
                // Contextual silence - remove without notification
                await calendarScheduler.removeBlock(block)
            }
        }

        // 6. Update Phenome with today's data
        await phenomeStore.recordDailySnapshot(
            sleep: sleepData,
            hrv: hrvData,
            recovery: recoveryScore,
            calendarDensity: calendarDensity
        )
    }

    /// Evening planning (runs via BGTaskScheduler ~9 PM)
    func runEveningCycle() async {
        // 1. Evaluate tomorrow's calendar
        let tomorrowEvents = await eventKitManager.fetchEvents(for: .tomorrow)

        // 2. Find optimal workout window
        let optimalWindow = optimalWindowFinder.findBestWindow(
            events: tomorrowEvents,
            phenome: phenomeStore.currentPhenome,
            sacredTimes: sacredTimeDetector.protectedSlots
        )

        guard let window = optimalWindow else {
            // No suitable window - contextual silence
            return
        }

        // 3. Check trust phase for action permission
        let canAutoSchedule = trustStateMachine.canExecute(.autoSchedule)

        if canAutoSchedule {
            // Phase 3+: Add block automatically
            let block = TrainingBlock(
                startDate: window.start,
                duration: window.duration,
                type: determineBlockType()
            )
            await calendarScheduler.scheduleBlock(block)
        } else if trustStateMachine.canExecute(.proposeBlock) {
            // Phase 2: Propose with notification
            await notificationOrchestrator.proposeBlock(
                window: window,
                type: determineBlockType()
            )
        }
        // Phase 1: Observer mode - no action, just learn
    }

    // MARK: - Workout Detection Response

    func handleWorkoutDetected(_ workout: HKWorkout) async {
        // Auto-log with passive acceptance
        let logEntry = await workoutLogger.createLogEntry(from: workout)

        // Send one-tap confirmation notification
        await notificationOrchestrator.sendWorkoutConfirmation(
            duration: workout.duration,
            type: workout.workoutActivityType,
            logId: logEntry.id
        )

        // Update Phenome
        await phenomeStore.recordWorkout(logEntry)

        // Update trust score
        trustStateMachine.recordCompletedWorkout()

        // Plan next session
        await planNextSession()
    }
}
```

### 2.3 Trust State Machine

```swift
// TrustStateMachine.swift
import Foundation

enum TrustPhase: Int, Codable, CaseIterable {
    case observer = 1       // Day 1: Suggest only
    case scheduler = 2      // Day 7+: Propose calendar blocks
    case autoScheduler = 3  // Day 14+: Auto-add blocks
    case transformer = 4    // Day 30+: Transform blocks automatically
    case fullGhost = 5      // Day 60+: Complete autonomy

    var displayName: String {
        switch self {
        case .observer: return "Observer"
        case .scheduler: return "Scheduler"
        case .autoScheduler: return "Auto-Scheduler"
        case .transformer: return "Transformer"
        case .fullGhost: return "Full Ghost"
        }
    }
}

enum GhostAction {
    case suggest           // Show insight, no calendar change
    case proposeBlock      // Propose block, require confirmation
    case autoSchedule      // Add block automatically
    case transformBlock    // Change block type based on data
    case removeBlock       // Remove block (protective action)
}

// ═══════════════════════════════════════════════════════════════════════════
// TRUST ATTRIBUTION LAYER (De-Romanticized Trust Signals)
// ═══════════════════════════════════════════════════════════════════════════

/// **SCALE HARDENING**: Every trust-affecting event must record context.
/// This prevents slow trust poisoning from ambiguous signals.
///
/// Problem: Deletes ≠ rejection, Skips ≠ disinterest, Compliance ≠ trust
/// Solution: Weight trust updates by (confidence × ambiguity)

struct TrustEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let eventType: TrustEventType

    // Context at time of event
    let context: TrustEventContext

    // Ghost's confidence when making the action
    let ghostConfidence: Double              // 0-1

    // Whether user NOTICED the action (high-ambiguity if not)
    let userAwareness: UserAwareness

    // Computed ambiguity score
    var ambiguityScore: Double {
        switch userAwareness {
        case .confirmed:
            return 0.0                        // User explicitly acted
        case .implicit:
            return 0.5                        // Inferred from behavior
        case .unknown:
            return 0.8                        // No signal either way
        }
    }

    // Weighted trust impact = base × confidence × (1 - ambiguity)
    func computeWeightedImpact(baseImpact: Double) -> Double {
        let ambiguityPenalty = 1.0 - ambiguityScore
        return baseImpact * ghostConfidence * ambiguityPenalty
    }
}

enum TrustEventType: String, Codable {
    case blockAccepted               // User worked out at scheduled time
    case blockRejected               // User explicitly deleted block
    case blockIgnored                // Block passed without workout
    case blockCompleted              // Workout completed (any time)
    case suggestionAccepted          // User accepted proposal
    case suggestionRejected          // User rejected proposal
    case blockModified               // User moved block time
    case workoutOverride             // User did different workout
    case safetyBreakerTriggered      // 3 consecutive deletes
}

enum UserAwareness: String, Codable {
    case confirmed                   // User explicitly interacted
    case implicit                    // Inferred from workout detection
    case unknown                     // No evidence either way
}

struct TrustEventContext: Codable {
    // Calendar context
    let meetingCount: Int?
    let backToBackHours: Int?

    // Recovery context
    let recoveryScore: Double?
    let sleepQuality: Double?
    let sleepDuration: Double?

    // Behavioral context
    let dayOfWeek: Int
    let hourOfDay: Int
    let isWeekend: Bool
    let travelDetected: Bool

    // Ghost state at time
    let trustPhase: TrustPhase
    let trustScore: Double
}

/// Attribution engine that records and weights trust events
actor TrustAttributionEngine {

    private var eventLog: [TrustEvent] = []
    private let maxEventLogSize = 500         // Rolling window

    /// Record a trust event with full context
    func record(
        type: TrustEventType,
        context: TrustEventContext,
        ghostConfidence: Double,
        awareness: UserAwareness
    ) async -> TrustEvent {
        let event = TrustEvent(
            id: UUID(),
            timestamp: Date(),
            eventType: type,
            context: context,
            ghostConfidence: ghostConfidence,
            userAwareness: awareness
        )

        eventLog.append(event)

        // Trim to rolling window
        if eventLog.count > maxEventLogSize {
            eventLog.removeFirst(eventLog.count - maxEventLogSize)
        }

        return event
    }

    /// Compute weighted trust delta (replaces naive delta)
    func computeTrustDelta(for event: TrustEvent) -> Double {
        let baseDelta = baseImpact(for: event.eventType)
        return event.computeWeightedImpact(baseImpact: baseDelta)
    }

    private func baseImpact(for type: TrustEventType) -> Double {
        switch type {
        case .blockAccepted: return +0.02
        case .blockRejected: return -0.02
        case .blockIgnored: return -0.01      // Ambiguous, small penalty
        case .blockCompleted: return +0.03
        case .suggestionAccepted: return +0.02
        case .suggestionRejected: return -0.01
        case .blockModified: return +0.01     // User engaged, net positive
        case .workoutOverride: return +0.02   // User worked out!
        case .safetyBreakerTriggered: return -0.10
        }
    }

    /// Analyze trust history for patterns (debugging aid)
    func analyzeAmbiguityRate() -> Double {
        guard !eventLog.isEmpty else { return 0 }
        let totalAmbiguity = eventLog.reduce(0.0) { $0 + $1.ambiguityScore }
        return totalAmbiguity / Double(eventLog.count)
    }
}

final class TrustStateMachine: ObservableObject {
    @Published private(set) var currentPhase: TrustPhase
    @Published private(set) var trustScore: Double  // 0.0 - 1.0

    // Progression tracking
    private(set) var daysActive: Int
    private(set) var acceptedSuggestions: Int
    private(set) var completedWorkouts: Int
    private(set) var overrideCount: Int

    // Confidence thresholds for actions
    private let actionConfidenceThresholds: [GhostAction: Double] = [
        .suggest: 0.0,
        .proposeBlock: 0.50,
        .autoSchedule: 0.70,
        .transformBlock: 0.85,
        .removeBlock: 0.90
    ]

    init(phenome: Phenome) {
        self.currentPhase = phenome.trustPhase
        self.trustScore = phenome.trustScore
        self.daysActive = phenome.daysActive
        self.acceptedSuggestions = phenome.acceptedSuggestions
        self.completedWorkouts = phenome.completedWorkouts
        self.overrideCount = phenome.overrideCount
    }

    /// Check if Ghost can execute an action given current trust level
    func canExecute(_ action: GhostAction, confidence: Double = 1.0) -> Bool {
        let requiredConfidence = actionConfidenceThresholds[action] ?? 1.0
        guard confidence >= requiredConfidence else { return false }

        switch action {
        case .suggest:
            return true // Always allowed
        case .proposeBlock:
            return currentPhase >= .scheduler
        case .autoSchedule:
            return currentPhase >= .autoScheduler
        case .transformBlock:
            return currentPhase >= .transformer
        case .removeBlock:
            return currentPhase >= .transformer // Protective actions allowed
        }
    }

    /// Record accepted suggestion (advances trust)
    func recordAcceptedSuggestion() {
        acceptedSuggestions += 1
        updateTrustScore(delta: +0.02)
        checkPhaseAdvancement()
    }

    /// Record rejected suggestion (slows trust accrual)
    func recordRejectedSuggestion() {
        overrideCount += 1
        updateTrustScore(delta: -0.01)
    }

    /// Record completed workout (major trust builder)
    func recordCompletedWorkout() {
        completedWorkouts += 1
        updateTrustScore(delta: +0.03)
        checkPhaseAdvancement()
        consecutiveAutoDeleteCount = 0  // Reset safety breaker on success
    }

    /// Record manual override (user knows better)
    func recordOverride() {
        overrideCount += 1
        updateTrustScore(delta: -0.02)
    }

    // MARK: - Safety Breaker (Relationship Preservation)

    /// **TRUST HARDENING**: If user manually deletes 3 auto-scheduled blocks
    /// consecutively, IMMEDIATELY downgrade from Auto-Scheduler to Propose mode.
    /// This preserves the relationship before the user loses trust entirely.

    private var consecutiveAutoDeleteCount: Int = 0
    private let safetyBreakerThreshold: Int = 3

    /// Called when user deletes an auto-scheduled block
    func recordAutoScheduledBlockDeleted() {
        guard currentPhase >= .autoScheduler else { return }

        consecutiveAutoDeleteCount += 1

        if consecutiveAutoDeleteCount >= safetyBreakerThreshold {
            // EMERGENCY: User is actively rejecting our autonomy
            triggerSafetyBreaker()
        }
    }

    /// Immediate downgrade to preserve relationship
    private func triggerSafetyBreaker() {
        let previousPhase = currentPhase

        // Downgrade to Scheduler (propose, don't auto-schedule)
        currentPhase = .scheduler
        trustScore = min(trustScore, 0.5)  // Cap trust at 50%
        consecutiveAutoDeleteCount = 0

        // Log for analytics - this is a critical event
        AppLogger.shared.warning(
            "Safety Breaker triggered: \(previousPhase) → \(currentPhase). " +
            "User deleted \(safetyBreakerThreshold) consecutive auto-scheduled blocks."
        )

        // Show user acknowledgment
        NotificationCenter.default.post(
            name: .trustSafetyBreakerTriggered,
            object: TrustDowngradeInfo(
                from: previousPhase,
                to: currentPhase,
                reason: "You've removed several scheduled workouts. " +
                        "I'll suggest times instead of auto-scheduling for now."
            )
        )
    }

    /// Reset safety breaker when user accepts a proposed block
    func recordAcceptedProposal() {
        consecutiveAutoDeleteCount = 0
        acceptedSuggestions += 1
        updateTrustScore(delta: +0.02)
        checkPhaseAdvancement()
    }

    private func updateTrustScore(delta: Double) {
        trustScore = max(0, min(1, trustScore + delta))
    }

    private func checkPhaseAdvancement() {
        // Phase advancement rules from PRD §1.3
        switch currentPhase {
        case .observer:
            // 7 days + 3 accepted suggestions → Scheduler
            if daysActive >= 7 && acceptedSuggestions >= 3 {
                advanceTo(.scheduler)
            }
        case .scheduler:
            // 14 days + 5 completed workouts → Auto-Scheduler
            if daysActive >= 14 && completedWorkouts >= 5 {
                advanceTo(.autoScheduler)
            }
        case .autoScheduler:
            // 30 days + trust score > 80% → Transformer
            if daysActive >= 30 && trustScore > 0.80 {
                advanceTo(.transformer)
            }
        case .transformer:
            // 60 days + trust score > 90% → Full Ghost
            if daysActive >= 60 && trustScore > 0.90 {
                advanceTo(.fullGhost)
            }
        case .fullGhost:
            break // Already at max
        }
    }

    private func advanceTo(_ phase: TrustPhase) {
        currentPhase = phase
        // Log phase advancement for analytics
    }

    /// Manual phase adjustment (user can always control)
    func setPhase(_ phase: TrustPhase) {
        currentPhase = phase
    }
}

extension Notification.Name {
    static let trustSafetyBreakerTriggered = Notification.Name("trustSafetyBreakerTriggered")
}

struct TrustDowngradeInfo {
    let from: TrustPhase
    let to: TrustPhase
    let reason: String
}
```

### 2.4 Phenome Data Model (On-Device)

> **HARDENED**: Trust State stored separately in CloudKit for resilient device restore.

```swift
// Phenome.swift - Decomposed Local Pattern Storage
import CoreData

/// **SCALE HARDENING**: The Phenome is decomposed into THREE physical stores
/// to enable safe migration, retroactive debugging, and independent recomputation.
///
/// This solves:
/// - Schema migrations become surgical, not existential
/// - Silent corruption is detectable via cross-store validation
/// - Ghost decisions can be replayed and audited
/// - Each store has its own sync, TTL, and rebuild strategy

// ═══════════════════════════════════════════════════════════════════════════
// STORE 1: RawSignalStore (Append-Only, Immutable)
// ═══════════════════════════════════════════════════════════════════════════

/// Raw daily aggregates from sensors - NEVER modified, only superseded
/// This is the single source of truth for all derived computations
actor RawSignalStore {

    /// Append-only storage policy
    enum Policy {
        static let immutable = true           // Never edit, only append
        static let retentionDays = 365        // Keep 1 year of raw data
        static let aggregationLevel = "daily" // Pre-aggregated for efficiency
    }

    /// Daily health aggregate - one per day, immutable after creation
    struct DailyAggregate: Codable, Identifiable {
        let id: UUID
        let date: Date                        // Calendar day (no time component)
        let createdAt: Date

        // Sleep signals
        let sleepDurationMinutes: Int?
        let sleepQualityScore: Double?        // 0-1
        let deepSleepMinutes: Int?
        let remSleepMinutes: Int?
        let sleepOnsetTime: Date?
        let wakeTime: Date?

        // Recovery signals
        let restingHeartRate: Double?
        let hrvMssd: Double?                  // HRV in milliseconds
        let respiratoryRate: Double?

        // Activity signals
        let activeEnergyBurned: Double?
        let stepCount: Int?
        let exerciseMinutes: Int?
        let standHours: Int?

        // Workout signals (array - multiple per day possible)
        let workoutSessions: [WorkoutSignal]

        // Calendar signals
        let meetingCount: Int?
        let meetingMinutes: Int?
        let backToBackMeetingHours: Int?

        // Context signals
        let travelDetected: Bool
        let timezoneOffset: Int?              // For jet lag detection
    }

    struct WorkoutSignal: Codable {
        let id: UUID
        let type: String                      // "strength", "cardio", etc.
        let durationMinutes: Int
        let startTime: Date
        let averageHeartRate: Double?
        let maxHeartRate: Double?
        let caloriesBurned: Double?
        let muscleGroupsWorked: [String]
        let source: String                    // "apple_watch", "vigor", "strava"
    }

    // Storage operations
    func append(_ aggregate: DailyAggregate) async throws {
        // Core Data append with uniqueness check on date
        // If aggregate for date exists, log warning (immutability violation)
    }

    func getRange(from: Date, to: Date) async -> [DailyAggregate] { [] }
    func getLast(days: Int) async -> [DailyAggregate] { [] }

    /// Rebuild derived stores from raw signals (disaster recovery)
    func replayForRecomputation(since: Date) async -> AsyncStream<DailyAggregate> {
        AsyncStream { continuation in
            // Stream aggregates for DerivedStateStore recomputation
            continuation.finish()
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// STORE 2: DerivedStateStore (Versioned, Recomputable)
// ═══════════════════════════════════════════════════════════════════════════

/// Patterns and predictions computed FROM RawSignalStore
/// ALWAYS recomputable - version tracks algorithm + model hash
actor DerivedStateStore {

    /// Every derived value carries its computation provenance
    struct Provenance: Codable {
        let algorithmVersion: String          // "sleep_impact_v2.1"
        let modelHash: String?                // Core ML model checksum
        let inputRange: ClosedRange<Date>     // Raw signals used
        let computedAt: Date
        let confidence: Double                // 0-1
    }

    /// Sleep impact pattern - how sleep affects this user
    struct SleepImpactPattern: Codable {
        let id: UUID
        let sleepThresholdHours: Double       // Below this, performance drops
        let performanceImpactPercent: Double  // e.g., -23%
        let provenance: Provenance
    }

    /// Recovery pattern - how quickly muscles recover
    struct RecoveryPattern: Codable {
        let id: UUID
        let muscleGroup: String
        let requiredRecoveryDays: Int
        let provenance: Provenance
    }

    /// Skip predictors - factors that predict workout skips
    struct SkipPredictor: Codable {
        let id: UUID
        let factors: [SkipFactor]
        let skipProbability: Double
        let provenance: Provenance
    }

    enum SkipFactor: Codable {
        case sleepUnder(hours: Double)
        case meetingsOver(count: Int)
        case backToBackMeetings(hours: Int)
        case travelDay
        case eveningBlock
    }

    /// Optimal workout windows - when this user performs best
    struct TimeWindow: Codable {
        let id: UUID
        let dayOfWeek: Int
        let startHour: Int
        let endHour: Int
        let performanceBoost: Double
        let provenance: Provenance
    }

    /// Current derived state for a user
    struct DerivedState: Codable {
        var sleepImpactPattern: SleepImpactPattern?
        var recoveryPatterns: [RecoveryPattern]
        var skipPredictors: [SkipPredictor]
        var optimalWindows: [TimeWindow]

        // Recomputation metadata
        var lastFullRecompute: Date?
        var needsRecompute: Bool
    }

    private var currentState: DerivedState = DerivedState()

    /// Recompute all patterns from raw signals (safe migration path)
    func recomputeAll(from rawStore: RawSignalStore, algorithmVersion: String) async {
        let signals = await rawStore.getLast(days: 90)
        // Run Core ML models on signals
        // Update patterns with new provenance
        currentState.lastFullRecompute = Date()
        currentState.needsRecompute = false
    }

    /// Check if algorithm version changed (triggers recompute)
    func validateVersion(currentAlgorithm: String) async -> Bool {
        // Compare provenance.algorithmVersion across patterns
        return true
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// STORE 3: BehavioralMemoryStore (User Preferences & Rejections)
// ═══════════════════════════════════════════════════════════════════════════

/// Sacred times, rejection patterns, user preferences
/// This is BEHAVIORAL data - learned from interactions, not sensors
actor BehavioralMemoryStore {

    /// Sacred time slot - protected from scheduling
    struct SacredTimeSlot: Codable, Identifiable {
        let id: UUID
        let dayOfWeek: Int?                   // nil = every day
        let startHour: Int
        let endHour: Int
        let reason: SacredReason
        let learnedAt: Date
        let confidence: Double
    }

    enum SacredReason: Codable {
        case userExplicit                     // User marked it
        case repeatedRejection(count: Int)    // Learned from behavior
        case defaultProtected                 // Weekend mornings, lunch
        case holidayDetected
    }

    /// Rejection pattern - time slots user has rejected
    struct RejectedSlotPattern: Codable, Identifiable {
        let id: UUID
        let dayOfWeek: Int
        let hourRange: ClosedRange<Int>
        let rejectionCount: Int
        let lastRejection: Date
        let isHardConstraint: Bool            // vs. soft preference
    }

    /// User profile preferences (not sensor-derived)
    struct UserPreferences: Codable {
        var equipment: EquipmentLevel
        var injuries: [Injury]
        var fitnessLevel: FitnessLevel
        var goals: [FitnessGoal]
        var preferredWorkoutDuration: Int?
        var preferredTimeOfDay: TimeOfDay?
    }

    enum TimeOfDay: String, Codable {
        case earlyMorning   // 5-7 AM
        case morning        // 7-10 AM
        case midday         // 10 AM - 2 PM
        case afternoon      // 2-5 PM
        case evening        // 5-8 PM
        case lateEvening    // 8-10 PM
    }

    /// Current behavioral state
    struct BehavioralMemory: Codable {
        var sacredSlots: [SacredTimeSlot]
        var rejectedSlots: [RejectedSlotPattern]
        var preferences: UserPreferences
        var updatedAt: Date
    }

    private var memory: BehavioralMemory = BehavioralMemory(
        sacredSlots: [],
        rejectedSlots: [],
        preferences: UserPreferences(
            equipment: .bodyweight,
            injuries: [],
            fitnessLevel: .intermediate,
            goals: []
        ),
        updatedAt: Date()
    )

    func recordRejection(day: Int, hour: Int, isHardConstraint: Bool) async {
        // Update or create rejection pattern
        memory.updatedAt = Date()
    }

    func markSacredTime(_ slot: SacredTimeSlot) async {
        memory.sacredSlots.append(slot)
        memory.updatedAt = Date()
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRUST STATE (Separate, Already Isolated)
// ═══════════════════════════════════════════════════════════════════════════

/// Trust State remains isolated as before - syncs independently
/// See TrustStateMachine for implementation

// ═══════════════════════════════════════════════════════════════════════════
// UNIFIED PHENOME FACADE (For Backward Compatibility)
// ═══════════════════════════════════════════════════════════════════════════

/// Facade that coordinates the three stores
/// Provides unified access while maintaining physical separation
@MainActor
final class PhenomeCoordinator: ObservableObject {

    let rawSignals: RawSignalStore
    let derivedState: DerivedStateStore
    let behavioralMemory: BehavioralMemoryStore

    init() {
        self.rawSignals = RawSignalStore()
        self.derivedState = DerivedStateStore()
        self.behavioralMemory = BehavioralMemoryStore()
    }

    /// Cross-store validation (detect silent corruption)
    func validateIntegrity() async -> [IntegrityIssue] {
        var issues: [IntegrityIssue] = []

        // Check: Derived patterns reference valid raw signal dates
        // Check: Behavioral rejections align with calendar data
        // Check: Version consistency across derived patterns

        return issues
    }

    /// Full disaster recovery - rebuild from raw signals
    func rebuildDerivedState(algorithmVersion: String) async {
        await derivedState.recomputeAll(from: rawSignals, algorithmVersion: algorithmVersion)
    }
}

struct IntegrityIssue {
    let store: String
    let issue: String
    let severity: IssueSeverity
    let autoRepairable: Bool
}

enum IssueSeverity { case warning, error, critical }
```

// MARK: - CloudKit Sync Schema (Trust State Isolation)

/// **HARDENED**: Trust State syncs independently from heavy Phenome data
/// Ensures device restore doesn't reset Ghost to Observer mode
struct CloudKitSyncSchema {

    /// Lightweight record - syncs immediately, survives restore
    static let trustStateRecordType = "TrustState"

    /// Heavy record - syncs opportunistically, can be rebuilt
    static let phenomeRecordType = "Phenome"

    /// Schema ensures Trust State is ALWAYS synced first
    struct TrustStateRecord {
        static let fields = [
            "trustPhase",           // Int (1-5)
            "trustScore",           // Double (0.0-1.0)
            "daysActive",           // Int
            "acceptedSuggestions",  // Int
            "completedWorkouts",    // Int
            "overrideCount",        // Int
            "lastSyncedAt"          // Date
        ]
        // Record size: ~200 bytes (always syncs)
    }

    /// Phenome is larger but can be rebuilt from HealthKit if lost
    struct PhenomeRecord {
        static let fields = [
            "patterns",             // JSON blob
            "workoutHistory",       // JSON blob (rolling 90 days)
            "sacredSlots",          // JSON blob
            "lastSyncedAt"          // Date
        ]
        // Record size: ~50-200 KB (syncs opportunistically)
    }

}

// MARK: - CloudKit Conflict Resolution

/// **HARDENED**: "Highest Trust Wins" merge policy
/// Prevents demotion when user switches between devices (iPhone ↔ iPad)
final class TrustStateConflictResolver {

    /// Merge strategy: Always keep the highest trust level
    /// Rationale: User earned that trust on SOME device; honor it everywhere
    static func resolve(local: TrustStateRecord, remote: TrustStateRecord) -> TrustStateRecord {

        // Rule 1: Higher phase always wins
        let winningPhase = max(local.trustPhase, remote.trustPhase)

        // Rule 2: Higher trust score within phase wins
        let winningScore: Double
        if local.trustPhase == remote.trustPhase {
            winningScore = max(local.trustScore, remote.trustScore)
        } else if local.trustPhase > remote.trustPhase {
            winningScore = local.trustScore
        } else {
            winningScore = remote.trustScore
        }

        // Rule 3: Aggregate activity counts (don't lose any)
        let mergedDaysActive = max(local.daysActive, remote.daysActive)
        let mergedAccepted = max(local.acceptedSuggestions, remote.acceptedSuggestions)
        let mergedWorkouts = max(local.completedWorkouts, remote.completedWorkouts)

        // Rule 4: Override count is summed (both devices' overrides matter)
        let mergedOverrides = local.overrideCount + remote.overrideCount

        return TrustStateRecord(
            trustPhase: winningPhase,
            trustScore: winningScore,
            daysActive: mergedDaysActive,
            acceptedSuggestions: mergedAccepted,
            completedWorkouts: mergedWorkouts,
            overrideCount: mergedOverrides,
            lastSyncedAt: Date()
        )
    }

    /// Register custom merge policy with CloudKit
    static func registerMergePolicy(container: CKContainer) {
        // CloudKit calls this when server record differs from local
        // We implement CKModifyRecordsOperation with custom merge
    }

}

struct TrustStateRecord {
var trustPhase: Int
var trustScore: Double
var daysActive: Int
var acceptedSuggestions: Int
var completedWorkouts: Int
var overrideCount: Int
var lastSyncedAt: Date
}

// ═══════════════════════════════════════════════════════════════════════════
// GLOBAL GHOST HEALTH MONITOR (Systemic Self-Degradation)
// ═══════════════════════════════════════════════════════════════════════════

/// **SCALE HARDENING**: When things go sideways (OS update, HK regression,
/// calendar bug), Ghost keeps trying. That's how apps get deleted.
///
/// This monitor detects systemic failures and auto-degrades Ghost autonomy
/// to preserve user trust before the user loses patience.

actor GhostHealthMonitor {

    // Health thresholds
    struct Thresholds {
        static let maxConsecutiveBackgroundFailures = 5
        static let maxMissedExecutionWindows = 3      // In 24 hours
        static let maxPhenomeInconsistencies = 2      // Per week
        static let maxCalendarMutationFailures = 3
        static let healthCheckIntervalHours = 4
    }

    // Current health state
    struct HealthState {
        var consecutiveBackgroundFailures: Int = 0
        var missedExecutionWindows: Int = 0
        var phenomeInconsistencies: Int = 0
        var calendarMutationFailures: Int = 0
        var lastSuccessfulCycle: Date?
        var lastHealthCheck: Date = Date()
        var currentMode: GhostHealthMode = .healthy

        var isHealthy: Bool {
            return currentMode == .healthy
        }
    }

    enum GhostHealthMode: String, Codable {
        case healthy              // Full autonomy
        case degraded             // Reduced autonomy, monitoring
        case safeMode             // Minimal actions, user notified
        case suspended            // Ghost paused, manual only
    }

    private var state = HealthState()
    private var hasNotifiedUser = false

    // MARK: - Failure Recording

    func recordBackgroundFailure(error: Error) async {
        state.consecutiveBackgroundFailures += 1
        await evaluateHealth()
    }

    func recordBackgroundSuccess() async {
        state.consecutiveBackgroundFailures = 0
        state.lastSuccessfulCycle = Date()
    }

    func recordMissedExecutionWindow() async {
        state.missedExecutionWindows += 1
        await evaluateHealth()
    }

    func recordPhenomeInconsistency(issue: IntegrityIssue) async {
        state.phenomeInconsistencies += 1
        await evaluateHealth()
    }

    func recordCalendarMutationFailure(error: Error) async {
        state.calendarMutationFailures += 1
        await evaluateHealth()
    }

    // MARK: - Health Evaluation

    private func evaluateHealth() async {
        let previousMode = state.currentMode

        // Determine new mode based on failure counts
        if state.consecutiveBackgroundFailures >= Thresholds.maxConsecutiveBackgroundFailures {
            state.currentMode = .suspended
        } else if state.calendarMutationFailures >= Thresholds.maxCalendarMutationFailures {
            state.currentMode = .safeMode
        } else if state.missedExecutionWindows >= Thresholds.maxMissedExecutionWindows {
            state.currentMode = .degraded
        } else if state.phenomeInconsistencies >= Thresholds.maxPhenomeInconsistencies {
            state.currentMode = .degraded
        } else {
            state.currentMode = .healthy
        }

        // Notify on mode change
        if state.currentMode != previousMode {
            await handleModeTransition(from: previousMode, to: state.currentMode)
        }
    }

    private func handleModeTransition(from: GhostHealthMode, to: GhostHealthMode) async {
        AppLogger.shared.warning(
            "Ghost Health Mode changed: \(from) → \(to)"
        )

        switch to {
        case .healthy:
            // Recovered - reset notification flag
            hasNotifiedUser = false

        case .degraded:
            // Reduce autonomy silently
            await reduceAutonomy()

        case .safeMode:
            // Pause calendar mutations, notify user ONCE
            await pauseCalendarMutations()
            if !hasNotifiedUser {
                await notifyUserOfIssue()
                hasNotifiedUser = true
            }

        case .suspended:
            // Full stop - notify user
            await suspendGhost()
            if !hasNotifiedUser {
                await notifyUserOfIssue()
                hasNotifiedUser = true
            }
        }
    }

    // MARK: - Degradation Actions

    private func reduceAutonomy() async {
        // Downgrade Trust State Machine to lower phase temporarily
        NotificationCenter.default.post(
            name: .ghostHealthDegraded,
            object: GhostDegradationInfo(
                mode: .degraded,
                reason: "Background execution issues detected",
                recommendedAction: "Monitoring - no user action needed"
            )
        )
    }

    private func pauseCalendarMutations() async {
        // Tell CalendarScheduler to stop creating/modifying blocks
        NotificationCenter.default.post(
            name: .ghostCalendarPaused,
            object: nil
        )
    }

    private func suspendGhost() async {
        // Full Ghost suspension
        NotificationCenter.default.post(
            name: .ghostSuspended,
            object: GhostDegradationInfo(
                mode: .suspended,
                reason: "Multiple system failures detected",
                recommendedAction: "Please restart the app or check system settings"
            )
        )
    }

    private func notifyUserOfIssue() async {
        // Show ONE notification with plain language
        let content = UNMutableNotificationContent()
        content.title = "Vigor needs attention"
        content.body = "I'm having trouble running in the background. Tap to check settings."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "ghost_health_issue",
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Recovery

    func attemptRecovery() async {
        // Reset failure counters and try again
        state.consecutiveBackgroundFailures = 0
        state.missedExecutionWindows = 0
        state.calendarMutationFailures = 0
        state.phenomeInconsistencies = 0
        state.currentMode = .healthy
        hasNotifiedUser = false

        NotificationCenter.default.post(
            name: .ghostHealthRecovered,
            object: nil
        )
    }

    // MARK: - Status Query

    func getCurrentMode() async -> GhostHealthMode {
        return state.currentMode
    }

    func canExecuteAction(_ action: GhostAction) async -> Bool {
        switch state.currentMode {
        case .healthy:
            return true
        case .degraded:
            // Only allow low-risk actions
            return action == .suggest || action == .proposeBlock
        case .safeMode:
            return action == .suggest
        case .suspended:
            return false
        }
    }

}

struct GhostDegradationInfo {
let mode: GhostHealthMonitor.GhostHealthMode
let reason: String
let recommendedAction: String
}

extension Notification.Name {
static let ghostHealthDegraded = Notification.Name("ghostHealthDegraded")
static let ghostCalendarPaused = Notification.Name("ghostCalendarPaused")
static let ghostSuspended = Notification.Name("ghostSuspended")
static let ghostHealthRecovered = Notification.Name("ghostHealthRecovered")
}

// ═══════════════════════════════════════════════════════════════════════════
// DECISION RECEIPT SYSTEM (Forensics & Debugging)
// ═══════════════════════════════════════════════════════════════════════════

/// **SCALE HARDENING**: This system fails SILENTLY by design.
/// When users say "it feels off", we need to explain what Ghost decided and why.
///
/// For every Ghost action, persist a Decision Receipt with:
/// - Inputs snapshot (hashed where needed for privacy)
/// - Decision taken
/// - Alternatives rejected
/// - Confidence score
/// - Trust impact
///
/// This is your: Debugger, Legal shield, User trust amplifier, Future personalization goldmine.

actor DecisionReceiptStore {

    struct DecisionReceipt: Codable, Identifiable {
        let id: UUID
        let timestamp: Date

        // What was decided
        let action: GhostActionType
        let outcome: String                   // Human-readable description

        // Input snapshot (privacy-safe)
        let inputs: DecisionInputs

        // Alternatives considered
        let alternativesRejected: [RejectedAlternative]

        // Confidence and reasoning
        let confidence: Double                // 0-1
        let primaryReason: String             // Why this decision
        let secondaryReasons: [String]

        // Trust impact
        let trustImpact: TrustImpact

        // Expiration (TTL)
        let expiresAt: Date                   // Default: 90 days
    }

    enum GhostActionType: String, Codable {
        case scheduledBlock
        case removedBlock
        case transformedBlock
        case suggestedWorkout
        case skippedScheduling
        case triggeredSafetyBreaker
        case changedTrustPhase
        case generatedInsight
    }

    struct DecisionInputs: Codable {
        // Health state (hashed for privacy)
        let recoveryScoreHash: String?        // Hash of score bucket
        let sleepQualityBucket: String?       // "good", "fair", "poor"
        let hrvTrendDirection: String?        // "up", "stable", "down"

        // Calendar state
        let meetingDensity: String            // "light", "moderate", "heavy"
        let availableSlots: Int
        let dayOfWeek: Int
        let hourOfDay: Int

        // Trust state
        let trustPhase: Int
        let trustScore: Double

        // Pattern state
        let patternConfidence: String         // "low", "medium", "high"
        let daysOfData: Int
    }

    struct RejectedAlternative: Codable {
        let action: String
        let reason: String
        let confidenceIfChosen: Double
    }

    struct TrustImpact: Codable {
        let trustDelta: Double
        let newTrustScore: Double
        let phaseChanged: Bool
        let eventType: String
    }

    // Storage
    private var receipts: [DecisionReceipt] = []
    private let maxReceiptsStored = 1000      // Rolling window
    private let defaultTTLDays = 90

    // MARK: - Recording

    func record(
        action: GhostActionType,
        outcome: String,
        inputs: DecisionInputs,
        alternatives: [RejectedAlternative],
        confidence: Double,
        primaryReason: String,
        secondaryReasons: [String] = [],
        trustImpact: TrustImpact
    ) async -> DecisionReceipt {

        let receipt = DecisionReceipt(
            id: UUID(),
            timestamp: Date(),
            action: action,
            outcome: outcome,
            inputs: inputs,
            alternativesRejected: alternatives,
            confidence: confidence,
            primaryReason: primaryReason,
            secondaryReasons: secondaryReasons,
            trustImpact: trustImpact,
            expiresAt: Calendar.current.date(byAdding: .day, value: defaultTTLDays, to: Date())!
        )

        receipts.append(receipt)

        // Trim expired and excess receipts
        await pruneReceipts()

        // Persist to Core Data (encrypted)
        await persistReceipt(receipt)

        return receipt
    }

    // MARK: - Querying

    func getReceipts(since: Date) async -> [DecisionReceipt] {
        return receipts.filter { $0.timestamp >= since }
    }

    func getReceipts(forAction: GhostActionType) async -> [DecisionReceipt] {
        return receipts.filter { $0.action == forAction }
    }

    func explainDecision(id: UUID) async -> String? {
        guard let receipt = receipts.first(where: { $0.id == id }) else {
            return nil
        }

        return """
        Decision: \(receipt.outcome)
        When: \(receipt.timestamp)
        Confidence: \(Int(receipt.confidence * 100))%

        Why: \(receipt.primaryReason)
        \(receipt.secondaryReasons.map { "• \($0)" }.joined(separator: "\n"))

        Alternatives considered:
        \(receipt.alternativesRejected.map { "• \($0.action): \($0.reason)" }.joined(separator: "\n"))

        Trust impact: \(receipt.trustImpact.trustDelta > 0 ? "+" : "")\(receipt.trustImpact.trustDelta)
        """
    }

    // MARK: - Analytics

    func getDecisionStats() async -> DecisionStats {
        let last30Days = receipts.filter {
            $0.timestamp >= Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        }

        let avgConfidence = last30Days.isEmpty ? 0 :
            last30Days.reduce(0) { $0 + $1.confidence } / Double(last30Days.count)

        let actionCounts = Dictionary(grouping: last30Days, by: { $0.action })
            .mapValues { $0.count }

        return DecisionStats(
            totalDecisions: last30Days.count,
            averageConfidence: avgConfidence,
            actionBreakdown: actionCounts,
            lowConfidenceCount: last30Days.filter { $0.confidence < 0.5 }.count
        )
    }

    struct DecisionStats {
        let totalDecisions: Int
        let averageConfidence: Double
        let actionBreakdown: [GhostActionType: Int]
        let lowConfidenceCount: Int
    }

    // MARK: - Maintenance

    private func pruneReceipts() async {
        let now = Date()

        // Remove expired
        receipts.removeAll { $0.expiresAt < now }

        // Trim to max size
        if receipts.count > maxReceiptsStored {
            receipts = Array(receipts.suffix(maxReceiptsStored))
        }
    }

    private func persistReceipt(_ receipt: DecisionReceipt) async {
        // Store in Core Data with encryption
        // This is the forensic record for debugging
    }

}

````

### 2.5 HealthKit Integration

```swift
// HealthKitObserver.swift
import HealthKit
import Combine

final class HealthKitObserver: ObservableObject {

    private let healthStore = HKHealthStore()

    // Required data types (Apple Watch mandatory)
    private let requiredTypes: Set<HKSampleType> = [
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.workoutType()
    ]

    // MARK: - Import State Persistence (Savepoint/Resume)

    private let importStateKey = "vigor_import_state"

    struct ImportState: Codable {
        var lastProcessedDate: Date
        var completedChunks: Int
        var totalChunks: Int
        var isComplete: Bool
    }

    // MARK: - Day 1 Magic: Progressive Import with Checkpointing

    /// **HARDENED**: Progressive Disclosure + Chunked Import with Savepoints
    ///
    /// Strategy (addresses UI hang AND OS task kill risks):
    /// 1. Instant (< 2 sec): Last 7 days only → Generate immediate insight
    /// 2. Background: Last 90 days in 7-day chunks with savepoints
    /// 3. Resume: If OS kills task, resume from last completed chunk
    /// 4. Overnight: Deep sample analysis → Pattern detection
    ///
    /// This ensures: UI never blocks, OS kills don't restart from zero.

    func importHistoricalDataProgressive(
        onInstantComplete: @escaping (InstantInsight) -> Void,
        onFullComplete: @escaping (HistoricalHealthData) -> Void
    ) async throws {

        // PHASE 1: INSTANT (7 days) - Never blocks UI
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

        async let recentSleep = fetchSleepAggregates(from: sevenDaysAgo)
        async let recentWorkouts = fetchWorkouts(from: sevenDaysAgo)
        async let recentHRV = fetchHRVAggregates(from: sevenDaysAgo)

        let instantData = try await InstantHealthData(
            sleepAggregates: recentSleep,
            workouts: recentWorkouts,
            hrvAggregates: recentHRV
        )

        // Generate immediate insight from 7-day data
        let instantInsight = generateInstantInsight(from: instantData)
        onInstantComplete(instantInsight)

        // PHASE 2: CHUNKED BACKGROUND (90 days in 7-day chunks with savepoints)
        Task.detached(priority: .utility) { [self] in
            let fullData = try await importWithCheckpointing()
            await MainActor.run {
                onFullComplete(fullData)
            }
        }
    }

    /// Chunked import with savepoint/resume capability
    /// If OS kills background task, we resume from last completed chunk
    private func importWithCheckpointing() async throws -> HistoricalHealthData {

        // Check for existing import state (resume case)
        let existingState = loadImportState()

        // Define chunks: 13 chunks of 7 days each = 91 days
        let chunkDays = 7
        let totalChunks = 13
        let startChunk = existingState?.completedChunks ?? 0

        var allSleepAggregates: [DailyAggregate] = []
        var allHRVAggregates: [DailyAggregate] = []
        var allStepAggregates: [DailyAggregate] = []
        var allRestingHRAggregates: [DailyAggregate] = []
        var allWorkouts: [HKWorkout] = []

        for chunkIndex in startChunk..<totalChunks {
            // Calculate date range for this chunk
            let chunkEnd = Calendar.current.date(byAdding: .day, value: -(chunkIndex * chunkDays), to: Date())!
            let chunkStart = Calendar.current.date(byAdding: .day, value: -chunkDays, to: chunkEnd)!

            // Fetch this chunk
            async let sleepChunk = fetchSleepAggregates(from: chunkStart, to: chunkEnd)
            async let hrvChunk = fetchHRVAggregates(from: chunkStart, to: chunkEnd)
            async let stepChunk = fetchStepAggregates(from: chunkStart, to: chunkEnd)
            async let hrChunk = fetchRestingHRAggregates(from: chunkStart, to: chunkEnd)
            async let workoutChunk = fetchWorkouts(from: chunkStart, to: chunkEnd)

            // Accumulate results
            allSleepAggregates.append(contentsOf: try await sleepChunk)
            allHRVAggregates.append(contentsOf: try await hrvChunk)
            allStepAggregates.append(contentsOf: try await stepChunk)
            allRestingHRAggregates.append(contentsOf: try await hrChunk)
            allWorkouts.append(contentsOf: try await workoutChunk)

            // SAVEPOINT: Persist progress after each chunk
            let state = ImportState(
                lastProcessedDate: chunkStart,
                completedChunks: chunkIndex + 1,
                totalChunks: totalChunks,
                isComplete: chunkIndex == totalChunks - 1
            )
            saveImportState(state)

            // Yield to allow OS to manage resources
            try await Task.sleep(nanoseconds: 100_000_000)  // 100ms pause between chunks
        }

        // Mark import complete
        clearImportState()

        return HistoricalHealthData(
            sleepAggregates: allSleepAggregates,
            workouts: allWorkouts,
            hrvAggregates: allHRVAggregates,
            stepAggregates: allStepAggregates,
            restingHRAggregates: allRestingHRAggregates,
            importedAt: Date(),
            deepAnalysisComplete: false
        )
    }

    private func loadImportState() -> ImportState? {
        guard let data = UserDefaults.standard.data(forKey: importStateKey) else { return nil }
        return try? JSONDecoder().decode(ImportState.self, from: data)
    }

    private func saveImportState(_ state: ImportState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: importStateKey)
    }

    private func clearImportState() {
        UserDefaults.standard.removeObject(forKey: importStateKey)
    }

    /// Generate instant insight from 7-day data (for immediate UI)
    private func generateInstantInsight(from data: InstantHealthData) -> InstantInsight {
        let avgSleep = data.sleepAggregates.map { $0.value }.reduce(0, +) / max(1, Double(data.sleepAggregates.count))
        let workoutCount = data.workouts.count
        let avgHRV = data.hrvAggregates.map { $0.value }.reduce(0, +) / max(1, Double(data.hrvAggregates.count))

        return InstantInsight(
            sleepAverage: avgSleep,
            workoutsThisWeek: workoutCount,
            hrvTrend: avgHRV > 40 ? .good : avgHRV > 25 ? .moderate : .low,
            readyForFullAnalysis: true
        )
    }

    // Legacy method (still available for background refresh)
    func importHistoricalData() async throws -> HistoricalHealthData {
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date())!

        async let sleepAggregates = fetchSleepAggregates(from: ninetyDaysAgo)
        async let hrvAggregates = fetchHRVAggregates(from: ninetyDaysAgo)
        async let stepAggregates = fetchStepAggregates(from: ninetyDaysAgo)
        async let restingHRAggregates = fetchRestingHRAggregates(from: ninetyDaysAgo)
        async let workouts = fetchWorkouts(from: ninetyDaysAgo)

        return try await HistoricalHealthData(
            sleepAggregates: sleepAggregates,
            workouts: workouts,
            hrvAggregates: hrvAggregates,
            stepAggregates: stepAggregates,
            restingHRAggregates: restingHRAggregates,
            importedAt: Date(),
            deepAnalysisComplete: false
        )
    }

    /// Fetch daily sleep aggregates (NOT raw samples)
    private func fetchSleepAggregates(from startDate: Date) async -> [DailyAggregate] {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: HKQuantityType.quantityType(forIdentifier: .appleStandTime)!, // Proxy
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startDate, end: Date()),
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)  // Daily buckets
            )

            query.initialResultsHandler = { _, results, _ in
                var aggregates: [DailyAggregate] = []
                results?.enumerateStatistics(from: startDate, to: Date()) { statistics, _ in
                    aggregates.append(DailyAggregate(
                        date: statistics.startDate,
                        value: statistics.sumQuantity()?.doubleValue(for: .hour()) ?? 0
                    ))
                }
                continuation.resume(returning: aggregates)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch daily HRV aggregates
    private func fetchHRVAggregates(from startDate: Date) async -> [DailyAggregate] {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: hrvType,
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startDate, end: Date()),
                options: .discreteAverage,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, results, _ in
                var aggregates: [DailyAggregate] = []
                results?.enumerateStatistics(from: startDate, to: Date()) { statistics, _ in
                    if let avg = statistics.averageQuantity()?.doubleValue(for: .secondUnit(with: .milli)) {
                        aggregates.append(DailyAggregate(date: statistics.startDate, value: avg))
                    }
                }
                continuation.resume(returning: aggregates)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch daily step aggregates
    private func fetchStepAggregates(from startDate: Date) async -> [DailyAggregate] {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startDate, end: Date()),
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, results, _ in
                var aggregates: [DailyAggregate] = []
                results?.enumerateStatistics(from: startDate, to: Date()) { statistics, _ in
                    if let sum = statistics.sumQuantity()?.doubleValue(for: .count()) {
                        aggregates.append(DailyAggregate(date: statistics.startDate, value: sum))
                    }
                }
                continuation.resume(returning: aggregates)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch daily resting HR aggregates
    private func fetchRestingHRAggregates(from startDate: Date) async -> [DailyAggregate] {
        let hrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: hrType,
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startDate, end: Date()),
                options: .discreteAverage,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, results, _ in
                var aggregates: [DailyAggregate] = []
                results?.enumerateStatistics(from: startDate, to: Date()) { statistics, _ in
                    if let avg = statistics.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
                        aggregates.append(DailyAggregate(date: statistics.startDate, value: avg))
                    }
                }
                continuation.resume(returning: aggregates)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Background Observers (Battery-Conscious)

    /// HARDENED: Explicit battery budget constraints
    /// - Workout detection: Immediate (required for core functionality)
    /// - Sleep/HRV: Hourly (batch processing)
    /// - Deep analysis: Only during charging (overnight)

    func setupBackgroundDelivery() {
        // Workout detection - IMMEDIATE (this is core to the Ghost)
        // Uses HKObserverQuery which wakes app AFTER workout completes, not continuously
        let workoutType = HKObjectType.workoutType()
        healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { success, error in
            if success {
                print("Background workout delivery enabled")
            }
        }

        // Sleep analysis - HOURLY (batched, not continuous)
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        healthStore.enableBackgroundDelivery(for: sleepType, frequency: .hourly) { _, _ in }

        // HRV - HOURLY (no need for real-time)
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        healthStore.enableBackgroundDelivery(for: hrvType, frequency: .hourly) { _, _ in }

        // NOTE: We do NOT enable background delivery for:
        // - Heart rate (too frequent, drains battery)
        // - Steps (aggregated daily is sufficient)
        // - Motion data (handled by Watch, not iPhone)
    }

    // MARK: - Deep Analysis (Overnight Only)

    /// Perform deep sample-level analysis only when device is charging
    /// This avoids CPU throttling and respects battery budget
    func performDeepAnalysisIfCharging() async {
        guard await isDeviceCharging() else {
            return  // Skip if not charging
        }

        guard await isNighttime() else {
            return  // Only run between 1 AM - 5 AM
        }

        // Now safe to do expensive analysis
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date())!

        // Fetch raw samples for detailed correlation analysis
        let sleepSamples = await fetchDetailedSleepSamples(from: ninetyDaysAgo)
        let workoutSamples = await fetchDetailedWorkoutSamples(from: ninetyDaysAgo)

        // Correlate sleep quality with workout performance
        await analyzeSeepWorkoutCorrelation(sleep: sleepSamples, workouts: workoutSamples)

        // Update Phenome with deep insights
        await phenomeStore?.updateDeepInsights()
    }

    private func isDeviceCharging() async -> Bool {
        await UIDevice.current.batteryState == .charging ||
               UIDevice.current.batteryState == .full
    }

    private func isNighttime() async -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 1 && hour <= 5
    }

    // MARK: - Fetch Methods

    func fetchOvernightSleep() async -> SleepData {
        let yesterday6PM = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date().addingTimeInterval(-86400))!
        let today10AM = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!

        let predicate = HKQuery.predicateForSamples(withStart: yesterday6PM, end: today10AM)
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, _ in
                let sleepData = self.processSleepSamples(samples as? [HKCategorySample] ?? [])
                continuation.resume(returning: sleepData)
            }
            healthStore.execute(query)
        }
    }

    func fetchMorningHRV() async -> HRVData {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: todayStart, end: Date())
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: hrvType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, _ in
                let avgHRV = statistics?.averageQuantity()?.doubleValue(for: .secondUnit(with: .milli)) ?? 0
                continuation.resume(returning: HRVData(average: avgHRV, date: Date()))
            }
            healthStore.execute(query)
        }
    }

    private func processSleepSamples(_ samples: [HKCategorySample]) -> SleepData {
        var totalAsleep: TimeInterval = 0
        var inBed: TimeInterval = 0

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)

            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                 HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                 HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                totalAsleep += duration
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                inBed += duration
            default:
                break
            }
        }

        return SleepData(
            totalAsleepHours: totalAsleep / 3600,
            inBedHours: inBed / 3600,
            efficiency: inBed > 0 ? totalAsleep / inBed : 0,
            date: Date()
        )
    }
}
````

### 2.6 Calendar Scheduler (Silent Blocks)

> **HARDENED**: Uses local-only calendar source to prevent sync pollution to corporate calendars.

```swift
// CalendarScheduler.swift
import EventKit

final class CalendarScheduler {

    private let eventStore: EKEventStore
    private var vigorCalendar: EKCalendar?

    // User-selected calendars that act as "hard blockers"
    private var blockerCalendarIDs: Set<String> = []

    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
        setupVigorCalendar()
        loadBlockerCalendars()
    }

    private func setupVigorCalendar() {
        // Find existing Vigor calendar
        if let existing = eventStore.calendars(for: .event)
            .first(where: { $0.title == "Vigor Training" && $0.source.sourceType == .local }) {
            vigorCalendar = existing
            return
        }

        // CRITICAL: Create calendar with LOCAL source only
        // This prevents Vigor blocks from syncing to Exchange/Outlook/iCloud
        guard let localSource = findLocalSource() else {
            // Fallback: create subscribed calendar (read-only appearance)
            createSubscribedCalendar()
            return
        }

        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = "Vigor Training"
        calendar.cgColor = UIColor.systemBlue.cgColor
        calendar.source = localSource  // LOCAL SOURCE ONLY

        do {
            try eventStore.saveCalendar(calendar, commit: true)
            vigorCalendar = calendar
        } catch {
            // Fallback to subscribed calendar
            createSubscribedCalendar()
        }
    }

    /// Find the local calendar source (not iCloud, Exchange, or Google)
    private func findLocalSource() -> EKSource? {
        // Priority: Local > CalDAV (self-hosted) > Subscribed
        // NEVER: Exchange, iCloud (which sync to cloud)
        return eventStore.sources.first { source in
            source.sourceType == .local
        }
    }

    /// Create a subscribed (overlay) calendar as fallback
    /// This appears on device but doesn't sync upstream
    private func createSubscribedCalendar() {
        // Subscribed calendars are read-only from server perspective
        // We manage them locally via a custom ICS feed
        // This is the safest option for corporate environments
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = "Vigor Training"
        calendar.cgColor = UIColor.systemBlue.cgColor

        // Use subscribed source if available
        if let subscribedSource = eventStore.sources.first(where: { $0.sourceType == .subscribed }) {
            calendar.source = subscribedSource
        } else if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            calendar.source = localSource
        }

        try? eventStore.saveCalendar(calendar, commit: true)
        vigorCalendar = calendar
    }

    /// Load user-selected blocker calendars (Work, Family, etc.)
    private func loadBlockerCalendars() {
        // These are calendars that mark time as truly "busy"
        // Stored in UserDefaults, configurable in settings
        if let ids = UserDefaults.standard.stringArray(forKey: "vigor_blocker_calendars") {
            blockerCalendarIDs = Set(ids)
        } else {
            // Default: all calendars except Vigor itself
            blockerCalendarIDs = Set(
                eventStore.calendars(for: .event)
                    .filter { $0.title != "Vigor Training" }
                    .map { $0.calendarIdentifier }
            )
        }
    }

    // MARK: - Block Scheduling

    func scheduleBlock(_ block: TrainingBlock) async throws {
        guard let calendar = vigorCalendar else {
            throw CalendarError.noCalendar
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = block.displayTitle
        event.startDate = block.startDate
        event.endDate = block.startDate.addingTimeInterval(block.duration)
        event.notes = encodeGhostMetadata(block.metadata)

        // Add structured location for Watch complication
        event.structuredLocation = EKStructuredLocation(title: block.type.emoji)

        // Set alert based on user preference
        event.addAlarm(EKAlarm(relativeOffset: -900)) // 15 min before

        try eventStore.save(event, span: .thisEvent, commit: true)
    }

    /// Transform block type (e.g., Heavy → Recovery)
    func transformBlock(_ block: TrainingBlock, to newType: BlockType) async throws {
        guard let event = findEvent(for: block) else { return }

        // Update title with transformation indicator
        event.title = "⚠️ \(newType.displayTitle) (Was: \(block.type.displayTitle))"

        // Update notes with explanation
        var metadata = block.metadata
        metadata.transformedFrom = block.type
        metadata.transformReason = generateTransformReason(from: block.type, to: newType)
        event.notes = encodeGhostMetadata(metadata)

        try eventStore.save(event, span: .thisEvent, commit: true)
    }

    /// Remove block silently (contextual silence)
    func removeBlock(_ block: TrainingBlock) async throws {
        guard let event = findEvent(for: block) else { return }
        try eventStore.remove(event, span: .thisEvent, commit: true)
    }

    // MARK: - Free Block Detection (Hardened)

    func findFreeBlocks(on date: Date, minDuration: TimeInterval = 1800) -> [TimeWindow] {
        let dayStart = Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: date)!
        let dayEnd = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: date)!

        // Only query blocker calendars (not all calendars)
        let blockerCalendars = eventStore.calendars(for: .event)
            .filter { blockerCalendarIDs.contains($0.calendarIdentifier) }

        let predicate = eventStore.predicateForEvents(
            withStart: dayStart,
            end: dayEnd,
            calendars: blockerCalendars.isEmpty ? nil : blockerCalendars
        )

        let events = eventStore.events(matching: predicate)
            .filter { event in
                // HARDENED: Smart all-day event handling
                // All-day events only block if marked as "Busy" (not "Free")
                if event.isAllDay {
                    return event.availability == .busy || event.availability == .unavailable
                }
                return true
            }
            .sorted { $0.startDate < $1.startDate }

        var freeBlocks: [TimeWindow] = []
        var currentTime = dayStart

        for event in events {
            // Skip Vigor's own events
            guard event.calendar?.calendarIdentifier != vigorCalendar?.calendarIdentifier else {
                continue
            }

            if event.startDate.timeIntervalSince(currentTime) >= minDuration {
                freeBlocks.append(TimeWindow(
                    start: currentTime,
                    end: event.startDate,
                    duration: event.startDate.timeIntervalSince(currentTime)
                ))
            }
            currentTime = max(currentTime, event.endDate)
        }

        // Check remaining time until day end
        if dayEnd.timeIntervalSince(currentTime) >= minDuration {
            freeBlocks.append(TimeWindow(
                start: currentTime,
                end: dayEnd,
                duration: dayEnd.timeIntervalSince(currentTime)
            ))
        }

        return freeBlocks
    }

    /// Configure which calendars act as blockers
    func setBlockerCalendars(_ calendarIDs: [String]) {
        blockerCalendarIDs = Set(calendarIDs)
        UserDefaults.standard.set(calendarIDs, forKey: "vigor_blocker_calendars")
    }

    /// Get all available calendars for user to select blockers
    func getAvailableCalendars() -> [CalendarInfo] {
        eventStore.calendars(for: .event)
            .filter { $0.title != "Vigor Training" }
            .map { calendar in
                CalendarInfo(
                    id: calendar.calendarIdentifier,
                    title: calendar.title,
                    color: UIColor(cgColor: calendar.cgColor ?? UIColor.gray.cgColor),
                    isBlocker: blockerCalendarIDs.contains(calendar.calendarIdentifier),
                    sourceType: calendar.source.sourceType.rawValue
                )
            }
    }

    private func encodeGhostMetadata(_ metadata: BlockMetadata) -> String {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(metadata),
              let json = String(data: data, encoding: .utf8) else {
            return ""
        }
        return "<!-- VIGOR:\(json) -->"
    }

    private func generateTransformReason(from: BlockType, to: BlockType) -> String {
        // Probabilistic language per PRD
        return "Your HRV is below baseline. Recovery prioritized to reduce strain risk. Tap to revert."
    }

    // MARK: - Deterministic Slot-Finding (Chaos Mode)

    /// **HARDENED**: Deterministic algorithm for rescheduling requests
    /// No LLM needed for "move my workout to later" - pure calendar math
    ///
    /// LLM is only called for SEMANTIC changes (injuries, exercise swaps)
    /// 95% of "Chaos" requests are logistical, not semantic

    func findNextViableSlot(
        after: Date,
        minDuration: TimeInterval = 1800,
        maxDaysAhead: Int = 7,
        preferredWindows: [PreferredWindow]? = nil
    ) -> TimeWindow? {

        let calendar = Calendar.current

        for dayOffset in 0..<maxDaysAhead {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: after) else {
                continue
            }

            // Skip if target date is before "after" time on day 0
            let dayStart: Date
            if dayOffset == 0 {
                dayStart = after
            } else {
                dayStart = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: targetDate)!
            }

            // Find all free blocks on this day
            let freeBlocks = findFreeBlocks(on: targetDate, minDuration: minDuration)

            // Filter to blocks after our start time
            let validBlocks = freeBlocks.filter { $0.start >= dayStart }

            // If preferred windows specified, try those first
            if let preferred = preferredWindows {
                for window in preferred {
                    if let match = findBlockInWindow(blocks: validBlocks, window: window, date: targetDate) {
                        return match
                    }
                }
            }

            // Otherwise return first available
            if let firstBlock = validBlocks.first {
                return firstBlock
            }
        }

        return nil  // No viable slot found
    }

    private func findBlockInWindow(blocks: [TimeWindow], window: PreferredWindow, date: Date) -> TimeWindow? {
        let windowStart = Calendar.current.date(bySettingHour: window.startHour, minute: 0, second: 0, of: date)!
        let windowEnd = Calendar.current.date(bySettingHour: window.endHour, minute: 0, second: 0, of: date)!

        return blocks.first { block in
            block.start >= windowStart && block.end <= windowEnd
        }
    }

    /// Reschedule block to next viable slot (pure deterministic, no LLM)
    func rescheduleToNextSlot(_ block: TrainingBlock) async throws -> TrainingBlock? {
        guard let nextSlot = findNextViableSlot(
            after: Date(),
            minDuration: block.duration,
            preferredWindows: loadUserPreferredWindows()
        ) else {
            return nil  // No viable slot in next 7 days
        }

        // Remove old block
        try await removeBlock(block)

        // Create new block at new time
        var newBlock = block
        newBlock.metadata.transformReason = "Rescheduled from \(formatTime(block.startDate)) to \(formatTime(nextSlot.start))"

        let rescheduledBlock = TrainingBlock(
            id: UUID(),
            startDate: nextSlot.start,
            duration: block.duration,
            type: block.type,
            metadata: newBlock.metadata
        )

        try await scheduleBlock(rescheduledBlock)
        return rescheduledBlock
    }

    private func loadUserPreferredWindows() -> [PreferredWindow] {
        // Load from user preferences/Phenome
        return [
            PreferredWindow(startHour: 6, endHour: 8, priority: 1),   // Early morning
            PreferredWindow(startHour: 12, endHour: 13, priority: 2), // Lunch
            PreferredWindow(startHour: 17, endHour: 19, priority: 3)  // After work
        ]
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PreferredWindow {
    let startHour: Int
    let endHour: Int
    let priority: Int
}

// MARK: - Shadow Calendar Sync (Exchange/Outlook Integration)

/// **ARCHITECTURAL ENHANCEMENT**: Shadow Sync to protect time from colleagues
///
/// The PRD targets high-performers in corporate environments. A local-only calendar
/// means colleagues can schedule over training blocks because they can't see them.
/// Shadow Sync writes "Busy" blocks to the user's work calendar via Microsoft Graph API.

final class CalendarShadowSync {

    private let graphClient: MSGraphClient?
    private var isShadowSyncEnabled: Bool = false

    // User's work calendar (Exchange/Outlook)
    private var workCalendarId: String?

    init() {
        self.graphClient = MSGraphClient.shared
        loadShadowSyncSettings()
    }

    // MARK: - Configuration

    /// Enable shadow sync to work calendar
    /// Called from Settings when user opts in
    func enableShadowSync(workCalendarId: String) async throws {
        guard let client = graphClient else {
            throw ShadowSyncError.graphNotConfigured
        }

        // Validate we have Graph API access
        guard await client.hasCalendarWritePermission() else {
            throw ShadowSyncError.insufficientPermissions
        }

        self.workCalendarId = workCalendarId
        self.isShadowSyncEnabled = true

        UserDefaults.standard.set(true, forKey: "vigor_shadow_sync_enabled")
        UserDefaults.standard.set(workCalendarId, forKey: "vigor_work_calendar_id")
    }

    func disableShadowSync() {
        isShadowSyncEnabled = false
        workCalendarId = nil
        UserDefaults.standard.set(false, forKey: "vigor_shadow_sync_enabled")
    }

    private func loadShadowSyncSettings() {
        isShadowSyncEnabled = UserDefaults.standard.bool(forKey: "vigor_shadow_sync_enabled")
        workCalendarId = UserDefaults.standard.string(forKey: "vigor_work_calendar_id")
    }

    // MARK: - Shadow Block Operations

    /// Create a "Busy" shadow block in work calendar
    /// Privacy: Only shows as "Busy" - no title, no details
    func createShadowBlock(for localBlock: TrainingBlock) async throws {
        guard isShadowSyncEnabled,
              let calendarId = workCalendarId,
              let client = graphClient else { return }

        let shadowEvent = MSGraphEvent(
            subject: "Busy",  // Generic - no "Training" or "Vigor"
            start: MSDateTimeTimeZone(
                dateTime: ISO8601DateFormatter().string(from: localBlock.startDate),
                timeZone: TimeZone.current.identifier
            ),
            end: MSDateTimeTimeZone(
                dateTime: ISO8601DateFormatter().string(from: localBlock.startDate.addingTimeInterval(localBlock.duration)),
                timeZone: TimeZone.current.identifier
            ),
            showAs: .busy,
            sensitivity: .private,  // Hidden from colleagues' detailed view
            isReminderOn: false,
            categories: ["Vigor"]  // Internal tracking only
        )

        // Store mapping for later updates/deletes
        let graphEventId = try await client.createEvent(in: calendarId, event: shadowEvent)

        // Store local ↔ shadow mapping
        await ShadowBlockMapping.store(localId: localBlock.id, graphId: graphEventId)
    }

    /// Update shadow block when local block changes
    func updateShadowBlock(localId: UUID, newStart: Date?, newDuration: TimeInterval?) async throws {
        guard isShadowSyncEnabled,
              let calendarId = workCalendarId,
              let client = graphClient,
              let graphId = await ShadowBlockMapping.getGraphId(for: localId) else { return }

        var updates: [String: Any] = [:]

        if let newStart = newStart {
            updates["start"] = MSDateTimeTimeZone(
                dateTime: ISO8601DateFormatter().string(from: newStart),
                timeZone: TimeZone.current.identifier
            )
        }

        if let duration = newDuration, let newStart = newStart {
            updates["end"] = MSDateTimeTimeZone(
                dateTime: ISO8601DateFormatter().string(from: newStart.addingTimeInterval(duration)),
                timeZone: TimeZone.current.identifier
            )
        }

        try await client.updateEvent(in: calendarId, eventId: graphId, updates: updates)
    }

    /// Delete shadow block when local block is removed
    func deleteShadowBlock(localId: UUID) async throws {
        guard isShadowSyncEnabled,
              let calendarId = workCalendarId,
              let client = graphClient,
              let graphId = await ShadowBlockMapping.getGraphId(for: localId) else { return }

        try await client.deleteEvent(in: calendarId, eventId: graphId)
        await ShadowBlockMapping.remove(localId: localId)
    }

    // MARK: - Work Calendar Discovery

    /// Get user's available work calendars for selection
    func getWorkCalendars() async throws -> [WorkCalendarInfo] {
        guard let client = graphClient else {
            throw ShadowSyncError.graphNotConfigured
        }

        let calendars = try await client.getCalendars()

        return calendars.map { calendar in
            WorkCalendarInfo(
                id: calendar.id,
                name: calendar.name,
                owner: calendar.owner?.emailAddress?.address ?? "Unknown",
                isDefault: calendar.isDefaultCalendar ?? false,
                canEdit: calendar.canEdit ?? false
            )
        }
    }
}

// Shadow block ID mapping (Core Data)
actor ShadowBlockMapping {
    private static var mappings: [UUID: String] = [:]

    static func store(localId: UUID, graphId: String) {
        mappings[localId] = graphId
        // Also persist to Core Data for app restarts
    }

    static func getGraphId(for localId: UUID) -> String? {
        return mappings[localId]
    }

    static func remove(localId: UUID) {
        mappings.removeValue(forKey: localId)
    }
}

struct WorkCalendarInfo: Identifiable {
    let id: String
    let name: String
    let owner: String
    let isDefault: Bool
    let canEdit: Bool
}

enum ShadowSyncError: Error {
    case graphNotConfigured
    case insufficientPermissions
    case calendarNotFound
    case syncFailed(String)
    case mdmBlocked  // Enterprise MDM policy blocking Graph API
}

// MARK: - MDM Fallback Protocol

/// **PLATFORM SURVIVAL**: Graceful Degradation When Graph API Blocked
///
/// Enterprise MDM policies (Intune, Jamf) often restrict third-party apps
/// from accessing Microsoft Graph API's Calendars.ReadWrite scope.
/// This class provides a fallback strategy that:
/// 1. Detects MDM-induced API blocks (vs. user denial)
/// 2. Creates a local "Overlay Calendar" visible only to the user
/// 3. Warns user that colleagues won't see their training blocks
/// 4. Periodically re-probes in case policy changes

final class MDMFallbackHandler {

    enum MDMState: String, Codable {
        case unknown           // Haven't checked yet
        case graphAvailable    // Full Shadow Sync works
        case mdmBlocked        // Enterprise blocks Graph API
        case userDenied        // User declined permission (different UX)
    }

    private(set) var currentState: MDMState = .unknown
    private let keychain = KeychainWrapper.standard

    // MARK: - Detection

    /// Probe Graph API availability on first Shadow Sync setup attempt
    func detectMDMRestriction() async -> MDMState {
        // Check for cached state (don't re-probe every launch)
        if let cached = getCachedState(), !shouldReprobe() {
            self.currentState = cached
            return cached
        }

        do {
            // Try to fetch calendar list - lightweight probe
            guard let client = MSGraphClient.shared else {
                return cacheAndReturn(.graphAvailable) // No Graph SDK = not applicable
            }

            let _ = try await client.getCalendars()
            return cacheAndReturn(.graphAvailable)

        } catch let error as NSError {
            // Distinguish MDM block from other failures
            if isMDMBlockError(error) {
                return cacheAndReturn(.mdmBlocked)
            } else if isUserDeniedError(error) {
                return cacheAndReturn(.userDenied)
            }
            // Transient network error - don't cache
            return .unknown
        }
    }

    /// MDM blocks return specific error codes/domains
    private func isMDMBlockError(_ error: NSError) -> Bool {
        // Azure AD Conditional Access / Intune policy block indicators:
        // - AADSTS53000: Access blocked by Conditional Access policies
        // - AADSTS530003: Device not compliant
        // - AADSTS50076: MFA required but can't satisfy
        let mdmErrorCodes = ["AADSTS53000", "AADSTS530003", "AADSTS50076", "AADSTS53003"]
        let errorString = error.localizedDescription + (error.userInfo["error_description"] as? String ?? "")
        return mdmErrorCodes.contains { errorString.contains($0) }
    }

    private func isUserDeniedError(_ error: NSError) -> Bool {
        // User explicitly declined calendar permission
        return error.domain == "com.microsoft.identity" && error.code == -50005
    }

    // MARK: - Fallback to Local Overlay Calendar

    /// Create a local-only calendar as fallback when Graph blocked
    func createLocalOverlayCalendar() async throws -> String {
        let eventStore = EKEventStore()

        // Create new calendar in local account
        let overlay = EKCalendar(for: .event, eventStore: eventStore)
        overlay.title = "Vigor (Local Only)"
        overlay.cgColor = UIColor.systemBlue.cgColor

        // Use local source (not iCloud/Exchange)
        if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            overlay.source = localSource
        } else {
            throw ShadowSyncError.syncFailed("No local calendar source available")
        }

        try eventStore.saveCalendar(overlay, commit: true)

        // Store overlay calendar ID
        UserDefaults.standard.set(overlay.calendarIdentifier, forKey: "vigor_overlay_calendar_id")

        return overlay.calendarIdentifier
    }

    /// Show appropriate warning based on MDM state
    func getWarningMessage() -> String? {
        switch currentState {
        case .mdmBlocked:
            return """
            Your organization's security policy prevents Vigor from \
            syncing to your work calendar. Training blocks will appear \
            in a local "Vigor" calendar that only you can see. \
            Your colleagues won't be able to see when you're busy.
            """
        case .userDenied:
            return """
            Calendar sync is disabled. Enable it in Settings → Privacy → \
            Calendars to let colleagues see when you're busy.
            """
        default:
            return nil
        }
    }

    // MARK: - Periodic Re-probe (Policy May Change)

    /// Re-check MDM state weekly in case policy changes
    private func shouldReprobe() -> Bool {
        guard let lastProbe = UserDefaults.standard.object(forKey: "vigor_mdm_last_probe") as? Date else {
            return true
        }
        let weekAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        return lastProbe < weekAgo
    }

    private func cacheAndReturn(_ state: MDMState) -> MDMState {
        self.currentState = state
        UserDefaults.standard.set(state.rawValue, forKey: "vigor_mdm_state")
        UserDefaults.standard.set(Date(), forKey: "vigor_mdm_last_probe")
        return state
    }

    private func getCachedState() -> MDMState? {
        guard let raw = UserDefaults.standard.string(forKey: "vigor_mdm_state") else { return nil }
        return MDMState(rawValue: raw)
    }
}

/// Extend CalendarShadowSync to use MDM fallback
extension CalendarShadowSync {

    /// Smart enable that handles MDM gracefully
    func enableWithMDMFallback() async throws {
        let mdmHandler = MDMFallbackHandler()
        let state = await mdmHandler.detectMDMRestriction()

        switch state {
        case .graphAvailable:
            // Normal path - full Shadow Sync
            let calendars = try await getWorkCalendars()
            if let defaultCal = calendars.first(where: { $0.isDefault }) {
                try await enableShadowSync(workCalendarId: defaultCal.id)
            }

        case .mdmBlocked:
            // Fallback to local overlay calendar
            let overlayId = try await mdmHandler.createLocalOverlayCalendar()
            UserDefaults.standard.set(true, forKey: "vigor_using_overlay_calendar")
            // Show warning to user
            NotificationCenter.default.post(
                name: .vigorMDMWarning,
                object: mdmHandler.getWarningMessage()
            )

        case .userDenied:
            // Different UX - direct user to Settings
            throw ShadowSyncError.insufficientPermissions

        case .unknown:
            // Network issue - try again later
            throw ShadowSyncError.syncFailed("Could not determine calendar access. Check connection.")
        }
    }
}

extension Notification.Name {
    static let vigorMDMWarning = Notification.Name("vigorMDMWarning")
}

// Microsoft Graph Client (stub - implementation in shared/graph.swift)
class MSGraphClient {
    static let shared: MSGraphClient? = nil  // Initialized with Azure AD config

    func hasCalendarWritePermission() async -> Bool { false }
    func createEvent(in calendarId: String, event: MSGraphEvent) async throws -> String { "" }
    func updateEvent(in calendarId: String, eventId: String, updates: [String: Any]) async throws { }
    func deleteEvent(in calendarId: String, eventId: String) async throws { }
    func getCalendars() async throws -> [MSGraphCalendar] { [] }
}

struct MSGraphEvent {
    let subject: String
    let start: MSDateTimeTimeZone
    let end: MSDateTimeTimeZone
    let showAs: ShowAs
    let sensitivity: Sensitivity
    let isReminderOn: Bool
    let categories: [String]

    enum ShowAs { case free, busy, tentative, oof, workingElsewhere }
    enum Sensitivity { case normal, personal, `private`, confidential }
}

struct MSDateTimeTimeZone {
    let dateTime: String
    let timeZone: String
}

struct MSGraphCalendar {
    let id: String
    let name: String
    let owner: EmailAddress?
    let isDefaultCalendar: Bool?
    let canEdit: Bool?

    struct EmailAddress {
        let address: String?
    }
}

// MARK: - Calendar Multiplexing (Corporate Resilience)

/// **CORPORATE HARDENING**: Calendar Multiplexing bypasses MDM write-permission blocks
///
/// Problem: Direct writes to Exchange via Graph API require tenant admin consent,
/// which enterprises block. Falling back to a local overlay calendar means colleagues
/// still book over training blocks.
///
/// Solution: Calendar Multiplexing
/// - READ from multiple calendars (Home, Work, Partner, Travel)
/// - WRITE to a dedicated "Vigor" calendar only
/// - User subscribes their work calendar to Vigor calendar via Exchange/Outlook
/// - This is a one-time setup that bypasses MDM because it's a calendar subscription,
///   not a third-party app write
///
/// Additionally: Detect when an assistant/delegate modifies events vs. the user directly.

final class CalendarMultiplexer {

    private let eventStore = EKEventStore()
    private var readCalendars: [CalendarSource] = []
    private var vigorCalendarId: String?

    struct CalendarSource: Codable {
        let id: String
        let name: String
        let type: CalendarType
        let isPrimary: Bool
    }

    enum CalendarType: String, Codable {
        case work           // Exchange/Outlook/Google Workspace
        case personal       // iCloud, Google personal
        case shared         // Shared team calendars (read-only)
        case partner        // Partner's calendar (read-only)
    }

    // MARK: - Setup

    /// Initialize multiplexer with user's calendar sources
    func configure(readFrom: [CalendarSource], vigorCalendarId: String) {
        self.readCalendars = readFrom
        self.vigorCalendarId = vigorCalendarId
        persistConfiguration()
    }

    /// Create the dedicated Vigor calendar (one-time setup)
    func createVigorCalendar() async throws -> String {
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = "Vigor Training"
        calendar.cgColor = UIColor.systemGreen.cgColor

        // Use iCloud source for maximum portability
        if let iCloudSource = eventStore.sources.first(where: {
            $0.sourceType == .calDAV && $0.title.contains("iCloud")
        }) {
            calendar.source = iCloudSource
        } else if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            calendar.source = localSource
        } else {
            throw CalendarMultiplexError.noCalendarSource
        }

        try eventStore.saveCalendar(calendar, commit: true)

        self.vigorCalendarId = calendar.calendarIdentifier
        UserDefaults.standard.set(calendar.calendarIdentifier, forKey: "vigor_calendar_id")

        return calendar.calendarIdentifier
    }

    // MARK: - Read Operations (Multi-Source)

    /// Find free time across ALL read calendars
    func findFreeBlocks(on date: Date, duration: TimeInterval) async -> [FreeBlock] {
        var allEvents: [EKEvent] = []

        // Aggregate events from all read calendars
        for source in readCalendars {
            guard let calendar = eventStore.calendar(withIdentifier: source.id) else { continue }

            let dayStart = Calendar.current.startOfDay(for: date)
            let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!

            let predicate = eventStore.predicateForEvents(
                withStart: dayStart,
                end: dayEnd,
                calendars: [calendar]
            )

            let events = eventStore.events(matching: predicate)
            allEvents.append(contentsOf: events)
        }

        // Find gaps that fit the required duration
        return calculateFreeBlocks(events: allEvents, date: date, minDuration: duration)
    }

    /// Check if a time slot conflicts with ANY read calendar
    func hasConflict(at startTime: Date, duration: TimeInterval) -> Bool {
        let endTime = startTime.addingTimeInterval(duration)

        for source in readCalendars {
            guard let calendar = eventStore.calendar(withIdentifier: source.id) else { continue }

            let predicate = eventStore.predicateForEvents(
                withStart: startTime,
                end: endTime,
                calendars: [calendar]
            )

            if !eventStore.events(matching: predicate).isEmpty {
                return true
            }
        }
        return false
    }

    // MARK: - Write Operations (Vigor Calendar Only)

    /// Create training block in Vigor calendar only
    func createTrainingBlock(_ block: TrainingBlock) async throws {
        guard let calendarId = vigorCalendarId,
              let calendar = eventStore.calendar(withIdentifier: calendarId) else {
            throw CalendarMultiplexError.vigorCalendarNotConfigured
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = block.displayTitle
        event.startDate = block.startDate
        event.endDate = block.startDate.addingTimeInterval(block.duration)
        event.notes = "Created by Vigor. Subscribe this calendar to your work calendar for visibility."

        try eventStore.save(event, span: .thisEvent, commit: true)

        // Store mapping for future operations
        await TrainingBlockMapping.store(blockId: block.id, eventId: event.eventIdentifier)
    }

    // MARK: - Helper

    private func calculateFreeBlocks(events: [EKEvent], date: Date, minDuration: TimeInterval) -> [FreeBlock] {
        // Implementation: Find gaps between events that meet minimum duration
        []
    }

    private func persistConfiguration() {
        if let data = try? JSONEncoder().encode(readCalendars) {
            UserDefaults.standard.set(data, forKey: "vigor_read_calendars")
        }
    }
}

enum CalendarMultiplexError: Error {
    case noCalendarSource
    case vigorCalendarNotConfigured
    case subscriptionFailed
}

struct FreeBlock {
    let start: Date
    let end: Date
    let duration: TimeInterval
    let quality: BlockQuality  // Morning, lunch, evening preference
}

enum BlockQuality: Double {
    case optimal = 1.0      // User's preferred time
    case good = 0.8         // Acceptable time
    case suboptimal = 0.5   // Not ideal but available
}

actor TrainingBlockMapping {
    private static var mappings: [UUID: String] = [:]

    static func store(blockId: UUID, eventId: String) {
        mappings[blockId] = eventId
    }

    static func getEventId(for blockId: UUID) -> String? {
        mappings[blockId]
    }
}

// MARK: - Delegate/Assistant Detection

/// **CORPORATE HARDENING**: Detect when events are modified by assistant vs. user
///
/// Problem: If Vigor creates a block and the CEO's assistant deletes it,
/// we shouldn't interpret that as "user rejected this time slot."
/// The assistant is cleaning up the calendar, not expressing preference.

extension CalendarMultiplexer {

    /// Check if an event modification was made by a delegate
    func wasModifiedByDelegate(eventId: String) async -> DelegateModification? {
        // Note: This requires Graph API for Exchange calendars
        // EventKit doesn't expose lastModifiedBy

        guard let client = MSGraphClient.shared else { return nil }

        do {
            let eventDetails = try await client.getEventDetails(eventId: eventId)

            // Check if modifier differs from owner
            if let modifier = eventDetails.lastModifiedBy?.emailAddress?.address,
               let owner = eventDetails.organizer?.emailAddress?.address,
               modifier.lowercased() != owner.lowercased() {
                return DelegateModification(
                    modifierEmail: modifier,
                    action: eventDetails.isCancelled ? .deleted : .modified,
                    timestamp: eventDetails.lastModifiedDateTime
                )
            }
        } catch {
            // Fail open - assume user modification
            return nil
        }

        return nil
    }

    /// Handle delegate-modified events differently
    func handleEventModification(eventId: String, modification: EventModification) async {
        // Check if this was a delegate action
        if let delegateAction = await wasModifiedByDelegate(eventId: eventId) {
            // Delegate action - treat as hard constraint, not preference signal
            switch delegateAction.action {
            case .deleted:
                // Assistant cleaned up - don't penalize this time slot
                await FeedbackEngine.shared.recordDelegateCleanup(eventId: eventId)
            case .modified:
                // Assistant moved the block - honor new time as constraint
                await FeedbackEngine.shared.recordDelegateReschedule(eventId: eventId)
            }
        } else {
            // User action - record as preference signal
            await FeedbackEngine.shared.recordUserModification(eventId: eventId, modification: modification)
        }
    }
}

struct DelegateModification {
    let modifierEmail: String
    let action: DelegateAction
    let timestamp: Date?

    enum DelegateAction {
        case deleted
        case modified
    }
}

enum EventModification {
    case deleted
    case moved(newStart: Date)
    case resized(newDuration: TimeInterval)
}

extension MSGraphClient {
    func getEventDetails(eventId: String) async throws -> MSGraphEventDetails {
        // Stub - fetch event with lastModifiedBy, organizer, etc.
        MSGraphEventDetails()
    }
}

struct MSGraphEventDetails {
    var lastModifiedBy: MSGraphEmailAddress?
    var organizer: MSGraphEmailAddress?
    var lastModifiedDateTime: Date?
    var isCancelled: Bool = false
}

struct MSGraphEmailAddress {
    var emailAddress: EmailAddressInfo?

    struct EmailAddressInfo {
        var address: String?
    }
}

struct TrainingBlock {
    let id: UUID
    let startDate: Date
    let duration: TimeInterval
    let type: BlockType
    var metadata: BlockMetadata

    var displayTitle: String {
        type.displayTitle
    }
}

enum BlockType: String, Codable {
    case trainingBlock = "training"
    case recoveryWalk = "recovery"
    case movementBreak = "movement"
    case heavyLifts = "heavy"
    case cardio = "cardio"

    var displayTitle: String {
        switch self {
        case .trainingBlock: return "Training Block"
        case .recoveryWalk: return "Recovery Walk"
        case .movementBreak: return "Movement Break"
        case .heavyLifts: return "Heavy Lifts"
        case .cardio: return "Cardio Session"
        }
    }

    var emoji: String {
        switch self {
        case .trainingBlock: return "🏋️"
        case .recoveryWalk: return "🚶"
        case .movementBreak: return "🧘"
        case .heavyLifts: return "💪"
        case .cardio: return "🏃"
        }
    }
}

struct BlockMetadata: Codable {
    var workoutPlanId: String?
    var estimatedCalories: Int?
    var muscleGroups: [String]?
    var equipment: [String]?
    var transformedFrom: BlockType?
    var transformReason: String?
    var confidence: Double?
}
```

### 2.7 Core ML Pattern Detection

```swift
// PatternDetector.swift
import CoreML
import CreateML

/// On-device pattern detection using Core ML
final class PatternDetector {

    // MARK: - Models (loaded from bundle or downloaded)
    private var sleepImpactModel: MLModel?
    private var skipPredictionModel: MLModel?
    private var recoveryModel: MLModel?

    // MARK: - Remote Configuration (externalized logic)
    private var config: GhostConfig

    init() {
        self.config = GhostConfigManager.shared.currentConfig
        loadModels()

        // Subscribe to config updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configDidUpdate),
            name: .ghostConfigUpdated,
            object: nil
        )
    }

    @objc private func configDidUpdate() {
        self.config = GhostConfigManager.shared.currentConfig
    }

    private func loadModels() {
        // Load bundled Core ML models
        // These are trained on anonymized aggregate data and distributed via Azure
        if let modelURL = Bundle.main.url(forResource: "SleepImpactClassifier", withExtension: "mlmodelc") {
            sleepImpactModel = try? MLModel(contentsOf: modelURL)
        }

        if let modelURL = Bundle.main.url(forResource: "SkipPredictor", withExtension: "mlmodelc") {
            skipPredictionModel = try? MLModel(contentsOf: modelURL)
        }

        if let modelURL = Bundle.main.url(forResource: "RecoveryAnalyzer", withExtension: "mlmodelc") {
            recoveryModel = try? MLModel(contentsOf: modelURL)
        }
    }

    // MARK: - Pattern Analysis

    /// Analyze sleep impact on workout performance
    func analyzeSleepImpact(phenome: Phenome) -> SleepImpactPattern? {
        let workoutsWithSleep = phenome.workoutHistory.compactMap { workout -> (workout: WorkoutRecord, sleep: SleepRecord)? in
            guard let sleep = phenome.sleepHistory.first(where: {
                Calendar.current.isDate($0.date, inSameDayAs: workout.date)
            }) else { return nil }
            return (workout, sleep)
        }

        guard workoutsWithSleep.count >= 30 else {
            return nil  // Not enough data
        }

        // Calculate correlation between sleep duration and workout performance
        let lowSleepWorkouts = workoutsWithSleep.filter { $0.sleep.totalAsleepHours < 6 }
        let normalSleepWorkouts = workoutsWithSleep.filter { $0.sleep.totalAsleepHours >= 6 }

        guard !lowSleepWorkouts.isEmpty && !normalSleepWorkouts.isEmpty else { return nil }

        let lowSleepAvgPerformance = lowSleepWorkouts.map(\.workout.perceivedIntensity).reduce(0, +) / Double(lowSleepWorkouts.count)
        let normalAvgPerformance = normalSleepWorkouts.map(\.workout.perceivedIntensity).reduce(0, +) / Double(normalSleepWorkouts.count)

        let impactPercent = ((lowSleepAvgPerformance - normalAvgPerformance) / normalAvgPerformance) * 100

        return SleepImpactPattern(
            sleepThresholdHours: 6.0,
            performanceImpactPercent: impactPercent,
            confidence: min(1.0, Double(workoutsWithSleep.count) / 60.0),
            dataPoints: workoutsWithSleep.count
        )
    }

    /// Predict skip probability for a given day
    func predictSkipProbability(
        sleepHours: Double,
        meetingCount: Int,
        backToBackHours: Int,
        isTravel: Bool,
        timeOfDay: Int,
        phenome: Phenome
    ) -> Double {

        var skipFactors: [Double] = []

        // Sleep factor
        if sleepHours < 5 {
            skipFactors.append(0.7)  // High skip risk
        } else if sleepHours < 6 {
            skipFactors.append(0.4)
        }

        // Meeting density factor
        if meetingCount > 6 {
            skipFactors.append(0.5)
        } else if meetingCount > 4 {
            skipFactors.append(0.3)
        }

        // Back-to-back meetings
        if backToBackHours > 3 {
            skipFactors.append(0.4)
        }

        // Travel
        if isTravel {
            skipFactors.append(0.6)
        }

        // Evening block (higher skip risk)
        if timeOfDay >= 19 {
            skipFactors.append(0.3)
        }

        // Combine factors (not additive, but compounding)
        if skipFactors.isEmpty {
            return 0.1  // Base skip rate
        }

        let combinedProbability = 1.0 - skipFactors.reduce(1.0) { $0 * (1.0 - $1) }
        return min(0.95, combinedProbability)
    }

    /// Calculate calendar density score
    func calculateDensity(events: [EKEvent]) -> CalendarDensity {
        let meetingCount = events.filter { !$0.isAllDay }.count

        // Calculate back-to-back hours
        var backToBackMinutes = 0
        let sortedEvents = events.filter { !$0.isAllDay }.sorted { $0.startDate < $1.startDate }

        for i in 0..<(sortedEvents.count - 1) {
            let gap = sortedEvents[i + 1].startDate.timeIntervalSince(sortedEvents[i].endDate)
            if gap < 900 {  // Less than 15 minutes
                backToBackMinutes += Int(sortedEvents[i].endDate.timeIntervalSince(sortedEvents[i].startDate) / 60)
            }
        }

        return CalendarDensity(
            meetingCount: meetingCount,
            backToBackMinutes: backToBackMinutes,
            hasEarlyMeeting: sortedEvents.first.map { Calendar.current.component(.hour, from: $0.startDate) < 9 } ?? false,
            hasLateMeeting: sortedEvents.last.map { Calendar.current.component(.hour, from: $0.endDate) > 18 } ?? false
        )
    }
}

struct CalendarDensity {
    let meetingCount: Int
    let backToBackMinutes: Int
    let hasEarlyMeeting: Bool
    let hasLateMeeting: Bool

    var stressLevel: StressLevel {
        if meetingCount > 6 || backToBackMinutes > 180 {
            return .high
        } else if meetingCount > 4 || backToBackMinutes > 90 {
            return .moderate
        } else {
            return .low
        }
    }
}

enum StressLevel {
    case low, moderate, high
}
```

### 2.8 Remote Configuration (Externalized Ghost Logic)

> **HARDENED**: Heuristic weights and thresholds are downloaded from Azure Blob Storage.
> This allows rapid iteration of Ghost behavior without App Store updates.

```swift
// GhostConfigManager.swift
import Foundation

/// Remote configuration for Ghost heuristics
/// Downloaded at app launch from Azure Blob Storage (vigorstorage)
final class GhostConfigManager: ObservableObject {

    static let shared = GhostConfigManager()

    @Published private(set) var currentConfig: GhostConfig
    private let configURL = URL(string: "https://vigorstorage.blob.core.windows.net/config/ghost-config.json")!
    private let cacheKey = "cached_ghost_config"

    private init() {
        // Load cached config immediately (offline-first)
        self.currentConfig = Self.loadCachedConfig() ?? GhostConfig.defaults
        // Fetch latest in background
        Task { await refreshConfig() }
    }

    // MARK: - Config Refresh

    func refreshConfig() async {
        do {
            let (data, response) = try await URLSession.shared.data(from: configURL)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return  // Keep cached config on error
            }

            let newConfig = try JSONDecoder().decode(GhostConfig.self, from: data)

            // Validate config before applying
            guard newConfig.isValid else {
                return  // Reject malformed config
            }

            // Update atomically
            await MainActor.run {
                self.currentConfig = newConfig
                NotificationCenter.default.post(name: .ghostConfigUpdated, object: nil)
            }

            // Cache for offline use
            UserDefaults.standard.set(data, forKey: cacheKey)

        } catch {
            // Silent failure - continue with cached config
        }
    }

    private static func loadCachedConfig() -> GhostConfig? {
        guard let data = UserDefaults.standard.data(forKey: "cached_ghost_config") else {
            return nil
        }
        return try? JSONDecoder().decode(GhostConfig.self, from: data)
    }
}

extension Notification.Name {
    static let ghostConfigUpdated = Notification.Name("ghostConfigUpdated")
}

/// Downloadable Ghost configuration
/// Stored in Azure Blob: vigorstorage/config/ghost-config.json
struct GhostConfig: Codable {

    let version: String
    let updatedAt: Date

    // MARK: - Trust State Machine Thresholds
    struct TrustThresholds: Codable {
        let observerToSchedulerDays: Int           // Default: 7
        let observerToSchedulerAccepted: Int       // Default: 3
        let schedulerToAutoSchedulerDays: Int      // Default: 14
        let schedulerToAutoSchedulerWorkouts: Int  // Default: 5
        let autoSchedulerToTransformerDays: Int    // Default: 30
        let autoSchedulerToTransformerScore: Double // Default: 0.80
        let transformerToFullGhostDays: Int        // Default: 60
        let transformerToFullGhostScore: Double    // Default: 0.90
    }
    let trustThresholds: TrustThresholds

    // MARK: - Skip Prediction Weights
    struct SkipPredictionWeights: Codable {
        let sleepWeight: Double           // How much sleep impacts skip prediction
        let meetingDensityWeight: Double  // Impact of busy calendar
        let backToBackWeight: Double      // Back-to-back meeting penalty
        let travelDayWeight: Double       // Travel detection weight
        let eveningBlockPenalty: Double   // Evening workout skip risk
        let baselineSkipRate: Double      // Default skip probability
    }
    let skipPrediction: SkipPredictionWeights

    // MARK: - Recovery Analyzer Settings
    struct RecoverySettings: Codable {
        let hrvLowThreshold: Double       // Below this = needs recovery
        let hrvHighThreshold: Double      // Above this = fully recovered
        let sleepDebtRecoveryDays: Int    // Days to consider for sleep debt
        let strainAccumulationWindow: Int // Days to track strain
    }
    let recovery: RecoverySettings

    // MARK: - Calendar Scheduling Rules
    struct SchedulingRules: Codable {
        let minBlockDurationMinutes: Int  // Minimum viable workout
        let maxBlocksPerDay: Int          // Don't over-schedule
        let preferredMorningHour: Int     // Start of morning window
        let preferredEveningHour: Int     // End of evening window
        let lunchBlockStart: Int          // Lunch window start
        let lunchBlockEnd: Int            // Lunch window end
        let weekendMorningBuffer: Int     // Don't schedule before X on weekends
    }
    let scheduling: SchedulingRules

    // MARK: - Notification Throttling
    struct NotificationRules: Codable {
        let maxNotificationsPerDay: Int   // Hard cap
        let quietHoursStart: Int          // Don't notify after
        let quietHoursEnd: Int            // Don't notify before
        let minTimeBetweenNotifications: Int // Minutes between notifications
    }
    let notifications: NotificationRules

    // MARK: - Validation
    var isValid: Bool {
        // Ensure thresholds are sensible
        trustThresholds.observerToSchedulerDays > 0 &&
        trustThresholds.observerToSchedulerDays <= 30 &&
        skipPrediction.sleepWeight >= 0 &&
        skipPrediction.sleepWeight <= 2.0 &&
        recovery.hrvLowThreshold > 0 &&
        recovery.hrvLowThreshold < recovery.hrvHighThreshold
    }

    // MARK: - Bundled Defaults
    static let defaults = GhostConfig(
        version: "1.0.0",
        updatedAt: Date(),
        trustThresholds: TrustThresholds(
            observerToSchedulerDays: 7,
            observerToSchedulerAccepted: 3,
            schedulerToAutoSchedulerDays: 14,
            schedulerToAutoSchedulerWorkouts: 5,
            autoSchedulerToTransformerDays: 30,
            autoSchedulerToTransformerScore: 0.80,
            transformerToFullGhostDays: 60,
            transformerToFullGhostScore: 0.90
        ),
        skipPrediction: SkipPredictionWeights(
            sleepWeight: 0.3,
            meetingDensityWeight: 0.25,
            backToBackWeight: 0.2,
            travelDayWeight: 0.4,
            eveningBlockPenalty: 0.15,
            baselineSkipRate: 0.1
        ),
        recovery: RecoverySettings(
            hrvLowThreshold: 30.0,
            hrvHighThreshold: 60.0,
            sleepDebtRecoveryDays: 7,
            strainAccumulationWindow: 14
        ),
        scheduling: SchedulingRules(
            minBlockDurationMinutes: 20,
            maxBlocksPerDay: 2,
            preferredMorningHour: 6,
            preferredEveningHour: 21,
            lunchBlockStart: 12,
            lunchBlockEnd: 13,
            weekendMorningBuffer: 9
        ),
        notifications: NotificationRules(
            maxNotificationsPerDay: 1,
            quietHoursStart: 22,
            quietHoursEnd: 7,
            minTimeBetweenNotifications: 60
        )
    )
}
```

**Azure Blob Storage Config File** (`vigorstorage/config/ghost-config.json`):

```json
{
  "version": "1.0.0",
  "updatedAt": "2026-01-26T00:00:00Z",
  "trustThresholds": {
    "observerToSchedulerDays": 7,
    "observerToSchedulerAccepted": 3,
    "schedulerToAutoSchedulerDays": 14,
    "schedulerToAutoSchedulerWorkouts": 5,
    "autoSchedulerToTransformerDays": 30,
    "autoSchedulerToTransformerScore": 0.8,
    "transformerToFullGhostDays": 60,
    "transformerToFullGhostScore": 0.9
  },
  "skipPrediction": {
    "sleepWeight": 0.3,
    "meetingDensityWeight": 0.25,
    "backToBackWeight": 0.2,
    "travelDayWeight": 0.4,
    "eveningBlockPenalty": 0.15,
    "baselineSkipRate": 0.1
  },
  "recovery": {
    "hrvLowThreshold": 30.0,
    "hrvHighThreshold": 60.0,
    "sleepDebtRecoveryDays": 7,
    "strainAccumulationWindow": 14
  },
  "scheduling": {
    "minBlockDurationMinutes": 20,
    "maxBlocksPerDay": 2,
    "preferredMorningHour": 6,
    "preferredEveningHour": 21,
    "lunchBlockStart": 12,
    "lunchBlockEnd": 13,
    "weekendMorningBuffer": 9
  },
  "notifications": {
    "maxNotificationsPerDay": 1,
    "quietHoursStart": 22,
    "quietHoursEnd": 7,
    "minTimeBetweenNotifications": 60
  }
}
```

---

### 2.9 Silent Push + Complication-Driven Wakes (Invisibility Paradox Solution)

> **CRITICAL PLATFORM SURVIVAL**: iOS aggressively throttles BGTaskScheduler for apps users
> don't actively engage with. The "Invisibility Paradox" is: Vigor's product success (user opens
> app <3 times/week) causes iOS to stop granting background execution time.

**The Problem:**

- iOS tracks "app engagement" to decide background task budget
- Apps users don't open for 4+ days get minimal/no BGTask executions
- Vigor's ghost design means users rarely open the app
- Result: Ghost stops working despite healthy phone/watch

**The Solution:**
Two orthogonal strategies that bypass engagement-based throttling:

#### Strategy 1: Server-Side Silent Push Notifications

Silent Push notifications (`content-available: 1`) are exempt from BGTaskScheduler
engagement throttling. The server can wake the app externally.

```swift
/// Azure Functions sends silent push at strategic times:
/// - 5:55 AM: Pre-morning cycle wake
/// - 2 hours before scheduled workout: Fresh context
/// - After major calendar change detection

final class SilentPushReceiver {

    /// Called from AppDelegate's didReceiveRemoteNotification
    func handleSilentPush(_ userInfo: [AnyHashable: Any],
                          completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        guard let pushType = userInfo["vigor_push_type"] as? String else {
            completionHandler(.noData)
            return
        }

        Task {
            do {
                switch pushType {
                case "morning_wake":
                    // Execute morning cycle
                    try await MorningCycleEngine.shared.executeIfNeeded()
                    completionHandler(.newData)

                case "pre_workout_refresh":
                    // Refresh recovery context before workout
                    try await RecoveryAnalyzer.shared.refreshHealthKit()
                    completionHandler(.newData)

                case "calendar_sync":
                    // Calendar changed externally, re-sync
                    try await CalendarScheduler.shared.syncFromCalendar()
                    completionHandler(.newData)

                case "config_update":
                    // New Ghost config available
                    try await GhostConfigManager.shared.fetchLatestConfig()
                    completionHandler(.newData)

                default:
                    completionHandler(.noData)
                }
            } catch {
                AppLogger.shared.error("Silent push failed: \(error)")
                completionHandler(.failed)
            }
        }
    }
}

/// Azure Function that sends silent push (Python)
/// Triggered by Timer at 5:55 AM in each user's timezone
/// See: functions-modernized/morning_wake_push.py
```

**Azure Functions Silent Push Implementation** (`morning_wake_push.py`):

```python
import azure.functions as func
from azure.cosmos import CosmosClient
from datetime import datetime, timezone, timedelta
import httpx
import json

# Timer trigger: Every 5 minutes (checks which timezones need wake)
@app.timer_trigger(schedule="0 */5 * * * *", arg_name="timer")
async def morning_wake_push(timer: func.TimerRequest):
    """
    Send silent push to users whose timezone is approaching 5:55 AM.
    This wakes their app before the 6 AM Morning Cycle.
    """
    now = datetime.now(timezone.utc)

    # Query users where local time is 5:55 AM
    users = await get_users_at_local_time(target_hour=5, target_minute=55)

    for user in users:
        if user.get("apns_token"):
            await send_silent_push(
                token=user["apns_token"],
                payload={
                    "aps": {
                        "content-available": 1  # Silent push flag
                    },
                    "vigor_push_type": "morning_wake",
                    "user_id": user["id"]
                }
            )

async def send_silent_push(token: str, payload: dict):
    """Send via APNs HTTP/2 API"""
    async with httpx.AsyncClient(http2=True) as client:
        await client.post(
            f"https://api.push.apple.com/3/device/{token}",
            json=payload,
            headers={
                "apns-push-type": "background",
                "apns-priority": "5",  # Low priority = silent
                "apns-topic": "com.vigor.app"
            }
        )
```

#### Strategy 2: Complication-Driven Wakes (watchOS)

Apple Watch complications get guaranteed timeline refresh opportunities. By requesting
a timeline refresh when Morning Cycle needs data, we get background execution.

```swift
/// Watch complication that displays recovery score
/// Key insight: Requesting timeline refresh grants background execution

final class RecoveryComplicationDataSource: NSObject, CLKComplicationDataSource {

    // MARK: - Timeline Configuration

    func getTimelineEndDate(for complication: CLKComplication,
                           withHandler handler: @escaping (Date?) -> Void) {
        // Request timeline extend to cover next morning cycle
        let tomorrow6AM = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 6, minute: 0),
            matchingPolicy: .nextTime
        )!
        handler(tomorrow6AM.addingTimeInterval(3600)) // 7 AM tomorrow
    }

    func getTimelineEntries(for complication: CLKComplication,
                            after date: Date,
                            limit: Int,
                            withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {

        // THIS IS THE KEY: When we provide timeline entries, we get execution time
        Task {
            // Refresh recovery data while we have execution time
            let recoveryScore = await WatchRecoveryEngine.shared.calculateCurrentScore()

            // Create timeline entry that will trigger refresh at 6 AM
            let morningRefreshDate = Calendar.current.nextDate(
                after: Date(),
                matching: DateComponents(hour: 6, minute: 0),
                matchingPolicy: .nextTime
            )!

            let template = createTemplate(score: recoveryScore, for: complication.family)
            let entry = CLKComplicationTimelineEntry(date: morningRefreshDate, complicationTemplate: template)

            handler([entry])

            // Use this background time to run Morning Cycle
            await WatchMorningOrchestrator.shared.executeIfNeeded()
        }
    }

    // MARK: - Complication Templates

    private func createTemplate(score: Int, for family: CLKComplicationFamily) -> CLKComplicationTemplate {
        switch family {
        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularClosedGaugeText(
                gaugeProvider: CLKSimpleGaugeProvider(
                    style: .fill,
                    gaugeColor: scoreColor(score),
                    fillFraction: Float(score) / 100.0
                ),
                centerTextProvider: CLKSimpleTextProvider(text: "\(score)")
            )
        case .modularSmall:
            return CLKComplicationTemplateModularSmallRingText(
                textProvider: CLKSimpleTextProvider(text: "\(score)"),
                fillFraction: Float(score) / 100.0,
                ringStyle: .closed
            )
        default:
            return CLKComplicationTemplateGraphicCornerGaugeText(
                gaugeProvider: CLKSimpleGaugeProvider(
                    style: .fill,
                    gaugeColor: scoreColor(score),
                    fillFraction: Float(score) / 100.0
                ),
                outerTextProvider: CLKSimpleTextProvider(text: "Recovery")
            )
        }
    }

    private func scoreColor(_ score: Int) -> UIColor {
        switch score {
        case 80...100: return .green
        case 50..<80: return .yellow
        default: return .red
        }
    }

    // MARK: - Proactive Refresh Request

    /// Request complication refresh to gain background execution
    /// Called from BGTaskScheduler when we need to ensure Morning Cycle runs
    static func requestRefresh() {
        let server = CLKComplicationServer.sharedInstance()
        for complication in server.activeComplications ?? [] {
            server.reloadTimeline(for: complication)
        }
    }
}
```

**Combined Strategy: Redundant Wake Sources**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    INVISIBILITY PARADOX MITIGATION                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  5:55 AM ──► Azure Timer Trigger ──► Silent Push ──► iPhone wakes ───┐     │
│                                                                        │     │
│  6:00 AM ──► Complication Timeline ──► Watch wakes ──────────────────├──►   │
│                                                                        │     │
│  6:00 AM ──► BGAppRefreshTask ──► (May be throttled) ───────────────┘     │
│                                                                             │
│                    ▼ MORNING CYCLE EXECUTES ▼                               │
│                                                                             │
│  All three paths attempt Morning Cycle.                                     │
│  MorningCycleEngine.executeIfNeeded() is idempotent.                        │
│  At least one will succeed even if iOS throttles BGTask.                    │
│                                                                             │
│  Metrics tracked:                                                           │
│  - Which wake source succeeded first                                        │
│  - BGTask throttle rate by user engagement tier                             │
│  - Silent push delivery latency                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.10 Three-Layer Health Data Model (Platform Foundation)

> **PLATFORM THINKING**: Health value comes from trends, volatility, contextual deltas, and
> confidence intervals—not latest values. A flat data model kills future insight quality.
> This three-layer architecture enables versioned recomputation and explainable insights.

**The Problem:**

- Flat health data models treat "latest value" as truth
- No separation between raw signal, derived calculation, and interpretation
- Changing formulas requires backfill nightmares
- Users ask "why did my score change?" and we can't answer

**The Solution:**
Three distinct layers with clear contracts:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    THREE-LAYER HEALTH DATA MODEL                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Layer 1: RAW SIGNAL (Immutable, Append-Only)                               │
│  ├── Source: HealthKit, sensors, calendar                                   │
│  ├── Rule: NEVER modified after write                                       │
│  ├── Examples: HRV samples, sleep stages, workout sessions                  │
│  └── Storage: Core Data with append-only policy                             │
│                           │                                                 │
│                           ▼                                                 │
│  Layer 2: DERIVED METRIC (Versioned, Recomputable)                          │
│  ├── Source: Computed from Raw Signals                                      │
│  ├── Rule: ALWAYS recomputable from Layer 1                                 │
│  ├── Examples: Recovery Score, Sleep Debt, Strain Index                     │
│  └── Storage: Core Data with version + provenance                           │
│                           │                                                 │
│                           ▼                                                 │
│  Layer 3: INSIGHT (Ephemeral, Explainable)                                  │
│  ├── Source: Interpreted from Derived Metrics                               │
│  ├── Rule: DISPOSABLE, can regenerate anytime                               │
│  ├── Examples: "Skip today", "Lower intensity", "Rest recommended"          │
│  └── Storage: Cached only, not persisted long-term                          │
│                                                                             │
│  KEY INVARIANT: Deleting Layer 3 data loses nothing.                        │
│  KEY INVARIANT: Deleting Layer 2 data is recoverable from Layer 1.          │
│  KEY INVARIANT: Layer 1 is the single source of truth.                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Layer 1: Raw Signal Store

```swift
/// Layer 1: Immutable raw health signals
/// RULE: Append-only. Never modify. Never delete (except for GDPR).

struct RawHealthSignal: Identifiable {
    let id: UUID
    let signalType: SignalType
    let timestamp: Date
    let value: Double
    let unit: String
    let source: SignalSource
    let metadata: [String: Any]?

    // Immutability enforced at storage layer
    var isImmutable: Bool { true }
}

enum SignalType: String, Codable {
    // Vitals
    case heartRate
    case heartRateVariability
    case restingHeartRate
    case bloodOxygen
    case respiratoryRate

    // Sleep
    case sleepStage          // awake, rem, core, deep
    case timeInBed
    case sleepDuration

    // Activity
    case activeEnergyBurned
    case stepCount
    case distanceWalkingRunning
    case exerciseMinutes

    // Workouts
    case workoutSession      // Full HKWorkout data
    case workoutHeartRateSamples

    // Calendar
    case calendarEvent       // Meeting density signal
    case travelDetected
}

enum SignalSource: String, Codable {
    case healthKit
    case appleWatch
    case manualEntry
    case calendar
    case inferred
}

/// Append-only storage for raw signals
actor RawSignalStore {

    private let persistentContainer: NSPersistentContainer

    /// Append new signal - NEVER updates existing
    func append(_ signal: RawHealthSignal) async throws {
        let context = persistentContainer.newBackgroundContext()
        context.perform {
            let entity = RawSignalEntity(context: context)
            entity.id = signal.id
            entity.signalType = signal.signalType.rawValue
            entity.timestamp = signal.timestamp
            entity.value = signal.value
            entity.unit = signal.unit
            entity.source = signal.source.rawValue
            entity.createdAt = Date()
            // No update method exists by design
            try? context.save()
        }
    }

    /// Query signals for metric computation
    func query(
        type: SignalType,
        from: Date,
        to: Date
    ) async -> [RawHealthSignal] {
        // Fetch from Core Data with date range predicate
        []
    }

    /// Bulk import from HealthKit (Day 1)
    func bulkImport(_ signals: [RawHealthSignal]) async throws {
        // Batch insert with duplicate detection
    }
}
```

#### Layer 2: Derived Metric Engine

```swift
/// Layer 2: Versioned, recomputable derived metrics
/// RULE: Always store version + inputs + computation timestamp

struct DerivedMetric: Identifiable, Codable {
    let id: UUID
    let metricType: MetricType
    let value: Double
    let confidence: Double           // 0.0-1.0

    // Versioning & Provenance
    let version: MetricVersion
    let computedAt: Date
    let inputWindow: DateInterval    // Which raw signals were used
    let inputDigest: String          // Hash of input signals (for cache invalidation)

    // Explanation (stored, not displayed yet)
    let explanation: MetricExplanation
}

enum MetricType: String, Codable {
    case recoveryScore       // 0-100
    case sleepDebt           // Hours owed
    case strainIndex         // Cumulative load
    case readinessScore      // Combined readiness
    case skipProbability     // Likelihood to skip today
    case optimalWorkoutTime  // Best time today
    case weeklyConsistency   // Pattern adherence
}

/// Metric versioning enables silent recomputation
struct MetricVersion: Codable, Comparable {
    let major: Int           // Breaking formula change
    let minor: Int           // Coefficient tuning
    let patch: Int           // Bug fix

    var string: String { "\(major).\(minor).\(patch)" }

    static func < (lhs: MetricVersion, rhs: MetricVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }

    static let current = MetricVersion(major: 1, minor: 0, patch: 0)
}

/// Stored explanation for every metric (enables "why did this change?")
struct MetricExplanation: Codable {
    let primaryDrivers: [Driver]     // Top 3 factors
    let inputSummary: InputSummary
    let confidenceFactors: [String]

    struct Driver: Codable {
        let factor: String           // e.g., "HRV", "Sleep Duration"
        let contribution: Double     // e.g., 0.35 (35% of score)
        let direction: Direction     // positive/negative impact
        let rawValue: Double         // Actual value used
        let comparedTo: String       // "baseline", "yesterday", "7-day avg"
    }

    enum Direction: String, Codable {
        case positive    // Helped the score
        case negative    // Hurt the score
        case neutral
    }

    struct InputSummary: Codable {
        let signalCount: Int
        let timeWindowHours: Int
        let oldestSignal: Date
        let newestSignal: Date
    }
}

/// Engine that computes metrics with full provenance
actor DerivedMetricEngine {

    private let rawSignalStore: RawSignalStore
    private let metricStore: MetricStore

    // MARK: - Compute with Provenance

    /// Compute a metric and store with full lineage
    func compute(_ type: MetricType, for date: Date) async -> DerivedMetric {
        let window = computationWindow(for: type, targetDate: date)
        let signals = await rawSignalStore.query(
            type: inputSignalTypes(for: type).first!,
            from: window.start,
            to: window.end
        )

        let (value, explanation) = calculate(type, from: signals)

        let metric = DerivedMetric(
            id: UUID(),
            metricType: type,
            value: value,
            confidence: calculateConfidence(signals),
            version: MetricVersion.current,
            computedAt: Date(),
            inputWindow: window,
            inputDigest: computeDigest(signals),
            explanation: explanation
        )

        await metricStore.store(metric)
        return metric
    }

    /// Recompute all metrics for a date range (silent backfill)
    func recompute(
        type: MetricType,
        from: Date,
        to: Date,
        newVersion: MetricVersion
    ) async {
        // Used when formula changes - reprocesses historical data
        var current = from
        while current <= to {
            let _ = await compute(type, for: current)
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }
    }

    // MARK: - Input Dependencies

    /// Define which raw signals feed each metric
    private func inputSignalTypes(for metric: MetricType) -> [SignalType] {
        switch metric {
        case .recoveryScore:
            return [.heartRateVariability, .sleepDuration, .restingHeartRate]
        case .sleepDebt:
            return [.sleepDuration, .timeInBed]
        case .strainIndex:
            return [.activeEnergyBurned, .exerciseMinutes, .workoutSession]
        case .readinessScore:
            return [.heartRateVariability, .sleepDuration, .restingHeartRate, .activeEnergyBurned]
        case .skipProbability:
            return [.sleepDuration, .calendarEvent, .workoutSession]
        case .optimalWorkoutTime:
            return [.calendarEvent, .heartRateVariability]
        case .weeklyConsistency:
            return [.workoutSession]
        }
    }

    private func computationWindow(for type: MetricType, targetDate: Date) -> DateInterval {
        let calendar = Calendar.current
        switch type {
        case .recoveryScore, .readinessScore:
            // Last 24 hours
            let start = calendar.date(byAdding: .hour, value: -24, to: targetDate)!
            return DateInterval(start: start, end: targetDate)
        case .sleepDebt:
            // Last 7 days
            let start = calendar.date(byAdding: .day, value: -7, to: targetDate)!
            return DateInterval(start: start, end: targetDate)
        case .strainIndex:
            // Last 14 days
            let start = calendar.date(byAdding: .day, value: -14, to: targetDate)!
            return DateInterval(start: start, end: targetDate)
        case .weeklyConsistency:
            // Last 4 weeks
            let start = calendar.date(byAdding: .day, value: -28, to: targetDate)!
            return DateInterval(start: start, end: targetDate)
        default:
            // Default 24 hours
            let start = calendar.date(byAdding: .hour, value: -24, to: targetDate)!
            return DateInterval(start: start, end: targetDate)
        }
    }
}
```

#### Layer 3: Ephemeral Insight Generator

```swift
/// Layer 3: Disposable insights derived from metrics
/// RULE: Never persisted long-term. Regenerate on demand.

struct Insight: Identifiable {
    let id: UUID
    let type: InsightType
    let headline: String
    let body: String?
    let action: InsightAction?
    let confidence: Double
    let generatedAt: Date
    let expiresAt: Date              // Insights are time-bound

    // Full explanation chain (stored for debugging)
    let derivation: InsightDerivation
}

enum InsightType: String, Codable {
    case morningRecommendation       // "Good recovery - full workout today"
    case skipSuggestion              // "Low energy detected - rest day?"
    case intensityAdjustment         // "Dial back today"
    case scheduleChange              // "Moved workout to 6 PM"
    case streakCelebration           // "7 days in a row!"
    case recoveryAlert               // "Recovery dipping - extra rest"
    case progressMilestone           // "VO2 max improved"
}

enum InsightAction: Codable {
    case confirm                     // User confirms recommendation
    case dismiss                     // User dismisses
    case modify(String)              // User modifies
    case snooze(TimeInterval)        // User delays decision
}

/// Full derivation chain for explainability
struct InsightDerivation: Codable {
    let inputMetrics: [MetricReference]
    let rule: String                  // Which rule triggered this
    let thresholdsUsed: [String: Double]
    let alternativeConsidered: String? // What else could have been suggested

    struct MetricReference: Codable {
        let metricType: String
        let value: Double
        let version: String
        let computedAt: Date
    }
}

/// Insight generator - fully stateless
struct InsightGenerator {

    private let metricEngine: DerivedMetricEngine
    private let config: GhostConfig

    /// Generate insights for right now (never cached)
    func generateCurrentInsights() async -> [Insight] {
        let recovery = await metricEngine.getLatest(.recoveryScore)
        let sleepDebt = await metricEngine.getLatest(.sleepDebt)
        let skipProb = await metricEngine.getLatest(.skipProbability)

        var insights: [Insight] = []

        // Morning recommendation
        if let recommendation = generateMorningRecommendation(
            recovery: recovery,
            sleepDebt: sleepDebt,
            skipProbability: skipProb
        ) {
            insights.append(recommendation)
        }

        // Recovery alert
        if let alert = generateRecoveryAlert(recovery: recovery, sleepDebt: sleepDebt) {
            insights.append(alert)
        }

        return insights
    }

    private func generateMorningRecommendation(
        recovery: DerivedMetric?,
        sleepDebt: DerivedMetric?,
        skipProbability: DerivedMetric?
    ) -> Insight? {
        guard let recovery = recovery else { return nil }

        let derivation = InsightDerivation(
            inputMetrics: [
                .init(metricType: "recoveryScore", value: recovery.value,
                      version: recovery.version.string, computedAt: recovery.computedAt)
            ],
            rule: "morning_recommendation_v1",
            thresholdsUsed: ["lowRecovery": 40, "highRecovery": 80],
            alternativeConsidered: recovery.value < 40 ? "Suggest rest day" : nil
        )

        if recovery.value >= 80 {
            return Insight(
                id: UUID(),
                type: .morningRecommendation,
                headline: "Great recovery! Full workout today.",
                body: "Your HRV and sleep indicate you're well-rested.",
                action: .confirm,
                confidence: recovery.confidence,
                generatedAt: Date(),
                expiresAt: Date().addingTimeInterval(12 * 3600),
                derivation: derivation
            )
        } else if recovery.value < 40 {
            return Insight(
                id: UUID(),
                type: .skipSuggestion,
                headline: "Low recovery detected",
                body: "Consider a rest day or light movement only.",
                action: .confirm,
                confidence: recovery.confidence,
                generatedAt: Date(),
                expiresAt: Date().addingTimeInterval(12 * 3600),
                derivation: derivation
            )
        }
        return nil
    }
}
```

#### Insight TTL & Lifecycle Management

> **OPERATIONAL HARDENING**: Insights are ephemeral by design. Without TTL policies,
> Core Data/CloudKit will bloat rapidly. Insights older than 30 days should be
> deleted or archived to cold storage.

```swift
/// Insight lifecycle manager - enforces TTL policies
actor InsightLifecycleManager {

    private let insightStore: InsightStore
    private let archiveStore: InsightArchiveStore

    /// TTL policies by insight type
    private let ttlPolicies: [InsightType: TimeInterval] = [
        .morningRecommendation: 24 * 3600,      // 24 hours (daily refresh)
        .skipSuggestion: 24 * 3600,             // 24 hours
        .intensityAdjustment: 7 * 24 * 3600,    // 7 days
        .scheduleChange: 48 * 3600,             // 48 hours
        .streakCelebration: 30 * 24 * 3600,     // 30 days (nice to keep)
        .recoveryAlert: 7 * 24 * 3600,          // 7 days
        .progressMilestone: 90 * 24 * 3600      // 90 days (achievements)
    ]

    /// Default TTL for any insight type not explicitly defined
    private let defaultTTL: TimeInterval = 30 * 24 * 3600  // 30 days

    // MARK: - TTL Enforcement

    /// Run daily (overnight batch job) to clean expired insights
    func enforceInsightTTL() async {
        let now = Date()

        for (type, ttl) in ttlPolicies {
            let cutoffDate = now.addingTimeInterval(-ttl)
            let expiredInsights = await insightStore.fetchInsights(
                ofType: type,
                olderThan: cutoffDate
            )

            for insight in expiredInsights {
                // Archive before delete (for analytics if needed)
                if type == .progressMilestone || type == .streakCelebration {
                    await archiveStore.archive(insight)
                }
                await insightStore.delete(insight)
            }
        }

        // Log cleanup metrics
        AppLogger.shared.info("Insight TTL enforcement completed")
    }

    /// Called when storage approaches limit
    func emergencyCleanup(keepDays: Int = 7) async {
        let cutoffDate = Date().addingTimeInterval(-Double(keepDays) * 24 * 3600)
        await insightStore.deleteAllOlderThan(cutoffDate)
    }
}

/// Cold storage for archived insights (optional analytics use)
actor InsightArchiveStore {
    func archive(_ insight: Insight) async {
        // Compress and store to Azure Blob or local archive
        // Only keep essential fields: type, date, headline
    }
}
```

---

### 2.11 Versioned Metric Computation & Recomputation Strategy

> **PLATFORM THINKING**: You WILL change formulas. You WILL fix bugs. Users WILL ask
> "why did my score change?" The system must answer that without losing trust.

#### Metric Registry

```swift
/// Central registry of all metric computations
/// Enables A/B testing, versioned rollout, and retroactive fixes

struct MetricRegistry {

    /// All registered metric definitions
    static let definitions: [MetricType: MetricDefinition] = [
        .recoveryScore: MetricDefinition(
            type: .recoveryScore,
            currentVersion: MetricVersion(major: 1, minor: 2, patch: 0),
            inputs: [.heartRateVariability, .sleepDuration, .restingHeartRate],
            windowHours: 24,
            computationTier: .nearRealTime,
            recomputeOnFormulaChange: true
        ),
        .sleepDebt: MetricDefinition(
            type: .sleepDebt,
            currentVersion: MetricVersion(major: 1, minor: 0, patch: 0),
            inputs: [.sleepDuration],
            windowHours: 168, // 7 days
            computationTier: .offlineBatch,
            recomputeOnFormulaChange: true
        ),
        .strainIndex: MetricDefinition(
            type: .strainIndex,
            currentVersion: MetricVersion(major: 1, minor: 1, patch: 0),
            inputs: [.activeEnergyBurned, .exerciseMinutes, .workoutSession],
            windowHours: 336, // 14 days
            computationTier: .offlineBatch,
            recomputeOnFormulaChange: true
        ),
        .skipProbability: MetricDefinition(
            type: .skipProbability,
            currentVersion: MetricVersion(major: 1, minor: 0, patch: 0),
            inputs: [.sleepDuration, .calendarEvent, .workoutSession],
            windowHours: 24,
            computationTier: .nearRealTime,
            recomputeOnFormulaChange: false // Too volatile
        )
    ]
}

struct MetricDefinition {
    let type: MetricType
    let currentVersion: MetricVersion
    let inputs: [SignalType]
    let windowHours: Int
    let computationTier: ComputationTier
    let recomputeOnFormulaChange: Bool
}
```

#### Computation Tier Strategy

```swift
/// Three-tier computation to control cost and latency
/// RULE: Hard-gate what runs where. No exceptions.

enum ComputationTier: String, Codable {
    case realTime        // < 100ms, triggered immediately
    case nearRealTime    // Hourly batch
    case offlineBatch    // Daily/weekly, overnight only

    var maxLatency: TimeInterval {
        switch self {
        case .realTime: return 0.1      // 100ms
        case .nearRealTime: return 3600  // 1 hour
        case .offlineBatch: return 86400 // 24 hours
        }
    }

    var batteryImpact: BatteryImpact {
        switch self {
        case .realTime: return .minimal
        case .nearRealTime: return .low
        case .offlineBatch: return .moderate
        }
    }
}

enum BatteryImpact: String {
    case minimal   // < 1% daily
    case low       // 1-3% daily
    case moderate  // 3-5% daily
}

/// Tier assignment and enforcement
actor ComputationScheduler {

    // MARK: - Real-Time Tier (< 100ms)

    /// Only critical, low-cost computations
    /// Examples: "Is there a workout now?", "Current recovery bucket"
    func computeRealTime(_ type: MetricType) async -> DerivedMetric? {
        guard MetricRegistry.definitions[type]?.computationTier == .realTime else {
            fatalError("Metric \(type) is not approved for real-time computation")
        }
        return await metricEngine.compute(type, for: Date())
    }

    // MARK: - Near-Real-Time Tier (Hourly)

    /// Scheduled hourly via BGAppRefreshTask
    /// Examples: Recovery Score, Skip Probability
    func computeNearRealTimeBatch() async {
        let nearRealTimeMetrics = MetricRegistry.definitions
            .filter { $0.value.computationTier == .nearRealTime }
            .map { $0.key }

        for metric in nearRealTimeMetrics {
            let _ = await metricEngine.compute(metric, for: Date())
        }
    }

    // MARK: - Offline Batch Tier (Overnight Only)

    /// Heavy computations run 2-5 AM when phone is charging
    /// Examples: Sleep Debt (7-day), Strain Index (14-day), Trend Analysis
    func computeOfflineBatch() async {
        // Only run if charging and overnight
        guard await isChargingAndOvernight() else { return }

        let batchMetrics = MetricRegistry.definitions
            .filter { $0.value.computationTier == .offlineBatch }
            .map { $0.key }

        for metric in batchMetrics {
            // Compute for last 7 days (fills any gaps)
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            var day = weekAgo
            while day <= Date() {
                let _ = await metricEngine.compute(metric, for: day)
                day = Calendar.current.date(byAdding: .day, value: 1, to: day)!
            }
        }
    }

    private func isChargingAndOvernight() async -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        let isOvernight = (2...5).contains(hour)
        let isCharging = await UIDevice.current.batteryState == .charging ||
                         UIDevice.current.batteryState == .full
        return isOvernight && isCharging
    }
}
```

---

### 2.12 User Health Profile State Machine

> **PLATFORM THINKING**: Personalization isn't a feature—it's state. Without modeling
> baseline, adaptation rate, and confidence level, the "AI coach" becomes generic noise.

```swift
/// User Health Profile State Machine
/// Extends Trust State Machine with health-specific phases

enum HealthProfilePhase: Int, Codable, Comparable {
    case baseline = 1        // Collecting baseline data (days 1-14)
    case adaptation = 2      // Learning user patterns (days 15-45)
    case maintenance = 3     // Stable personalization (day 45+)
    case regression = 4      // Detected backslide, re-adapting

    static func < (lhs: HealthProfilePhase, rhs: HealthProfilePhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct UserHealthProfile: Codable {

    // Current phase
    var phase: HealthProfilePhase
    var phaseEnteredAt: Date

    // Baseline metrics (established in baseline phase)
    var baselineHRV: Double?              // User's typical HRV
    var baselineSleepDuration: TimeInterval?
    var baselineRestingHR: Double?
    var baselineWorkoutsPerWeek: Double?
    var baselineActiveCalories: Double?

    // Confidence in our understanding
    var patternConfidence: Double         // 0.0-1.0
    var dataPointsCollected: Int
    var consecutiveAccuratePredictions: Int

    // Adaptation tracking
    var adaptationRate: AdaptationRate
    var lastSignificantChange: Date?

    // Regression detection
    var regressionIndicators: [RegressionIndicator]
}

enum AdaptationRate: String, Codable {
    case slow      // User patterns are stable
    case moderate  // Some variation week-to-week
    case fast      // User patterns change frequently
}

struct RegressionIndicator: Codable {
    let type: RegressionType
    let detectedAt: Date
    let severity: Double  // 0.0-1.0

    enum RegressionType: String, Codable {
        case activityDecline     // Workouts dropping
        case sleepDegradation    // Sleep quality declining
        case hrvDropping         // Stress indicators rising
        case engagementLoss      // Ignoring recommendations
    }
}

/// State machine that manages health profile transitions
actor HealthProfileStateMachine {

    private var profile: UserHealthProfile
    private let metricEngine: DerivedMetricEngine

    // MARK: - Phase Transitions

    func evaluateTransition() async {
        switch profile.phase {
        case .baseline:
            await checkBaselineCompletion()
        case .adaptation:
            await checkAdaptationCompletion()
        case .maintenance:
            await checkForRegression()
        case .regression:
            await checkRecoveryFromRegression()
        }
    }

    private func checkBaselineCompletion() async {
        // Need 14 days of data to establish baseline
        guard profile.dataPointsCollected >= 14 * 24 else { return } // ~24 signals/day

        // Establish baselines
        profile.baselineHRV = await calculateBaseline(.heartRateVariability)
        profile.baselineSleepDuration = await calculateBaseline(.sleepDuration)
        profile.baselineRestingHR = await calculateBaseline(.restingHeartRate)
        profile.baselineWorkoutsPerWeek = await calculateWorkoutFrequency()

        // Transition to adaptation
        profile.phase = .adaptation
        profile.phaseEnteredAt = Date()
        profile.patternConfidence = 0.3 // Low initial confidence
    }

    private func checkAdaptationCompletion() async {
        // Need 30+ days and 80%+ prediction accuracy
        let daysInPhase = Calendar.current.dateComponents(
            [.day],
            from: profile.phaseEnteredAt,
            to: Date()
        ).day ?? 0

        guard daysInPhase >= 30 else { return }
        guard profile.patternConfidence >= 0.8 else { return }
        guard profile.consecutiveAccuratePredictions >= 10 else { return }

        // Transition to maintenance
        profile.phase = .maintenance
        profile.phaseEnteredAt = Date()
    }

    private func checkForRegression() async {
        let indicators = await detectRegressionIndicators()

        if indicators.count >= 2 || indicators.contains(where: { $0.severity > 0.7 }) {
            profile.regressionIndicators = indicators
            profile.phase = .regression
            profile.phaseEnteredAt = Date()
            profile.patternConfidence *= 0.7 // Reduce confidence
        }
    }

    private func checkRecoveryFromRegression() async {
        let daysInRegression = Calendar.current.dateComponents(
            [.day],
            from: profile.phaseEnteredAt,
            to: Date()
        ).day ?? 0

        // Need 7+ days of improved behavior
        if daysInRegression >= 7 && profile.regressionIndicators.isEmpty {
            profile.phase = .adaptation // Back to adaptation, not maintenance
            profile.phaseEnteredAt = Date()
        }
    }

    // MARK: - Personalization Based on Phase

    /// Get personalization intensity based on current phase
    func personalizationLevel() -> PersonalizationLevel {
        switch profile.phase {
        case .baseline:
            return .generic  // Use population defaults
        case .adaptation:
            return .partial  // Blend population + personal
        case .maintenance:
            return .full     // Fully personalized
        case .regression:
            return .cautious // Reduce intensity, more conservative
        }
    }
}

enum PersonalizationLevel {
    case generic    // Population defaults only
    case partial    // 50/50 blend
    case full       // Fully personalized to user
    case cautious   // Back off intensity
}
```

---

### 2.13 Bidirectional Feedback Loops

> **PLATFORM THINKING**: Without feedback, models don't improve, trust doesn't increase,
> and coaching feels dumb after week 3. Instrument micro-feedback, not surveys.

```swift
/// Micro-feedback capture system
/// RULE: 1-tap maximum. Never interrupt flow. Always implicit when possible.

struct FeedbackEvent: Codable {
    let id: UUID
    let type: FeedbackType
    let timestamp: Date
    let context: FeedbackContext

    // What we're getting feedback on
    let targetType: FeedbackTarget
    let targetId: String

    // The feedback itself
    let signal: FeedbackSignal
}

enum FeedbackType: String, Codable {
    case implicit            // Detected from behavior
    case explicit1Tap        // Single tap response
    case explicitChoice      // A/B choice
}

enum FeedbackTarget: String, Codable {
    case workoutRecommendation
    case scheduleSlot
    case intensityLevel
    case restDaySuggestion
    case insight
}

enum FeedbackSignal: Codable {
    // Implicit signals
    case followed            // User did what we suggested
    case ignored             // User didn't follow through
    case modified(String)    // User changed our suggestion
    case rejected            // User explicitly rejected

    // Explicit 1-tap signals
    case tooHard
    case tooEasy
    case justRight
    case wrongTime
    case helpful
    case notHelpful
}

struct FeedbackContext: Codable {
    let recoveryScore: Double?
    let dayOfWeek: Int
    let timeOfDay: Int
    let workoutType: String?
    let trustPhase: Int
}

/// Feedback collector that learns from every interaction
actor FeedbackEngine {

    private let feedbackStore: FeedbackStore
    private let recommendationWeights: RecommendationWeightAdjuster

    // MARK: - Implicit Feedback (Automatic)

    /// Called when user completes a recommended workout
    func recordWorkoutCompleted(recommendationId: String, actualDuration: TimeInterval) {
        let event = FeedbackEvent(
            id: UUID(),
            type: .implicit,
            timestamp: Date(),
            context: currentContext(),
            targetType: .workoutRecommendation,
            targetId: recommendationId,
            signal: .followed
        )
        Task {
            await feedbackStore.store(event)
            await recommendationWeights.reinforce(recommendationId, positive: true)
        }
    }

    /// Called when recommended workout window passes without activity
    func recordWorkoutMissed(recommendationId: String, scheduledTime: Date) {
        let event = FeedbackEvent(
            id: UUID(),
            type: .implicit,
            timestamp: Date(),
            context: currentContext(),
            targetType: .workoutRecommendation,
            targetId: recommendationId,
            signal: .ignored
        )
        Task {
            await feedbackStore.store(event)
            await recommendationWeights.reinforce(recommendationId, positive: false)
        }
    }

    /// Called when user reschedules a workout
    func recordWorkoutRescheduled(originalId: String, newTime: Date) {
        let event = FeedbackEvent(
            id: UUID(),
            type: .implicit,
            timestamp: Date(),
            context: currentContext(),
            targetType: .scheduleSlot,
            targetId: originalId,
            signal: .modified("rescheduled to \(newTime)")
        )
        Task {
            await feedbackStore.store(event)
            await recommendationWeights.adjustTimePreference(
                fromOriginal: originalId,
                toNew: newTime
            )
        }
    }

    // MARK: - Explicit 1-Tap Feedback

    /// Post-workout intensity check (shown on watch)
    func recordIntensityFeedback(_ feedback: IntensityFeedback, workoutId: String) {
        let signal: FeedbackSignal = {
            switch feedback {
            case .tooEasy: return .tooEasy
            case .justRight: return .justRight
            case .tooHard: return .tooHard
            }
        }()

        let event = FeedbackEvent(
            id: UUID(),
            type: .explicit1Tap,
            timestamp: Date(),
            context: currentContext(),
            targetType: .intensityLevel,
            targetId: workoutId,
            signal: signal
        )

        Task {
            await feedbackStore.store(event)
            await recommendationWeights.adjustIntensityBias(feedback)
        }
    }

    /// Insight helpfulness (subtle thumbs up/down)
    func recordInsightFeedback(_ helpful: Bool, insightId: String) {
        let event = FeedbackEvent(
            id: UUID(),
            type: .explicit1Tap,
            timestamp: Date(),
            context: currentContext(),
            targetType: .insight,
            targetId: insightId,
            signal: helpful ? .helpful : .notHelpful
        )

        Task {
            await feedbackStore.store(event)
            await recommendationWeights.adjustInsightRule(insightId, positive: helpful)
        }
    }
}

enum IntensityFeedback {
    case tooEasy
    case justRight
    case tooHard
}

/// Adjusts recommendation weights based on feedback
actor RecommendationWeightAdjuster {

    private var timeSlotWeights: [Int: Double] = [:]  // Hour -> weight
    private var intensityBias: Double = 0.0           // -1 (easier) to +1 (harder)
    private var insightRuleWeights: [String: Double] = [:]

    func reinforce(_ recommendationId: String, positive: Bool) {
        // Adjust weights based on what worked
    }

    func adjustTimePreference(fromOriginal: String, toNew: Date) {
        // Learn preferred times from reschedules
        let hour = Calendar.current.component(.hour, from: toNew)
        timeSlotWeights[hour, default: 1.0] += 0.1
    }

    func adjustIntensityBias(_ feedback: IntensityFeedback) {
        switch feedback {
        case .tooHard:
            intensityBias = max(-1, intensityBias - 0.05)
        case .tooEasy:
            intensityBias = min(1, intensityBias + 0.05)
        case .justRight:
            // Reinforce current calibration
            break
        }
    }

    func adjustInsightRule(_ ruleId: String, positive: Bool) {
        let delta = positive ? 0.1 : -0.1
        insightRuleWeights[ruleId, default: 1.0] += delta
    }
}
```

#### Failure Disambiguation (One-Tap Triage)

> **SIGNAL QUALITY**: An ignored block is NOISE. A disambiguated failure is SIGNAL.
>
> Problem: User missed Tuesday's workout. If we learn "6 PM Tuesday is bad," but the
> truth is "user had the flu," we've poisoned the model. Implicit feedback alone is dangerous.

```swift
/// Failure disambiguation system - converts noise into signal
/// On next app open after missed block, ask ONE question to disambiguate

enum MissedBlockReason: String, Codable {
    case scheduleConflict   // "Time didn't work" → Learn time preference
    case lifeHappened       // "Just life" → Don't penalize time slot
    case feltUnwell         // "Wasn't feeling it" → May correlate with recovery
    case tooTired           // "Too tired" → Recovery signal
    case forgotAboutIt      // "Forgot" → Notification timing issue
}

struct FailureDisambiguator {

    /// Pending missed blocks awaiting disambiguation
    private var pendingMissedBlocks: [MissedBlockRecord] = []

    struct MissedBlockRecord: Codable {
        let blockId: UUID
        let scheduledTime: Date
        let missedAt: Date
        let recoveryScoreAtTime: Double?
    }

    // MARK: - Detection

    /// Called when scheduled block window passes without workout detection
    func recordMissedBlock(_ block: TrainingBlock, recoveryScore: Double?) {
        let record = MissedBlockRecord(
            blockId: block.id,
            scheduledTime: block.startDate,
            missedAt: Date(),
            recoveryScoreAtTime: recoveryScore
        )
        pendingMissedBlocks.append(record)
        persistPendingBlocks()
    }

    // MARK: - Disambiguation UI

    /// Called on app foreground - check if we need to show triage
    func shouldShowTriageOnAppOpen() -> MissedBlockRecord? {
        // Only show for recent misses (within 48 hours)
        let cutoff = Date().addingTimeInterval(-48 * 3600)
        return pendingMissedBlocks.first { $0.missedAt > cutoff }
    }

    /// One-Tap Triage UI
    /// Shows: "I see we missed Tuesday. What happened?"
    /// Options: Schedule conflict | Just life | Not feeling well | Too tired | Forgot
    func presentTriageUI(for record: MissedBlockRecord) -> some View {
        VStack(spacing: 16) {
            Text("Missed \(record.scheduledTime.formatted(.dateTime.weekday(.wide)))'s workout")
                .font(.headline)

            Text("Quick check-in helps me learn your preferences")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // One-tap options
            ForEach(MissedBlockReason.allCases, id: \.self) { reason in
                Button(action: { handleTriageResponse(record: record, reason: reason) }) {
                    Text(reason.displayText)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }

    // MARK: - Learning from Disambiguation

    func handleTriageResponse(record: MissedBlockRecord, reason: MissedBlockReason) {
        Task {
            switch reason {
            case .scheduleConflict:
                // Time slot didn't work - LEARN from this
                await FeedbackEngine.shared.recordTimeSlotFailure(
                    time: record.scheduledTime,
                    isHardConstraint: true
                )

            case .lifeHappened:
                // Random life event - DON'T penalize time slot
                await FeedbackEngine.shared.recordNeutralMiss(blockId: record.blockId)

            case .feltUnwell, .tooTired:
                // Correlate with recovery score - potential model improvement
                await FeedbackEngine.shared.recordRecoveryCorrelatedMiss(
                    blockId: record.blockId,
                    reason: reason,
                    recoveryScore: record.recoveryScoreAtTime
                )

            case .forgotAboutIt:
                // Notification didn't work - adjust notification timing
                await FeedbackEngine.shared.recordNotificationFailure(
                    scheduledTime: record.scheduledTime
                )
            }

            // Remove from pending
            removePendingBlock(record.blockId)
        }
    }

    private func removePendingBlock(_ blockId: UUID) {
        pendingMissedBlocks.removeAll { $0.blockId == blockId }
        persistPendingBlocks()
    }

    private func persistPendingBlocks() {
        if let data = try? JSONEncoder().encode(pendingMissedBlocks) {
            UserDefaults.standard.set(data, forKey: "pending_missed_blocks")
        }
    }
}

extension MissedBlockReason: CaseIterable {
    var displayText: String {
        switch self {
        case .scheduleConflict: return "⏰ Time didn't work"
        case .lifeHappened: return "🤷 Just life"
        case .feltUnwell: return "🤒 Wasn't feeling well"
        case .tooTired: return "😴 Too tired"
        case .forgotAboutIt: return "💭 Forgot about it"
        }
    }
}

extension FeedbackEngine {
    func recordTimeSlotFailure(time: Date, isHardConstraint: Bool) async {
        // Penalize this hour on this day of week
    }

    func recordNeutralMiss(blockId: UUID) async {
        // Log but don't adjust weights
    }

    func recordRecoveryCorrelatedMiss(blockId: UUID, reason: MissedBlockReason, recoveryScore: Double?) async {
        // Correlate with recovery - if low recovery + "too tired", validates recovery model
    }

    func recordNotificationFailure(scheduledTime: Date) async {
        // Adjust notification lead time
    }

    func recordDelegateCleanup(eventId: String) async {
        // Log delegate action - don't penalize
    }

    func recordDelegateReschedule(eventId: String) async {
        // Honor delegate's new time as constraint
    }

    func recordUserModification(eventId: String, modification: EventModification) async {
        // Learn from user's explicit change
    }
}
```

---

## 3. Azure Backend Architecture

### 3.1 Reusing Existing Infrastructure

The backend leverages the deployed `vigor-rg` resources:

| Resource            | Type            | Purpose in Ghost Architecture                      |
| ------------------- | --------------- | -------------------------------------------------- |
| `vigor-functions`   | Function App    | Ghost API endpoints                                |
| `vigor-cosmos-prod` | Cosmos DB       | User profiles, workout library, RAG knowledge base |
| `vigor-openai`      | Foundry         | GPT-5-mini for workout generation                  |
| `vigor-foundry`     | Foundry Project | RAG indexes, fine-tuning                           |
| `vigor-frontend`    | Static Web App  | Admin dashboard (not user-facing)                  |
| `vigor-kv-*`        | Key Vault       | Secrets management                                 |
| `vigor-insights`    | App Insights    | Telemetry and monitoring                           |
| `vigorstorage*`     | Storage Account | Core ML model distribution, assets                 |

### 3.2 Hybrid Workout Generation Engine

> **HARDENED**: Uses deterministic templates for 90% of workouts (instant, free), LLM only for edge cases.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     HYBRID WORKOUT GENERATION ENGINE                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Request arrives ──► Template Matcher ──► Template found? ──► YES ──► Return│
│                              │                                              │
│                              └── NO ──► RAG + LLM Pipeline ──► Streaming ──►│
│                                              │                              │
│                                              └── Cache result for future    │
│                                                                             │
│  Template Coverage: ~90% of requests (standard blocks, common goals)        │
│  LLM Coverage: ~10% of requests (travel, injuries, chaos management)        │
│                                                                             │
│  Latency: Template = <100ms | LLM = 2-4s (streamed)                         │
│  Cost: Template = $0 | LLM = ~$0.003/request                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.3 API Endpoints (Azure Functions)

```python
# function_app.py - Ghost API with Hybrid Engine
import azure.functions as func
import json
from shared.auth import validate_apple_token
from shared.cosmos_db import CosmosClient
from shared.openai_client import OpenAIClient
from shared.rag import ExerciseRAG
from shared.templates import WorkoutTemplateEngine

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# =============================================================================
# HYBRID WORKOUT GENERATION (Templates + RAG-Grounded LLM)
# =============================================================================

@app.route(route="workouts/generate", methods=["POST"])
async def generate_workout(req: func.HttpRequest) -> func.HttpResponse:
    """
    HARDENED: Hybrid workout generation with template fallback.

    Strategy:
    1. Try deterministic template first (instant, free)
    2. Fall back to RAG + LLM only for edge cases
    3. Stream response for perceived speed

    The Ghost Engine calls this when:
    1. User explicitly requests a workout via single command
    2. Calendar block needs workout content
    3. Equipment/context changes require new plan
    """
    try:
        # Validate Apple Sign-In token
        user_id = await validate_apple_token(req.headers.get("Authorization"))
        if not user_id:
            return func.HttpResponse(status_code=401)

        body = req.get_json()

        # Extract context from Ghost Engine
        context = WorkoutContext(
            duration_minutes=body.get("duration", 30),
            equipment=body.get("equipment", []),
            limitations=body.get("limitations", []),
            recent_muscle_groups=body.get("recentMuscleGroups", []),
            recovery_score=body.get("recoveryScore", 0.7),
            time_of_day=body.get("timeOfDay", "morning"),
            goal=body.get("goal", "general_fitness"),
            is_travel=body.get("isTravel", False),
            chaos_mode=body.get("chaosMode", False)  # Unusual circumstances
        )

        # STEP 1: Try template engine first (instant, free)
        template_engine = WorkoutTemplateEngine()
        template_workout = template_engine.match(context)

        if template_workout and not context.chaos_mode:
            # Template hit! Return immediately
            cosmos = CosmosClient()
            saved = await cosmos.save_workout(user_id, template_workout)
            return func.HttpResponse(
                json.dumps(saved),
                mimetype="application/json",
                headers={"X-Vigor-Source": "template"}  # Track for analytics
            )

        # STEP 2: Fall back to RAG + LLM (streaming)
        # Check if streaming is requested
        if req.headers.get("Accept") == "application/x-ndjson":
            return await generate_streaming_workout(context, user_id)

        # Non-streaming fallback
        rag = ExerciseRAG()
        relevant_exercises = await rag.retrieve(
            equipment=context.equipment,
            muscle_groups=get_target_muscles(context),
            difficulty=get_difficulty(context.recovery_score),
            contraindications=context.limitations,
            limit=15  # Reduced from 20 to lower token count
        )

        # Generate workout with grounded context
        openai = OpenAIClient()
        workout = await openai.generate_workout(
            context=context,
            exercise_pool=relevant_exercises,
            user_id=user_id
        )

        # Store generated workout
        cosmos = CosmosClient()
        saved = await cosmos.save_workout(user_id, workout)

        return func.HttpResponse(
            json.dumps(saved),
            mimetype="application/json",
            headers={"X-Vigor-Source": "llm"}
        )

    except Exception as e:
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            status_code=500
        )


async def generate_streaming_workout(context: WorkoutContext, user_id: str):
    """
    HARDENED: Streaming workout generation for perceived instant response.

    Returns NDJSON (newline-delimited JSON) stream:
    1. First: Warmup exercises (instant gratification)
    2. Then: Main workout (as tokens arrive)
    3. Finally: Cool-down and metadata

    This eliminates the 5-8 second "staring at spinner" problem.
    """
    from azure.functions import HttpResponse
    import asyncio

    async def generate():
        # Immediately yield warmup (deterministic, instant)
        warmup = WorkoutTemplateEngine.get_standard_warmup(context.duration_minutes)
        yield json.dumps({"type": "warmup", "exercises": warmup}) + "\n"

        # Start LLM generation
        rag = ExerciseRAG()
        exercises = await rag.retrieve(
            equipment=context.equipment,
            muscle_groups=get_target_muscles(context),
            difficulty=get_difficulty(context.recovery_score),
            contraindications=context.limitations,
            limit=15
        )

        openai = OpenAIClient()
        async for chunk in openai.generate_workout_streaming(context, exercises):
            yield json.dumps({"type": "exercise", "data": chunk}) + "\n"

        # Yield cool-down (deterministic, instant)
        cooldown = WorkoutTemplateEngine.get_standard_cooldown()
        yield json.dumps({"type": "cooldown", "exercises": cooldown}) + "\n"

        # Yield metadata
        yield json.dumps({"type": "complete", "source": "llm"}) + "\n"

    return HttpResponse(
        body=generate(),
        mimetype="application/x-ndjson",
        headers={"X-Vigor-Source": "llm-streaming"}
    )


@app.route(route="workouts/library", methods=["GET"])
async def get_workout_library(req: func.HttpRequest) -> func.HttpResponse:
    """
    Get user's workout library for offline caching.
    Ghost Engine caches these locally for offline operation.
    """
    user_id = await validate_apple_token(req.headers.get("Authorization"))
    if not user_id:
        return func.HttpResponse(status_code=401)

    cosmos = CosmosClient()
    workouts = await cosmos.get_user_workouts(user_id, limit=50)

    return func.HttpResponse(
        json.dumps({"workouts": workouts}),
        mimetype="application/json"
    )


# =============================================================================
# GHOST SYNC (Minimal - Anonymized Only)
# =============================================================================

@app.route(route="ghost/sync", methods=["POST"])
async def ghost_sync(req: func.HttpRequest) -> func.HttpResponse:
    """
    Sync anonymized patterns for model improvement.

    PRIVACY: Only aggregate patterns are transmitted, never:
    - Raw health data
    - Calendar event titles/details
    - Location specifics
    - Personal identifiers
    """
    user_id = await validate_apple_token(req.headers.get("Authorization"))
    if not user_id:
        return func.HttpResponse(status_code=401)

    body = req.get_json()

    # Anonymized aggregates only
    anonymized_data = {
        "user_hash": hash_user_id(user_id),  # One-way hash
        "patterns": {
            "avg_sleep_hours": body.get("avgSleepHours"),
            "workout_frequency": body.get("workoutFrequency"),
            "skip_rate": body.get("skipRate"),
            "optimal_time_bucket": body.get("optimalTimeBucket"),  # "morning", "afternoon", "evening"
            "recovery_pattern": body.get("recoveryPattern"),
        },
        "trust_phase": body.get("trustPhase"),
        "days_active": body.get("daysActive"),
    }

    # Store for aggregate analysis
    cosmos = CosmosClient()
    await cosmos.store_anonymized_pattern(anonymized_data)

    return func.HttpResponse(json.dumps({"synced": True}))


# =============================================================================
# MODEL DISTRIBUTION
# =============================================================================

@app.route(route="models/manifest", methods=["GET"])
async def get_model_manifest(req: func.HttpRequest) -> func.HttpResponse:
    """
    Get latest Core ML model versions for background update.
    """
    manifest = {
        "models": [
            {
                "name": "SleepImpactClassifier",
                "version": "1.2.0",
                "url": f"{STORAGE_URL}/models/SleepImpactClassifier_1.2.0.mlmodelc.zip",
                "checksum": "sha256:abc123..."
            },
            {
                "name": "SkipPredictor",
                "version": "1.1.0",
                "url": f"{STORAGE_URL}/models/SkipPredictor_1.1.0.mlmodelc.zip",
                "checksum": "sha256:def456..."
            },
            {
                "name": "RecoveryAnalyzer",
                "version": "1.0.0",
                "url": f"{STORAGE_URL}/models/RecoveryAnalyzer_1.0.0.mlmodelc.zip",
                "checksum": "sha256:ghi789..."
            }
        ],
        "updated_at": "2026-01-26T00:00:00Z"
    }

    return func.HttpResponse(
        json.dumps(manifest),
        mimetype="application/json"
    )


# =============================================================================
# USER PROFILE
# =============================================================================

@app.route(route="users/profile", methods=["GET", "PUT"])
async def user_profile(req: func.HttpRequest) -> func.HttpResponse:
    """
    Get or update user profile.
    Profile data is minimal - most data lives on-device in Phenome.
    """
    user_id = await validate_apple_token(req.headers.get("Authorization"))
    if not user_id:
        return func.HttpResponse(status_code=401)

    cosmos = CosmosClient()

    if req.method == "GET":
        profile = await cosmos.get_user_profile(user_id)
        return func.HttpResponse(
            json.dumps(profile or {}),
            mimetype="application/json"
        )

    elif req.method == "PUT":
        body = req.get_json()
        # Only store essential profile data
        profile = {
            "userId": user_id,
            "equipment": body.get("equipment"),
            "injuries": body.get("injuries", []),
            "fitnessLevel": body.get("fitnessLevel"),
            "goals": body.get("goals", []),
            "tier": body.get("tier", "free"),
            "updatedAt": datetime.utcnow().isoformat()
        }

        saved = await cosmos.upsert_user_profile(profile)
        return func.HttpResponse(
            json.dumps(saved),
            mimetype="application/json"
        )


# =============================================================================
# HEALTH CHECK
# =============================================================================

@app.route(route="health", methods=["GET"])
async def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """System health check."""
    return func.HttpResponse(
        json.dumps({
            "status": "healthy",
            "version": "2.0.0",
            "timestamp": datetime.utcnow().isoformat()
        }),
        mimetype="application/json"
    )
```

### 3.3 RAG-Grounded Workout Generation

```python
# shared/rag.py - Exercise knowledge base with RAG
from azure.search.documents import SearchClient
from azure.core.credentials import AzureKeyCredential
from typing import List, Dict
import os

class ExerciseRAG:
    """
    Retrieval-Augmented Generation for exercise selection.

    Ensures workout generation is grounded in:
    1. Verified exercise database (not hallucinated movements)
    2. Equipment compatibility
    3. Muscle group targeting
    4. Difficulty appropriateness
    5. Safety considerations for injuries
    """

    def __init__(self):
        self.search_client = SearchClient(
            endpoint=os.environ["AZURE_SEARCH_ENDPOINT"],
            index_name="exercise-knowledge-base",
            credential=AzureKeyCredential(os.environ["AZURE_SEARCH_KEY"])
        )

    async def retrieve(
        self,
        equipment: List[str],
        muscle_groups: List[str],
        difficulty: str,
        contraindications: List[str] = None,
        limit: int = 20
    ) -> List[Dict]:
        """
        Retrieve relevant exercises from knowledge base.
        """

        # Build filter expression
        filters = []

        if equipment:
            equipment_filter = " or ".join([f"equipment/any(e: e eq '{e}')" for e in equipment])
            filters.append(f"({equipment_filter})")

        if muscle_groups:
            muscle_filter = " or ".join([f"primaryMuscles/any(m: m eq '{m}')" for m in muscle_groups])
            filters.append(f"({muscle_filter})")

        if difficulty:
            filters.append(f"difficulty eq '{difficulty}'")

        # Exclude contraindicated exercises
        if contraindications:
            for contra in contraindications:
                filters.append(f"not (contraindications/any(c: c eq '{contra}'))")

        filter_str = " and ".join(filters) if filters else None

        results = self.search_client.search(
            search_text="*",
            filter=filter_str,
            top=limit,
            select=["id", "name", "description", "equipment", "primaryMuscles",
                    "secondaryMuscles", "difficulty", "instructions", "modifications",
                    "videoUrl", "imageUrl"]
        )

        return [dict(r) for r in results]


# shared/openai_client.py - Grounded workout generation
from openai import AzureOpenAI
import json
from typing import List, Dict

class OpenAIClient:
    """Azure OpenAI client with RAG grounding."""

    def __init__(self):
        self.client = AzureOpenAI(
            azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
            api_key=os.environ["AZURE_OPENAI_API_KEY"],
            api_version="2024-02-01"
        )
        self.deployment = os.environ.get("AZURE_OPENAI_DEPLOYMENT", "gpt-5-mini")

    async def generate_workout(
        self,
        context: "WorkoutContext",
        exercise_pool: List[Dict],
        user_id: str
    ) -> Dict:
        """
        Generate workout using RAG-grounded exercise pool.

        The model can ONLY select from exercises in the pool,
        preventing hallucinated or unsafe exercises.
        """

        system_prompt = """You are Vigor's Ghost - a fitness system that generates
personalized workouts. Your voice is a high-end concierge: concise, precise, professional.

CRITICAL RULES:
1. ONLY use exercises from the provided exercise pool
2. Never invent exercises or equipment not in the pool
3. Respect all stated limitations and injuries
4. Match workout duration to requested time
5. Balance muscle groups appropriately
6. Include proper warm-up and cool-down

OUTPUT FORMAT: Valid JSON matching the workout schema."""

        user_prompt = f"""Generate a workout with these parameters:

CONTEXT:
- Duration: {context.duration_minutes} minutes
- Equipment available: {', '.join(context.equipment) or 'bodyweight only'}
- Limitations/injuries: {', '.join(context.limitations) or 'none'}
- Recently worked muscles (avoid): {', '.join(context.recent_muscle_groups) or 'none'}
- Recovery score: {context.recovery_score} (0-1, lower = more recovery needed)
- Time of day: {context.time_of_day}
- Goal: {context.goal}

AVAILABLE EXERCISES (select ONLY from this list):
{json.dumps(exercise_pool, indent=2)}

Generate a complete workout plan in JSON format."""

        response = self.client.chat.completions.create(
            model=self.deployment,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            response_format={"type": "json_object"},
            temperature=0.7,
            max_tokens=2000
        )

        workout = json.loads(response.choices[0].message.content)

        # Validate all exercises are from pool
        exercise_ids = {e["id"] for e in exercise_pool}
        for exercise in workout.get("exercises", []):
            if exercise.get("exerciseId") not in exercise_ids:
                raise ValueError(f"Generated exercise not in pool: {exercise}")

        return workout

    async def generate_workout_streaming(
        self,
        context: "WorkoutContext",
        exercise_pool: List[Dict]
    ):
        """
        HARDENED: Streaming workout generation for instant perceived response.
        Yields exercise chunks as they're generated.
        """
        # Same prompts as above, but with streaming
        response = self.client.chat.completions.create(
            model=self.deployment,
            messages=[
                {"role": "system", "content": self._get_system_prompt()},
                {"role": "user", "content": self._get_user_prompt(context, exercise_pool)}
            ],
            response_format={"type": "json_object"},
            temperature=0.7,
            max_tokens=2000,
            stream=True  # Enable streaming
        )

        buffer = ""
        for chunk in response:
            if chunk.choices[0].delta.content:
                buffer += chunk.choices[0].delta.content
                # Try to yield complete exercise objects as they form
                if '"exerciseId"' in buffer and '}' in buffer:
                    try:
                        # Extract complete exercise
                        yield {"partial": buffer}
                    except:
                        pass


# shared/templates.py - Dynamic Skeleton workout templates
class WorkoutTemplateEngine:
    """
    HARDENED: Dynamic Skeleton engine for 90% of workout requests.

    **CONCIERGE UPGRADE**: Instead of returning static templates that feel repetitive,
    we use "skeletons" that define the STRUCTURE (Push/Pull/Legs, circuit timing),
    but slot in exercises DYNAMICALLY from the Exercise RAG.

    Benefits:
    - Instant (no LLM call)
    - Free (no token cost)
    - Varied (different exercises each time)
    - Reliable (no hallucinations)

    Templates are:
    - Skeletons define: structure, timing, muscle groups, rep schemes
    - RAG provides: specific exercises matching user's equipment + skill level
    """

    # Pre-defined workout SKELETONS by goal + duration + equipment
    # Skeletons define STRUCTURE, not specific exercises
    SKELETONS = {
        # Key: (goal, duration_bucket, equipment_level)
        ("strength", 30, "bodyweight"): {
            "name": "30-Min Bodyweight Strength",
            "structure": [
                {"slot": "push", "sets": 3, "reps": "10-15", "rest": 60},
                {"slot": "legs", "sets": 3, "reps": "15-20", "rest": 60},
                {"slot": "core", "sets": 3, "reps": "30-45s", "rest": 45},
                {"slot": "legs_unilateral", "sets": 3, "reps": "10 each", "rest": 60},
                {"slot": "cardio_burst", "sets": 3, "reps": "20", "rest": 45},
            ]
        },
        ("strength", 30, "dumbbells"): {
            "name": "30-Min Dumbbell Strength",
            "structure": [
                {"slot": "legs_compound", "sets": 3, "reps": "12", "rest": 60},
                {"slot": "pull_horizontal", "sets": 3, "reps": "10 each", "rest": 60},
                {"slot": "push_horizontal", "sets": 3, "reps": "10", "rest": 60},
                {"slot": "hip_hinge", "sets": 3, "reps": "12", "rest": 60},
                {"slot": "arms", "sets": 2, "reps": "12", "rest": 45},
            ]
        },
        ("strength", 45, "full_gym"): {
            "name": "45-Min Full Gym Strength",
            "structure": [
                {"slot": "legs_compound", "sets": 4, "reps": "8", "rest": 90},
                {"slot": "push_horizontal", "sets": 4, "reps": "8", "rest": 90},
                {"slot": "pull_horizontal", "sets": 3, "reps": "10", "rest": 75},
                {"slot": "push_vertical", "sets": 3, "reps": "10", "rest": 75},
                {"slot": "pull_vertical", "sets": 3, "reps": "12", "rest": 60},
            ]
        },
        ("recovery", 20, "bodyweight"): {
            "name": "20-Min Recovery",
            "structure": [
                {"slot": "spine_mobility", "sets": 2, "reps": "10", "rest": 30},
                {"slot": "hip_mobility", "sets": 2, "reps": "10 each", "rest": 30},
                {"slot": "full_body_stretch", "sets": 2, "reps": "5 each", "rest": 30},
                {"slot": "foam_rolling", "sets": 1, "reps": "5min", "rest": 0},
            ]
        },
        # Add more skeletons...
    }

    # Exercise pool by slot type + equipment (loaded from RAG index)
    EXERCISE_POOL = {
        # Push exercises
        ("push", "bodyweight"): ["Push-ups", "Diamond Push-ups", "Pike Push-ups", "Decline Push-ups", "Archer Push-ups"],
        ("push", "dumbbells"): ["Dumbbell Press", "Arnold Press", "Incline Press", "Floor Press"],
        ("push", "full_gym"): ["Bench Press", "Incline Bench", "Cable Flyes", "Machine Press"],

        # Legs exercises
        ("legs", "bodyweight"): ["Squats", "Jump Squats", "Pistol Squats (Assisted)", "Wall Sit"],
        ("legs_compound", "dumbbells"): ["Goblet Squats", "Sumo Squats", "Split Squats"],
        ("legs_compound", "full_gym"): ["Barbell Squats", "Leg Press", "Hack Squats", "Front Squats"],
        ("legs_unilateral", "bodyweight"): ["Lunges", "Step-ups", "Bulgarian Split Squats (BW)"],

        # Pull exercises
        ("pull_horizontal", "dumbbells"): ["Dumbbell Rows", "Renegade Rows", "Bent Over Rows"],
        ("pull_horizontal", "full_gym"): ["Barbell Rows", "Cable Rows", "T-Bar Rows"],
        ("pull_vertical", "full_gym"): ["Lat Pulldowns", "Pull-ups (Assisted)", "Cable Pullovers"],

        # Core exercises
        ("core", "bodyweight"): ["Plank", "Side Plank", "Dead Bug", "Bird Dog", "Hollow Hold"],

        # Mobility/Recovery
        ("spine_mobility", "bodyweight"): ["Cat-Cow Stretch", "Thread the Needle", "Spinal Twists"],
        ("hip_mobility", "bodyweight"): ["Hip Circles", "90/90 Stretch", "Pigeon Pose"],
        ("full_body_stretch", "bodyweight"): ["World's Greatest Stretch", "Downward Dog", "Child's Pose"],

        # Add more slots...
    }

    @classmethod
    def match(cls, context: "WorkoutContext") -> Optional[Dict]:
        """
        Match context to a skeleton, then fill slots with varied exercises.
        Returns None if no suitable skeleton (triggers LLM fallback).
        """
        # Determine duration bucket
        if context.duration_minutes <= 25:
            duration_bucket = 20
        elif context.duration_minutes <= 35:
            duration_bucket = 30
        elif context.duration_minutes <= 50:
            duration_bucket = 45
        else:
            duration_bucket = 60

        # Determine equipment level
        if "barbell" in context.equipment or "full_gym" in context.equipment:
            equipment_level = "full_gym"
        elif "dumbbells" in context.equipment or "kettlebell" in context.equipment:
            equipment_level = "dumbbells"
        else:
            equipment_level = "bodyweight"

        # Check for skeleton match
        key = (context.goal, duration_bucket, equipment_level)
        skeleton = cls.SKELETONS.get(key)

        if skeleton:
            # DYNAMIC: Fill skeleton slots with varied exercises
            workout = cls._fill_skeleton(skeleton, equipment_level, context)
            workout["generatedAt"] = datetime.utcnow().isoformat()
            workout["source"] = "dynamic_skeleton"
            return workout

        return None  # No match, fall back to LLM

    @classmethod
    def _fill_skeleton(cls, skeleton: Dict, equipment_level: str, context: "WorkoutContext") -> Dict:
        """Fill skeleton slots with exercises, avoiding recent repeats."""
        workout = {
            "name": skeleton["name"],
            "exercises": []
        }

        # Get user's recent exercises to avoid repetition
        recent_exercises = set(context.recent_exercises[-10:]) if hasattr(context, 'recent_exercises') else set()

        for slot in skeleton["structure"]:
            slot_type = slot["slot"]
            pool_key = (slot_type, equipment_level)

            # Fallback to bodyweight if no exercises for this equipment
            if pool_key not in cls.EXERCISE_POOL:
                pool_key = (slot_type, "bodyweight")

            exercise_pool = cls.EXERCISE_POOL.get(pool_key, [])

            # Filter out recent exercises
            available = [e for e in exercise_pool if e not in recent_exercises]
            if not available:
                available = exercise_pool  # Fall back if all are recent

            # Select random exercise from pool
            if available:
                import random
                selected = random.choice(available)
                recent_exercises.add(selected)

                workout["exercises"].append({
                    "name": selected,
                    "sets": slot["sets"],
                    "reps": slot["reps"],
                    "rest": slot["rest"]
                })

        return workout

    @classmethod
    def get_standard_warmup(cls, duration_minutes: int) -> List[Dict]:
        """Standard warmup for streaming response (instant)."""
        if duration_minutes < 30:
            return [
                {"name": "Jumping Jacks", "duration": "30s"},
                {"name": "Arm Circles", "duration": "30s"},
                {"name": "Leg Swings", "duration": "30s"},
            ]
        else:
            return [
                {"name": "Light Jog in Place", "duration": "60s"},
                {"name": "Jumping Jacks", "duration": "30s"},
                {"name": "Arm Circles", "duration": "30s"},
                {"name": "Hip Circles", "duration": "30s"},
                {"name": "Leg Swings", "duration": "30s"},
            ]

    @classmethod
    def get_standard_cooldown(cls) -> List[Dict]:
        """Standard cooldown for streaming response (instant)."""
        return [
            {"name": "Deep Breathing", "duration": "60s"},
            {"name": "Quad Stretch", "duration": "30s each"},
            {"name": "Hamstring Stretch", "duration": "30s each"},
            {"name": "Shoulder Stretch", "duration": "30s each"},
        ]


# ═══════════════════════════════════════════════════════════════════════════
# WORKOUT CONTRACTS (Deterministic Safety Guardrails)
# ═══════════════════════════════════════════════════════════════════════════

# **SCALE HARDENING**: Dynamic Skeletons + RAG + LLM can produce unsafe workouts
# at scale due to: Exercise DB drift, prompt regressions, model updates.
# Workout Contracts provide deterministic post-generation validation.

class WorkoutContract:
    """
    Pre-validated workout constraints that MUST pass before delivery.
    If validation fails: fall back to known-safe template, log incident.
    No exceptions.
    """

    # Hard caps by workout type (non-negotiable)
    VOLUME_CAPS = {
        "strength": {
            "max_exercises": 10,
            "max_sets_per_exercise": 6,
            "max_total_sets": 30,
            "max_reps_per_set": 20,
            "min_rest_seconds": 30,
        },
        "hypertrophy": {
            "max_exercises": 12,
            "max_sets_per_exercise": 5,
            "max_total_sets": 35,
            "max_reps_per_set": 25,
            "min_rest_seconds": 30,
        },
        "cardio": {
            "max_exercises": 8,
            "max_total_duration_minutes": 90,
            "max_intensity_zone": 5,
        },
        "recovery": {
            "max_exercises": 10,
            "max_total_duration_minutes": 45,
            "forbidden_movements": ["explosive", "heavy", "impact"],
        },
        "hiit": {
            "max_exercises": 12,
            "max_work_interval_seconds": 90,
            "min_rest_ratio": 0.5,  # rest >= 50% of work
            "max_total_rounds": 15,
        },
    }

    # Progression limits (prevent injury)
    PROGRESSION_LIMITS = {
        "max_weight_increase_percent": 10,    # vs. last session
        "max_volume_increase_percent": 15,    # vs. last week
        "max_intensity_increase_percent": 10, # vs. last session
        "min_deload_frequency_weeks": 4,      # force deload every 4 weeks
    }

    # Forbidden exercise combinations
    FORBIDDEN_COMBINATIONS = [
        {"heavy_deadlift", "heavy_back_squat"},  # Same session
        {"overhead_press", "upright_row"},        # Shoulder impingement risk
        {"kipping_pullup", "heavy_row"},          # Shoulder fatigue
    ]

    @classmethod
    def validate(cls, workout: Dict, workout_type: str, user_context: Dict) -> "ContractResult":
        """
        Validate generated workout against safety contracts.
        Returns ContractResult with pass/fail and specific violations.
        """
        violations = []
        caps = cls.VOLUME_CAPS.get(workout_type, cls.VOLUME_CAPS["strength"])
        exercises = workout.get("exercises", [])

        # 1. Exercise count check
        if len(exercises) > caps.get("max_exercises", 10):
            violations.append(ContractViolation(
                rule="max_exercises",
                expected=caps["max_exercises"],
                actual=len(exercises),
                severity="high"
            ))

        # 2. Total sets check
        total_sets = sum(e.get("sets", 0) for e in exercises)
        if total_sets > caps.get("max_total_sets", 30):
            violations.append(ContractViolation(
                rule="max_total_sets",
                expected=caps["max_total_sets"],
                actual=total_sets,
                severity="high"
            ))

        # 3. Per-exercise set cap
        for exercise in exercises:
            if exercise.get("sets", 0) > caps.get("max_sets_per_exercise", 6):
                violations.append(ContractViolation(
                    rule="max_sets_per_exercise",
                    expected=caps["max_sets_per_exercise"],
                    actual=exercise["sets"],
                    severity="medium",
                    context=exercise["name"]
                ))

        # 4. Rest period check
        for exercise in exercises:
            if exercise.get("rest", 60) < caps.get("min_rest_seconds", 30):
                violations.append(ContractViolation(
                    rule="min_rest_seconds",
                    expected=caps["min_rest_seconds"],
                    actual=exercise["rest"],
                    severity="medium",
                    context=exercise["name"]
                ))

        # 5. Forbidden combinations
        exercise_tags = set(e.get("movement_type", "") for e in exercises)
        for forbidden_combo in cls.FORBIDDEN_COMBINATIONS:
            if forbidden_combo.issubset(exercise_tags):
                violations.append(ContractViolation(
                    rule="forbidden_combination",
                    expected="not present",
                    actual=str(forbidden_combo),
                    severity="high"
                ))

        # 6. Injury safety check
        user_injuries = user_context.get("injuries", [])
        for exercise in exercises:
            contraindicated = exercise.get("contraindicated_for", [])
            for injury in user_injuries:
                if injury in contraindicated:
                    violations.append(ContractViolation(
                        rule="injury_contraindication",
                        expected=f"no exercises contraindicated for {injury}",
                        actual=exercise["name"],
                        severity="critical"
                    ))

        # Determine result
        critical_violations = [v for v in violations if v.severity == "critical"]
        high_violations = [v for v in violations if v.severity == "high"]

        if critical_violations:
            return ContractResult(passed=False, violations=violations, action="reject")
        elif high_violations:
            return ContractResult(passed=False, violations=violations, action="fallback_to_template")
        elif violations:
            return ContractResult(passed=True, violations=violations, action="warn_and_proceed")
        else:
            return ContractResult(passed=True, violations=[], action="proceed")


class ContractViolation:
    def __init__(self, rule: str, expected, actual, severity: str, context: str = None):
        self.rule = rule
        self.expected = expected
        self.actual = actual
        self.severity = severity  # critical, high, medium, low
        self.context = context

    def __str__(self):
        ctx = f" ({self.context})" if self.context else ""
        return f"[{self.severity.upper()}] {self.rule}: expected {self.expected}, got {self.actual}{ctx}"


class ContractResult:
    def __init__(self, passed: bool, violations: List[ContractViolation], action: str):
        self.passed = passed
        self.violations = violations
        self.action = action  # proceed, warn_and_proceed, fallback_to_template, reject

    @property
    def should_fallback(self) -> bool:
        return self.action in ("fallback_to_template", "reject")


# Contract enforcement wrapper
class SafeWorkoutGenerator:
    """
    Wraps any workout generator with contract enforcement.
    Logs all violations with model/version fingerprint for debugging.
    """

    def __init__(self, template_engine: WorkoutTemplateEngine):
        self.template_engine = template_engine
        self.contract = WorkoutContract()

    async def generate(
        self,
        context: "WorkoutContext",
        user_context: Dict,
        model_version: str
    ) -> Dict:
        """Generate workout with contract enforcement."""

        # Try dynamic skeleton first
        workout = self.template_engine.match(context)
        source = "skeleton"

        if not workout:
            # Fall back to LLM
            workout = await self._generate_via_llm(context)
            source = "llm"

        # ALWAYS validate against contract
        result = self.contract.validate(
            workout=workout,
            workout_type=context.goal,
            user_context=user_context
        )

        if result.should_fallback:
            # Log incident with full context
            self._log_contract_violation(
                violations=result.violations,
                source=source,
                model_version=model_version,
                context=context
            )

            # Return known-safe template
            return self._get_fallback_template(context)

        if result.violations:
            # Warn but proceed
            self._log_contract_violation(
                violations=result.violations,
                source=source,
                model_version=model_version,
                context=context,
                severity="warning"
            )

        workout["contractValidated"] = True
        workout["contractViolations"] = len(result.violations)
        return workout

    def _log_contract_violation(
        self,
        violations: List[ContractViolation],
        source: str,
        model_version: str,
        context: "WorkoutContext",
        severity: str = "error"
    ):
        """Log violation with fingerprint for debugging regressions."""
        incident = {
            "timestamp": datetime.utcnow().isoformat(),
            "severity": severity,
            "source": source,
            "modelVersion": model_version,
            "workoutType": context.goal,
            "duration": context.duration_minutes,
            "equipment": context.equipment,
            "violations": [str(v) for v in violations],
        }
        # Send to Application Insights
        AppLogger.shared.log_contract_violation(incident)

    def _get_fallback_template(self, context: "WorkoutContext") -> Dict:
        """Return a known-safe, pre-validated template."""
        return {
            "name": f"Safe {context.goal.title()} Workout",
            "source": "fallback_template",
            "exercises": [
                {"name": "Warm-up", "sets": 1, "reps": "5 min", "rest": 0},
                {"name": "Bodyweight Squats", "sets": 3, "reps": "12", "rest": 60},
                {"name": "Push-ups", "sets": 3, "reps": "10", "rest": 60},
                {"name": "Lunges", "sets": 3, "reps": "10 each", "rest": 60},
                {"name": "Plank", "sets": 3, "reps": "30s", "rest": 45},
                {"name": "Cool-down Stretch", "sets": 1, "reps": "5 min", "rest": 0},
            ],
            "contractValidated": True,
            "contractViolations": 0,
        }

    async def _generate_via_llm(self, context: "WorkoutContext") -> Dict:
        """LLM generation (implementation in openai_client.py)."""
        # ... existing LLM generation code ...
        return {}
```

### 3.5 Cosmos DB Schema

```python
# shared/cosmos_db.py - Database operations
from azure.cosmos import CosmosClient as AzureCosmosClient
from azure.cosmos.partition_key import PartitionKey
import os

class CosmosClient:
    """Cosmos DB client for Vigor data."""

    def __init__(self):
        self.client = AzureCosmosClient(
            url=os.environ["COSMOS_DB_ENDPOINT"],
            credential=os.environ["COSMOS_DB_KEY"]
        )
        self.database = self.client.get_database_client("vigor_db")

    # Container references
    @property
    def users(self):
        return self.database.get_container_client("users")

    @property
    def workouts(self):
        return self.database.get_container_client("workouts")

    @property
    def exercises(self):
        return self.database.get_container_client("exercises")

    @property
    def anonymized_patterns(self):
        return self.database.get_container_client("anonymized_patterns")


# Database Schema (Cosmos DB Containers)
SCHEMA = {
    "users": {
        "partitionKey": "/userId",
        "example": {
            "id": "user_apple_abc123",
            "userId": "user_apple_abc123",
            "appleUserId": "001234.abc...",  # Apple Sign-In ID
            "email": "user@icloud.com",
            "profile": {
                "equipment": "home_gym",
                "injuries": ["shoulder"],
                "fitnessLevel": "intermediate",
                "goals": ["strength", "endurance"]
            },
            "tier": "premium",  # or "free"
            "createdAt": "2026-01-01T00:00:00Z",
            "updatedAt": "2026-01-26T00:00:00Z"
        }
    },

    "workouts": {
        "partitionKey": "/userId",
        "example": {
            "id": "workout_uuid",
            "userId": "user_apple_abc123",
            "name": "Upper Body Strength",
            "description": "45-minute dumbbell workout",
            "exercises": [
                {
                    "exerciseId": "ex_001",
                    "name": "Dumbbell Bench Press",
                    "sets": 3,
                    "reps": "8-12",
                    "restSeconds": 90,
                    "notes": "Control the descent"
                }
            ],
            "metadata": {
                "duration": 45,
                "difficulty": "intermediate",
                "equipment": ["dumbbells", "bench"],
                "muscleGroups": ["chest", "shoulders", "triceps"],
                "calories": 280
            },
            "generatedBy": "gpt-5-mini",
            "createdAt": "2026-01-26T00:00:00Z"
        }
    },

    "exercises": {
        "partitionKey": "/category",
        "purpose": "RAG knowledge base for workout generation",
        "example": {
            "id": "ex_001",
            "category": "strength",
            "name": "Dumbbell Bench Press",
            "description": "Compound chest exercise with dumbbells",
            "primaryMuscles": ["chest"],
            "secondaryMuscles": ["shoulders", "triceps"],
            "equipment": ["dumbbells", "bench"],
            "difficulty": "intermediate",
            "instructions": [
                "Lie on bench with dumbbells at chest height",
                "Press weights up until arms extended",
                "Lower with control to starting position"
            ],
            "modifications": {
                "easier": "Use lighter weight, reduce range",
                "harder": "Pause at bottom, slow eccentric"
            },
            "contraindications": ["shoulder_injury", "chest_injury"],
            "videoUrl": "https://...",
            "imageUrl": "https://..."
        }
    },

    "anonymized_patterns": {
        "partitionKey": "/dateKey",  # YYYY-MM format
        "purpose": "Aggregate patterns for model training (no PII)",
        "example": {
            "id": "pattern_uuid",
            "dateKey": "2026-01",
            "userHash": "sha256_of_user_id",  # One-way hash
            "patterns": {
                "avgSleepHours": 6.5,
                "workoutFrequency": 3.2,
                "skipRate": 0.15,
                "optimalTimeBucket": "morning",
                "recoveryPattern": "standard"
            },
            "trustPhase": 3,
            "daysActive": 45,
            "timestamp": "2026-01-26T00:00:00Z"
        },
        "ttl": 7776000  # 90 days, then auto-delete
    }
}
```

---

## 4. Watch App Architecture

### 4.1 watchOS App Structure

```swift
// VigorWatch/VigorWatchApp.swift
import SwiftUI
import WatchKit
import HealthKit

@main
struct VigorWatchApp: App {

    @StateObject private var workoutDetector = WorkoutDetector()
    @StateObject private var connectivityManager = WatchConnectivityManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workoutDetector)
                .environmentObject(connectivityManager)
        }

        // Background workout detection
        WKBackgroundRefreshDelegate {
            BackgroundRefreshHandler()
        }
    }
}

// ContentView.swift - Minimal Watch UI
struct ContentView: View {
    @EnvironmentObject var workoutDetector: WorkoutDetector

    var body: some View {
        VStack(spacing: 12) {
            // Recovery status
            RecoveryRing(score: workoutDetector.currentRecoveryScore)

            // Next scheduled workout (from iPhone)
            if let next = workoutDetector.nextScheduledWorkout {
                Text(next.title)
                    .font(.headline)
                Text(next.timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("No workout scheduled")
                    .foregroundColor(.secondary)
            }

            // Quick actions
            if workoutDetector.isWorkoutActive {
                Button("End Workout") {
                    workoutDetector.endWorkout()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
```

### 4.2 Workout Detection Engine

```swift
// WorkoutDetector.swift
import HealthKit
import WatchKit
import Combine

final class WorkoutDetector: NSObject, ObservableObject {

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    @Published var isWorkoutActive = false
    @Published var currentRecoveryScore: Double = 0.7
    @Published var nextScheduledWorkout: ScheduledWorkout?

    private let connectivityManager: WatchConnectivityManager

    /// Debouncing: Prevent repeated wakes during workout (e.g., Strava writes mid-workout)
    private var lastObserverWake: Date?
    private let debounceInterval: TimeInterval = 60  // 1 minute minimum between wakes

    override init() {
        self.connectivityManager = WatchConnectivityManager.shared
        super.init()

        setupBackgroundDelivery()
    }

    private func setupBackgroundDelivery() {
        // Monitor for workout starts
        let workoutType = HKObjectType.workoutType()

        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] _, _, error in
            guard error == nil else { return }
            self?.handleObserverWake()
        }

        healthStore.execute(query)
    }

    /// **BATTERY HARDENING**: Debounce HKObserverQuery to prevent repeated wakes
    ///
    /// Problem: Third-party apps (Strava, Nike Run Club) write workout samples
    /// continuously during exercise, which can wake Vigor repeatedly.
    /// Solution: Only process if workout has ENDED, not just updated.
    private func handleObserverWake() {
        // Debounce check
        if let lastWake = lastObserverWake,
           Date().timeIntervalSince(lastWake) < debounceInterval {
            // Too soon after last wake - skip
            return
        }
        lastObserverWake = Date()

        checkForEndedWorkouts()
    }

    private func checkForEndedWorkouts() {
        let now = Date()
        let fiveMinutesAgo = now.addingTimeInterval(-300)

        // Only query for ENDED workouts (endDate in past, not currently ongoing)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            HKQuery.predicateForSamples(withStart: fiveMinutesAgo, end: now),
            HKQuery.predicateForWorkouts(with: .greaterThanOrEqualTo, duration: 60) // At least 1 min
        ])

        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: predicate,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        ) { [weak self] _, samples, _ in
            guard let workout = samples?.first as? HKWorkout else { return }

            // Verify workout actually ended (not still in progress)
            guard workout.endDate < Date() else { return }

            // Check we haven't already processed this workout
            guard self?.hasProcessedWorkout(workout) == false else { return }

            self?.handleCompletedWorkout(workout)
        }

        healthStore.execute(query)
    }

    private var processedWorkoutIds: Set<UUID> = []

    private func hasProcessedWorkout(_ workout: HKWorkout) -> Bool {
        processedWorkoutIds.contains(workout.uuid)
    }

    private func handleCompletedWorkout(_ workout: HKWorkout) {
        // Mark as processed
        processedWorkoutIds.insert(workout.uuid)

        // Prune old IDs (keep last 50)
        if processedWorkoutIds.count > 50 {
            processedWorkoutIds = Set(Array(processedWorkoutIds).suffix(50))
        }

        // Send to iPhone for logging
        let workoutData: [String: Any] = [
            "type": "workout_completed",
            "activityType": workout.workoutActivityType.rawValue,
            "duration": workout.duration,
            "startDate": workout.startDate.timeIntervalSince1970,
            "endDate": workout.endDate.timeIntervalSince1970,
            "totalEnergyBurned": workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
            "averageHeartRate": fetchAverageHeartRate(for: workout)
        ]

        connectivityManager.sendMessage(workoutData)
    }

    private func fetchAverageHeartRate(for workout: HKWorkout) -> Double {
        // Synchronous fetch for Watch (simplified)
        // In production, use async/await properly
        return 0 // Placeholder
    }
}
```

### 4.3 Complications

```swift
// ComplicationController.swift
import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {

    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        let template = createTemplate(for: complication)
        let entry = CLKComplicationTimelineEntry(
            date: Date(),
            complicationTemplate: template
        )
        handler(entry)
    }

    private func createTemplate(for complication: CLKComplication) -> CLKComplicationTemplate {
        switch complication.family {
        case .circularSmall:
            return CLKComplicationTemplateCircularSmallRingText(
                textProvider: CLKSimpleTextProvider(text: "3"),  // Streak
                fillFraction: 0.7,  // Recovery
                ringStyle: .closed
            )

        case .modularSmall:
            return CLKComplicationTemplateModularSmallStackText(
                line1TextProvider: CLKSimpleTextProvider(text: "🏋️"),
                line2TextProvider: CLKSimpleTextProvider(text: "6PM")
            )

        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularView(
                ComplicationCircularView()
            )

        default:
            return CLKComplicationTemplateGraphicCornerTextView(
                ComplicationCornerView()
            )
        }
    }
}

// ComplicationCircularView.swift
struct ComplicationCircularView: View {
    var body: some View {
        ZStack {
            // Recovery ring
            Circle()
                .stroke(Color.green, lineWidth: 4)
                .opacity(0.3)

            Circle()
                .trim(from: 0, to: 0.7)  // Recovery score
                .stroke(Color.green, lineWidth: 4)
                .rotationEffect(.degrees(-90))

            // Next workout time
            VStack(spacing: 0) {
                Text("6")
                    .font(.system(size: 16, weight: .bold))
                Text("PM")
                    .font(.system(size: 8))
            }
        }
    }
}
```

### 4.4 Watch Autonomy (Phone-Independent Operation)

> **HARDENED**: Watch functions 100% without iPhone present.
>
> The Apple Watch is the primary sensor device—it measures "the soul of the workout."
> `WatchConnectivity` is notoriously unreliable for background transfers.
> The Watch must be able to detect, log, and confirm workouts autonomously.

#### 4.4.1 Single-Writer Principle (Device Authority Boundaries)

> **SCALE HARDENING**: When Watch + Phone disagree, which wins?
> Without explicit authority domains, you get: double-logged workouts, stale recovery
> decisions, phantom trust progression. These bugs are nightmare-tier to reproduce.

**The Solution: Single-Writer per Domain**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SINGLE-WRITER PRINCIPLE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  WATCH = Authoritative for WORKOUTS                                        │
│  ├── Workout start/end detection                                           │
│  ├── Heart rate during exercise                                            │
│  ├── Muscle groups worked                                                  │
│  ├── Actual duration                                                       │
│  └── Completion confirmation                                               │
│                                                                             │
│  PHONE = Authoritative for PLANNING & TRUST                                │
│  ├── Calendar block scheduling                                             │
│  ├── Trust state progression                                               │
│  ├── Phenome pattern computation                                           │
│  ├── Morning orchestration decisions                                       │
│  └── Behavioral memory updates                                             │
│                                                                             │
│  BACKEND = RECONCILER ONLY (Never Authoritative)                           │
│  ├── Duplicate detection                                                   │
│  ├── Conflict quarantine                                                   │
│  ├── Cross-device sync coordination                                        │
│  └── Audit log preservation                                                │
│                                                                             │
│  CONFLICT RESOLUTION:                                                       │
│  • Authoritative domain wins unconditionally                               │
│  • Non-authoritative updates are QUEUED, not applied                       │
│  • Conflicts are logged for forensics, never silently merged               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

```swift
// SingleWriterAuthority.swift - Device domain ownership
import Foundation

/// Every synced record carries authority metadata
protocol AuthoritativeRecord: Codable {
    var id: UUID { get }
    var originDevice: DeviceOrigin { get }
    var authoritativeDomain: AuthorityDomain { get }
    var monotonicSequence: UInt64 { get }
    var createdAt: Date { get }
    var modifiedAt: Date { get }
}

enum DeviceOrigin: String, Codable {
    case iPhone
    case appleWatch
    case iPad
    case backend                      // Server-originated (rare)
}

enum AuthorityDomain: String, Codable {
    case workouts                     // Watch authoritative
    case planning                     // Phone authoritative
    case trust                        // Phone authoritative
    case phenome                      // Phone authoritative
    case profile                      // Phone authoritative (user edits)
}

/// Conflict detection and resolution
actor AuthorityConflictResolver {

    struct ConflictRecord: Codable {
        let id: UUID
        let domain: AuthorityDomain
        let localRecord: Data         // Serialized local
        let remoteRecord: Data        // Serialized remote
        let detectedAt: Date
        let resolution: Resolution?
    }

    enum Resolution: String, Codable {
        case localWins                 // Local was authoritative
        case remoteWins                // Remote was authoritative
        case quarantined               // Neither authoritative, needs manual
        case merged                    // Non-conflicting fields merged
    }

    private var conflictLog: [ConflictRecord] = []

    /// Resolve conflict based on domain authority
    func resolve<T: AuthoritativeRecord>(
        local: T,
        remote: T,
        currentDevice: DeviceOrigin
    ) async -> (winner: T, resolution: Resolution) {

        let domain = local.authoritativeDomain
        let authoritativeDevice = authorityMap[domain]

        // Rule: Authoritative device ALWAYS wins
        if local.originDevice == authoritativeDevice {
            return (local, .localWins)
        } else if remote.originDevice == authoritativeDevice {
            return (remote, .remoteWins)
        } else {
            // Neither is authoritative - use sequence number
            if local.monotonicSequence > remote.monotonicSequence {
                return (local, .localWins)
            } else {
                return (remote, .remoteWins)
            }
        }
    }

    private let authorityMap: [AuthorityDomain: DeviceOrigin] = [
        .workouts: .appleWatch,
        .planning: .iPhone,
        .trust: .iPhone,
        .phenome: .iPhone,
        .profile: .iPhone
    ]

    /// Log conflict for forensics (never silently swallow)
    func logConflict<T: AuthoritativeRecord>(local: T, remote: T, resolution: Resolution) async {
        // Persist to Core Data for debugging
    }
}

/// Workout record with authority metadata
struct AuthoritativeWorkout: AuthoritativeRecord {
    let id: UUID
    let originDevice: DeviceOrigin
    let authoritativeDomain: AuthorityDomain = .workouts
    let monotonicSequence: UInt64
    let createdAt: Date
    var modifiedAt: Date

    // Workout data
    let activityType: UInt
    let duration: TimeInterval
    let startDate: Date
    let endDate: Date
    let totalEnergyBurned: Double?
    let averageHeartRate: Double?
    let muscleGroups: [String]
    let completionConfirmed: Bool
}

/// Trust event with authority metadata
struct AuthoritativeTrustEvent: AuthoritativeRecord {
    let id: UUID
    let originDevice: DeviceOrigin
    let authoritativeDomain: AuthorityDomain = .trust
    let monotonicSequence: UInt64
    let createdAt: Date
    var modifiedAt: Date

    // Trust data
    let eventType: TrustEventType
    let trustDelta: Double
    let newTrustScore: Double
    let newTrustPhase: TrustPhase
}

/// Monotonic sequence generator (prevents clock skew issues)
actor SequenceGenerator {
    private var currentSequence: UInt64 = 0

    func next() async -> UInt64 {
        // Load from UserDefaults on first access
        if currentSequence == 0 {
            currentSequence = UInt64(UserDefaults.standard.integer(forKey: "vigor_sequence"))
        }
        currentSequence += 1
        UserDefaults.standard.set(Int(currentSequence), forKey: "vigor_sequence")
        return currentSequence
    }
}
```

```swift
// WatchAutonomousSync.swift
import Foundation
import WatchKit
import HealthKit
import Network

/// Autonomous sync layer - Watch works independently of iPhone
final class WatchAutonomousSync: ObservableObject {

    private let healthStore = HKHealthStore()
    private var networkMonitor: NWPathMonitor?
    private var pendingQueue: [PendingWorkoutSync] = []

    // Direct backend connection (WiFi/Cellular)
    private let apiBaseURL = URL(string: "https://vigor-functions.azurewebsites.net/api")!

    @Published var isPhoneReachable = false
    @Published var hasDirectConnectivity = false

    init() {
        setupNetworkMonitoring()
        loadPendingQueue()
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.hasDirectConnectivity = path.status == .satisfied
                if path.status == .satisfied {
                    Task { await self?.flushPendingQueue() }
                }
            }
        }
        networkMonitor?.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }

    // MARK: - Autonomous Workout Logging

    /// Log workout directly from Watch - no iPhone required
    func logWorkout(_ workout: HKWorkout) async {
        let workoutData = WorkoutSyncPayload(
            id: UUID(),
            activityType: workout.workoutActivityType.rawValue,
            duration: workout.duration,
            startDate: workout.startDate,
            endDate: workout.endDate,
            totalEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
            averageHeartRate: await fetchAverageHeartRate(for: workout),
            source: "watch_autonomous"
        )

        // Strategy: Try direct sync, fall back to queue
        if hasDirectConnectivity {
            do {
                try await syncToBackend(workoutData)
            } catch {
                // Queue for later
                queueForLater(workoutData)
            }
        } else {
            // No connectivity - queue for later
            queueForLater(workoutData)
        }

        // Also try phone sync as backup (if reachable)
        if isPhoneReachable {
            sendToPhone(workoutData)
        }
    }

    // MARK: - Direct Backend Sync (WiFi/Cellular)

    private func syncToBackend(_ workout: WorkoutSyncPayload) async throws {
        let url = apiBaseURL.appendingPathComponent("watch/workouts")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(getAuthToken(), forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(workout)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SyncError.serverError
        }
    }

    // MARK: - Offline Queue Management

    private func queueForLater(_ workout: WorkoutSyncPayload) {
        let pending = PendingWorkoutSync(
            workout: workout,
            queuedAt: Date(),
            retryCount: 0
        )
        pendingQueue.append(pending)
        savePendingQueue()
    }

    private func flushPendingQueue() async {
        guard !pendingQueue.isEmpty else { return }

        var failedItems: [PendingWorkoutSync] = []

        for item in pendingQueue {
            do {
                try await syncToBackend(item.workout)
            } catch {
                // Increment retry count
                var failed = item
                failed.retryCount += 1
                if failed.retryCount < 5 {
                    failedItems.append(failed)
                }
                // Drop items after 5 retries
            }
        }

        pendingQueue = failedItems
        savePendingQueue()
    }

    private func loadPendingQueue() {
        guard let data = UserDefaults.standard.data(forKey: "pending_workout_queue"),
              let queue = try? JSONDecoder().decode([PendingWorkoutSync].self, from: data) else {
            return
        }
        pendingQueue = queue
    }

    private func savePendingQueue() {
        guard let data = try? JSONEncoder().encode(pendingQueue) else { return }
        UserDefaults.standard.set(data, forKey: "pending_workout_queue")
    }

    // MARK: - Phone Sync (Fallback)

    private func sendToPhone(_ workout: WorkoutSyncPayload) {
        guard let data = try? JSONEncoder().encode(workout) else { return }
        WatchConnectivityManager.shared.sendData(data, type: .workoutCompleted)
    }

    // MARK: - Helpers

    private func fetchAverageHeartRate(for workout: HKWorkout) async -> Double {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: workout.startDate,
                end: workout.endDate,
                options: .strictStartDate
            )

            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, _ in
                let avgHR = statistics?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
                continuation.resume(returning: avgHR)
            }

            healthStore.execute(query)
        }
    }

    private func getAuthToken() -> String {
        // Retrieve cached Apple Sign-In token
        return UserDefaults.standard.string(forKey: "vigor_auth_token") ?? ""
    }
}

struct WorkoutSyncPayload: Codable {
    let id: UUID
    let activityType: UInt
    let duration: TimeInterval
    let startDate: Date
    let endDate: Date
    let totalEnergyBurned: Double?
    let averageHeartRate: Double
    let source: String
}

struct PendingWorkoutSync: Codable {
    let workout: WorkoutSyncPayload
    let queuedAt: Date
    var retryCount: Int
}

enum SyncError: Error {
    case serverError
    case networkUnavailable
    case authenticationFailed
}
```

**Backend Endpoint for Watch Direct Sync** (added to `function_app.py`):

```python
@app.route(route="watch/workouts", methods=["POST"])
async def watch_workout_sync(req: func.HttpRequest) -> func.HttpResponse:
    """
    Direct workout sync from Apple Watch.

    Called when Watch has WiFi/Cellular but no iPhone.
    Handles duplicate detection in case both Watch and iPhone sync.
    """
    user_id = await validate_apple_token(req.headers.get("Authorization"))
    if not user_id:
        return func.HttpResponse(status_code=401)

    body = req.get_json()

    # Deduplicate by workout ID
    workout_id = body.get("id")
    cosmos = CosmosClient()

    existing = await cosmos.get_workout_by_id(user_id, workout_id)
    if existing:
        return func.HttpResponse(json.dumps({"status": "duplicate", "id": workout_id}))

    # Store workout
    workout = {
        "id": workout_id,
        "userId": user_id,
        "activityType": body.get("activityType"),
        "duration": body.get("duration"),
        "startDate": body.get("startDate"),
        "endDate": body.get("endDate"),
        "totalEnergyBurned": body.get("totalEnergyBurned"),
        "averageHeartRate": body.get("averageHeartRate"),
        "source": body.get("source", "watch"),
        "syncedAt": datetime.utcnow().isoformat()
    }

    await cosmos.store_workout(workout)

    return func.HttpResponse(
        json.dumps({"status": "synced", "id": workout_id}),
        mimetype="application/json"
    )
```

### 4.5 Hybrid Morning Orchestration (Corporate Hardened)

> **CORPORATE HARDENING**: The original Watch-first design fails for "bathroom charger" users
> who put on their watch after morning coffee. Gemini correctly identified that Silent Push
> to iPhone must be primary, with Watch as fallback/viewer.

**The Problem (Revised):**

- HealthKit background delivery on iPhone is batched, not real-time
- **The "Bathroom Charger" User**: Many users charge watch overnight and wear it AFTER coffee
- If Watch is primary trigger, the 5-6 AM "Morning Magic" moment is missed
- Watch Phenome may be stale if overnight iPhone analysis hasn't synced yet

**The Solution (Hybrid Triggering):**

1. **Primary Trigger**: Silent Push to iPhone at 5:55 AM (bypasses engagement throttling)
2. **Fallback Trigger**: Watch wrist-raise (for users who interact with Watch first)
3. **Staleness Check**: Watch verifies Phenome `computedAt` before making decisions

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    HYBRID MORNING ORCHESTRATION                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  5:55 AM ──► Azure Timer ──► Silent Push ──► iPhone Morning Engine ───┐    │
│                                                 (PRIMARY PATH)          │    │
│                                                                         │    │
│  User wakes ──► Wrist Raise ──► Watch checks Phenome staleness ───────┤    │
│                                   │                                     │    │
│                                   ├── Phenome < 6 hours old ──► Display │    │
│                                   │                                     │    │
│                                   └── Phenome > 6 hours old ──► Force sync  │
│                                       then display or degrade to Safe Mode  │
│                                                                             │
│  KEY INSIGHT: iPhone does the THINKING, Watch does the DISPLAYING          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### iPhone Morning Engine (Primary)

```swift
/// iPhone-side Morning Engine - receives Silent Push and orchestrates
final class iPhoneMorningEngine {

    static let shared = iPhoneMorningEngine()

    private let metricEngine: DerivedMetricEngine
    private let phenomeStore: PhenomeStore
    private var hasFiredToday = false

    /// Called from Silent Push handler at 5:55 AM
    func executeFromSilentPush() async {
        guard shouldExecuteToday() else { return }

        markFiredToday()

        do {
            // iPhone has authoritative overnight analysis
            let recoveryScore = await calculateMorningRecovery()
            let recommendation = await determineOptimalSlot(recoveryScore: recoveryScore)

            // Update Phenome with fresh decision + timestamp
            await phenomeStore.storeMorningDecision(
                MorningDecision(
                    score: recoveryScore,
                    recommendation: recommendation,
                    computedAt: Date()  // Critical for staleness checks
                )
            )

            // Push to Watch immediately
            await WatchConnectivityManager.shared.sendMorningDecision(
                score: recoveryScore,
                recommendation: recommendation
            )

            // Push to CloudKit for other devices
            await CloudKitSyncEngine.shared.storeMorningDecision(
                score: recoveryScore,
                recommendation: recommendation
            )

            // Schedule notification if needed
            if recommendation.requiresNotification {
                await scheduleLocalNotification(recommendation)
            }

        } catch {
            AppLogger.shared.error("iPhone morning orchestration failed: \(error)")
            resetFiredFlag()
        }
    }

    private func shouldExecuteToday() -> Bool {
        if hasFiredToday { return false }
        let lastFired = UserDefaults.standard.object(forKey: "iphone_morning_last_fired") as? Date
        if let lastFired = lastFired {
            return !Calendar.current.isDateInToday(lastFired)
        }
        return true
    }

    private func markFiredToday() {
        hasFiredToday = true
        UserDefaults.standard.set(Date(), forKey: "iphone_morning_last_fired")
    }

    private func resetFiredFlag() {
        hasFiredToday = false
    }
}
```

#### Watch Morning Orchestrator (Fallback + Display)

```swift
/// Watch Extension: Morning Orchestration
/// Now acts as FALLBACK trigger and DISPLAY layer, not primary orchestrator

final class WatchMorningOrchestrator {

    static let shared = WatchMorningOrchestrator()

    private let healthStore = HKHealthStore()
    private let recoveryEngine = WatchRecoveryEngine.shared
    private var hasFiredToday = false

    /// Maximum age of Phenome data before we consider it stale
    private let phenomeStalenessThreshold: TimeInterval = 6 * 3600  // 6 hours

    // MARK: - Wrist-Raise Detection

    /// Called from ExtensionDelegate when Watch wakes from wrist raise
    func onWristRaise() {
        Task {
            await handleWristRaise()
        }
    }

    /// Wrist raise handling with staleness check
    private func handleWristRaise() async {
        guard shouldExecuteToday() else {
            // Already fired - just display cached decision
            await displayCachedDecision()
            return
        }

        // Check if iPhone already computed today's decision
        if let cachedDecision = await getCachedMorningDecision(),
           !isStalePhenome(cachedDecision.computedAt) {
            // iPhone did the work - just display
            await displayDecision(cachedDecision)
            markFiredToday()
            return
        }

        // iPhone hasn't computed yet - we need to act
        if await canComputeWithFreshData() {
            // We have fresh enough data - compute locally
            await executeAsBackup()
        } else {
            // Data is stale - degrade to Safe Mode
            await displaySafeModeRecommendation()
        }
    }

    /// Check if our Phenome data is fresh enough to trust
    private func isStalePhenome(_ computedAt: Date) -> Bool {
        return Date().timeIntervalSince(computedAt) > phenomeStalenessThreshold
    }

    /// Can we make a trustworthy decision with current data?
    private func canComputeWithFreshData() async -> Bool {
        guard let phenome = await WatchPhenomeCache.shared.getCurrent() else {
            return false
        }
        return !isStalePhenome(phenome.lastUpdated)
    }

    /// Safe Mode: Generic recommendation when data is stale
    /// Avoids injury risk from making decisions on old data
    private func displaySafeModeRecommendation() async {
        let safeRecommendation = MorningRecommendation(
            action: .suggest,
            originalSlot: nil,
            suggestedSlot: nil,
            suggestedIntensity: .light,
            reason: "Morning check-in pending. Light movement is always safe.",
            requiresNotification: false,
            isSafeMode: true  // Flag for UI to show explanation
        )

        await displayDecision(MorningDecision(
            score: RecoveryScore.unknown,
            recommendation: safeRecommendation,
            computedAt: Date()
        ))

        // Request iPhone sync
        WatchConnectivityManager.shared.requestImmediateSync()
    }

    /// Called from WKApplicationRefreshBackgroundTask
    func onBackgroundRefresh() {
        Task {
            await executeIfNeeded()
        }
    }

    /// Core orchestration logic - idempotent
    func executeIfNeeded() async {
        // Only fire once per calendar day
        guard shouldExecuteToday() else { return }

        // Mark as fired before async work (prevent race conditions)
        markFiredToday()

        do {
            // Step 1: Calculate recovery score from watch sensors
            let recoveryScore = await calculateMorningRecoveryScore()

            // Step 2: Determine optimal workout slot
            let recommendation = await determineOptimalSlot(recoveryScore: recoveryScore)

            // Step 3: Push decision to iPhone (if available) and CloudKit
            await propagateMorningDecision(
                score: recoveryScore,
                recommendation: recommendation
            )

            // Step 4: Update complication with fresh score
            RecoveryComplicationDataSource.requestRefresh()

            // Step 5: Send notification to phone if needed
            if recommendation.requiresNotification {
                await sendMorningNotification(recommendation)
            }

        } catch {
            AppLogger.shared.error("Morning orchestration failed: \(error)")
            // Reset flag to retry on next wrist raise
            resetFiredFlag()
        }
    }

    // MARK: - Day-Gate Logic

    private func shouldExecuteToday() -> Bool {
        // Only run during morning window
        let hour = Calendar.current.component(.hour, from: Date())
        guard (5...10).contains(hour) else { return false }

        // Only run once per calendar day
        if hasFiredToday { return false }

        let lastFired = UserDefaults.standard.object(forKey: "morning_last_fired") as? Date
        if let lastFired = lastFired {
            return !Calendar.current.isDateInToday(lastFired)
        }
        return true
    }

    private func markFiredToday() {
        hasFiredToday = true
        UserDefaults.standard.set(Date(), forKey: "morning_last_fired")
    }

    private func resetFiredFlag() {
        hasFiredToday = false
    }

    // MARK: - Recovery Calculation (Watch-Authoritative)

    private func calculateMorningRecoveryScore() async -> RecoveryScore {
        // Watch has real-time access to overnight data
        let overnight = await fetchOvernightHealthData()

        // Calculate recovery using watch's authoritative data
        let hrvScore = calculateHRVScore(overnight.hrv)
        let sleepScore = calculateSleepScore(overnight.sleep)
        let restingHRScore = calculateRestingHRScore(overnight.restingHR)

        let composite = (hrvScore * 0.4) + (sleepScore * 0.4) + (restingHRScore * 0.2)

        return RecoveryScore(
            overall: Int(composite * 100),
            hrv: overnight.hrv,
            sleepDuration: overnight.sleep,
            restingHeartRate: overnight.restingHR,
            calculatedAt: Date(),
            source: .watch
        )
    }

    private func fetchOvernightHealthData() async -> OvernightData {
        let calendar = Calendar.current
        let now = Date()
        let lastNight9PM = calendar.date(
            bySettingHour: 21,
            minute: 0,
            second: 0,
            of: calendar.date(byAdding: .day, value: -1, to: now)!
        )!

        async let hrv = queryHRV(from: lastNight9PM, to: now)
        async let sleep = querySleepDuration(from: lastNight9PM, to: now)
        async let restingHR = queryRestingHeartRate(from: lastNight9PM, to: now)

        return OvernightData(
            hrv: await hrv,
            sleep: await sleep,
            restingHR: await restingHR
        )
    }

    // MARK: - Optimal Slot Determination

    private func determineOptimalSlot(recoveryScore: RecoveryScore) async -> MorningRecommendation {
        // Get today's schedule from local cache
        let todaySchedule = await WatchScheduleCache.shared.getTodaySchedule()

        // Check if there's a scheduled workout
        if let scheduled = todaySchedule.scheduledWorkout {
            // Evaluate if scheduled time is still optimal given recovery
            if recoveryScore.overall < 40 {
                // Low recovery - suggest lighter workout or reschedule
                return MorningRecommendation(
                    action: .modifyIntensity,
                    originalSlot: scheduled,
                    suggestedIntensity: .light,
                    reason: "Recovery score is \(recoveryScore.overall)%. Light movement recommended.",
                    requiresNotification: true
                )
            } else {
                // Recovery is adequate - confirm scheduled workout
                return MorningRecommendation(
                    action: .confirm,
                    originalSlot: scheduled,
                    suggestedIntensity: recoveryScore.overall > 80 ? .high : .moderate,
                    reason: nil,
                    requiresNotification: false
                )
            }
        } else {
            // No scheduled workout - find optimal slot
            if recoveryScore.overall > 50 {
                let slot = await findBestSlotForToday()
                return MorningRecommendation(
                    action: .suggest,
                    originalSlot: nil,
                    suggestedSlot: slot,
                    suggestedIntensity: recoveryScore.overall > 80 ? .high : .moderate,
                    reason: "Good recovery (\(recoveryScore.overall)%). Workout opportunity at \(slot.formattedTime).",
                    requiresNotification: true
                )
            } else {
                return MorningRecommendation(
                    action: .rest,
                    originalSlot: nil,
                    reason: "Low recovery (\(recoveryScore.overall)%). Rest day recommended.",
                    requiresNotification: false
                )
            }
        }
    }

    // MARK: - Propagation

    private func propagateMorningDecision(score: RecoveryScore, recommendation: MorningRecommendation) async {
        // 1. Store locally on Watch
        await WatchDecisionCache.shared.store(score: score, recommendation: recommendation)

        // 2. Push to iPhone via WatchConnectivity (if reachable)
        let payload = MorningDecisionPayload(
            score: score,
            recommendation: recommendation,
            generatedAt: Date(),
            source: .watch
        )

        if let data = try? JSONEncoder().encode(payload) {
            WatchConnectivityManager.shared.sendData(data, type: .morningDecision)
        }

        // 3. Push to CloudKit for other devices
        await CloudKitSyncEngine.shared.storeMorningDecision(payload)
    }

    // MARK: - Notification to iPhone

    private func sendMorningNotification(_ recommendation: MorningRecommendation) async {
        guard let reason = recommendation.reason else { return }

        WatchConnectivityManager.shared.sendNotificationRequest(
            title: "Morning Check-In",
            body: reason,
            userInfo: ["type": "morning_recommendation"]
        )
    }
}

// MARK: - Supporting Types

struct OvernightData {
    let hrv: Double           // Average overnight HRV
    let sleep: TimeInterval   // Total sleep duration
    let restingHR: Double     // Lowest resting HR
}

struct RecoveryScore: Codable {
    let overall: Int          // 0-100
    let hrv: Double
    let sleepDuration: TimeInterval
    let restingHeartRate: Double
    let calculatedAt: Date
    let source: RecoverySource

    enum RecoverySource: String, Codable {
        case watch
        case phone
        case backend
    }
}

struct MorningRecommendation: Codable {
    enum Action: String, Codable {
        case confirm          // Proceed with scheduled workout
        case modifyIntensity  // Keep time, change intensity
        case suggest          // No workout scheduled, suggest one
        case rest             // Too tired, recommend rest
    }

    enum Intensity: String, Codable {
        case light
        case moderate
        case high
    }

    let action: Action
    let originalSlot: TimeSlot?
    var suggestedSlot: TimeSlot? = nil
    let suggestedIntensity: Intensity?
    let reason: String?
    let requiresNotification: Bool
}

struct MorningDecisionPayload: Codable {
    let score: RecoveryScore
    let recommendation: MorningRecommendation
    let generatedAt: Date
    let source: RecoveryScore.RecoverySource
}

/// Local cache for today's schedule on Watch
actor WatchScheduleCache {
    static let shared = WatchScheduleCache()

    func getTodaySchedule() async -> TodaySchedule {
        // Fetch from local storage (synced from phone or CloudKit)
        TodaySchedule(scheduledWorkout: nil, meetings: [])
    }
}

struct TodaySchedule {
    let scheduledWorkout: TimeSlot?
    let meetings: [TimeSlot]
}

/// Local cache for morning decisions
actor WatchDecisionCache {
    static let shared = WatchDecisionCache()

    func store(score: RecoveryScore, recommendation: MorningRecommendation) async {
        // Persist to UserDefaults for complication access
    }
}
```

**Integration with ExtensionDelegate**:

```swift
// Vigor WatchKit Extension/ExtensionDelegate.swift

class ExtensionDelegate: NSObject, WKApplicationDelegate {

    func applicationDidBecomeActive() {
        // Wrist raise or user interaction
        WatchMorningOrchestrator.shared.onWristRaise()
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                // Background refresh
                WatchMorningOrchestrator.shared.onBackgroundRefresh()
                refreshTask.setTaskCompletedWithSnapshot(false)

            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                snapshotTask.setTaskCompleted(
                    restoredDefaultState: true,
                    estimatedSnapshotExpiration: Date.distantFuture,
                    userInfo: nil
                )

            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
```

**Morning Orchestration Flow:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    WATCH-DRIVEN MORNING ORCHESTRATION                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  User raises wrist ──► ExtensionDelegate.applicationDidBecomeActive()      │
│         │                                                                   │
│         ▼                                                                   │
│  WatchMorningOrchestrator.executeIfNeeded()                                 │
│         │                                                                   │
│         ├── Is it morning (5-10 AM)? ── NO ──► Exit                         │
│         │                                                                   │
│         ├── Already fired today? ── YES ──► Exit                            │
│         │                                                                   │
│         ▼                                                                   │
│  Calculate Recovery Score (Watch-authoritative HRV, sleep, RHR)             │
│         │                                                                   │
│         ▼                                                                   │
│  Determine Optimal Slot (confirm/modify/suggest/rest)                       │
│         │                                                                   │
│         ▼                                                                   │
│  Propagate Decision:                                                        │
│    ├── Local Watch cache (complication reads this)                          │
│    ├── WatchConnectivity → iPhone (if reachable)                            │
│    └── CloudKit → other devices                                             │
│         │                                                                   │
│         ▼                                                                   │
│  iPhone receives via WCSession or CloudKit subscription                     │
│         │                                                                   │
│         ▼                                                                   │
│  iPhone shows notification if recommendation.requiresNotification           │
│                                                                             │
│  KEY BENEFIT: Watch has real-time sensor data, not batched like iPhone      │
│  KEY BENEFIT: Triggers on natural user behavior, not arbitrary clock time   │
│  KEY BENEFIT: Bypasses iOS engagement-based throttling entirely             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Day 1 Magic Implementation

### 5.1 Onboarding Flow

```swift
// OnboardingView.swift
import SwiftUI
import HealthKit
import EventKit

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var currentStep = 0

    var body: some View {
        VStack {
            switch currentStep {
            case 0:
                WelcomeStep(onContinue: { currentStep = 1 })
            case 1:
                HealthDataStep(viewModel: viewModel, onContinue: { currentStep = 2 })
            case 2:
                CalendarStep(viewModel: viewModel, onContinue: { currentStep = 3 })
            case 3:
                ProfileStep(viewModel: viewModel, onContinue: { currentStep = 4 })
            case 4:
                AbsolutionStep(viewModel: viewModel)
            default:
                EmptyView()
            }
        }
    }
}

// Step 4: Quick Profile
struct ProfileStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("A few quick questions")
                    .font(.title2)

                // Equipment
                VStack(alignment: .leading) {
                    Text("What equipment do you have access to?")
                        .font(.headline)

                    Picker("Equipment", selection: $viewModel.equipment) {
                        Text("Bodyweight only").tag(EquipmentLevel.bodyweight)
                        Text("Dumbbells").tag(EquipmentLevel.dumbbells)
                        Text("Home gym").tag(EquipmentLevel.homeGym)
                        Text("Full gym").tag(EquipmentLevel.fullGym)
                    }
                    .pickerStyle(.segmented)
                }

                // Injuries
                VStack(alignment: .leading) {
                    Text("Any injuries or limitations?")
                        .font(.headline)

                    TextField("e.g., bad shoulder, lower back", text: $viewModel.injuries)
                        .textFieldStyle(.roundedBorder)
                }

                Button("Continue") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

// Step 5: The Absolution Moment (Day 1 Magic)
struct AbsolutionStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isAnalyzing {
                    ProgressView("Analyzing your last 90 days...")
                } else if let insight = viewModel.day1Insight {
                    // The Absolution
                    Text("Here's what I see:")
                        .font(.title2)
                        .fontWeight(.bold)

                    VStack(alignment: .leading, spacing: 16) {
                        InsightRow(icon: "figure.walk", text: insight.activitySummary)
                        InsightRow(icon: "bed.double", text: insight.sleepSummary)
                        InsightRow(icon: "calendar", text: insight.scheduleSummary)
                        InsightRow(icon: "dumbbell", text: insight.workoutSummary)
                    }

                    Divider()

                    // The Absolution Message
                    VStack(spacing: 12) {
                        Text("It wasn't your fault you fell off.")
                            .font(.headline)

                        Text(insight.absolutionMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // First scheduled block
                    VStack(spacing: 12) {
                        Text("Your first session")
                            .font(.headline)

                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundColor(.green)
                            Text(insight.firstSessionDescription)
                        }

                        Text("Already on your calendar. We start simple. We start winnable.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button("Let's Go") {
                        viewModel.completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .onAppear {
            Task {
                await viewModel.analyzeHistoricalData()
            }
        }
    }
}

struct Day1Insight {
    let activitySummary: String
    let sleepSummary: String
    let scheduleSummary: String
    let workoutSummary: String
    let absolutionMessage: String
    let firstSessionDescription: String
}
```

---

## 6. Value Receipt (Sunday Summary)

### 6.1 Value Receipt Generator

```swift
// ValueReceiptGenerator.swift
import Foundation

struct ValueReceipt: Codable {
    let weekOf: Date
    let workoutsCompleted: Int
    let workoutsAlmostSkipped: Int  // Ghost saved these

    struct GhostDecision: Codable {
        let date: Date
        let action: String
        let reason: String
    }
    let decisions: [GhostDecision]

    struct RiskSignal: Codable {
        let date: Date
        let signal: String
        let probability: Double?
    }
    let risksDetected: [RiskSignal]

    struct PhenomeInsight: Codable {
        let metric: String
        let trend: String
        let value: String
    }
    let phenomeInsights: [PhenomeInsight]
}

final class ValueReceiptGenerator {

    private let phenomeStore: PhenomeStore
    private let ghostLog: GhostActionLog

    init(phenomeStore: PhenomeStore, ghostLog: GhostActionLog) {
        self.phenomeStore = phenomeStore
        self.ghostLog = ghostLog
    }

    func generateWeeklyReceipt() -> ValueReceipt {
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let phenome = phenomeStore.currentPhenome

        // Workouts this week
        let weekWorkouts = phenome.workoutHistory.filter { $0.date >= weekStart }

        // Ghost decisions this week
        let decisions = ghostLog.actionsThisWeek().map { action -> ValueReceipt.GhostDecision in
            ValueReceipt.GhostDecision(
                date: action.date,
                action: describeAction(action),
                reason: action.reason
            )
        }

        // Risk signals (use probabilistic language per PRD)
        let risks = ghostLog.risksThisWeek().map { risk -> ValueReceipt.RiskSignal in
            ValueReceipt.RiskSignal(
                date: risk.date,
                signal: describeRisk(risk),  // "Elevated strain risk" not "Prevented injury"
                probability: risk.probability
            )
        }

        // Phenome changes
        let insights = generatePhenomeInsights(phenome: phenome, weekStart: weekStart)

        // Count "almost skipped" (high skip probability but completed anyway)
        let almostSkipped = weekWorkouts.filter { workout in
            ghostLog.skipProbability(for: workout.date) > 0.6
        }.count

        return ValueReceipt(
            weekOf: weekStart,
            workoutsCompleted: weekWorkouts.count,
            workoutsAlmostSkipped: almostSkipped,
            decisions: decisions,
            risksDetected: risks,
            phenomeInsights: insights
        )
    }

    private func describeAction(_ action: GhostAction) -> String {
        // Per PRD: Use probabilistic language
        switch action.type {
        case .rescheduled:
            return "Rescheduled session"
        case .transformed:
            return "Adjusted intensity (Heavy → Recovery)"
        case .removed:
            return "Rest day suggested"
        case .scheduled:
            return "Training block added"
        }
    }

    private func describeRisk(_ risk: RiskDetection) -> String {
        // Per PRD §5.2: Probabilistic language
        switch risk.type {
        case .injuryRisk:
            return "Elevated strain risk detected"
        case .skipRisk:
            return "High skip probability (\(Int(risk.probability * 100))%)"
        case .overtraining:
            return "Strain accumulation elevated"
        case .poorRecovery:
            return "Recovery below baseline"
        }
    }
}
```

---

## 7. Cost Management & Budget

### 7.1 Cost Architecture

| Component       | Monthly Cost      | Notes                         |
| --------------- | ----------------- | ----------------------------- |
| Azure Functions | ~$5-10            | Pay-per-execution, serverless |
| Cosmos DB       | ~$15-20           | 400 RU/s autoscale            |
| Azure OpenAI    | ~$10-20           | Per-token, with caching       |
| Storage         | ~$2               | Core ML models, assets        |
| App Insights    | ~$3-5             | Telemetry                     |
| **Total**       | **~$35-55/month** | Well under $100 ceiling       |

### 7.2 Cost Optimization Strategies

```python
# Cost optimization in Azure Functions
from functools import lru_cache
import hashlib

class CostOptimizedOpenAI:
    """Azure OpenAI with aggressive cost optimization."""

    def __init__(self):
        self.client = AzureOpenAI(...)
        self.cache = {}  # In production: Redis or Cosmos DB

    async def generate_workout(self, context: WorkoutContext, exercise_pool: List[Dict]) -> Dict:
        # 1. Check cache first
        cache_key = self._compute_cache_key(context, exercise_pool)
        if cached := self.cache.get(cache_key):
            return cached

        # 2. Use smaller context window
        trimmed_pool = exercise_pool[:15]  # Limit exercises to reduce tokens

        # 3. Generate
        response = await self.client.chat.completions.create(
            model="gpt-5-mini",  # Cost-effective model
            messages=[...],
            max_tokens=1500,  # Limit response size
            temperature=0.7
        )

        workout = json.loads(response.choices[0].message.content)

        # 4. Cache result (1 hour TTL)
        self.cache[cache_key] = workout

        return workout

    def _compute_cache_key(self, context: WorkoutContext, pool: List[Dict]) -> str:
        """Create cache key from workout parameters."""
        key_data = {
            "duration": context.duration_minutes,
            "equipment": sorted(context.equipment),
            "goal": context.goal,
            "pool_ids": sorted([e["id"] for e in pool])
        }
        return hashlib.sha256(json.dumps(key_data).encode()).hexdigest()
```

### 7.3 Per-User Limits

```python
# Rate limiting per user tier
class UserLimits:
    FREE_TIER = {
        "monthly_workout_generations": 10,
        "monthly_ai_chats": 20,
        "max_stored_workouts": 50
    }

    PREMIUM_TIER = {
        "monthly_workout_generations": None,  # Unlimited
        "monthly_ai_chats": None,
        "max_stored_workouts": None
    }

async def check_user_limits(user_id: str, operation: str) -> bool:
    """Check if user can perform operation within limits."""
    cosmos = CosmosClient()
    user = await cosmos.get_user_profile(user_id)

    tier = user.get("tier", "free")
    limits = UserLimits.FREE_TIER if tier == "free" else UserLimits.PREMIUM_TIER

    if limits.get(f"monthly_{operation}") is None:
        return True  # Unlimited

    # Count this month's usage
    usage = await cosmos.count_monthly_usage(user_id, operation)
    return usage < limits[f"monthly_{operation}"]
```

---

## 8. Battery Budget & Platform Constraints

> **HARDENED**: Explicit constraints for iOS/watchOS background execution limits.

### 8.1 iOS Background Execution Budget

| Operation                 | Frequency                   | Battery Impact | Constraint                              |
| ------------------------- | --------------------------- | -------------- | --------------------------------------- |
| **Workout Detection**     | Immediate (HKObserverQuery) | Low            | Wakes app AFTER workout, not continuous |
| **Sleep Analysis**        | Hourly                      | Minimal        | Batched via HKStatisticsCollectionQuery |
| **HRV Sampling**          | Hourly                      | Minimal        | Aggregate queries only                  |
| **Morning Ghost Cycle**   | Once/day ~6 AM              | Low            | BGAppRefreshTask, 30s max               |
| **Evening Ghost Cycle**   | Once/day ~9 PM              | Low            | BGAppRefreshTask, 30s max               |
| **Deep Pattern Analysis** | Overnight only              | Medium         | BGProcessingTask, charging required     |

### 8.2 watchOS Background Constraints

```swift
// WatchBackgroundBudget.swift
struct WatchBackgroundBudget {

    /// Maximum background runtime per hour
    static let maxBackgroundMinutesPerHour = 4  // Apple's limit

    /// Operations and their costs
    enum Operation: Double {
        case workoutDetection = 0.5    // Very light
        case complicationUpdate = 0.2  // Light
        case healthDataSync = 1.0      // Moderate
        case fullPhoneSync = 2.0       // Heavy
    }

    /// Track cumulative budget usage
    private static var hourlyUsage: Double = 0
    private static var hourStart: Date = Date()

    static func canExecute(_ operation: Operation) -> Bool {
        resetIfNewHour()
        return hourlyUsage + operation.rawValue <= Double(maxBackgroundMinutesPerHour)
    }

    static func recordExecution(_ operation: Operation) {
        hourlyUsage += operation.rawValue
    }

    private static func resetIfNewHour() {
        if Date().timeIntervalSince(hourStart) > 3600 {
            hourlyUsage = 0
            hourStart = Date()
        }
    }
}
```

### 8.3 Background Task Registration

```swift
// BackgroundTaskManager.swift
import BackgroundTasks

class BackgroundTaskManager {

    static let morningCycleIdentifier = "com.vigor.ghost.morning"
    static let eveningCycleIdentifier = "com.vigor.ghost.evening"
    static let deepAnalysisIdentifier = "com.vigor.ghost.deepAnalysis"

    static func registerTasks() {
        // Morning Ghost Cycle (lightweight)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: morningCycleIdentifier,
            using: nil
        ) { task in
            handleMorningCycle(task: task as! BGAppRefreshTask)
        }

        // Evening Ghost Cycle (lightweight)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: eveningCycleIdentifier,
            using: nil
        ) { task in
            handleEveningCycle(task: task as! BGAppRefreshTask)
        }

        // Deep Analysis (heavy, overnight only)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: deepAnalysisIdentifier,
            using: nil
        ) { task in
            handleDeepAnalysis(task: task as! BGProcessingTask)
        }
    }

    static func scheduleMorningCycle() {
        let request = BGAppRefreshTaskRequest(identifier: morningCycleIdentifier)

        // Schedule for ~6 AM tomorrow
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 6
        components.minute = 0
        request.earliestBeginDate = Calendar.current.date(from: components)

        try? BGTaskScheduler.shared.submit(request)
    }

    static func scheduleDeepAnalysis() {
        let request = BGProcessingTaskRequest(identifier: deepAnalysisIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = true  // CRITICAL: Only when charging

        // Schedule for overnight (1-5 AM)
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 2
        request.earliestBeginDate = Calendar.current.date(from: components)

        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handleMorningCycle(task: BGAppRefreshTask) {
        // Set expiration handler
        task.expirationHandler = {
            // Save state and clean up
        }

        Task {
            let engine = GhostEngine()
            await engine.runMorningCycle()

            // Schedule next morning
            scheduleMorningCycle()

            task.setTaskCompleted(success: true)
        }
    }

    private static func handleDeepAnalysis(task: BGProcessingTask) {
        task.expirationHandler = {
            // Save partial progress
        }

        Task {
            let observer = HealthKitObserver()
            await observer.performDeepAnalysisIfCharging()

            task.setTaskCompleted(success: true)
        }
    }
}
```

### 8.4 Critical Platform Constraints

| Constraint                                | Impact                            | Mitigation                                   |
| ----------------------------------------- | --------------------------------- | -------------------------------------------- |
| **iOS kills apps using >80% CPU for 60s** | Day 1 import would fail           | Use HKStatisticsCollectionQuery (aggregates) |
| **BGAppRefreshTask max 30s runtime**      | Ghost cycles must be fast         | Pre-compute, cache aggressively              |
| **watchOS 4-min/hour background limit**   | Watch can't run complex logic     | Phone does heavy lifting, Watch reports      |
| **HealthKit background delivery batched** | Not real-time for all types       | Use HKObserverQuery for workouts only        |
| **EventKit sync can be slow**             | Calendar writes may fail silently | Local-only calendar, retry logic             |

---

## 9. Security & Privacy

### 9.1 Data Classification

| Data Type             | Storage Location  | Encryption         | Server Access |
| --------------------- | ----------------- | ------------------ | ------------- |
| Raw HealthKit data    | On-device only    | iOS keychain       | Never         |
| Calendar event titles | On-device only    | iOS keychain       | Never         |
| Phenome patterns      | Device + CloudKit | E2E (Apple keys)   | Never         |
| User profile          | Cosmos DB         | At-rest encryption | Yes           |
| Workout plans         | Cosmos DB         | At-rest encryption | Yes           |
| Anonymized aggregates | Cosmos DB         | At-rest encryption | Yes           |

### 9.2 Authentication Flow

```swift
// Sign in with Apple (required)
import AuthenticationServices

class AuthenticationManager: NSObject, ObservableObject, ASAuthorizationControllerDelegate {

    @Published var isAuthenticated = false
    @Published var userID: String?

    func signIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

        let userID = credential.user
        let identityToken = credential.identityToken

        // Send to backend for verification
        Task {
            await authenticateWithBackend(userID: userID, token: identityToken)
        }
    }

    private func authenticateWithBackend(userID: String, token: Data?) async {
        guard let token = token,
              let tokenString = String(data: token, encoding: .utf8) else { return }

        let response = try? await APIClient.shared.authenticate(appleToken: tokenString)

        if response?.success == true {
            self.userID = userID
            self.isAuthenticated = true

            // Store refresh token securely
            try? KeychainManager.store(key: "refreshToken", value: response?.refreshToken ?? "")
        }
    }
}
```

### 8.3 Privacy Guarantees

```swift
// Privacy policy enforcement
struct PrivacyGuarantees {

    /// Data that NEVER leaves the device
    static let deviceOnlyData: Set<String> = [
        "raw_healthkit_samples",
        "calendar_event_titles",
        "calendar_attendees",
        "location_history",
        "sleep_stage_details",
        "heart_rate_samples"
    ]

    /// Data sent to server (always encrypted in transit)
    static let serverData: Set<String> = [
        "user_profile",          // Equipment, injuries, goals
        "workout_requests",      // Duration, type, equipment
        "anonymized_aggregates"  // Hashed patterns only
    ]

    /// Data synced via CloudKit (E2E encrypted, Apple manages keys)
    static let cloudKitData: Set<String> = [
        "phenome",              // Full pattern data
        "workout_history",      // Local workout records
        "trust_progression"     // Ghost trust state
    ]
}
```

---

## 9. Monitoring & Observability

### 9.1 Telemetry (Anonymized)

```python
# Application Insights integration
from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry import trace

configure_azure_monitor(
    connection_string=os.environ["APPLICATIONINSIGHTS_CONNECTION_STRING"]
)

tracer = trace.get_tracer(__name__)

# Track Ghost operations (anonymized)
async def track_ghost_decision(decision_type: str, confidence: float, phase: int):
    with tracer.start_as_current_span("ghost_decision") as span:
        span.set_attributes({
            "decision.type": decision_type,
            "decision.confidence": confidence,
            "user.trust_phase": phase,
            # NO user_id, NO PII
        })
```

### 9.2 Health Checks

```python
@app.route(route="health", methods=["GET"])
async def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """Comprehensive health check."""

    checks = {}

    # Cosmos DB
    try:
        cosmos = CosmosClient()
        await cosmos.ping()
        checks["cosmos_db"] = "healthy"
    except Exception as e:
        checks["cosmos_db"] = f"unhealthy: {str(e)}"

    # Azure OpenAI
    try:
        openai = OpenAIClient()
        await openai.ping()
        checks["openai"] = "healthy"
    except Exception as e:
        checks["openai"] = f"unhealthy: {str(e)}"

    # Storage (for model distribution)
    try:
        storage = StorageClient()
        await storage.ping()
        checks["storage"] = "healthy"
    except Exception as e:
        checks["storage"] = f"unhealthy: {str(e)}"

    overall = "healthy" if all(v == "healthy" for v in checks.values()) else "degraded"

    return func.HttpResponse(
        json.dumps({
            "status": overall,
            "checks": checks,
            "version": "2.0.0",
            "timestamp": datetime.utcnow().isoformat()
        }),
        mimetype="application/json"
    )
```

---

## 10. Deployment & CI/CD

### 10.1 iOS App Deployment

```yaml
# .github/workflows/ios-deploy.yml
name: iOS Build and Deploy

on:
  push:
    branches: [main]
    paths:
      - "ios/**"

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: "15.2"

      - name: Install dependencies
        run: |
          cd ios
          xcodebuild -resolvePackageDependencies

      - name: Build and Archive
        run: |
          cd ios
          xcodebuild archive \
            -scheme Vigor \
            -archivePath build/Vigor.xcarchive \
            -configuration Release

      - name: Upload to TestFlight
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
        run: |
          xcrun altool --upload-app \
            --file build/Vigor.ipa \
            --apiKey $APP_STORE_CONNECT_API_KEY
```

### 10.2 Azure Functions Deployment

```yaml
# .github/workflows/azure-functions.yml
name: Deploy Azure Functions

on:
  push:
    branches: [main]
    paths:
      - "functions-modernized/**"

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install dependencies
        run: |
          cd functions-modernized
          pip install -r requirements.txt

      - name: Deploy to Azure Functions
        uses: Azure/functions-action@v1
        with:
          app-name: "vigor-functions"
          package: "functions-modernized"
          publish-profile: ${{ secrets.AZURE_FUNCTIONAPP_PUBLISH_PROFILE }}
```

---

## 11. Success Metrics Implementation

### 11.1 PRD Metrics Tracking

| Metric              | Target  | Implementation                                          |
| ------------------- | ------- | ------------------------------------------------------- |
| Time to First Magic | < 5 min | Track `onboarding_completed` timestamp vs `app_install` |
| Weekly Active Rate  | 80%+    | Count users with ≥1 Ghost interaction per week          |
| Proactive Sessions  | 60%+    | Track workouts from Ghost-scheduled blocks              |
| Zero-Input Workouts | 40%+    | Track auto-logged workouts (one-tap confirm)            |
| App Opens per Week  | < 3     | Track `app_foreground` events                           |
| 30-Day Retention    | 50%+    | Cohort analysis on user activity                        |

### 11.2 Anti-Metrics

```python
# Track anti-metrics to ensure Ghost is working
class AntiMetrics:
    """
    Per PRD: These metrics should be LOW for a successful Ghost.
    High values indicate the app is nagging, not helping.
    """

    @staticmethod
    async def track_notification_tap_rate(user_hash: str, tapped: bool):
        """High tap rate = too many notifications (bad)"""
        # Log but alert if aggregate tap rate > 50%
        pass

    @staticmethod
    async def track_time_in_app(user_hash: str, session_duration_seconds: int):
        """High time in app = too much friction (bad)"""
        # Alert if average session > 5 minutes
        pass

    @staticmethod
    async def track_daily_active_users():
        """High DAU relative to WAU = users checking too often (bad)"""
        # Ghost succeeds when DAU/WAU < 0.5
        pass
```

---

## Appendix A: Glossary

| Term                   | Definition                                                 |
| ---------------------- | ---------------------------------------------------------- |
| **Ghost**              | Vigor's operational mode - working invisibly in background |
| **Phenome**            | Personal patterns unique to each user (on-device)          |
| **Trust Ladder**       | 5-phase progression from Observer to Full Ghost            |
| **Silent Calendar**    | Calendar blocks that appear without notification           |
| **Zero-Input Workout** | Workout logged with one-tap confirmation only              |
| **Value Receipt**      | Weekly proof-of-value summary (Sunday)                     |
| **Sacred Time**        | Protected slots that Ghost never schedules over            |
| **Contextual Silence** | Not scheduling when conditions are poor                    |

---

## Appendix B: API Reference

### Workout Generation

```
POST /api/workouts/generate
Authorization: Bearer <apple_token>

Request:
{
  "duration": 30,
  "equipment": ["dumbbells"],
  "limitations": ["shoulder"],
  "recentMuscleGroups": ["chest", "back"],
  "recoveryScore": 0.7,
  "timeOfDay": "morning",
  "goal": "strength"
}

Response:
{
  "id": "workout_uuid",
  "name": "Upper Body Strength",
  "exercises": [...],
  "metadata": {...}
}
```

### Ghost Sync

```
POST /api/ghost/sync
Authorization: Bearer <apple_token>

Request:
{
  "avgSleepHours": 6.5,
  "workoutFrequency": 3.2,
  "skipRate": 0.15,
  "optimalTimeBucket": "morning",
  "trustPhase": 3,
  "daysActive": 45
}

Response:
{
  "synced": true
}
```

### Model Manifest

```
GET /api/models/manifest

Response:
{
  "models": [
    {
      "name": "SleepImpactClassifier",
      "version": "1.2.0",
      "url": "https://...",
      "checksum": "sha256:..."
    }
  ],
  "updated_at": "2026-01-26T00:00:00Z"
}
```

---

_"Build me a ghost. A ghost that watches over me, knows when I am weak, knows when I am strong, and whispers exactly what I need to survive the modern world."_
