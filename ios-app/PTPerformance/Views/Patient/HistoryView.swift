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
                    ProgressView("Loading history...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        Task {
                            await viewModel.refresh(for: patientId)
                        }
                    }
                } else {
                    // Summary cards
                    if let stats = viewModel.summaryStats {
                        SummaryCardsView(stats: stats)
                    }

                    // Pain trend chart
                    if !viewModel.painTrend.isEmpty {
                        PainTrendSection(dataPoints: viewModel.painTrend)
                    }

                    // Adherence card
                    if let adherence = viewModel.adherence {
                        AdherenceSection(adherence: adherence)
                    }

                    // Recent sessions list
                    if !viewModel.recentSessions.isEmpty {
                        RecentSessionsSection(sessions: viewModel.recentSessions)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("History")
        .refreshable {
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

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
            .background(Color(.systemGray6))
            .cornerRadius(12)

            Text("Pain above 5 indicates potential risk and triggers therapist alerts")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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
            .background(Color(.systemGray6))
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
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .bold()
        }
    }
}

// MARK: - Recent Sessions Section

struct RecentSessionsSection: View {
    let sessions: [SessionSummary]

    var body: some View {
        VStack(spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

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

            if session.completed {
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
        .background(Color(.systemGray6))
        .cornerRadius(8)
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

// MARK: - Preview

#if DEBUG
struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HistoryView(patientId: "patient-1")
        }
    }
}
#endif
