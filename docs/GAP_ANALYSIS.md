# Vigor Gap Analysis Report

**Generated**: 2026-01-28
**Spec Versions**: PRD v5.0 | Tech Spec v2.6 | UX Spec v1.3
**Scope**: iOS App, Backend, Frontend, Watch, Testing, CI/CD

---

## Executive Summary

The Vigor codebase has strong foundations across the core Ghost Engine, Trust State Machine, Phenome data model, calendar scheduling, notification orchestration, and onboarding flow. However, several critical spec requirements remain unimplemented — most notably CloudKit sync, the Emergency/Red Button system, Siri Shortcuts, and explainability UI. Core ML models are placeholder (rule-based fallbacks). The backend lacks the hybrid workout template engine, model distribution endpoint, and watch direct-sync endpoint. Testing coverage has significant holes in Calendar, Health, Phenome, and Onboarding domains.

**Gap Count**: 42 gaps identified (7 P0, 12 P1, 15 P2, 8 P3)

---

## GAPS FOUND

### P0 — Critical / Blocks Core Product Promise

#### P0-1: CloudKit Sync — EMPTY

- **Spec**: Tech Spec §2.4 requires CloudKit E2E encrypted Phenome sync with "Highest Trust Wins" merge policy. Trust State must sync independently and survive device restore.
- **Status**: `ios/Vigor/Data/CloudKit/` is **empty**. No CloudKit container, no record types, no sync engine.
- **Impact**: Device restore resets Ghost to Observer mode. Multi-device (iPhone ↔ iPad) loses all trust progression. Single point of failure on local Core Data.
- **Files needed**: `CloudKitSyncEngine.swift`, `TrustStateConflictResolver.swift`, CloudKit container configuration in entitlements.

#### P0-2: Core ML Models — Placeholder Only

- **Spec**: Tech Spec §2.7 specifies three trained Core ML models: `SleepImpactClassifier`, `SkipPredictor`, `RecoveryAnalyzer`. Tech Spec §3.2 requires backend model distribution endpoint (`GET /api/models/manifest`).
- **Status**: `SkipPredictor.swift` line 66: `"// Placeholder for now"` — loads no `.mlmodelc` bundle. All four ML files (`SkipPredictor`, `RecoveryAnalyzer`, `OptimalWindowFinder`, `PatternDetector`) use rule-based heuristics with no trained model.
- **Impact**: Pattern detection accuracy is minimal. Ghost decisions lack ML-driven personalization. Skip prediction, recovery analysis, and optimal window finding are all approximations.
- **Files needed**: Trained `.mlmodel` files in bundle, model loading code in each predictor, backend `models/manifest` endpoint in blueprints.

#### P0-3: Emergency / Red Button System — EMPTY

- **Spec**: PRD §4.9 requires an "I'm crashing" Siri Shortcut and crisis protocol. UX Spec §6.1 specifies the Red Button flow: immediately drops to recovery mode, cancels all upcoming blocks, sends reassurance.
- **Status**: `ios/Vigor/Core/Emergency/` is **empty**. No crisis protocol, no emergency UI, no Siri shortcut.
- **Impact**: When users are burned out/injured, there's no escape hatch. They'll delete the app instead of using a safe off-ramp.
- **Files needed**: `EmergencyProtocol.swift`, `CrisisManager.swift`, associated UI view, Siri Intent definition.

#### P0-4: Siri Shortcuts / App Intents — NOT IMPLEMENTED

- **Spec**: Tech Spec §2.1 and PRD §4.9 require Siri Shortcuts for "I'm crashing" and quick commands. `InfoPlist.swift` line 140 has `<!-- Siri (future) -->` comment with the entitlement key present but no implementation.
- **Status**: No `AppIntent` definitions, no `SiriKit` intent handling, no `.intentdefinition` file.
- **Impact**: Voice-driven emergency protocol impossible. Missing a key hands-free interaction model for workout context.
- **Files needed**: `AppIntents/` directory with intent definitions, shortcut donation logic.

#### P0-5: Remote Ghost Configuration — NOT IMPLEMENTED

- **Spec**: Tech Spec §2.8 specifies `GhostConfigManager` downloading config from Azure Blob Storage (`vigorstorage/config/ghost-config.json`). Config controls trust thresholds, skip prediction weights, recovery settings, scheduling rules, notification throttling.
- **Status**: No `GhostConfigManager.swift` found in codebase. Grep for `GhostConfig|RemoteConfig` returns zero results. All heuristic values are hardcoded.
- **Impact**: Cannot tune Ghost behavior without App Store updates. No A/B testing capability. Every threshold change requires a full release cycle.
- **Files needed**: `GhostConfigManager.swift`, Azure Blob Storage config file, config validation logic.

