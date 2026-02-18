//
//  RecommendationFeedbackStore.swift
//  PTPerformance
//
//  ACP-1025: AI Recommendations Transparency
//  Local store for user feedback on AI recommendations (thumbs up/down)
//

import Foundation
import SwiftUI

// MARK: - Feedback Models

/// Represents user feedback on an AI recommendation
struct RecommendationFeedback: Codable, Identifiable {
    let id: UUID
    let recommendationId: String
    let recommendationType: RecommendationFeedbackType
    let isPositive: Bool
    let timestamp: Date
    let comment: String?

    init(
        id: UUID = UUID(),
        recommendationId: String,
        recommendationType: RecommendationFeedbackType,
        isPositive: Bool,
        timestamp: Date = Date(),
        comment: String? = nil
    ) {
        self.id = id
        self.recommendationId = recommendationId
        self.recommendationType = recommendationType
        self.isPositive = isPositive
        self.timestamp = timestamp
        self.comment = comment
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.recommendationId = (try? container.decode(String.self, forKey: .recommendationId)) ?? ""
        self.recommendationType = (try? container.decode(RecommendationFeedbackType.self, forKey: .recommendationType)) ?? .healthInsight
        self.isPositive = (try? container.decode(Bool.self, forKey: .isPositive)) ?? true
        self.timestamp = (try? container.decodeIfPresent(Double.self, forKey: .timestamp))
            .map { Date(timeIntervalSinceReferenceDate: $0) } ?? Date()
        self.comment = try? container.decodeIfPresent(String.self, forKey: .comment)
    }
}

/// Types of AI recommendations that can receive feedback
enum RecommendationFeedbackType: String, Codable {
    case deload
    case workoutAdaptation
    case workoutSuggestion
    case nutritionAdvice
    case recoveryProtocol
    case healthInsight
}

// MARK: - Data Confidence Level

/// Indicates how much data the AI had available to make a recommendation
enum DataConfidenceLevel: String {
    case low
    case moderate
    case high
    case veryHigh

    /// Display label
    var displayName: String {
        switch self {
        case .low: return "Limited Data"
        case .moderate: return "Moderate Data"
        case .high: return "Good Data"
        case .veryHigh: return "Excellent Data"
        }
    }

    /// Icon for the confidence level
    var icon: String {
        switch self {
        case .low: return "chart.bar.fill"
        case .moderate: return "chart.bar.fill"
        case .high: return "chart.bar.fill"
        case .veryHigh: return "chart.bar.fill"
        }
    }

    /// Color for the confidence indicator
    var color: Color {
        switch self {
        case .low: return .orange
        case .moderate: return .yellow
        case .high: return .modusTealAccent
        case .veryHigh: return .modusCyan
        }
    }

    /// Number of filled bars (out of 4) for the visual indicator
    var filledBars: Int {
        switch self {
        case .low: return 1
        case .moderate: return 2
        case .high: return 3
        case .veryHigh: return 4
        }
    }

    /// Description of what the confidence level means
    var description: String {
        switch self {
        case .low:
            return "Based on less than 1 week of data. Recommendations will improve as you log more."
        case .moderate:
            return "Based on 1-2 weeks of data. Getting more accurate."
        case .high:
            return "Based on 2-4 weeks of data. Recommendations are well-informed."
        case .veryHigh:
            return "Based on 4+ weeks of data. High confidence in these recommendations."
        }
    }

    /// Determines confidence level based on number of data points available
    static func from(dataPointCount: Int) -> DataConfidenceLevel {
        switch dataPointCount {
        case 0..<5: return .low
        case 5..<14: return .moderate
        case 14..<28: return .high
        default: return .veryHigh
        }
    }
}

// MARK: - Driving Data Point

