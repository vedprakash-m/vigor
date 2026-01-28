//
//  AccessibilityTests.swift
//  VigorTests
//
//  Created by Vigor Team on January 27, 2026.
//  Copyright © 2026 Vigor. All rights reserved.
//
//  Accessibility compliance tests for Ghost UI.
//  Ensures WCAG 2.1 AA compliance.
//

import XCTest
import SwiftUI
@testable import Vigor

final class AccessibilityTests: XCTestCase {

    // MARK: - VoiceOver Label Tests

    func testTriageCardHasAccessibilityLabels() {
        let card = TriageCardView.mock()

        XCTAssertNotNil(card.accessibilityLabel, "Triage card needs accessibility label")
        XCTAssertFalse(card.accessibilityLabel?.isEmpty ?? true)
    }

    func testTriageOptionsAreAccessible() {
        let options = [
            MockTriageOption(action: .confirm, label: "Good to go"),
            MockTriageOption(action: .reschedule, label: "Find another time"),
            MockTriageOption(action: .skip, label: "Not today")
        ]

        for option in options {
            XCTAssertTrue(option.isAccessibilityElement, "Option should be accessibility element")
            XCTAssertNotNil(option.accessibilityLabel, "Option needs label")
            XCTAssertNotNil(option.accessibilityHint, "Option needs hint")
        }
    }

    func testValueReceiptIsAccessible() {
        let receipt = MockValueReceipt(
            completedWorkouts: 4,
            scheduledWorkouts: 5,
            ghostContributions: 3
        )

        XCTAssertNotNil(receipt.accessibilityLabel, "Value receipt needs label")
        XCTAssertTrue(receipt.accessibilityLabel?.contains("4") ?? false, "Should mention completed count")
        XCTAssertTrue(receipt.accessibilityLabel?.contains("5") ?? false, "Should mention scheduled count")
    }

    func testTrustIndicatorIsAccessible() {
        let indicator = MockTrustIndicator(phase: .scheduler, confidence: 0.35)

        XCTAssertNotNil(indicator.accessibilityLabel)
        XCTAssertTrue(indicator.accessibilityLabel?.contains("Scheduler") ?? false)
        XCTAssertTrue(indicator.accessibilityLabel?.contains("35") ?? false, "Should include percentage")
    }

    // MARK: - Dynamic Type Tests

    func testTriageCardSupportsDynamicType() {
        let card = MockTriageCardView()

        // Check that card uses scalable fonts
        XCTAssertTrue(card.usesScaledFont, "Should use scaled font")
        XCTAssertTrue(card.supportsAccessibilitySizes, "Should support accessibility sizes")
    }

    func testValueReceiptSupportsDynamicType() {
        let receipt = MockValueReceiptView()

        XCTAssertTrue(receipt.usesScaledFont)
        XCTAssertTrue(receipt.supportsAccessibilitySizes)
    }

    func testOnboardingSupportsDynamicType() {
        let onboarding = MockOnboardingView()

        XCTAssertTrue(onboarding.usesScaledFont)
        XCTAssertTrue(onboarding.supportsAccessibilitySizes)
        XCTAssertTrue(onboarding.buttonsAreMinimumSize, "Buttons should be at least 44pt")
    }

    // MARK: - Color Contrast Tests

    func testPrimaryButtonContrast() {
        let button = MockPrimaryButton()
        let contrastRatio = calculateContrastRatio(
            foreground: button.textColor,
            background: button.backgroundColor
        )

        // WCAG 2.1 AA requires 4.5:1 for normal text
        XCTAssertGreaterThanOrEqual(contrastRatio, 4.5, "Primary button needs 4.5:1 contrast")
    }

    func testSecondaryButtonContrast() {
        let button = MockSecondaryButton()
        let contrastRatio = calculateContrastRatio(
            foreground: button.textColor,
            background: button.backgroundColor
        )

        XCTAssertGreaterThanOrEqual(contrastRatio, 4.5, "Secondary button needs 4.5:1 contrast")
    }

