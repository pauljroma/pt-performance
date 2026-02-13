//
//  ProgramHeatmapChart.swift
//  PTPerformance
//
//  Heatmap visualization for program phase metrics
//  Shows phase-by-phase completion, adherence, pain, and strength data
//

import SwiftUI
import Charts

// MARK: - Program Heatmap Chart

struct ProgramHeatmapChart: View {
    let dataPoints: [HeatmapDataPoint]
    let metricType: HeatmapMetricType
    var onCellTap: ((HeatmapDataPoint) -> Void)?

    @State private var selectedPoint: HeatmapDataPoint?

    private var accessibilitySummary: String {
        guard !dataPoints.isEmpty else { return "No data available" }
        let phaseCount = dataPoints.count
        let avgValue = dataPoints.map { $0.normalizedValue }.reduce(0, +) / Double(phaseCount)
        return "Heatmap showing \(metricType.displayName) across \(phaseCount) phases. Average: \(Int(avgValue * 100))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Phase Performance")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    Text(metricType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Legend
                legendView
            }

            if dataPoints.isEmpty {
                emptyState
            } else {
                heatmapGrid
            }

            // Selected cell detail
            if let selected = selectedPoint {
                selectedDetailView(selected)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Phase Performance Heatmap")
        .accessibilityValue(accessibilitySummary)
    }

    // MARK: - Legend

    private var legendView: some View {
        HStack(spacing: 4) {
            ForEach([0.2, 0.4, 0.6, 0.8, 1.0], id: \.self) { value in
                Rectangle()
                    .fill(colorForValue(value))
                    .frame(width: 12, height: 12)
                    .cornerRadius(CornerRadius.xs)
            }

            Text("Low")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            Text("High")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.3))

            Text("No phase data available")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Heatmap Grid

