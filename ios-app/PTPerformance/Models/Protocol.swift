//
//  Protocol.swift
//  PTPerformance
//
//  Therapy protocol templates with constraints for program building
//

import Foundation

struct TherapyProtocol: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let category: ProtocolCategory
    let durationWeeks: Int
    let phases: [ProtocolPhase]
    let constraints: ProtocolConstraints
    let createdAt: Date
    
    enum ProtocolCategory: String, Codable {
        case postSurgical = "post_surgical"
        case returnToSport = "return_to_sport"
        case strengthBuilding = "strength_building"
        case painManagement = "pain_management"
        case throwing = "throwing"
    }
    
    struct ProtocolPhase: Codable, Hashable {
        let id: UUID
        let name: String
        let order: Int
        let durationWeeks: Int
        let goals: [String]
        let allowedExerciseCategories: [String]
        let prohibitedExercises: [String]
        let restrictions: [String]
        let progressionCriteria: [String]
    }
    
    struct ProtocolConstraints: Codable, Hashable {
        let minPhases: Int
        let maxPhases: Int
        let canSkipPhases: Bool
        let canModifyDuration: Bool
        let requiredExerciseTypes: [String]
        let prohibitedExercises: [String]
        let maxPainLevel: Int
        let minAdherencePercent: Double
    }

    struct ProtocolPhaseConstraints: Codable, Hashable {
        let maxPainLevel: Int
        let requiredExerciseTypes: [String]
        let prohibitedExercises: [String]
        let minAdherencePercent: Double
        let maxIntensityPercent: Int
        let rpeRange: ClosedRange<Int>

        enum CodingKeys: String, CodingKey {
            case maxPainLevel
            case requiredExerciseTypes
            case prohibitedExercises
            case minAdherencePercent
            case maxIntensityPercent
            case rpeRange
        }

        init(maxPainLevel: Int, requiredExerciseTypes: [String], prohibitedExercises: [String], minAdherencePercent: Double, maxIntensityPercent: Int, rpeRange: ClosedRange<Int>) {
            self.maxPainLevel = maxPainLevel
            self.requiredExerciseTypes = requiredExerciseTypes
            self.prohibitedExercises = prohibitedExercises
            self.minAdherencePercent = minAdherencePercent
            self.maxIntensityPercent = maxIntensityPercent
            self.rpeRange = rpeRange
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            maxPainLevel = try container.decode(Int.self, forKey: .maxPainLevel)
            requiredExerciseTypes = try container.decode([String].self, forKey: .requiredExerciseTypes)
            prohibitedExercises = try container.decode([String].self, forKey: .prohibitedExercises)
            minAdherencePercent = try container.decode(Double.self, forKey: .minAdherencePercent)
            maxIntensityPercent = try container.decode(Int.self, forKey: .maxIntensityPercent)

            // Decode rpeRange as array and convert to ClosedRange
            let rangeArray = try container.decode([Int].self, forKey: .rpeRange)
            guard rangeArray.count == 2 else {
                throw DecodingError.dataCorruptedError(forKey: .rpeRange, in: container, debugDescription: "rpeRange must have exactly 2 elements")
            }
            rpeRange = rangeArray[0]...rangeArray[1]
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(maxPainLevel, forKey: .maxPainLevel)
            try container.encode(requiredExerciseTypes, forKey: .requiredExerciseTypes)
            try container.encode(prohibitedExercises, forKey: .prohibitedExercises)
            try container.encode(minAdherencePercent, forKey: .minAdherencePercent)
            try container.encode(maxIntensityPercent, forKey: .maxIntensityPercent)

            // Encode rpeRange as array
            try container.encode([rpeRange.lowerBound, rpeRange.upperBound], forKey: .rpeRange)
        }
    }
    
    // Sample protocols for testing
    static let throwingOnRamp = TherapyProtocol(
        id: UUID(),
        name: "8-Week Throwing On-Ramp",
        description: "Progressive return to throwing program for baseball/softball athletes",
        category: .throwing,
        durationWeeks: 8,
        phases: [
            ProtocolPhase(
                id: UUID(),
                name: "Phase 1: Foundation",
                order: 1,
                durationWeeks: 2,
                goals: ["Establish arm care routine", "Build scapular stability"],
                allowedExerciseCategories: ["shoulder_stability", "arm_care", "mobility"],
                prohibitedExercises: ["overhead_throwing", "weighted_ball"],
                restrictions: ["No throwing", "Focus on mobility"],
                progressionCriteria: ["Pain < 2/10", "Full ROM achieved"]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 2: Light Toss",
                order: 2,
                durationWeeks: 2,
                goals: ["Introduce light throwing", "Build throwing volume tolerance"],
                allowedExerciseCategories: ["light_toss", "arm_care", "shoulder_stability"],
                prohibitedExercises: ["max_effort_throw", "weighted_ball"],
                restrictions: ["Max 30 throws", "45 feet max", "50% effort"],
                progressionCriteria: ["Pain < 3/10", "No velocity drop", "Good command"]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 3: Distance Build",
                order: 3,
                durationWeeks: 2,
                goals: ["Increase throwing distance", "Build arm strength"],
                allowedExerciseCategories: ["distance_toss", "arm_care", "plyometrics"],
                prohibitedExercises: ["max_effort_throw"],
                restrictions: ["Max 60 throws", "Progress to 120 feet", "70% effort"],
                progressionCriteria: ["Pain < 3/10", "Velocity within 3 mph baseline"]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 4: Return to Mound",
                order: 4,
                durationWeeks: 2,
                goals: ["Return to mound throwing", "Build to game intensity"],
                allowedExerciseCategories: ["mound_work", "bullpen", "arm_care"],
                prohibitedExercises: [],
                restrictions: ["Progressive bullpen protocol", "Monitor pitch count"],
                progressionCriteria: ["Pain < 2/10", "Full velocity restored", "Good command"]
            )
        ],
        constraints: ProtocolConstraints(
            minPhases: 4,
            maxPhases: 4,
            canSkipPhases: false,
            canModifyDuration: true,
            requiredExerciseTypes: ["arm_care", "shoulder_stability"],
            prohibitedExercises: ["max_effort_throw", "weighted_ball_max"],
            maxPainLevel: 3,
            minAdherencePercent: 0.80
        ),
        createdAt: Date()
    )
    
    static let shoulderRehab = TherapyProtocol(
        id: UUID(),
        name: "Post-Op Shoulder Rehab",
        description: "Structured rehabilitation following shoulder surgery",
        category: .postSurgical,
        durationWeeks: 12,
        phases: [
            ProtocolPhase(
                id: UUID(),
                name: "Phase 1: Protection",
                order: 1,
                durationWeeks: 3,
                goals: ["Protect surgical repair", "Control pain/inflammation"],
                allowedExerciseCategories: ["passive_rom", "pendulums", "isometric"],
                prohibitedExercises: ["active_elevation", "external_rotation_beyond_30"],
                restrictions: ["Sling for 6 weeks", "No active ROM"],
                progressionCriteria: ["Pain < 3/10", "Minimal swelling"]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 2: Active ROM",
                order: 2,
                durationWeeks: 3,
                goals: ["Restore active ROM", "Begin light strengthening"],
                allowedExerciseCategories: ["active_assisted_rom", "light_resistance", "scapular_strengthening"],
                prohibitedExercises: ["overhead_press", "heavy_weights"],
                restrictions: ["No weights > 3 lbs", "ROM as tolerated"],
                progressionCriteria: ["Active elevation > 120°", "Pain < 3/10"]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 3: Strengthening",
                order: 3,
                durationWeeks: 3,
                goals: ["Progressive strengthening", "Improve function"],
                allowedExerciseCategories: ["progressive_resistance", "functional_movements"],
                prohibitedExercises: [],
                restrictions: ["Progress weights gradually"],
                progressionCriteria: ["Full ROM", "Strength 70% of uninvolved side"]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 4: Return to Activity",
                order: 4,
                durationWeeks: 3,
                goals: ["Sport-specific training", "Return to full activity"],
                allowedExerciseCategories: ["sport_specific", "advanced_strengthening", "plyometrics"],
                prohibitedExercises: [],
                restrictions: ["Gradual return to sport"],
                progressionCriteria: ["Strength 90%+ of uninvolved", "No pain with activity"]
            )
        ],
        constraints: ProtocolConstraints(
            minPhases: 4,
            maxPhases: 5,
            canSkipPhases: false,
            canModifyDuration: true,
            requiredExerciseTypes: ["scapular_strengthening", "rotator_cuff"],
            prohibitedExercises: ["contact_sports_phase1", "overhead_throwing_phase1"],
            maxPainLevel: 4,
            minAdherencePercent: 0.85
        ),
        createdAt: Date()
    )
    
    static let strengthFoundation = TherapyProtocol(
        id: UUID(),
        name: "General Strength Foundation",
        description: "Build overall strength and movement quality",
        category: .strengthBuilding,
        durationWeeks: 6,
        phases: [
            ProtocolPhase(
                id: UUID(),
                name: "Phase 1: Movement Prep",
                order: 1,
                durationWeeks: 2,
                goals: ["Establish movement patterns", "Build work capacity"],
                allowedExerciseCategories: ["bodyweight", "mobility", "basic_lifts"],
                prohibitedExercises: ["max_effort_lifts"],
                restrictions: ["Focus on form over load"],
                progressionCriteria: ["Good movement quality", "No pain"]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 2: Load Introduction",
                order: 2,
                durationWeeks: 2,
                goals: ["Progressive loading", "Build strength"],
                allowedExerciseCategories: ["progressive_resistance", "compound_movements"],
                prohibitedExercises: [],
                restrictions: ["3-4 sets per exercise", "8-12 reps"],
                progressionCriteria: ["Consistent technique", "RPE 6-7"]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 3: Consolidation",
                order: 3,
                durationWeeks: 2,
                goals: ["Solidify gains", "Prepare for specialization"],
                allowedExerciseCategories: ["all"],
                prohibitedExercises: [],
                restrictions: ["Vary rep ranges 5-15"],
                progressionCriteria: ["Strength improvements sustained"]
            )
        ],
        constraints: ProtocolConstraints(
            minPhases: 3,
            maxPhases: 4,
            canSkipPhases: false,
            canModifyDuration: true,
            requiredExerciseTypes: ["squat_pattern", "hinge_pattern", "push", "pull"],
            prohibitedExercises: [],
            maxPainLevel: 4,
            minAdherencePercent: 0.75
        ),
        createdAt: Date()
    )

    static let winterLift = TherapyProtocol(
        id: UUID(),
        name: "Winter Lift 3x/week",
        description: "12-week progressive strength building program with 3 training days per week. Focuses on compound lifts, hypertrophy, and work capacity.",
        category: .strengthBuilding,
        durationWeeks: 12,
        phases: [
            ProtocolPhase(
                id: UUID(),
                name: "Phase 1: Foundation",
                order: 1,
                durationWeeks: 4,
                goals: [
                    "Build base strength",
                    "Establish movement patterns",
                    "Develop work capacity"
                ],
                allowedExerciseCategories: [
                    "compound_lower",
                    "compound_upper",
                    "unilateral",
                    "core",
                    "accessory"
                ],
                prohibitedExercises: [],
                restrictions: [
                    "Max 75% intensity",
                    "RPE 6-7 for primary lifts",
                    "Focus on form over load"
                ],
                progressionCriteria: [
                    "Complete ≥90% of prescribed sessions",
                    "RPE within target range (6-7) for final week",
                    "No pain > 3/10",
                    "Proper form on primary lifts"
                ]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 2: Build",
                order: 2,
                durationWeeks: 4,
                goals: [
                    "Increase load capacity",
                    "Improve time under tension",
                    "Develop strength endurance"
                ],
                allowedExerciseCategories: [
                    "compound_lower",
                    "compound_upper",
                    "unilateral",
                    "core",
                    "plyometric",
                    "accessory"
                ],
                prohibitedExercises: [],
                restrictions: [
                    "Max 88% intensity",
                    "RPE 7-9 for primary lifts",
                    "Progressive overload on primary movements"
                ],
                progressionCriteria: [
                    "Complete ≥90% of prescribed sessions",
                    "RPE within target range (7-9) for primary lifts",
                    "No pain > 3/10",
                    "Progressive overload on primary lifts"
                ]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 3: Intensify",
                order: 3,
                durationWeeks: 4,
                goals: [
                    "Peak strength development",
                    "Explosive power",
                    "Work capacity maintenance"
                ],
                allowedExerciseCategories: [
                    "compound_lower",
                    "compound_upper",
                    "unilateral",
                    "core",
                    "plyometric",
                    "explosive",
                    "accessory"
                ],
                prohibitedExercises: [],
                restrictions: [
                    "Max 92% intensity",
                    "RPE 8-9 for primary lifts",
                    "Monitor bar speed and power output"
                ],
                progressionCriteria: [
                    "Complete ≥90% of prescribed sessions",
                    "RPE within target range (8-9) for primary lifts",
                    "No pain > 2/10",
                    "Maintain or improve bar speed"
                ]
            )
        ],
        constraints: ProtocolConstraints(
            minPhases: 3,
            maxPhases: 3,
            canSkipPhases: false,
            canModifyDuration: true,
            requiredExerciseTypes: [
                "compound_lower",
                "compound_upper",
                "unilateral",
                "core"
            ],
            prohibitedExercises: [],
            maxPainLevel: 3,
            minAdherencePercent: 0.85
        ),
        createdAt: Date()
    )

    // Sample data for picker/testing
    static let sampleProtocols = [
        throwingOnRamp,
        shoulderRehab,
        strengthFoundation,
        winterLift
    ]
}
