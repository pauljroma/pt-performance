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
        case performance = "performance"
        case lifestyle = "lifestyle"
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

    static let performanceExplosive = TherapyProtocol(
        id: UUID(),
        name: "Athletic Performance: Explosive Power",
        description: "8-week program focused on explosive power development for athletes",
        category: .performance,
        durationWeeks: 8,
        phases: [
            ProtocolPhase(
                id: UUID(),
                name: "Phase 1: Strength Base",
                order: 1,
                durationWeeks: 3,
                goals: [
                    "Compound lifts",
                    "Moderate intensity",
                    "Build work capacity"
                ],
                allowedExerciseCategories: [
                    "compound_lower",
                    "compound_upper",
                    "core",
                    "accessory"
                ],
                prohibitedExercises: ["max_effort_plyometrics"],
                restrictions: [
                    "Focus on compound lifts",
                    "Moderate intensity (70-80%)",
                    "Build work capacity foundation"
                ],
                progressionCriteria: [
                    "Complete ≥85% of prescribed sessions",
                    "Pain < 3/10",
                    "Solid compound lift technique"
                ]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 2: Power Development",
                order: 2,
                durationWeeks: 3,
                goals: [
                    "Plyometrics",
                    "Olympic lift variations",
                    "Contrast training"
                ],
                allowedExerciseCategories: [
                    "compound_lower",
                    "compound_upper",
                    "plyometric",
                    "explosive",
                    "olympic_lifts"
                ],
                prohibitedExercises: [],
                restrictions: [
                    "Introduce plyometrics progressively",
                    "Olympic lift variations at moderate load",
                    "Contrast training pairs"
                ],
                progressionCriteria: [
                    "Complete ≥85% of prescribed sessions",
                    "Pain < 3/10",
                    "Power output improving"
                ]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 3: Speed & Peaking",
                order: 3,
                durationWeeks: 2,
                goals: [
                    "Sport-specific power",
                    "Velocity work"
                ],
                allowedExerciseCategories: [
                    "compound_lower",
                    "compound_upper",
                    "plyometric",
                    "explosive",
                    "sport_specific",
                    "velocity"
                ],
                prohibitedExercises: [],
                restrictions: [
                    "Reduce volume",
                    "Maximize velocity and power output",
                    "Sport-specific movement patterns"
                ],
                progressionCriteria: [
                    "Pain < 3/10",
                    "Peak power metrics achieved",
                    "Sport-specific readiness"
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
                "plyometric"
            ],
            prohibitedExercises: [],
            maxPainLevel: 3,
            minAdherencePercent: 0.85
        ),
        createdAt: Date()
    )

    static let performanceEndurance = TherapyProtocol(
        id: UUID(),
        name: "Athletic Performance: Endurance",
        description: "6-week endurance building program for sport-specific conditioning",
        category: .performance,
        durationWeeks: 6,
        phases: [
            ProtocolPhase(
                id: UUID(),
                name: "Phase 1: Aerobic Base",
                order: 1,
                durationWeeks: 2,
                goals: [
                    "Steady-state cardio",
                    "Light resistance",
                    "Build work capacity"
                ],
                allowedExerciseCategories: [
                    "cardio",
                    "endurance",
                    "light_resistance",
                    "mobility"
                ],
                prohibitedExercises: ["max_effort_sprints"],
                restrictions: [
                    "Steady-state cardio focus",
                    "Light resistance only",
                    "Build aerobic base"
                ],
                progressionCriteria: [
                    "Complete ≥80% of prescribed sessions",
                    "Pain < 4/10",
                    "Aerobic base established"
                ]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 2: Threshold Training",
                order: 2,
                durationWeeks: 2,
                goals: [
                    "Interval training",
                    "Tempo work",
                    "Lactate threshold"
                ],
                allowedExerciseCategories: [
                    "cardio",
                    "endurance",
                    "interval_training",
                    "tempo",
                    "resistance"
                ],
                prohibitedExercises: [],
                restrictions: [
                    "Interval training progression",
                    "Tempo work at threshold pace",
                    "Monitor heart rate zones"
                ],
                progressionCriteria: [
                    "Complete ≥80% of prescribed sessions",
                    "Pain < 4/10",
                    "Threshold pace improving"
                ]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 3: Race-Specific",
                order: 3,
                durationWeeks: 2,
                goals: [
                    "Sport-specific conditioning",
                    "Taper"
                ],
                allowedExerciseCategories: [
                    "cardio",
                    "endurance",
                    "sport_specific",
                    "taper",
                    "active_recovery"
                ],
                prohibitedExercises: [],
                restrictions: [
                    "Sport-specific conditioning focus",
                    "Progressive taper",
                    "Recovery prioritized"
                ],
                progressionCriteria: [
                    "Pain < 4/10",
                    "Race-specific readiness",
                    "Freshness and confidence"
                ]
            )
        ],
        constraints: ProtocolConstraints(
            minPhases: 3,
            maxPhases: 3,
            canSkipPhases: false,
            canModifyDuration: true,
            requiredExerciseTypes: [
                "cardio",
                "endurance"
            ],
            prohibitedExercises: [],
            maxPainLevel: 4,
            minAdherencePercent: 0.80
        ),
        createdAt: Date()
    )

    static let lifestyleWellness = TherapyProtocol(
        id: UUID(),
        name: "Lifestyle: Daily Wellness",
        description: "4-week gentle wellness routine focused on mobility, light strength, and daily movement habits",
        category: .lifestyle,
        durationWeeks: 4,
        phases: [
            ProtocolPhase(
                id: UUID(),
                name: "Phase 1: Foundation Habits",
                order: 1,
                durationWeeks: 2,
                goals: [
                    "Basic mobility",
                    "Walking",
                    "Bodyweight movements",
                    "Establish routine"
                ],
                allowedExerciseCategories: [
                    "mobility",
                    "bodyweight",
                    "walking",
                    "stretching"
                ],
                prohibitedExercises: ["heavy_resistance"],
                restrictions: [
                    "Gentle movements only",
                    "Focus on habit formation",
                    "Daily consistency over intensity"
                ],
                progressionCriteria: [
                    "Complete ≥60% of prescribed sessions",
                    "Pain < 5/10",
                    "Routine established"
                ]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 2: Habit Consolidation",
                order: 2,
                durationWeeks: 2,
                goals: [
                    "Progressive volume",
                    "Consistency building"
                ],
                allowedExerciseCategories: [
                    "mobility",
                    "bodyweight",
                    "walking",
                    "stretching",
                    "light_resistance"
                ],
                prohibitedExercises: ["heavy_resistance"],
                restrictions: [
                    "Progressive volume increase",
                    "Maintain consistency",
                    "Listen to body"
                ],
                progressionCriteria: [
                    "Complete ≥60% of prescribed sessions",
                    "Pain < 5/10",
                    "Habits consolidated"
                ]
            )
        ],
        constraints: ProtocolConstraints(
            minPhases: 2,
            maxPhases: 3,
            canSkipPhases: true,
            canModifyDuration: true,
            requiredExerciseTypes: [
                "mobility",
                "bodyweight"
            ],
            prohibitedExercises: [],
            maxPainLevel: 5,
            minAdherencePercent: 0.60
        ),
        createdAt: Date()
    )

    static let lifestyleActiveAging = TherapyProtocol(
        id: UUID(),
        name: "Lifestyle: Active Aging",
        description: "6-week program for maintaining strength, balance, and mobility as you age",
        category: .lifestyle,
        durationWeeks: 6,
        phases: [
            ProtocolPhase(
                id: UUID(),
                name: "Phase 1: Balance & Stability",
                order: 1,
                durationWeeks: 2,
                goals: [
                    "Balance exercises",
                    "Fall prevention",
                    "Proprioception"
                ],
                allowedExerciseCategories: [
                    "balance",
                    "functional_strength",
                    "mobility",
                    "proprioception"
                ],
                prohibitedExercises: ["heavy_resistance", "high_impact"],
                restrictions: [
                    "Balance exercises with support available",
                    "Fall prevention focus",
                    "Proprioception training"
                ],
                progressionCriteria: [
                    "Complete ≥70% of prescribed sessions",
                    "Pain < 4/10",
                    "Improved balance confidence"
                ]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 2: Strength & Function",
                order: 2,
                durationWeeks: 2,
                goals: [
                    "Functional strength",
                    "Daily task simulation"
                ],
                allowedExerciseCategories: [
                    "balance",
                    "functional_strength",
                    "mobility",
                    "light_resistance",
                    "daily_function"
                ],
                prohibitedExercises: ["heavy_resistance", "high_impact"],
                restrictions: [
                    "Functional movement patterns",
                    "Simulate daily activities",
                    "Progressive resistance with caution"
                ],
                progressionCriteria: [
                    "Complete ≥70% of prescribed sessions",
                    "Pain < 4/10",
                    "Improved functional strength"
                ]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 3: Independence & Vitality",
                order: 3,
                durationWeeks: 2,
                goals: [
                    "Combined training",
                    "Confidence building"
                ],
                allowedExerciseCategories: [
                    "balance",
                    "functional_strength",
                    "mobility",
                    "light_resistance",
                    "daily_function",
                    "combined_training"
                ],
                prohibitedExercises: ["heavy_resistance", "high_impact"],
                restrictions: [
                    "Combined balance and strength work",
                    "Build independence",
                    "Celebrate progress"
                ],
                progressionCriteria: [
                    "Complete ≥70% of prescribed sessions",
                    "Pain < 4/10",
                    "Confidence and independence improved"
                ]
            )
        ],
        constraints: ProtocolConstraints(
            minPhases: 3,
            maxPhases: 4,
            canSkipPhases: true,
            canModifyDuration: true,
            requiredExerciseTypes: [
                "balance",
                "functional_strength"
            ],
            prohibitedExercises: [],
            maxPainLevel: 4,
            minAdherencePercent: 0.70
        ),
        createdAt: Date()
    )

    static let lifestyleStressRelief = TherapyProtocol(
        id: UUID(),
        name: "Lifestyle: Stress Relief & Recovery",
        description: "4-week stress management program combining breathwork, mobility, and active recovery",
        category: .lifestyle,
        durationWeeks: 4,
        phases: [
            ProtocolPhase(
                id: UUID(),
                name: "Phase 1: Breathwork & Mobility",
                order: 1,
                durationWeeks: 2,
                goals: [
                    "Breathing exercises",
                    "Yoga-inspired flows",
                    "Gentle stretching"
                ],
                allowedExerciseCategories: [
                    "mobility",
                    "breathing",
                    "yoga",
                    "stretching"
                ],
                prohibitedExercises: ["high_intensity", "heavy_resistance"],
                restrictions: [
                    "Breathing exercises daily",
                    "Yoga-inspired flows",
                    "Gentle stretching only"
                ],
                progressionCriteria: [
                    "Complete ≥60% of prescribed sessions",
                    "Pain < 5/10",
                    "Breathwork routine established"
                ]
            ),
            ProtocolPhase(
                id: UUID(),
                name: "Phase 2: Active Recovery",
                order: 2,
                durationWeeks: 2,
                goals: [
                    "Light movement",
                    "Foam rolling",
                    "Progressive relaxation"
                ],
                allowedExerciseCategories: [
                    "mobility",
                    "breathing",
                    "foam_rolling",
                    "active_recovery",
                    "relaxation"
                ],
                prohibitedExercises: ["high_intensity", "heavy_resistance"],
                restrictions: [
                    "Light movement only",
                    "Foam rolling and self-massage",
                    "Progressive relaxation techniques"
                ],
                progressionCriteria: [
                    "Complete ≥60% of prescribed sessions",
                    "Pain < 5/10",
                    "Stress management skills developed"
                ]
            )
        ],
        constraints: ProtocolConstraints(
            minPhases: 2,
            maxPhases: 2,
            canSkipPhases: false,
            canModifyDuration: true,
            requiredExerciseTypes: [
                "mobility",
                "breathing"
            ],
            prohibitedExercises: [],
            maxPainLevel: 5,
            minAdherencePercent: 0.60
        ),
        createdAt: Date()
    )

    // Sample data for picker/testing
    static let sampleProtocols = [
        throwingOnRamp,
        shoulderRehab,
        strengthFoundation,
        winterLift,
        performanceExplosive,
        performanceEndurance,
        lifestyleWellness,
        lifestyleActiveAging,
        lifestyleStressRelief
    ]
}

