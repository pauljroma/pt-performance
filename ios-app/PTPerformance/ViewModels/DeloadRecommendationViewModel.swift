import Foundation
import SwiftUI

/// ViewModel for displaying deload recommendations and fatigue analysis
/// Manages state for the deload recommendation view with fatigue trends
@MainActor
class DeloadRecommendationViewModel: ObservableObject {
    // MARK: - Dependencies

    private let fatigueTrackingService: FatigueTrackingService
    private let deloadRecommendationService: DeloadRecommendationService
    private let patientId: UUID

    // MARK: - Data State

    @Published var fatigueSummary: FatigueSummary?
    @Published var prescription: DeloadPrescription?
    @Published var urgency: DeloadUrgency = .none
    @Published var contributingFactors: [String] = []
    @Published var trendData: [FatigueTrendPoint] = []

    // MARK: - UI State

    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isActivating: Bool = false
    @Published var isDismissing: Bool = false
    @Published var showActivationSuccess: Bool = false
    @Published var showDismissalSuccess: Bool = false

    // MARK: - Computed Properties

    /// Whether we have recommendation data to display
    var hasData: Bool {
        fatigueSummary != nil
    }

    /// Whether a deload is recommended
    var deloadRecommended: Bool {
        urgency != .none && prescription != nil
    }

    /// Fatigue score (0-100)
    var fatigueScore: Double {
        fatigueSummary?.fatigueScore ?? 0
    }

    /// Formatted fatigue score text
    var fatigueScoreText: String {
        String(format: "%.0f", fatigueScore)
    }

    /// Color for the fatigue score based on band
    var fatigueColor: Color {
        guard let bandString = fatigueSummary?.fatigueBand,
              let band = FatigueBand(rawValue: bandString) else {
            return .gray
        }
        return band.color
    }

    /// Fatigue band enum for display
    var fatigueBand: FatigueBand? {
        guard let bandString = fatigueSummary?.fatigueBand else { return nil }
        return FatigueBand(rawValue: bandString)
    }

    /// Description text for the fatigue level
    var fatigueDescription: String {
        fatigueBand?.description ?? "No fatigue data available"
    }

    // MARK: - Initialization

    init(
        patientId: UUID,
        fatigueTrackingService: FatigueTrackingService = FatigueTrackingService(),
        deloadRecommendationService: DeloadRecommendationService = DeloadRecommendationService()
    ) {
        self.patientId = patientId
        self.fatigueTrackingService = fatigueTrackingService
        self.deloadRecommendationService = deloadRecommendationService
    }

    // MARK: - Load Data

    /// Load all deload recommendation and fatigue data
    func loadData() async {
        isLoading = true
        showError = false
        errorMessage = ""

        do {
            // Fetch deload recommendation
            try await deloadRecommendationService.fetchRecommendation(patientId: patientId)

            if let recommendation = deloadRecommendationService.recommendation {
                fatigueSummary = recommendation.fatigueSummary
                prescription = recommendation.deloadPrescription
                urgency = recommendation.urgency
                contributingFactors = recommendation.fatigueSummary.contributingFactors
            }

            // Fetch fatigue trend data for 7 days
            let fatigueAccumulations = try await fatigueTrackingService.getFatigueTrend(
                patientId: patientId,
                days: 7
            )

            // Convert to trend points for chart
            trendData = fatigueAccumulations.map { accumulation in
                FatigueTrendPoint(
                    date: accumulation.calculationDate,
                    fatigueScore: accumulation.fatigueScore,
                    band: accumulation.fatigueBand
                )
            }.sorted { $0.date < $1.date }

        } catch {
            self.error = error
            errorMessage = "Failed to load recovery data. Please try again."
            showError = true
        }

        isLoading = false
    }

    // MARK: - Activate Deload

