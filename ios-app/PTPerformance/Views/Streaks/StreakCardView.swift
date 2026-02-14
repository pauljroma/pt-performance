//
//  StreakCardView.swift
//  PTPerformance
//
//  ACP-836: Streak Tracking Feature
//  ACP-1029: Streak System Gamification - Growing flame icons, streak freeze indicator
//  Compact streak card for display on home screen and other views
//

import SwiftUI

/// Compact streak card showing current streak with navigation to full dashboard
/// ACP-1029: Enhanced with growing flame icon, streak freeze indicator, and comeback state
struct StreakCardView: View {
    // MARK: - Properties

    let patientId: UUID

    @StateObject private var viewModel: StreakCardViewModel
    @StateObject private var freezeService = StreakFreezeService.shared
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
        _viewModel = StateObject(wrappedValue: StreakCardViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        NavigationLink {
            StreakDashboardView(patientId: patientId)
        } label: {
            HStack(spacing: 16) {
                // ACP-1029: Growing flame icon that upgrades at milestones
                GrowingFlameIcon(streak: viewModel.currentStreak, size: 18)
                    .overlay(
                        // Streak count overlay
                        Text("\(viewModel.currentStreak)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .offset(y: 14)
                    )
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Current Streak")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)

                        Spacer()

                        // ACP-1029: Streak freeze indicator
                        if freezeService.inventory.availableCount > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "shield.checkered")
                                    .font(.system(size: 10))
                                Text("\(freezeService.inventory.availableCount)")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(Color.modusTealAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.modusTealAccent.opacity(0.15))
                            )
                        }

                        if viewModel.isAtRisk {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                Text("At Risk")
                                    .font(.caption)
                            }
                            .foregroundColor(.orange)
                        } else if viewModel.currentStreak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                Text("Safe")
                                    .font(.caption)
                            }
                            .foregroundColor(Color.modusTealAccent)
                        }
                    }

                    Text(viewModel.motivationalMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    // Mini progress to next badge
                    if let nextBadge = viewModel.badgeLevel.nextBadge {
                        HStack(spacing: 4) {
                            ProgressView(value: viewModel.progressToNextBadge)
                                .tint(Color.modusCyan)

                            Text("\(viewModel.daysToNextBadge)d to \(nextBadge.displayName)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .adaptiveShadow(Shadow.subtle)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current streak \(viewModel.currentStreak) days, \(viewModel.motivationalMessage)")
        .task {
            await viewModel.loadData()
        }
    }
}

/// Minimal streak indicator for toolbar or compact spaces
/// ACP-1029: Enhanced with growing flame icon
struct StreakIndicator: View {
    let currentStreak: Int
    let isAtRisk: Bool

    var body: some View {
        HStack(spacing: 4) {
            GrowingFlameIcon(streak: currentStreak, size: 10)

            Text("\(currentStreak)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(
            Capsule()
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .accessibilityLabel("Streak \(currentStreak) days\(isAtRisk ? ", at risk" : "")")
    }
}

// MARK: - ViewModel

@MainActor
class StreakCardViewModel: ObservableObject {
    // MARK: - Properties

    private let patientId: UUID
    private let service: StreakTrackingService

    @Published var currentStreak = 0
    @Published var longestStreak = 0
    @Published var isAtRisk = true

    // MARK: - Initialization

    init(patientId: UUID, service: StreakTrackingService? = nil) {
        self.patientId = patientId
        self.service = service ?? StreakTrackingService.shared
    }

    // MARK: - Computed Properties

    var streakColor: Color {
        if currentStreak == 0 { return .gray }
        if currentStreak < 7 { return .orange }
        if currentStreak < 30 { return Color.modusCyan }
        return Color.modusTealAccent
    }

    var motivationalMessage: String {
        StreakBadge.badge(for: currentStreak).description
    }

    var badgeLevel: StreakBadge {
        StreakBadge.badge(for: longestStreak)
    }

    var progressToNextBadge: Double {
        guard let nextBadge = badgeLevel.nextBadge else { return 1.0 }
        let currentDays = longestStreak
        let currentBadgeMin = badgeLevel.minDays
        let nextBadgeMin = nextBadge.minDays
        let progress = Double(currentDays - currentBadgeMin) / Double(nextBadgeMin - currentBadgeMin)
        return min(max(progress, 0), 1)
    }

    var daysToNextBadge: Int {
        guard let nextBadge = badgeLevel.nextBadge else { return 0 }
        return max(0, nextBadge.minDays - longestStreak)
    }

    // MARK: - Methods

    func loadData() async {
        do {
            if let streak = try await service.getCombinedStreak(for: patientId) {
                currentStreak = streak.currentStreak
                longestStreak = streak.longestStreak
                isAtRisk = streak.isAtRisk

                // ACP-1029: Check for milestones and freeze rewards
                StreakFreezeService.shared.checkMilestone(for: currentStreak)
                StreakFreezeService.shared.checkAndAwardFreezes(for: currentStreak)
                StreakFreezeService.shared.evaluateComebackState(
                    currentStreak: currentStreak,
                    lastActivityDate: streak.lastActivityDate
                )
            }
        } catch {
            DebugLogger.shared.warning("StreakCardView", "Error loading data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Previews

#Preview("Streak Card - Active") {
    StreakCardView(patientId: UUID())
        .padding()
}

#Preview("Streak Card - At Risk") {
    StreakCardView(patientId: UUID())
        .padding()
}

#Preview("Streak Indicator") {
    HStack {
        StreakIndicator(currentStreak: 7, isAtRisk: false)
        StreakIndicator(currentStreak: 30, isAtRisk: false)
        StreakIndicator(currentStreak: 100, isAtRisk: false)
        StreakIndicator(currentStreak: 0, isAtRisk: true)
    }
    .padding()
}