#### P0-6: Backend Hybrid Workout Template Engine — NOT IMPLEMENTED

- **Spec**: Tech Spec §3.2 specifies Dynamic Skeleton engine handling ~90% of workout requests (instant, free) with RAG+LLM fallback for edge cases. Includes `WorkoutContract` safety validation.
- **Status**: Backend `workouts_bp.py` has a `generate_workout` endpoint but grep for `template|skeleton|WorkoutTemplate` in `functions-modernized/shared/` returns zero. No template engine, no dynamic skeleton logic, no workout contracts.
- **Impact**: Every workout generation call hits the LLM ($0.003/request). No instant fallback. No safety validation guardrails. Cost scales linearly with users.
- **Files needed**: `shared/templates.py`, `shared/workout_contracts.py`, skeleton expansion into `workouts_bp.py`.

#### P0-7: Backend Model Distribution Endpoint — MISSING

- **Spec**: Tech Spec §3.2 defines `GET /api/models/manifest` for Core ML model version distribution.
- **Status**: Not present in any blueprint. No manifest endpoint.
- **Impact**: No mechanism to update on-device ML models without App Store release.
- **Files needed**: New endpoint in `ghost_bp.py` or dedicated `models_bp.py`.

---

### P1 — High / Degrades Key Experience

#### P1-1: Explainability / Decision Log UI — EMPTY

- **Spec**: UX Spec §6.2 requires "Why did this happen?" UI showing Ghost decision receipts. Tech Spec §2.4 has full `DecisionReceiptStore` spec with `explainDecision()` API.
- **Status**: `ios/Vigor/UI/Explainability/` is **empty**. Backend `DecisionReceiptStore.swift` exists in Ghost Engine but no UI surfaces it.
- **Impact**: Users can't understand Ghost decisions. Trust erodes when actions feel arbitrary.
- **Files needed**: `ExplainabilityView.swift`, `DecisionLogView.swift`.

#### P1-2: Fallback / Degradation UI — EMPTY

- **Spec**: UX Spec §3.6 requires graceful degradation states (no Watch, no calendar access, poor connectivity). `GhostHealthMonitor` has modes (healthy → degraded → safeMode → suspended) but no UI.
- **Status**: `ios/Vigor/UI/Fallback/` is **empty**. `GhostHealthMonitor.swift` posts `NotificationCenter` events but nothing listens in the UI layer.
- **Impact**: When Ghost degrades, user sees nothing. Silent failures lead to confusion and app deletion.
- **Files needed**: `DegradationBannerView.swift`, `SafeModeView.swift`, notification observers in `HomeView`.

#### P1-3: Haptic Vocabulary — Incomplete

- **Spec**: UX Spec §4.6 specifies a rich haptic vocabulary including WatchKit haptics, breathing-pattern haptics for trust advancement, and distinct patterns for each Ghost action type. Tech Spec mentions CoreHaptics engine.
- **Status**: `VigorHaptics.swift` has only 4 basic `UIKit` haptic methods (`trustAdvancement`, `blockScheduled`, `workoutCompleted`, `warning`). No `CoreHaptics` engine, no WatchKit haptics, no breathing pattern.
- **Impact**: Haptic communication — a key invisible feedback channel — is minimal. Trust advancement feels like any other notification.
- **Files needed**: Expand `VigorHaptics.swift` with `CHHapticEngine`, add `WKInterfaceDevice.default().play()` calls in Watch app.

#### P1-4: Value Receipt — Missing Sharing / Clean Mode

- **Spec**: UX Spec §5.3 requires shareable Value Receipt with "Clean Mode" (strips personal data for social sharing). PRD §5.2 specifies the Sunday evening delivery.
- **Status**: `ValueReceiptView.swift` and `ValueReceiptGenerator.swift` exist, but grep for `Clean Mode|cleanMode|shareable|sharing` returns zero results.
- **Impact**: Value Receipt can't be shared socially. Missing a key virality/word-of-mouth mechanism.
- **Files needed**: Add sharing/export logic and Clean Mode data stripping to `ValueReceiptView.swift`.

#### P1-5: Bidirectional Feedback Engine — NOT IMPLEMENTED

