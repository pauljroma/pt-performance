//
//  DemoDataProvider.swift
//  PTPerformance
//
//  Phase 4: Demo Mode & Testing Utilities
//  Provides demo/mock data for development and testing the X2Index Command Center
//

import Foundation
import SwiftUI

// MARK: - Demo Data Provider

/// Provides demo/mock data for development and testing
/// Used when USE_DEMO_DATA environment variable is set or authentication is unavailable
enum DemoDataProvider {

    // MARK: - Safety Incidents

    static var sampleSafetyIncidents: [SafetyIncident] {
        [
            SafetyIncident(
                id: UUID(),
                athleteId: UUID(),
                incidentType: .painThreshold,
                severity: .high,
                description: "Patient reported sudden increase in knee pain (8/10) during squat exercise",
                status: .open,
                createdAt: Date().addingTimeInterval(-3600) // 1 hour ago
            ),
            SafetyIncident(
                id: UUID(),
                athleteId: UUID(),
                incidentType: .vitalAnomaly,
                severity: .medium,
                description: "Recovery score dropped 30% from baseline over 3 days",
                status: .open,
                createdAt: Date().addingTimeInterval(-7200) // 2 hours ago
            ),
            SafetyIncident(
                id: UUID(),
                athleteId: UUID(),
                incidentType: .missedEscalation,
                severity: .low,
                description: "Patient missed 2 consecutive scheduled sessions",
                status: .open,
                createdAt: Date().addingTimeInterval(-86400) // 1 day ago
            ),
            SafetyIncident(
                id: UUID(),
                athleteId: UUID(),
                incidentType: .contradictoryData,
                severity: .medium,
                description: "Check-in reported high energy but objective metrics show poor recovery",
                status: .investigating,
                createdAt: Date().addingTimeInterval(-43200) // 12 hours ago
            ),
            SafetyIncident(
                id: UUID(),
                athleteId: UUID(),
                incidentType: .aiUncertainty,
                severity: .low,
                description: "AI model confidence below threshold for training recommendation",
                triggerData: [
                    "confidence_score": .double(0.45),
                    "claim_type": .string("workloadAdjustment")
                ],
                status: .open,
                createdAt: Date().addingTimeInterval(-7200) // 2 hours ago
            )
        ]
    }

    // MARK: - Conflict Groups

    static var sampleConflictGroups: [ConflictGroup] {
        [
            ConflictGroup(
                eventIds: [UUID(), UUID()],
                conflictType: .valueDiscrepancy,
                description: "HRV reading differs between Apple Health (62ms) and WHOOP (58ms)",
                timestamp: Date().addingTimeInterval(-1800) // 30 minutes ago
            ),
            ConflictGroup(
                eventIds: [UUID(), UUID()],
                conflictType: .sourceConflict,
                description: "Sleep duration: Apple Watch reports 7.5hrs, Oura Ring reports 8.2hrs",
                timestamp: Date().addingTimeInterval(-3600) // 1 hour ago
            ),
            ConflictGroup(
                eventIds: [UUID()],
                conflictType: .missingData,
                description: "Recovery score missing for yesterday - WHOOP sync failed",
                timestamp: Date().addingTimeInterval(-43200) // 12 hours ago
            ),
            ConflictGroup(
                eventIds: [UUID(), UUID()],
                conflictType: .timestampMismatch,
                description: "Workout logged at different times across Apple Health and manual entry",
                timestamp: Date().addingTimeInterval(-7200) // 2 hours ago
            ),
            ConflictGroup(
                eventIds: [UUID(), UUID(), UUID()],
                conflictType: .duplicateEntry,
                description: "Same workout appears to be logged 3 times from different sources",
                timestamp: Date().addingTimeInterval(-14400) // 4 hours ago
            )
        ]
    }

    // MARK: - Weekly Report Summaries

