import Foundation
import SwiftUI

// MARK: - Visit Summary Model
// Comprehensive summary of a patient treatment session

/// Exercise performed during a visit
struct ExercisePerformed: Codable, Identifiable {
    var id: UUID
    var name: String
    var sets: Int
    var reps: String              // Can be range like "10-12" or specific "15"
    var load: String?             // Weight, resistance band color, etc.
    var duration: String?         // For timed exercises
    var intensity: String?        // RPE or percentage
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sets
        case reps
        case load
        case duration
        case intensity
        case notes
    }

    // MARK: - Computed Properties

    /// Formatted exercise summary for display
    var summary: String {
        var parts = ["\(sets) x \(reps)"]
        if let load = load, !load.isEmpty {
            parts.append("@ \(load)")
        }
        if let duration = duration, !duration.isEmpty {
            parts.append("(\(duration))")
        }
        return parts.joined(separator: " ")
    }

    /// Whether exercise has additional details
    var hasDetails: Bool {
        load != nil || duration != nil || intensity != nil || notes != nil
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        name: String,
        sets: Int,
        reps: String,
        load: String? = nil,
        duration: String? = nil,
        intensity: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.load = load
        self.duration = duration
        self.intensity = intensity
        self.notes = notes
    }
}

/// Comprehensive visit summary for a treatment session
struct VisitSummary: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let sessionId: UUID
    let therapistId: UUID

    let visitDate: Date

    // Exercise tracking
    var exercisesPerformed: [ExercisePerformed]?
    var totalExercises: Int?
    var durationMinutes: Int?

    // Patient response metrics
    var avgPainScore: Double?
    var avgRpe: Double?
    var peakPainScore: Int?
    var endPainScore: Int?

    // Clinical observations
    var clinicalNotes: String?
    var patientResponse: String?
    var modificationsMade: String?

    // Planning
    var nextVisitFocus: String?
    var homeProgramChanges: String?

    // Additional tracking
    var goalsAddressed: [String]?
    var treatmentInterventions: [String]?
    var patientEducation: String?

    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case sessionId = "session_id"
        case therapistId = "therapist_id"
        case visitDate = "visit_date"
        case exercisesPerformed = "exercises_performed"
        case totalExercises = "total_exercises"
        case durationMinutes = "duration_minutes"
        case avgPainScore = "avg_pain_score"
        case avgRpe = "avg_rpe"
        case peakPainScore = "peak_pain_score"
        case endPainScore = "end_pain_score"
        case clinicalNotes = "clinical_notes"
        case patientResponse = "patient_response"
        case modificationsMade = "modifications_made"
        case nextVisitFocus = "next_visit_focus"
        case homeProgramChanges = "home_program_changes"
        case goalsAddressed = "goals_addressed"
        case treatmentInterventions = "treatment_interventions"
        case patientEducation = "patient_education"
        case createdAt = "created_at"
    }

    // MARK: - Computed Properties

    /// Formatted visit date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: visitDate)
    }

    /// Formatted date and time
    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: visitDate)
    }

    /// Formatted duration
    var formattedDuration: String? {
        guard let minutes = durationMinutes else { return nil }
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)h \(remainingMinutes)m"
            }
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
        return "\(minutes) min"
    }

    /// Exercise count (from array or total field)
    var exerciseCount: Int {
        if let exercises = exercisesPerformed {
            return exercises.count
        }
        return totalExercises ?? 0
    }

    /// Total sets performed
    var totalSets: Int {
        exercisesPerformed?.reduce(0) { $0 + $1.sets } ?? 0
    }

    /// Average pain formatted for display
    var formattedAvgPain: String? {
        guard let pain = avgPainScore else { return nil }
        return String(format: "%.1f/10", pain)
    }

    /// Average RPE formatted for display
    var formattedAvgRpe: String? {
        guard let rpe = avgRpe else { return nil }
        return String(format: "%.1f/10", rpe)
    }

    /// Pain response assessment
    var painResponse: PainResponse {
        guard let peak = peakPainScore, let end = endPainScore else {
            return .unknown
        }

        if end < peak - 1 {
            return .improved
        } else if end > peak + 1 {
            return .worsened
        }
        return .stable
    }

    /// Session intensity level based on RPE
    var intensityLevel: IntensityLevel {
        guard let rpe = avgRpe else { return .unknown }
        switch rpe {
        case 0..<4: return .light
        case 4..<6: return .moderate
        case 6..<8: return .hard
        default: return .veryHard
        }
    }

    /// Quick summary for list display
    var quickSummary: String {
        var parts: [String] = []

        if exerciseCount > 0 {
            parts.append("\(exerciseCount) exercises")
        }
        if let duration = formattedDuration {
            parts.append(duration)
        }
        if let pain = formattedAvgPain {
            parts.append("Pain: \(pain)")
        }

        return parts.isEmpty ? "No data" : parts.joined(separator: " | ")
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        patientId: UUID,
        sessionId: UUID,
        therapistId: UUID,
        visitDate: Date = Date(),
        exercisesPerformed: [ExercisePerformed]? = nil,
        totalExercises: Int? = nil,
        durationMinutes: Int? = nil,
        avgPainScore: Double? = nil,
        avgRpe: Double? = nil,
        peakPainScore: Int? = nil,
        endPainScore: Int? = nil,
        clinicalNotes: String? = nil,
        patientResponse: String? = nil,
        modificationsMade: String? = nil,
        nextVisitFocus: String? = nil,
        homeProgramChanges: String? = nil,
        goalsAddressed: [String]? = nil,
        treatmentInterventions: [String]? = nil,
        patientEducation: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.patientId = patientId
        self.sessionId = sessionId
        self.therapistId = therapistId
        self.visitDate = visitDate
        self.exercisesPerformed = exercisesPerformed
        self.totalExercises = totalExercises
        self.durationMinutes = durationMinutes
        self.avgPainScore = avgPainScore
        self.avgRpe = avgRpe
        self.peakPainScore = peakPainScore
        self.endPainScore = endPainScore
        self.clinicalNotes = clinicalNotes
        self.patientResponse = patientResponse
        self.modificationsMade = modificationsMade
        self.nextVisitFocus = nextVisitFocus
        self.homeProgramChanges = homeProgramChanges
        self.goalsAddressed = goalsAddressed
        self.treatmentInterventions = treatmentInterventions
        self.patientEducation = patientEducation
        self.createdAt = createdAt
    }
}

