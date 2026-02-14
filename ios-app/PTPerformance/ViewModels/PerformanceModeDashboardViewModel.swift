//
//  PerformanceModeDashboardViewModel.swift
//  PTPerformance
//
//  ViewModel for the Performance Mode Dashboard
//  Extracted from PerformanceModeDashboardView.swift
//

import Foundation
import SwiftUI

// MARK: - Time Range Enum

enum PerformanceTimeRange: String, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"

    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "3 Months"
        }
    }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        }
    }
}

// MARK: - Performance Recommendation Model

struct PerformanceRecommendation: Identifiable {
    var id: String { "\(icon)-\(text)" }
    let text: String
    let icon: String
    let color: Color
}

// MARK: - Performance Dashboard ViewModel

@MainActor
class PerformanceModeDashboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var acwrValue: Double = 0
    @Published var acwrStatus: ACWRStatus = .unknown
    @Published var readinessScore: Double = 0
    @Published var fatigueBand: FatigueBand = .low
    @Published var acuteLoad: Double = 0
    @Published var chronicLoad: Double = 0
    @Published var fatigueTrend: [FatigueAccumulation] = []
    @Published var consecutiveLowReadinessDays: Int = 0
    @Published var recommendations: [PerformanceRecommendation] = []

    // Readiness factors
    @Published var sleepQuality: String = "Not checked in"
    @Published var hrvStatus: String = "Not tracked"
    @Published var recoveryStatus: String = "Not checked in"

    private let fatigueService = FatigueTrackingService.shared
    private let readinessService = ReadinessService()
    private var hasReadinessData = false

    var acwrColor: Color {
        acwrStatus.color
    }

    var acwrStatusIcon: String {
        acwrStatus.icon
    }

    var readinessColor: Color {
        ReadinessColor.color(for: readinessScore)
    }

    var fatigueBandColor: Color {
        fatigueBand.color
    }

    /// Tracks the last time range used so refresh can forward it.
    private var lastTimeRange: PerformanceTimeRange = .week

    func loadData(patientId: UUID, timeRange: PerformanceTimeRange = .week) async {
        lastTimeRange = timeRange
        await performLoad(patientId: patientId, timeRange: timeRange)
    }

    func refresh(patientId: UUID) async {
        await performLoad(patientId: patientId, timeRange: lastTimeRange)
    }

    private func performLoad(patientId: UUID, timeRange: PerformanceTimeRange) async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        // Load fatigue data
        do {
            try await fatigueService.fetchCurrentFatigue(patientId: patientId)
            if let fatigue = fatigueService.currentFatigue {
                acwrValue = fatigue.acuteChronicRatio ?? 1.0
                acwrStatus = ACWRStatus.status(for: acwrValue)
                fatigueBand = fatigue.fatigueBand
                acuteLoad = fatigue.trainingLoad7d ?? 0
                chronicLoad = fatigue.trainingLoad14d ?? 0
                consecutiveLowReadinessDays = fatigue.consecutiveLowReadiness
            }
        } catch {
            DebugLogger.shared.log("[PerformanceDashboardVM] Failed to load fatigue: \(error)", level: .warning)
        }

        // Load fatigue trend for chart (based on selected time range)
        do {
            let trendData = try await fatigueService.getFatigueTrend(patientId: patientId, days: timeRange.days)
            fatigueTrend = trendData
        } catch {
            DebugLogger.shared.log("[PerformanceDashboardVM] Failed to load fatigue trend: \(error)", level: .warning)
            fatigueTrend = []
        }

        // Load readiness
        hasReadinessData = false
        do {
            if let readiness = try await readinessService.getTodayReadiness(for: patientId) {
                readinessScore = readiness.readinessScore ?? 0
                hasReadinessData = true
                updateReadinessFactors(from: readiness)
            } else {
                sleepQuality = "Not checked in"
                hrvStatus = "Not tracked"
                recoveryStatus = "Not checked in"
                readinessScore = 0
            }
        } catch {
            DebugLogger.shared.log("[PerformanceDashboardVM] Failed to load readiness: \(error)", level: .warning)
            sleepQuality = "Not checked in"
            hrvStatus = "Not tracked"
            recoveryStatus = "Not checked in"
        }

        // Build dynamic recommendations from real data
        buildRecommendations()
    }

    private func updateReadinessFactors(from readiness: DailyReadiness) {
        if let sleep = readiness.sleepHours {
            sleepQuality = sleep >= 7 ? "Good" : sleep >= 5 ? "Fair" : "Poor"
        } else {
            sleepQuality = "Not logged"
        }

        // HRV is not tracked in the current DailyReadiness model
        hrvStatus = "Not tracked"

        // Derive recovery status from energy and soreness levels
        if let energy = readiness.energyLevel, let soreness = readiness.sorenessLevel {
            let recoveryScore = (energy + (10 - soreness)) / 2  // Higher is better
            recoveryStatus = recoveryScore >= 7 ? "Recovered" : recoveryScore >= 5 ? "Moderate" : "Fatigued"
        } else if let energy = readiness.energyLevel {
            recoveryStatus = energy >= 7 ? "Recovered" : energy >= 5 ? "Moderate" : "Fatigued"
        } else {
            recoveryStatus = "Not logged"
        }
    }

    private func buildRecommendations() {
        var recs: [PerformanceRecommendation] = []

        // 1. ACWR-based recommendation (always relevant if we have data)
        if acwrStatus != .unknown {
            recs.append(PerformanceRecommendation(
                text: acwrStatus.recommendation,
                icon: acwrStatus.icon,
                color: acwrStatus.color
            ))
        }

        // 2. Fatigue-band-specific recommendation
        switch fatigueBand {
        case .high:
            recs.append(PerformanceRecommendation(
                text: "Fatigue is elevated -- prioritize recovery and consider reducing volume",
                icon: "battery.25",
                color: .orange
            ))
        case .critical:
            recs.append(PerformanceRecommendation(
                text: "Fatigue is critical -- a deload period is strongly recommended",
                icon: "battery.0",
                color: .red
            ))
        case .moderate:
            recs.append(PerformanceRecommendation(
                text: "Moderate fatigue detected -- monitor how you feel during warm-ups",
                icon: "battery.75",
                color: .yellow
            ))
        case .low:
            break // No recommendation needed for low fatigue
        }

        // 3. Sleep-based recommendation (only if data shows poor sleep)
        if sleepQuality == "Poor" {
            recs.append(PerformanceRecommendation(
                text: "Sleep was below 5 hours -- aim for 7-8 hours for optimal recovery",
                icon: "moon.fill",
                color: .purple
            ))
        } else if sleepQuality == "Fair" {
            recs.append(PerformanceRecommendation(
                text: "Sleep was fair -- try to get closer to 7-8 hours tonight",
                icon: "moon.fill",
                color: .yellow
            ))
        }

        // 4. Recovery-based recommendation
        if recoveryStatus == "Fatigued" {
            recs.append(PerformanceRecommendation(
                text: "Recovery is low -- consider active recovery or a lighter session",
                icon: "figure.walk",
                color: .orange
            ))
        }

        // 5. Consecutive low readiness days
        if consecutiveLowReadinessDays >= 3 {
            recs.append(PerformanceRecommendation(
                text: "\(consecutiveLowReadinessDays) consecutive low readiness days -- consider a deload",
                icon: "exclamationmark.triangle.fill",
                color: .red
            ))
        } else if consecutiveLowReadinessDays >= 2 {
            recs.append(PerformanceRecommendation(
                text: "\(consecutiveLowReadinessDays) consecutive low readiness days -- monitor closely",
                icon: "exclamationmark.triangle",
                color: .orange
            ))
        }

        // 6. If no readiness check-in today, prompt
        if !hasReadinessData {
            recs.append(PerformanceRecommendation(
                text: "Complete today's readiness check-in for personalized recommendations",
                icon: "plus.circle",
                color: .modusCyan
            ))
        }

        recommendations = recs
    }
}
