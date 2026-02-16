//
//  LocalWorkoutGenerator.swift
//  Vigor
//
//  Generates workout plans locally using template patterns.
//  Falls back when API is unavailable. Adapts to user equipment,
//  time window, recovery state, and recent workout history.
//

import Foundation

@MainActor
final class LocalWorkoutGenerator {
    static let shared = LocalWorkoutGenerator()
    private init() {}

    // MARK: - Public API

    func generate(
        window: TimeWindow,
        preferences: WorkoutPreferences,
        recentHistory: [DetectedWorkout]
    ) async -> GeneratedWorkout? {
        let availableMinutes = Int(window.duration / 60) - 10 // leave 10 min buffer
        guard availableMinutes >= 20 else { return nil }

        let type = pickType(preferences: preferences, recent: recentHistory)
        let exercises = buildExercises(for: type, minutes: availableMinutes, equipment: preferences.equipment)
        let warmup = buildWarmup(for: type)
        let cooldown = buildCooldown()

        return GeneratedWorkout(
            id: UUID().uuidString,
            type: type,
            name: nameForType(type),
            description: descriptionForType(type, minutes: availableMinutes),
            durationMinutes: availableMinutes,
            exercises: exercises,
            warmup: warmup,
            cooldown: cooldown,
            generatedAt: Date(),
            confidence: 0.75
        )
    }

    // MARK: - Type Selection

    private func pickType(preferences: WorkoutPreferences, recent: [DetectedWorkout]) -> WorkoutType {
        let recentTypes = recent.prefix(3).map { $0.type }

        // If the user has had many intense workouts recently, suggest recovery
        let recentIntenseCount = recentTypes.filter { $0 == .strength || $0 == .hiit }.count
        if recentIntenseCount >= 2 {
            let recoveryCandidates: [WorkoutType] = [.recoveryWalk, .lightCardio, .flexibility]
            let notRecent = recoveryCandidates.filter { !recentTypes.contains($0) }
            if let pick = notRecent.randomElement() { return pick }
        }

        let candidates: [WorkoutType] = [.strength, .cardio, .hiit, .flexibility]

        // Prefer types NOT done recently for variety
        let notRecent = candidates.filter { !recentTypes.contains($0) }
        if let pick = notRecent.randomElement() { return pick }
        return candidates.randomElement() ?? .strength
    }

    // MARK: - Exercise Templates

    private func buildExercises(for type: WorkoutType, minutes: Int, equipment: [String]) -> [Exercise] {
        switch type {
        case .strength:     return strengthExercises(minutes: minutes, equipment: equipment)
        case .cardio:       return cardioExercises(minutes: minutes)
        case .hiit:         return hiitExercises(minutes: minutes)
        case .flexibility:  return flexibilityExercises(minutes: minutes)
        case .recoveryWalk: return recoveryWalkExercises(minutes: minutes)
        case .lightCardio:  return lightCardioExercises(minutes: minutes)
        case .other:        return strengthExercises(minutes: minutes, equipment: equipment)
        }
    }

    private func strengthExercises(minutes: Int, equipment: [String]) -> [Exercise] {
        let hasWeights = equipment.contains(where: { $0.lowercased().contains("dumbbell") || $0.lowercased().contains("barbell") })
        let roundCount = max(2, minutes / 10)
        var list: [Exercise] = []

        let pool: [(String, String)] = hasWeights ?
            [("Goblet Squat", "12"), ("Dumbbell Row", "10 per side"), ("Push-Up", "12-15"),
             ("Romanian Deadlift", "10"), ("Overhead Press", "10"), ("Plank", "30s")] :
            [("Bodyweight Squat", "15"), ("Push-Up", "12-15"), ("Inverted Row / Doorframe Row", "10"),
             ("Reverse Lunge", "10 per side"), ("Pike Push-Up", "8-10"), ("Plank", "45s")]

        for (i, ex) in pool.prefix(roundCount).enumerated() {
            list.append(Exercise(id: "str-\(i)", name: ex.0, sets: 3, reps: ex.1, duration: nil, restSeconds: 60, notes: nil))
        }
        return list
    }

    private func cardioExercises(minutes: Int) -> [Exercise] {
        let runMinutes = max(10, minutes - 5)
        return [
            Exercise(id: "car-0", name: "Steady-State Run / Brisk Walk", sets: nil, reps: nil, duration: runMinutes * 60, restSeconds: nil, notes: "Keep heart rate in zone 2 (conversational pace)")
        ]
    }

    private func hiitExercises(minutes: Int) -> [Exercise] {
        let rounds = max(4, (minutes - 4) / 2)  // ~2 min per round (30s work + 30s rest × 2)
        return [
            Exercise(id: "hiit-0", name: "Burpees", sets: rounds, reps: "30s on / 30s off", duration: nil, restSeconds: 30, notes: nil),
            Exercise(id: "hiit-1", name: "Mountain Climbers", sets: rounds, reps: "30s on / 30s off", duration: nil, restSeconds: 30, notes: nil),
            Exercise(id: "hiit-2", name: "Jump Squats", sets: rounds / 2, reps: "30s on / 30s off", duration: nil, restSeconds: 30, notes: nil)
        ]
    }