- **Spec**: Tech Spec §2.13 specifies full `FeedbackEngine` with implicit signals, 1-tap post-workout intensity check (Watch), `RecommendationWeightAdjuster`, and micro-feedback capture.
- **Status**: No `FeedbackEngine.swift` in codebase. `WorkoutFeedbackCard` in `TriageCard.swift` exists for one-time triage but doesn't feed into a learning system.
- **Impact**: Ghost doesn't learn from user behavior. Recommendations don't improve over time. The "gets smarter" promise is hollow.
- **Files needed**: `FeedbackEngine.swift`, `RecommendationWeightAdjuster.swift`, Watch intensity feedback UI.

#### P1-6: User Health Profile State Machine — NOT IMPLEMENTED

- **Spec**: Tech Spec §2.12 defines `HealthProfileStateMachine` with phases: baseline → adaptation → maintenance → regression. Controls personalization intensity.
- **Status**: Not implemented. No health profile phases. Ghost treats all users identically regardless of data richness.
- **Impact**: Day-1 users get same personalization as day-60 users. No baseline establishment. No regression detection.
- **Files needed**: `HealthProfileStateMachine.swift`, `UserHealthProfile.swift`.

#### P1-7: Backend Watch Direct-Sync Endpoint — MISSING

- **Spec**: Tech Spec §4.4 defines `POST /api/watch/workouts` for Watch autonomous workout logging when iPhone is unavailable.
- **Status**: Not present in any backend blueprint.
- **Impact**: Watch can't sync workouts independently. If iPhone is out of Bluetooth range, workouts queue indefinitely.
- **Files needed**: Add endpoint to `workouts_bp.py` or new `watch_bp.py`.

#### P1-8: Backend User Tier Model — Incomplete

- **Spec**: PRD pricing section defines FREE and PREMIUM tiers with limits (10 AI generations/month for free, unlimited for premium). Tech Spec §7.3 defines `UserLimits` with `FREE_TIER` and `PREMIUM_TIER`.
- **Status**: `shared/models.py` `UserTier` enum has only `FREE` and `ADMIN`. No `PREMIUM` tier. No rate limiting by tier. `_validate_ai_budget` exists in `workouts_bp.py` but only checks admin-level budgets, not per-user tier limits.
- **Impact**: Cannot enforce free tier limits. Cannot monetize. All users get unlimited access.
- **Files needed**: Add `PREMIUM` to `UserTier`, implement per-user rate limiting in workout/coaching endpoints.

#### P1-9: Insight TTL & Lifecycle Management — NOT IMPLEMENTED

- **Spec**: Tech Spec §2.10 specifies `InsightLifecycleManager` with per-type TTL policies, emergency cleanup, and cold storage archival.
- **Status**: No lifecycle management for insights or decision receipts.
- **Impact**: Core Data / storage will bloat over time. Stale insights accumulate without cleanup.
- **Files needed**: `InsightLifecycleManager.swift`.

#### P1-10: Calendar Shadow Sync (Exchange/Outlook) — Stub Only

- **Spec**: Tech Spec §2.6 specifies `CalendarShadowSync` with Microsoft Graph API for writing "Busy" blocks to work calendar, plus `MDMFallbackHandler` for enterprise environments and `CalendarMultiplexer` for multi-source reading.
- **Status**: `CalendarShadowSync.swift` exists in `Data/Calendar/` but `MSGraphClient.shared` is `nil` (stub). `MDMFallbackHandler` and `CalendarMultiplexer` don't exist as separate implementations.
- **Impact**: Colleagues can't see training blocks. Corporate users will have workouts booked over.
- **Files needed**: Full Graph API integration, MDM detection, calendar multiplexer.

#### P1-11: Three-Layer Health Data Model — Partially Implemented

- **Spec**: Tech Spec §2.10 defines three distinct layers: Raw Signal Store (immutable), Derived Metric Engine (versioned), Ephemeral Insight Generator.
- **Status**: `RawSignalStore`, `DerivedStateStore`, and `BehavioralMemoryStore` exist in `Core/Phenome/` with Core Data entities. However, `DerivedMetricEngine` (versioned computation with provenance), `MetricRegistry`, and `InsightGenerator` (Layer 3 ephemeral) are not implemented.
- **Impact**: No versioned recomputation. No provenance tracking. Can't answer "why did my score change?" No metric registry for A/B testing.
- **Files needed**: `DerivedMetricEngine.swift`, `MetricRegistry.swift`, `InsightGenerator.swift`.

#### P1-12: Failure Disambiguation (One-Tap Triage on Miss) — Partially Implemented

