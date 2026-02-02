//
//  WeeklySummaryHistoryView.swift
//  PTPerformance
//
//  Created by BUILD ACP-843 - Weekly Progress Summary Feature
//  Historical view of weekly summaries for trend analysis
//

import SwiftUI
import Charts

/// Historical view showing past weekly summaries
struct WeeklySummaryHistoryView: View {
    // MARK: - Properties

    let patientId: UUID

    // MARK: - State

    @State private var summaries: [WeeklySummary] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var selectedSummary: WeeklySummary?

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isLoading && summaries.isEmpty {
                    loadingView
                } else if !summaries.isEmpty {
                    // Trend chart
                    trendChart

                    // Weekly list
                    weeklyList
                } else if let error = error {
                    errorView(error)
                } else {
                    emptyStateView
                }
            }
            .padding()
        }
        .navigationTitle("Weekly History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSummary) { summary in
            WeeklySummaryDetailSheet(summary: summary)
        }
        .refreshable {
            await loadHistory()
        }
        .task {
            await loadHistory()
        }
    }

    // MARK: - Trend Chart

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Adherence Trend")
                .font(.headline)

            if #available(iOS 16.0, *) {
                Chart(summaries.reversed()) { summary in
                    LineMark(
                        x: .value("Week", summary.weekStartDate),
                        y: .value("Adherence", summary.adherencePercentage)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Week", summary.weekStartDate),
                        y: .value("Adherence", summary.adherencePercentage)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Week", summary.weekStartDate),
                        y: .value("Adherence", summary.adherencePercentage)
                    )
                    .foregroundStyle(.blue)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 50, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)%")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 180)
                .padding(.vertical, 8)
            } else {
                // Fallback for iOS 15
                Text("Upgrade to iOS 16 for charts")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Weekly List

    private var weeklyList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Past Weeks")
                .font(.headline)

            ForEach(summaries) { summary in
                Button {
                    selectedSummary = summary
                } label: {
                    weeklyRow(summary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func weeklyRow(_ summary: WeeklySummary) -> some View {
        HStack(spacing: 16) {
            // Performance indicator
            Image(systemName: summary.performanceCategory.emoji)
                .font(.system(size: 24))
                .foregroundColor(summary.performanceCategory.color)
                .frame(width: 40)

            // Week info
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.dateRangeString)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    Text("\(summary.workoutsCompleted)/\(summary.workoutsScheduled) workouts")
                    Text("|")
                        .foregroundColor(.secondary)
                    Text("\(Int(summary.adherencePercentage))%")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            // Volume indicator
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: summary.volumeChangeEmoji)
                    .foregroundColor(summary.volumeChangePercent >= 0 ? .green : .red)

                Text("\(summary.volumeChangePercent >= 0 ? "+" : "")\(Int(summary.volumeChangePercent))%")
                    .font(.caption.bold())
                    .foregroundColor(summary.volumeChangePercent >= 0 ? .green : .red)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading history...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Error View

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Couldn't Load History")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await loadHistory()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            title: "No Weekly History Yet",
            message: "Complete workouts throughout the week to see your progress summaries here. Track your adherence trends and celebrate your weekly wins.",
            icon: "calendar.badge.clock",
            iconColor: .blue,
            action: nil
        )
    }

    // MARK: - Data Loading

    private func loadHistory() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            let history = try await WeeklySummaryService.shared.fetchSummaryHistory(for: patientId)
            await MainActor.run {
                summaries = history
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }
}

// MARK: - Detail Sheet

struct WeeklySummaryDetailSheet: View {
    let summary: WeeklySummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: summary.performanceCategory.emoji)
                            .font(.system(size: 48))
                            .foregroundColor(summary.performanceCategory.color)

                        Text(summary.performanceCategory.displayName)
                            .font(.title2.bold())

                        Text(summary.dateRangeString)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Stats grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        statCard("Workouts", value: "\(summary.workoutsCompleted)/\(summary.workoutsScheduled)")
                        statCard("Adherence", value: "\(Int(summary.adherencePercentage))%")
                        statCard("Volume", value: summary.formattedVolume)
                        statCard("Streak", value: "\(summary.currentStreak) days")
                    }
                    .padding(.horizontal)

                    // Wins
                    if !summary.wins.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Wins")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(summary.wins, id: \.self) { win in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(win)
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Focus areas
                    if !summary.improvementAreas.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Focus Areas")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(summary.improvementAreas, id: \.self) { area in
                                HStack {
                                    Image(systemName: "target")
                                        .foregroundColor(.blue)
                                    Text(area)
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Week Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func statCard(_ title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WeeklySummaryHistoryView(patientId: UUID())
    }
}
