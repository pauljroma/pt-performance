//
//  BodyCompositionTimelineView.swift
//  PTPerformance
//
//  Body Composition timeline with chart and entry list (ACP-509)
//

import SwiftUI
import Charts

/// Main timeline/chart view for body composition tracking
struct BodyCompositionTimelineView: View {
    @StateObject private var viewModel = BodyCompositionViewModel()

    @State private var showingEntrySheet = false
    @State private var didSaveEntry = false
    @State private var selectedPeriod: BodyCompPeriod = .threeMonths
    @State private var selectedMetric: ChartMetric = .weight

    /// Patient ID from the current user session
    private var patientId: String? {
        PTSupabaseClient.shared.userId
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.entries.isEmpty {
                loadingState
            } else if viewModel.entries.isEmpty {
                emptyState
            } else {
                contentView
            }
        }
        .navigationTitle("Body Composition")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEntrySheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingEntrySheet, onDismiss: {
            if didSaveEntry {
                didSaveEntry = false
                refreshData()
            }
        }) {
            if let pid = patientId {
                BodyCompositionEntryView(
                    didSave: $didSaveEntry,
                    patientId: pid
                )
            }
        }
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Period Picker
                periodPicker

                // Metric Selector
                metricPicker

                // Chart
                chartSection

                // Stats Row
                statsRow

                // Recent Entries List
                entriesSection
            }
            .padding()
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        HStack(spacing: 8) {
            ForEach(BodyCompPeriod.allCases, id: \.self) { period in
                Button {
                    selectedPeriod = period
                } label: {
                    Text(period.label)
                        .font(.caption)
                        .fontWeight(selectedPeriod == period ? .bold : .regular)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            selectedPeriod == period
                                ? Color.modusCyan.opacity(0.2)
                                : Color(.tertiarySystemGroupedBackground)
                        )
                        .foregroundColor(selectedPeriod == period ? .modusCyan : .primary)
                        .cornerRadius(CornerRadius.sm)
                }
            }
        }
    }

    // MARK: - Metric Picker

    private var metricPicker: some View {
        Picker("Metric", selection: $selectedMetric) {
            ForEach(ChartMetric.allCases, id: \.self) { metric in
                Text(metric.label).tag(metric)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedMetric.label)
                .font(.headline)

            let filteredData = filteredEntries

            if chartDataPoints(for: filteredData).isEmpty {
                Text("No \(selectedMetric.label.lowercased()) data for this period.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(chartDataPoints(for: filteredData), id: \.date) { point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value(selectedMetric.label, point.value)
                        )
                        .foregroundStyle(selectedMetric.color.gradient)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value(selectedMetric.label, point.value)
                        )
                        .foregroundStyle(selectedMetric.color)
                        .symbolSize(40)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(String(format: "%.0f", doubleValue))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.caption)
                    }
                }
                .frame(height: 220)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(title: "Latest", value: formattedStat(latestValue))
            statCard(title: "Average", value: formattedStat(averageValue))
            statCard(title: "Min", value: formattedStat(minValue))
            statCard(title: "Max", value: formattedStat(maxValue))
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Entries Section

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Entries")
                .font(.headline)

            ForEach(filteredEntries) { entry in
                entryRow(entry)
            }
        }
    }

    private func entryRow(_ entry: BodyComposition) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.formattedDate)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    if let weight = entry.weightLb {
                        Label(String(format: "%.1f lbs", weight), systemImage: "scalemass")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let bf = entry.bodyFatPercent {
                        Label(String(format: "%.1f%%", bf), systemImage: "percent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Button(role: .destructive) {
                deleteEntry(entry)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.sm)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Loading body composition data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            title: "No Body Composition Data",
            message: "Start tracking your weight, body fat percentage, and muscle mass to visualize your fitness journey over time.",
            icon: "figure.arms.open",
            iconColor: .blue,
            action: EmptyStateView.EmptyStateAction(
                title: "Add First Entry",
                icon: "plus.circle.fill",
                action: { showingEntrySheet = true }
            )
        )
    }

    // MARK: - Helper Methods

    /// Entries filtered by selected time period
    private var filteredEntries: [BodyComposition] {
        guard let cutoffDate = selectedPeriod.cutoffDate else {
            return viewModel.entries
        }
        return viewModel.entries.filter { $0.recordedAt >= cutoffDate }
    }

    /// Extract chart data points for the selected metric
    private func chartDataPoints(for entries: [BodyComposition]) -> [BodyCompDataPoint] {
        let sorted = entries.sorted { $0.recordedAt < $1.recordedAt }
        return sorted.compactMap { entry in
            guard let value = metricValue(for: entry) else { return nil }
            return BodyCompDataPoint(date: entry.recordedAt, value: value)
        }
    }

    /// Get the metric value from an entry based on selected metric
    private func metricValue(for entry: BodyComposition) -> Double? {
        switch selectedMetric {
        case .weight:
            return entry.weightLb
        case .bodyFat:
            return entry.bodyFatPercent
        case .muscleMass:
            return entry.muscleMassLb
        }
    }

    // Stats computed properties based on selected metric
    private var latestValue: Double? {
        switch selectedMetric {
        case .weight: return viewModel.latestWeight
        case .bodyFat: return viewModel.latestBodyFat
        case .muscleMass: return viewModel.latestMuscleMass
        }
    }

    private var averageValue: Double? {
        switch selectedMetric {
        case .weight: return viewModel.averageWeight
        case .bodyFat: return viewModel.averageBodyFat
        case .muscleMass: return viewModel.averageMuscleMass
        }
    }

    private var minValue: Double? {
        let values = filteredEntries.compactMap { metricValue(for: $0) }
        return values.min()
    }

    private var maxValue: Double? {
        let values = filteredEntries.compactMap { metricValue(for: $0) }
        return values.max()
    }

    private func formattedStat(_ value: Double?) -> String {
        guard let value = value else { return "--" }
        switch selectedMetric {
        case .weight, .muscleMass:
            return String(format: "%.1f", value)
        case .bodyFat:
            return String(format: "%.1f%%", value)
        }
    }

    private func loadData() async {
        guard let pid = patientId else { return }
        await viewModel.loadEntries(patientId: pid)
    }

    private func refreshData() {
        Task {
            await loadData()
        }
    }

    private func deleteEntry(_ entry: BodyComposition) {
        Task {
            await viewModel.deleteEntry(id: entry.id)
        }
    }
}

// MARK: - Supporting Types

/// Time period filter for body composition chart
enum BodyCompPeriod: CaseIterable {
    case oneMonth
    case threeMonths
    case sixMonths
    case oneYear
    case all

    var label: String {
        switch self {
        case .oneMonth: return "1M"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .oneYear: return "1Y"
        case .all: return "All"
        }
    }

    var cutoffDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: Date())
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: Date())
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: Date())
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: Date())
        case .all:
            return nil
        }
    }
}

/// Selectable metric for the chart
enum ChartMetric: CaseIterable {
    case weight
    case bodyFat
    case muscleMass

    var label: String {
        switch self {
        case .weight: return "Weight"
        case .bodyFat: return "Body Fat"
        case .muscleMass: return "Muscle Mass"
        }
    }

    var color: Color {
        switch self {
        case .weight: return .blue
        case .bodyFat: return .orange
        case .muscleMass: return .green
        }
    }
}

/// A single data point for charting
private struct BodyCompDataPoint {
    let date: Date
    let value: Double
}

// MARK: - Preview

#if DEBUG
struct BodyCompositionTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        BodyCompositionTimelineView()
    }
}
#endif
