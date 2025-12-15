//
//  ProgressChartsView.swift
//  PTPerformance
//
//  Created by Build 46 Swarm Agent 3
//  Main analytics dashboard with volume, strength, and consistency charts
//

import SwiftUI
import Charts

struct ProgressChartsView: View {

    @State private var selectedPeriod: TimePeriod = .month
    @State private var volumeData: VolumeChartData?
    @State private var consistencyData: ConsistencyChartData?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let patientId: String

    init(patientId: String) {
        self.patientId = patientId
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time period selector
                    periodPicker

                    if isLoading && volumeData == nil {
                        ProgressView("Loading analytics...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if let error = errorMessage {
                        errorView(error)
                    } else {
                        // Summary cards
                        summaryCards

                        // Volume chart
                        if let data = volumeData {
                            VolumeChartCard(data: data)
                        }

                        // Consistency chart
                        if let data = consistencyData {
                            ConsistencyChartCard(data: data)
                        }

                        // Strength chart (for top exercise)
                        strengthChartSection
                    }
                }
                .padding()
            }
            .navigationTitle("Progress")
            .refreshable {
                await loadAnalytics()
            }
            .onAppear {
                Task {
                    await loadAnalytics()
                }
            }
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Time Period", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: selectedPeriod) { _, _ in
            Task {
                await loadAnalytics()
            }
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // Total volume
            if let volume = volumeData {
                SummaryCard(
                    title: "Total Volume",
                    value: volume.formattedTotal,
                    subtitle: selectedPeriod.displayName,
                    icon: "scalemass.fill",
                    color: .blue
                )
            }

            // Completion rate
            if let consistency = consistencyData {
                SummaryCard(
                    title: "Completion Rate",
                    value: consistency.formattedCompletionRate,
                    subtitle: "\(consistency.totalCompleted)/\(consistency.totalScheduled) sessions",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }

            // Current streak
            if let consistency = consistencyData, consistency.currentStreak > 0 {
                SummaryCard(
                    title: "Current Streak",
                    value: "\(consistency.currentStreak)",
                    subtitle: consistency.currentStreak == 1 ? "week" : "weeks",
                    icon: "flame.fill",
                    color: .orange
                )
            }

            // Peak volume
            if let volume = volumeData, let peakDate = volume.peakDate {
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

    private var strengthChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strength Progress")
                .font(.headline)
                .padding(.horizontal)

            Text("Select an exercise to view strength progression")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // TODO: Exercise selector and chart
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Load Analytics")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Try Again") {
                Task {
                    await loadAnalytics()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Actions

    private func loadAnalytics() async {
        isLoading = true
        errorMessage = nil

        do {
            async let volume = AnalyticsService.shared.calculateVolumeData(
                for: patientId,
                period: selectedPeriod
            )
            async let consistency = AnalyticsService.shared.calculateConsistencyData(
                for: patientId,
                period: selectedPeriod
            )

            (volumeData, consistencyData) = try await (volume, consistency)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
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
        ProgressChartsView(patientId: "test-patient-id")
    }
}