    private func flexibilityExercises(minutes: Int) -> [Exercise] {
        return [
            Exercise(id: "flex-0", name: "Cat-Cow", sets: nil, reps: "10", duration: nil, restSeconds: nil, notes: nil),
            Exercise(id: "flex-1", name: "Downward Dog → Cobra Flow", sets: nil, reps: "8", duration: nil, restSeconds: nil, notes: "Hold each position 3 breaths"),
            Exercise(id: "flex-2", name: "Pigeon Pose", sets: nil, reps: nil, duration: 60, restSeconds: nil, notes: "60s each side"),
            Exercise(id: "flex-3", name: "Supine Spinal Twist", sets: nil, reps: nil, duration: 60, restSeconds: nil, notes: "60s each side"),
            Exercise(id: "flex-4", name: "Standing Forward Fold", sets: nil, reps: nil, duration: 60, restSeconds: nil, notes: "Let gravity do the work")
        ]
    }

    private func recoveryWalkExercises(minutes: Int) -> [Exercise] {
        let walkMinutes = max(10, minutes - 5)
        return [
            Exercise(id: "rw-0", name: "Easy Walk", sets: nil, reps: nil, duration: walkMinutes * 60, restSeconds: nil,
                     notes: "Keep a relaxed pace. Heart rate should stay below zone 2. Focus on breathing and posture."),
            Exercise(id: "rw-1", name: "Gentle Calf Stretch", sets: nil, reps: nil, duration: 30, restSeconds: nil, notes: "30s each side"),
            Exercise(id: "rw-2", name: "Standing Quad Stretch", sets: nil, reps: nil, duration: 30, restSeconds: nil, notes: "30s each side")
        ]
    }

    private func lightCardioExercises(minutes: Int) -> [Exercise] {
        let roundMinutes = max(5, (minutes - 5) / 3)
        return [
            Exercise(id: "lc-0", name: "Light Jog / Power Walk", sets: nil, reps: nil, duration: roundMinutes * 60, restSeconds: 60,
                     notes: "Stay at conversational pace; HR zone 1-2"),
            Exercise(id: "lc-1", name: "Marching in Place", sets: nil, reps: nil, duration: roundMinutes * 60, restSeconds: 60,
                     notes: "High knees at a comfortable tempo"),
            Exercise(id: "lc-2", name: "Lateral Shuffle", sets: nil, reps: nil, duration: roundMinutes * 60, restSeconds: nil,
                     notes: "Easy side-to-side movement, 30s each direction")
        ]
    }

    // MARK: - Warmup / Cooldown

    private func buildWarmup(for type: WorkoutType) -> [Exercise] {
        [
            Exercise(id: "wu-0", name: "Arm Circles", sets: nil, reps: "10 each direction", duration: nil, restSeconds: nil, notes: nil),
            Exercise(id: "wu-1", name: "Leg Swings", sets: nil, reps: "10 each leg", duration: nil, restSeconds: nil, notes: nil),
            Exercise(id: "wu-2", name: "Bodyweight Squat (light)", sets: nil, reps: "10", duration: nil, restSeconds: nil, notes: "Slow & controlled")
        ]
    }

    private func buildCooldown() -> [Exercise] {
        [
            Exercise(id: "cd-0", name: "Hamstring Stretch", sets: nil, reps: nil, duration: 30, restSeconds: nil, notes: "30s each leg"),
            Exercise(id: "cd-1", name: "Quad Stretch", sets: nil, reps: nil, duration: 30, restSeconds: nil, notes: "30s each leg"),
            Exercise(id: "cd-2", name: "Deep Breathing", sets: nil, reps: "5 breaths", duration: nil, restSeconds: nil, notes: "4-7-8 pattern")
        ]
    }

    // MARK: - Naming

    private func nameForType(_ type: WorkoutType) -> String {
        switch type {
        case .strength:     return "Full Body Strength"
        case .cardio:       return "Steady Cardio"
        case .hiit:         return "HIIT Blast"
        case .flexibility:  return "Mobility Flow"
        case .recoveryWalk: return "Recovery Walk"
        case .lightCardio:  return "Light Cardio"
        case .other:        return "General Workout"
        }
    }

    private func descriptionForType(_ type: WorkoutType, minutes: Int) -> String {
        switch type {
        case .strength:     return "A \(minutes)-minute full body strength session focusing on compound movements."
        case .cardio:       return "A \(minutes)-minute steady-state cardio session to build aerobic base."
        case .hiit:         return "A \(minutes)-minute high-intensity interval session for maximum efficiency."
        case .flexibility:  return "A \(minutes)-minute mobility and flexibility flow to aid recovery."
        case .recoveryWalk: return "A gentle \(minutes)-minute walk to promote active recovery and circulation."
        case .lightCardio:  return "A \(minutes)-minute low-intensity cardio session to maintain movement without stress."
        case .other:        return "A \(minutes)-minute workout tailored to your schedule."
        }
    }
}