- **Spec**: Tech Spec §2.13 specifies `FailureDisambiguator` with 5 triage options shown on next app open after a missed block.
- **Status**: `FailureDisambiguator.swift` exists in `Core/GhostEngine/` and `TriageCard.swift` has a missed-workout card type. However, the full flow (detection → queueing → on-foreground presentation → learning) may not be fully wired.
- **Impact**: Missed blocks may be treated as generic negative signals, poisoning the model.
- **Files needed**: Verify wiring; may need integration fixes rather than new files.

---

### P2 — Medium / Missing Feature or Coverage

#### P2-1: WidgetKit Integration — NOT IMPLEMENTED

- **Spec**: UX Spec §4.5 requires home screen widgets showing recovery score, next workout, weekly streak. PRD implies widget as a low-friction surface.
- **Status**: No WidgetKit code found anywhere in the project. Grep returns zero results.
- **Impact**: Missing a key engagement surface that doesn't require app open.
- **Files needed**: New `VigorWidget/` target with widget definitions.

#### P2-2: Watch Complication — Partially Implemented

- **Spec**: Tech Spec §2.9 specifies complication-driven wakes as part of Invisibility Paradox mitigation. §4.3 has full `ComplicationController` with recovery ring, next workout time, and `RecoveryComplicationDataSource` for timeline refresh.
- **Status**: `ComplicationController.swift` exists (403 lines, includes placeholder comments) but `RecoveryComplicationDataSource` for timeline-driven wakes is not confirmed implemented. Complication data appears to use hardcoded values.
- **Impact**: Complication-driven background execution (Strategy 2 of Invisibility Paradox) may not function, reducing reliability of Ghost cycles.
- **Files needed**: Verify/implement `RecoveryComplicationDataSource`, connect to real recovery data.

#### P2-3: Watch Autonomous Sync — Partially Implemented

- **Spec**: Tech Spec §4.4 requires Watch to function 100% without iPhone. Includes direct backend sync via WiFi/Cellular, offline queue, and HKObserverQuery debouncing.
- **Status**: `WatchWorkoutManager.swift` (357+ lines) exists with HKWorkoutSession support. `WatchConnectivityManager.swift` exists. However, `WatchAutonomousSync` (direct backend calls, offline queue) is not confirmed.
- **Impact**: Watch may not sync workouts when iPhone is unavailable.
- **Files needed**: `WatchAutonomousSync.swift`, offline queue management.

#### P2-4: Test Coverage — Calendar, Health, Phenome, Onboarding, Haptics

- **Spec**: Comprehensive testing required across all domains.
- **Status**: Empty test directories: `VigorTests/Calendar/`, `VigorTests/Health/`, `VigorTests/Phenome/`, `VigorTests/Onboarding/`, `VigorTests/Haptics/`, `VigorTests/Context/`.
- **Impact**: Calendar scheduling (critical path), HealthKit import, Phenome data integrity, onboarding flow, and haptics have zero test coverage.
- **Files needed**: Test files for each empty directory.

#### P2-5: Backend RAG Exercise Knowledge Base — NOT IMPLEMENTED

- **Spec**: Tech Spec §3.3 specifies `ExerciseRAG` class using Azure AI Search (`exercise-knowledge-base` index) for retrieval-augmented workout generation.
- **Status**: No `shared/rag.py` file. No Azure AI Search integration. Workout generation goes directly to LLM without grounding.
- **Impact**: Generated workouts may include hallucinated exercises. No equipment/contraindication filtering at retrieval layer.
- **Files needed**: `shared/rag.py`, Azure AI Search index configuration.

#### P2-6: Backend APNs Implementation — Partial

- **Spec**: Tech Spec §2.9 requires server-side silent push notifications at strategic times (5:55 AM morning wake, pre-workout refresh, calendar sync).
- **Status**: `shared/apns_client.py` exists. `ghost_bp.py` has `ghost_morning_wake_trigger` (timer) and `ghost_silent_push` endpoint. However, timer triggers need Azure Function timer binding configuration verification.
- **Impact**: May not reliably wake apps for morning/evening cycles if timer triggers aren't properly configured.
- **Files needed**: Verify timer trigger bindings in `host.json` and function configuration.

#### P2-7: iPhoneMorningEngine — NOT IMPLEMENTED

