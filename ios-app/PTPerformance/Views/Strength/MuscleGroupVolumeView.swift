//
//  MuscleGroupVolumeView.swift
//  PTPerformance
//
//  ACP-1027: Volume per Muscle Group Breakdown
//  Displays pie chart and bar chart showing weekly volume distribution
//  across muscle groups using Swift Charts framework.
//

import SwiftUI
import Charts

// MARK: - Muscle Group Volume View

/// Displays volume distribution across muscle groups
/// Shows both a pie chart for overall breakdown and a stacked bar chart for weekly trends
struct MuscleGroupVolumeView: View {

    // MARK: - Properties

    let volumeByGroup: [MuscleGroupVolumeData]
    let weeklyBreakdown: [WeeklyMuscleGroupVolume]

    // MARK: - State

    @State private var selectedGroup: MuscleGroup?
    @State private var showBarChart = false

    // MARK: - Computed

    private var totalVolume: Double {
        volumeByGroup.reduce(0) { $0 + $1.totalVolume }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.lg) {
            if volumeByGroup.isEmpty {
                emptyState
            } else {
                // Toggle between pie and bar chart
                chartToggle

                // Chart section
                if showBarChart {
                    weeklyBarChart
                } else {
                    pieChartSection
                }

                // Muscle group breakdown list
                muscleGroupBreakdownList
            }
        }
    }

    // MARK: - Chart Toggle

    private var chartToggle: some View {
        Picker("Chart Type", selection: $showBarChart) {
            Label("Distribution", systemImage: "chart.pie.fill").tag(false)
            Label("Weekly", systemImage: "chart.bar.fill").tag(true)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Pie Chart Section

    private var pieChartSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Volume Distribution")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)
                .accessibilityAddTraits(.isHeader)

            ZStack {
                Chart(volumeByGroup) { group in
                    SectorMark(
                        angle: .value("Volume", group.totalVolume),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(group.muscleGroup.color)
                    .cornerRadius(4)
                    .opacity(selectedGroup == nil || selectedGroup == group.muscleGroup ? 1.0 : 0.4)
                }
                .chartLegend(.hidden)
                .frame(height: 250)
                .chartBackground { _ in
                    // Center label
                    VStack(spacing: 2) {
                        if let selected = selectedGroup,
                           let groupData = volumeByGroup.first(where: { $0.muscleGroup == selected }) {
                            Text(selected.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.modusDeepTeal)

                            Text(formatVolume(groupData.totalVolume))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text(String(format: "%.0f%%", groupData.percentage))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Total Volume")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(formatVolume(totalVolume))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .onTapGesture {
                selectedGroup = nil
            }

            // Legend
            pieChartLegend
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Pie Chart Legend

    private var pieChartLegend: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.xs) {
            ForEach(volumeByGroup.prefix(6)) { group in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if selectedGroup == group.muscleGroup {
                            selectedGroup = nil
                        } else {
                            selectedGroup = group.muscleGroup
                        }
                    }
                    HapticFeedback.selectionChanged()
                } label: {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(group.muscleGroup.color)
                            .frame(width: 8, height: 8)

                        Text(group.muscleGroup.rawValue)
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(
                        selectedGroup == group.muscleGroup
                            ? group.muscleGroup.color.opacity(0.15)
                            : Color.clear
                    )
                    .cornerRadius(CornerRadius.xs)
                }
            }
        }
    }

    // MARK: - Weekly Bar Chart

    private var weeklyBarChart: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Weekly Volume by Muscle Group")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)
                .accessibilityAddTraits(.isHeader)

            if weeklyBreakdown.isEmpty {
                weeklyChartEmptyState
            } else {
                Chart(weeklyBreakdown) { item in
                    BarMark(
                        x: .value("Week", item.weekStart, unit: .weekOfYear),
                        y: .value("Volume", item.volume)
                    )
                    .foregroundStyle(by: .value("Muscle Group", item.muscleGroup.rawValue))
                }
                .chartForegroundStyleScale(
                    domain: MuscleGroup.allCases.map(\.rawValue),
                    range: MuscleGroup.allCases.map(\.color)
                )
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let vol = value.as(Double.self) {
                                Text(formatAxisVolume(vol))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.caption)
                    }
                }
                .chartLegend(position: .bottom, spacing: 8) {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 4) {
                        ForEach(activeGroups, id: \.self) { group in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(group.color)
                                    .frame(width: 6, height: 6)
                                Text(group.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 250)
                .animatedTrim(duration: 0.8, delay: 0.1)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    private var activeGroups: [MuscleGroup] {
        let groups = Set(weeklyBreakdown.map { $0.muscleGroup })
        return MuscleGroup.allCases.filter { groups.contains($0) }
    }

    // MARK: - Muscle Group Breakdown List

    private var muscleGroupBreakdownList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Breakdown")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)
                .accessibilityAddTraits(.isHeader)

            ForEach(volumeByGroup) { group in
                muscleGroupRow(group)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func muscleGroupRow(_ data: MuscleGroupVolumeData) -> some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Image(systemName: data.muscleGroup.icon)
                    .font(.subheadline)
                    .foregroundColor(data.muscleGroup.color)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(data.muscleGroup.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("\(data.exerciseCount) exercise\(data.exerciseCount == 1 ? "" : "s"), \(data.sessionCount) session\(data.sessionCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatVolume(data.totalVolume))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .monospacedDigit()

                    Text(String(format: "%.0f%%", data.percentage))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(height: 4)

                    Rectangle()
                        .fill(data.muscleGroup.color)
                        .frame(width: geometry.size.width * CGFloat(data.percentage / 100), height: 4)
                }
                .cornerRadius(2)
            }
            .frame(height: 4)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(data.muscleGroup.rawValue): \(formatVolume(data.totalVolume)), \(String(format: "%.0f", data.percentage)) percent of total")
    }

    // MARK: - Empty States

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 48))
                .foregroundColor(.modusCyan.opacity(0.5))

            Text("No Volume Data")
                .font(.headline)

            Text("Complete workouts to see how your training volume is distributed across muscle groups.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.xxl)
    }

    private var weeklyChartEmptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.3))

            Text("Not enough weekly data")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM lbs", volume / 1_000_000)
        } else if volume >= 1000 {
            return String(format: "%.1fK lbs", volume / 1000)
        } else {
            return String(format: "%.0f lbs", volume)
        }
    }

    private func formatAxisVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.0fK", volume / 1000)
        } else {
            return String(format: "%.0f", volume)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct MuscleGroupVolumeView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData: [MuscleGroupVolumeData] = [
            MuscleGroupVolumeData(muscleGroup: .chest, totalVolume: 28500, percentage: 30, exerciseCount: 3, sessionCount: 12),
            MuscleGroupVolumeData(muscleGroup: .back, totalVolume: 22000, percentage: 23, exerciseCount: 4, sessionCount: 10),
            MuscleGroupVolumeData(muscleGroup: .legs, totalVolume: 25000, percentage: 26, exerciseCount: 3, sessionCount: 8),
            MuscleGroupVolumeData(muscleGroup: .shoulders, totalVolume: 10000, percentage: 11, exerciseCount: 2, sessionCount: 6),
            MuscleGroupVolumeData(muscleGroup: .arms, totalVolume: 9500, percentage: 10, exerciseCount: 4, sessionCount: 8)
        ]

        ScrollView {
            MuscleGroupVolumeView(
                volumeByGroup: sampleData,
                weeklyBreakdown: []
            )
            .padding()
        }
    }
}
#endif
