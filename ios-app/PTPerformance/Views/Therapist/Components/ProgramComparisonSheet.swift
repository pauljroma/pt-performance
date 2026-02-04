//
//  ProgramComparisonSheet.swift
//  PTPerformance
//
//  Side-by-side comparison of 2-3 programs
//  Shows bar charts, winner badges, and export functionality
//

import SwiftUI
import Charts

// MARK: - Program Comparison Sheet

struct ProgramComparisonSheet: View {
    @ObservedObject var viewModel: ProgramEffectivenessViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showExportSheet = false
    @State private var exportImage: UIImage?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if viewModel.isLoadingDetails {
                loadingView
            } else if let comparison = viewModel.comparison {
                comparisonContent(comparison)
            } else {
                emptyState
            }
        }
        .navigationTitle("Compare Programs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    exportComparison()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(viewModel.comparison == nil)
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let image = exportImage {
                ShareSheet(items: [image])
            }
        }
    }

    // MARK: - Comparison Content

    private func comparisonContent(_ comparison: ProgramComparison) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Programs being compared
                programsHeader(comparison.programs)

                // Metric comparison charts
                ForEach(ComparisonMetric.allCases) { metric in
                    metricComparisonCard(metric: metric, programs: comparison.programs, comparison: comparison)
                }

                // Overall winner
                overallWinnerCard(comparison)

                // Detailed stats table
                detailedStatsTable(comparison.programs)

                // Export button
                Button {
                    exportComparison()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Comparison")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Programs Header

    private func programsHeader(_ programs: [ProgramMetrics]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comparing \(programs.count) Programs")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(programs.enumerated()), id: \.element.id) { index, program in
                        ComparisonProgramBadge(
                            program: program,
                            colorIndex: index
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Metric Comparison Card

    private func metricComparisonCard(metric: ComparisonMetric, programs: [ProgramMetrics], comparison: ProgramComparison) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with winner badge
            HStack {
                Label(metric.displayName, systemImage: metric.icon)
                    .font(.headline)

                Spacer()

                if let winner = comparison.bestProgram(for: metric) {
                    WinnerBadge(programName: winner.programName)
                }
            }
            .padding(.horizontal)

            // Bar chart
            Chart {
                ForEach(Array(programs.enumerated()), id: \.element.id) { index, program in
                    let value = metricValue(for: metric, program: program)
                    BarMark(
                        x: .value("Program", program.programName),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(programColor(for: index))
                    .cornerRadius(4)
                    .annotation(position: .top) {
                        VStack(spacing: 2) {
                            if comparison.isWinner(program, for: metric) {
                                Image(systemName: "crown.fill")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                            Text(formattedMetricValue(metric, value: value))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYScale(domain: 0...(maxValueForMetric(metric, programs: programs) * 1.2))
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
    }

    // MARK: - Overall Winner Card

    private func overallWinnerCard(_ comparison: ProgramComparison) -> some View {
        VStack(spacing: 16) {
            if let winner = comparison.bestProgram(for: .effectiveness) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .font(.title)
                        .foregroundColor(.yellow)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Most Effective Program")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(winner.programName)
                            .font(.headline)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "%.0f%%", winner.effectivenessScore * 100))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)

                        Text("effectiveness")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Win count summary
                Divider()

                HStack(spacing: 16) {
                    ForEach(comparison.programs) { program in
                        let winCount = ComparisonMetric.allCases.filter { comparison.isWinner(program, for: $0) }.count

                        VStack(spacing: 4) {
                            Text("\(winCount)")
                                .font(.title3)
                                .fontWeight(.bold)

                            Text(program.programName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)

                            Text("wins")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.green.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Detailed Stats Table

    private func detailedStatsTable(_ programs: [ProgramMetrics]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Statistics")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("Metric")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)

                    ForEach(programs) { program in
                        Text(program.programName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))

                // Data rows
                ForEach(statsRows, id: \.label) { row in
                    statsRow(row, programs: programs)
                    Divider()
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
            .padding(.horizontal)
        }
    }

    private struct StatsRow {
        let label: String
        let getValue: (ProgramMetrics) -> String
    }

    private var statsRows: [StatsRow] {
        [
            StatsRow(label: "Total Patients", getValue: { "\($0.totalEnrollments)" }),
            StatsRow(label: "Completion Rate", getValue: { $0.formattedCompletionRate }),
            StatsRow(label: "Adherence", getValue: { $0.formattedAdherence }),
            StatsRow(label: "Pain Reduction", getValue: { $0.formattedPainReduction }),
            StatsRow(label: "Strength Gain", getValue: { $0.formattedStrengthGain }),
            StatsRow(label: "Avg Duration", getValue: { String(format: "%.1f wks", $0.averageDurationWeeks) }),
            StatsRow(label: "Active", getValue: { "\($0.activeEnrollments)" }),
            StatsRow(label: "Dropped", getValue: { "\($0.droppedEnrollments)" })
        ]
    }

    private func statsRow(_ row: StatsRow, programs: [ProgramMetrics]) -> some View {
        HStack {
            Text(row.label)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 100, alignment: .leading)

            ForEach(programs) { program in
                Text(row.getValue(program))
                    .font(.caption)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Helper Methods

    private func metricValue(for metric: ComparisonMetric, program: ProgramMetrics) -> Double {
        switch metric {
        case .completionRate:
            return program.completionRate * 100
        case .painReduction:
            return program.averagePainReduction
        case .strengthGain:
            return program.averageStrengthGain * 100
        case .adherence:
            return program.averageAdherence * 100
        case .effectiveness:
            return program.effectivenessScore * 100
        }
    }

    private func formattedMetricValue(_ metric: ComparisonMetric, value: Double) -> String {
        switch metric {
        case .completionRate, .adherence, .effectiveness, .strengthGain:
            return String(format: "%.0f%%", value)
        case .painReduction:
            return String(format: "%.1f", value)
        }
    }

    private func maxValueForMetric(_ metric: ComparisonMetric, programs: [ProgramMetrics]) -> Double {
        programs.map { metricValue(for: metric, program: $0) }.max() ?? 100
    }

    private func programColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .purple, .orange]
        return colors[index % colors.count]
    }

    private func exportComparison() {
        if let image = viewModel.generateComparisonImage() {
            exportImage = image
            showExportSheet = true
        }
    }

    // MARK: - Loading & Empty States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading comparison...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Unable to Compare")
                .font(.headline)

            Text("Please select 2-3 programs to compare.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Supporting Views

private struct ComparisonProgramBadge: View {
    let program: ProgramMetrics
    let colorIndex: Int

    private var color: Color {
        let colors: [Color] = [.blue, .green, .purple, .orange]
        return colors[colorIndex % colors.count]
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(program.programName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(program.totalEnrollments) patients")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }
}

private struct WinnerBadge: View {
    let programName: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.caption2)
                .foregroundColor(.yellow)

            Text(programName)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.yellow.opacity(0.2))
        .cornerRadius(8)
    }
}

// Note: ShareSheet is implemented elsewhere in the codebase

// MARK: - Preview

#if DEBUG
struct ProgramComparisonSheet_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProgramComparisonSheet(viewModel: {
                let vm = ProgramEffectivenessViewModel()
                vm.comparison = ProgramComparison(
                    programs: ProgramMetrics.sampleList,
                    comparisonDate: Date()
                )
                return vm
            }())
        }
    }
}
#endif
