import Foundation
import SwiftUI

// MARK: - Workout Adaptation Models

/// Recommended workout modification based on readiness
struct WorkoutAdaptation: Sendable {
    let recommendationType: AdaptationType
    let scalingFactors: ScalingFactors
    let alternativeWorkouts: [AlternativeWorkout]
    let deloadProtocol: DeloadProtocol?
    let message: String
    let detailedRecommendation: String
    let recoveryTips: [RecoveryTip]

    enum AdaptationType: String, Sendable, CaseIterable {
        case fullIntensity = "full_intensity"
        case slightReduction = "slight_reduction"
        case moderateReduction = "moderate_reduction"
        case lightActivity = "light_activity"
        case restDay = "rest_day"
        case deloadRecommended = "deload_recommended"

        var displayName: String {
            switch self {
            case .fullIntensity: return "Full Intensity"
            case .slightReduction: return "Slight Reduction"
            case .moderateReduction: return "Moderate Reduction"
            case .lightActivity: return "Light Activity"
            case .restDay: return "Rest Day"
            case .deloadRecommended: return "Deload Recommended"
            }
        }

        var icon: String {
            switch self {
            case .fullIntensity: return "flame.fill"
            case .slightReduction: return "gauge.high"
            case .moderateReduction: return "gauge.medium"
            case .lightActivity: return "figure.walk"
            case .restDay: return "bed.double.fill"
            case .deloadRecommended: return "arrow.down.to.line"
            }
        }

        var color: Color {
            switch self {
            case .fullIntensity: return .green
            case .slightReduction: return .blue
            case .moderateReduction: return .yellow
            case .lightActivity: return .orange
            case .restDay: return .purple
            case .deloadRecommended: return .red
            }
        }
    }
}

/// Scaling factors for workout parameters
struct ScalingFactors: Sendable {
    let intensityMultiplier: Double    // e.g., 0.85 = 15% reduction
    let volumeMultiplier: Double       // e.g., 0.70 = 30% reduction
    let setsReduction: Int             // Number of sets to drop per exercise
    let rpeTarget: Int?                // Target RPE if applicable
    let restMultiplier: Double         // Rest period multiplier (>1 means more rest)

    /// Create scaling factors from readiness score
    static func fromReadinessScore(_ score: Double) -> ScalingFactors {
        if score >= 80 {
            return ScalingFactors(
                intensityMultiplier: 1.0,
                volumeMultiplier: 1.0,
                setsReduction: 0,
                rpeTarget: nil,
                restMultiplier: 1.0
            )
        } else if score >= 60 {
            return ScalingFactors(
                intensityMultiplier: 0.95,
                volumeMultiplier: 0.90,
                setsReduction: 0,
                rpeTarget: 7,
                restMultiplier: 1.1
            )
        } else if score >= 40 {
            return ScalingFactors(
                intensityMultiplier: 0.85,
                volumeMultiplier: 0.75,
                setsReduction: 1,
                rpeTarget: 6,
                restMultiplier: 1.25
            )
        } else if score >= 25 {
            return ScalingFactors(
                intensityMultiplier: 0.70,
                volumeMultiplier: 0.60,
                setsReduction: 2,
                rpeTarget: 5,
                restMultiplier: 1.5
            )
        } else {
            // Very low readiness - rest recommended
            return ScalingFactors(
                intensityMultiplier: 0.50,
                volumeMultiplier: 0.40,
                setsReduction: 3,
                rpeTarget: 4,
                restMultiplier: 2.0
            )
        }
    }

    /// Formatted intensity reduction for display
    var intensityReductionText: String {
        if intensityMultiplier >= 1.0 {
            return "No reduction"
        }
        let reduction = Int((1.0 - intensityMultiplier) * 100)
        return "\(reduction)% reduction"
    }

    /// Formatted volume reduction for display
    var volumeReductionText: String {
        if volumeMultiplier >= 1.0 {
            return "No reduction"
        }
        let reduction = Int((1.0 - volumeMultiplier) * 100)
        return "\(reduction)% reduction"
    }
}

/// Alternative workout suggestion
struct AlternativeWorkout: Identifiable, Sendable {
    let id: UUID
    let name: String
    let type: WorkoutType
    let duration: Int               // Minutes
    let intensity: Intensity
    let description: String
    let benefits: [String]