// MARK: - Pain Response

enum PainResponse: String, Codable {
    case improved = "improved"
    case stable = "stable"
    case worsened = "worsened"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .improved: return "Pain Improved"
        case .stable: return "Pain Stable"
        case .worsened: return "Pain Increased"
        case .unknown: return "Not Assessed"
        }
    }

    var color: Color {
        switch self {
        case .improved: return .green
        case .stable: return .yellow
        case .worsened: return .red
        case .unknown: return .gray
        }
    }

    var iconName: String {
        switch self {
        case .improved: return "arrow.down"
        case .stable: return "minus"
        case .worsened: return "arrow.up"
        case .unknown: return "questionmark"
        }
    }
}

// MARK: - Intensity Level

enum IntensityLevel: String, Codable {
    case light = "light"
    case moderate = "moderate"
    case hard = "hard"
    case veryHard = "very_hard"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .hard: return "Hard"
        case .veryHard: return "Very Hard"
        case .unknown: return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .light: return .green
        case .moderate: return .yellow
        case .hard: return .orange
        case .veryHard: return .red
        case .unknown: return .gray
        }
    }

    var rpeRange: String {
        switch self {
        case .light: return "RPE 1-3"
        case .moderate: return "RPE 4-5"
        case .hard: return "RPE 6-7"
        case .veryHard: return "RPE 8-10"
        case .unknown: return "N/A"
        }
    }
}

// MARK: - Visit Summary Statistics

/// Aggregated statistics across multiple visits
struct VisitStatistics: Codable {
    let patientId: UUID
    let totalVisits: Int
    let totalDurationMinutes: Int
    let avgPainScore: Double?
    let avgRpe: Double?
    let avgExercisesPerVisit: Double
    let mostCommonExercises: [String]
    let painTrend: PainResponse

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case totalVisits = "total_visits"
        case totalDurationMinutes = "total_duration_minutes"
        case avgPainScore = "avg_pain_score"
        case avgRpe = "avg_rpe"
        case avgExercisesPerVisit = "avg_exercises_per_visit"
        case mostCommonExercises = "most_common_exercises"
        case painTrend = "pain_trend"
    }

    /// Formatted total duration across all visits
    var formattedTotalDuration: String {
        let hours = totalDurationMinutes / 60
        let minutes = totalDurationMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
        return "\(minutes) min"
    }
}

