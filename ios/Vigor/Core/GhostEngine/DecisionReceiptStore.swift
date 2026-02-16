//
//  DecisionReceiptStore.swift
//  Vigor
//
//  Forensic logging for Ghost decisions.
//  Records: action, inputs (hashed), alternatives, confidence, trust impact
//  90-day TTL with rolling window.
//
//  Per Tech Spec §2.4
//
//  Backed by Core Data for persistence across app launches.
//

import Foundation
import CoreData

actor DecisionReceiptStore {

    // MARK: - Singleton

    static let shared = DecisionReceiptStore()

    // MARK: - Core Data

    private var stack: CoreDataStack { CoreDataStack.shared }

    // MARK: - Write Buffer

    private var pendingReceipts: [DecisionReceipt] = []
    private let maxReceiptAge: TimeInterval = 90 * 24 * 60 * 60 // 90 days

    // MARK: - Storage Operations

    func store(_ receipt: DecisionReceipt) async {
        var mutableReceipt = receipt
        mutableReceipt.timestamp = Date()

        pendingReceipts.append(mutableReceipt)

        // Flush when buffer is big enough
        if pendingReceipts.count >= 10 {
            await flush()
        }
    }

    func flush() async {
        guard !pendingReceipts.isEmpty else { return }

        let toWrite = pendingReceipts
        pendingReceipts.removeAll()

        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            for r in toWrite {
                _ = DecisionReceiptEntity.from(r, context: ctx)
            }
            CoreDataStack.save(ctx)
        }
    }

    // MARK: - Query Operations

    func getReceipts(
        for action: DecisionAction? = nil,
        from startDate: Date? = nil,
        to endDate: Date? = nil,
        limit: Int = 100
    ) async -> [DecisionReceipt] {
        // Include any un-flushed pending receipts
        await flush()

        let ctx = stack.viewContext
        var result: [DecisionReceipt] = []
        ctx.performAndWait {
            let req = DecisionReceiptEntity.fetchRequest()
            var predicates: [NSPredicate] = []

            if let action = action {
                predicates.append(NSPredicate(format: "action == %@", action.rawValue))
            }
            if let start = startDate {
                predicates.append(NSPredicate(format: "timestamp >= %@", start as NSDate))
            }
            if let end = endDate {
                predicates.append(NSPredicate(format: "timestamp <= %@", end as NSDate))
            }

            if !predicates.isEmpty {
                req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            req.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            req.fetchLimit = limit

            result = ((try? ctx.fetch(req)) ?? []).map { $0.toDomain() }
        }
        return result
    }

    func getRecentReceipts(days: Int) async -> [DecisionReceipt] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
        return await getReceipts(from: cutoff)
    }

    func getReceiptsForExplainability(blockId: String) async -> [DecisionReceipt] {
        // Flush first so nothing is missed
        await flush()

        let ctx = stack.viewContext
        var result: [DecisionReceipt] = []
        ctx.performAndWait {
            let req = DecisionReceiptEntity.fetchRequest()
            // inputsJSON is a text column – search for the block_id substring
            req.predicate = NSPredicate(format: "inputsJSON CONTAINS %@", blockId)
            req.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            result = ((try? ctx.fetch(req)) ?? []).map { $0.toDomain() }
        }
        return result
    }

    // MARK: - Analytics

    func getSuccessRate(for action: DecisionAction, days: Int) async -> Double {
        let recent = await getReceipts(for: action, from: Date().addingTimeInterval(-Double(days) * 86400))
        guard !recent.isEmpty else { return 0 }
        let successes = recent.filter { $0.outcome.isSuccess }.count
        return Double(successes) / Double(recent.count)
    }

    func getAverageConfidence(for action: DecisionAction, days: Int) async -> Double {
        let recent = await getReceipts(for: action, from: Date().addingTimeInterval(-Double(days) * 86400))
        guard !recent.isEmpty else { return 0 }
        return recent.reduce(0.0) { $0 + $1.confidence } / Double(recent.count)
    }

    // MARK: - Cleanup (90-day TTL)

    func pruneExpiredReceipts() {
        let now = Date() as NSDate
        let ctx = stack.newBackgroundContext()
        ctx.performAndWait {
            CoreDataStack.batchDelete(
                entityName: "DecisionReceiptEntity",
                predicate: NSPredicate(format: "ttlDate <= %@", now),
                in: ctx
            )
        }
    }
}

