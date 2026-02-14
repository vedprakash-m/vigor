//
//  VigorHaptics.swift
//  Vigor
//
//  Haptic feedback engine for trust advancement and other events.
//

import UIKit

enum VigorHaptics {
    static func trustAdvancement() async {
        await MainActor.run {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    static func blockScheduled() async {
        await MainActor.run {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }

    static func workoutCompleted() async {
        await MainActor.run {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    static func warning() async {
        await MainActor.run {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }
}