    enum WorkoutType: String, Sendable {
        case mobility = "mobility"
        case yoga = "yoga"
        case walking = "walking"
        case swimming = "swimming"
        case lightCardio = "light_cardio"
        case stretching = "stretching"
        case breathwork = "breathwork"
        case meditation = "meditation"

        var displayName: String {
            switch self {
            case .mobility: return "Mobility Work"
            case .yoga: return "Yoga"
            case .walking: return "Walking"
            case .swimming: return "Swimming"
            case .lightCardio: return "Light Cardio"
            case .stretching: return "Stretching"
            case .breathwork: return "Breathwork"
            case .meditation: return "Meditation"
            }
        }

        var icon: String {
            switch self {
            case .mobility: return "figure.flexibility"
            case .yoga: return "figure.mind.and.body"
            case .walking: return "figure.walk"
            case .swimming: return "figure.pool.swim"
            case .lightCardio: return "figure.run"
            case .stretching: return "figure.cooldown"
            case .breathwork: return "wind"
            case .meditation: return "brain.head.profile"
            }
        }
    }

    enum Intensity: String, Sendable {
        case veryLight = "very_light"
        case light = "light"
        case moderate = "moderate"

        var displayName: String {
            switch self {
            case .veryLight: return "Very Light"
            case .light: return "Light"
            case .moderate: return "Moderate"
            }
        }
    }
}

/// Deload protocol specification
struct DeloadProtocol: Sendable {
    let durationDays: Int
    let loadReduction: Double
    let volumeReduction: Double
    let frequency: DeloadFrequency
    let focus: DeloadFocusArea
    let weeklySchedule: [DayPlan]
    let nutritionGuidelines: [String]
    let sleepGuidelines: [String]

    enum DeloadFrequency: String, Sendable {
        case everySession = "every_session"
        case alternateSession = "alternate_session"
        case reducedDays = "reduced_days"

        var description: String {
            switch self {
            case .everySession: return "Train every scheduled session at reduced intensity"
            case .alternateSession: return "Train every other scheduled session"
            case .reducedDays: return "Reduce training days this week"
            }
        }
    }

    enum DeloadFocusArea: String, Sendable {
        case technique = "technique"
        case mobility = "mobility"
        case activeRecovery = "active_recovery"
        case mentalReset = "mental_reset"

        var displayName: String {
            switch self {
            case .technique: return "Technique Focus"
            case .mobility: return "Mobility Focus"
            case .activeRecovery: return "Active Recovery"
            case .mentalReset: return "Mental Reset"
            }
        }

        var description: String {
            switch self {
            case .technique:
                return "Focus on movement quality with lighter loads"
            case .mobility:
                return "Prioritize flexibility and joint health"
            case .activeRecovery:
                return "Light movement to promote blood flow"
            case .mentalReset:
                return "Take a mental break from intense training"
            }
        }
    }

    struct DayPlan: Sendable {
        let dayNumber: Int
        let activity: String
        let duration: Int?  // Minutes
        let notes: String?
    }
}

/// Recovery tip suggestion
struct RecoveryTip: Identifiable, Sendable {
    let id: UUID
    let category: Category
    let title: String
    let description: String
    let priority: Priority

    enum Category: String, Sendable, CaseIterable {
        case sleep = "sleep"
        case nutrition = "nutrition"
        case hydration = "hydration"
        case mobility = "mobility"
        case stress = "stress"
        case activity = "activity"

        var displayName: String {
            rawValue.capitalized
        }

        var icon: String {
            switch self {
            case .sleep: return "moon.fill"
            case .nutrition: return "fork.knife"
            case .hydration: return "drop.fill"
            case .mobility: return "figure.flexibility"
            case .stress: return "brain.head.profile"
            case .activity: return "figure.walk"
            }
        }

        var color: Color {
            switch self {
            case .sleep: return .indigo
            case .nutrition: return .green
            case .hydration: return .blue
            case .mobility: return .orange
            case .stress: return .purple
            case .activity: return .mint
            }
        }
    }

