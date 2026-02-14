//
//  RehabModeDashboardViewModel.swift
//  PTPerformance
//
//  ViewModel for the Rehab Mode Dashboard
//  Extracted from RehabModeDashboardView.swift
//

import Foundation
import SwiftUI

// MARK: - Rehab Mode Dashboard ViewModel

@MainActor
class RehabModeDashboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var todayPainScore: Int?
    @Published var weeklyAveragePain: Double?
    @Published var painHistory: [PainHistoryEntry] = []
    @Published var activePainRegions: [PainLocation] = []
    @Published var deloadRecommendation: DeloadRecommendation?
    @Published var recoveryTips: [String] = []

    /// Whether recovery tips are contextual to a real deload recommendation
    @Published var isDeloadContextual: Bool = false

    private let supabase = PTSupabaseClient.shared
    private let deloadService = DeloadRecommendationService.shared

    var painTrendIcon: String {
        guard let today = todayPainScore, let avg = weeklyAveragePain else {
            return "minus"
        }
        if Double(today) < avg {
            return "arrow.down.right"
        } else if Double(today) > avg {
            return "arrow.up.right"
        }
        return "minus"
    }

    var painTrendColor: Color {
        guard let today = todayPainScore, let avg = weeklyAveragePain else {
            return .secondary
        }
        if Double(today) < avg {
            return .green
        } else if Double(today) > avg {
            return .red
        }
        return .secondary
    }

    var painTrendLabel: String {
        guard let today = todayPainScore, let avg = weeklyAveragePain else {
            return "N/A"
        }
        if Double(today) < avg {
            return "Improving"
        } else if Double(today) > avg {
            return "Worsening"
        }
        return "Stable"
    }

    func loadData() async {
        guard !isLoading else { return }
        await fetchAllData(setErrorOnAuthFailure: true)
    }

    func refresh() async {
        await fetchAllData(setErrorOnAuthFailure: false, showLoading: false)
    }

    /// Shared data-fetching logic used by both `loadData()` and `refresh()`.
    /// - Parameters:
    ///   - setErrorOnAuthFailure: When `true`, sets `errorMessage` if the user
    ///     is not authenticated (used on initial load). On refresh, silently returns.
    ///   - showLoading: When `true`, sets `isLoading` during the fetch. Pass `false`
    ///     on refresh to avoid replacing existing content with a loading spinner.
    private func fetchAllData(setErrorOnAuthFailure: Bool, showLoading: Bool = true) async {
        if showLoading { isLoading = true }
        defer { if showLoading { isLoading = false } }

        guard let patientIdString = supabase.userId,
              let patientId = UUID(uuidString: patientIdString) else {
            if setErrorOnAuthFailure {
                errorMessage = "Please sign in to view your rehab dashboard."
            }
            return
        }

        // Load deload recommendation (real service)
        do {
            try await deloadService.fetchRecommendation(patientId: patientId)
            deloadRecommendation = deloadService.recommendation
        } catch {
            DebugLogger.shared.log("[RehabDashboardVM] Failed to load deload: \(error)", level: .warning)
        }

        // Pain tracking: no PainTrackingService exists yet, so use proper empty states
        // These will be nil/empty, letting the UI show appropriate empty states
        todayPainScore = nil
        weeklyAveragePain = nil
        painHistory = []
        activePainRegions = []

        // Build recovery tips contextual to the deload recommendation, if available
        buildRecoveryTips()
    }

    private func buildRecoveryTips() {
        if let deload = deloadRecommendation, deload.deloadRecommended {
            // Contextual tips based on actual deload recommendation
            isDeloadContextual = true
            var tips: [String] = []

            // Urgency-specific advice
            switch deload.urgency {
            case .required:
                tips.append("A deload period is required -- reduce training intensity immediately")
            case .recommended:
                tips.append("A deload week is recommended to support recovery")
            case .suggested:
                tips.append("Consider a lighter training week if fatigue persists")
            case .none:
                break
            }

            // Prescription-specific advice
            if let prescription = deload.deloadPrescription {
                tips.append("Reduce load by \(prescription.formattedLoadReduction) and volume by \(prescription.formattedVolumeReduction)")
                if !prescription.focus.isEmpty {
                    tips.append("Focus area: \(prescription.focus)")
                }
            }

            // Contributing factors
            let factors = deload.fatigueSummary.contributingFactors
            if factors.contains(where: { $0.lowercased().contains("sleep") }) {
                tips.append("Prioritize sleep quality -- it's a key factor in your fatigue")
            }
            if factors.contains(where: { $0.lowercased().contains("rpe") || $0.lowercased().contains("intensity") }) {
                tips.append("Recent training intensity has been high -- use lighter loads")
            }

            // Always include a general recovery tip
            tips.append("Stay hydrated and prioritize nutrition for recovery")

            recoveryTips = tips
        } else {
            // Generic wellness tips when no deload recommendation is active
            isDeloadContextual = false
            recoveryTips = [
                "Prioritize quality sleep for optimal recovery",
                "Stay hydrated throughout the day",
                "Include mobility work in your routine",
                "Listen to your body and adjust training as needed"
            ]
        }
    }
}

// MARK: - Pain History Entry

struct PainHistoryEntry: Identifiable {
    let id = UUID()
    let date: Date
    let score: Int
}
