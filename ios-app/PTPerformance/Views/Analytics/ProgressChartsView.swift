//
//  ProgressChartsView.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 3
//  Updated by Build 49 with modular chart components
//  Main analytics dashboard with volume, strength, and consistency charts
//

import SwiftUI
import Charts

struct ProgressChartsView: View {

    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var selectedExerciseId: String? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let patientId = appState.userId {
                        // Time period selector
                        periodPicker

                        if viewModel.isLoading && viewModel.isEmpty {
                            ProgressView("Loading analytics...")
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if viewModel.isEmpty {
                            emptyState
                        } else {
                            // Summary cards
                            summaryCards

                            // Volume chart
                            if let data = viewModel.volumeData {
                                VolumeChartView(data: data)
                                    .padding(.horizontal)
                            } else if let error = viewModel.volumeError {
                                sectionErrorView("Volume", error: error) {
                                    Task {
                                        await viewModel.loadVolumeData(for: patientId)
                                    }
                                }
                            }

                            // Consistency chart
                            if let data = viewModel.consistencyData {
                                ConsistencyChartView(data: data)
                                    .padding(.horizontal)
                            } else if let error = viewModel.consistencyError {
                                sectionErrorView("Consistency", error: error) {
                                    Task {
                                        await viewModel.loadConsistencyData(for: patientId)
                                    }
                                }
                            }

                            // Strength chart (with exercise selector)
                            strengthChartSection(patientId: patientId)
                        }
                    } else {
                        notSignedInView
                    }
                }
                .padding()
            }
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ContextualHelpButton(articleId: "understanding-progress")
                }
            }
            .refreshable {
                if let patientId = appState.userId {
                    await viewModel.refresh(for: patientId)
                }
            }
            .task {
                if let patientId = appState.userId {
                    await viewModel.loadAnalytics(for: patientId)
                }
            }
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Time Period", selection: $viewModel.selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: viewModel.selectedPeriod) { _, _ in
            Task {
                if let patientId = appState.userId {
                    await viewModel.periodChanged(for: patientId)
                }
            }
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // Total volume
            if let volume = viewModel.volumeData {
                SummaryCard(
                    title: "Total Volume",
                    value: volume.formattedTotal,
                    subtitle: viewModel.selectedPeriod.displayName,
                    icon: "scalemass.fill",
                    color: .blue
                )
            }

            // Completion rate
            if let consistency = viewModel.consistencyData {
                SummaryCard(
                    title: "Completion Rate",
                    value: consistency.formattedCompletionRate,
                    subtitle: "\(consistency.totalCompleted)/\(consistency.totalScheduled) sessions",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }

            // Current streak
            if let consistency = viewModel.consistencyData, consistency.currentStreak > 0 {
                SummaryCard(
                    title: "Current Streak",
                    value: "\(consistency.currentStreak)",
                    subtitle: consistency.currentStreak == 1 ? "week" : "weeks",
                    icon: "flame.fill",
                    color: .orange
                )
            }

            // Peak volume
            if let volume = viewModel.volumeData, let peakDate = volume.peakDate {
                SummaryCard(
                    title: "Peak Week",
                    value: String(format: "%.0f lbs", volume.peakVolume),
                    subtitle: peakDate.formatted(date: .abbreviated, time: .omitted),
                    icon: "arrow.up.circle.fill",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Strength Chart Section

    private func strengthChartSection(patientId: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let data = viewModel.strengthData {
                StrengthChartView(data: data)
                    .padding(.horizontal)
            } else if viewModel.isLoadingStrength {
                ProgressView("Loading strength data...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let error = viewModel.strengthError {
                sectionErrorView("Strength", error: error) {
                    if let exerciseId = selectedExerciseId {
                        Task {
                            await viewModel.loadStrengthData(for: patientId, exerciseId: exerciseId)
                        }
                    }
                }
            } else {
                StrengthEmptyState()
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.3))

            Text("No Analytics Data")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Complete workouts to see your progress analytics")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Not Signed In View

    private var notSignedInView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(.orange.opacity(0.5))

            Text("Sign In Required")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Sign in to view your progress analytics")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Section Error View

    private func sectionErrorView(_ section: String, error: String, retry: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)

            Text("Unable to Load \(section) Data")
                .font(.headline)

            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                retry()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)

                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Volume Chart Card

struct VolumeChartCard: View {
    let data: VolumeChartData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Training Volume")
                        .font(.headline)

                    Text("Total weight lifted over time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(data.formattedAverage)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("avg/week")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Chart(data.dataPoints) { dataPoint in
                BarMark(
                    x: .value("Week", dataPoint.date, unit: .weekOfYear),
                    y: .value("Volume", dataPoint.totalVolume)
                )
                .foregroundStyle(.blue.gradient)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Consistency Chart Card

struct ConsistencyChartCard: View {
    let data: ConsistencyChartData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout Consistency")
                        .font(.headline)

                    Text("Completion rate per week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if data.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)

                        Text("\(data.currentStreak)")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(data.currentStreak == 1 ? "week" : "weeks")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Chart(data.dataPoints) { dataPoint in
                BarMark(
                    x: .value("Week", dataPoint.weekStart, unit: .weekOfYear),
                    y: .value("Rate", dataPoint.completionRate)
                )
                .foregroundStyle(
                    dataPoint.isGoodWeek ? Color.green.gradient : Color.orange.gradient
                )

                RuleMark(y: .value("Goal", 0.8))
                    .foregroundStyle(.gray.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                    AxisValueLabel {
                        if let percent = value.as(Double.self) {
                            Text("\(Int(percent * 100))%")
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Preview

struct ProgressChartsView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        appState.userId = "test-patient-id"
        appState.isAuthenticated = true

        return ProgressChartsView()
            .environmentObject(appState)
    }
}