// MARK: - Protocol Template (X2Index PT Workflow)

struct ProtocolTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: ProtocolCategory
    let description: String
    let defaultDurationDays: Int
    let tasks: [ProtocolTask]
    let isActive: Bool

    enum ProtocolCategory: String, Codable, CaseIterable {
        case recovery
        case returnToPlay
        case performance
        case injury
        case maintenance

        var displayName: String {
            switch self {
            case .recovery: return "Recovery"
            case .returnToPlay: return "Return to Play"
            case .performance: return "Performance"
            case .injury: return "Injury"
            case .maintenance: return "Maintenance"
            }
        }

        var iconName: String {
            switch self {
            case .recovery: return "arrow.counterclockwise.circle"
            case .returnToPlay: return "figure.run"
            case .performance: return "bolt.fill"
            case .injury: return "cross.circle"
            case .maintenance: return "wrench.and.screwdriver"
            }
        }

        var color: String {
            switch self {
            case .recovery: return "blue"
            case .returnToPlay: return "green"
            case .performance: return "orange"
            case .injury: return "red"
            case .maintenance: return "purple"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, category, description, tasks
        case defaultDurationDays = "default_duration_days"
        case isActive = "is_active"
    }

    var estimatedDuration: String {
        if defaultDurationDays == 1 {
            return "1 day"
        } else if defaultDurationDays < 7 {
            return "\(defaultDurationDays) days"
        } else {
            let weeks = defaultDurationDays / 7
            return weeks == 1 ? "1 week" : "\(weeks) weeks"
        }
    }

    var taskCount: Int {
        tasks.count
    }
}

// MARK: - Protocol Task

struct ProtocolTask: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let description: String?
    let taskType: TaskType
    let frequency: TaskFrequency
    let defaultTime: String? // "08:00"
    let durationMinutes: Int?
    let instructions: String?

    enum TaskType: String, Codable, CaseIterable {
        case exercise
        case stretch
        case ice
        case heat
        case rest
        case medication
        case checkIn
        case appointment

        var displayName: String {
            switch self {
            case .exercise: return "Exercise"
            case .stretch: return "Stretch"
            case .ice: return "Ice"
            case .heat: return "Heat"
            case .rest: return "Rest"
            case .medication: return "Medication"
            case .checkIn: return "Check-In"
            case .appointment: return "Appointment"
            }
        }

        var iconName: String {
            switch self {
            case .exercise: return "figure.strengthtraining.traditional"
            case .stretch: return "figure.flexibility"
            case .ice: return "snowflake"
            case .heat: return "flame"
            case .rest: return "bed.double"
            case .medication: return "pills"
            case .checkIn: return "checkmark.message"
            case .appointment: return "calendar.badge.clock"
            }
        }

        var color: String {
            switch self {
            case .exercise: return "green"
            case .stretch: return "purple"
            case .ice: return "cyan"
            case .heat: return "orange"
            case .rest: return "blue"
            case .medication: return "pink"
            case .checkIn: return "teal"
            case .appointment: return "indigo"
            }
        }
    }

    enum TaskFrequency: String, Codable, CaseIterable {
        case daily
        case twiceDaily
        case everyOtherDay
        case weekly
        case asNeeded

        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .twiceDaily: return "Twice Daily"
            case .everyOtherDay: return "Every Other Day"
            case .weekly: return "Weekly"
            case .asNeeded: return "As Needed"
            }
        }

        var occurrencesPerWeek: Double {
            switch self {
            case .daily: return 7.0
            case .twiceDaily: return 14.0
            case .everyOtherDay: return 3.5
            case .weekly: return 1.0
            case .asNeeded: return 0.0
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, frequency, instructions
        case taskType = "task_type"
        case defaultTime = "default_time"
        case durationMinutes = "duration_minutes"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ProtocolTask, rhs: ProtocolTask) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Athlete Plan

struct AthletePlan: Codable, Identifiable {
    let id: UUID
    let athleteId: UUID
    let protocolId: UUID
    let startDate: Date
    let endDate: Date
    let assignedBy: UUID
    var tasks: [AssignedTask]
    var status: PlanStatus
    var notes: String?
    let createdAt: Date

    enum PlanStatus: String, Codable, CaseIterable {
        case active
        case completed
        case paused
        case cancelled

        var displayName: String {
            switch self {
            case .active: return "Active"
            case .completed: return "Completed"
            case .paused: return "Paused"
            case .cancelled: return "Cancelled"
            }
        }

        var color: String {
            switch self {
            case .active: return "green"
            case .completed: return "blue"
            case .paused: return "yellow"
            case .cancelled: return "gray"
            }
        }

        var iconName: String {
            switch self {
            case .active: return "play.circle.fill"
            case .completed: return "checkmark.circle.fill"
            case .paused: return "pause.circle.fill"
            case .cancelled: return "xmark.circle.fill"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, status, notes, tasks
        case athleteId = "athlete_id"
        case protocolId = "protocol_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case assignedBy = "assigned_by"
        case createdAt = "created_at"
    }

    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        let completedCount = tasks.filter { $0.status == .completed }.count
        return Double(completedCount) / Double(tasks.count)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0)
    }

    var totalDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    var daysElapsed: Int {
        max(0, Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0)
    }

    var completedTasks: Int {
        tasks.filter { $0.status == .completed }.count
    }

    var pendingTasks: Int {
        tasks.filter { $0.status == .pending }.count
    }

    var overdueTasks: Int {
        tasks.filter { $0.status == .overdue }.count
    }

    var todaysTasks: [AssignedTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return tasks.filter { calendar.startOfDay(for: $0.dueDate) == today }
    }
}

// MARK: - Assigned Task

struct AssignedTask: Codable, Identifiable {
    let id: UUID
    let planId: UUID
    let title: String
    let taskType: ProtocolTask.TaskType
    let dueDate: Date
    let dueTime: String?
    var status: TaskStatus
    var completedAt: Date?
    var notes: String?

    enum TaskStatus: String, Codable, CaseIterable {
        case pending
        case completed
        case skipped
        case overdue

        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .completed: return "Completed"
            case .skipped: return "Skipped"
            case .overdue: return "Overdue"
            }
        }

        var iconName: String {
            switch self {
            case .pending: return "circle"
            case .completed: return "checkmark.circle.fill"
            case .skipped: return "arrow.right.circle"
            case .overdue: return "exclamationmark.circle"
            }
        }

        var color: String {
            switch self {
            case .pending: return "gray"
            case .completed: return "green"
            case .skipped: return "orange"
            case .overdue: return "red"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, title, status, notes
        case planId = "plan_id"
        case taskType = "task_type"
        case dueDate = "due_date"
        case dueTime = "due_time"
        case completedAt = "completed_at"
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(dueDate)
    }

    var isPast: Bool {
        dueDate < Date() && !isToday
    }

    var formattedDueTime: String? {
        guard let dueTime = dueTime else { return nil }
        let components = dueTime.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return dueTime
        }

        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        guard let date = calendar.date(from: dateComponents) else {
            return dueTime
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Plan Customization

struct PlanCustomization {
    var startDate: Date
    var endDate: Date
    var taskCustomizations: [UUID: TaskCustomization]
    var notes: String?

    struct TaskCustomization {
        var isIncluded: Bool
        var customTime: String?
        var reminderEnabled: Bool
        var customInstructions: String?

        init(
            isIncluded: Bool = true,
            customTime: String? = nil,
            reminderEnabled: Bool = true,
            customInstructions: String? = nil
        ) {
            self.isIncluded = isIncluded
            self.customTime = customTime
            self.reminderEnabled = reminderEnabled
            self.customInstructions = customInstructions
        }
    }

    init(template: ProtocolTemplate) {
        self.startDate = Date()
        self.endDate = Calendar.current.date(byAdding: .day, value: template.defaultDurationDays, to: Date()) ?? Date()
        self.taskCustomizations = Dictionary(uniqueKeysWithValues: template.tasks.map { task in
            (task.id, TaskCustomization(
                isIncluded: true,
                customTime: task.defaultTime,
                reminderEnabled: true,
                customInstructions: nil
            ))
        })
        self.notes = nil
    }

    var includedTaskCount: Int {
        taskCustomizations.values.filter { $0.isIncluded }.count
    }

    mutating func toggleTask(_ taskId: UUID) {
        if var customization = taskCustomizations[taskId] {
            customization.isIncluded.toggle()
            taskCustomizations[taskId] = customization
        }
    }

    mutating func setTaskTime(_ taskId: UUID, time: String?) {
        if var customization = taskCustomizations[taskId] {
            customization.customTime = time
            taskCustomizations[taskId] = customization
        }
    }

    mutating func setTaskReminder(_ taskId: UUID, enabled: Bool) {
        if var customization = taskCustomizations[taskId] {
            customization.reminderEnabled = enabled
            taskCustomizations[taskId] = customization
        }
    }

    mutating func setTaskInstructions(_ taskId: UUID, instructions: String?) {
        if var customization = taskCustomizations[taskId] {
            customization.customInstructions = instructions
            taskCustomizations[taskId] = customization
        }
    }
}

// MARK: - Sample Protocol Templates

extension ProtocolTemplate {
    static let postWorkoutRecovery = ProtocolTemplate(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        name: "Post-Workout Recovery",
        category: .recovery,
        description: "Comprehensive recovery routine for post-workout muscle recovery and soreness prevention",
        defaultDurationDays: 3,
        tasks: [
            ProtocolTask(
                id: UUID(),
                title: "Static Stretching Routine",
                description: "Full body static stretch sequence",
                taskType: .stretch,
                frequency: .daily,
                defaultTime: "18:00",
                durationMinutes: 15,
                instructions: "Hold each stretch for 30 seconds. Focus on major muscle groups worked during training."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Foam Rolling Session",
                description: "Self-myofascial release",
                taskType: .exercise,
                frequency: .daily,
                defaultTime: "19:00",
                durationMinutes: 10,
                instructions: "Roll slowly over each muscle group. Pause on tender spots for 30 seconds."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Ice Bath / Cold Therapy",
                description: "Cold water immersion for recovery",
                taskType: .ice,
                frequency: .daily,
                defaultTime: "19:30",
                durationMinutes: 10,
                instructions: "10 minutes in cold water (50-59F). Focus on lower body immersion."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Recovery Check-In",
                description: "Rate soreness and recovery status",
                taskType: .checkIn,
                frequency: .daily,
                defaultTime: "08:00",
                durationMinutes: 2,
                instructions: "Rate muscle soreness 1-10 and note any areas of concern."
            )
        ],
        isActive: true
    )

    static let returnToTraining = ProtocolTemplate(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        name: "Return to Training (Mild Strain)",
        category: .returnToPlay,
        description: "Progressive return protocol following mild muscle strain with gradual load increase",
        defaultDurationDays: 14,
        tasks: [
            ProtocolTask(
                id: UUID(),
                title: "Gentle Mobility Work",
                description: "Pain-free range of motion exercises",
                taskType: .stretch,
                frequency: .twiceDaily,
                defaultTime: "07:00",
                durationMinutes: 10,
                instructions: "Move through pain-free range only. Stop if pain exceeds 3/10."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Ice Application",
                description: "Apply ice to affected area",
                taskType: .ice,
                frequency: .daily,
                defaultTime: "20:00",
                durationMinutes: 15,
                instructions: "Apply ice pack wrapped in cloth for 15 minutes. Do not apply directly to skin."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Progressive Loading Exercise",
                description: "Gradual strength rebuilding",
                taskType: .exercise,
                frequency: .everyOtherDay,
                defaultTime: "10:00",
                durationMinutes: 20,
                instructions: "Start with bodyweight, progress to light resistance as tolerated."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Pain & Function Check-In",
                description: "Daily symptom monitoring",
                taskType: .checkIn,
                frequency: .daily,
                defaultTime: "21:00",
                durationMinutes: 3,
                instructions: "Rate pain at rest and with movement. Note any improvements or setbacks."
            ),
            ProtocolTask(
                id: UUID(),
                title: "PT Follow-Up Appointment",
                description: "Progress evaluation with PT",
                taskType: .appointment,
                frequency: .weekly,
                defaultTime: "14:00",
                durationMinutes: 45,
                instructions: "Bring completed check-in logs. Be prepared to demonstrate movement quality."
            )
        ],
        isActive: true
    )

    static let performanceOptimization = ProtocolTemplate(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        name: "Performance Optimization",
        category: .performance,
        description: "Peak performance protocol combining activation, recovery, and readiness optimization",
        defaultDurationDays: 7,
        tasks: [
            ProtocolTask(
                id: UUID(),
                title: "Morning Activation Routine",
                description: "Dynamic warm-up and neural activation",
                taskType: .exercise,
                frequency: .daily,
                defaultTime: "06:30",
                durationMinutes: 15,
                instructions: "Dynamic stretches, activation drills, light plyometrics."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Pre-Training Prep",
                description: "Sport-specific warm-up",
                taskType: .exercise,
                frequency: .daily,
                defaultTime: "15:00",
                durationMinutes: 20,
                instructions: "Movement preparation specific to training focus."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Post-Training Flush",
                description: "Active recovery work",
                taskType: .stretch,
                frequency: .daily,
                defaultTime: "18:00",
                durationMinutes: 10,
                instructions: "Light cardio followed by stretching and mobility."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Readiness Assessment",
                description: "Daily performance readiness check",
                taskType: .checkIn,
                frequency: .daily,
                defaultTime: "07:00",
                durationMinutes: 5,
                instructions: "Rate sleep quality, energy, motivation, and physical readiness."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Contrast Therapy",
                description: "Hot/cold alternating therapy",
                taskType: .heat,
                frequency: .everyOtherDay,
                defaultTime: "19:00",
                durationMinutes: 20,
                instructions: "3 min hot, 1 min cold. Repeat 4 times. End on cold."
            )
        ],
        isActive: true
    )

    static let sleepImprovement = ProtocolTemplate(
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        name: "Sleep Improvement Protocol",
        category: .maintenance,
        description: "Evidence-based sleep hygiene and recovery optimization program",
        defaultDurationDays: 21,
        tasks: [
            ProtocolTask(
                id: UUID(),
                title: "Evening Wind-Down Routine",
                description: "Relaxation and sleep preparation",
                taskType: .rest,
                frequency: .daily,
                defaultTime: "21:00",
                durationMinutes: 30,
                instructions: "Dim lights, no screens, gentle stretching or breathing exercises."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Sleep Environment Check",
                description: "Optimize bedroom conditions",
                taskType: .checkIn,
                frequency: .weekly,
                defaultTime: "20:00",
                durationMinutes: 10,
                instructions: "Check room temp (65-68F), darkness, noise levels. Make adjustments as needed."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Morning Light Exposure",
                description: "Natural light for circadian rhythm",
                taskType: .exercise,
                frequency: .daily,
                defaultTime: "07:00",
                durationMinutes: 15,
                instructions: "Get outside within 30 min of waking. 10-15 min of natural light exposure."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Sleep Quality Log",
                description: "Track sleep metrics",
                taskType: .checkIn,
                frequency: .daily,
                defaultTime: "08:00",
                durationMinutes: 2,
                instructions: "Record: bedtime, wake time, perceived quality (1-10), interruptions."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Gentle Evening Stretch",
                description: "Relaxation stretching routine",
                taskType: .stretch,
                frequency: .daily,
                defaultTime: "21:30",
                durationMinutes: 10,
                instructions: "Slow, relaxing stretches. Focus on breathing. Avoid stimulating movements."
            )
        ],
        isActive: true
    )

    static let stressManagement = ProtocolTemplate(
        id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
        name: "Stress Management",
        category: .maintenance,
        description: "Holistic stress reduction protocol combining movement, breathing, and mindfulness",
        defaultDurationDays: 14,
        tasks: [
            ProtocolTask(
                id: UUID(),
                title: "Morning Breathwork",
                description: "Box breathing or 4-7-8 technique",
                taskType: .rest,
                frequency: .daily,
                defaultTime: "06:30",
                durationMinutes: 10,
                instructions: "Box breathing: 4 sec inhale, 4 sec hold, 4 sec exhale, 4 sec hold. Repeat 10 cycles."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Midday Movement Break",
                description: "Active stress relief",
                taskType: .exercise,
                frequency: .daily,
                defaultTime: "12:00",
                durationMinutes: 15,
                instructions: "Walk, stretch, or light movement. Get away from desk/work area."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Evening Decompression",
                description: "End-of-day stress release",
                taskType: .stretch,
                frequency: .daily,
                defaultTime: "18:00",
                durationMinutes: 20,
                instructions: "Yoga-inspired flow or gentle stretching. Focus on hip openers and shoulder release."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Stress Level Check-In",
                description: "Monitor stress patterns",
                taskType: .checkIn,
                frequency: .twiceDaily,
                defaultTime: "09:00",
                durationMinutes: 2,
                instructions: "Rate stress 1-10. Note triggers. Identify one positive moment."
            ),
            ProtocolTask(
                id: UUID(),
                title: "Progressive Muscle Relaxation",
                description: "Tension release technique",
                taskType: .rest,
                frequency: .daily,
                defaultTime: "21:00",
                durationMinutes: 15,
                instructions: "Systematically tense and release each muscle group. Start from feet, work to head."
            )
        ],
        isActive: true
    )

    static let sampleTemplates: [ProtocolTemplate] = [
        .postWorkoutRecovery,
        .returnToTraining,
        .performanceOptimization,
        .sleepImprovement,
        .stressManagement
    ]
}

// MARK: - TaskType SwiftUI Extensions

import SwiftUI

extension ProtocolTask.TaskType {
    /// SF Symbol icon name for the task type
    var icon: String {
        switch self {
        case .exercise: return "figure.run"
        case .stretch: return "figure.flexibility"
        case .ice: return "snowflake"
        case .heat: return "flame.fill"
        case .rest: return "bed.double.fill"
        case .medication: return "pills.fill"
        case .checkIn: return "checkmark.circle.fill"
        case .appointment: return "calendar"
        }
    }

    /// SwiftUI Color for the task type
    var swiftUIColor: Color {
        switch self {
        case .exercise: return .orange
        case .stretch: return .purple
        case .ice: return .cyan
        case .heat: return .red
        case .rest: return .blue
        case .medication: return .green
        case .checkIn: return .modusTealAccent
        case .appointment: return .modusCyan
        }
    }
}
