import SwiftUI

/// ACP-901: Main Recovery Tracking Dashboard with Training Adjustment Recommendations
/// Displays recovery score, training recommendations, quick-log buttons, weekly trends, and streak tracking
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
                // Recovery Score Card (Primary)
                recoveryScoreCard

                // Low Recovery Alert (conditional)
                if viewModel.showLowRecoveryAlert {
                    lowRecoveryAlertCard
                }

                // Quick Log Recovery Methods
                recoveryMethodsSection

                // Weekly Trend
                weeklyTrendSection

                // Streak Card
                streakCard

                // Quick Log Section (existing protocols)
                quickLogSection

                // Weekly Summary
                weeklySummaryCard

                // Recent Sessions
                recentSessionsSection
            }
            .padding()
        }
    }

    // MARK: - Recovery Score Card

    private var recoveryScoreCard: some View {
        VStack(spacing: Spacing.md) {
            // Header
            HStack {
                Image(systemName: viewModel.recoveryStatus.icon)
                    .font(.title2)
                    .foregroundColor(viewModel.recoveryStatus.color)
                    .accessibilityHidden(true)

                Text("RECOVERY STATUS")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .accessibilityAddTraits(.isHeader)

            // Score Display
            VStack(spacing: Spacing.sm) {
                Text(viewModel.formattedRecoveryScore)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(viewModel.recoveryStatus.color)

                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(viewModel.recoveryStatus.color)
                            .frame(width: geometry.size.width * CGFloat(viewModel.recoveryScore) / 100.0)
                    }
                }
                .frame(height: 8)

                Text(viewModel.recoveryStatus.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(viewModel.recoveryStatus.color)
            }

            // Metrics Row
            HStack(spacing: Spacing.xl) {
                MetricIndicator(
                    label: "Sleep",
                    value: String(format: "%.1fh", viewModel.sleepHours),
                    status: viewModel.sleepStatus
                )

                MetricIndicator(
                    label: "HRV",
                    value: "\(viewModel.hrvValue)ms",
                    status: viewModel.hrvStatus
                )

                MetricIndicator(
                    label: "Soreness",
                    value: viewModel.sorenessLevel.displayName,
                    status: viewModel.sorenessStatus
                )
            }
            .padding(.top, Spacing.sm)

            // Recommendation
            if let recommendation = viewModel.trainingRecommendation {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .accessibilityHidden(true)

                    Text(recommendation.headline)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .padding(.top, Spacing.sm)
            }

            // CTA Button
            Button {
                viewModel.startTodaysWorkout()
            } label: {
                Text("Start Today's Workout")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(viewModel.recoveryStatus.color)
                    .cornerRadius(CornerRadius.md)
            }
            .padding(.top, Spacing.sm)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .contain)
    }

    // MARK: - Low Recovery Alert Card

    private var lowRecoveryAlertCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .accessibilityHidden(true)

                Text("LOW RECOVERY DETECTED")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)

                Spacer()

                Button {
                    viewModel.showLowRecoveryAlert = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Dismiss alert")
            }

            // Recovery Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Your recovery is at \(viewModel.recoveryScore)%")
                    .font(.headline)

                let hrvNote = viewModel.hrvValue < 40 ? "HRV down \(40 - viewModel.hrvValue)%" : ""
                let sleepNote = viewModel.sleepHours < 6 ? "poor sleep" : ""
                let notes = [hrvNote, sleepNote].filter { !$0.isEmpty }.joined(separator: ", ")

                if !notes.isEmpty {
                    Text("(\(notes))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Recommendation Section
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("RECOMMENDATION:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                Text("Swap today's heavy work for:")
                    .font(.subheadline)

                if let recommendation = viewModel.trainingRecommendation {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ForEach(recommendation.alternativeActivities, id: \.self) { activity in
                            HStack(spacing: Spacing.xs) {
                                Circle()
                                    .fill(Color.secondary)
                                    .frame(width: 6, height: 6)
                                Text(activity)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.leading, Spacing.sm)
                }
            }

            // Action Buttons
            HStack(spacing: Spacing.md) {
                Button {
                    viewModel.adjustWorkout()
                } label: {
                    Text("Adjust Workout")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.modusCyan)
                        .cornerRadius(CornerRadius.sm)
                }

                Button {
                    viewModel.trainAnyway()
                } label: {
                    Text("Train Anyway")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.sm)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Recovery Methods Section

    private var recoveryMethodsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick Log Recovery")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach([RecoveryMethod.coldPlunge, .sauna, .yoga, .massage], id: \.self) { method in
                        RecoveryMethodButton(
                            method: method,
                            isLogged: viewModel.recoveryMethodsLoggedToday.contains(method),
                            action: {
                                viewModel.logRecoveryMethod(method)
                            }
                        )
                    }
                }
                .padding(.horizontal, 1) // Prevent clipping
            }
        }
    }

    // MARK: - Weekly Trend Section

    private var weeklyTrendSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Weekly Trend")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: Spacing.xs) {
                ForEach(viewModel.weeklyTrendData) { trend in
                    WeeklyTrendRow(trend: trend)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.lg)
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