    enum Priority: Int, Sendable, Comparable {
        case high = 1
        case medium = 2
        case low = 3

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

// MARK: - Workout Adaptation Service

/// Service for adapting workouts based on readiness and recovery status
/// Provides intelligent recommendations for workout modifications, alternatives,
/// and deload protocols based on the user's current readiness state.
@MainActor
class WorkoutAdaptationService: ObservableObject {

    // MARK: - Singleton

    static let shared = WorkoutAdaptationService()

    // MARK: - Published Properties

    @Published var currentAdaptation: WorkoutAdaptation?
    @Published var isLoading: Bool = false
    @Published var error: String?

    // MARK: - Dependencies

    private let readinessService: ReadinessService
    private let healthKitService: HealthKitService

    // MARK: - Initialization

    nonisolated init(
        readinessService: ReadinessService = ReadinessService(),
        healthKitService: HealthKitService = .shared
    ) {
        self.readinessService = readinessService
        self.healthKitService = healthKitService
    }

    // MARK: - Public Methods

    /// Get workout adaptation based on current readiness
    /// - Parameter patientId: Patient UUID
    /// - Returns: WorkoutAdaptation with recommendations
    func getWorkoutAdaptation(for patientId: UUID) async throws -> WorkoutAdaptation {
        isLoading = true
        defer { isLoading = false }

        // Get composite readiness score
        let compositeScore = try await readinessService.calculateCompositeReadiness(
            for: patientId,
            using: healthKitService
        )

        // Generate adaptation based on score
        let adaptation = generateAdaptation(from: compositeScore)

        currentAdaptation = adaptation
        return adaptation
    }

    /// Get workout adaptation from a pre-calculated readiness score
    /// - Parameter score: Pre-calculated composite readiness score
    /// - Returns: WorkoutAdaptation with recommendations
    func getWorkoutAdaptation(from score: CompositeReadinessScore) -> WorkoutAdaptation {
        let adaptation = generateAdaptation(from: score)
        currentAdaptation = adaptation
        return adaptation
    }

    /// Apply scaling factors to a workout weight
    /// - Parameters:
    ///   - baseWeight: Original prescribed weight
    ///   - readinessScore: Current readiness score
    /// - Returns: Adjusted weight
    func adjustWeight(_ baseWeight: Double, for readinessScore: Double) -> Double {
        let factors = ScalingFactors.fromReadinessScore(readinessScore)
        return baseWeight * factors.intensityMultiplier
    }

    /// Apply scaling factors to workout volume (sets x reps)
    /// - Parameters:
    ///   - baseSets: Original prescribed sets
    ///   - baseReps: Original prescribed reps
    ///   - readinessScore: Current readiness score
    /// - Returns: Tuple of adjusted (sets, reps)
    func adjustVolume(sets baseSets: Int, reps baseReps: Int, for readinessScore: Double) -> (sets: Int, reps: Int) {
        let factors = ScalingFactors.fromReadinessScore(readinessScore)

        // Reduce sets first, then reps if needed
        var adjustedSets = max(1, baseSets - factors.setsReduction)
        var adjustedReps = baseReps

        // If volume multiplier requires more reduction, reduce reps
        let targetVolume = Double(baseSets * baseReps) * factors.volumeMultiplier
        let currentVolume = Double(adjustedSets * adjustedReps)

        if currentVolume > targetVolume {
            adjustedReps = max(1, Int(targetVolume / Double(adjustedSets)))
        }

        return (sets: adjustedSets, reps: adjustedReps)
    }

    /// Adjust rest periods based on readiness
    /// - Parameters:
    ///   - baseRest: Original rest period in seconds
    ///   - readinessScore: Current readiness score
    /// - Returns: Adjusted rest period in seconds
    func adjustRestPeriod(_ baseRest: Int, for readinessScore: Double) -> Int {
        let factors = ScalingFactors.fromReadinessScore(readinessScore)
        return Int(Double(baseRest) * factors.restMultiplier)
    }

