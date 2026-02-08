# Vigor Implementation Plan

**Version**: 1.5
**Date**: January 27, 2026
**Status**: Active Implementation
**Aligned with**: PRD-Vigor.md v5.0, Tech_Spec_Vigor.md v2.6, UX_Spec.md v1.3

---

## 📊 Implementation Progress

| Phase         | Description                     | Status      | Progress |
| ------------- | ------------------------------- | ----------- | -------- |
| **Phase 0.1** | Archive Web Frontend            | ✅ Complete | 100%     |
| **Phase 0.2** | Create iOS Project Structure    | ✅ Complete | 100%     |
| **Phase 0.3** | Update Repository Documentation | ✅ Complete | 100%     |
| **Phase 0.4** | Configure CI/CD for iOS         | ✅ Complete | 100%     |
| **Phase 1**   | Native iOS App Foundation       | ✅ Complete | 100%     |
| **Phase 2**   | Ghost Intelligence Layer        | ✅ Complete | 100%     |
| **Phase 3**   | watchOS Companion App           | ✅ Complete | 100%     |
| **Phase 4**   | Azure Backend Modernization     | ✅ Complete | 100%     |
| **Phase 5**   | Calendar & Notification System  | ✅ Complete | 100%     |
| **Phase 6**   | UX Polish & Testing             | ✅ Complete | 100%     |
| **Phase 7**   | Production Hardening & Wiring   | 🔴 Active   | 0%       |

### Recently Completed Files

**Phase 0:**

- `.archive/frontend-web-app/` - Archived user-facing pages and components
- `README.md` - Updated for iOS-first architecture
- `ios/README.md` - iOS development documentation
- `.github/workflows/ios-build.yml` - Xcode build and test
- `.github/workflows/ios-deploy.yml` - TestFlight deployment

**Phase 1:**

- `ios/Vigor/App/VigorApp.swift` - @main entry point
- `ios/Vigor/App/AppDelegate.swift` - Push, BGTaskScheduler
- `ios/Vigor/App/ContentView.swift` - Root view with auth state
- `ios/Vigor/Core/Auth/AuthManager.swift` - MSAL integration
- `ios/Vigor/Core/Auth/MSALConfiguration.swift` - Auth config
- `ios/Vigor/Data/HealthKit/HealthKitObserver.swift` - Progressive import
- `ios/Vigor/Data/HealthKit/HealthKitTypes.swift` - Data models
- `ios/Vigor/Data/Calendar/CalendarScheduler.swift` - EventKit integration
- `ios/Vigor/Data/Calendar/CalendarShadowSync.swift` - MS Graph Shadow Sync
- `ios/Vigor/Core/Phenome/PhenomeCoordinator.swift` - 3-store coordinator
- `ios/Vigor/Core/Phenome/MetricRegistry.swift` - Versioned metrics
- `ios/Vigor/Core/Phenome/RawSignalStore.swift` - HealthKit data store
- `ios/Vigor/Core/Phenome/DerivedStateStore.swift` - Computed metrics
- `ios/Vigor/Core/Phenome/BehavioralMemoryStore.swift` - Preferences
- `ios/Vigor/Data/API/VigorAPIClient.swift` - Azure Functions client
- `ios/Vigor/Data/API/APIModels.swift` - Request/response DTOs
- `ios/Vigor/Background/SilentPushReceiver.swift` - P0 survival mechanism
- `ios/Vigor/Notifications/NotificationOrchestrator.swift` - Max 1/day
- `ios/Vigor/UI/Onboarding/OnboardingFlow.swift` - 6-step onboarding
- `ios/Vigor/UI/Components/TriageCard.swift` - Actionable cards
- `ios/Vigor/UI/Home/HomeView.swift` - Main Ghost interface
- `ios/Shared/WatchConnectivity/WatchConnectivityManager.swift` - WCSession
- `ios/Shared/Sync/AuthorityConflictResolver.swift` - Domain authority

**Phase 2:**

- `ios/Vigor/Core/GhostEngine/GhostEngine.swift` - Central orchestration
- `ios/Vigor/Core/GhostEngine/GhostHealthMonitor.swift` - Health modes
- `ios/Vigor/Core/GhostEngine/DecisionReceiptStore.swift` - Forensic logging
- `ios/Vigor/Core/GhostEngine/FailureDisambiguator.swift` - Failure triage
- `ios/Vigor/Core/Trust/TrustStateMachine.swift` - 5-phase progression
- `ios/Vigor/Core/Trust/TrustPhase.swift` - Phase capabilities
- `ios/Vigor/Core/Trust/TrustEvent.swift` - Trust-affecting events
- `ios/Vigor/Core/Trust/TrustAttributionEngine.swift` - Weighted deltas
- `ios/Vigor/Core/ML/SkipPredictor.swift` - Skip probability
- `ios/Vigor/Core/ML/RecoveryAnalyzer.swift` - Recovery scoring
- `ios/Vigor/Core/ML/OptimalWindowFinder.swift` - Best workout windows
- `ios/Vigor/Core/ML/PatternDetector.swift` - Behavioral patterns
- `ios/VigorTests/Trust/TrustStateMachineTests.swift` - Phase transitions
- `ios/VigorTests/Trust/SafetyBreakerTests.swift` - 3-delete trigger
- `ios/VigorTests/Trust/TrustAttributionTests.swift` - Weighted deltas

**Phase 3:**

- `ios/VigorWatch/App/VigorWatchApp.swift` - Watch app entry
- `ios/VigorWatch/Views/TodayView.swift` - Today workout view
- `ios/VigorWatch/Views/ActiveWorkoutView.swift` - Workout tracking
- `ios/VigorWatch/Workout/WatchWorkoutManager.swift` - HKWorkoutSession
- `ios/VigorWatch/Sync/WatchSyncManager.swift` - Phone sync
- `ios/VigorWatch/Complications/ComplicationController.swift` - Complications

**Phase 4:**

- `functions-modernized/function_app.py` - Ghost API endpoints + Timer functions
- `functions-modernized/shared/cosmos_db.py` - Ghost-specific database methods
- `functions-modernized/shared/apns_client.py` - APNs silent push client

**Phase 5:**

- `ios/Vigor/Data/Calendar/BlockTransformer.swift` - Transform logic
- `ios/Vigor/Data/Calendar/SacredTimeDetector.swift` - Sacred time protection
- `ios/Vigor/UI/ValueReceipt/ValueReceiptView.swift` - Weekly receipt

**Phase 6:**

- `ios/VigorTests/Simulation/GhostSimulationTests.swift` - 60-day journey tests
- `ios/VigorTests/Simulation/CalendarIntegrationTests.swift` - Calendar tests
- `ios/VigorTests/Simulation/GhostCycleTests.swift` - Morning/evening cycle tests
- `ios/VigorTests/Performance/PerformanceTests.swift` - Background efficiency
- `ios/VigorTests/Accessibility/AccessibilityTests.swift` - WCAG compliance
- `ios/VigorTests/WatchConnectivity/WatchConnectivityTests.swift` - iPhone-Watch sync
- `ios/AppStoreMetadata.md` - App Store listing content
- `ios/Vigor/PrivacyInfo.xcprivacy` - Privacy manifest
- `ios/Vigor/Configuration/InfoPlist.swift` - Info.plist documentation
- `ios/Vigor/UI/Onboarding/OnboardingView.swift` - Polished onboarding
- `ios/Vigor/UI/Triage/TriageCardView.swift` - Morning triage card

---

## ⚠️ Critical Architecture Principle: Platform Survival

> **"The Ghost must survive while the user ignores it."**

This plan addresses the **Invisibility Paradox**: By succeeding at the product goal (user rarely opens app), we risk technical failure (iOS terminates background tasks for unused apps).

**Non-Negotiable Infrastructure** (Must be P0):

| Survival Mechanism                | Implementation                                           | Phase   | Status  |
| --------------------------------- | -------------------------------------------------------- | ------- | ------- |
| **Silent Push Wake**              | Azure Timer Function (5:55 AM) → APNs → App Wake         | Phase 4 | ✅ Done |
| **Complication-Driven Wake**      | Watch complication refresh triggers iPhone sync          | Phase 3 | ✅ Done |
| **Calendar Multiplexing**         | Read from Exchange/Outlook, Write to Local               | Phase 1 | ✅ Done |
| **Authority Conflict Resolution** | Single-Writer Principle (Watch=Workouts, Phone=Planning) | Phase 1 | ✅ Done |
| **Safety Breaker**                | 3 consecutive deletes → immediate trust downgrade        | Phase 2 | ✅ Done |
| **Failure Triage**                | Disambiguate "bad schedule" vs "life happened"           | Phase 2 | ✅ Done |

**If these mechanisms are not implemented as P0, the Ghost will die in the background after 3 days of non-use.**

---

## Executive Summary

### Current State Analysis

The existing implementation is a **conventional web-based fitness app** with:

- React/TypeScript frontend (Vite, Chakra UI)
- Python Azure Functions backend
- Microsoft Entra ID authentication
- Basic AI workout generation via Azure OpenAI
- Standard CRUD operations for workouts, users, and chat

### Target State (Per Specs)

Vigor is designed as an **invisible fitness system ("The Ghost")** requiring:

- **Native iOS/watchOS app** (SwiftUI, HealthKit, EventKit, Core ML)
- Apple Watch as a **mandatory hardware requirement**
- On-device Phenome storage with CloudKit sync
- Trust Accrual Ladder (5-phase progressive autonomy)
- Silent calendar scheduling with zero user input
- Edge-first ML for pattern detection and predictions
- Azure backend as enhancement layer (not core dependency)

### Strategic Decision: Complete Rewrite Required

The current implementation represents a **fundamentally different product architecture**:

| Aspect           | Current                | Target                        | Decision    |
| ---------------- | ---------------------- | ----------------------------- | ----------- |
| **Platform**     | Web (React/TypeScript) | Native iOS/watchOS (SwiftUI)  | **Rewrite** |
| **Core Logic**   | Server-dependent       | Edge-first, offline-capable   | **Rewrite** |
| **Data Model**   | Flat user profiles     | Decomposed Phenome (3 stores) | **Rewrite** |
| **Sensors**      | None                   | HealthKit mandatory           | **New**     |
| **Calendar**     | None                   | EventKit integration          | **New**     |
| **ML**           | Server LLM only        | Core ML on-device             | **New**     |
| **Trust System** | None                   | 5-phase state machine         | **New**     |
| **UX Paradigm**  | App-centric dashboard  | Invisible/calendar-first      | **Rewrite** |

**The web frontend will be repurposed as an admin dashboard** for monitoring, configuration, and analytics.
**The Azure Functions backend will be refactored** to serve the native app with Ghost-specific APIs.

---

## Archive Strategy

Move deprecated/superseded code to `.archive/` to maintain clean project structure:

```
.archive/
├── frontend-web-app/           # Current React frontend (becomes admin dashboard)
│   ├── src/pages/              # User-facing pages (replaced by iOS app)
│   ├── src/components/         # User-facing components
│   └── README.md               # Documentation of why archived
├── functions-v1/               # Original function implementations
└── docs/pre-v5/                # Older spec versions
```

---

## Implementation Phases

### Phase 0: Project Restructure & Foundation

**Duration**: 1 week
**Goal**: Prepare repository structure for native iOS development

### Phase 1: Native iOS App Foundation

**Duration**: 3 weeks
**Goal**: Core iOS app with HealthKit, EventKit, and basic Ghost Engine

### Phase 2: Ghost Intelligence Layer

**Duration**: 4 weeks
**Goal**: Phenome storage, Trust State Machine, Core ML models

### Phase 3: watchOS Companion App

**Duration**: 2 weeks
**Goal**: Apple Watch app with complications and workout detection

### Phase 4: Azure Backend Modernization

**Duration**: 2 weeks
**Goal**: Refactor backend for Ghost-specific APIs and RAG workout generation

### Phase 5: Calendar & Notification System

**Duration**: 2 weeks
**Goal**: Silent calendar blocks, notification orchestration, block transformation

### Phase 6: UX Polish & Testing

**Duration**: 2 weeks
**Goal**: Value receipts, onboarding flow, edge case handling, TestFlight

---

## Phase 0: Project Restructure & Foundation

### Task 0.1: Archive Current Web Frontend

**Priority**: P0 (Blocker)
**Files to Archive**:

```
frontend/src/pages/
├── CoachPage.tsx           → .archive/frontend-web-app/src/pages/
├── DashboardPage.tsx       → .archive/frontend-web-app/src/pages/
├── LandingPage.tsx         → .archive/frontend-web-app/src/pages/
├── OnboardingPage.tsx      → .archive/frontend-web-app/src/pages/
├── PersonalizedDashboardPage.tsx → .archive/frontend-web-app/src/pages/
├── ProfilePage.tsx         → .archive/frontend-web-app/src/pages/
├── WorkoutPage.tsx         → .archive/frontend-web-app/src/pages/
└── RegisterPage.tsx        → .archive/frontend-web-app/src/pages/

frontend/src/components/
├── CommunityFeatures.tsx   → .archive/frontend-web-app/src/components/
├── PremiumFeatures.tsx     → .archive/frontend-web-app/src/components/
├── SocialFeatures.tsx      → .archive/frontend-web-app/src/components/
├── QuickReplies.tsx        → .archive/frontend-web-app/src/components/
└── EnhancedProgressVisualization.tsx → .archive/frontend-web-app/src/components/
```

**Retain in Frontend** (for Admin Dashboard):

- AdminPage.tsx
- AdminAuditSecurity.tsx
- AnalyticsDashboard.tsx
- BulkUserOperations.tsx
- LLMOrchestrationPage.tsx
- LLMAnalyticsSimple.tsx
- LLMConfigurationSimple.tsx
- LLMHealthMonitoring.tsx
- TierManagementPage.tsx
- UserManagement.tsx
- ErrorBoundary.tsx
- Layout.tsx
- ProtectedRoute.tsx
- OAuthCallback.tsx

### Task 0.2: Create iOS Project Structure

**Priority**: P0 (Blocker)
**Create**:

```
ios/
├── Vigor.xcodeproj/
├── Vigor/
│   ├── App/
│   │   ├── VigorApp.swift
│   │   └── AppDelegate.swift
│   ├── Core/
│   │   ├── GhostEngine/
│   │   │   ├── GhostEngine.swift
│   │   │   ├── GhostHealthMonitor.swift
│   │   │   └── DecisionReceiptStore.swift
│   │   ├── Trust/
│   │   │   ├── TrustStateMachine.swift
│   │   │   ├── TrustPhase.swift
│   │   │   └── TrustAttributionEngine.swift
│   │   ├── Phenome/
│   │   │   ├── PhenomeCoordinator.swift
│   │   │   ├── RawSignalStore.swift
│   │   │   ├── DerivedStateStore.swift
│   │   │   └── BehavioralMemoryStore.swift
│   │   └── ML/
│   │       ├── PatternDetector.swift
│   │       ├── SkipPredictor.swift
│   │       ├── RecoveryAnalyzer.swift
│   │       └── OptimalWindowFinder.swift
│   ├── Data/
│   │   ├── HealthKit/
│   │   │   ├── HealthKitObserver.swift
│   │   │   └── HealthKitTypes.swift
│   │   ├── Calendar/
│   │   │   ├── CalendarScheduler.swift
│   │   │   ├── SacredTimeDetector.swift
│   │   │   └── BlockTransformer.swift
│   │   ├── CloudKit/
│   │   │   ├── CloudKitSync.swift
│   │   │   └── TrustStateConflictResolver.swift
│   │   └── API/
│   │       ├── VigorAPIClient.swift
│   │       └── APIModels.swift
│   ├── UI/
│   │   ├── Onboarding/
│   │   ├── Today/
│   │   ├── Settings/
│   │   └── ValueReceipt/
│   ├── Notifications/
│   │   └── NotificationOrchestrator.swift
│   ├── Background/
│   │   └── BackgroundTaskManager.swift
│   └── Resources/
│       ├── Assets.xcassets
│       └── Info.plist
├── VigorWatch/
│   ├── App/
│   │   └── VigorWatchApp.swift
│   ├── Complications/
│   │   └── ComplicationController.swift
│   ├── Views/
│   │   ├── TodayView.swift
│   │   ├── ActiveWorkoutView.swift
│   │   └── RecoveryView.swift
│   └── Extension/
│       └── ExtensionDelegate.swift
├── VigorWatchExtension/
├── Shared/
│   ├── Models/
│   ├── Extensions/
│   └── Utilities/
└── VigorTests/
```

### Task 0.3: Update Repository Documentation

**Priority**: P1
**Update**:

- `README.md` - Update to reflect iOS-first architecture
- `docs/` - Add iOS development setup guide
- Create `ios/README.md` with build instructions
- Update `CONTRIBUTING.md` with native development guidelines

### Task 0.4: Configure CI/CD for iOS

**Priority**: P1
**Create**:

- `.github/workflows/ios-build.yml` - Xcode build and test
- `.github/workflows/ios-deploy.yml` - TestFlight deployment
- Update existing workflows to ignore `ios/` directory

---

## Phase 1: Native iOS App Foundation

### Task 1.1: SwiftUI App Shell

**Priority**: P0 (Blocker)
**Description**: Create basic SwiftUI app with navigation structure

**Implementation Details**:

```swift
// VigorApp.swift
@main
struct VigorApp: App {
    @StateObject private var ghostEngine = GhostEngine()
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ghostEngine)
                .environmentObject(authManager)
        }
    }
}
```

**Files to Create**:

- `ios/Vigor/App/VigorApp.swift`
- `ios/Vigor/App/ContentView.swift`
- `ios/Vigor/UI/Navigation/AppNavigation.swift`

### Task 1.2: Microsoft Entra ID Authentication for iOS

**Priority**: P0 (Blocker)
**Description**: Integrate MSAL for iOS authentication

**Dependencies**:

- MSAL.framework via Swift Package Manager
- Configure Azure AD app registration for iOS redirect URIs

**Implementation Details**:

```swift
// AuthManager.swift
@MainActor
final class AuthManager: ObservableObject {
    private let msalClient: MSALPublicClientApplication

    @Published var isAuthenticated = false
    @Published var currentUser: User?

    func signIn() async throws { }
    func signOut() async { }
    func getAccessToken() async throws -> String { }
}
```

**Files to Create**:

- `ios/Vigor/Core/Auth/AuthManager.swift`
- `ios/Vigor/Core/Auth/MSALConfiguration.swift`
- Update `Info.plist` with URL schemes

### Task 1.3: HealthKit Authorization & Basic Import

**Priority**: P0 (Blocker)
**Description**: Request HealthKit permissions, implement progressive 7-day + 90-day import

**Implementation Details** (per Tech Spec §2.5):

- Request read access: sleep, HRV, resting HR, steps, workouts
- Implement chunked import with savepoints
- Background delivery for workouts (immediate) and sleep (hourly)

**Files to Create**:

- `ios/Vigor/Data/HealthKit/HealthKitObserver.swift`
- `ios/Vigor/Data/HealthKit/HealthKitTypes.swift`
- `ios/Vigor/Data/HealthKit/ImportState.swift`
- Update `Info.plist` with HealthKit usage descriptions

### Task 1.4: EventKit Authorization & Calendar Multiplexing

**Priority**: P0 (Blocker)
**Description**: Request calendar permissions, create Vigor-specific local calendar, implement multi-source reading

**Implementation Details** (per Tech Spec §2.6):

- Create "Vigor Training" calendar with LOCAL source only (write target)
- **Calendar Multiplexing (CRITICAL)**: Read from ALL calendars (Exchange, Outlook, iCloud, Google) to detect conflicts
- Write ONLY to local Vigor calendar (prevents corporate sync pollution)
- Implement blocker calendar selection UI
- Smart all-day event filtering (skip "Mom's Birthday" all-day events unless marked Busy)
- Detect MDM-blocked calendars and degrade gracefully

**Corporate Resilience** (per Tech Spec §2.5):

```swift
// CalendarMultiplexer.swift
final class CalendarMultiplexer {
    /// Read from ALL calendars to find busy slots
    func getAllBusySlots(for date: Date) -> [TimeSlot] {
        // Aggregate from Exchange, Outlook, iCloud, Google, Local
    }

    /// Write ONLY to Vigor's local calendar
    func scheduleBlock(_ block: TrainingBlock) {
        // Target: local "Vigor Training" calendar only
    }
}
```

**Files to Create**:

- `ios/Vigor/Data/Calendar/CalendarScheduler.swift`
- `ios/Vigor/Data/Calendar/CalendarMultiplexer.swift`
- `ios/Vigor/Data/Calendar/CalendarModels.swift`
- `ios/Vigor/Data/Calendar/MDMFallbackHandler.swift`
- Update `Info.plist` with calendar usage descriptions

### Task 1.4b: Calendar Shadow Sync (Corporate Resilience)

**Priority**: P0 (Blocker)
**Description**: Write "Busy" blocks back to corporate Exchange/Outlook calendars to prevent colleagues from double-booking workout times

**Why This Is in Phase 1 (not Phase 5)**:

Without Shadow Sync from Day 1, colleagues can book over Vigor's scheduled workout blocks. By Phase 5, the user has been double-booked for 16 weeks = trust destroyed. This is **Corporate Resilience**, not polish.

**Implementation Details** (per Tech Spec §2.5):

```swift
// CalendarShadowSync.swift
final class CalendarShadowSync {
    private let msGraphClient: MSGraphClient
    private let fallbackHandler: MDMFallbackHandler

    /// Sync Vigor's scheduled blocks to corporate calendars
    func syncToExchange(_ blocks: [TrainingBlock]) async throws {
        guard MDMPolicy.allowsExternalCalendarWrites else {
            // MDM blocks external writes - show guidance
            await fallbackHandler.showManualBlockingGuidance(blocks)
            return
        }

        for block in blocks {
            try await msGraphClient.createEvent(
                calendar: .primary,
                event: MSEvent(
                    subject: "Busy",  // Intentionally vague
                    showAs: .busy,
                    isPrivate: true,
                    start: block.start,
                    end: block.end
                )
            )
        }
    }

    /// Cleanup when workout is skipped/completed/cancelled
    func removeFromExchange(_ blockId: UUID) async throws {
        // Find matching Vigor-created event and delete
    }
}
```

**MDM Fallback (Graceful Degradation)**:

```swift
// MDMFallbackHandler.swift
extension MDMFallbackHandler {
    /// When corporate policy blocks calendar writes
    func showManualBlockingGuidance(_ blocks: [TrainingBlock]) async {
        // Surface UI: "Your IT policy prevents auto-blocking.
        // Tap to copy times and add manually."
        let copyableText = blocks.map { $0.formattedForCalendarCopy }.joined(separator: "\n")
        await ClipboardBridge.copy(copyableText)
    }
}
```

**Files to Create**:

- `ios/Vigor/Data/Calendar/CalendarShadowSync.swift`
- `ios/Vigor/Data/Calendar/MSGraphClient.swift`
- `ios/Vigor/Data/Calendar/MSEvent.swift`
- Extend `ios/Vigor/Data/Calendar/MDMFallbackHandler.swift`

### Task 1.5: Core Data + CloudKit Schema with Metric Provenance

**Priority**: P0 (Blocker)
**Description**: Set up local Core Data store with CloudKit sync AND versioned metric recomputation engine

**Implementation Details** (per Tech Spec §2.4, §2.10, §2.11):

- Three physical stores: RawSignalStore, DerivedStateStore, BehavioralMemoryStore
- Trust State in separate CloudKit record for resilient sync
- E2E encryption via CloudKit private database

**Metric Provenance Engine (CRITICAL)**:

The Tech Spec requires a **versioned recomputation engine** to handle formula changes without breaking user trust ("Why did my recovery score change?").

```swift
// MetricRegistry.swift
struct MetricVersion: Codable, Hashable {
    let metricName: String      // e.g., "recovery_score"
    let algorithmVersion: Int   // e.g., 3
    let computedAt: Date
    let inputSnapshot: InputSnapshot  // Hashed inputs used
}

actor MetricRegistry {
    /// All registered metric formulas with versions
    private var formulas: [String: MetricFormula] = [:]

    /// Compute a derived metric and store provenance
    func compute<T: DerivedMetric>(
        _ metric: T.Type,
        from inputs: T.Inputs
    ) async -> MetricResult<T.Value> {
        let version = MetricVersion(
            metricName: T.name,
            algorithmVersion: T.version,
            computedAt: Date(),
            inputSnapshot: inputs.snapshot()
        )

        let value = T.compute(from: inputs)

        // Store provenance for explainability
        await DerivedStateStore.shared.store(
            value: value,
            provenance: version
        )

        return MetricResult(value: value, provenance: version)
    }

    /// Silent Backfill: Recompute historical metrics with new algorithm
    func backfill<T: DerivedMetric>(
        _ metric: T.Type,
        from startDate: Date,
        to endDate: Date
    ) async {
        // Fetch raw inputs from RawSignalStore
        // Recompute with current algorithm version
        // Store new values with new provenance
        // Preserves old values for audit trail
    }
}

// Example: Recovery Score with provenance
struct RecoveryScoreMetric: DerivedMetric {
    static let name = "recovery_score"
    static let version = 3  // Increment when algorithm changes

    struct Inputs: MetricInputs {
        let hrvSamples: [HRVSample]
        let sleepData: SleepAnalysis
        let recentStrain: [StrainScore]
    }

    static func compute(from inputs: Inputs) -> Double {
        // Algorithm v3: Weighted HRV + Sleep + Strain
        // When we change this formula, increment `version`
        // Old computations remain queryable with their version
    }
}
```

**Why This Matters**:

- Bug in Recovery Score formula? Fix it, backfill, no data migration
- User asks "Why did my score change?" → Show algorithm version diff
- A/B test new formulas by computing both versions

**Files to Create**:

- `ios/Vigor/Core/Phenome/Phenome.xcdatamodeld`
- `ios/Vigor/Core/Phenome/PhenomeCoordinator.swift`
- `ios/Vigor/Core/Phenome/RawSignalStore.swift`
- `ios/Vigor/Core/Phenome/DerivedStateStore.swift`
- `ios/Vigor/Core/Phenome/BehavioralMemoryStore.swift`
- `ios/Vigor/Core/Phenome/MetricRegistry.swift`
- `ios/Vigor/Core/Phenome/MetricVersion.swift`
- `ios/Vigor/Core/Phenome/MetricProvenance.swift`
- `ios/Vigor/Data/CloudKit/CloudKitSync.swift`
- `ios/VigorTests/Phenome/MetricRegistryTests.swift`

### Task 1.6: API Client for Azure Backend

**Priority**: P1
**Description**: Swift API client for workout generation and sync

**Files to Create**:

- `ios/Vigor/Data/API/VigorAPIClient.swift`
- `ios/Vigor/Data/API/APIModels.swift`
- `ios/Vigor/Data/API/NetworkError.swift`

### Task 1.7: Device Authority Conflict Resolution

**Priority**: P0 (Blocker)
**Description**: Implement Single-Writer Principle to prevent Watch/Phone data conflicts

**The Problem** (per Tech Spec §4.4.1):

- Watch and Phone can both write workout data
- Without clear authority rules: double-logging, stale overwrites, trust corruption

**Single-Writer Principle**:

| Data Type             | Authority | Rationale                         |
| --------------------- | --------- | --------------------------------- |
| Workout Sessions      | **Watch** | On-wrist sensors are ground truth |
| Workout Logs          | **Watch** | Sensor fidelity                   |
| Calendar Mutations    | **Phone** | EventKit requires foreground      |
| Trust State           | **Phone** | Planning decisions                |
| Phenome Derived State | **Phone** | ML models run on iPhone           |

**Implementation Details**:

```swift
// AuthorityConflictResolver.swift
actor AuthorityConflictResolver {
    enum DataDomain {
        case workoutSession, workoutLog, calendarMutation, trustState, phenome
    }

    func authorityDevice(for domain: DataDomain) -> AuthorityDevice {
        switch domain {
        case .workoutSession, .workoutLog: return .watch
        case .calendarMutation, .trustState, .phenome: return .phone
        }
    }

    /// Resolve conflict when both devices have written
    func resolve<T: Timestamped>(
        watchValue: T?,
        phoneValue: T?,
        domain: DataDomain
    ) -> T? {
        let authority = authorityDevice(for: domain)
        switch authority {
        case .watch: return watchValue ?? phoneValue
        case .phone: return phoneValue ?? watchValue
        }
    }
}
```

**Files to Create**:

- `ios/Shared/Sync/AuthorityConflictResolver.swift`
- `ios/Shared/Sync/DataDomain.swift`
- `ios/Shared/Sync/ConflictResolutionPolicy.swift`

### Task 1.8: Silent Push Infrastructure (iOS Side)

**Priority**: P0 (Blocker)
**Description**: Handle silent push notifications to wake Ghost Engine

**The Problem** (per Tech Spec §2.9 - Invisibility Paradox):

- iOS aggressively throttles BGTaskScheduler for apps not opened recently
- After 3+ days of no foreground use, background tasks may not run
- Silent Push bypasses this throttling

**Implementation Details**:

```swift
// SilentPushReceiver.swift
final class SilentPushReceiver {
    /// Handle content-available:1 push from Azure
    func handleSilentPush(_ payload: [AnyHashable: Any]) async {
        guard let action = payload["ghost_action"] as? String else { return }

        switch action {
        case "morning_cycle":
            await GhostEngine.shared.runMorningCycle()
        case "evening_cycle":
            await GhostEngine.shared.runEveningCycle()
        case "config_update":
            await RemoteConfigManager.shared.refresh()
        default:
            break
        }
    }
}
```

**Files to Create**:

- `ios/Vigor/Background/SilentPushReceiver.swift`
- `ios/Vigor/Background/PushNotificationHandler.swift`
- Update `AppDelegate.swift` with push handling
- Configure APNs entitlements

---

## Phase 2: Ghost Intelligence Layer

### Task 2.1: Trust State Machine Implementation

**Priority**: P0 (Blocker)
**Description**: Implement 5-phase trust progression with safety breakers

**Implementation Details** (per Tech Spec §2.3):