/// A single data point that drove an AI recommendation
struct RecommendationDrivingFactor: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let metric: String
    let detail: String
    let category: HealthInsightCategory

    /// Creates a driving factor from common metric types
    static func hrv(changePercent: Double) -> RecommendationDrivingFactor {
        let direction = changePercent < 0 ? "down" : "up"
        return RecommendationDrivingFactor(
            icon: "heart.fill",
            iconColor: changePercent < -10 ? .orange : .modusTealAccent,
            metric: "HRV \(direction) \(abs(Int(changePercent)))%",
            detail: "Compared to your 7-day baseline",
            category: .recovery
        )
    }

    static func sleepQuality(poorNights: Int, totalNights: Int) -> RecommendationDrivingFactor {
        return RecommendationDrivingFactor(
            icon: "moon.fill",
            iconColor: poorNights >= 3 ? .orange : .indigo,
            metric: "Sleep quality poor \(poorNights)/\(totalNights) nights",
            detail: "Below your optimal sleep threshold",
            category: .sleep
        )
    }

    static func volumeChange(changePercent: Double) -> RecommendationDrivingFactor {
        let direction = changePercent > 0 ? "up" : "down"
        return RecommendationDrivingFactor(
            icon: "figure.strengthtraining.traditional",
            iconColor: changePercent > 15 ? .orange : .blue,
            metric: "Volume \(direction) \(abs(Int(changePercent)))% this week",
            detail: "Compared to your 4-week average",
            category: .training
        )
    }

    static func readinessScore(score: Double) -> RecommendationDrivingFactor {
        return RecommendationDrivingFactor(
            icon: "gauge.with.dots.needle.33percent",
            iconColor: score < 50 ? .orange : .modusTealAccent,
            metric: "Readiness at \(Int(score))%",
            detail: score < 50 ? "Below optimal range" : "Within healthy range",
            category: .recovery
        )
    }

    static func acuteChronicRatio(ratio: Double) -> RecommendationDrivingFactor {
        return RecommendationDrivingFactor(
            icon: "arrow.up.arrow.down",
            iconColor: ratio > 1.3 ? .orange : .modusTealAccent,
            metric: "Workload ratio at \(String(format: "%.2f", ratio))",
            detail: ratio > 1.3 ? "Elevated - risk of overtraining" : "Within safe range",
            category: .training
        )
    }

    static func consecutiveLowDays(days: Int) -> RecommendationDrivingFactor {
        return RecommendationDrivingFactor(
            icon: "calendar.badge.exclamationmark",
            iconColor: days > 2 ? .orange : .blue,
            metric: "\(days) consecutive low readiness days",
            detail: days > 2 ? "Extended recovery period detected" : "Monitoring trend",
            category: .recovery
        )
    }

    static func rpeAverage(rpe: Double) -> RecommendationDrivingFactor {
        return RecommendationDrivingFactor(
            icon: "flame.fill",
            iconColor: rpe > 8 ? .red : (rpe > 7 ? .orange : .blue),
            metric: "Avg RPE at \(String(format: "%.1f", rpe))",
            detail: rpe > 8 ? "Very high perceived exertion" : "Effort level tracked",
            category: .training
        )
    }

    static func fatigueScore(score: Double) -> RecommendationDrivingFactor {
        return RecommendationDrivingFactor(
            icon: "battery.25",
            iconColor: score > 70 ? .orange : .modusTealAccent,
            metric: "Fatigue score at \(Int(score))/100",
            detail: score > 70 ? "High fatigue accumulated" : "Fatigue within normal range",
            category: .recovery
        )
    }
}

// MARK: - Recommendation Feedback Store

/// Persists user feedback on AI recommendations using UserDefaults
/// Feedback data is stored locally and can be synced to backend in the future
@MainActor
class RecommendationFeedbackStore: ObservableObject {

    static let shared = RecommendationFeedbackStore()

    private let userDefaultsKey = "ai_recommendation_feedback"

    @Published private(set) var feedbackItems: [RecommendationFeedback] = []

    nonisolated init() { }

    /// Load stored feedback from UserDefaults
    func loadFeedback() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            feedbackItems = []
            return
        }

        do {
            let items = try SafeJSON.decoder().decode([RecommendationFeedback].self, from: data)
            feedbackItems = items
        } catch {
            #if DEBUG
            DebugLogger.shared.warning("FEEDBACK", "Failed to decode feedback: \(error)")
            #endif
            feedbackItems = []
        }
    }

    /// Submit feedback for a recommendation
    /// - Parameters:
    ///   - recommendationId: Unique ID of the recommendation
    ///   - type: Type of recommendation
    ///   - isPositive: true for thumbs up, false for thumbs down
    ///   - comment: Optional text comment
    func submitFeedback(
        recommendationId: String,
        type: RecommendationFeedbackType,
        isPositive: Bool,
        comment: String? = nil
    ) {
        // Remove any existing feedback for this recommendation
        feedbackItems.removeAll { $0.recommendationId == recommendationId }

        let feedback = RecommendationFeedback(
            recommendationId: recommendationId,
            recommendationType: type,
            isPositive: isPositive,
            comment: comment
        )

        feedbackItems.append(feedback)
        saveFeedback()

        #if DEBUG
        DebugLogger.shared.info("FEEDBACK", "Submitted \(isPositive ? "positive" : "negative") feedback for \(type.rawValue) recommendation \(recommendationId.prefix(8))")
        #endif
    }

    /// Get existing feedback for a specific recommendation
    func getFeedback(for recommendationId: String) -> RecommendationFeedback? {
        feedbackItems.first { $0.recommendationId == recommendationId }
    }

    /// Check if user has already given feedback for a recommendation
    func hasFeedback(for recommendationId: String) -> Bool {
        feedbackItems.contains { $0.recommendationId == recommendationId }
    }

    /// Remove feedback for a specific recommendation
    func removeFeedback(for recommendationId: String) {
        feedbackItems.removeAll { $0.recommendationId == recommendationId }
        saveFeedback()
    }

    /// Get summary statistics
    var totalFeedbackCount: Int { feedbackItems.count }
    var positiveFeedbackCount: Int { feedbackItems.filter(\.isPositive).count }
    var negativeFeedbackCount: Int { feedbackItems.filter { !$0.isPositive }.count }

    // MARK: - Private

    private func saveFeedback() {
        do {
            let data = try SafeJSON.encoder().encode(feedbackItems)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            #if DEBUG
            DebugLogger.shared.error("FEEDBACK", "Failed to save feedback: \(error)")
            #endif
        }
    }
}
