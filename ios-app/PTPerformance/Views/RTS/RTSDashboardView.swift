//
//  RTSDashboardView.swift
//  PTPerformance
//
//  Main Return-to-Sport dashboard view for patients
//  Shows protocol overview, current phase, readiness score, and recent activity
//

import SwiftUI

// MARK: - RTS Dashboard View

/// Main RTS view for a patient showing protocol overview
struct RTSDashboardView: View {
    let patientId: UUID
    @StateObject private var viewModel = RTSProtocolViewModel()

    @State private var showCriteriaSheet = false
    @State private var showTestRecordingSheet = false
    @State private var selectedPhase: RTSPhase?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.currentProtocol == nil {
                loadingView
            } else if let error = viewModel.errorMessage, viewModel.currentProtocol == nil {
                errorView(error)
            } else if let rtsProtocol = viewModel.currentProtocol {
                contentView(rtsProtocol)
            } else {
                emptyStateView
            }
        }
        .navigationTitle("Return to Sport")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.loadData(patientId: patientId)
        }
        .task {
            await viewModel.loadData(patientId: patientId)
        }
        .sheet(isPresented: $showCriteriaSheet) {
            if let phase = viewModel.currentPhase,
               let protocolId = viewModel.currentProtocol?.id {
                NavigationStack {
                    RTSCriteriaChecklistView(
                        phaseId: phase.id,
                        protocolId: protocolId
                    )
                }
            }
        }
    }

    // MARK: - Content View

    private func contentView(_ rtsProtocol: RTSProtocol) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Current phase card with traffic light
                currentPhaseCard

                // Progress timeline
                if !viewModel.phases.isEmpty {
                    RTSPhaseProgressView(
                        phases: viewModel.phases,
                        currentPhaseId: rtsProtocol.currentPhaseId,
                        onPhaseSelect: { phase in
                            selectedPhase = phase
                        }
                    )
                    .padding(.horizontal)
                }

                // Readiness score gauge
                if let score = viewModel.latestReadinessScore {
                    RTSReadinessGaugeView(score: score, showDetails: true)
                        .padding(.horizontal)
                }

                // Quick actions
                quickActionsSection

                // Recent activity
                recentActivitySection
            }
            .padding(.bottom, Spacing.xl)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Current Phase Card

    private var currentPhaseCard: some View {
        VStack(spacing: Spacing.md) {
            if let phase = viewModel.currentPhase {
                HStack(spacing: Spacing.md) {
                    // Traffic light indicator
                    RTSTrafficLightBadge(
                        level: phase.activityLevel,
                        size: .large
                    )

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Current Phase")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(phase.phaseName)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(phase.statusText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Days in phase
                    if let days = phase.daysInPhase {
                        VStack(spacing: Spacing.xxs) {
                            Text("\(days)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Text("days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Phase description
                Text(phase.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Progress bar (if target duration exists)
                if let progress = phase.progressPercentage {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        HStack {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(phase.activityLevel.color)
                                    .frame(width: geometry.size.width * progress)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            } else {
                // No active phase
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "flag.fill")
                        .font(.largeTitle)
                        .foregroundColor(.modusCyan)

                    Text("Ready to Begin")
                        .font(.headline)

                    Text("Your return-to-sport journey will start soon")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
        .padding(.horizontal)
        .padding(.top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(currentPhaseAccessibilityLabel)
    }

    private var currentPhaseAccessibilityLabel: String {
        if let phase = viewModel.currentPhase {
            var label = "Current phase: \(phase.phaseName), \(phase.activityLevel.displayName)"
            if let days = phase.daysInPhase {
                label += ", \(days) days in phase"
            }
            return label
        }
        return "Ready to begin your return-to-sport journey"
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    RTSQuickActionButton(
                        title: "Record Test",
                        icon: "checkmark.circle",
                        color: .blue
                    ) {
                        HapticFeedback.light()
                        showTestRecordingSheet = true
                    }

                    RTSQuickActionButton(
                        title: "View Criteria",
                        icon: "list.bullet.clipboard",
                        color: .purple
                    ) {
                        HapticFeedback.light()
                        showCriteriaSheet = true
                    }

                    RTSQuickActionButton(
                        title: "Progress",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green
                    ) {
                        HapticFeedback.light()
                        // Navigate to progress view
                    }

                    RTSQuickActionButton(
                        title: "Resources",
                        icon: "book.fill",
                        color: .orange
                    ) {
                        HapticFeedback.light()
                        // Navigate to resources
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)

            if viewModel.recentActivity.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "clock")
                            .font(.title2)
                            .foregroundColor(.secondary)

                        Text("No recent activity")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, Spacing.lg)
                    Spacer()
                }
                .background(Color(.systemBackground))
                .cornerRadius(CornerRadius.md)
                .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentActivity.prefix(5)) { activity in
                        RTSActivityRow(activity: activity)

                        if activity.id != viewModel.recentActivity.prefix(5).last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(CornerRadius.md)
                .adaptiveShadow(Shadow.subtle)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading your RTS journey...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Load")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Button {
                Task {
                    await viewModel.loadData(patientId: patientId)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.headline)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(Color.modusCyan)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.md)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        EmptyStateView(
            title: "No Active Protocol",
            message: "You don't have an active Return-to-Sport protocol yet. Your therapist will set one up for you.",
            icon: "figure.run",
            iconColor: .blue
        )
    }
}

// MARK: - Quick Action Button

/// Compact quick action button for dashboard
private struct RTSQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(width: 80)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to \(title.lowercased())")
    }
}

// MARK: - RTS Activity Row

/// Single activity row in the recent activity list
private struct RTSActivityRow: View {
    let activity: RTSActivityItem

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(activity.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: activity.icon)
                    .font(.body)
                    .foregroundColor(activity.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(activity.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Timestamp
            Text(activity.formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activity.title), \(activity.subtitle), \(activity.formattedDate)")
    }
}

// MARK: - Traffic Light Badge

/// Reusable traffic light indicator badge
struct RTSTrafficLightBadge: View {
    let level: RTSTrafficLight
    var size: BadgeSize = .medium

    /// Use the canonical top-level BadgeSize enum
    typealias BadgeSize = PTPerformance.BadgeSize

    /// Traffic light badge dimension based on size
    private var badgeDimension: CGFloat {
        switch size {
        case .small: return 24
        case .medium: return 36
        case .large: return 48
        }
    }

    /// Traffic light icon size based on size
    private var badgeIconSize: Font {
        switch size {
        case .small: return .caption
        case .medium: return .body
        case .large: return .title2
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(level.color.opacity(0.2))
                .frame(width: badgeDimension, height: badgeDimension)

            Circle()
                .fill(level.color)
                .frame(width: badgeDimension * 0.7, height: badgeDimension * 0.7)

            Image(systemName: level.icon)
                .font(badgeIconSize)
                .foregroundColor(.white)
        }
        .accessibilityLabel("\(level.displayName) status")
    }
}

// MARK: - Preview

#if DEBUG
struct RTSDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RTSDashboardView(patientId: UUID())
        }
    }
}
#endif