- Observer → Scheduler → Auto-Scheduler → Transformer → Full Ghost
- Action confidence thresholds per phase
- Trust Attribution Layer with weighted trust updates (confidence × ambiguity)

**Safety Breaker (CRITICAL - per Tech Spec §2.3)**:

> If user manually deletes 3 auto-scheduled blocks consecutively, IMMEDIATELY downgrade from Auto-Scheduler to Scheduler phase.

```swift
// SafetyBreaker.swift
extension TrustStateMachine {
    private var consecutiveAutoDeleteCount: Int = 0
    private let safetyBreakerThreshold: Int = 3

    func recordAutoScheduledBlockDeleted() {
        guard currentPhase >= .autoScheduler else { return }

        consecutiveAutoDeleteCount += 1

        if consecutiveAutoDeleteCount >= safetyBreakerThreshold {
            triggerSafetyBreaker()
        }
    }

    private func triggerSafetyBreaker() {
        let previousPhase = currentPhase

        // EMERGENCY: Immediate downgrade
        currentPhase = .scheduler
        trustScore = min(trustScore, 0.5)
        consecutiveAutoDeleteCount = 0

        // Trigger Apology UI (see Task 6.9)
        NotificationCenter.default.post(
            name: .trustSafetyBreakerTriggered,
            object: TrustDowngradeInfo(
                from: previousPhase,
                to: currentPhase,
                reason: "You've removed several scheduled workouts. I'll suggest times instead of auto-scheduling for now."
            )
        )
    }
}
```

**Required Unit Tests**:

- Test: 2 deletes → no downgrade
- Test: 3 deletes → immediate downgrade to Scheduler
- Test: Completed workout resets counter
- Test: Safety breaker triggers notification

**Files to Create**:

- `ios/Vigor/Core/Trust/TrustStateMachine.swift`
- `ios/Vigor/Core/Trust/TrustPhase.swift`
- `ios/Vigor/Core/Trust/TrustAttributionEngine.swift`
- `ios/Vigor/Core/Trust/TrustEvent.swift`
- `ios/Vigor/Core/Trust/SafetyBreaker.swift`
- `ios/VigorTests/Trust/SafetyBreakerTests.swift`

### Task 2.1b: Health Profile State Machine

**Priority**: P1
**Description**: Track user's physiological data maturity - distinct from Trust Machine

**The Distinction** (per Tech Spec §2.12):

- **Trust Machine** (Task 2.1): Tracks _permission_ - how much autonomy user grants
- **Health Profile Machine** (This task): Tracks _understanding_ - how well we know the user's body

Without this, the Ghost doesn't know if it's still learning baseline (Day 1-14) or if the user is backsliding.

**Health Profile States**:

| State           | Duration   | Meaning                | AI Behavior                                         |
| --------------- | ---------- | ---------------------- | --------------------------------------------------- |
| **Baseline**    | Days 1-14  | Gathering initial data | Conservative predictions, wide confidence intervals |
| **Adaptation**  | Days 15-45 | Learning patterns      | Narrowing predictions, identifying optimal windows  |
| **Maintenance** | Day 45+    | Stable understanding   | Confident predictions, proactive scheduling         |
| **Regression**  | Variable   | User habits breaking   | Widen confidence, reduce autonomy, offer support    |

**Implementation Details**:

```swift
// HealthProfileStateMachine.swift
enum HealthProfilePhase: String, Codable {
    case baseline       // Gathering initial 14 days of data
    case adaptation     // Learning patterns (days 15-45)
    case maintenance    // Stable understanding
    case regression     // User habits breaking down
}

actor HealthProfileStateMachine {
    @Published private(set) var currentPhase: HealthProfilePhase = .baseline
    @Published private(set) var confidenceScore: Double = 0.0  // 0.0 - 1.0

    private var dataPoints: Int = 0
    private var consecutiveMissedDays: Int = 0
    private var patternStability: Double = 0.0

    /// Called daily during Morning Cycle
    func evaluatePhaseTransition() async {
        let metrics = await gatherHealthMetrics()

        switch currentPhase {
        case .baseline:
            if metrics.daysOfData >= 14 && metrics.dataCompleteness > 0.7 {
                await transitionTo(.adaptation)
            }

        case .adaptation:
            if metrics.daysOfData >= 45 && metrics.patternStability > 0.8 {
                await transitionTo(.maintenance)
            }

        case .maintenance:
            if metrics.recentMissRate > 0.5 || metrics.patternDeviation > 0.4 {
                await transitionTo(.regression)
            }

        case .regression:
            if metrics.recoverySignals > 0.6 {
                // User is getting back on track
                await transitionTo(.adaptation)
            }
        }

        // Update confidence score used by Trust Machine
        confidenceScore = calculateConfidence(for: currentPhase, metrics: metrics)
    }

    /// Confidence score affects Trust Machine decisions
    private func calculateConfidence(for phase: HealthProfilePhase, metrics: HealthMetrics) -> Double {
        switch phase {
        case .baseline: return 0.3 + (Double(metrics.daysOfData) / 14.0) * 0.2
        case .adaptation: return 0.5 + metrics.patternStability * 0.3
        case .maintenance: return 0.8 + metrics.patternStability * 0.2
        case .regression: return max(0.3, 0.6 - metrics.recentMissRate)
        }
    }
}

// Integration with Trust Machine
extension TrustStateMachine {
    /// Confidence from Health Profile affects action thresholds
    func actionConfidenceThreshold(for action: GhostAction) -> Double {
        let healthConfidence = HealthProfileStateMachine.shared.confidenceScore
        let baseThreshold = action.baseConfidenceThreshold

        // Lower health confidence = higher threshold for autonomous action
        return baseThreshold / healthConfidence
    }
}
```

**UX Implications**:

- During `Baseline`: "Still learning your patterns..."
- During `Regression`: "Noticed things have been tough. Let's rebuild together."

**Files to Create**:

- `ios/Vigor/Core/Health/HealthProfileStateMachine.swift`
- `ios/Vigor/Core/Health/HealthProfilePhase.swift`
- `ios/Vigor/Core/Health/HealthMetrics.swift`
- `ios/VigorTests/Health/HealthProfileStateMachineTests.swift`

### Task 2.2: Core ML Model Integration

**Priority**: P1
**Description**: Integrate pattern detection, skip prediction, and recovery analysis

**Models to Create/Train**:

1. **PatternDetector** - Sleep impact, workout timing patterns
2. **SkipPredictor** - Meeting density + sleep → skip probability
3. **RecoveryAnalyzer** - HRV trends, strain accumulation
4. **OptimalWindowFinder** - Best workout times per user

**Files to Create**:

- `ios/Vigor/Core/ML/PatternDetector.swift`
- `ios/Vigor/Core/ML/SkipPredictor.swift`
- `ios/Vigor/Core/ML/RecoveryAnalyzer.swift`
- `ios/Vigor/Core/ML/OptimalWindowFinder.swift`
- ML model files (.mlmodel) in Resources

### Task 2.3: Ghost Engine Orchestration

**Priority**: P0 (Blocker)
**Description**: Central orchestration layer coordinating all Ghost components

**Implementation Details** (per Tech Spec §2.2):

- Morning cycle (6 AM): Pull sleep, calculate recovery, transform blocks
- Evening cycle (9 PM): Evaluate tomorrow, find optimal window, schedule/propose
- Workout detection response: Auto-log, update Phenome, plan next session

**Files to Create**:

- `ios/Vigor/Core/GhostEngine/GhostEngine.swift`
- `ios/Vigor/Core/GhostEngine/GhostCycle.swift`

### Task 2.4: Ghost Health Monitor

**Priority**: P1
**Description**: Systemic self-degradation for silent failures

**Implementation Details** (per Tech Spec §2.4):

- Track: background failures, missed windows, calendar failures
- Modes: healthy → degraded → safeMode → suspended
- Auto-recovery with notification

**Files to Create**:

- `ios/Vigor/Core/GhostEngine/GhostHealthMonitor.swift`
- `ios/Vigor/Core/GhostEngine/GhostHealthMode.swift`

### Task 2.5: Decision Receipt System

**Priority**: P2
**Description**: Forensic logging for Ghost decisions

**Implementation Details** (per Tech Spec §2.4):

- Record: action, inputs (hashed), alternatives, confidence, trust impact
- 90-day TTL with rolling window
- Explainability queries for debugging

**Files to Create**:

- `ios/Vigor/Core/GhostEngine/DecisionReceiptStore.swift`
- `ios/Vigor/Core/GhostEngine/DecisionReceipt.swift`

### Task 2.6: Failure Triage Logic (Disambiguation)

**Priority**: P0 (Blocker)
**Description**: Distinguish "bad schedule" from "life happened" when workouts are missed

**The Problem** (per Tech Spec §2.13):

- User misses a scheduled workout
- Was it because the TIME was wrong? → Learn to avoid that slot
- Or was it because LIFE happened? → Don't penalize the slot
- Without disambiguation, Ghost learns wrong patterns

**Implementation Details**:

```swift
// FailureDisambiguator.swift
enum MissedWorkoutReason: String, Codable {
    case badTimeSlot       // "That time doesn't work for me"
    case lifeHappened      // "Just couldn't today"
    case feltUnwell        // "Needed rest"
    case unknown           // No response (ambiguous)
}

actor FailureDisambiguator {
    /// Called when scheduled block passes without workout detection
    func handleMissedBlock(_ block: TrainingBlock) async {
        // Check if we should ask (max 1 triage per day)
        guard await canRequestTriage() else {
            await recordAmbiguousMiss(block)
            return
        }

        // Trigger One-Tap Triage UI (see Task 6.10)
        await requestTriage(for: block)
    }

    func processTriage(block: TrainingBlock, reason: MissedWorkoutReason) async {
        switch reason {
        case .badTimeSlot:
            // Learn: this slot is not good for this user
            await BehavioralMemoryStore.shared.recordRejection(
                day: block.dayOfWeek,
                hour: block.hour,
                isHardConstraint: false
            )
            // Smaller trust penalty (Ghost was wrong)
            await TrustStateMachine.shared.updateTrust(delta: -0.01)

        case .lifeHappened, .feltUnwell:
            // Don't penalize the slot
            // Minimal trust impact (not Ghost's fault)
            await TrustStateMachine.shared.updateTrust(delta: -0.005)

        case .unknown:
            // Ambiguous signal - weighted penalty
            await TrustStateMachine.shared.updateTrust(
                delta: -0.01,
                ambiguityWeight: 0.5  // Half-weight for uncertain signals
            )
        }
    }
}
```

**Files to Create**:

- `ios/Vigor/Core/GhostEngine/FailureDisambiguator.swift`
- `ios/Vigor/Core/GhostEngine/MissedWorkoutReason.swift`
- `ios/VigorTests/Ghost/FailureDisambiguatorTests.swift`

### Task 2.7: Emergency Protocol (The Red Button)

**Priority**: P1
**Description**: "Hey Siri, I'm crashing" - immediate burnout intervention

**The Differentiator** (per PRD §4.9, UX Spec §3.7):

- Target demographic: high-performers heading toward burnout
- When triggered: block calendar, silence notifications, queue recovery content
- This is the "premium concierge" moment that justifies the product positioning

**Implementation Details**:

```swift
// EmergencyManager.swift
actor EmergencyManager {
    /// Triggered via Siri: "Hey Siri, I'm crashing"
    func activateEmergencyProtocol(duration: TimeInterval = 900) async { // 15 min default
        // 1. Block calendar immediately
        await CalendarScheduler.shared.createEmergencyBlock(
            duration: duration,
            title: "Recovery Time",
            showAs: .busy
        )

        // 2. Activate Focus Mode (requires Focus Filter capability)
        await FocusModeIntegration.activateRecoveryFocus(duration: duration)

        // 3. Queue NSDR/recovery content
        await RecoveryContentPlayer.queueNSDR()

        // 4. Log for pattern detection (burnout signal)
        await BehavioralMemoryStore.shared.recordEmergencyActivation(
            timestamp: Date(),
            triggerContext: await gatherContext()
        )

        // 5. Haptic confirmation (see Task 3.6)
        await VigorHaptics.playEmergencyAcknowledgment()
    }
}

// VigorShortcuts.swift - App Intents
import AppIntents

struct CrashingIntent: AppIntent {
    static var title: LocalizedStringResource = "I'm Crashing"
    static var description = IntentDescription("Activate emergency recovery protocol")

    @Parameter(title: "Duration")
    var durationMinutes: Int?

    func perform() async throws -> some IntentResult {
        let duration = TimeInterval((durationMinutes ?? 15) * 60)
        await EmergencyManager.shared.activateEmergencyProtocol(duration: duration)
        return .result(dialog: "Got it. Taking care of you.")
    }
}

struct VigorShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CrashingIntent(),
            phrases: [
                "I'm crashing in \(.applicationName)",
                "Emergency mode in \(.applicationName)",
                "I need a break with \(.applicationName)"
            ],
            shortTitle: "I'm Crashing",
            systemImageName: "heart.circle"
        )
    }
}
```

**Focus Mode Integration**:

```swift
// FocusModeIntegration.swift
import Intents

final class FocusModeIntegration {
    /// Activate Recovery Focus (requires user to create "Recovery" Focus in Settings)
    static func activateRecoveryFocus(duration: TimeInterval) async {
        // Use INSetFocusModeIntent or Focus Filter API
        // Fallback: Just DND via notification settings
    }
}
```

**Files to Create**:

- `ios/Vigor/Core/Emergency/EmergencyManager.swift`
- `ios/Vigor/Core/Emergency/RecoveryContentPlayer.swift`
- `ios/Vigor/Core/Emergency/FocusModeIntegration.swift`
- `ios/Vigor/App/Intents/VigorShortcuts.swift`
- `ios/Vigor/App/Intents/CrashingIntent.swift`
- Configure App Intents capability in Xcode

### Task 2.8: Recovery Content Manager

**Priority**: P1
**Description**: Content delivery system for Emergency Protocol and NSDR/breathing exercises

**The Problem**:
Task 2.7 handles the _trigger_ logic for "I'm crashing," but where does the actual recovery content come from?

**Content Types**:

| Content                 | Source              | Duration  | Use Case        |
| ----------------------- | ------------------- | --------- | --------------- |
| **NSDR Audio**          | Bundled + Streaming | 10-20 min | Deep recovery   |
| **Breathing Guides**    | Bundled + Haptic    | 2-5 min   | Quick reset     |
| **Grounding Exercises** | Bundled text        | 1-2 min   | Anxiety relief  |
| **Ambient Sounds**      | Streaming           | Variable  | Background calm |

**Implementation Details**:

