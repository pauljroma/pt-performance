//
//  StreakCardView.swift
//  PTPerformance
//
//  ACP-836: Streak Tracking Feature
//  Compact streak card for display on home screen and other views
//

import SwiftUI

/// Compact streak card showing current streak with navigation to full dashboard
struct StreakCardView: View {
    // MARK: - Properties

    let patientId: UUID

    @StateObject private var viewModel: StreakCardViewModel
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
                // Streak flame
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [viewModel.streakColor.opacity(0.3), viewModel.streakColor.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 56, height: 56)

                    VStack(spacing: 0) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18))
                            .foregroundColor(viewModel.streakColor)

                        Text("\(viewModel.currentStreak)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Current Streak")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)

                        Spacer()

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
                            .foregroundColor(.green)
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
                                .tint(viewModel.badgeLevel.color)

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
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .adaptiveShadow(Shadow.subtle)
            )
        }
        .buttonStyle(.plain)
        .task {
            await viewModel.loadData()
        }
    }
}

/// Minimal streak indicator for toolbar or compact spaces
struct StreakIndicator: View {
    let currentStreak: Int
    let isAtRisk: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundColor(isAtRisk ? .orange : .red)

            Text("\(currentStreak)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
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
        if currentStreak < 30 { return .red }
        return .purple
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
            }
        } catch {
            #if DEBUG
            print("[StreakCard] Error loading data: \(error)")
            #endif
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
        StreakIndicator(currentStreak: 3, isAtRisk: true)
        StreakIndicator(currentStreak: 0, isAtRisk: true)
    }
    .padding()
}
