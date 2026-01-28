//
//  InfoPlist.swift
//  Vigor
//
//  Info.plist keys and usage descriptions for The Ghost.
//  This file documents the required Info.plist entries.
//

/*
 ============================================================
 REQUIRED INFO.PLIST ENTRIES FOR THE GHOST
 ============================================================

 Add these to your Info.plist file:

 <!-- HealthKit Usage Description -->
 <key>NSHealthShareUsageDescription</key>
 <string>The Ghost reads your health data to understand your recovery status and optimize workout scheduling. Better recovery data means smarter scheduling that adapts to how you're feeling.</string>

 <key>NSHealthUpdateUsageDescription</key>
 <string>The Ghost records your workouts to track your training history and improve future scheduling recommendations.</string>

 <!-- Calendar Usage Description -->
 <key>NSCalendarsUsageDescription</key>
 <string>The Ghost reads your calendars to find the best workout times that don't conflict with your existing commitments. It only writes to its own "Vigor Training" calendar.</string>

 <!-- Calendar Write-Only for Full Disk Access -->
 <key>NSCalendarsFullAccessUsageDescription</key>
 <string>The Ghost needs calendar access to schedule training blocks and detect conflicts with your existing events. It reads all calendars but only writes to its own "Vigor Training" calendar.</string>

 <!-- Background Modes -->
 <key>UIBackgroundModes</key>
 <array>
     <string>fetch</string>
     <string>processing</string>
     <string>remote-notification</string>
 </array>

 <!-- Background Task Identifiers -->
 <key>BGTaskSchedulerPermittedIdentifiers</key>
 <array>
     <string>com.vigor.ghost.morning-wake</string>
     <string>com.vigor.ghost.evening-cycle</string>
     <string>com.vigor.ghost.phenome-sync</string>
     <string>com.vigor.ghost.calendar-scan</string>
 </array>

 <!-- Push Notification Entitlement -->
 <key>aps-environment</key>
 <string>development</string>  <!-- Change to "production" for App Store -->

 <!-- Required Device Capabilities -->
 <key>UIRequiredDeviceCapabilities</key>
 <array>
     <string>arm64</string>
     <string>healthkit</string>
 </array>

 <!-- App Transport Security (for Azure Functions) -->
 <key>NSAppTransportSecurity</key>
 <dict>
     <key>NSAllowsArbitraryLoads</key>
     <false/>
 </dict>

 <!-- Supported Interface Orientations -->
 <key>UISupportedInterfaceOrientations</key>
 <array>
     <string>UIInterfaceOrientationPortrait</string>
     <string>UIInterfaceOrientationPortraitUpsideDown</string>
 </array>

 <key>UISupportedInterfaceOrientations~ipad</key>
 <array>
     <string>UIInterfaceOrientationPortrait</string>
     <string>UIInterfaceOrientationPortraitUpsideDown</string>
     <string>UIInterfaceOrientationLandscapeLeft</string>
     <string>UIInterfaceOrientationLandscapeRight</string>
 </array>

 <!-- Watch Companion App -->
 <key>WKCompanionAppBundleIdentifier</key>
 <string>com.vigor.app</string>

 <!-- Privacy Manifest -->
 <key>NSPrivacyManifestPath</key>
 <string>PrivacyInfo.xcprivacy</string>

 <!-- App Category -->
 <key>LSApplicationCategoryType</key>
 <string>public.app-category.healthcare-fitness</string>

 ============================================================
 ENTITLEMENTS (Vigor.entitlements)
 ============================================================

 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
     <!-- HealthKit -->
     <key>com.apple.developer.healthkit</key>
     <true/>
     <key>com.apple.developer.healthkit.access</key>
     <array>
         <string>health-records</string>
     </array>
     <key>com.apple.developer.healthkit.background-delivery</key>
     <true/>

     <!-- iCloud / CloudKit -->
     <key>com.apple.developer.icloud-container-identifiers</key>
     <array>
         <string>iCloud.com.vigor.phenome</string>
     </array>
     <key>com.apple.developer.icloud-services</key>
     <array>
         <string>CloudKit</string>
     </array>
     <key>com.apple.developer.ubiquity-kvstore-identifier</key>
     <string>$(TeamIdentifierPrefix)com.vigor.app</string>

     <!-- Push Notifications -->
     <key>aps-environment</key>
     <string>development</string>

     <!-- App Groups (for Watch communication) -->
     <key>com.apple.security.application-groups</key>
     <array>
         <string>group.com.vigor.shared</string>
     </array>

     <!-- Keychain Sharing -->
     <key>keychain-access-groups</key>
     <array>
         <string>$(AppIdentifierPrefix)com.vigor.shared</string>
     </array>

     <!-- Siri (future) -->
     <key>com.apple.developer.siri</key>
     <true/>
 </dict>
 </plist>

 ============================================================
 WATCH EXTENSION INFO.PLIST ADDITIONS
 ============================================================

 <!-- HealthKit on Watch -->
 <key>NSHealthShareUsageDescription</key>
 <string>The Ghost Watch app records your workouts and heart rate to sync with your iPhone for better scheduling.</string>

 <key>NSHealthUpdateUsageDescription</key>
 <string>The Ghost records workouts completed on your Apple Watch.</string>

 <!-- Watch Complications -->
 <key>CLKComplicationPrincipalClass</key>
 <string>$(PRODUCT_MODULE_NAME).ComplicationController</string>

 <key>CLKComplicationSupportedFamilies</key>
 <array>
     <string>CLKComplicationFamilyCircularSmall</string>
     <string>CLKComplicationFamilyGraphicCircular</string>
     <string>CLKComplicationFamilyGraphicCorner</string>
     <string>CLKComplicationFamilyGraphicRectangular</string>
     <string>CLKComplicationFamilyModularSmall</string>
 </array>

 */