```swift
// RecoveryContentManager.swift
actor RecoveryContentManager {
    enum ContentType {
        case nsdr(duration: Int)      // Non-Sleep Deep Rest
        case breathing(pattern: BreathingPattern)
        case grounding
        case ambient(sound: AmbientSound)
    }

    /// Queue content for immediate playback
    func queue(_ type: ContentType) async {
        switch type {
        case .nsdr(let duration):
            await playNSDR(duration: duration)
        case .breathing(let pattern):
            await startBreathingGuide(pattern: pattern)
        case .grounding:
            await showGroundingExercise()
        case .ambient(let sound):
            await playAmbient(sound: sound)
        }
    }

    /// NSDR: Guided relaxation audio
    private func playNSDR(duration: Int) async {
        // 1. Check for bundled audio (offline-first)
        if let localURL = Bundle.main.url(
            forResource: "nsdr_\(duration)min",
            withExtension: "m4a"
        ) {
            await AudioPlayer.shared.play(localURL)
        } else {
            // 2. Stream from CDN if not bundled
            await AudioPlayer.shared.stream(
                from: "https://cdn.vigor.app/nsdr/\(duration)min.m4a"
            )
        }

        // 3. Sync haptics with audio cues (via Watch)
        await VigorHaptics.playBreathingPrompt()
    }

    /// Breathing: Haptic-guided patterns
    private func startBreathingGuide(pattern: BreathingPattern) async {
        // Box breathing: 4-4-4-4
        // 4-7-8 breathing: inhale 4, hold 7, exhale 8
        for cycle in 0..<pattern.cycles {
            await VigorHaptics.playBreathingPrompt(
                inhaleSeconds: pattern.inhale,
                exhaleSeconds: pattern.exhale
            )
            try? await Task.sleep(for: .seconds(pattern.cycleDuration))
        }
    }
}

enum BreathingPattern {
    case box          // 4-4-4-4
    case relaxing     // 4-7-8
    case energizing   // 4-2-4

    var inhale: Double { ... }
    var hold: Double { ... }
    var exhale: Double { ... }
    var cycles: Int { ... }
}
```

**Bundled Assets** (offline-first):

- `nsdr_10min.m4a` - Short NSDR session
- `nsdr_20min.m4a` - Full NSDR session
- `ambient_rain.m4a` - Rain sounds
- `ambient_forest.m4a` - Forest sounds

**Files to Create**:

- `ios/Vigor/Core/Emergency/RecoveryContentManager.swift`
- `ios/Vigor/Core/Emergency/BreathingPattern.swift`
- `ios/Vigor/Core/Emergency/AudioPlayer.swift`
- `ios/Vigor/Resources/Audio/` - Bundled audio assets

### Task 2.9: Context & Travel Engine

**Priority**: P1
**Description**: Location-aware context detection for "Smart Illusion" - silence when away from home

**Why This Matters** (per PRD §3.3):

> "Days with travel = No scheduling"

The Ghost must know when the user is traveling to avoid scheduling workouts in hotel rooms or airport lounges. This requires LocationManager integration but with privacy-first design.

**Context Types**:

| Context        | Detection Method             | Ghost Behavior             |
| -------------- | ---------------------------- | -------------------------- |
| **Home**       | Significant location history | Normal scheduling          |
| **Work**       | Repeated weekday location    | Lunch/pre-work windows     |
| **Traveling**  | 50+ km from home             | No scheduling, gentle mode |
| **Gym Nearby** | Location API (if enabled)    | Boost gym workout priority |

**Implementation Details**:

```swift
// ContextEngine.swift
actor ContextEngine {
    enum UserContext: Codable {
        case home
        case work
        case traveling(distance: Double)
        case unknown
    }

    private let locationManager: CLLocationManager

    /// Detect current context without continuous tracking
    func detectContext() async -> UserContext {
        guard let homeLocation = await learnedHomeLocation() else {
            return .unknown
        }

        guard let currentLocation = await getCurrentLocation() else {
            return .unknown
        }

        let distanceFromHome = currentLocation.distance(from: homeLocation)

        if distanceFromHome < 500 {
            return .home
        } else if distanceFromHome > 50_000 {
            return .traveling(distance: distanceFromHome)
        } else if await isKnownWorkLocation(currentLocation) {
            return .work
        }

        return .unknown
    }

    /// Feed travel signal to GhostEngine
    func updateTravelStatus() async {
        let context = await detectContext()

        switch context {
        case .traveling(let distance):
            await RawSignalStore.shared.store(
                signal: TravelSignal(
                    detected: true,
                    distanceFromHome: distance,
                    timestamp: Date()
                )
            )
            // Disable scheduling for today
            await GhostEngine.shared.enterTravelMode()

        case .home:
            await GhostEngine.shared.exitTravelMode()

        default:
            break
        }
    }

    /// Learn home location from significant location history
    private func learnedHomeLocation() async -> CLLocation? {
        // Use overnight locations (11pm-6am) to infer home
        let overnightLocations = await BehavioralMemoryStore.shared.query(
            .significantLocations(timeRange: 23..<6)
        )
        return overnightLocations.mostFrequent()
    }
}
```

**Privacy-First Design**:

- Use `significantLocationChangeMonitoring` (not continuous GPS)
- Store learned locations on-device only (never sync)
- Users can disable in Settings → no degradation, just less smart

**Files to Create**:

- `ios/Vigor/Core/Context/ContextEngine.swift`
- `ios/Vigor/Core/Context/TravelSignal.swift`
- `ios/Vigor/Core/Context/LocationLearner.swift`
- `ios/VigorTests/Context/ContextEngineTests.swift`

### Task 2.10: Ghost Simulation Testing Suite

**Priority**: P1
**Description**: Testing harness to simulate 60+ days of user behavior for Trust Ladder validation

**Why This Is Critical**:

The Trust Ladder takes 60+ days to fully mature (Phase 2 Observer → Phase 5 Guardian). Manual testing is impossible. Without simulation:

- We can't verify Trust progression logic
- We can't test Safety Breaker triggers
- We can't validate Phenome pattern detection

**Implementation Details**:

```swift
// GhostSimulator.swift
final class GhostSimulator {
    struct SimulationConfig {
        let days: Int                    // e.g., 60
        let workoutCompletionRate: Double // e.g., 0.7 (70%)
        let skipPattern: SkipPattern     // e.g., .mondayHeavy
        let recoveryVariance: ClosedRange<Double> // e.g., 0.5...0.95
        let travelDays: Set<Int>         // e.g., [15, 16, 30, 31]
    }

    /// Run full simulation and return final state
    func simulate(config: SimulationConfig) async -> SimulationResult {
        let ghost = GhostEngine(testMode: true)

        for day in 1...config.days {
            // 1. Generate mock HealthKit data
            let mockHealthData = generateMockHealthData(
                day: day,
                recoveryScore: Double.random(in: config.recoveryVariance)
            )
            await ghost.ingestHealthData(mockHealthData)

            // 2. Simulate calendar busyness
            let mockCalendar = generateMockCalendar(day: day)
            await ghost.ingestCalendar(mockCalendar)

            // 3. Simulate travel days
            if config.travelDays.contains(day) {
                await ghost.enterTravelMode()
            } else {
                await ghost.exitTravelMode()
            }

            // 4. Simulate workout completion/skip
            let scheduledWorkout = await ghost.scheduleForToday()
            if shouldComplete(day: day, rate: config.workoutCompletionRate) {
                await ghost.completeWorkout(scheduledWorkout)
            } else {
                await ghost.skipWorkout(scheduledWorkout, reason: .skipped)
            }

            // 5. Run nightly cycles
            await ghost.runEveningCycle()
        }

        return SimulationResult(
            finalTrustScore: ghost.currentTrustScore,
            trustPhase: ghost.currentTrustPhase,
            safetyBreakerTriggers: ghost.safetyBreakerHistory,
            patternStats: ghost.patternStats
        )
    }
}

// SimulationTests.swift
final class SimulationTests: XCTestCase {
    func testTrustProgressionTo60Days() async {
        let config = GhostSimulator.SimulationConfig(
            days: 60,
            workoutCompletionRate: 0.85,
            skipPattern: .random,
            recoveryVariance: 0.6...0.9,
            travelDays: [15, 16, 45]
        )

        let result = await GhostSimulator().simulate(config: config)

        XCTAssertEqual(result.trustPhase, .guardian)
        XCTAssertGreaterThan(result.finalTrustScore, 0.75)
    }

    func testSafetyBreakerTriggersOnPoorRecovery() async {
        let config = GhostSimulator.SimulationConfig(
            days: 14,
            workoutCompletionRate: 0.9,
            skipPattern: .none,
            recoveryVariance: 0.2...0.4, // Consistently poor recovery
            travelDays: []
        )

        let result = await GhostSimulator().simulate(config: config)

        XCTAssertGreaterThan(result.safetyBreakerTriggers.count, 0)
    }
}
```

**Files to Create**:

- `ios/VigorTests/Simulation/GhostSimulator.swift`
- `ios/VigorTests/Simulation/SimulationConfig.swift`
- `ios/VigorTests/Simulation/SimulationResult.swift`
- `ios/VigorTests/Simulation/MockDataGenerator.swift`
- `ios/VigorTests/Simulation/SimulationTests.swift`

---

## Phase 3: watchOS Companion App

### Task 3.1: watchOS App Foundation

**Priority**: P0 (Blocker)
**Description**: Basic watchOS app with WatchConnectivity

**Files to Create**:

- `ios/VigorWatch/App/VigorWatchApp.swift`
- `ios/VigorWatch/Extension/ExtensionDelegate.swift`
- `ios/Shared/WatchConnectivity/WatchSessionManager.swift`

### Task 3.2: Context-Aware Complications

**Priority**: P1
**Description**: Complications that transform based on time and context

**Implementation Details** (per UX Spec §2.2.2):

- Morning: Recovery Score (with staleness indicators)
- Workday: Next Block Countdown or Movement Prompt
- Evening: Ghost Status checkmark
- Post-workout: Streak display (1 hour)

**Files to Create**:

- `ios/VigorWatch/Complications/ComplicationController.swift`
- `ios/VigorWatch/Complications/ComplicationDataSource.swift`
- `ios/VigorWatch/Complications/ComplicationViews.swift`

### Task 3.3: Watch App Screens (3 Only)

**Priority**: P1
**Description**: Minimal watch UI per UX Spec

**Screens**:

1. **Today** - Recovery score, next block, streak, "Start Now" button
2. **Active Workout** - Current exercise, progress, rest timer
3. **Post-Workout** - Feel check (1-tap slider)

**Files to Create**:

- `ios/VigorWatch/Views/TodayView.swift`
- `ios/VigorWatch/Views/ActiveWorkoutView.swift`
- `ios/VigorWatch/Views/PostWorkoutView.swift`

### Task 3.4: Workout Detection & Logging

**Priority**: P0 (Blocker)
**Description**: Auto-detect workouts from Watch sensors

**Implementation Details**:

- HKWorkoutSession integration
- Passive acceptance model: "Logged. Tap if wrong."
- Sync to iPhone via WatchConnectivity + direct backend

**Files to Create**:

- `ios/VigorWatch/Workout/WorkoutDetectionEngine.swift`
- `ios/VigorWatch/Workout/WorkoutLogger.swift`

### Task 3.5: Hybrid Orchestration (Morning Sync)

**Priority**: P1
**Description**: Handle "bathroom charger" users per Tech Spec §4.5

**Implementation Details**:

- iPhone Silent Push as primary wake mechanism
- Watch fallback on wrist-raise if iPhone unavailable
- 6-hour staleness check for Watch Phenome

**Files to Create**:

- `ios/VigorWatch/Sync/HybridOrchestrator.swift`
- `ios/Shared/Sync/StalenessChecker.swift`

### Task 3.6: Haptic Engine Implementation

**Priority**: P0 (Elevated from P1)
**Description**: Implement the Haptic Vocabulary - Watch as intimate communication channel

**Why P0** (per UX Spec §4.6):

> "The Watch is on the skin... Haptics are the most intimate communication channel."

Generic haptics feel like notifications. Vigor's haptics should feel like a _touch_. This is **not just implementation** - it requires an **Iterative Tuning Phase** on real hardware.

**Haptic Vocabulary**:

| Context                    | Pattern                   | Technical Implementation                        |
| -------------------------- | ------------------------- | ----------------------------------------------- |
| **Acknowledgment**         | Single soft pulse         | `.click`                                        |
| **Gentle Correction**      | Two soft pulses, pause    | `.click`, 200ms, `.click`                       |
| **Breathing Prompt**       | Slow wave (inhale/exhale) | Custom `.notification` sequence                 |
| **Completion Celebration** | Solid resonant pulse      | `.success`                                      |
| **Emergency Ack**          | Three rapid, one long     | `.notification` × 3, `.success`                 |
| **Trust Advancement**      | Rising triple pulse       | `.click` (light), `.click` (medium), `.success` |

**Implementation Details**:

```swift
// VigorHaptics.swift (Shared between iOS and watchOS)
import WatchKit

enum VigorHaptics {
    /// Single soft pulse - "I heard you"
    static func playAcknowledgment() {
        WKInterfaceDevice.current().play(.click)
    }

    /// Two soft pulses - "Hmm, let me adjust"
    static func playGentleCorrection() async {
        let device = WKInterfaceDevice.current()
        device.play(.click)
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
        device.play(.click)
    }

    /// Breathing guide - slow wave pattern
    static func playBreathingPrompt(inhaleSeconds: Double = 4, exhaleSeconds: Double = 6) async {
        // Ramp up haptic intensity during inhale
        // Ramp down during exhale
        // Uses .notification for softer feel
    }

    /// Solid resonant pulse - "Done!"
    static func playCompletion() {
        WKInterfaceDevice.current().play(.success)
    }

    /// Emergency acknowledged - "I've got you"
    static func playEmergencyAcknowledgment() async {
        let device = WKInterfaceDevice.current()
        for _ in 0..<3 {
            device.play(.notification)
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms pause
        device.play(.success)
    }

    /// Trust phase advancement - "You're growing"
    static func playTrustAdvancement() async {
        let device = WKInterfaceDevice.current()
        device.play(.click) // Light
        try? await Task.sleep(nanoseconds: 150_000_000)
        device.play(.click) // Medium
        try? await Task.sleep(nanoseconds: 150_000_000)
        device.play(.success) // Full
    }
}
```

**Files to Create**:

- `ios/Shared/Haptics/VigorHaptics.swift`
- `ios/VigorWatch/Haptics/WatchHapticPlayer.swift`
- `ios/VigorTests/Haptics/HapticSequenceTests.swift`

### Task 3.7: Staleness Visualizers (ViewModifiers)

**Priority**: P1
**Description**: Visual degradation when data is stale - "Staleness Honesty"

**The Trust Problem** (per UX Spec §2.3.3, Tech Spec §4.5):

- Background sync WILL lag sometimes (iOS throttling, network issues)
- If we show stale data as fresh, user makes bad decisions → trust erosion
- Solution: Visually honest degradation that says "this might be outdated"

**Staleness Thresholds**:

| Age           | Visual State                      | Meaning        |
| ------------- | --------------------------------- | -------------- |
| < 30 min      | Full opacity, no indicator        | Fresh          |
| 30 min - 2 hr | Subtle dimming (90% opacity)      | Slightly stale |
| 2 - 6 hr      | Visible dimming (70%) + timestamp | Stale          |
| > 6 hr        | Desaturated + warning badge       | Very stale     |
| > 24 hr       | Grayed out + "Tap to refresh"     | Expired        |

**Implementation Details**:

```swift
// StalenessModifier.swift
import SwiftUI

struct StalenessModifier: ViewModifier {
    let lastSync: Date
    @Environment(\.now) private var now

    private var staleness: StalenessLevel {
        let age = now.timeIntervalSince(lastSync)
        switch age {
        case ..<1800: return .fresh           // < 30 min
        case ..<7200: return .slightlyStale   // < 2 hr
        case ..<21600: return .stale          // < 6 hr
        case ..<86400: return .veryStale      // < 24 hr
        default: return .expired
        }
    }

    func body(content: Content) -> some View {
        content
            .opacity(staleness.opacity)
            .saturation(staleness.saturation)
            .overlay(alignment: .topTrailing) {
                if staleness >= .stale {
                    StalenessIndicator(level: staleness, lastSync: lastSync)
                }
            }
    }
}

enum StalenessLevel: Comparable {
    case fresh, slightlyStale, stale, veryStale, expired

    var opacity: Double {
        switch self {
        case .fresh: return 1.0
        case .slightlyStale: return 0.9
        case .stale: return 0.7
        case .veryStale: return 0.5
        case .expired: return 0.3
        }
    }

    var saturation: Double {
        switch self {
        case .fresh, .slightlyStale: return 1.0
        case .stale: return 0.8
        case .veryStale: return 0.5
        case .expired: return 0.2
        }
    }
}

// Usage:
RecoveryScoreCard(score: phenome.recoveryScore)
    .staleState(lastSync: phenome.lastSyncTimestamp)

extension View {
    func staleState(lastSync: Date) -> some View {
        modifier(StalenessModifier(lastSync: lastSync))
    }
}
```

**Apply To**:

- Recovery Score (iOS + Watch)
- Next Block countdown
- Complication data
- Any Phenome-derived display

**Files to Create**:

- `ios/Shared/UI/Modifiers/StalenessModifier.swift`
- `ios/Shared/UI/Components/StalenessIndicator.swift`
- `ios/Shared/UI/StalenessLevel.swift`

---

## Phase 4: Azure Backend Modernization

### Task 4.1: Refactor API Structure for Ghost

**Priority**: P0 (Blocker)
**Description**: Update Azure Functions for native app consumption

**New/Updated Endpoints**:

```
POST /api/ghost/sync           # Anonymized pattern sync
GET  /api/ghost/config         # Remote Ghost configuration
POST /api/workouts/generate    # RAG-grounded workout generation
GET  /api/models/update        # Core ML model distribution
POST /api/phenome/backup       # Server-side Phenome backup (optional)
```

**Files to Modify**:

- `functions-modernized/function_app.py`
- Add new route handlers

### Task 4.2: Remote Configuration System

**Priority**: P1
**Description**: Azure Blob Storage for Ghost heuristics (per Tech Spec §2.8)

**Configuration Categories**:

- Trust thresholds (phase advancement rules)
- Notification timing rules
- Sacred time defaults
- Recovery score weights
- Skip prediction factors

**Files to Create**:

- `functions-modernized/shared/remote_config.py`
- Add blob storage integration

### Task 4.3: RAG Workout Generation (Dynamic Skeletons)

**Priority**: P1
**Description**: Hybrid template + LLM generation (per Tech Spec §3.4)

**Implementation Details**:

- Template engine for 90% of requests (fast, cheap)
- LLM for edge cases and semantic changes
- Workout Contracts: deterministic post-generation validator
- Exercise variation from RAG pool

**Files to Modify**:

- `functions-modernized/shared/openai_client.py`
- Add template engine
- Add workout validator

### Task 4.4: Core ML Model Distribution

**Priority**: P2
**Description**: Endpoint for model version checking and download

**Files to Create**:

- `functions-modernized/shared/model_distribution.py`
- Azure Blob Storage for model files

### Task 4.5: Cosmos DB Schema Updates

**Priority**: P1
**Description**: Update schema for Ghost-specific data

**New Collections/Updates**:

- `ghost_configs` - Remote configuration versions
- `phenome_backups` - Optional server-side backup
- `decision_receipts` - Anonymized decision analytics
- `push_tokens` - APNs device tokens for silent push
- Update `users` - Add trust state fields

**Files to Modify**:

- `functions-modernized/shared/cosmos_db.py`
- `functions-modernized/shared/models.py`

### Task 4.6: Silent Push Wake Infrastructure (Azure Side)

**Priority**: P0 (Blocker)
**Description**: Azure Timer Function to wake iOS apps via Silent Push at 5:55 AM

**The Problem** (per Tech Spec §2.9 - Invisibility Paradox):

- iOS throttles BGTaskScheduler for apps not opened recently
- After 3 days of non-use, Morning Cycle may not run
- Silent Push (`content-available: 1`) bypasses this throttling
- **Without this, the Ghost dies in the background**

**Implementation Details**:

```python
# morning_wake_push.py
import azure.functions as func
from azure.cosmos.aio import CosmosClient
import aiohttp
import jwt
import time

# Timer trigger: 5:55 AM in each user's timezone
@app.timer_trigger(
    schedule="55 5 * * *",  # 5:55 AM daily
    arg_name="timer",
    run_on_startup=False
)
async def morning_wake_push(timer: func.TimerRequest) -> None:
    """Wake all iOS devices via Silent Push before Morning Cycle"""

    # Get all active users with push tokens
    users_with_tokens = await cosmos_db.get_users_with_push_tokens()

    for user in users_with_tokens:
        # Respect user timezone (don't wake at 5:55 AM UTC for SF user)
        if not is_local_morning(user.timezone):
            continue

        # Send silent push via APNs
        await send_silent_push(
            device_token=user.apns_token,
            payload={
                "aps": {
                    "content-available": 1  # Silent push flag
                },
                "ghost_action": "morning_cycle"
            }
        )

async def send_silent_push(device_token: str, payload: dict):
    """Send push via APNs HTTP/2 API"""
    # Use PyAPNs2 or direct HTTP/2 to api.push.apple.com
    pass
```

**APNs Configuration Required**:

- Apple Push Notification Service certificate (`.p8` key)
- Key ID and Team ID in Azure Key Vault
- APNs endpoint: `api.push.apple.com` (production)

**Files to Create**:

- `functions-modernized/morning_wake_push.py`
- `functions-modernized/evening_planning_push.py`
- `functions-modernized/shared/apns_client.py`
- `functions-modernized/shared/push_token_store.py`

### Task 4.7: Push Token Registration Endpoint

**Priority**: P0 (Blocker)
**Description**: Endpoint for iOS app to register/update APNs device tokens

**Implementation Details**:

```python
# In function_app.py
@app.route(
    route="devices/push-token",
    methods=["POST", "DELETE"],
    auth_level=func.AuthLevel.ANONYMOUS
)
async def manage_push_token(req: func.HttpRequest) -> func.HttpResponse:
    """Register or remove APNs push token for user's device"""
    current_user = await get_current_user_from_token(req)
    if not current_user:
        return unauthorized_response()

    if req.method == "POST":
        data = req.get_json()
        await cosmos_db.upsert_push_token(
            user_id=current_user["email"],
            device_id=data["device_id"],
            apns_token=data["apns_token"],
            timezone=data.get("timezone", "UTC")
        )
        return success_response({"registered": True})

    elif req.method == "DELETE":
        device_id = req.params.get("device_id")
        await cosmos_db.remove_push_token(
            user_id=current_user["email"],
            device_id=device_id
        )
        return success_response({"removed": True})
```

**Files to Modify**:

- `functions-modernized/function_app.py` - Add endpoint
- `functions-modernized/shared/cosmos_db.py` - Add token operations

### Task 4.8: Admin Dashboard Integration

**Priority**: P2
**Description**: Wire retained React Admin components to new Azure Functions backend for operational visibility

**Why This Exists**:

Phase 0.1 retained React admin components (`AdminPage.tsx`, `AdminAuditSecurity.tsx`, etc.) but the Tasks.md never wired them to the new backend. Without this, operators have no visibility into Ghost decisions or system health.

**Admin Dashboard Capabilities**:

| Feature                | Data Source                       | UI Component             |
| ---------------------- | --------------------------------- | ------------------------ |
| **Decision Audit Log** | `decision_receipts` container     | `AdminAuditSecurity.tsx` |
| **User Trust Phases**  | `trust_state` in user profiles    | `AdminPage.tsx`          |
| **Ghost Health**       | `ghost_health` telemetry          | `AnalyticsDashboard.tsx` |
| **Safety Breakers**    | `safety_breaker_events` container | Custom alert panel       |
| **Rate Limit Status**  | `rate_limiter.py` metrics         | Real-time dashboard      |

**Implementation Details**:

```python
# In function_app.py - Admin endpoints
@app.route(
    route="admin/decision-receipts",
    methods=["GET"],
    auth_level=func.AuthLevel.ANONYMOUS
)
async def get_decision_receipts(req: func.HttpRequest) -> func.HttpResponse:
    """Get recent Ghost decision receipts for audit"""
    current_user = await get_current_user_from_token(req)
    if not is_admin(current_user):
        return forbidden_response()

    days_back = int(req.params.get("days", "7"))
    user_filter = req.params.get("user_id")  # Optional

    receipts = await cosmos_db.query_decision_receipts(
        days_back=days_back,
        user_id=user_filter
    )

    return success_response({"receipts": receipts})


@app.route(
    route="admin/ghost-health",
    methods=["GET"],
    auth_level=func.AuthLevel.ANONYMOUS
)
async def get_ghost_health(req: func.HttpRequest) -> func.HttpResponse:
    """Get Ghost system health metrics"""
    current_user = await get_current_user_from_token(req)
    if not is_admin(current_user):
        return forbidden_response()

    health = await cosmos_db.get_ghost_health_metrics()
    return success_response(health)


@app.route(
    route="admin/safety-breakers",
    methods=["GET"],
    auth_level=func.AuthLevel.ANONYMOUS
)
async def get_safety_breaker_events(req: func.HttpRequest) -> func.HttpResponse:
    """Get Safety Breaker trigger events"""
    current_user = await get_current_user_from_token(req)
    if not is_admin(current_user):
        return forbidden_response()

    events = await cosmos_db.query_safety_breaker_events(
        days_back=int(req.params.get("days", "30"))
    )
    return success_response({"events": events})
```

**Frontend Integration**:

```typescript
// frontend/src/services/adminApi.ts
export const AdminAPI = {
  async getDecisionReceipts(daysBack = 7, userId?: string) {
    const params = new URLSearchParams({ days: String(daysBack) });
    if (userId) params.append("user_id", userId);
    return fetch(`/api/admin/decision-receipts?${params}`);
  },

  async getGhostHealth() {
    return fetch("/api/admin/ghost-health");
  },

  async getSafetyBreakerEvents(daysBack = 30) {
    return fetch(`/api/admin/safety-breakers?days=${daysBack}`);
  },
};
```

**Files to Modify**:

- `functions-modernized/function_app.py` - Add admin endpoints
- `functions-modernized/shared/cosmos_db.py` - Add admin query functions
- `frontend/src/services/adminApi.ts` - Create API client
- `frontend/src/pages/AdminPage.tsx` - Wire to new backend
- `frontend/src/components/AdminAuditSecurity.tsx` - Update data source

---

## Phase 5: Calendar & Notification System

### Task 5.1: Block Transformation Logic

**Priority**: P0 (Blocker)
**Description**: Transform blocks based on real-time data

**Transformation Rules** (per PRD §4.4):

- Heavy Lifts → Recovery Walk (if HRV crashed)
- Any block → Remove (if sleep < threshold)
- Preserve user ego: Show what was changed and why

**Files to Create**:

- `ios/Vigor/Data/Calendar/BlockTransformer.swift`
- `ios/Vigor/Data/Calendar/TransformationRules.swift`

### Task 5.2: Sacred Time Detection

**Priority**: P1
**Description**: Protect sacred time slots from scheduling

**Detection Signals** (per PRD §4.4):

- Block deleted 3+ times at same time → Never schedule
- Weekend mornings before 9 AM → Protected by default
- Recurring personal blocks → Always protected
- Lunch blocks (12-1 PM) → Protected unless opted in

**Files to Create**:

- `ios/Vigor/Data/Calendar/SacredTimeDetector.swift`
- `ios/Vigor/Core/Phenome/SacredTimeStore.swift`

### Task 5.3: Notification Orchestrator

**Priority**: P0 (Blocker)
**Description**: Max 1 notification per day, binary actions only

**Notification Types**:

- Block proposal (Phase 2): "6 PM workout? [Yes/No]"
- Workout confirmation: "45 min logged. [Correct/Wrong]"
- Block transformation: "Changed to Recovery Walk. [OK/Revert]"

**Implementation Details** (per PRD §4.3):

- Never ask questions
- Binary response only
- Contextual silence (poor sleep = say nothing)

**Files to Create**:

- `ios/Vigor/Notifications/NotificationOrchestrator.swift`
- `ios/Vigor/Notifications/NotificationTypes.swift`
- `ios/Vigor/Notifications/NotificationContent.swift`

### Task 5.4: Calendar Shadow Sync (Corporate Visibility) - POLISH

**Priority**: P2 (Core functionality moved to Task 1.4b)
**Description**: Enhanced Shadow Sync features - delegate detection, conflict resolution, advanced MDM handling

**Note**: Core Shadow Sync functionality (writing "Busy" blocks to Exchange) is now in **Task 1.4b** in Phase 1. This task covers polish and edge cases for enterprise users.

**Why This Is Now Polish**:

Task 1.4b ensures basic Shadow Sync works from Day 1. This task adds:

- Delegate modification detection
- Assistant/EA conflict handling
- Advanced MDM diagnostics
- Sync conflict resolution

**Implementation Details**:

```swift
// ShadowSync.swift
final class CalendarShadowSync {
    private let graphClient: MSGraphClient

    /// Sync local Vigor block to user's Exchange/Outlook calendar
    func syncToExchange(_ block: TrainingBlock) async throws {
        // Create event in user's primary Outlook calendar
        let event = MSEvent(
            subject: "🏋️ Training Block",
            start: block.startDate,
            end: block.endDate,
            showAs: .busy,  // Critical: blocks time for colleagues
            isReminderOn: false,
            body: "Scheduled by Vigor. Focus time for fitness."
        )

        try await graphClient.createEvent(event)
    }

    /// Detect if block was deleted by assistant (delegate)
    func detectDelegateModification(_ event: MSEvent) -> Bool {
        // Check lastModifiedBy field
        guard let modifier = event.lastModifiedBy else { return false }
        return modifier.emailAddress != currentUserEmail
    }
}
```

**MDM Fallback Handler**:

```swift
// MDMFallbackHandler.swift
final class MDMFallbackHandler {
    /// Detect if corporate MDM blocks Graph API
    func isGraphAPIBlocked() async -> Bool {
        do {
            // Attempt lightweight Graph call
            _ = try await graphClient.getMe()
            return false
        } catch let error as MSGraphError {
            // MDM typically returns 403 or connection refused
            return error.isAccessDenied || error.isConnectionRefused
        } catch {
            return true
        }
    }

    /// Graceful degradation when Graph is blocked
    func handleBlockedGraph() {
        // Disable shadow sync, continue with local-only
        UserDefaults.standard.set(false, forKey: "shadowSyncEnabled")

        // Inform user (one-time)
        if !hasShownMDMWarning {
            showMDMWarningUI()
        }
    }
}
```