    private var heatmapGrid: some View {
        VStack(spacing: 8) {
            // Phase labels
            HStack(spacing: 8) {
                Text("Phase")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .leading)

                ForEach(dataPoints) { point in
                    Text("P\(point.phaseNumber)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Heatmap cells
            HStack(spacing: 8) {
                Text(metricType.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .leading)
                    .lineLimit(1)

                ForEach(dataPoints) { point in
                    heatmapCell(for: point)
                }
            }

            // Value labels
            HStack(spacing: 8) {
                Text("")
                    .frame(width: 60)

                ForEach(dataPoints) { point in
                    Text(formattedValue(for: point))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Patient count
            HStack(spacing: 8) {
                Text("Patients")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .leading)

                ForEach(dataPoints) { point in
                    Text("\(point.patientCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func heatmapCell(for point: HeatmapDataPoint) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPoint = selectedPoint?.id == point.id ? nil : point
            }
            onCellTap?(point)
            HapticFeedback.light()
        } label: {
            RoundedRectangle(cornerRadius: 6)
                .fill(colorForValue(point.normalizedValue))
                .frame(height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            selectedPoint?.id == point.id ? Color.primary : Color.clear,
                            lineWidth: 2
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(point.phaseName), \(metricType.displayName)")
        .accessibilityValue(formattedValue(for: point))
    }

    // MARK: - Selected Detail View

    private func selectedDetailView(_ point: HeatmapDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(point.phaseName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("Phase \(point.phaseNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(formattedValue(for: point))
                        .font(.headline)
                        .foregroundColor(point.color)

                    Text("\(point.patientCount) patients")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func colorForValue(_ value: Double) -> Color {
        let hue: Double
        if value >= 0.8 {
            hue = 0.33 // Green
        } else if value >= 0.6 {
            hue = 0.17 // Yellow-green
        } else if value >= 0.4 {
            hue = 0.08 // Orange
        } else {
            hue = 0 // Red
        }

        return Color(hue: hue, saturation: 0.7, brightness: 0.85)
    }

    private func formattedValue(for point: HeatmapDataPoint) -> String {
        switch metricType {
        case .completion, .adherence:
            return String(format: "%.0f%%", point.value * 100)
        case .painLevel:
            return String(format: "%.1f", point.value)
        case .strengthProgress:
            return String(format: "+%.0f%%", point.value * 100)
        }
    }
}

// MARK: - Dropoff Funnel Chart

struct DropoffFunnelChart: View {
    let dropoffData: [PhaseDropoffData]
    var onPhaseTap: ((PhaseDropoffData) -> Void)?

    @State private var selectedPhase: PhaseDropoffData?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Patient Journey")
                        .font(.headline)

                    Text("Completion through phases")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            if dropoffData.isEmpty {
                emptyState
            } else {
                funnelView
            }

            // Legend
            legendView
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.3))

            Text("No phase data available")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }

    private var funnelView: some View {
        GeometryReader { geometry in
            let maxPatients = dropoffData.first?.startingPatients ?? 1
            let barSpacing: CGFloat = 8
            let barHeight = (geometry.size.height - CGFloat(dropoffData.count - 1) * barSpacing) / CGFloat(dropoffData.count)

            VStack(spacing: barSpacing) {
                ForEach(dropoffData) { phase in
                    funnelBar(
                        phase: phase,
                        maxPatients: maxPatients,
                        totalWidth: geometry.size.width,
                        height: barHeight
                    )
                }
            }
        }
        .frame(height: 200)
    }

    private func funnelBar(phase: PhaseDropoffData, maxPatients: Int, totalWidth: CGFloat, height: CGFloat) -> some View {
        let widthRatio = CGFloat(phase.completingPatients) / CGFloat(max(maxPatients, 1))
        let barWidth = max(totalWidth * widthRatio, 60) // Minimum width for visibility

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPhase = selectedPhase?.id == phase.id ? nil : phase
            }
            onPhaseTap?(phase)
            HapticFeedback.light()
        } label: {
            HStack {
                // Phase indicator
                VStack(alignment: .leading, spacing: 2) {
                    Text("P\(phase.phaseNumber)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                .frame(width: 24)

                // Funnel bar
                ZStack(alignment: .leading) {
                    // Background (total starting)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: height - 8)

                    // Completing patients
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForRisk(phase.riskLevel))
                        .frame(width: barWidth, height: height - 8)

                    // Patient count
                    HStack {
                        Text("\(phase.completingPatients)/\(phase.startingPatients)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)

                        Spacer()

                        if phase.droppedPatients > 0 {
                            Text("-\(phase.droppedPatients)")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                        }
                    }
                }

                // Completion rate
                Text(phase.formattedCompletionRate)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForRisk(phase.riskLevel))
                    .frame(width: 40, alignment: .trailing)
            }
            .padding(.vertical, 2)
            .background(
                selectedPhase?.id == phase.id ?
                    Color.blue.opacity(0.1) : Color.clear
            )
            .cornerRadius(CornerRadius.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var legendView: some View {
        HStack(spacing: 16) {
            legendItem(color: .green, label: "Low Risk (<15%)")
            legendItem(color: .orange, label: "Medium (15-30%)")
            legendItem(color: .red, label: "High Risk (>30%)")
        }
        .font(.caption2)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
        }
    }

    private func colorForRisk(_ risk: RiskLevel) -> Color {
        switch risk {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Outcome Distribution Chart

struct OutcomeDistributionChart: View {
    let distribution: OutcomeDistribution

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Outcome Distribution")
                .font(.headline)

            Chart {
                ForEach(distribution.chartData) { data in
                    SectorMark(
                        angle: .value("Count", data.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 1
                    )
                    .foregroundStyle(data.color)
                    .annotation(position: .overlay) {
                        if data.count > 0 {
                            Text("\(data.count)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .frame(height: 180)

            // Legend
            HStack(spacing: 12) {
                ForEach(distribution.chartData) { data in
                    if data.count > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(data.color)
                                .frame(width: 8, height: 8)
                            Text(data.category.displayName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Summary stats
            Divider()

            HStack(spacing: 16) {
                VStack {
                    Text(String(format: "%.0f%%", distribution.successRate * 100))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Success")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack {
                    Text(String(format: "%.0f%%", distribution.partialRate * 100))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Partial")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack {
                    Text(String(format: "%.0f%%", distribution.failureRate * 100))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("Failed")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 50)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Preview

#if DEBUG
struct ProgramHeatmapChart_Previews: PreviewProvider {
    static var sampleHeatmapData: [HeatmapDataPoint] {
        [
            HeatmapDataPoint(phaseNumber: 1, phaseName: "Foundation", metricType: .completion, value: 0.95, patientCount: 45),
            HeatmapDataPoint(phaseNumber: 2, phaseName: "Strengthening", metricType: .completion, value: 0.88, patientCount: 42),
            HeatmapDataPoint(phaseNumber: 3, phaseName: "Advanced", metricType: .completion, value: 0.82, patientCount: 38),
            HeatmapDataPoint(phaseNumber: 4, phaseName: "Return to Sport", metricType: .completion, value: 0.90, patientCount: 35)
        ]
    }

    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProgramHeatmapChart(
                    dataPoints: sampleHeatmapData,
                    metricType: .completion
                )

                DropoffFunnelChart(
                    dropoffData: PhaseDropoffData.sampleList
                )

                OutcomeDistributionChart(
                    distribution: OutcomeDistribution.sample
                )
            }
            .padding()
        }
    }
}
#endif
