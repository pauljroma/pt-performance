import Foundation
import SwiftUI

// MARK: - BUILD 351: Readiness Band System Types

/// Readiness band levels for workout modification
enum ReadinessBand: String, Codable, CaseIterable {
    case green = "green"    // Full intensity - go hard
    case yellow = "yellow"  // Slight reduction - be mindful
    case orange = "orange"  // Moderate reduction - take it easy
    case red = "red"        // Recovery only - minimal load

    /// Display name for UI
    var displayName: String {
        switch self {
        case .green: return "Ready to Train"
        case .yellow: return "Train with Caution"
        case .orange: return "Reduced Intensity"
        case .red: return "Recovery Day"
        }
    }

    /// Description of the readiness level
    var description: String {
        switch self {
        case .green: return "You're recovered and ready for a full workout"
        case .yellow: return "Minor fatigue detected - consider slight modifications"
        case .orange: return "Elevated fatigue - reduce intensity and volume"
        case .red: return "High fatigue or pain - focus on recovery today"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        case .red: return .red
        }
    }

    /// Load adjustment multiplier (negative = reduction)
    var loadAdjustment: Double {
        switch self {
        case .green: return 0.0      // No reduction
        case .yellow: return -0.10   // 10% reduction
        case .orange: return -0.25   // 25% reduction
        case .red: return -0.50      // 50% reduction
        }
    }

    /// Volume adjustment multiplier (negative = reduction)
    var volumeAdjustment: Double {
        switch self {
        case .green: return 0.0      // No reduction
        case .yellow: return -0.10   // 10% reduction
        case .orange: return -0.30   // 30% reduction
        case .red: return -0.50      // 50% reduction
        }
    }
}

/// Joint pain location enum for readiness assessment
enum JointPainLocation: String, Codable, CaseIterable {
    case shoulder
    case elbow
    case hip
    case knee
    case back

    var displayName: String {
        rawValue.capitalized
    }
}

/// Input for WHOOP-style readiness calculations (distinct from ReadinessInput for database)
struct BandCalculationInput {
    var sleepHours: Double?
    var sleepQuality: Int?         // 1-5 scale
    var hrvValue: Double?
    var whoopRecoveryPct: Int?
    var subjectiveReadiness: Int?  // 1-5 scale
    var armSoreness: Bool
    var armSorenessSeverity: Int?  // 1-3 scale
    var jointPain: [JointPainLocation]
    var jointPainNotes: String?
}

/// Preview of readiness calculation result
struct ReadinessPreview {
    let band: ReadinessBand
    let score: Double?
}

// MARK: - Daily Readiness Model

/// Daily readiness check-in
/// Simplified schema with core wellness metrics
struct DailyReadiness: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let date: Date

    // Core metrics (1-10 scale for levels)
    let sleepHours: Double?
    let sorenessLevel: Int?     // 1-10 (1=no soreness, 10=extreme)
    let energyLevel: Int?       // 1-10 (1=exhausted, 10=fully energized)
    let stressLevel: Int?       // 1-10 (1=no stress, 10=extreme)

    // Calculated score (0-100, auto-calculated by database)
    let readinessScore: Double?

    // Optional
    let notes: String?

    // Metadata
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case date
        case sleepHours = "sleep_hours"
        case sorenessLevel = "soreness_level"
        case energyLevel = "energy_level"
        case stressLevel = "stress_level"
        case readinessScore = "readiness_score"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Memberwise initializer (replaces default since we have custom decoder)
    init(
        id: UUID,
        patientId: UUID,
        date: Date,
        sleepHours: Double? = nil,
        sorenessLevel: Int? = nil,
        energyLevel: Int? = nil,
        stressLevel: Int? = nil,
        readinessScore: Double? = nil,
        notes: String? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.patientId = patientId
        self.date = date
        self.sleepHours = sleepHours
        self.sorenessLevel = sorenessLevel
        self.energyLevel = energyLevel
        self.stressLevel = stressLevel
        self.readinessScore = readinessScore
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoder to handle PostgreSQL numeric as string AND date format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        patientId = try container.decode(UUID.self, forKey: .patientId)

        // BUILD 133: Handle DATE column format "YYYY-MM-DD" from PostgreSQL
        // Database returns DATE as "2026-01-04" (not ISO8601 with time component)
        if let dateString = try? container.decode(String.self, forKey: .date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let parsedDate = dateFormatter.date(from: dateString) {
                date = parsedDate
            } else {
                // Fallback: try ISO8601 decoder in case database schema changes
                date = try container.decode(Date.self, forKey: .date)
            }
        } else {
            // Fallback: try standard date decoding (ISO8601)
            date = try container.decode(Date.self, forKey: .date)
        }

        // Handle numeric fields that might come as strings from PostgreSQL
        if let sleepString = try? container.decode(String.self, forKey: .sleepHours) {
            sleepHours = Double(sleepString)
        } else {
            sleepHours = try container.decodeIfPresent(Double.self, forKey: .sleepHours)
        }

        sorenessLevel = try container.decodeIfPresent(Int.self, forKey: .sorenessLevel)
        energyLevel = try container.decodeIfPresent(Int.self, forKey: .energyLevel)
        stressLevel = try container.decodeIfPresent(Int.self, forKey: .stressLevel)

        // Readiness score might come as string from PostgreSQL numeric type
        if let scoreString = try? container.decode(String.self, forKey: .readinessScore) {
            readinessScore = Double(scoreString)
        } else {
            readinessScore = try container.decodeIfPresent(Double.self, forKey: .readinessScore)
        }

        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    // MARK: - BUILD 351: Computed Readiness Band

    /// Convert readiness score to ReadinessBand for UI display
    var readinessBand: ReadinessBand {
        guard let score = readinessScore else { return .yellow }
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .yellow
        } else if score >= 40 {
            return .orange
        } else {
            return .red
        }
    }
}

