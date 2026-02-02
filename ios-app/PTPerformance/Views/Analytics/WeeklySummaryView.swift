//
//  WeeklySummaryView.swift
//  PTPerformance
//
//  Created by BUILD ACP-843 - Weekly Progress Summary Feature
//  Full weekly recap view with wins, improvement areas, and history
//

import SwiftUI

/// Full weekly summary view with detailed breakdown
struct WeeklySummaryView: View {
    // MARK: - Properties

    let patientId: UUID

    // MARK: - State

    @StateObject private var viewModel: WeeklySummaryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWeek: Int = 0  // 0 = current, 1 = last week, etc.

    // MARK: - Init

    init(patientId: UUID) {
        self.patientId = patientId
        self._viewModel = StateObject(wrappedValue: WeeklySummaryViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Week selector
                    weekSelector

                    if viewModel.isLoading {
                        loadingView
                    } else if let summary = viewModel.currentSummary {
                        // Performance header
                        performanceHeader(summary)

                        // Key metrics grid
                        metricsGrid(summary)

                        // Wins section
                        winsSection(summary)

                        // Improvement areas
                        improvementSection(summary)

                        // Notification settings
                        notificationSettings

                        // History link
                        historyButton
                    } else if let error = viewModel.error {
                        errorView(error)
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("Weekly Summary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Week Selector

    private var weekSelector: some View {
        Picker("Week", selection: $selectedWeek) {
            Text("This Week").tag(0)
            Text("Last Week").tag(1)
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedWeek) { _, newValue in
            Task {
                await viewModel.selectWeek(offset: newValue)
            }
        }
    }

    // MARK: - Performance Header

    private func performanceHeader(_ summary: WeeklySummary) -> some View {
        VStack(spacing: 12) {
            // Performance badge
            HStack(spacing: 8) {
                Image(systemName: summary.performanceCategory.emoji)
                    .font(.system(size: 24))
                    .foregroundColor(summary.performanceCategory.color)

                Text(summary.performanceCategory.displayName)
                    .font(.title2.bold())
                    .foregroundColor(summary.performanceCategory.color)
            }

            // Date range
            Text(summary.dateRangeString)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(summary.performanceCategory.color.opacity(0.1))
        )
    }

    // MARK: - Metrics Grid

    private func metricsGrid(_ summary: WeeklySummary) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // Workouts completed
            metricCard(
                title: "Workouts",
                value: "\(summary.workoutsCompleted)/\(summary.workoutsScheduled)",
                icon: "figure.run",
                color: summary.adherencePercentage >= 80 ? .green : .orange
            )

            // Adherence
            metricCard(
                title: "Adherence",
                value: "\(Int(summary.adherencePercentage))%",
                icon: "checkmark.circle.fill",
                color: summary.adherencePercentage >= 80 ? .green : (summary.adherencePercentage >= 60 ? .orange : .red)
            )

            // Volume
            metricCard(
                title: "Volume",
                value: summary.formattedVolume,
                icon: "scalemass.fill",
                color: .blue
            )

            // Volume change
            metricCard(
                title: "vs Last Week",
                value: "\(summary.volumeChangePercent >= 0 ? "+" : "")\(Int(summary.volumeChangePercent))%",
                icon: summary.volumeChangeEmoji,
                color: summary.volumeChangePercent >= 0 ? .green : .red
            )

            // Streak
            metricCard(
                title: "Streak",
                value: "\(summary.currentStreak) days",
                icon: "flame.fill",
                color: summary.streakMaintained ? .orange : .gray
            )

            // Top exercise
            if let topEx = summary.topExercise {
                metricCard(
                    title: "Star Exercise",
                    value: topEx,
                    icon: "star.fill",
                    color: .yellow,
                    isText: true
                )
            }
        }
    }

    private func metricCard(title: String, value: String, icon: String, color: Color, isText: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if isText {
                Text(value)
                    .font(.footnote.bold())
                    .foregroundColor(.primary)
                    .lineLimit(2)
            } else {
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Wins Section

    private func winsSection(_ summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("Wins This Week")
                    .font(.headline)
            }

            VStack(spacing: 8) {
                ForEach(summary.wins, id: \.self) { win in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 20))

                        Text(win)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.1))
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Improvement Section

    private func improvementSection(_ summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.blue)
                Text("Focus Areas")
                    .font(.headline)
            }

            VStack(spacing: 8) {
                ForEach(summary.improvementAreas, id: \.self) { area in
                    HStack(spacing: 12) {
                        Image(systemName: "target")
                            .foregroundColor(.blue)
                            .font(.system(size: 18))

                        Text(area)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Notification Settings

    private var notificationSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.purple)
                Text("Weekly Notifications")
                    .font(.headline)
            }

            NavigationLink {
                WeeklySummaryPreferencesView(patientId: patientId)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.preferences?.notificationEnabled == true ? "Enabled" : "Disabled")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)

                        if let prefs = viewModel.preferences, prefs.notificationEnabled {
                            Text(prefs.notificationTimeDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
    }

    // MARK: - History Button

    private var historyButton: some View {
        NavigationLink {
            WeeklySummaryHistoryView(patientId: patientId)
        } label: {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("View History")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading your week...")
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

            Text("Couldn't Load Summary")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.refresh()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("No Data Yet")
                .font(.headline)

            Text("Complete some workouts to see your weekly summary")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - ViewModel

@MainActor
class WeeklySummaryViewModel: ObservableObject {
    let patientId: UUID

    @Published var currentSummary: WeeklySummary?
    @Published var preferences: WeeklySummaryPreferences?
    @Published var isLoading = false
    @Published var error: Error?

    private var weekOffset: Int = 0

    init(patientId: UUID) {
        self.patientId = patientId
    }

    func loadData() async {
        isLoading = true
        error = nil

        do {
            async let summaryTask = WeeklySummaryService.shared.fetchCurrentWeekSummary(for: patientId)
            async let prefsTask = WeeklySummaryService.shared.fetchPreferences(for: patientId)

            let (summary, prefs) = try await (summaryTask, prefsTask)
            currentSummary = summary
            preferences = prefs
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }

    func selectWeek(offset: Int) async {
        weekOffset = offset
        isLoading = true
        error = nil

        do {
            if offset == 0 {
                currentSummary = try await WeeklySummaryService.shared.fetchCurrentWeekSummary(for: patientId)
            } else {
                currentSummary = try await WeeklySummaryService.shared.fetchPreviousWeekSummary(for: patientId)
            }
        } catch {
            self.error = error
        }

        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    WeeklySummaryView(patientId: UUID())
}
