import SwiftUI
import Charts

/// History view showing pain trends, adherence, and recent sessions
struct HistoryView: View {
    let patientId: String

    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    // Build 60: Skeleton loading states
                    HistoryLoadingView()
                } else if let error = viewModel.errorMessage {
                    // Build 60: Enhanced error view
                    ErrorStateView.genericError(message: error) {
                        Task {
                            await viewModel.refresh(for: patientId)
                        }
                    }
                } else if viewModel.isEmpty {
                    // Empty state when no data is available
                    EmptyHistoryView()
                } else {
                    // Summary cards
                    if let stats = viewModel.summaryStats {
                        SummaryCardsView(stats: stats)
                    }

                    // Pain trend chart
                    if !viewModel.painTrend.isEmpty {
                        PainTrendSection(dataPoints: viewModel.painTrend)
                    } else if viewModel.summaryStats != nil {
                        EmptyDataSection(
                            title: "No Pain Data Yet",
                            message: "Complete sessions and log pain scores to see your pain trend over time",
                            icon: "chart.line.uptrend.xyaxis"
                        )
                    }

                    // Adherence card
                    if let adherence = viewModel.adherence {
                        AdherenceSection(adherence: adherence)
                    }

                    // BUILD 219: Combined workout history (prescribed + manual)
                    // BUILD 296: Added NavigationLink → SessionDetailView (ACP-588)
                    if !viewModel.allWorkouts.isEmpty {
                        RecentWorkoutsSection(
                            workouts: viewModel.allWorkouts,
                            patientId: patientId,
                            hasMoreWorkouts: viewModel.hasMoreWorkouts,
                            isLoadingMore: viewModel.isLoadingMore,
                            onLoadMore: {
                                Task {
                                    await viewModel.loadMoreWorkouts()
                                }
                            }
                        )
                    } else if viewModel.summaryStats != nil {
                        EmptyDataSection(
                            title: "No Workouts Yet",
                            message: "Your completed sessions and manual workouts will appear here",
                            icon: "calendar.badge.clock"
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("History")
        .refreshable {
            HapticFeedback.light()
            await viewModel.refresh(for: patientId)
        }
        .task {
            await viewModel.fetchData(for: patientId)
        }
    }
}

// MARK: - Summary Cards

struct SummaryCardsView: View {
    let stats: SummaryStats

    var body: some View {
        VStack(spacing: 16) {
            Text("Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 16) {
                SummaryCard(
                    title: "Adherence",
                    value: "\(Int(stats.adherencePercentage))%",
                    icon: "checkmark.circle.fill",
                    color: adherenceColor(stats.adherencePercentage)
                )

                SummaryCard(
                    title: "Avg Pain",
                    value: String(format: "%.1f", stats.avgPainScore),
                    icon: "heart.fill",
                    color: painColor(stats.avgPainScore)
                )

                SummaryCard(
                    title: "Sessions",
                    value: "\(stats.completedSessions)/\(stats.totalSessions)",
                    icon: "calendar",
                    color: .blue
                )
            }
        }
    }

    private func adherenceColor(_ percentage: Double) -> Color {
        switch percentage {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }

    private func painColor(_ pain: Double) -> Color {
        switch pain {
        case 0...2: return .green
        case 2...5: return .yellow
        default: return .red
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .accessibilityHidden(true)

            Text(value)
                .font(.title2)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Pain Trend Section

struct PainTrendSection: View {
    let dataPoints: [PainDataPoint]

    var body: some View {
        VStack(spacing: 12) {
            Text("Pain Trend (14 Days)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)

            Chart {
                ForEach(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Pain", point.painScore)
                    )
                    .foregroundStyle(.red)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Pain", point.painScore)
                    )
                    .foregroundStyle(.red)
                }

                // Threshold line at pain = 5
                RuleMark(y: .value("Threshold", 5))
                    .foregroundStyle(.orange.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Safety Threshold")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
            }
            .chartYScale(domain: 0...10)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 2, 5, 7, 10])
            }
            .frame(height: 200)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .accessibilityLabel(chartAccessibilityLabel)
            .accessibilityHint("Shows pain levels over the last 14 days")

            Text("Pain above 5 indicates potential risk and triggers therapist alerts")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var chartAccessibilityLabel: String {
        guard !dataPoints.isEmpty else {
            return "No pain data available"
        }
        let avgPain = dataPoints.map { $0.painScore }.reduce(0, +) / Double(dataPoints.count)
        let maxPain = dataPoints.map { $0.painScore }.max() ?? 0
        let minPain = dataPoints.map { $0.painScore }.min() ?? 0
        let latestPain = dataPoints.sorted { $0.date > $1.date }.first?.painScore ?? 0
        return "Pain trend chart showing \(dataPoints.count) data points. Average pain \(String(format: "%.1f", avgPain)), range \(String(format: "%.1f", minPain)) to \(String(format: "%.1f", maxPain)), most recent \(String(format: "%.1f", latestPain))"
    }
}

// MARK: - Adherence Section

struct AdherenceSection: View {
    let adherence: AdherenceData

    var body: some View {
        VStack(spacing: 12) {
            Text("Adherence")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 32) {
                // Circular adherence chart
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)

                    Circle()
                        .trim(from: 0, to: adherence.adherencePercentage / 100)
                        .stroke(adherenceColor, lineWidth: 20)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: adherence.adherencePercentage)

                    VStack {
                        Text("\(Int(adherence.adherencePercentage))%")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(adherenceColor)

                        Text("Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 150, height: 150)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Adherence: \(Int(adherence.adherencePercentage)) percent complete")
                .accessibilityValue("\(adherence.completedSessions) of \(adherence.totalSessions) sessions completed")

                // Stats
                VStack(alignment: .leading, spacing: 12) {
                    StatRow(
                        label: "Completed",
                        value: "\(adherence.completedSessions)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )

                    StatRow(
                        label: "Remaining",
                        value: "\(adherence.totalSessions - adherence.completedSessions)",
                        icon: "circle",
                        color: .gray
                    )

                    StatRow(
                        label: "Total",
                        value: "\(adherence.totalSessions)",
                        icon: "calendar",
                        color: .blue
                    )
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private var adherenceColor: Color {
        switch adherence.adherencePercentage {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .accessibilityHidden(true)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .bold()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Recent Sessions Section (Legacy - kept for compatibility)

struct RecentSessionsSection: View {
    let sessions: [SessionSummary]

    var body: some View {
        VStack(spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                ForEach(sessions) { session in
                    SessionRow(session: session)
                }
            }
        }
    }
}

struct SessionRow: View {
    let session: SessionSummary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Session \(session.sessionNumber)")
                    .font(.headline)

                Text(session.sessionDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if session.completed == true {
                Label("Complete", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Label("Pending", systemImage: "circle")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session \(session.sessionNumber), \(session.sessionDate.formatted(date: .abbreviated, time: .omitted)), \(session.completed == true ? "completed" : "pending")")
    }
}

// MARK: - BUILD 219: Combined Workout History Section

struct RecentWorkoutsSection: View {
    let workouts: [WorkoutHistoryItem]
    let patientId: String
    var hasMoreWorkouts: Bool = false
    var isLoadingMore: Bool = false
    var onLoadMore: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Text("Recent Workouts")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                ForEach(workouts) { workout in
                    NavigationLink(destination: SessionDetailView(workout: workout, patientId: patientId)) {
                        WorkoutHistoryRow(workout: workout)
                    }
                    .buttonStyle(.plain)
                }

                // Pagination: Load More button or loading indicator
                if hasMoreWorkouts {
                    if isLoadingMore {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Loading more...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        Button(action: {
                            onLoadMore?()
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                Text("Load More Workouts")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }
}

struct WorkoutHistoryRow: View {
    let workout: WorkoutHistoryItem

    var body: some View {
        HStack(spacing: 12) {
            // Type indicator icon
            Image(systemName: workout.isManual ? "figure.strengthtraining.traditional" : "list.clipboard")
                .font(.title2)
                .foregroundColor(workout.isManual ? .orange : .blue)
                .frame(width: 40)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(workout.name)
                        .font(.headline)
                        .lineLimit(1)

                    // Session source badge
                    SessionSourceBadge(source: workout.sessionSource)
                }

                HStack(spacing: 12) {
                    Text(workout.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let count = workout.exerciseCount, count > 0 {
                        Text("\(count) exercises")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let duration = workout.duration {
                        Text("\(duration)m")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Stats row for manual workouts
                if workout.isManual {
                    HStack(spacing: 16) {
                        if let volume = workout.volume, volume > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "scalemass")
                                    .font(.caption2)
                                Text(formatVolume(volume))
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }

                        if let pain = workout.avgPain {
                            HStack(spacing: 2) {
                                Image(systemName: "heart")
                                    .font(.caption2)
                                Text(String(format: "%.1f", pain))
                                    .font(.caption)
                            }
                            .foregroundColor(painColor(pain))
                        }
                    }
                }
            }

            Spacer()

            // Completion status + chevron
            VStack(spacing: 4) {
                if workout.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .accessibilityHidden(true)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(workoutAccessibilityLabel)
        .accessibilityHint("Double tap to view workout details")
        .contextMenu {
            Button {
                HapticFeedback.light()
                // Copy workout summary
                var summary = "\(workout.name) - \(workout.date.formatted(date: .abbreviated, time: .omitted))"
                if let duration = workout.duration {
                    summary += " (\(duration) min)"
                }
                if let volume = workout.volume, volume > 0 {
                    summary += " - \(formatVolume(volume))"
                }
                UIPasteboard.general.string = summary
            } label: {
                Label("Copy Summary", systemImage: "doc.on.doc")
            }

            if let volume = workout.volume, volume > 0 {
                Button {
                    HapticFeedback.light()
                    UIPasteboard.general.string = "Volume: \(formatVolume(volume))"
                } label: {
                    Label("Copy Volume", systemImage: "scalemass")
                }
            }

            Divider()

            Button {
                HapticFeedback.light()
                // Share workout summary
                var summary = "Completed \(workout.name) on \(workout.date.formatted(date: .long, time: .omitted))"
                if let duration = workout.duration {
                    summary += " (\(duration) min)"
                }
                if let volume = workout.volume, volume > 0 {
                    summary += " - Total volume: \(formatVolume(volume))"
                }
                UIPasteboard.general.string = summary
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return "\(Int(volume)) lbs"
    }

    private func painColor(_ pain: Double) -> Color {
        switch pain {
        case 0...2: return .green
        case 2...5: return .yellow
        default: return .red
        }
    }

    private var workoutAccessibilityLabel: String {
        var label = workout.name
        label += ", \(workout.sessionSource.displayName) workout"
        label += ", \(workout.date.formatted(date: .abbreviated, time: .omitted))"
        if let count = workout.exerciseCount, count > 0 {
            label += ", \(count) exercises"
        }
        if let duration = workout.duration {
            label += ", \(duration) minutes"
        }
        if let volume = workout.volume, volume > 0 {
            label += ", volume \(formatVolume(volume))"
        }
        label += workout.isCompleted ? ", completed" : ", not completed"
        return label
    }
}

// MARK: - Session Source Badge

/// Badge showing the source of a workout (program, prescribed, chosen, quick_pick)
struct SessionSourceBadge: View {
    let source: SessionSource

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: source.icon)
                .font(.caption2)
            Text(source.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(backgroundColor.opacity(0.2))
        .foregroundColor(backgroundColor)
        .cornerRadius(4)
        .accessibilityLabel("\(source.displayName) workout")
        .accessibilityHint("Indicates how this workout was initiated")
    }

    private var backgroundColor: Color {
        switch source {
        case .program: return .blue
        case .prescribed: return .purple
        case .chosen: return .green
        case .quickPick: return .orange
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text("Error")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: retry) {
                Label("Retry", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - Empty States

struct EmptyHistoryView: View {
    var onStartSession: (() -> Void)?

    var body: some View {
        EmptyStateView(
            title: "No History Yet",
            message: "Complete your first session to start tracking your progress and recovery journey. Your pain trends, adherence, and workout history will appear here.",
            icon: "clock.arrow.circlepath",
            iconColor: .blue,
            action: onStartSession.map { action in
                EmptyStateView.EmptyStateAction(
                    title: "Start First Session",
                    icon: "play.circle.fill",
                    action: action
                )
            }
        )
        .padding()
    }
}

struct EmptyDataSection: View {
    let title: String
    let message: String
    let icon: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - History Loading View (Build 60)

struct HistoryLoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Summary cards skeleton
            VStack(spacing: 16) {
                Text("Summary")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 16) {
                    ForEach(0..<3) { _ in
                        SkeletonSummaryCard()
                    }
                }
            }
            .padding()

            // Pain trend skeleton
            ChartLoadingView()

            // Adherence skeleton
            SkeletonAdherenceCard()
                .padding()

            // Recent sessions skeleton
            VStack(spacing: 12) {
                Text("Recent Sessions")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(0..<3) { _ in
                    SkeletonSessionRow()
                }
            }
            .padding()
        }
    }
}

struct SkeletonSummaryCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .shimmer(isAnimating: isAnimating)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 20)
                .shimmer(isAnimating: isAnimating)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 12)
                .shimmer(isAnimating: isAnimating)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

struct SkeletonAdherenceCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 12) {
            Text("Adherence")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 32) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 150)
                    .shimmer(isAnimating: isAnimating)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 16)
                            .shimmer(isAnimating: isAnimating)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

struct SkeletonSessionRow: View {
    @State private var isAnimating = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 16)
                    .shimmer(isAnimating: isAnimating)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 12)
                    .shimmer(isAnimating: isAnimating)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 16)
                .shimmer(isAnimating: isAnimating)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                HistoryView(patientId: "patient-1")
            }
            .previewDisplayName("History View")

            HistoryLoadingView()
                .previewDisplayName("Loading State")
        }
    }
}
#endif