// MARK: - Decision Receipt

struct DecisionReceipt: Identifiable, Codable {
    let id: UUID
    var timestamp: Date
    let action: DecisionAction
    var inputs: [DecisionInput]
    var alternatives: [String]
    var confidence: Double
    var outcome: DecisionOutcome
    var trustImpact: Double?

    init(action: DecisionAction) {
        self.id = UUID()
        self.timestamp = Date()
        self.action = action
        self.inputs = []
        self.alternatives = []
        self.confidence = 0.0
        self.outcome = .pending
        self.trustImpact = nil
    }

    mutating func addInput(_ key: String, value: Any) {
        // Hash sensitive values
        let hashedValue = hashIfSensitive(key: key, value: value)
        inputs.append(DecisionInput(key: key, value: hashedValue))
    }

    private func hashIfSensitive(key: String, value: Any) -> String {
        let sensitiveKeys = ["user_id", "device_token", "calendar_id"]

        if sensitiveKeys.contains(key) {
            // Return hashed value for privacy
            return String(describing: value).hashValue.description
        }

        return String(describing: value)
    }
}

struct DecisionInput: Codable, Equatable {
    let key: String
    let value: String
}

enum DecisionAction: String, Codable {
    case morningCycle = "morning_cycle"
    case eveningCycle = "evening_cycle"
    case workoutDetected = "workout_detected"
    case blockCreated = "block_created"
    case blockTransformed = "block_transformed"
    case blockRemoved = "block_removed"
    case trustAdvanced = "trust_advanced"
    case trustRetreated = "trust_retreated"
    case safetyBreakerTriggered = "safety_breaker_triggered"
    case triageRecorded = "triage_recorded"
    case healthModeChanged = "health_mode_changed"
}

enum DecisionOutcome: Codable, Equatable {
    case pending
    case success
    case failure(String)
    case skipped(String)

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

// MARK: - Human Readable Extension

extension DecisionReceipt {
    var humanReadableReason: String {
        switch action {
        case .morningCycle:
            return formatMorningCycleReason()
        case .eveningCycle:
            return formatEveningCycleReason()
        case .blockTransformed:
            return formatBlockTransformationReason()
        case .blockRemoved:
            return formatBlockRemovalReason()
        default:
            return "Decision made based on your patterns and preferences."
        }
    }

    private func formatMorningCycleReason() -> String {
        var reasons: [String] = []

        if let sleepHours = inputs.first(where: { $0.key == "sleep_hours" })?.value,
           let hours = Double(sleepHours), hours < 6 {
            reasons.append("You got \(String(format: "%.1f", hours)) hours of sleep")
        }

        if let recoveryScore = inputs.first(where: { $0.key == "recovery_score" })?.value,
           let score = Double(recoveryScore), score < 50 {
            reasons.append("Your recovery score is \(Int(score))%")
        }

        if reasons.isEmpty {
            return "Your morning metrics look good!"
        }

        return reasons.joined(separator: ". ") + "."
    }

    private func formatEveningCycleReason() -> String {
        if let window = inputs.first(where: { $0.key == "optimal_window_start" })?.value {
            return "Found an optimal workout window at \(window) based on your calendar."
        }
        return "Analyzed tomorrow's schedule to find the best time for your workout."
    }

    private func formatBlockTransformationReason() -> String {
        if let originalType = inputs.first(where: { $0.key == "original_block_type" })?.value,
           let transformation = inputs.first(where: { $0.key == "transformation" })?.value {
            return "Changed from \(originalType) to \(transformation) to match your recovery level."
        }
        return "Adjusted your workout based on how you're feeling."
    }

    private func formatBlockRemovalReason() -> String {
        if let recoveryScore = inputs.first(where: { $0.key == "recovery_score" })?.value,
           let score = Double(recoveryScore) {
            return "Removed today's workout because your recovery score (\(Int(score))%) suggests you need rest."
        }
        return "Removed workout to prioritize your recovery."
    }
}