    /// Check if a deload is recommended
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - consecutiveLowDays: Number of consecutive low readiness days
    /// - Returns: DeloadProtocol if deload is recommended, nil otherwise
    func checkDeloadRecommendation(
        for patientId: UUID,
        consecutiveLowDays: Int
    ) async throws -> DeloadProtocol? {
        // Deload triggers:
        // 1. 3+ consecutive days of low readiness (<50)
        // 2. Average readiness <55 over past 7 days
        // 3. Declining trend with high fatigue markers

        if consecutiveLowDays >= 3 {
            return createDeloadProtocol(severity: .moderate)
        }

        // Check 7-day average
        let trend = try await readinessService.getReadinessTrend(for: patientId, days: 7)
        if let avg = trend.statistics.avgReadiness, avg < 55 {
            return createDeloadProtocol(severity: .light)
        }

        // Check for declining trend with multiple low days
        let lowDaysCount = trend.trendData.filter { ($0.readinessScore ?? 100) < 60 }.count
        if lowDaysCount >= 4 {
            return createDeloadProtocol(severity: .light)
        }

        return nil
    }

    /// Get quick message for readiness-based recommendation
    /// - Parameter readinessScore: Current readiness score (0-100)
    /// - Returns: User-friendly message string
    func getQuickRecommendation(for readinessScore: Double) -> String {
        let percentage = Int(readinessScore)

        if readinessScore >= 80 {
            return "You're \(percentage)% ready - time to crush it!"
        } else if readinessScore >= 60 {
            return "You're \(percentage)% ready - train smart today"
        } else if readinessScore >= 40 {
            return "You're \(percentage)% ready - consider a lighter workout"
        } else if readinessScore >= 25 {
            return "You're \(percentage)% ready - try this mobility routine instead"
        } else {
            return "You're \(percentage)% ready - rest day recommended"
        }
    }

    // MARK: - Private Methods

    private func generateAdaptation(from score: CompositeReadinessScore) -> WorkoutAdaptation {
        let readiness = score.overallScore

        // Determine adaptation type
        let adaptationType: WorkoutAdaptation.AdaptationType
        let scalingFactors: ScalingFactors
        let message: String
        let detailedRecommendation: String

        if readiness >= 80 {
            adaptationType = .fullIntensity
            scalingFactors = ScalingFactors.fromReadinessScore(readiness)
            message = "You're fully recovered - go all out!"
            detailedRecommendation = """
            Your recovery metrics are excellent. All indicators suggest you're ready \
            for a high-intensity session. Focus on progressive overload and push \
            yourself today.
            """
        } else if readiness >= 65 {
            adaptationType = .slightReduction
            scalingFactors = ScalingFactors.fromReadinessScore(readiness)
            message = "Good recovery - train with slight caution"
            detailedRecommendation = """
            Your recovery is good but not optimal. Consider reducing intensity by \
            5-10% and listen to your body. If you feel great during warmup, \
            proceed as planned.
            """
        } else if readiness >= 50 {
            adaptationType = .moderateReduction
            scalingFactors = ScalingFactors.fromReadinessScore(readiness)
            message = "Moderate fatigue - reduce intensity today"
            detailedRecommendation = """
            Your body is showing signs of accumulated fatigue. Reduce weights by \
            15-20% and drop 1-2 sets per exercise. Focus on technique and \
            maintaining movement quality.
            """
        } else if readiness >= 35 {
            adaptationType = .lightActivity
            scalingFactors = ScalingFactors.fromReadinessScore(readiness)
            message = "High fatigue - light activity recommended"
            detailedRecommendation = """
            Your recovery metrics indicate significant fatigue. Skip the scheduled \
            workout and focus on mobility, stretching, or a light walk. Active \
            recovery will help more than pushing through.
            """
        } else if readiness >= 20 {
            adaptationType = .restDay
            scalingFactors = ScalingFactors.fromReadinessScore(readiness)
            message = "Very low readiness - rest today"
            detailedRecommendation = """
            Your body needs rest. Take today off from structured exercise. Focus \
            on sleep, nutrition, and stress management. Light stretching or a \
            short walk is fine if it feels good.
            """
        } else {
            adaptationType = .deloadRecommended
            scalingFactors = ScalingFactors.fromReadinessScore(readiness)
            message = "Critical fatigue - deload week recommended"
            detailedRecommendation = """
            Multiple recovery indicators are concerning. Consider taking a full \
            deload week with significantly reduced training. Prioritize sleep, \
            nutrition, and stress reduction.
            """
        }

        // Generate alternative workouts based on readiness
        let alternatives = generateAlternativeWorkouts(for: readiness)

        // Generate deload protocol if needed
        let deloadProtocol: DeloadProtocol?
        if readiness < 40 {
            deloadProtocol = createDeloadProtocol(severity: readiness < 25 ? .aggressive : .moderate)
        } else {
            deloadProtocol = nil
        }

        // Generate recovery tips based on breakdown
        let recoveryTips = generateRecoveryTips(from: score)

        return WorkoutAdaptation(
            recommendationType: adaptationType,
            scalingFactors: scalingFactors,
            alternativeWorkouts: alternatives,
            deloadProtocol: deloadProtocol,
            message: message,
            detailedRecommendation: detailedRecommendation,
            recoveryTips: recoveryTips
        )
    }