- **Spec**: Tech Spec §4.5 defines `iPhoneMorningEngine` as the PRIMARY path for morning orchestration (receives silent push at 5:55 AM, computes recovery, pushes to Watch).
- **Status**: `GhostEngine.swift` has `runMorningCycle()` and `runEveningCycle()` but the explicit `iPhoneMorningEngine` with silent-push-driven execution, Watch Phenome push, and CloudKit sync isn't a distinct component.
- **Impact**: Morning orchestration may rely solely on BGTaskScheduler (throttled by iOS for low-engagement apps — the Invisibility Paradox).
- **Files needed**: Wire `SilentPushReceiver` → `GhostEngine.runMorningCycle()` path, ensure idempotency.

#### P2-8: Computation Tier Scheduler — NOT IMPLEMENTED

- **Spec**: Tech Spec §2.11 defines three computation tiers (realTime < 100ms, nearRealTime hourly, offlineBatch overnight+charging) with `ComputationScheduler` enforcing which metrics run where.
- **Status**: No `ComputationScheduler`. All metric computation appears ad-hoc.
- **Impact**: Battery drain from running heavy computations at wrong times. No enforcement of overnight-only deep analysis.
- **Files needed**: `ComputationScheduler.swift`.

#### P2-9: Backend Workout Safety Contracts — NOT IMPLEMENTED

- **Spec**: Tech Spec §3.4 specifies `WorkoutContract` with volume caps, progression limits, forbidden exercise combinations, and injury contraindication checks. `SafeWorkoutGenerator` wraps generation with contract enforcement.
- **Status**: `WorkoutSafetyValidator` class exists in `shared/models.py` but no `WorkoutContract` or `SafeWorkoutGenerator`.
- **Impact**: Generated workouts may exceed safe volume limits. No protection against LLM hallucinating dangerous exercise combinations.
- **Files needed**: `shared/workout_contracts.py`.

#### P2-10: Backend Streaming Workout Generation — NOT CONFIRMED

- **Spec**: Tech Spec §3.2 specifies NDJSON streaming for workout generation (warmup instant, exercises streamed, cooldown instant).
- **Status**: `workouts_bp.py` has `generate_workout` but streaming variant using `application/x-ndjson` is not confirmed.
- **Impact**: Users wait 2-5 seconds staring at a spinner instead of seeing progressive results.
- **Files needed**: Add streaming response support to `generate_workout` endpoint.

#### P2-11: Privacy Info — Incomplete

- **Spec**: Tech Spec §9 specifies comprehensive data classification. Apple requires PrivacyInfo.xcprivacy for App Store submission.
- **Status**: `PrivacyInfo.xcprivacy` exists with some entries including coarse location. Needs audit against actual data collection.
- **Impact**: App Store rejection risk if privacy manifest doesn't match actual data usage.
- **Files needed**: Audit and update `PrivacyInfo.xcprivacy`.

#### P2-12: Backend Cost Metrics — Partial

- **Spec**: Tech Spec §7.1-7.3 specifies cost tracking per-user with caching, limits, and optimization.
- **Status**: `admin_bp.py` has `get_cost_metrics` endpoint. `workouts_bp.py` has `_validate_ai_budget`. But no per-user cost tracking or caching.
- **Impact**: Cannot identify cost outliers or enforce per-user limits.
- **Files needed**: Enhance cost tracking with per-user granularity.

#### P2-13: Onboarding Absolution — Partially Implemented

- **Spec**: PRD §5.1 / UX Spec §5.2 specify the "Absolution Moment" — analyzing 90 days of HealthKit data to generate a personalized first insight within 5 minutes.
- **Status**: `FirstInsightGenerator.swift` (391 lines) exists and generates insights. `OnboardingFlow.swift` has an `absolution` step. However, the connection between `FirstInsightGenerator` and the absolution UI step needs verification for full data flow.
- **Impact**: Day 1 magic may not fully deliver on the "5-minute insight" promise if data flow is incomplete.
- **Files needed**: Verify integration between `FirstInsightGenerator` → `OnboardingViewModel` → `AbsolutionStepView`.

#### P2-14: E2E Tests — Minimal

- **Spec**: Comprehensive E2E testing expected.
- **Status**: `frontend/e2e/` has `homepage.spec.ts` and `user-flow.spec.ts`. No iOS E2E tests (XCUITest). No backend integration tests against real Azure services.
- **Impact**: No end-to-end validation of critical user flows.
- **Files needed**: iOS XCUITest targets, backend integration test suite.

#### P2-15: Navigation Architecture — EMPTY