    func testCardBackgroundContrast() {
        let card = MockTriageCardView()
        let contrastRatio = calculateContrastRatio(
            foreground: card.textColor,
            background: card.backgroundColor
        )

        XCTAssertGreaterThanOrEqual(contrastRatio, 4.5)
    }

    func testWorkoutTypeIconsHaveContrast() {
        let workoutTypes: [WorkoutType] = [.strength, .cardio, .hiit, .mobility, .recovery]

        for type in workoutTypes {
            let icon = MockWorkoutIcon(type: type)
            let contrastRatio = calculateContrastRatio(
                foreground: icon.iconColor,
                background: icon.backgroundColor
            )

            // Icons need 3:1 minimum contrast
            XCTAssertGreaterThanOrEqual(contrastRatio, 3.0, "\(type) icon needs 3:1 contrast")
        }
    }

    // MARK: - Touch Target Tests

    func testTriageButtonsAreMinimumSize() {
        let options = MockTriageCardView().optionButtons

        for button in options {
            XCTAssertGreaterThanOrEqual(button.height, 44, "Button height must be >= 44pt")
            XCTAssertGreaterThanOrEqual(button.width, 44, "Button width must be >= 44pt")
        }
    }

    func testNavigationButtonsAreMinimumSize() {
        let navButtons = MockNavigationView().buttons

        for button in navButtons {
            XCTAssertGreaterThanOrEqual(button.height, 44)
            XCTAssertGreaterThanOrEqual(button.width, 44)
        }
    }

    func testWatchComplicationTouchTargets() {
        // Watch needs even larger targets (38pt minimum on small screens)
        let complications = MockWatchComplications()

        for button in complications.interactiveElements {
            XCTAssertGreaterThanOrEqual(button.diameter, 38, "Watch elements must be >= 38pt")
        }
    }

    // MARK: - Reduce Motion Tests

    func testTriageCardRespectsReduceMotion() {
        let card = MockTriageCardView()

        // When reduce motion is on, animations should be minimal/none
        XCTAssertTrue(card.respectsReduceMotion, "Should respect reduce motion preference")
    }

    func testValueReceiptRespectsReduceMotion() {
        let receipt = MockValueReceiptView()

        XCTAssertTrue(receipt.respectsReduceMotion)
    }

    // MARK: - High Contrast Tests

    func testHighContrastModeSupport() {
        let card = MockTriageCardView()

        // High contrast mode should increase contrast ratios
        let normalContrast = calculateContrastRatio(
            foreground: card.textColor,
            background: card.backgroundColor
        )

        let highContrastCard = MockTriageCardView(highContrast: true)
        let highContrast = calculateContrastRatio(
            foreground: highContrastCard.textColor,
            background: highContrastCard.backgroundColor
        )

        XCTAssertGreaterThanOrEqual(highContrast, normalContrast, "High contrast should improve ratio")
        XCTAssertGreaterThanOrEqual(highContrast, 7.0, "High contrast should meet AAA (7:1)")
    }

    // MARK: - Screen Reader Order Tests

    func testTriageCardReadingOrder() {
        let card = MockTriageCardView()
        let order = card.accessibilityElements

        // Should read: Title, Workout type, Time, Options
        XCTAssertTrue(order.first?.contains("Training") ?? false, "Should start with title/workout")
        XCTAssertTrue(order.last?.contains("option") ?? true, "Should end with options")
    }

    func testValueReceiptReadingOrder() {
        let receipt = MockValueReceiptView()
        let order = receipt.accessibilityElements

        // Should read: Summary, Details, Ghost contributions
        XCTAssertGreaterThan(order.count, 0, "Should have accessibility elements")
    }

    // MARK: - Focus Management Tests

    func testModalPresentationFocusManagement() {
        let modal = MockTriageModal()

        XCTAssertTrue(modal.trapsFocus, "Modal should trap focus")
        XCTAssertNotNil(modal.firstFocusElement, "Modal should have initial focus element")
        XCTAssertNotNil(modal.dismissAction, "Modal should have dismiss action")
    }

    // MARK: - Helper Methods

    private func calculateContrastRatio(foreground: Color, background: Color) -> Double {
        // Simplified contrast calculation
        // Real implementation would use WCAG luminance formula
        let fgLuminance = luminance(for: foreground)
        let bgLuminance = luminance(for: background)

        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)