// MARK: - Input Model

/// Input model for creating visit summaries
struct VisitSummaryInput: Codable {
    var patientId: String?
    var sessionId: String?
    var therapistId: String?
    var visitDate: String?

    var exercisesPerformed: [ExercisePerformed]?
    var totalExercises: Int?
    var durationMinutes: Int?

    var avgPainScore: Double?
    var avgRpe: Double?
    var peakPainScore: Int?
    var endPainScore: Int?

    var clinicalNotes: String?
    var patientResponse: String?
    var modificationsMade: String?

    var nextVisitFocus: String?
    var homeProgramChanges: String?

    var goalsAddressed: [String]?
    var treatmentInterventions: [String]?
    var patientEducation: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case sessionId = "session_id"
        case therapistId = "therapist_id"
        case visitDate = "visit_date"
        case exercisesPerformed = "exercises_performed"
        case totalExercises = "total_exercises"
        case durationMinutes = "duration_minutes"
        case avgPainScore = "avg_pain_score"
        case avgRpe = "avg_rpe"
        case peakPainScore = "peak_pain_score"
        case endPainScore = "end_pain_score"
        case clinicalNotes = "clinical_notes"
        case patientResponse = "patient_response"
        case modificationsMade = "modifications_made"
        case nextVisitFocus = "next_visit_focus"
        case homeProgramChanges = "home_program_changes"
        case goalsAddressed = "goals_addressed"
        case treatmentInterventions = "treatment_interventions"
        case patientEducation = "patient_education"
    }

    /// Validate input values
    func validate() throws {
        if let pain = avgPainScore, pain < 0 || pain > 10 {
            throw VisitSummaryError.invalidPainScore("Pain score must be 0-10")
        }
        if let rpe = avgRpe, rpe < 0 || rpe > 10 {
            throw VisitSummaryError.invalidRpeScore("RPE must be 0-10")
        }
        if let duration = durationMinutes, duration < 0 {
            throw VisitSummaryError.invalidDuration("Duration cannot be negative")
        }
    }
}

// MARK: - Errors

enum VisitSummaryError: LocalizedError {
    case invalidPainScore(String)
    case invalidRpeScore(String)
    case invalidDuration(String)
    case summaryNotFound
    case saveFailed
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .invalidPainScore(let message):
            return message
        case .invalidRpeScore(let message):
            return message
        case .invalidDuration(let message):
            return message
        case .summaryNotFound:
            return "Visit summary not found"
        case .saveFailed:
            return "Failed to save visit summary"
        case .fetchFailed:
            return "Failed to fetch visit summary"
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension VisitSummary {
    static let sample = VisitSummary(
        patientId: UUID(),
        sessionId: UUID(),
        therapistId: UUID(),
        exercisesPerformed: [
            ExercisePerformed(name: "Shoulder Flexion AAROM", sets: 3, reps: "15", notes: "Pain-free range"),
            ExercisePerformed(name: "External Rotation w/ Band", sets: 3, reps: "12", load: "Yellow band"),
            ExercisePerformed(name: "Scapular Retraction", sets: 3, reps: "15"),
            ExercisePerformed(name: "Prone Y's", sets: 2, reps: "10", load: "2 lbs")
        ],
        totalExercises: 4,
        durationMinutes: 45,
        avgPainScore: 3.5,
        avgRpe: 5.0,
        peakPainScore: 5,
        endPainScore: 3,
        clinicalNotes: "Patient demonstrating improved ROM and reduced pain with exercises. Good form throughout session.",
        patientResponse: "Tolerated session well. Reports feeling stronger.",
        modificationsMade: "Reduced resistance on external rotation due to mild discomfort at end range.",
        nextVisitFocus: "Progress strengthening exercises if pain remains controlled",
        homeProgramChanges: "Added prone Y exercise to HEP"
    )

    static let minimalSample = VisitSummary(
        patientId: UUID(),
        sessionId: UUID(),
        therapistId: UUID(),
        totalExercises: 6,
        durationMinutes: 30
    )
}

extension ExercisePerformed {
    static let sample = ExercisePerformed(
        name: "Shoulder External Rotation",
        sets: 3,
        reps: "12-15",
        load: "Yellow band",
        intensity: "RPE 5",
        notes: "Focus on slow eccentric"
    )
}
#endif