- **Spec**: UX Spec defines multi-screen navigation with deep linking.
- **Status**: `ios/Vigor/UI/Navigation/` is **empty**. Navigation appears handled inline in `App` and `HomeView`.
- **Impact**: No coordinated navigation. Deep linking (from notifications, Siri) may not work.
- **Files needed**: `NavigationCoordinator.swift` or SwiftUI `NavigationPath` management.

---

### P3 — Low / Polish & Enhancement

#### P3-1: CoreLocation for Timezone / Travel Detection

- **Spec**: Tech Spec §2.4 mentions `travelDetected` and `timezoneOffset` in `RawSignalStore.DailyAggregate`. PRD mentions jet lag detection.
- **Status**: No `CLLocationManager` usage in app code (only privacy manifest declaration). No travel detection implementation.
- **Files needed**: Coarse location monitoring for timezone change detection.

#### P3-2: Accessibility — Partial

- **Spec**: UX Spec §7 requires full VoiceOver support, Dynamic Type, and reduced motion alternatives.
- **Status**: `VigorTests/Accessibility/AccessibilityTests.swift` exists (tests written). Implementation coverage in views is unknown without auditing each SwiftUI view.
- **Files needed**: Audit all views for accessibility labels, traits, and Dynamic Type support.

#### P3-3: Settings View — Incomplete

- **Spec**: UX Spec specifies settings for trust phase visibility, calendar blocker selection, notification preferences, haptic toggle, and Shadow Sync configuration.
- **Status**: `SettingsView.swift` exists with haptic toggle. Full feature coverage unknown.
- **Files needed**: Audit against spec settings requirements.

#### P3-4: Backend Anonymous Pattern Aggregation

- **Spec**: Tech Spec §3.1 specifies `/api/ghost/sync` storing anonymized aggregates with one-way user hash for model improvement.
- **Status**: `ghost_bp.py` has `ghost_sync` endpoint. Anonymization implementation depth unclear.
- **Files needed**: Verify one-way hashing and data minimization in sync endpoint.

#### P3-5: Week Overview / Streak UI

- **Spec**: UX Spec §5.4 specifies 7-day week overview with per-day workout indicators, streak tracking, and trend visualization.
- **Status**: `HomeView.swift` has `WeekOverviewView` and `DayIndicator`. Implementation depth needs review.
- **Files needed**: Verify completeness of week overview.

#### P3-6: Deep Analysis — Overnight Only Guard

- **Spec**: Tech Spec §2.5 specifies deep analysis runs only during 1-5 AM when charging. `performDeepAnalysisIfCharging()` checks battery state and time.
- **Status**: `HealthKitObserver.swift` exists but the overnight-only guard and deep analysis pipeline integration isn't confirmed.
- **Files needed**: Verify `BGProcessingTask` with `requiresExternalPower = true` is properly configured.

#### P3-7: Anti-Metrics Tracking

- **Spec**: Tech Spec §11.2 defines anti-metrics: notification tap rate (should be low), time-in-app (should be low), DAU/WAU ratio (should be < 0.5).
- **Status**: No anti-metrics tracking implementation found.
- **Files needed**: Analytics event tracking for anti-metrics.

#### P3-8: iPad Support

- **Spec**: Tech Spec §4.4 mentions iPhone ↔ iPad via CloudKit trust sync.
- **Status**: No iPad-specific layouts or universal app configuration visible.
- **Files needed**: Adaptive layouts, iPad navigation patterns.

---

## ALREADY COMPLETE

### iOS App — Strong Foundations

