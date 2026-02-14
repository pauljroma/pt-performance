//
//  TodayModeStatusCard.swift
//  PTPerformance
//
//  Mode-specific status card extracted from TodaySessionView.
//  Displays relevant metrics for the current training mode and navigates
//  to the full dashboard on tap.
//
//  ACP-MODE: Supports Rehab, Strength, and Performance modes.
//

import SwiftUI

/// Standalone view that renders the correct mode-specific status card
/// based on the patient's current training mode.
///
/// Extracted from `TodaySessionView.modeStatusCard` to reduce file size
/// and improve readability.
struct TodayModeStatusCard: View {
    // MARK: - Dependencies

    /// The current training mode (rehab / strength / performance).
    let currentMode: Mode

    /// View model that holds the loaded status-card metrics.
    @ObservedObject var modeStatusVM: ModeStatusCardViewModel

    /// Whether the current user has a valid user ID (non-nil means yes).
    /// Strength and Performance cards are only shown when this is true.
    let hasUserId: Bool

    // MARK: - Actions

    /// Called when the user wants to open the Rehab dashboard.
    var onShowRehabDashboard: () -> Void = {}

    /// Called when the user wants to open the Strength dashboard.
    var onShowStrengthDashboard: () -> Void = {}

    /// Called when the user wants to open the Performance dashboard.
    var onShowPerformanceDashboard: () -> Void = {}

    /// Called when the user wants to perform a readiness check-in
    /// (from the Performance mode card).
    var onShowReadinessCheckIn: () -> Void = {}

    // MARK: - Body

    var body: some View {
        switch currentMode {
        case .rehab:
            rehabCard

        case .strength:
            if hasUserId {
                strengthCard
            }

        case .performance:
            if hasUserId {
                performanceCard
            }
        }
    }

    // MARK: - Private Sub-views

    private var rehabCard: some View {
        RehabModeStatusCard(
            todayPainScore: modeStatusVM.todayPainScore,
            previousPainScore: modeStatusVM.previousPainScore,
            activePainRegions: modeStatusVM.activePainRegions,
            hasActiveAlerts: modeStatusVM.hasActiveAlerts,
            alertCount: modeStatusVM.alertCount,
            deloadUrgency: modeStatusVM.deloadUrgency,
            onLogPain: {
                HapticFeedback.light()
                onShowRehabDashboard()
            },
            onViewAlerts: {
                HapticFeedback.light()
                onShowRehabDashboard()
            },
            onViewDashboard: {
                HapticFeedback.light()
                onShowRehabDashboard()
            }
        )
    }

    private var strengthCard: some View {
        StrengthModeStatusCard(
            estimatedTotal: modeStatusVM.estimatedTotal,
            topLifts: modeStatusVM.topLifts,
            recentPRs: modeStatusVM.recentPRs,
            volumeTrend: modeStatusVM.volumeTrend,
            currentStreak: modeStatusVM.strengthStreak,
            unit: WeightUnit.defaultUnit,
            onTapCard: {
                HapticFeedback.light()
                onShowStrengthDashboard()
            },
            onViewPRs: {
                HapticFeedback.light()
                onShowStrengthDashboard()
            }
        )
    }

    private var performanceCard: some View {
        PerformanceModeStatusCard(
            statusData: modeStatusVM.performanceStatusData,
            onTapCard: {
                HapticFeedback.light()
                onShowPerformanceDashboard()
            },
            onCheckIn: {
                HapticFeedback.light()
                onShowReadinessCheckIn()
            }
        )
    }
}