    static var sampleReportSummaries: [WeeklyReportSummary] {
        let calendar = Calendar.current
        let today = Date()

        return [
            WeeklyReportSummary(
                title: "Week 6",
                dateRange: "Feb 3 - Feb 9",
                patientCount: 14,
                isReady: true,
                highlights: "Overall adherence improved to 87%. 3 patients hit new PRs.",
                generatedAt: calendar.date(byAdding: .day, value: -1, to: today)
            ),
            WeeklyReportSummary(
                title: "Week 5",
                dateRange: "Jan 27 - Feb 2",
                patientCount: 14,
                isReady: true,
                highlights: "3 patients achieved their ROM goals. 1 escalation resolved.",
                generatedAt: calendar.date(byAdding: .day, value: -8, to: today)
            ),
            WeeklyReportSummary(
                title: "Week 4",
                dateRange: "Jan 20 - Jan 26",
                patientCount: 12,
                isReady: true,
                highlights: "New patient onboarded successfully. Average pain scores down 15%.",
                generatedAt: calendar.date(byAdding: .day, value: -15, to: today)
            ),
            WeeklyReportSummary(
                title: "Week 3",
                dateRange: "Jan 13 - Jan 19",
                patientCount: 12,
                isReady: true,
                highlights: "Strong adherence week at 91%. 2 patients graduated from rehab phase.",
                generatedAt: calendar.date(byAdding: .day, value: -22, to: today)
            )
        ]
    }

    // MARK: - Trend Insights

    static var sampleTrendInsights: [TrendInsight] {
        [
            TrendInsight(
                id: UUID(),
                type: .bestEver,
                title: "Best Week Ever!",
                message: "Patient adherence hit 95% this week - highest on record",
                severity: .positive,
                metricType: .sessionAdherence,
                relatedDate: Date(),
                actionable: false,
                recommendation: nil
            ),
            TrendInsight(
                id: UUID(),
                type: .warning,
                title: "Pain Trending Up",
                message: "Average pain level increased 15% over the past 2 weeks",
                severity: .warning,
                metricType: .painLevel,
                relatedDate: Date(),
                actionable: true,
                recommendation: "Consider reducing workout intensity or scheduling a check-in"
            ),
            TrendInsight(
                id: UUID(),
                type: .pattern,
                title: "Monday Motivation",
                message: "Sessions completed on Mondays have 40% better adherence",
                severity: .neutral,
                metricType: .sessionAdherence,
                relatedDate: nil,
                actionable: true,
                recommendation: "Schedule more critical exercises on Mondays"
            ),
            TrendInsight(
                id: UUID(),
                type: .recovery,
                title: "Recovery Improving",
                message: "Average recovery score up 12% compared to last month",
                severity: .positive,
                metricType: .recoveryScore,
                relatedDate: Date().addingTimeInterval(-604800), // 1 week ago
                actionable: false,
                recommendation: nil
            ),
            TrendInsight(
                id: UUID(),
                type: .milestone,
                title: "Strength Milestone",
                message: "3 patients achieved new personal records this week",
                severity: .positive,
                metricType: .strengthProgress,
                relatedDate: Date(),
                actionable: false,
                recommendation: nil
            )
        ]
    }

    // MARK: - Sample Data Conflicts

    static var sampleDataConflicts: [DataConflict] {
        DataConflict.generateSampleConflicts(count: 5)
    }
}

// MARK: - ProcessInfo Extension for Demo Mode

extension ProcessInfo {
    /// Whether the app is running in demo mode
    /// Demo mode is enabled via USE_DEMO_DATA environment variable or debug_demo_mode UserDefaults
    static var isDemoMode: Bool {
        #if DEBUG
        // Check environment variable first (for UI tests and launch args)
        if processInfo.environment["USE_DEMO_DATA"] == "1" {
            return true
        }
        // Check UserDefaults for debug toggle in settings
        return UserDefaults.standard.bool(forKey: "debug_demo_mode")
        #else
        return false
        #endif
    }
}

// MARK: - Environment Key for Demo Mode

private struct UseDemoDataKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    /// Whether to use demo data in views
    /// Can be set via environment modifier for previews
    var useDemoData: Bool {
        get { self[UseDemoDataKey.self] }
        set { self[UseDemoDataKey.self] = newValue }
    }
}

// MARK: - View Modifier for Demo Mode

extension View {
    /// Enable demo mode for this view and its descendants
    func demoMode(_ enabled: Bool = true) -> some View {
        self.environment(\.useDemoData, enabled)
    }
}

// MARK: - AppState Preview Extension

#if DEBUG
extension AppState {
    /// Preview instance with demo authentication state
    static var preview: AppState {
        let state = AppState()
        state.isAuthenticated = true
        state.userId = UUID().uuidString
        state.userRole = .therapist
        return state
    }

    /// Preview instance for patient role
    static var patientPreview: AppState {
        let state = AppState()
        state.isAuthenticated = true
        state.userId = UUID().uuidString
        state.userRole = .patient
        return state
    }
}
#endif