// MARK: - Usage Description Constants

/// Centralized usage description strings for consistency
enum UsageDescriptions {

    static let healthKitRead = """
    The Ghost reads your health data to understand your recovery status and optimize workout scheduling. \
    Better recovery data means smarter scheduling that adapts to how you're feeling.
    """

    static let healthKitWrite = """
    The Ghost records your workouts to track your training history and improve future scheduling recommendations.
    """

    static let calendar = """
    The Ghost reads your calendars to find the best workout times that don't conflict with your existing commitments. \
    It only writes to its own "Vigor Training" calendar.
    """

    static let calendarFullAccess = """
    The Ghost needs calendar access to schedule training blocks and detect conflicts with your existing events. \
    It reads all calendars but only writes to its own "Vigor Training" calendar.
    """

    static let backgroundRefresh = """
    The Ghost uses background refresh to check your calendar and health data in the morning, \
    so your day's schedule is ready when you wake up.
    """

    static let notifications = """
    The Ghost sends silent notifications to wake up and check your schedule. \
    You won't see these - they're invisible, just like The Ghost.
    """

    static let watchHealthKit = """
    The Ghost Watch app records your workouts and heart rate to sync with your iPhone for better scheduling.
    """
}

// MARK: - Background Task Identifiers

/// BGTaskScheduler task identifiers
enum BackgroundTaskIdentifiers {
    static let morningWake = "com.vigor.ghost.morning-wake"
    static let eveningCycle = "com.vigor.ghost.evening-cycle"
    static let phenomeSync = "com.vigor.ghost.phenome-sync"
    static let calendarScan = "com.vigor.ghost.calendar-scan"

    static var all: [String] {
        [morningWake, eveningCycle, phenomeSync, calendarScan]
    }
}

// MARK: - App Group Identifiers

/// Shared container identifiers for iPhone-Watch communication
enum AppGroupIdentifiers {
    static let shared = "group.com.vigor.shared"
    static let phenome = "iCloud.com.vigor.phenome"
}

// MARK: - Keychain Groups

enum KeychainGroups {
    static let shared = "com.vigor.shared"
}