| Component                       | Status      | Notes                                                                                                         |
| ------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------- |
| **Ghost Engine**                | ✅ Complete | 648-line orchestrator with morning/evening cycles, workout detection, block management                        |
| **Trust State Machine**         | ✅ Complete | All 5 phases, safety breaker (3-delete threshold), manual advance/retreat, weighted trust attribution         |
| **Trust Attribution Engine**    | ✅ Complete | De-romanticized signals with ambiguity scoring, confidence weighting, rolling event log                       |
| **Phenome Data Model**          | ✅ Complete | 3-store decomposition (RawSignalStore, DerivedStateStore, BehavioralMemoryStore) with Core Data entities      |
| **Calendar Scheduler**          | ✅ Complete | Local-only calendar source, free block detection, all-day event handling, blocker calendar selection          |
| **Block Transformer**           | ✅ Complete | Evaluate blocks against recovery/sleep/calendar, transform/remove decisions                                   |
| **Sacred Time Detector**        | ✅ Complete | Protected slots from scheduling                                                                               |
| **Notification Orchestrator**   | ✅ Complete | 3 categories, max 1/day rate limit, priority queue, badge-only mode, pre-onboarding gate                      |
| **Onboarding Flow**             | ✅ Complete | 1052-line flow: welcome → meetTheGhost → watchPairing → permissions → preferences → absolution → confirmation |
| **Home View**                   | ✅ Complete | Ghost status header, triage card, week overview, quick actions                                                |
| **Triage Card System**          | ✅ Complete | Missed workout, block proposal, workout feedback, block transformation cards                                  |
| **Value Receipt Generator**     | ✅ Complete | Weekly summary with decisions, risk signals, phenome insights                                                 |
| **Value Receipt View**          | ✅ Complete | UI for Sunday summary                                                                                         |
| **First Insight Generator**     | ✅ Complete | 391-line "Absolution Moment" with sleep/workout/recovery/schedule insights                                    |
| **Decision Receipt Store**      | ✅ Complete | Full forensic logging with inputs, alternatives, confidence, trust impact                                     |
| **Ghost Health Monitor**        | ✅ Complete | 4-mode degradation (healthy → degraded → safeMode → suspended), failure tracking, onboarding awareness        |
| **API Client**                  | ✅ Complete | 424-line client covering user profile, ghost sync, workouts, trust, coaching, devices, offline queue          |
| **Offline API Queue**           | ✅ Complete | Queues failed requests for retry                                                                              |
| **Auth Manager**                | ✅ Complete | MSAL integration with dev-mode stub for free provisioning                                                     |
| **HealthKit Observer**          | ✅ Complete | Sleep, HRV, workout fetch. Background delivery setup                                                          |
| **Logger**                      | ✅ Complete | `VigorLogger.swift` structured logging                                                                        |
| **Local Workout Generator**     | ✅ Complete | Template-based offline workout generation with type selection, exercise building                              |
| **Exercise Database**           | ✅ Complete | Local exercise pool                                                                                           |
| **Authority Conflict Resolver** | ✅ Complete | Watch-owns-workouts, Phone-owns-planning principle, conflict detection, resolution logging                    |
| **Silent Push Receiver**        | ✅ Complete | Handles `morning_wake`, `pre_workout_refresh`, `calendar_sync`, `config_update` push types                    |

### Watch App

| Component                    | Status      | Notes                                                 |
| ---------------------------- | ----------- | ----------------------------------------------------- |
| **TodayView**                | ✅ Complete | Watch face for current state                          |
| **ActiveWorkoutView**        | ✅ Complete | In-workout display                                    |
| **WatchWorkoutManager**      | ✅ Complete | HKWorkoutSession management, workout types            |
| **ComplicationController**   | ✅ Partial  | Basic complications exist, needs real data connection |
| **WatchConnectivityManager** | ✅ Complete | Phone ↔ Watch messaging                               |

### Backend

| Component             | Status             | Notes                                                                                                         |
| --------------------- | ------------------ | ------------------------------------------------------------------------------------------------------------- |
| **Auth Blueprint**    | ✅ Complete        | User profile, token validation                                                                                |
| **Workout Blueprint** | ✅ Complete        | Generate, log, history, sync training blocks                                                                  |
| **Ghost Blueprint**   | ✅ Complete        | Sync, silent push, trust, schedule, phenome sync, decision receipts, device tokens, timer triggers            |
| **Trust Blueprint**   | ✅ Complete        | Record events, get history                                                                                    |
| **Coach Blueprint**   | ✅ Complete        | AI chat, history, recommendations, recovery                                                                   |
| **Devices Blueprint** | ✅ Complete        | Device registration, push tokens                                                                              |
| **Admin Blueprint**   | ✅ Complete        | Cost metrics, ghost health, trust distribution, users, decision receipts, safety events, analytics, AI config |
| **Health Blueprint**  | ✅ Complete        | Health checks                                                                                                 |
| **Cosmos DB Client**  | ✅ Complete        | Database operations                                                                                           |
| **OpenAI Client**     | ✅ Complete        | GPT-5-mini workout generation                                                                                 |
| **Rate Limiter**      | ✅ Complete        | Request limiting                                                                                              |
| **Data Models**       | ✅ Mostly complete | User, WorkoutPlan, Exercise, WorkoutLog, AICoachMessage, safety validator                                     |

### Frontend (Admin Dashboard)

| Component             | Status      | Notes                                                                          |
| --------------------- | ----------- | ------------------------------------------------------------------------------ |
| **Admin Routes**      | ✅ Complete | 9 routes covering LLM health, users, config, analytics, audit, bulk ops, tiers |
| **Component Library** | ✅ Complete | Lazy-loaded admin components                                                   |
| **Auth (MSAL)**       | ✅ Complete | Microsoft auth integration                                                     |