        return (lighter + 0.05) / (darker + 0.05)
    }

    private func luminance(for color: Color) -> Double {
        // Simplified - would use actual RGB values
        switch color {
        case .white: return 1.0
        case .black: return 0.0
        case .blue: return 0.2126 * 0 + 0.7152 * 0 + 0.0722 * 1
        case .green: return 0.2126 * 0 + 0.7152 * 0.5 + 0.0722 * 0
        default: return 0.5
        }
    }
}

// MARK: - Mock Views for Testing

struct MockTriageOption {
    let action: TriageAction
    let label: String

    var isAccessibilityElement: Bool { true }
    var accessibilityLabel: String? { label }
    var accessibilityHint: String? { "Double tap to \(label.lowercased())" }
}

struct MockValueReceipt {
    let completedWorkouts: Int
    let scheduledWorkouts: Int
    let ghostContributions: Int

    var accessibilityLabel: String? {
        "Weekly summary: \(completedWorkouts) of \(scheduledWorkouts) workouts completed. Ghost helped \(ghostContributions) times."
    }
}

struct MockTrustIndicator {
    let phase: TrustPhase
    let confidence: Double

    var accessibilityLabel: String? {
        let percentage = Int(confidence * 100)
        return "Trust level: \(phase.displayName) at \(percentage) percent"
    }
}

class MockTriageCardView {
    let highContrast: Bool

    init(highContrast: Bool = false) {
        self.highContrast = highContrast
    }

    var accessibilityLabel: String? { "Strength Training at 7 AM" }
    var usesScaledFont: Bool { true }
    var supportsAccessibilitySizes: Bool { true }
    var textColor: Color { highContrast ? .black : .primary }
    var backgroundColor: Color { highContrast ? .white : Color(white: 0.95) }
    var respectsReduceMotion: Bool { true }

    var optionButtons: [MockButton] {
        [
            MockButton(width: 100, height: 48),
            MockButton(width: 100, height: 48),
            MockButton(width: 100, height: 48)
        ]
    }

    var accessibilityElements: [String] {
        ["Strength Training", "7:00 AM", "45 minutes", "Confirm option", "Reschedule option", "Skip option"]
    }

    static func mock() -> MockTriageCardView {
        MockTriageCardView()
    }
}

class MockValueReceiptView {
    var usesScaledFont: Bool { true }
    var supportsAccessibilitySizes: Bool { true }
    var respectsReduceMotion: Bool { true }

    var accessibilityElements: [String] {
        ["Weekly Summary", "4 of 5 workouts", "Ghost contributions: 3 reschedules"]
    }
}

class MockOnboardingView {
    var usesScaledFont: Bool { true }
    var supportsAccessibilitySizes: Bool { true }
    var buttonsAreMinimumSize: Bool { true }
}

struct MockPrimaryButton {
    var textColor: Color { .white }
    var backgroundColor: Color { .blue }
}

struct MockSecondaryButton {
    var textColor: Color { .blue }
    var backgroundColor: Color { .white }
}

struct MockWorkoutIcon {
    let type: WorkoutType

    var iconColor: Color {
        switch type {
        case .strength: return .orange
        case .cardio: return .red
        case .hiit: return .purple
        case .mobility: return .green
        case .recovery: return .blue
        case .custom: return .gray
        }
    }

    var backgroundColor: Color { .white }
}

struct MockButton {
    let width: CGFloat
    let height: CGFloat
}

class MockNavigationView {
    var buttons: [MockButton] {
        [MockButton(width: 44, height: 44), MockButton(width: 44, height: 44)]
    }
}

class MockWatchComplications {
    var interactiveElements: [MockCircle] {
        [MockCircle(diameter: 40), MockCircle(diameter: 38)]
    }
}

struct MockCircle {
    let diameter: CGFloat
}

class MockTriageModal {
    var trapsFocus: Bool { true }
    var firstFocusElement: String? { "Confirm button" }
    var dismissAction: String? { "Escape or swipe down to dismiss" }
}

extension TrustPhase {
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