**Files to Create**:

- `ios/Vigor/Data/Calendar/ShadowSync.swift`
- `ios/Vigor/Data/Calendar/GraphAPIClient.swift`
- `ios/Vigor/Data/Calendar/MDMFallbackHandler.swift`
- `ios/Vigor/Data/Calendar/DelegateDetector.swift`

### Task 5.5: Deterministic Slot-Finding (Chaos Mode)

**Priority**: P1
**Description**: Fast rescheduling without LLM (per Tech Spec §2.6)

**Implementation Details**:

- Deterministic algorithm for "move to later"
- LLM only for semantic changes (injuries, exercise swaps)
- Preferred window matching

**Files to Implement**:

- Add to `ios/Vigor/Data/Calendar/CalendarScheduler.swift`

### Task 5.6: "Why?" UI Integration (Explainability)

**Priority**: P2
**Description**: User-facing transparency log that explains Ghost decisions in plain English

**The Problem** (per UX Spec §6.2):

- Task 2.5 creates `DecisionReceipts` for forensic logging
- But users need to understand _why_ things happened
- "Why was my workout changed to Recovery Walk?" → Clear answer

**Implementation Details**:

```swift
// WhyExplanationView.swift
struct WhyExplanationView: View {
    let receipt: DecisionReceipt

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // The decision
            Text(receipt.actionDescription)
                .font(.headline)

            // Plain English explanation
            Text(receipt.humanReadableReason)
                .font(.body)
                .foregroundColor(.secondary)

            // Contributing factors
            ForEach(receipt.factors, id: \.name) { factor in
                FactorRow(factor: factor)
            }

            // Timestamp
            Text("Decided \(receipt.timestamp.relative)")
                .font(.caption)
                .foregroundColor(.tertiary)
        }
        .padding()
    }
}

struct FactorRow: View {
    let factor: DecisionFactor

    var body: some View {
        HStack {
            Image(systemName: factor.icon)
                .foregroundColor(factor.impactColor)

            VStack(alignment: .leading) {
                Text(factor.name)
                    .font(.subheadline)
                Text(factor.value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Impact indicator
            Text(factor.impactLabel)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(factor.impactColor.opacity(0.2))
                .cornerRadius(4)
        }
    }
}

// DecisionReceipt extension for human-readable output
extension DecisionReceipt {
    var humanReadableReason: String {
        switch action {
        case .transformedBlock(let from, let to):
            return "Changed from \(from.type) to \(to.type) because your recovery signals suggested your body needs gentler movement today."

        case .scheduledBlock(let block):
            return "Scheduled for \(block.time) because this window had the best combination of calendar availability and your historical energy patterns."

        case .removedBlock(let block):
            return "Removed today's workout because your sleep was significantly below your baseline, and pushing through would likely hurt more than help."

        case .trustDowngrade(let from, let to):
            return "Stepped back to \(to.displayName) because recent schedule changes suggested the timing wasn't working for you."
        }
    }

    var factors: [DecisionFactor] {
        // Extract from inputSnapshot in provenance
        return inputs.map { input in
            DecisionFactor(
                name: input.displayName,
                value: input.displayValue,
                impact: input.impactLevel,
                icon: input.icon
            )
        }
    }
}
```

**Entry Points**:

- Tap on any calendar block → "Why this time?"
- Tap on transformation notification → "Why was this changed?"
- Today View "Recent Decisions" section
- Settings → "Decision History"

**Files to Create**:

- `ios/Vigor/UI/Explainability/WhyExplanationView.swift`
- `ios/Vigor/UI/Explainability/FactorRow.swift`
- `ios/Vigor/UI/Explainability/DecisionHistoryView.swift`
- `ios/Vigor/Core/GhostEngine/DecisionReceipt+HumanReadable.swift`

---

## Phase 6: UX Polish & Testing

### Task 6.1: Onboarding Flow (Day 1 Magic + Absolution)

**Priority**: P0 (Blocker)
**Description**: < 2 minute onboarding with instant insight AND absolution narrative

**Flow** (per PRD §3.2, §5.1, UX Spec §5.2):

1. Health Data permission (one tap)
2. Calendar permission (one tap)
3. Basic profile: Equipment, injuries (30 seconds)
4. **Absolution Moment** - The differentiating experience

**The Absolution Engine**:

> "It wasn't your fault... Your schedule was designed to make you fail."

This is NOT a generic insight chart. It's a specific narrative that:

- Identifies failure patterns in the user's history
- Externalizes blame from user to circumstances
- Creates emotional relief that builds immediate trust

**Implementation Details**:

```swift
// AbsolutionEngine.swift
struct AbsolutionNarrative {
    let headline: String           // "It wasn't your fault."
    let explanation: String        // "Looking at your last 90 days..."
    let pattern: FailurePattern    // The detected pattern
    let absolution: String         // "Your schedule was designed to make you fail."
    let hope: String               // "Here's what we can do together."
}

enum FailurePattern: String {
    case backToBackMeetings    // "You had 3+ hour meeting blocks before every skipped workout"
    case sleepDebt             // "Your sleep averaged 5.2 hours on days you missed training"
    case weekendOnly           // "You only worked out on weekends - weekdays were impossible"
    case eveningCollapse       // "By 6 PM, you had no energy left - meetings drained you"
    case noPattern             // Fallback: "Life got busy. That's human."
}

actor AbsolutionEngine {
    /// Analyze 7-90 day history to find the absolution narrative
    func generateAbsolution(from phenome: Phenome) async -> AbsolutionNarrative {
        // 1. Find workout gaps (skipped or missed)
        let gaps = await findWorkoutGaps(phenome)

        // 2. Correlate with context signals
        let meetingDensity = await analyzeMeetingDensity(phenome, around: gaps)
        let sleepQuality = await analyzeSleepQuality(phenome, around: gaps)
        let timeOfDay = await analyzeTimePatterns(phenome)

        // 3. Identify dominant failure pattern
        let pattern = detectDominantPattern(
            meetingDensity: meetingDensity,
            sleepQuality: sleepQuality,
            timeOfDay: timeOfDay
        )

        // 4. Generate narrative copy
        return buildNarrative(for: pattern, with: phenome)
    }

    private func buildNarrative(for pattern: FailurePattern, with phenome: Phenome) -> AbsolutionNarrative {
        switch pattern {
        case .backToBackMeetings:
            return AbsolutionNarrative(
                headline: "It wasn't your fault.",
                explanation: "Looking at your calendar, on days you skipped workouts, you averaged \(phenome.avgMeetingHours) hours of back-to-back meetings.",
                pattern: pattern,
                absolution: "Your schedule was designed to make you fail.",
                hope: "I've already found 3 protected windows this week where we can rebuild."
            )
        case .sleepDebt:
            return AbsolutionNarrative(
                headline: "Your body was telling you something.",
                explanation: "On days you skipped training, your sleep averaged \(phenome.avgSleepOnSkipDays) hours.",
                pattern: pattern,
                absolution: "Skipping was actually the right call for recovery.",
                hope: "Let's work with your energy, not against it."
            )
        // ... other patterns
        }
    }
}
```

**UI for Absolution**:

```swift
// AbsolutionView.swift
struct AbsolutionView: View {
    let narrative: AbsolutionNarrative

    var body: some View {
        VStack(spacing: 32) {
            // Dramatic pause, then headline
            Text(narrative.headline)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(narrative.explanation)
                .font(.body)
                .foregroundColor(.secondary)

            // The money line - bigger, emphasized
            Text(narrative.absolution)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Divider()

            Text(narrative.hope)
                .font(.body)
                .foregroundColor(.accentColor)

            Button("Let's Begin") {
                // Transition to main app
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

**Files to Create**:

- `ios/Vigor/Core/Onboarding/AbsolutionEngine.swift`
- `ios/Vigor/Core/Onboarding/FailurePattern.swift`
- `ios/Vigor/Core/Onboarding/AbsolutionNarrative.swift`
- `ios/Vigor/UI/Onboarding/OnboardingView.swift`
- `ios/Vigor/UI/Onboarding/HealthPermissionView.swift`
- `ios/Vigor/UI/Onboarding/CalendarPermissionView.swift`
- `ios/Vigor/UI/Onboarding/ProfileSetupView.swift`
- `ios/Vigor/UI/Onboarding/AbsolutionView.swift`
- `ios/VigorTests/Onboarding/AbsolutionEngineTests.swift`

### Task 6.2: Value Receipt (Weekly Summary)

**Priority**: P1
**Description**: Sunday summary of Ghost's actions, triggered by GhostEngine's Sunday Evening cycle

**Content** (per UX Spec):

- Workouts scheduled/completed
- Time saved from auto-scheduling
- Pattern insights discovered
- Trust phase progress

**Sunday Evening Cycle Integration** (CRITICAL):

The Value Receipt must be triggered by GhostEngine's Sunday Evening cycle, not just a UI timer. This ensures the summary reflects the complete week's data.

```swift
// GhostEngine.swift extension
extension GhostEngine {
    /// Sunday Evening cycle - runs after 6pm on Sundays
    func runSundayEveningCycle() async {
        // 1. Finalize week's metrics
        await MetricRegistry.shared.computeWeeklyAggregates()

        // 2. Generate Value Receipt
        let receipt = await ValueReceiptGenerator.shared.generate(
            weekEnding: Date(),
            fromStore: DerivedStateStore.shared
        )

        // 3. Store receipt for later viewing
        await DerivedStateStore.shared.store(valueReceipt: receipt)

        // 4. Deliver via notification (subtle)
        await NotificationManager.shared.schedule(
            .valueReceipt(receipt),
            deliveryTime: .now
        )

        // 5. Update Weekly Reflection trigger
        await WeeklyReflectionManager.shared.enableReflection(receipt)
    }
}

// ValueReceiptGenerator.swift
actor ValueReceiptGenerator {
    func generate(
        weekEnding: Date,
        fromStore: DerivedStateStore
    ) async -> ValueReceipt {
        let weekStart = weekEnding.startOfWeek

        // Query week's data
        let workoutLogs = await fromStore.query(
            .workoutLogs(range: weekStart...weekEnding)
        )
        let patternInsights = await fromStore.query(
            .patternInsights(range: weekStart...weekEnding)
        )
        let trustProgress = await fromStore.query(
            .trustScoreHistory(range: weekStart...weekEnding)
        )

        // Calculate "time saved" (scheduled - actual decision time)
        let timeSaved = calculateTimeSaved(workoutLogs)

        return ValueReceipt(
            weekEnding: weekEnding,
            workoutsScheduled: workoutLogs.count,
            workoutsCompleted: workoutLogs.filter(\.completed).count,
            minutesSaved: timeSaved,
            insights: patternInsights,
            trustDelta: trustProgress.delta
        )
    }
}
```

**Files to Create**:

- `ios/Vigor/UI/ValueReceipt/ValueReceiptView.swift`
- `ios/Vigor/UI/ValueReceipt/ValueReceiptGenerator.swift`
- `ios/Vigor/UI/ValueReceipt/WeeklyReflectionManager.swift`

### Task 6.3: Today View (Minimal iPhone UI)

**Priority**: P1
**Description**: Single screen for rare app opens

**Content** (per UX Spec):

- Recovery score (prominent)
- Next scheduled block
- Ghost status (current phase)
- "Why?" explanation for recent decisions

**Files to Create**:

- `ios/Vigor/UI/Today/TodayView.swift`
- `ios/Vigor/UI/Today/RecoveryScoreCard.swift`
- `ios/Vigor/UI/Today/NextBlockCard.swift`

### Task 6.4: Settings & Trust Configuration

**Priority**: P1
**Description**: User control over Ghost autonomy

**Settings**:

- Current trust phase (manual advance/retreat)
- Blocker calendar selection
- Sacred time configuration
- Notification preferences
- Data export

**Files to Create**:

- `ios/Vigor/UI/Settings/SettingsView.swift`
- `ios/Vigor/UI/Settings/TrustPhaseControl.swift`
- `ios/Vigor/UI/Settings/CalendarSettingsView.swift`
- `ios/Vigor/UI/Settings/SacredTimeSettingsView.swift`

### Task 6.5: Edge Case Handling

**Priority**: P1
**Description**: Graceful degradation for all edge cases

**Edge Cases to Handle**:

- Apple Watch not paired
- HealthKit permissions denied
- Calendar permissions denied
- Offline mode
- Stale Phenome data
- Ghost Health degradation

**Files to Create**:

- `ios/Vigor/UI/Fallback/NoWatchView.swift`
- `ios/Vigor/UI/Fallback/PermissionDeniedView.swift`
- `ios/Vigor/UI/Fallback/OfflineModeView.swift`
- `ios/Vigor/UI/Fallback/DegradedModeView.swift`

### Task 6.6: Accessibility

**Priority**: P1
**Description**: Full VoiceOver and Dynamic Type support

**Implementation**:

- VoiceOver labels for all interactive elements
- Dynamic Type for all text
- Reduce Motion support
- High contrast mode

### Task 6.7: Unit & Integration Tests

**Priority**: P1
**Description**: Comprehensive test coverage

**Test Categories**:

- Trust State Machine transitions
- Phenome store operations
- Calendar scheduling logic
- Ghost cycle execution
- API client mocking
- HealthKit mocking

**Files to Create**:

- `ios/VigorTests/Trust/TrustStateMachineTests.swift`
- `ios/VigorTests/Phenome/PhenomeCoordinatorTests.swift`
- `ios/VigorTests/Calendar/CalendarSchedulerTests.swift`
- `ios/VigorTests/Ghost/GhostEngineTests.swift`

### Task 6.8: TestFlight Preparation

**Priority**: P0 (Blocker)
**Description**: App Store Connect setup and beta deployment

**Tasks**:

- Configure App Store Connect
- Set up TestFlight groups
- Prepare beta release notes
- Configure crash reporting (AppCenter/Crashlytics)

### Task 6.9: Apology State UI (Trust Recovery)

**Priority**: P1
**Description**: Visual UI state when Ghost degrades or Safety Breaker triggers

**The Problem** (per UX Spec §3.5):

- When Ghost fails (Safety Breaker, Health degradation), generic UI destroys trust
- User needs to see the Ghost acknowledge its mistake
- "Humble" recovery is critical to maintaining relationship

**Apology States**:

| Trigger                    | UI Change                      | Message                                                                             |
| -------------------------- | ------------------------------ | ----------------------------------------------------------------------------------- |
| Safety Breaker (3 deletes) | Dimmed interface, humbled tone | "I've been scheduling at bad times. I'll suggest instead of auto-schedule for now." |
| Ghost Health → degraded    | Warning banner                 | "I'm having trouble running in the background. Things may be delayed."              |
| Ghost Health → suspended   | Full-screen takeover           | "I've paused to avoid causing problems. Tap to check settings."                     |

**Implementation Details**:

```swift
// ApologyStateView.swift
struct ApologyStateView: View {
    let degradation: GhostDegradationInfo

