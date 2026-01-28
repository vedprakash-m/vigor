# 👻 The Ghost - iOS App

> Native iOS/watchOS implementation of The Ghost invisible fitness system.

## 📱 Requirements

- **Xcode**: 15.2+
- **iOS**: 17.0+
- **watchOS**: 10.0+
- **Apple Developer Account**: Required for HealthKit, Push, CloudKit
- **Physical Devices**: Simulator lacks HealthKit/Watch connectivity

## 🏗️ Architecture

### Core Components

```
ios/
├── Vigor/                    # iPhone App
│   ├── App/
│   │   ├── VigorApp.swift    # @main entry point
│   │   ├── AppDelegate.swift # Push, BGTaskScheduler
│   │   └── ContentView.swift # Root view with auth state
│   │
│   ├── Core/
│   │   ├── GhostEngine/      # Central orchestration
│   │   │   ├── GhostEngine.swift
│   │   │   ├── GhostHealthMonitor.swift
│   │   │   ├── DecisionReceiptStore.swift
│   │   │   └── FailureDisambiguator.swift
│   │   │
│   │   ├── Trust/            # 5-phase state machine
│   │   │   ├── TrustStateMachine.swift
│   │   │   ├── TrustPhase.swift
│   │   │   ├── TrustEvent.swift
│   │   │   └── TrustAttributionEngine.swift
│   │   │
│   │   ├── Phenome/          # 3-store data architecture
│   │   │   ├── PhenomeCoordinator.swift
│   │   │   ├── MetricRegistry.swift
│   │   │   ├── RawSignalStore.swift
│   │   │   ├── DerivedStateStore.swift
│   │   │   └── BehavioralMemoryStore.swift
│   │   │
│   │   ├── ML/               # Intelligence layer
│   │   │   ├── SkipPredictor.swift
│   │   │   ├── RecoveryAnalyzer.swift
│   │   │   ├── OptimalWindowFinder.swift
│   │   │   └── PatternDetector.swift
│   │   │
│   │   └── Auth/
│   │       ├── AuthManager.swift
│   │       └── MSALConfiguration.swift
│   │
│   ├── Data/
│   │   ├── HealthKit/
│   │   │   ├── HealthKitObserver.swift
│   │   │   └── HealthKitTypes.swift
│   │   ├── Calendar/
│   │   │   ├── CalendarScheduler.swift
│   │   │   └── CalendarShadowSync.swift
│   │   └── API/
│   │       ├── VigorAPIClient.swift
│   │       └── APIModels.swift
│   │
│   ├── Background/
│   │   └── SilentPushReceiver.swift  # P0 for Ghost survival
│   │
│   ├── Notifications/
│   │   └── NotificationOrchestrator.swift
│   │
│   └── UI/
│       ├── Onboarding/
│       │   └── OnboardingFlow.swift
│       ├── Home/
│       │   └── HomeView.swift
│       └── Components/
│           └── TriageCard.swift
│
├── VigorWatch/               # Apple Watch App
│   ├── App/
│   │   └── VigorWatchApp.swift
│   ├── Views/
│   │   ├── TodayView.swift
│   │   └── ActiveWorkoutView.swift
│   ├── Workout/
│   │   └── WatchWorkoutManager.swift
│   ├── Sync/
│   │   └── WatchSyncManager.swift
│   └── Complications/
│       └── ComplicationController.swift
│
├── Shared/                   # Shared Code
│   ├── Models/
│   ├── WatchConnectivity/
│   │   └── WatchConnectivityManager.swift
│   └── Sync/
│       └── AuthorityConflictResolver.swift
│
└── VigorTests/
    └── Trust/
        ├── TrustStateMachineTests.swift
        ├── SafetyBreakerTests.swift
        └── TrustAttributionTests.swift
```

## 🚀 Getting Started

### 1. Clone and Open

```bash
cd vigor/ios
open Vigor.xcodeproj
```

### 2. Configure Signing

1. Select the **Vigor** target
2. Go to **Signing & Capabilities**
3. Select your **Team**
4. Ensure unique **Bundle Identifier**

Repeat for **VigorWatch** and **VigorWatch Extension** targets.

### 3. Configure Capabilities

Enable these capabilities for the **Vigor** target:

- ✅ HealthKit (Clinical Health Records not needed)
- ✅ Push Notifications
- ✅ Background Modes:
  - Background fetch
  - Remote notifications
  - Background processing
- ✅ iCloud (CloudKit)
- ✅ App Groups (for Watch connectivity)

