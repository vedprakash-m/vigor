//
//  ExerciseDatabase.swift
//  Vigor
//
//  Categorized exercise library with equipment requirements,
//  muscle groups, difficulty levels, and contraindications.
//  Used by LocalWorkoutGenerator for varied, safe workout programming.
//

import Foundation

// MARK: - Exercise Catalog Entry

struct ExerciseCatalogEntry: Identifiable {
    let id: String
    let name: String
    let category: ExerciseCategory
    let muscleGroups: [MuscleGroup]
    let equipment: [EquipmentType]
    let difficulty: ExerciseDifficulty
    let defaultSets: Int
    let defaultReps: String
    let defaultDuration: Int? // seconds, for timed exercises
    let defaultRest: Int // seconds
    let notes: String?
    let contraindications: [Contraindication]

    /// Convert to the Exercise struct used by workout plans.
    func toExercise(idPrefix: String, index: Int) -> Exercise {
        Exercise(
            id: "\(idPrefix)-\(index)",
            name: name,
            sets: defaultDuration == nil ? defaultSets : nil,
            reps: defaultDuration == nil ? defaultReps : nil,
            duration: defaultDuration,
            restSeconds: defaultRest > 0 ? defaultRest : nil,
            notes: notes
        )
    }
}

// MARK: - Enums

enum ExerciseCategory: String, CaseIterable {
    case upperPush   = "upper_push"
    case upperPull   = "upper_pull"
    case lowerPush   = "lower_push"
    case lowerPull   = "lower_pull"
    case core        = "core"
    case cardio      = "cardio"
    case mobility    = "mobility"
    case plyometric  = "plyometric"
}

enum MuscleGroup: String, CaseIterable {
    case chest, shoulders, triceps
    case back, biceps, forearms
    case quads, hamstrings, glutes, calves
    case abs, obliques, lowerBack
    case fullBody, cardioSystem
}

enum EquipmentType: String, CaseIterable {
    case none        = "none"
    case dumbbell    = "dumbbell"
    case barbell     = "barbell"
    case kettlebell  = "kettlebell"
    case resistanceBand = "resistance_band"
    case pullUpBar   = "pull_up_bar"
    case bench       = "bench"
    case mat         = "mat"
}

enum ExerciseDifficulty: Int, Comparable {
    case beginner    = 1
    case intermediate = 2
    case advanced    = 3