    private func generateAlternativeWorkouts(for readiness: Double) -> [AlternativeWorkout] {
        var alternatives: [AlternativeWorkout] = []

        if readiness < 70 {
            alternatives.append(AlternativeWorkout(
                id: UUID(),
                name: "20-Minute Mobility Flow",
                type: .mobility,
                duration: 20,
                intensity: .light,
                description: "Focus on hips, shoulders, and spine with gentle movements",
                benefits: ["Improves joint health", "Promotes blood flow", "Reduces stiffness"]
            ))
        }

        if readiness < 60 {
            alternatives.append(AlternativeWorkout(
                id: UUID(),
                name: "30-Minute Recovery Walk",
                type: .walking,
                duration: 30,
                intensity: .veryLight,
                description: "Easy-paced walk outdoors to promote active recovery",
                benefits: ["Improves circulation", "Reduces stress", "Supports recovery"]
            ))

            alternatives.append(AlternativeWorkout(
                id: UUID(),
                name: "Gentle Yoga Session",
                type: .yoga,
                duration: 25,
                intensity: .light,
                description: "Restorative yoga focusing on breathing and gentle stretches",
                benefits: ["Reduces tension", "Improves flexibility", "Calms nervous system"]
            ))
        }

        if readiness < 40 {
            alternatives.append(AlternativeWorkout(
                id: UUID(),
                name: "10-Minute Breathwork",
                type: .breathwork,
                duration: 10,
                intensity: .veryLight,
                description: "Box breathing and relaxation techniques",
                benefits: ["Activates parasympathetic system", "Reduces cortisol", "Improves HRV"]
            ))

            alternatives.append(AlternativeWorkout(
                id: UUID(),
                name: "15-Minute Stretch Routine",
                type: .stretching,
                duration: 15,
                intensity: .veryLight,
                description: "Full body passive stretching to release tension",
                benefits: ["Releases muscle tension", "Improves recovery", "Promotes relaxation"]
            ))
        }

        if readiness < 30 {
            alternatives.append(AlternativeWorkout(
                id: UUID(),
                name: "Guided Meditation",
                type: .meditation,
                duration: 15,
                intensity: .veryLight,
                description: "Body scan meditation for deep relaxation",
                benefits: ["Mental recovery", "Stress reduction", "Better sleep"]
            ))
        }

        return alternatives
    }

    private enum DeloadSeverity {
        case light
        case moderate
        case aggressive
    }