For **VigorWatch**:

- ✅ HealthKit
- ✅ Background Modes (Workout processing)

### 4. Configure MSAL

Edit `MSALConfiguration.swift` with your Azure AD app registration:

```swift
static let clientId = "your-client-id"
static let redirectUri = "msauth.com.vigor.app://auth"
```

### 5. Build and Run

1. Connect physical iPhone + Apple Watch
2. Select **Vigor** scheme
3. **Cmd+R** to build and run

## 🧪 Testing

### Unit Tests

```bash
# From Xcode: Cmd+U
# Or from command line:
xcodebuild test -scheme Vigor -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Trust State Machine Tests

The Trust tests verify the 5-phase state machine and Safety Breaker:

```swift
// ios/VigorTests/Trust/
- TrustStateMachineTests.swift   // Phase transitions
- SafetyBreakerTests.swift       // 3-delete trigger
- TrustAttributionTests.swift    // Weighted deltas
```

### Device Testing

Full integration requires physical devices:

- HealthKit data requires real health sources
- Watch connectivity requires paired devices
- Background tasks require real-world timing

## 🔑 Key Patterns

### Actor Pattern

All stores use Swift actors for thread safety:

```swift
actor TrustStateMachine {
    private var currentPhase: TrustPhase = .observer
    private var confidence: Double = 0.0
}
```

### Authority Model

Watch and Phone have clear authority boundaries:

| Domain                 | Authority |
| ---------------------- | --------- |
| Workout execution      | Watch     |
| Workout detection      | Watch     |
| Heart rate (real-time) | Watch     |
| Scheduling decisions   | Phone     |
| Calendar management    | Phone     |
| Trust calculations     | Phone     |

### Calendar Multiplexing

Per PRD safety requirements:

- **Read**: ALL calendars (for conflict detection)
- **Write**: ONLY local "Vigor Training" calendar

### Background Survival (P0)

Three mechanisms keep Ghost alive:

1. **BGTaskScheduler**: App Refresh + Processing tasks
2. **Silent Push (APNs)**: Server-triggered wake
3. **Complications**: Watch face triggers iPhone wake

## 📦 Dependencies

### Swift Packages

```swift
// Package.swift dependencies (when Xcode project created)
dependencies: [
    .package(url: "https://github.com/AzureAD/microsoft-authentication-library-for-objc", from: "1.3.0"),
]
```

### System Frameworks

- HealthKit
- EventKit
- CloudKit
- UserNotifications
- BackgroundTasks
- WatchConnectivity

## 🔧 Configuration

### Environment Variables

Create `Config.xcconfig` for environment-specific settings:

```
// Development
API_BASE_URL = http://localhost:7071
PUSH_ENVIRONMENT = development

// Production
API_BASE_URL = https://vigor-functions.azurewebsites.net
PUSH_ENVIRONMENT = production
```

### Info.plist Keys

Required usage descriptions:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Vigor needs access to your health data to personalize your training schedule and track recovery.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Vigor saves your workout data to Apple Health.</string>

<key>NSCalendarsUsageDescription</key>
<string>Vigor reads your calendar to find optimal workout times and avoid conflicts.</string>

<key>NSCalendarsWriteOnlyAccessUsageDescription</key>
<string>Vigor creates training blocks in your calendar.</string>
```

## 🚢 Deployment

### TestFlight

1. **Archive**: Product → Archive
2. **Distribute**: Organizer → Distribute App → TestFlight
3. **Upload** to App Store Connect

### App Store

1. Complete **App Store Connect** listing
2. Submit for **Review**
3. Monitor for **HealthKit** and **Background** scrutiny

### Checklist

- [ ] All capabilities configured in portal
- [ ] Privacy manifest complete
- [ ] App Privacy responses filled
- [ ] HealthKit Clinical Records disabled (unless needed)
- [ ] Background task identifiers registered

## 🐛 Troubleshooting

### HealthKit Not Available

- Ensure running on physical device
- Check HealthKit capability is enabled
- Verify authorization status

### Watch Not Syncing

- Check both devices on same iCloud account
- Verify Watch app installed
- Check WCSession activation state

### Background Tasks Not Running

- BGTaskScheduler requires real-world timing
- Cannot be tested in Simulator
- Check task identifiers in Info.plist

### Silent Push Not Waking

- Verify push entitlement in provisioning profile
- Check APNs configuration in Azure
- Monitor with Console.app on device

---

**👻 The Ghost: Built for the edge, designed for invisibility.**