    var body: some View {
        VStack(spacing: 16) {
            // Humbled Ghost icon (dimmed, smaller)
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
                .opacity(0.7)

            Text(degradation.reason)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let action = degradation.recommendedAction {
                Button(action.title) {
                    action.perform()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.95))
    }
}
```

**Files to Create**:

- `ios/Vigor/UI/Fallback/ApologyStateView.swift`
- `ios/Vigor/UI/Fallback/GhostDegradationBanner.swift`
- `ios/Vigor/UI/Fallback/SuspendedStateView.swift`

### Task 6.10: One-Tap Triage UI (Missed Workout)

**Priority**: P1
**Description**: Disambiguation card shown on app open after missed workout

**The Problem** (per UX Spec §3.7, Tech Spec §2.13):

- User missed scheduled workout
- Ghost needs to know: Was the TIME wrong, or did LIFE happen?
- Without this data, Ghost learns wrong patterns

**Implementation Details**:

```swift
// TriageCardView.swift
struct TriageCardView: View {
    let missedBlock: TrainingBlock
    let onResponse: (MissedWorkoutReason) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Missed your \(missedBlock.formattedTime) workout")
                .font(.headline)

            Text("Quick question to help me learn:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // One-tap options (binary per PRD)
            HStack(spacing: 16) {
                TriageButton(
                    title: "Bad time",
                    subtitle: "Schedule differently",
                    icon: "clock.badge.xmark"
                ) {
                    onResponse(.badTimeSlot)
                }

                TriageButton(
                    title: "Just today",
                    subtitle: "Time was fine",
                    icon: "calendar.badge.minus"
                ) {
                    onResponse(.lifeHappened)
                }
            }

            // Dismiss without answering (ambiguous)
            Button("Skip") {
                onResponse(.unknown)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}
```

**Display Rules**:

- Show on first app open after missed block
- Maximum 1 triage request per day
- Auto-dismiss after 24 hours (record as `.unknown`)
- Never interrupt active workout

**Files to Create**:

- `ios/Vigor/UI/Triage/TriageCardView.swift`
- `ios/Vigor/UI/Triage/TriageButton.swift`
- `ios/Vigor/UI/Triage/TriageCoordinator.swift`

### Task 6.11: Value Receipt "Clean Mode" (Social Share)

**Priority**: P2
**Description**: High-contrast, biometric-free shareable image for viral marketing

**The Opportunity** (per UX Spec §2.3.5):

- Users want to share fitness progress on social media
- BUT: Sharing raw health data feels vulnerable/braggy
- Solution: "Clean Mode" - abstracted, beautiful, shareable

**Clean Mode Requirements**:

- **No raw biometrics** (no HRV numbers, sleep hours)
- **High contrast** design (looks good on Instagram stories)
- **Abstract achievements** ("4-week streak" not "burned 3,400 calories")
- **Brand presence** (subtle Vigor watermark for organic growth)

**Implementation Details**:

```swift
// CleanModeRenderer.swift
import SwiftUI

struct CleanModeReceipt: View {
    let receipt: ValueReceipt

    var body: some View {
        VStack(spacing: 24) {
            // Abstract achievement, not raw data
            Text(receipt.abstractAchievement)
                .font(.system(size: 48, weight: .bold, design: .rounded))

            // e.g., "4 weeks consistent" not "12 workouts"
            Text(receipt.streakDescription)
                .font(.title2)
                .foregroundColor(.secondary)

            // Visual representation (circles, not numbers)
            WeekDotsView(completedDays: receipt.completedDays)

            // Subtle branding
            HStack {
                Image("vigor-wordmark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 16)
                    .opacity(0.5)
            }
        }
        .padding(40)
        .background(
            LinearGradient(
                colors: [.black, Color(hex: "1a1a2e")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .foregroundColor(.white)
    }
}

// ShareLink integration
struct ValueReceiptView: View {
    let receipt: ValueReceipt
    @State private var renderedImage: Image?

    var body: some View {
        VStack {
            // Normal detailed view
            DetailedReceiptView(receipt: receipt)

            // Share button
            ShareLink(
                item: renderedImage ?? Image(systemName: "square"),
                preview: SharePreview("My Vigor Week", image: renderedImage ?? Image(systemName: "square"))
            ) {
                Label("Share Clean Mode", systemImage: "square.and.arrow.up")
            }
            .task {
                renderedImage = await renderCleanMode(receipt)
            }
        }
    }

    @MainActor
    func renderCleanMode(_ receipt: ValueReceipt) async -> Image {
        let renderer = ImageRenderer(content: CleanModeReceipt(receipt: receipt))
        renderer.scale = 3.0 // High resolution for social
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "photo")
    }
}
```

**Abstract Achievement Mapping**:

| Raw Data         | Clean Mode Display |
| ---------------- | ------------------ |
| 12 workouts      | "Consistent"       |
| 4-week streak    | "4 weeks strong"   |
| 85% completion   | "On track"         |
| 3 auto-scheduled | "Flowing"          |

**Files to Create**:

- `ios/Vigor/UI/ValueReceipt/CleanModeRenderer.swift`
- `ios/Vigor/UI/ValueReceipt/CleanModeReceipt.swift`
- `ios/Vigor/UI/ValueReceipt/WeekDotsView.swift`
- `ios/Vigor/UI/ValueReceipt/AbstractAchievementMapper.swift`

---

## Admin Dashboard Retention (Frontend)

### Task A.1: Refactor Frontend as Admin-Only

**Priority**: P2
**Description**: Strip user-facing pages, retain admin functionality

**Keep**:

- Admin authentication (Entra ID with admin role check)
- Analytics dashboard
- LLM monitoring and configuration
- User management
- Cost metrics
- Audit logs

**Remove** (archive):

- Landing page (marketing)
- User onboarding
- Workout pages
- Coach chat
- Profile pages

### Task A.2: Add Ghost Monitoring Dashboard

**Priority**: P2
**Description**: Admin visibility into Ghost operations

**Features**:

- User trust phase distribution
- Ghost Health Monitor status across users
- Decision receipt analytics
- Calendar mutation metrics
- Phenome sync status

---

## Dependencies & Prerequisites

### External Dependencies

1. **Apple Developer Account** - iOS/watchOS development
2. **Azure Subscription** - Existing (vigor-rg)
3. **Microsoft Entra ID** - Existing (add iOS redirect URIs)
4. **Apple Watch Hardware** - For testing

### Swift Package Dependencies

```swift
// Package.swift or Xcode SPM
dependencies: [
    .package(url: "https://github.com/AzureAD/microsoft-authentication-library-for-objc", from: "1.0.0"),
    // Add other dependencies as needed
]
```

### Development Environment

- Xcode 15+
- iOS 17+ target
- watchOS 10+ target
- macOS Sonoma+ (for development)

---

## Risk Mitigation

### Risk 1: HealthKit Data Accuracy

**Mitigation**: Implement data validation, fallback to manual input for edge cases

### Risk 2: iOS Background Task Throttling

**Mitigation**: Silent Push + Complication-Driven Wakes (per Tech Spec §2.9)

### Risk 3: Calendar Permission Rejection

**Mitigation**: Graceful degradation to notification-only mode

### Risk 4: Apple Watch Requirement Friction

**Mitigation**: Clear messaging during onboarding, marketing positioning as premium feature

### Risk 5: LLM Latency for Workout Generation

**Mitigation**: Template engine for 90% of requests, streaming for edge cases

---

## Success Metrics

| Metric                   | Target            | Measurement    |
| ------------------------ | ----------------- | -------------- |
| Time to First Magic      | < 5 minutes       | Analytics      |
| App Opens per Week       | < 3               | Analytics      |
| Proactive Sessions       | > 60% of workouts | Phenome data   |
| Zero-Input Workouts      | > 40% auto-logged | Phenome data   |
| 30-Day Retention         | > 50%             | Analytics      |
| Trust Phase 3+ Users     | > 30% at 30 days  | Trust State    |
| Ghost Health Degradation | < 5% of users     | Health Monitor |

---

## Timeline Summary

| Phase     | Duration     | Key Deliverable                                                                                                        |
| --------- | ------------ | ---------------------------------------------------------------------------------------------------------------------- |
| Phase 0   | 1 week       | Repository restructure, iOS project setup                                                                              |
| Phase 1   | 3.5 weeks    | iOS app with HealthKit, EventKit, **Metric Provenance Engine**, Authority Resolution, Silent Push                      |
| Phase 2   | 5 weeks      | Ghost Engine, Trust Machine, **Health Profile Machine**, Safety Breaker, Failure Triage, Core ML, **Recovery Content** |
| Phase 3   | 2.5 weeks    | watchOS app with complications, **Haptic Engine (P0)**, **Staleness Visualizers**                                      |
| Phase 4   | 2.5 weeks    | Backend modernization, **Wake Infrastructure (P0)**, Push Registration                                                 |
| Phase 5   | 2.5 weeks    | Calendar blocks, notifications, **Shadow Sync (P1)**, **Why? UI**                                                      |
| Phase 6   | 3 weeks      | **Absolution Engine**, **Apology UI**, **Triage UI**, **Clean Mode Share**, TestFlight                                 |
| **Total** | **20 weeks** | Production-ready Vigor iOS app with Platform Survival + Soul + Brain                                                   |

---

## Notes for Implementation

1. **Start with Phase 0 immediately** - Archive and restructure before any development
2. **Phase 1-2 can partially parallel Phase 4** - Backend work is independent
3. **Phase 3 depends on Phase 1-2** - Watch needs iPhone Ghost Engine
4. **Phase 5-6 are sequential** - UX depends on all underlying systems
5. **Maintain the web admin dashboard** - Critical for operations visibility
6. **Test on real Apple Watch hardware** - Simulator insufficient for sensor testing
7. **Weekly spec alignment reviews** - Ensure implementation matches PRD/Tech Spec vision

### ⚠️ Critical Path Items (Do Not Defer)

The following items are **load-bearing infrastructure**. Deferring them will result in a beautiful app that dies in the background or makes unintelligent decisions:

**Platform Survival (Body)**:

| Item                      | Task     | Why Critical                                                |
| ------------------------- | -------- | ----------------------------------------------------------- |
| **Wake Infrastructure**   | 4.6, 4.7 | Without Silent Push, Ghost stops after 3 days of non-use    |
| **Silent Push Handler**   | 1.8      | iOS side of wake mechanism                                  |
| **Calendar Multiplexing** | 1.4      | Without reading Exchange, corporate users get double-booked |
| **Authority Resolution**  | 1.7      | Without it, Watch/Phone data conflicts corrupt Phenome      |

**Intelligence Foundation (Brain)**:

| Item                       | Task | Why Critical                                                      |
| -------------------------- | ---- | ----------------------------------------------------------------- |
| **Metric Provenance**      | 1.5  | Without it, algorithm updates require data migration nightmares   |
| **Health Profile Machine** | 2.1b | Without it, Ghost doesn't know if learning baseline or regressing |
| **Safety Breaker**         | 2.1  | Without it, trust erosion spiral leads to app deletion            |
| **Failure Triage**         | 2.6  | Without it, Ghost learns wrong patterns from ambiguous signals    |

**User Experience (Soul)**:

| Item              | Task | Why Critical                                                  |
| ----------------- | ---- | ------------------------------------------------------------- |
| **Haptic Engine** | 3.6  | Without tuned haptics, Watch feels like generic notifications |
| **Shadow Sync**   | 5.4  | Without it, high-performers (target market) can't use product |
| **Why? UI**       | 5.6  | Without explainability, users don't trust autonomous actions  |

**Validation Gate**: Before declaring Phase 4 complete, verify:

- [ ] Timer Function runs at 5:55 AM in staging
- [ ] Silent Push wakes test device that hasn't been opened in 4 days
- [ ] Morning Cycle executes successfully on wake

---

_This document serves as the authoritative implementation plan for Vigor v1.3. All development work should reference this document and the aligned specifications (PRD v5.0, Tech Spec v2.6, UX Spec v1.3)._

---

## Appendix: Architectural Review Integration

This plan incorporates feedback from four comprehensive architectural reviews:

### Review 1: Platform Survival (Infrastructure)

1. **Invisibility Paradox** - iOS background task throttling → Silent Push wake mechanism (Tasks 1.8, 4.6, 4.7)
2. **Corporate Resilience** - MDM blocks, calendar visibility → Calendar Multiplexing (Task 1.4), Shadow Sync (Task 5.4)
3. **Device Authority Conflicts** - Watch/Phone data races → Single-Writer Principle (Task 1.7)
4. **Trust Erosion Spiral** - Ambiguous feedback → Safety Breaker (Task 2.1), Failure Triage (Task 2.6)
5. **Recovery UI States** - Silent failures → Apology State (Task 6.9), Triage UI (Task 6.10)

### Review 2: Product Soul (Experience)

6. **Emergency Protocol** - "I'm crashing" Siri integration → The Red Button (Task 2.7)
7. **Haptic Vocabulary** - Watch as intimate channel → VigorHaptics (Task 3.6, elevated to P0)
8. **Staleness Honesty** - Trust through transparency → Visual degradation modifiers (Task 3.7)
9. **Absolution Moment** - Day 1 emotional connection → Absolution Engine (Task 6.1)
10. **Viral Marketing Loop** - Social sharing → Clean Mode receipts (Task 6.11)

### Review 3: Health Intelligence (Brain)

11. **Metric Provenance** - Versioned recomputation engine → MetricRegistry (Task 1.5 expanded)
12. **Health Profile Machine** - Physiological understanding state → Baseline→Maintenance→Regression (Task 2.1b)
13. **Recovery Content** - Emergency Protocol content delivery → NSDR/Breathing assets (Task 2.8)
14. **Explainability UI** - User-facing "Why?" transparency → DecisionReceipt visualization (Task 5.6)

### Review 4: Operational Resilience (Gaps & Testing)

15. **Shadow Sync Timing** - Phase 5 was too late; colleagues double-book → Moved to Phase 1 (Task 1.4b)
16. **Travel/Context Detection** - "Smart Illusion" for location-aware silence → ContextEngine (Task 2.9)
17. **Admin Dashboard Wiring** - React admin retained but not connected → Backend integration (Task 4.8)
18. **Trust Simulation** - 60-day Trust Ladder untestable manually → GhostSimulator (Task 2.10)
19. **Value Receipt Trigger** - Must be tied to GhostEngine Sunday cycle → Explicit hookup (Task 6.2 refined)

---

### Architecture Philosophy

> **"Build the Body (infrastructure), the Brain (intelligence), AND the Soul (experience)."**

| Layer     | What It Does                                                    | Without It               |
| --------- | --------------------------------------------------------------- | ------------------------ |
| **Body**  | Survives iOS throttling, corporate MDM, device conflicts        | App dies in background   |
| **Brain** | Learns user patterns, adapts algorithms, explains decisions     | App feels dumb/arbitrary |
| **Soul**  | Creates emotional connection, recovers from failures gracefully | App feels like a utility |

Vigor must be **all three**: invisible infrastructure that survives iOS, intelligent systems that learn and explain, wrapped in moments that feel like a premium concierge.

---

### Coverage Summary

| Spec Area                     | Coverage | Status                                        |
| ----------------------------- | -------- | --------------------------------------------- |
| **Infrastructure / Survival** | 100%     | 🟢 Excellent                                  |
| **UX / Soul**                 | 100%     | 🟢 Excellent                                  |
| **Trust / Autonomy**          | 100%     | 🟢 Excellent                                  |
| **Data Science / Metrics**    | 100%     | 🟢 Excellent                                  |
| **Hardware / Sensors**        | 100%     | 🟢 Excellent                                  |
| **Operational / Testing**     | 100%     | 🟢 Excellent (added Simulation, Admin Wiring) |

---

## Phase 7: Production Hardening & Integration Wiring

**Date**: February 7, 2026
**Status**: 🔴 Active
**Goal**: Transform scaffolded prototype into production-reliable system by fixing security vulnerabilities, wiring disconnected subsystems, and eliminating dead code.

> **"Scaffolding is not architecture. The gap between compiles and works is where trust dies."**

### Assessment Summary

A comprehensive architecture review on February 7, 2026 revealed that while Phases 0-6 built the correct skeleton across all three surfaces (iOS, Azure Functions backend, React admin dashboard), critical connective tissue is missing. The codebase has:

- 🔴 **Security vulnerabilities**: JWT secret committed to git, no input validation, JWKS fetched on every request
- 🔴 **Build-breaking bugs**: Frontend missing imports, undefined constants, unauthenticated API calls
- 🔴 **Disconnected subsystems**: APNs client never called, Ghost Cosmos containers never initialized, ML stores return empty data
- 🟡 **Dead code accumulation**: ~2,000 lines of unused code across frontend, duplicate types across iOS
- ✅ **Zero backend test coverage**: Test suite created — 22 tests passing (test_helpers.py + test_auth.py)

### Phase 7 Progress

| Sub-Phase     | Description                          | Status      | Progress |
| ------------- | ------------------------------------ | ----------- | -------- |
| **Phase 7.0** | Critical Security & Build Fixes      | ✅ Complete | 100%     |
| **Phase 7.1** | Backend Reliability & Decomposition  | ✅ Complete | 100%     |
| **Phase 7.2** | Frontend Cleanup & Production Safety | ✅ Complete | 100%     |

---

### Phase 7.0: Critical Security & Build Fixes

**Priority**: P0 — Must complete before any deployment
**Scope**: Security vulnerabilities + build-breaking bugs that prevent the system from functioning

#### Task 7.0.1: Rotate Committed JWT Secret ✅ SECURITY

**File**: `infrastructure/bicep/parameters-modernized.bicepparam`
**Issue**: `param secretKey = 'vigor-jwt-secret-key-prod-2026'` is committed to git in plaintext
**Fix**:

- [x] Replace hardcoded secret with a placeholder referencing Key Vault
- [x] Add `.bicepparam` to `.gitignore` (`.bicepparam.example` stays tracked)
- [x] Document: "After deploy, rotate secret via Azure Portal > Function App > Configuration"

#### Task 7.0.2: Remove Default Admin Password ✅

**File**: `functions-modernized/shared/config.py`
**Issue**: `ADMIN_PASSWORD` defaults to `"ChangeMe123!"`
**Fix**:

- [x] Remove the `ADMIN_PASSWORD` field entirely (auth is Entra ID, not passwords)
- [x] Remove any references to `ADMIN_PASSWORD` across the codebase

#### Task 7.0.3: Fix Bicep RBAC Role Assignment ✅

**File**: `infrastructure/bicep/main-modernized.bicep`
**Issue**: Role `b24988ac-6180-42a0-ab88-20f7382dd24c` is **Contributor** (full resource management), not Cosmos DB Data Contributor
**Fix**:

- [x] Change to `00000000-0000-0000-0000-000000000002` (Cosmos DB Built-in Data Contributor) scoped at Cosmos account level

#### Task 7.0.4: Fix Bicep Environment Parameter Mismatch ✅

**File**: `infrastructure/bicep/main-modernized.bicep`
**Issue**: `param environment` defaults to `'prod'` but retention conditional checks `environment == 'production'` — never matches
**Fix**:

- [x] Change conditional to `environment == 'prod'` to match the default parameter value

#### Task 7.0.5: Add Missing Ghost Cosmos DB Containers to Bicep ✅

**File**: `infrastructure/bicep/main-modernized.bicep`
**Issue**: Backend code references 6 containers that don't exist in infrastructure: `ghost_actions`, `trust_states`, `training_blocks`, `phenome`, `decision_receipts`, `push_queue`
**Fix**:

- [x] Add all 6 container resources with `/userId` partition key and appropriate TTLs
- [x] `decision_receipts`: 90-day TTL (7776000 seconds) per Tech Spec §2.4
- [x] `push_queue`: 7-day TTL (604800 seconds) for transient push queue items

#### Task 7.0.6: Make CORS Environment-Conditional ✅

**File**: `infrastructure/bicep/function-app-modernized.bicep`
**Issue**: `localhost:5173` and `localhost:3000` are in production CORS — attack surface
**Fix**:

- [x] Add `environment` parameter to function-app module
- [x] Only include localhost origins when `environment != 'prod'`

#### Task 7.0.7: Fix Frontend — Missing AdminProtectedRoute Import ✅

**File**: `frontend/src/App.tsx`
**Issue**: `AdminProtectedRoute` is used on lines 58/69 but never imported — build fails
**Fix**:

- [x] Add `import { AdminProtectedRoute } from './components/AdminProtectedRoute'`

#### Task 7.0.8: Fix Frontend — TierManagementPage Undefined Constants ✅

**File**: `frontend/src/pages/TierManagementPage.tsx`
**Issue**: References `TIER_PRICING.PREMIUM_MONTHLY` and `TIER_PRICING.PREMIUM_YEARLY` which don't exist on the exported `TIER_PRICING` object (actual keys are `free`, `premium`, `enterprise`)
**Fix**:

- [x] Import `TIER_PRICING` from `adminConfig`
- [x] Use `TIER_PRICING.premium.price` (49) and `TIER_PRICING.premium.yearlyPrice` (499)

#### Task 7.0.9: Wire Admin API Token ✅

**File**: `frontend/src/contexts/AuthContext.tsx`, `frontend/src/services/adminApi.ts`
**Issue**: `setAdminAccessToken()` is never called — all admin API requests go unauthenticated
**Fix**:

- [x] In `AuthContext.tsx`, import and call `setAdminAccessToken(response.accessToken)` alongside `api.setAccessToken()`

#### Task 7.0.10: Cache JWKS Keys with TTL ✅

**File**: `functions-modernized/shared/auth.py`
**Issue**: JWKS keys fetched from `login.microsoftonline.com` on every authenticated request — 50-200ms latency penalty per call
**Fix**:

- [x] Add module-level `_jwks_cache` with `_jwks_cache_expiry` (24-hour TTL)
- [x] Return cached keys if not expired; fetch and update cache only on miss/expiry
- [x] Force refresh on key-not-found to handle key rotation

#### Task 7.0.11: Validate JWT Issuer Claim ✅

**File**: `functions-modernized/shared/auth.py`
**Issue**: `iss` (issuer) claim is not validated — a token from any Azure tenant with matching `aud` passes
**Fix**:

- [x] Add `issuer` parameter to `jwt.decode()` matching expected tenant
- [x] Support both v1 and v2 issuer formats
- [x] Handle `common` tenant gracefully (skip issuer validation)

#### Task 7.0.12: Fix `get_cosmos_container` Sync-in-Async ✅

**File**: `functions-modernized/shared/cosmos_db.py`
**Issue**: Creates synchronous `CosmosClient` inside running async event loop — blocks entire process
**Fix**:

- [x] Refactor `ensure_user_exists` in `auth.py` to be fully async using the async `CosmosDBClient`
- [x] Remove `get_cosmos_container` sync fallback entirely (no remaining callers)

---

### Phase 7.1: Backend Reliability & Decomposition

**Priority**: P1 — Required for production reliability

#### Task 7.1.1: Initialize Ghost Cosmos Containers in Python ✅

**File**: `functions-modernized/shared/cosmos_db.py`
**Issue**: Only 4 containers initialized (`users`, `workouts`, `workout_logs`, `ai_coach_messages`), but Ghost code references 6 more
**Fix**:

- [x] Add `ghost_actions`, `trust_states`, `training_blocks`, `phenome`, `decision_receipts`, `push_queue` to `self.containers` dict in `initialize()`

#### Task 7.1.2: Add Pydantic Input Validation to Endpoints ✅

**File**: `functions-modernized/shared/helpers.py` (new)
**Issue**: Every endpoint does `req.get_json()` with no schema validation — existing Pydantic models (`WorkoutGenerationRequest`, `CoachChatRequest`, `WorkoutSessionRequest`) are never used
**Fix**:

- [x] Create helper `parse_request_body(req, model_class)` that parses JSON and validates against Pydantic model
- [x] Returns (model, None) on success, (None, error_response) on failure
- [x] Applied in blueprint endpoints for POST/PUT handlers

#### Task 7.1.3: Add Structured Error Responses ✅

**File**: `functions-modernized/shared/helpers.py` (new)
**Issue**: All exceptions return generic 500 — no differentiation between 400/404/409/500
**Fix**:

- [x] Create `error_response(message, status_code, code=None, details=None)` helper
- [x] Create `success_response(data, status_code=200)` helper
- [x] Applied across all Blueprint endpoints with proper HTTP status codes (400, 401, 403, 404, 405, 422, 429, 500)

#### Task 7.1.4: Add Query Parameter Bounds Validation ✅

**File**: `functions-modernized/shared/helpers.py` (new)
**Issue**: `limit` and `offset` query params accept arbitrary integers — DoS vector via `limit=999999`
**Fix**:

- [x] Create `parse_pagination(req, max_limit=100)` helper
- [x] Clamp `limit` to `[1, max_limit]`, `offset` to `[0, ∞)`
- [x] Applied to all paginated endpoints in blueprints

#### Task 7.1.5: Decompose function_app.py into Blueprints ✅

**File**: `functions-modernized/function_app.py` (1,275 lines → 55 lines + 6 blueprint files)
**Issue**: All 23+ endpoints in a single file — unmaintainable
**Fix**:

- [x] Create `blueprints/` directory with: `auth_bp.py`, `workouts_bp.py`, `coach_bp.py`, `ghost_bp.py`, `admin_bp.py`, `health_bp.py`
- [x] Move endpoints into appropriate blueprints using `func.Blueprint()`
- [x] Register all blueprints in `function_app.py` (now 55 lines)
- [x] Created `shared/helpers.py` for common patterns (error_response, success_response, parse_request_body, parse_pagination)

#### Task 7.1.6: Create Backend Test Suite ✅

**File**: `functions-modernized/tests/` (new directory)
**Issue**: Current `test_simple.py` has 0 real tests — 0% coverage
**Fix**:

- [x] Create `tests/conftest.py` with fixtures for mock Cosmos, mock auth, HTTP request factory
- [x] Create `tests/test_auth.py` — JWKS caching tests with mock network (3 tests)
- [x] Create `tests/test_helpers.py` — error_response, success_response, parse_request_body, parse_pagination (19 tests)
- [x] All 22 tests pass (`pytest -v`)

---

### Phase 7.2: Frontend Cleanup & Production Safety

**Priority**: P1 — Required for reliable admin operations

#### Task 7.2.1: Remove Silent Mock Data Fallback in Production ✅

**File**: `frontend/src/services/adminApi.ts`
**Issue**: API failures silently return mock data — admin sees fake health metrics with no warning
**Fix**:

- [x] Guard all 7 mock fallbacks behind `import.meta.env.DEV` check
- [x] In production, re-throw the error so the component shows error state

#### Task 7.2.2: Remove Dead LLM Orchestration Route ✅

**Files**: `frontend/src/App.tsx`, `frontend/src/pages/LLMOrchestrationPage.tsx`
**Issue**: Two LLM config pages exist — `LLMConfigurationSimple` (correct, Ghost-aligned) and `LLMOrchestrationPage` (older, exposes unsupported temperature/topP controls)
**Fix**:

- [x] Remove `/llm` route from `App.tsx`
- [x] Remove `LLMOrchestrationPage` import
- [x] Delete `LLMOrchestrationPage.tsx` file
- [x] Verified sidebar nav in `Layout.tsx` does not link to `/llm`

#### Task 7.2.3: Add Route-Based Code Splitting ✅

**File**: `frontend/src/App.tsx`
**Issue**: All 9 admin page components eagerly imported — entire bundle loaded regardless of route
**Fix**:

- [x] Convert 10 page imports to `React.lazy()` with `<Suspense fallback={<Spinner />}>`
- [x] Keep `Layout`, `ErrorBoundary`, `AuthProvider`, `AdminProtectedRoute` eager (always needed)

#### Task 7.2.4: Remove Dead Frontend Code ✅

**Files**: Multiple
**Issue**: ~2,000 lines of unused code across the frontend
**Fix**:

- [x] Delete `frontend/src/store/chatStore.ts` (Zustand store, never imported)
- [x] Delete `frontend/src/pages/ForgotPasswordPage.tsx` (Entra ID handles passwords)
- [x] Delete `frontend/src/pages/ResetPasswordPage.tsx` (Entra ID handles passwords)
- [x] Remove corresponding routes from `App.tsx` (`/forgot-password`, `/reset-password`)
- [x] Delete `frontend/src/__tests__/components/ForgotPasswordPage.test.tsx`

#### Task 7.2.5: Fix Frontend TypeScript Configuration ✅

**File**: `frontend/tsconfig.app.json`
**Issue**: `strict: false` allows type errors to accumulate silently
**Fix**:

- [x] Set `"strict": true`
- [x] Set `"noUnusedLocals": true`
- [x] Set `"noUnusedParameters": true`
- [x] Fixed 72 type errors across 5 files (type definitions, Chakra v3 API, missing imports)
- [x] `npm run build` succeeds with zero errors

---

### Phase 7 Validation Gates

**Before declaring Phase 7.0 complete:** ✅ ALL PASSED

- [x] `parameters-modernized.bicepparam` has no hardcoded secrets
- [x] `config.py` has no default passwords
- [x] Bicep deploys successfully with correct RBAC role
- [x] Frontend builds without errors (`npm run build`) — imports/constants fixed
- [x] Admin API calls include auth token — wired in AuthContext
- [x] JWKS keys are cached (verified via `_jwks_cache` module-level variable)

**Before declaring Phase 7.1 complete:** ✅ ALL PASSED

- [x] All Ghost containers initialized in Python code
- [x] Invalid request bodies return 400 with details (parse_request_body helper)
- [x] Backend tests pass (`pytest -v`) — 22/22 pass, covering auth + helpers
- [x] `function_app.py` is <100 lines (imports + blueprint registration) — now 55 lines

**Before declaring Phase 7.2 complete:** ✅ ALL PASSED

- [x] Production build shows no mock data without explicit dev flag
- [x] Bundle size reduced — code-split into 13 chunks via React.lazy()
- [x] `npm run build` succeeds with `strict: true` — zero TS errors
- [x] No dead routes in App.tsx — removed /llm, /forgot-password, /reset-password
- [x] 4 dead files deleted (ForgotPasswordPage, ResetPasswordPage, LLMOrchestrationPage, chatStore)