    private func createDeloadProtocol(severity: DeloadSeverity) -> DeloadProtocol {
        switch severity {
        case .light:
            return DeloadProtocol(
                durationDays: 5,
                loadReduction: 0.25,
                volumeReduction: 0.30,
                frequency: .everySession,
                focus: .technique,
                weeklySchedule: [
                    DeloadProtocol.DayPlan(dayNumber: 1, activity: "Light training (50% weight)", duration: 30, notes: "Focus on technique"),
                    DeloadProtocol.DayPlan(dayNumber: 2, activity: "Mobility work", duration: 20, notes: nil),
                    DeloadProtocol.DayPlan(dayNumber: 3, activity: "Light training (60% weight)", duration: 30, notes: "Focus on technique"),
                    DeloadProtocol.DayPlan(dayNumber: 4, activity: "Rest or walking", duration: 30, notes: nil),
                    DeloadProtocol.DayPlan(dayNumber: 5, activity: "Light training (65% weight)", duration: 30, notes: "Test how you feel")
                ],
                nutritionGuidelines: [
                    "Maintain protein intake at 1g/lb bodyweight",
                    "Don't restrict calories during deload",
                    "Increase anti-inflammatory foods"
                ],
                sleepGuidelines: [
                    "Aim for 8+ hours per night",
                    "Consistent bedtime each night",
                    "Avoid screens 1 hour before bed"
                ]
            )

        case .moderate:
            return DeloadProtocol(
                durationDays: 7,
                loadReduction: 0.35,
                volumeReduction: 0.45,
                frequency: .alternateSession,
                focus: .activeRecovery,
                weeklySchedule: [
                    DeloadProtocol.DayPlan(dayNumber: 1, activity: "Light full body (40% weight)", duration: 25, notes: "High reps, low weight"),
                    DeloadProtocol.DayPlan(dayNumber: 2, activity: "Yoga or mobility", duration: 30, notes: nil),
                    DeloadProtocol.DayPlan(dayNumber: 3, activity: "Rest", duration: nil, notes: "Complete rest"),
                    DeloadProtocol.DayPlan(dayNumber: 4, activity: "Light training (50% weight)", duration: 25, notes: nil),
                    DeloadProtocol.DayPlan(dayNumber: 5, activity: "Walking or swimming", duration: 30, notes: "Easy effort"),
                    DeloadProtocol.DayPlan(dayNumber: 6, activity: "Rest", duration: nil, notes: nil),
                    DeloadProtocol.DayPlan(dayNumber: 7, activity: "Light training (60% weight)", duration: 30, notes: "Assess readiness")
                ],
                nutritionGuidelines: [
                    "Increase protein to 1.2g/lb bodyweight",
                    "Add extra fruits and vegetables",
                    "Stay hydrated - aim for 0.5oz/lb bodyweight",
                    "Consider adding omega-3 supplements"
                ],
                sleepGuidelines: [
                    "Prioritize 8-9 hours per night",
                    "Take short naps if needed (20-30 min)",
                    "Cool, dark room for optimal sleep",
                    "No caffeine after 2pm"
                ]
            )

        case .aggressive:
            return DeloadProtocol(
                durationDays: 10,
                loadReduction: 0.50,
                volumeReduction: 0.60,
                frequency: .reducedDays,
                focus: .mentalReset,
                weeklySchedule: [
                    DeloadProtocol.DayPlan(dayNumber: 1, activity: "Complete rest", duration: nil, notes: "No structured exercise"),
                    DeloadProtocol.DayPlan(dayNumber: 2, activity: "Light walking", duration: 20, notes: "Very easy pace"),
                    DeloadProtocol.DayPlan(dayNumber: 3, activity: "Rest", duration: nil, notes: nil),
                    DeloadProtocol.DayPlan(dayNumber: 4, activity: "Gentle yoga", duration: 20, notes: nil),
                    DeloadProtocol.DayPlan(dayNumber: 5, activity: "Rest", duration: nil, notes: nil),
                    DeloadProtocol.DayPlan(dayNumber: 6, activity: "Mobility work", duration: 20, notes: nil),
                    DeloadProtocol.DayPlan(dayNumber: 7, activity: "Rest", duration: nil, notes: nil),
                    DeloadProtocol.DayPlan(dayNumber: 8, activity: "Very light training (30%)", duration: 20, notes: "Test the waters"),
                    DeloadProtocol.DayPlan(dayNumber: 9, activity: "Walking or stretching", duration: 25, notes: nil),
                    DeloadProtocol.DayPlan(dayNumber: 10, activity: "Light training (50%)", duration: 30, notes: "Gradual return")
                ],
                nutritionGuidelines: [
                    "Focus on nutrient-dense whole foods",
                    "Increase protein to 1.2g/lb",
                    "Add bone broth or collagen",
                    "Consider magnesium supplementation",
                    "Reduce processed foods"
                ],
                sleepGuidelines: [
                    "Make sleep your #1 priority",
                    "9+ hours if possible",
                    "No alarm if possible",
                    "Address any sleep issues (apnea, etc.)",
                    "Consider sleep tracking"
                ]
            )
        }
    }

