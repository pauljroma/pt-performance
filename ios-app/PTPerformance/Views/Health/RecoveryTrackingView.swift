import SwiftUI

/// ACP-901: Main Recovery Tracking Dashboard
/// Displays quick-log buttons, weekly summary, recent sessions, and streak tracking
struct RecoveryTrackingView: View {
    @StateObject private var viewModel = RecoveryTrackingViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.recentSessions.isEmpty {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle("Recovery Tracking")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        RecoveryHistoryView()
                    } label: {
                        Image(systemName: "calendar")
                    }
                    .accessibilityLabel("View recovery history")
                    .accessibilityHint("Opens calendar view of past recovery sessions")
                }
            }
            .sheet(isPresented: $viewModel.showingLogSheet) {
                RecoverySessionLogView(
                    selectedType: viewModel.selectedSessionType,
                    onSave: { [weak viewModel] session in
                        Task {
                            guard let viewModel else { return }
                            await viewModel.saveSession(session)
                        }
                    }
                )
            }
            .fullScreenCover(isPresented: $viewModel.showingTimer) {
                if let config = viewModel.timerConfig {
                    RecoverySessionTimerView(
                        sessionType: config.sessionType,
                        targetDuration: config.duration,
                        temperature: config.temperature,
                        onComplete: { [weak viewModel] duration, notes in
                            Task {
                                guard let viewModel else { return }
                                await viewModel.completeTimerSession(
                                    duration: duration,
                                    notes: notes
                                )
                            }
                        },
                        onCancel: {
                            viewModel.cancelTimer()
                        }
                    )
                }
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading recovery data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Streak Card
                streakCard

                // Quick Log Section
                quickLogSection

                // Weekly Summary
                weeklySummaryCard

                // Recent Sessions
                recentSessionsSection
            }
            .padding()
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.currentStreak) Day Streak")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(viewModel.streakMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Best: \(viewModel.longestStreak)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if viewModel.hasRecoveredToday {
                        Label("Today", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.modusTealAccent)
                    }
                }
            }

            // Streak progress bar
            if viewModel.currentStreak > 0 {
                streakProgressBar
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.red.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Recovery streak: \(viewModel.currentStreak) days. \(viewModel.streakMessage). Best streak: \(viewModel.longestStreak) days")
    }

    private var streakProgressBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 7-day goal progress
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(geometry.size.width * CGFloat(viewModel.currentStreak) / 7.0, geometry.size.width))
                }
            }
            .frame(height: 8)

            HStack {
                Text("Weekly Goal")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(min(viewModel.currentStreak, 7))/7 days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Quick Log Section

    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick Log")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                QuickLogCard(
                    title: "Sauna",
                    icon: "flame.fill",
                    gradient: [.orange, .red],
                    action: {
                        HapticFeedback.medium()
                        viewModel.startQuickLog(for: .saunaTraditional)
                    }
                )

                QuickLogCard(
                    title: "Cold Plunge",
                    icon: "snowflake",
                    gradient: [.cyan, .blue],
                    action: {
                        HapticFeedback.medium()
                        viewModel.startQuickLog(for: .coldPlunge)
                    }
                )

                QuickLogCard(
                    title: "Contrast",
                    icon: "arrow.left.arrow.right",
                    gradient: [.purple, .indigo],
                    action: {
                        HapticFeedback.medium()
                        viewModel.startQuickLog(for: .contrast)
                    }
                )
            }

            // More options button
            Button {
                viewModel.showAllSessionTypes()
            } label: {
                HStack {
                    Text("More Recovery Types")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.modusCyan)
                .padding(.vertical, Spacing.xs)
            }
            .accessibilityLabel("View more recovery session types")
        }
    }

    // MARK: - Weekly Summary Card

    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("This Week")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    RecoveryHistoryView()
                } label: {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
                .accessibilityLabel("See all recovery history")
            }
            .accessibilityAddTraits(.isHeader)

            HStack(spacing: Spacing.lg) {
                WeeklyStat(
                    value: "\(viewModel.weeklyStats.sessions)",
                    label: "Sessions",
                    icon: "figure.mind.and.body",
                    color: .modusCyan
                )

                WeeklyStat(
                    value: "\(viewModel.weeklyStats.totalMinutes)",
                    label: "Minutes",
                    icon: "clock.fill",
                    color: .modusTealAccent
                )

                if let favorite = viewModel.weeklyStats.favoriteType {
                    WeeklyStat(
                        value: favorite.shortName,
                        label: "Favorite",
                        icon: favorite.icon,
                        color: .modusDeepTeal
                    )
                }
            }

            // Weekly breakdown by type
            if !viewModel.weeklyBreakdown.isEmpty {
                Divider()

                VStack(spacing: Spacing.xs) {
                    ForEach(viewModel.weeklyBreakdown, id: \.type) { breakdown in
                        HStack {
                            Image(systemName: breakdown.type.icon)
                                .font(.caption)
                                .foregroundColor(breakdown.type.color)
                                .frame(width: 20)
                                .accessibilityHidden(true)

                            Text(breakdown.type.displayName)
                                .font(.caption)

                            Spacer()

                            Text("\(breakdown.count) sessions")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(breakdown.totalMinutes) min")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(breakdown.type.displayName): \(breakdown.count) sessions, \(breakdown.totalMinutes) minutes")
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Recent Sessions Section

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recent Sessions")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if viewModel.recentSessions.isEmpty {
                emptySessionsView
            } else {
                ForEach(viewModel.recentSessions.prefix(5)) { session in
                    RecentSessionRow(session: session)
                }
            }
        }
    }

    private var emptySessionsView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
                .accessibilityHidden(true)

            Text("No Recovery Sessions Yet")
                .font(.subheadline)
                .fontWeight(.medium)

            Text("Tap a quick log button above to track your first recovery session.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Quick Log Card

private struct QuickLogCard: View {
    let title: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                        isPressed = false
                    }
                }
        )
        .accessibilityLabel("Log \(title) session")
        .accessibilityHint("Starts a new \(title) recovery session")
    }
}

// MARK: - Weekly Stat

private struct WeeklyStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .accessibilityHidden(true)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Recent Session Row

private struct RecentSessionRow: View {
    let session: RecoverySession

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(session.protocolType.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: session.protocolType.icon)
                    .font(.body)
                    .foregroundColor(session.protocolType.color)
            }
            .accessibilityHidden(true)

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(session.protocolType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(session.loggedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Duration
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.durationMinutes) min")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let temp = session.temperature {
                    Text(session.protocolType.isColdTherapy ? "\(Int(temp))°F" : "\(Int(temp))°F")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.protocolType.displayName), \(session.durationMinutes) minutes, \(session.loggedAt.formatted(date: .abbreviated, time: .shortened))")
    }
}

// MARK: - Recovery Protocol Type Extensions

extension RecoveryProtocolType {
    var shortName: String {
        switch self {
        case .saunaTraditional: return "Sauna"
        case .saunaInfrared: return "Infrared"
        case .saunaSteam: return "Steam"
        case .coldPlunge: return "Plunge"
        case .coldShower: return "Shower"
        case .iceBath: return "Ice"
        case .contrast: return "Contrast"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct RecoveryTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryTrackingView()
            .previewDisplayName("Recovery Tracking")
    }
}
#endif