// MARK: - Metric Indicator

private struct MetricIndicator: View {
    let label: String
    let value: String
    let status: MetricStatus

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Image(systemName: status.icon)
                .font(.caption)
                .foregroundColor(status.color)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Recovery Method Button

private struct RecoveryMethodButton: View {
    let method: RecoveryMethod
    let isLogged: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(isLogged ? method.color.opacity(0.2) : Color(.tertiarySystemGroupedBackground))
                        .frame(width: 60, height: 60)

                    Image(systemName: method.icon)
                        .font(.title2)
                        .foregroundColor(isLogged ? method.color : .primary)
                }

                Text(method.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isLogged ? method.color : .primary)
            }
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
        .accessibilityLabel("Log \(method.fullName)")
        .accessibilityHint(isLogged ? "Already logged today" : "Tap to log")
    }
}

// MARK: - Weekly Trend Row

private struct WeeklyTrendRow: View {
    let trend: DailyRecoveryTrend

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(trend.dayName)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 30, alignment: .leading)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(trend.status.color)
                        .frame(width: geometry.size.width * trend.scorePercentage)
                }
            }
            .frame(height: 12)

            Text("\(trend.score)%")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 35, alignment: .trailing)

            // Arrow indicator
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundColor(.secondary)

            // Intensity recommendation
            HStack(spacing: 2) {
                Text(trend.recommendedIntensity.displayName)
                    .font(.caption2)
                    .foregroundColor(trend.recommendedIntensity.color)

                if trend.workoutCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            .frame(width: 70, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(trend.dayName): \(trend.score)% recovery, \(trend.recommendedIntensity.displayName) workout\(trend.workoutCompleted ? ", completed" : "")")
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
                    Text(session.protocolType.isColdTherapy ? "\(Int(temp))F" : "\(Int(temp))F")
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

        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Preview with low recovery alert
                    PreviewLowRecoveryCard()
                }
                .padding()
            }
        }
        .previewDisplayName("Low Recovery Alert")
    }
}

private struct PreviewLowRecoveryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)

                Text("LOW RECOVERY DETECTED")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)

                Spacer()
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Your recovery is at 45%")
                    .font(.headline)

                Text("(HRV down 20%, poor sleep)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("RECOMMENDATION:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                Text("Swap today's heavy squats for:")
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(["Light mobility work", "20-min zone 2 cardio", "Extra recovery focus"], id: \.self) { activity in
                        HStack(spacing: Spacing.xs) {
                            Circle()
                                .fill(Color.secondary)
                                .frame(width: 6, height: 6)
                            Text(activity)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.leading, Spacing.sm)
            }

            HStack(spacing: Spacing.md) {
                Button {} label: {
                    Text("Adjust Workout")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.modusCyan)
                        .cornerRadius(CornerRadius.sm)
                }

                Button {} label: {
                    Text("Train Anyway")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.sm)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
#endif