    private func generateRecoveryTips(from score: CompositeReadinessScore) -> [RecoveryTip] {
        var tips: [RecoveryTip] = []
        let breakdown = score.breakdown

        // Sleep tips
        if let sleepHours = breakdown.sleepHours, sleepHours < 7 {
            tips.append(RecoveryTip(
                id: UUID(),
                category: .sleep,
                title: "Get More Sleep",
                description: "You got \(String(format: "%.1f", sleepHours)) hours. Aim for 7-9 hours for optimal recovery.",
                priority: sleepHours < 6 ? .high : .medium
            ))
        }

        if let efficiency = breakdown.sleepEfficiency, efficiency < 85 {
            tips.append(RecoveryTip(
                id: UUID(),
                category: .sleep,
                title: "Improve Sleep Quality",
                description: "Sleep efficiency was \(Int(efficiency))%. Try a consistent bedtime and cooler room temperature.",
                priority: efficiency < 75 ? .high : .medium
            ))
        }

        // HRV tips
        if let deviation = breakdown.hrvDeviation, deviation < -15 {
            tips.append(RecoveryTip(
                id: UUID(),
                category: .stress,
                title: "HRV Below Baseline",
                description: "Your HRV is \(Int(abs(deviation)))% below your baseline. Consider stress reduction techniques.",
                priority: deviation < -25 ? .high : .medium
            ))
        }

        // Soreness tips
        if let soreness = breakdown.sorenessLevel, soreness >= 6 {
            tips.append(RecoveryTip(
                id: UUID(),
                category: .mobility,
                title: "Address Muscle Soreness",
                description: "High soreness detected. Try foam rolling, light stretching, or contrast showers.",
                priority: soreness >= 8 ? .high : .medium
            ))
        }

        // Energy tips
        if let energy = breakdown.energyLevel, energy <= 4 {
            tips.append(RecoveryTip(
                id: UUID(),
                category: .nutrition,
                title: "Boost Energy Levels",
                description: "Low energy reported. Check hydration, consider a balanced snack, or take a short power nap.",
                priority: energy <= 2 ? .high : .medium
            ))
        }

        // Stress tips
        if let stress = breakdown.stressLevel, stress >= 7 {
            tips.append(RecoveryTip(
                id: UUID(),
                category: .stress,
                title: "Manage Stress",
                description: "High stress levels detected. Try breathwork, meditation, or a walk in nature.",
                priority: stress >= 8 ? .high : .medium
            ))
        }

        // General tips based on overall score
        if score.overallScore < 50 {
            tips.append(RecoveryTip(
                id: UUID(),
                category: .hydration,
                title: "Hydrate Well",
                description: "Ensure you're drinking enough water today. Aim for half your body weight in ounces.",
                priority: .medium
            ))

            tips.append(RecoveryTip(
                id: UUID(),
                category: .activity,
                title: "Light Movement",
                description: "Even when tired, light movement helps recovery. Try a 10-minute walk.",
                priority: .low
            ))
        }

        // Sort by priority
        return tips.sorted { $0.priority < $1.priority }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension WorkoutAdaptation {
    static var sampleHighReadiness: WorkoutAdaptation {
        WorkoutAdaptation(
            recommendationType: .fullIntensity,
            scalingFactors: ScalingFactors.fromReadinessScore(85),
            alternativeWorkouts: [],
            deloadProtocol: nil,
            message: "You're 85% ready - time to crush it!",
            detailedRecommendation: "Your recovery metrics are excellent.",
            recoveryTips: []
        )
    }

    static var sampleLowReadiness: WorkoutAdaptation {
        WorkoutAdaptation(
            recommendationType: .lightActivity,
            scalingFactors: ScalingFactors.fromReadinessScore(35),
            alternativeWorkouts: [
                AlternativeWorkout(
                    id: UUID(),
                    name: "20-Minute Mobility Flow",
                    type: .mobility,
                    duration: 20,
                    intensity: .light,
                    description: "Focus on hips, shoulders, and spine",
                    benefits: ["Improves joint health", "Promotes blood flow"]
                )
            ],
            deloadProtocol: nil,
            message: "You're 35% ready - try this mobility routine instead",
            detailedRecommendation: "Your body is showing signs of significant fatigue.",
            recoveryTips: [
                RecoveryTip(
                    id: UUID(),
                    category: .sleep,
                    title: "Get More Sleep",
                    description: "Aim for 8+ hours tonight",
                    priority: .high
                )
            ]
        )
    }
}
#endif