### Testing

| Component                    | Status      | Notes                                              |
| ---------------------------- | ----------- | -------------------------------------------------- |
| **Trust Tests**              | ✅ Complete | SafetyBreaker, TrustAttribution, TrustStateMachine |
| **Ghost Retry Tests**        | ✅ Complete | Retry logic                                        |
| **First Insight Tests**      | ✅ Complete | Insight generation                                 |
| **Notification Tests**       | ✅ Complete | Orchestrator behavior                              |
| **Ghost Simulation Tests**   | ✅ Complete | Full cycle simulation                              |
| **Watch Connectivity Tests** | ✅ Complete | Message exchange                                   |
| **Offline Queue Tests**      | ✅ Complete | Queue management                                   |
| **Accessibility Tests**      | ✅ Complete | VoiceOver/a11y                                     |
| **Performance Tests**        | ✅ Complete | Performance benchmarks                             |
| **Backend Tests**            | ✅ Complete | Auth, trust, cosmos, coach, ghost, admin, helpers  |

### CI/CD

| Component          | Status      | Notes                              |
| ------------------ | ----------- | ---------------------------------- |
| **Backend CI/CD**  | ✅ Complete | Python quality + deploy pipeline   |
| **Frontend CI/CD** | ✅ Complete | Node quality + deploy              |
| **iOS Build**      | ✅ Complete | Xcode 15.2, macos-14 runner        |
| **iOS Deploy**     | ✅ Complete | Tag-triggered TestFlight/App Store |

---

## RECOMMENDED NEXT PHASE

### Phase 1: Foundation Gaps (Week 1-2)

Priority: Close P0 gaps that block core product promise.

1. **P0-5: Remote Ghost Configuration** — Implement `GhostConfigManager.swift`. Low effort, high impact. Unblocks tuning everything else without App Store updates.
2. **P0-6: Backend Hybrid Template Engine** — Create `shared/templates.py` with Dynamic Skeletons. Immediately cuts LLM costs by ~90% and adds instant workout delivery.
3. **P0-1: CloudKit Sync** — Implement Trust State sync first (lightweight record, critical for device restore). Phenome sync can follow incrementally.
4. **P0-7: Model Distribution Endpoint** — Add `GET /api/models/manifest` to backend. Infrastructure for P0-2.

### Phase 2: Intelligence & Safety (Week 3-4)

Priority: Make the Ghost actually smart and safe.

5. **P0-2: Core ML Models** — Train initial models on synthetic/aggregate data. Even basic models outperform hardcoded heuristics.
6. **P1-5: Feedback Engine** — Implement bidirectional learning. Without this, Ghost can't improve.
7. **P1-6: Health Profile State Machine** — Baseline → adaptation → maintenance phases control personalization quality.
8. **P2-9: Workout Safety Contracts** — Critical safety guardrail before scaling workout generation.

### Phase 3: User Trust & Transparency (Week 5-6)

Priority: Users must understand and trust the Ghost.

9. **P0-3: Emergency / Red Button** — Safety off-ramp prevents rage-deletes.
10. **P1-1: Explainability UI** — Surface decision receipts to users.
11. **P1-2: Fallback/Degradation UI** — Make Ghost health visible when degraded.
12. **P1-8: User Tiers** — Enable monetization. Add PREMIUM tier and enforce limits.

### Phase 4: Platform Polish (Week 7-8)

Priority: Complete the platform.

13. **P0-4: Siri Shortcuts** — Voice-driven emergency protocol and quick commands.
14. **P1-3: Haptic Vocabulary** — Rich haptic feedback via CoreHaptics.
15. **P1-4: Value Receipt Sharing** — Clean Mode for social sharing.
16. **P2-1: WidgetKit** — Home screen presence without app opens.
17. **P2-4: Test Coverage** — Fill empty test directories (Calendar, Health, Phenome, Onboarding).

### Phase 5: Corporate & Scale (Week 9+)

Priority: Enterprise hardening.

18. **P1-10: Calendar Shadow Sync** — Full Graph API integration for corporate users.
19. **P1-11: Three-Layer Health Model** — Versioned metric computation with provenance.
20. **P2-3: Watch Autonomous Sync** — Direct backend calls from Watch.
21. **P2-15: Navigation Architecture** — Deep linking from notifications and Siri.