/// Input model for creating/updating daily readiness
struct ReadinessInput: Codable {
    var sleepHours: Double?
    var sorenessLevel: Int?     // 1-10
    var energyLevel: Int?       // 1-10
    var stressLevel: Int?       // 1-10
    var notes: String?

    // Internal fields for database
    var patientId: String?
    var date: String?

    enum CodingKeys: String, CodingKey {
        case sleepHours = "sleep_hours"
        case sorenessLevel = "soreness_level"
        case energyLevel = "energy_level"
        case stressLevel = "stress_level"
        case notes
        case patientId = "patient_id"
        case date
    }

    /// Validate input before submission
    func validate() throws {
        if let sleep = sleepHours {
            guard sleep >= 0 && sleep <= 24 else {
                throw ReadinessError.invalidSleepHours
            }
        }

        if let soreness = sorenessLevel {
            guard soreness >= 1 && soreness <= 10 else {
                throw ReadinessError.invalidSorenessLevel
            }
        }

        if let energy = energyLevel {
            guard energy >= 1 && energy <= 10 else {
                throw ReadinessError.invalidEnergyLevel
            }
        }

        if let stress = stressLevel {
            guard stress >= 1 && stress <= 10 else {
                throw ReadinessError.invalidStressLevel
            }
        }

        // At least one metric must be provided
        guard sleepHours != nil || sorenessLevel != nil ||
              energyLevel != nil || stressLevel != nil else {
            throw ReadinessError.noMetricsProvided
        }
    }
}

/// Readiness trend data returned from database function
struct ReadinessTrend: Codable {
    let patientId: UUID
    let daysAnalyzed: Int
    let currentDate: Date
    let trendData: [TrendDataPoint]
    let statistics: TrendStatistics

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case daysAnalyzed = "days_analyzed"
        case currentDate = "current_date"
        case trendData = "trend_data"
        case statistics
    }

    struct TrendDataPoint: Codable {
        let date: Date
        let readinessScore: Double?
        let sleepHours: Double?
        let sorenessLevel: Int?
        let energyLevel: Int?
        let stressLevel: Int?
        let notes: String?

        enum CodingKeys: String, CodingKey {
            case date
            case readinessScore = "readiness_score"
            case sleepHours = "sleep_hours"
            case sorenessLevel = "soreness_level"
            case energyLevel = "energy_level"
            case stressLevel = "stress_level"
            case notes
        }
    }

    struct TrendStatistics: Codable {
        let avgReadiness: Double?
        let minReadiness: Double?
        let maxReadiness: Double?
        let avgSleep: Double?
        let avgSoreness: Double?
        let avgEnergy: Double?
        let avgStress: Double?
        let totalEntries: Int

        enum CodingKeys: String, CodingKey {
            case avgReadiness = "avg_readiness"
            case minReadiness = "min_readiness"
            case maxReadiness = "max_readiness"
            case avgSleep = "avg_sleep"
            case avgSoreness = "avg_soreness"
            case avgEnergy = "avg_energy"
            case avgStress = "avg_stress"
            case totalEntries = "total_entries"
        }
    }
}

/// Readiness-related errors
enum ReadinessError: LocalizedError {
    case invalidSleepHours
    case invalidSorenessLevel
    case invalidEnergyLevel
    case invalidStressLevel
    case noMetricsProvided
    case scoreCalculationFailed
    case noDataFound
    case trendCalculationFailed

    var errorDescription: String? {
        switch self {
        case .invalidSleepHours:
            return "Sleep hours must be between 0 and 24"
        case .invalidSorenessLevel:
            return "Soreness level must be between 1 and 10"
        case .invalidEnergyLevel:
            return "Energy level must be between 1 and 10"
        case .invalidStressLevel:
            return "Stress level must be between 1 and 10"
        case .noMetricsProvided:
            return "At least one metric must be provided"
        case .scoreCalculationFailed:
            return "Failed to calculate readiness score"
        case .noDataFound:
            return "No readiness data found"
        case .trendCalculationFailed:
            return "Failed to calculate readiness trend"
        }
    }
}

// MARK: - Display Extensions

extension DailyReadiness {
    /// Readiness category based on score
    var category: ReadinessCategory? {
        guard let score = readinessScore else { return nil }
        return ReadinessCategory.category(for: score)
    }

    /// Color for displaying the readiness score
    var scoreColor: Color {
        return category?.color ?? .gray
    }

    /// Formatted score text for display
    var scoreText: String {
        guard let score = readinessScore else { return "--" }
        return String(format: "%.0f", score)
    }

    /// Formatted date for accessibility and display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