    static func < (lhs: ExerciseDifficulty, rhs: ExerciseDifficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum Contraindication: String {
    case kneeInjury      = "knee"
    case shoulderInjury  = "shoulder"
    case backInjury      = "back"
    case wristInjury     = "wrist"
    case ankleInjury     = "ankle"
    case hipInjury       = "hip"
    case neckInjury      = "neck"
}

// MARK: - Exercise Database

struct ExerciseDatabase {

    /// Filter exercises by category, available equipment, max difficulty, and injuries.
    static func exercises(
        category: ExerciseCategory,
        availableEquipment: [String] = [],
        maxDifficulty: ExerciseDifficulty = .advanced,
        injuries: [String] = []
    ) -> [ExerciseCatalogEntry] {
        let equipmentSet = Set(availableEquipment.map { $0.lowercased() })
        let injurySet = Set(injuries.map { $0.lowercased() })

        return all.filter { entry in
            guard entry.category == category else { return false }
            guard entry.difficulty <= maxDifficulty else { return false }

            // Equipment check: entry needs no equipment OR user has at least one matching piece
            let needsEquipment = !entry.equipment.contains(.none)
            if needsEquipment {
                let entryEquipNames = Set(entry.equipment.map { $0.rawValue })
                if entryEquipNames.isDisjoint(with: equipmentSet) && !equipmentSet.isEmpty {
                    return false
                }
            }

            // Contraindication check
            for contra in entry.contraindications {
                if injurySet.contains(contra.rawValue) { return false }
            }

            return true
        }
    }

    /// Pick `count` random exercises from a category, respecting constraints.
    static func pick(
        _ count: Int,
        from category: ExerciseCategory,
        equipment: [String] = [],
        injuries: [String] = [],
        maxDifficulty: ExerciseDifficulty = .advanced
    ) -> [ExerciseCatalogEntry] {
        let pool = exercises(category: category, availableEquipment: equipment,
                             maxDifficulty: maxDifficulty, injuries: injuries)
        return Array(pool.shuffled().prefix(count))
    }

    // MARK: - Full Catalog

    static let all: [ExerciseCatalogEntry] = upperPush + upperPull + lowerPush + lowerPull + core + cardio + mobility + plyometric

    // MARK: Upper Push

    static let upperPush: [ExerciseCatalogEntry] = [
        ExerciseCatalogEntry(id: "ex-push-up", name: "Push-Up", category: .upperPush,
            muscleGroups: [.chest, .shoulders, .triceps], equipment: [.none],
            difficulty: .beginner, defaultSets: 3, defaultReps: "12-15", defaultDuration: nil, defaultRest: 60,
            notes: "Keep core tight, full range of motion", contraindications: [.wristInjury, .shoulderInjury]),

        ExerciseCatalogEntry(id: "ex-pike-pushup", name: "Pike Push-Up", category: .upperPush,
            muscleGroups: [.shoulders, .triceps], equipment: [.none],
            difficulty: .intermediate, defaultSets: 3, defaultReps: "8-10", defaultDuration: nil, defaultRest: 60,
            notes: "Hips high, head toward floor", contraindications: [.shoulderInjury, .wristInjury]),

        ExerciseCatalogEntry(id: "ex-db-bench", name: "Dumbbell Bench Press", category: .upperPush,
            muscleGroups: [.chest, .shoulders, .triceps], equipment: [.dumbbell, .bench],
            difficulty: .intermediate, defaultSets: 3, defaultReps: "10-12", defaultDuration: nil, defaultRest: 90,
            notes: nil, contraindications: [.shoulderInjury]),

        ExerciseCatalogEntry(id: "ex-overhead-press", name: "Overhead Press", category: .upperPush,
            muscleGroups: [.shoulders, .triceps], equipment: [.dumbbell],
            difficulty: .intermediate, defaultSets: 3, defaultReps: "10", defaultDuration: nil, defaultRest: 90,
            notes: "Brace core, avoid arching back", contraindications: [.shoulderInjury, .backInjury]),

        ExerciseCatalogEntry(id: "ex-diamond-pushup", name: "Diamond Push-Up", category: .upperPush,
            muscleGroups: [.triceps, .chest], equipment: [.none],
            difficulty: .intermediate, defaultSets: 3, defaultReps: "8-12", defaultDuration: nil, defaultRest: 60,
            notes: "Hands close together under chest", contraindications: [.wristInjury]),

        ExerciseCatalogEntry(id: "ex-incline-pushup", name: "Incline Push-Up", category: .upperPush,
            muscleGroups: [.chest, .triceps], equipment: [.none],
            difficulty: .beginner, defaultSets: 3, defaultReps: "12-15", defaultDuration: nil, defaultRest: 45,
            notes: "Hands on elevated surface — good regression", contraindications: [.wristInjury]),
    ]

    // MARK: Upper Pull

    static let upperPull: [ExerciseCatalogEntry] = [
        ExerciseCatalogEntry(id: "ex-inv-row", name: "Inverted Row", category: .upperPull,
            muscleGroups: [.back, .biceps], equipment: [.none],
            difficulty: .beginner, defaultSets: 3, defaultReps: "10-12", defaultDuration: nil, defaultRest: 60,
            notes: "Use a sturdy table or low bar", contraindications: [.shoulderInjury]),

        ExerciseCatalogEntry(id: "ex-db-row", name: "Dumbbell Row", category: .upperPull,
            muscleGroups: [.back, .biceps], equipment: [.dumbbell],
            difficulty: .beginner, defaultSets: 3, defaultReps: "10 per side", defaultDuration: nil, defaultRest: 60,
            notes: nil, contraindications: [.backInjury]),

        ExerciseCatalogEntry(id: "ex-pullup", name: "Pull-Up", category: .upperPull,
            muscleGroups: [.back, .biceps, .forearms], equipment: [.pullUpBar],
            difficulty: .advanced, defaultSets: 3, defaultReps: "5-8", defaultDuration: nil, defaultRest: 90,
            notes: "Full hang to chin above bar", contraindications: [.shoulderInjury]),

        ExerciseCatalogEntry(id: "ex-band-pulldown", name: "Band Lat Pulldown", category: .upperPull,
            muscleGroups: [.back, .biceps], equipment: [.resistanceBand],
            difficulty: .beginner, defaultSets: 3, defaultReps: "12-15", defaultDuration: nil, defaultRest: 45,
            notes: "Anchor band overhead", contraindications: [.shoulderInjury]),

        ExerciseCatalogEntry(id: "ex-face-pull", name: "Band Face Pull", category: .upperPull,
            muscleGroups: [.shoulders, .back], equipment: [.resistanceBand],
            difficulty: .beginner, defaultSets: 3, defaultReps: "15", defaultDuration: nil, defaultRest: 45,
            notes: "Pull to face height, squeeze shoulder blades", contraindications: [.shoulderInjury]),
    ]

    // MARK: Lower Push (Quad-dominant)

    static let lowerPush: [ExerciseCatalogEntry] = [
        ExerciseCatalogEntry(id: "ex-bw-squat", name: "Bodyweight Squat", category: .lowerPush,
            muscleGroups: [.quads, .glutes], equipment: [.none],
            difficulty: .beginner, defaultSets: 3, defaultReps: "15", defaultDuration: nil, defaultRest: 60,
            notes: "Full depth, knees tracking toes", contraindications: [.kneeInjury]),

        ExerciseCatalogEntry(id: "ex-goblet-squat", name: "Goblet Squat", category: .lowerPush,
            muscleGroups: [.quads, .glutes, .abs], equipment: [.dumbbell],
            difficulty: .beginner, defaultSets: 3, defaultReps: "12", defaultDuration: nil, defaultRest: 60,
            notes: "Hold dumbbell at chest", contraindications: [.kneeInjury]),

        ExerciseCatalogEntry(id: "ex-rev-lunge", name: "Reverse Lunge", category: .lowerPush,
            muscleGroups: [.quads, .glutes], equipment: [.none],
            difficulty: .beginner, defaultSets: 3, defaultReps: "10 per side", defaultDuration: nil, defaultRest: 60,
            notes: "Step back, knee gently touches ground", contraindications: [.kneeInjury]),

        ExerciseCatalogEntry(id: "ex-bb-squat", name: "Barbell Squat", category: .lowerPush,
            muscleGroups: [.quads, .glutes, .hamstrings], equipment: [.barbell],
            difficulty: .advanced, defaultSets: 4, defaultReps: "8-10", defaultDuration: nil, defaultRest: 120,
            notes: "Brace core, break at hips and knees simultaneously", contraindications: [.kneeInjury, .backInjury]),

        ExerciseCatalogEntry(id: "ex-step-up", name: "Step-Up", category: .lowerPush,
            muscleGroups: [.quads, .glutes], equipment: [.none],
            difficulty: .beginner, defaultSets: 3, defaultReps: "10 per side", defaultDuration: nil, defaultRest: 60,
            notes: "Use a sturdy bench or step", contraindications: [.kneeInjury, .ankleInjury]),
    ]

    // MARK: Lower Pull (Hip-dominant)

    static let lowerPull: [ExerciseCatalogEntry] = [
        ExerciseCatalogEntry(id: "ex-rdl", name: "Romanian Deadlift", category: .lowerPull,
            muscleGroups: [.hamstrings, .glutes, .lowerBack], equipment: [.dumbbell],
            difficulty: .intermediate, defaultSets: 3, defaultReps: "10", defaultDuration: nil, defaultRest: 90,
            notes: "Hinge at hips, soft knee bend, flat back", contraindications: [.backInjury]),

        ExerciseCatalogEntry(id: "ex-hip-thrust", name: "Hip Thrust", category: .lowerPull,
            muscleGroups: [.glutes, .hamstrings], equipment: [.bench],
            difficulty: .intermediate, defaultSets: 3, defaultReps: "12-15", defaultDuration: nil, defaultRest: 60,
            notes: "Shoulders on bench, drive hips to ceiling", contraindications: [.hipInjury]),

        ExerciseCatalogEntry(id: "ex-glute-bridge", name: "Glute Bridge", category: .lowerPull,
            muscleGroups: [.glutes, .hamstrings], equipment: [.none],
            difficulty: .beginner, defaultSets: 3, defaultReps: "15", defaultDuration: nil, defaultRest: 45,
            notes: "Squeeze glutes at top", contraindications: []),

        ExerciseCatalogEntry(id: "ex-single-rdl", name: "Single-Leg Romanian Deadlift", category: .lowerPull,
            muscleGroups: [.hamstrings, .glutes], equipment: [.none],
            difficulty: .intermediate, defaultSets: 3, defaultReps: "8 per side", defaultDuration: nil, defaultRest: 60,
            notes: "Balance challenge — use wall for support if needed", contraindications: [.ankleInjury, .backInjury]),

        ExerciseCatalogEntry(id: "ex-kb-swing", name: "Kettlebell Swing", category: .lowerPull,
            muscleGroups: [.glutes, .hamstrings, .lowerBack], equipment: [.kettlebell],
            difficulty: .intermediate, defaultSets: 3, defaultReps: "15", defaultDuration: nil, defaultRest: 60,
            notes: "Power from hips, arms are just handles", contraindications: [.backInjury]),
    ]

    // MARK: Core

    static let core: [ExerciseCatalogEntry] = [
        ExerciseCatalogEntry(id: "ex-plank", name: "Plank", category: .core,
            muscleGroups: [.abs, .obliques], equipment: [.none],
            difficulty: .beginner, defaultSets: 3, defaultReps: "30-60s", defaultDuration: 45, defaultRest: 30,
            notes: "Straight line from head to heels", contraindications: [.backInjury]),

        ExerciseCatalogEntry(id: "ex-dead-bug", name: "Dead Bug", category: .core,
            muscleGroups: [.abs, .lowerBack], equipment: [.mat],
            difficulty: .beginner, defaultSets: 3, defaultReps: "10 per side", defaultDuration: nil, defaultRest: 30,
            notes: "Press lower back into floor", contraindications: []),

        ExerciseCatalogEntry(id: "ex-pallof-press", name: "Band Pallof Press", category: .core,
            muscleGroups: [.abs, .obliques], equipment: [.resistanceBand],
            difficulty: .intermediate, defaultSets: 3, defaultReps: "10 per side", defaultDuration: nil, defaultRest: 45,
            notes: "Resist rotation", contraindications: []),

        ExerciseCatalogEntry(id: "ex-bicycle-crunch", name: "Bicycle Crunch", category: .core,
            muscleGroups: [.abs, .obliques], equipment: [.none],
            difficulty: .beginner, defaultSets: 3, defaultReps: "15 per side", defaultDuration: nil, defaultRest: 30,
            notes: "Slow and controlled, no yanking on neck", contraindications: [.neckInjury, .backInjury]),

        ExerciseCatalogEntry(id: "ex-side-plank", name: "Side Plank", category: .core,
            muscleGroups: [.obliques, .abs], equipment: [.none],
            difficulty: .intermediate, defaultSets: 2, defaultReps: "30s each side", defaultDuration: 30, defaultRest: 30,
            notes: "Stack feet or stagger for balance", contraindications: [.shoulderInjury, .wristInjury]),
    ]

    // MARK: Cardio

    static let cardio: [ExerciseCatalogEntry] = [
        ExerciseCatalogEntry(id: "ex-run", name: "Steady-State Run", category: .cardio,
            muscleGroups: [.cardioSystem, .quads, .calves], equipment: [.none],
            difficulty: .beginner, defaultSets: 1, defaultReps: "", defaultDuration: 1200, defaultRest: 0,
            notes: "Conversational pace, Zone 2 heart rate", contraindications: [.kneeInjury, .ankleInjury]),

        ExerciseCatalogEntry(id: "ex-brisk-walk", name: "Brisk Walk", category: .cardio,
            muscleGroups: [.cardioSystem, .glutes, .calves], equipment: [.none],
            difficulty: .beginner, defaultSets: 1, defaultReps: "", defaultDuration: 1800, defaultRest: 0,
            notes: "Maintain brisk pace; great for recovery days", contraindications: []),

        ExerciseCatalogEntry(id: "ex-jump-rope", name: "Jump Rope", category: .cardio,
            muscleGroups: [.cardioSystem, .calves], equipment: [.none],
            difficulty: .intermediate, defaultSets: 5, defaultReps: "60s on / 30s off", defaultDuration: nil, defaultRest: 30,
            notes: "Stay on balls of feet", contraindications: [.kneeInjury, .ankleInjury]),

        ExerciseCatalogEntry(id: "ex-march-place", name: "Marching in Place", category: .cardio,
            muscleGroups: [.cardioSystem, .quads], equipment: [.none],
            difficulty: .beginner, defaultSets: 1, defaultReps: "", defaultDuration: 600, defaultRest: 0,
            notes: "Lift knees to hip height", contraindications: []),
    ]

    // MARK: Mobility

    static let mobility: [ExerciseCatalogEntry] = [
        ExerciseCatalogEntry(id: "ex-cat-cow", name: "Cat-Cow", category: .mobility,
            muscleGroups: [.lowerBack, .abs], equipment: [.mat],
            difficulty: .beginner, defaultSets: 1, defaultReps: "10", defaultDuration: nil, defaultRest: 0,
            notes: "Sync with breath", contraindications: []),

        ExerciseCatalogEntry(id: "ex-down-dog", name: "Downward Dog → Cobra Flow", category: .mobility,
            muscleGroups: [.hamstrings, .shoulders, .abs], equipment: [.mat],
            difficulty: .beginner, defaultSets: 1, defaultReps: "8", defaultDuration: nil, defaultRest: 0,
            notes: "Hold each position 3 breaths", contraindications: [.wristInjury]),

        ExerciseCatalogEntry(id: "ex-pigeon", name: "Pigeon Pose", category: .mobility,
            muscleGroups: [.glutes, .hamstrings], equipment: [.mat],
            difficulty: .beginner, defaultSets: 1, defaultReps: "", defaultDuration: 60, defaultRest: 0,
            notes: "60s each side, ease into it", contraindications: [.kneeInjury, .hipInjury]),

        ExerciseCatalogEntry(id: "ex-spinal-twist", name: "Supine Spinal Twist", category: .mobility,
            muscleGroups: [.lowerBack, .obliques], equipment: [.mat],
            difficulty: .beginner, defaultSets: 1, defaultReps: "", defaultDuration: 60, defaultRest: 0,
            notes: "60s each side, let gravity pull", contraindications: [.backInjury]),

        ExerciseCatalogEntry(id: "ex-world-greatest", name: "World's Greatest Stretch", category: .mobility,
            muscleGroups: [.quads, .hamstrings, .glutes, .shoulders], equipment: [.none],
            difficulty: .beginner, defaultSets: 1, defaultReps: "5 per side", defaultDuration: nil, defaultRest: 0,
            notes: "Lunge, twist, reach — flows through all major areas", contraindications: []),

        ExerciseCatalogEntry(id: "ex-90-90", name: "90/90 Hip Switch", category: .mobility,
            muscleGroups: [.glutes, .hamstrings], equipment: [.mat],
            difficulty: .beginner, defaultSets: 1, defaultReps: "8 per side", defaultDuration: nil, defaultRest: 0,
            notes: "Sit on floor, rotate hips side to side", contraindications: [.hipInjury, .kneeInjury]),
    ]

    // MARK: Plyometric

    static let plyometric: [ExerciseCatalogEntry] = [
        ExerciseCatalogEntry(id: "ex-burpee", name: "Burpee", category: .plyometric,
            muscleGroups: [.fullBody, .cardioSystem], equipment: [.none],
            difficulty: .intermediate, defaultSets: 4, defaultReps: "30s on / 30s off", defaultDuration: nil, defaultRest: 30,
            notes: nil, contraindications: [.kneeInjury, .wristInjury, .backInjury]),

        ExerciseCatalogEntry(id: "ex-jump-squat", name: "Jump Squat", category: .plyometric,
            muscleGroups: [.quads, .glutes, .calves], equipment: [.none],
            difficulty: .intermediate, defaultSets: 3, defaultReps: "10", defaultDuration: nil, defaultRest: 60,
            notes: "Land softly, absorb through knees", contraindications: [.kneeInjury, .ankleInjury]),

        ExerciseCatalogEntry(id: "ex-mt-climbers", name: "Mountain Climbers", category: .plyometric,
            muscleGroups: [.abs, .cardioSystem, .quads], equipment: [.none],
            difficulty: .beginner, defaultSets: 4, defaultReps: "30s on / 30s off", defaultDuration: nil, defaultRest: 30,
            notes: "Plank position, drive knees to chest", contraindications: [.wristInjury]),

        ExerciseCatalogEntry(id: "ex-box-jump", name: "Box Jump", category: .plyometric,
            muscleGroups: [.quads, .glutes, .calves], equipment: [.none],
            difficulty: .advanced, defaultSets: 3, defaultReps: "8", defaultDuration: nil, defaultRest: 90,
            notes: "Use a sturdy surface, step down (don't jump)", contraindications: [.kneeInjury, .ankleInjury]),

        ExerciseCatalogEntry(id: "ex-high-knees", name: "High Knees", category: .plyometric,
            muscleGroups: [.cardioSystem, .quads], equipment: [.none],
            difficulty: .beginner, defaultSets: 4, defaultReps: "20s", defaultDuration: nil, defaultRest: 20,
            notes: "Drive knees up, pump arms", contraindications: [.kneeInjury]),
    ]
}