    /// Activate the current deload prescription
    func activateDeload() async {
        guard let prescription = prescription else { return }

        isActivating = true
        showError = false

        do {
            try await deloadRecommendationService.activateDeload(
                patientId: patientId,
                prescription: prescription
            )

            showActivationSuccess = true
            urgency = .none // Clear the recommendation after activation

        } catch {
            self.error = error
            errorMessage = "Failed to activate deload. Please try again."
            showError = true
        }

        isActivating = false
    }

    // MARK: - Dismiss Recommendation

    /// Dismiss the current deload recommendation
    /// - Parameter reason: Optional reason for dismissal
    func dismissRecommendation(reason: String? = nil) async {
        isDismissing = true
        showError = false

        do {
            try await deloadRecommendationService.dismissRecommendation(
                patientId: patientId,
                reason: reason
            )

            showDismissalSuccess = true
            urgency = .none // Clear the recommendation after dismissal
            prescription = nil

        } catch {
            self.error = error
            errorMessage = "Failed to dismiss recommendation. Please try again."
            showError = true
        }

        isDismissing = false
    }

    // MARK: - Refresh

    /// Refresh all data (for pull-to-refresh)
    func refresh() async {
        await loadData()
    }

    // MARK: - Error Handling

    /// Clear any stored error
    func clearError() {
        error = nil
        showError = false
        errorMessage = ""
    }
}

// MARK: - Fatigue Trend Point

/// Data point for fatigue trend visualization
struct FatigueTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let fatigueScore: Double
    let band: FatigueBand

    /// Formatted date for chart labels
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    /// Formatted score text
    var formattedScore: String {
        String(format: "%.0f", fatigueScore)
    }
}

// MARK: - Preview Support

extension DeloadRecommendationViewModel {
    /// Preview instance with mock data showing deload recommended
    static var preview: DeloadRecommendationViewModel {
        let vm = DeloadRecommendationViewModel(patientId: UUID())

        vm.fatigueSummary = FatigueSummary(
            fatigueScore: 72.0,
            fatigueBand: "high",
            avgReadiness7d: 55.0,
            acuteChronicRatio: 1.45,
            consecutiveLowDays: 4,
            contributingFactors: [
                "Elevated acute:chronic workload ratio",
                "Consecutive low readiness days",
                "High average RPE in recent sessions"
            ]
        )

        vm.prescription = DeloadPrescription(
            durationDays: 7,
            loadReductionPct: 0.30,
            volumeReductionPct: 0.40,
            focus: "Active recovery and mobility work",
            suggestedStartDate: Date()
        )

        vm.urgency = .recommended
        vm.contributingFactors = vm.fatigueSummary?.contributingFactors ?? []

        // Mock trend data
        let calendar = Calendar.current
        vm.trendData = (0..<7).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -6 + daysAgo, to: Date()) ?? Date()
            let score = 45.0 + Double(daysAgo) * 5.0 + Double.random(in: -5...5)
            let band: FatigueBand = score > 70 ? .high : (score > 50 ? .moderate : .low)
            return FatigueTrendPoint(date: date, fatigueScore: score, band: band)
        }

        return vm
    }

    /// Preview instance with no deload needed
    static var noDeloadPreview: DeloadRecommendationViewModel {
        let vm = DeloadRecommendationViewModel(patientId: UUID())

        vm.fatigueSummary = FatigueSummary(
            fatigueScore: 35.0,
            fatigueBand: "low",
            avgReadiness7d: 78.0,
            acuteChronicRatio: 1.05,
            consecutiveLowDays: 0,
            contributingFactors: []
        )

        vm.prescription = nil
        vm.urgency = .none
        vm.contributingFactors = []

        // Mock trend data
        let calendar = Calendar.current
        vm.trendData = (0..<7).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -6 + daysAgo, to: Date()) ?? Date()
            let score = 30.0 + Double.random(in: -5...10)
            return FatigueTrendPoint(date: date, fatigueScore: score, band: .low)
        }

        return vm
    }
}
