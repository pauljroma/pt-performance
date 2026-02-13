//
//  ROMProgressCard.swift
//  PTPerformance
//
//  ROM Progress Card - Visual progress tracking for Range of Motion
//  Shows current ROM vs baseline/goal with trend visualization
//

import SwiftUI
import Charts

/// Card displaying ROM progress with visual indicators
/// Note: This view should be wrapped with .visibleIf(.romExercises) when used
/// as it's a Rehab mode feature
struct ROMProgressCard: View {
    // MARK: - Properties

    let measurements: [ROMeasurement]
    let targetJoint: String?
    let targetMovement: String?

    var onViewDetail: (() -> Void)?
    var onAddMeasurement: (() -> Void)?

    // MARK: - Computed Properties

    private var filteredMeasurements: [ROMeasurement] {
        var result = measurements

        if let joint = targetJoint {
            result = result.filter { $0.joint == joint }
        }
        if let movement = targetMovement {
            result = result.filter { $0.movement == movement }
        }

        return result.sorted { $0.measurementDate ?? Date() > $1.measurementDate ?? Date() }
    }

    private var latestMeasurement: ROMeasurement? {
        filteredMeasurements.first
    }

    private var baselineMeasurement: ROMeasurement? {
        filteredMeasurements.last
    }

    private var progressPercentage: Double? {
        guard let latest = latestMeasurement,
              let baseline = baselineMeasurement,
              baseline.normalRangeMin != baseline.normalRangeMax else { return nil }

        let normalRange = Double(latest.normalRangeMax - latest.normalRangeMin)
        guard normalRange > 0 else { return nil }

        let baselineDeficit = Double(latest.normalRangeMin - baseline.degrees)
        let currentDeficit = Double(latest.normalRangeMin - latest.degrees)

        if baselineDeficit <= 0 { return 100 } // Started within normal
        if currentDeficit <= 0 { return 100 } // Now within normal

        let improvement = baselineDeficit - currentDeficit
        return min(100, max(0, (improvement / baselineDeficit) * 100))
    }

    private var isImproving: Bool {
        guard let latest = latestMeasurement,
              let baseline = baselineMeasurement else { return false }
        return latest.degrees > baseline.degrees
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection

            Divider()
                .padding(.horizontal)

            // Content
            if filteredMeasurements.isEmpty {
                emptyState
            } else {
                VStack(spacing: 16) {
                    // Current Status
                    currentStatusSection

                    // Progress Chart (if multiple measurements)
                    if filteredMeasurements.count > 1 {
                        progressChartSection
                    }

                    // Baseline Comparison
                    if let baseline = baselineMeasurement, let latest = latestMeasurement, baseline.id != latest.id {
                        baselineComparisonSection(baseline: baseline, latest: latest)
                    }
                }
                .padding()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: "ruler.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("ROM Progress")
                    .font(.headline)
                    .foregroundColor(.primary)

                if let joint = targetJoint {
                    Text(joint.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let onViewDetail = onViewDetail, !filteredMeasurements.isEmpty {
                Button(action: onViewDetail) {
                    Text("Details")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
    }

    // MARK: - Current Status Section

    private var currentStatusSection: some View {
        HStack(spacing: 16) {
            // Current ROM Display
            if let latest = latestMeasurement {
                VStack(spacing: 4) {
                    Text("\(latest.degrees)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(latest.statusColor)
                        + Text("\u{00B0}")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(latest.statusColor)

                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Normal Range Comparison
                VStack(alignment: .leading, spacing: 8) {
                    // Progress towards normal
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Normal Range")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(latest.normalRangeMin)\u{00B0} - \(latest.normalRangeMax)\u{00B0}")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.green)
                        }

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(.tertiarySystemFill))

                                // Current progress
                                let progress = min(1, max(0, Double(latest.degrees) / Double(latest.normalRangeMin)))
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(latest.statusColor)
                                    .frame(width: geometry.size.width * CGFloat(progress))
                            }
                        }
                        .frame(height: 6)
                    }

                    // Status label
                    HStack(spacing: 4) {
                        Image(systemName: latest.degrees >= latest.normalRangeMin ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                            .foregroundColor(latest.statusColor)
                            .font(.caption)

                        Text(romStatusLabel(for: latest))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func romStatusLabel(for measurement: ROMeasurement) -> String {
        let deficit = measurement.normalRangeMin - measurement.degrees
        if deficit <= 0 {
            return "Within normal limits"
        } else if deficit <= 10 {
            return "Near normal (\(deficit)\u{00B0} below)"
        } else {
            return "\(deficit)\u{00B0} below normal"
        }
    }

    // MARK: - Progress Chart Section

    private var progressChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress Over Time")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            Chart(filteredMeasurements.prefix(10).reversed()) { measurement in
                // Line showing progress
                LineMark(
                    x: .value("Date", measurement.measurementDate ?? Date()),
                    y: .value("Degrees", measurement.degrees)
                )
                .foregroundStyle(Color.purple)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                .interpolationMethod(.catmullRom)

                // Points
                PointMark(
                    x: .value("Date", measurement.measurementDate ?? Date()),
                    y: .value("Degrees", measurement.degrees)
                )
                .foregroundStyle(measurement.statusColor)
                .symbolSize(30)

                // Normal range reference line
                if let latest = latestMeasurement {
                    RuleMark(y: .value("Normal Min", latest.normalRangeMin))
                        .foregroundStyle(Color.green.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .frame(height: 150)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    // MARK: - Baseline Comparison Section

    private func baselineComparisonSection(baseline: ROMeasurement, latest: ROMeasurement) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress from Baseline")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                // Baseline
                VStack(spacing: 4) {
                    Text("\(baseline.degrees)\u{00B0}")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.secondary)

                    Text("Baseline")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Arrow with improvement
                VStack(spacing: 4) {
                    let improvement = latest.degrees - baseline.degrees
                    Image(systemName: improvement >= 0 ? "arrow.right" : "arrow.left")
                        .foregroundColor(improvement >= 0 ? .green : .red)

                    HStack(spacing: 2) {
                        Text(improvement >= 0 ? "+" : "")
                            .foregroundColor(improvement >= 0 ? .green : .red)
                        Text("\(improvement)\u{00B0}")
                            .foregroundColor(improvement >= 0 ? .green : .red)
                    }
                    .font(.caption.weight(.bold))
                }
                .frame(maxWidth: .infinity)

                // Current
                VStack(spacing: 4) {
                    Text("\(latest.degrees)\u{00B0}")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(latest.statusColor)

                    Text("Current")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isImproving ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
            )

            // Progress percentage
            if let progress = progressPercentage {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.purple)
                        .font(.caption)

                    Text("\(Int(progress))% progress towards normal range")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "ruler")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No ROM Measurements")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)

            Text("Your therapist will record ROM measurements during sessions")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let onAddMeasurement = onAddMeasurement {
                Button(action: onAddMeasurement) {
                    Text("Add Measurement")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.purple)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ROM Measurement Extension

extension ROMeasurement {
    var measurementDate: Date? {
        // Assuming the model has a createdAt or measuredAt date
        // For now returning nil - would be populated from actual data
        nil
    }
}

// MARK: - Multi-Joint ROM Summary Card

/// Summary card showing ROM progress across multiple joints
struct ROMSummaryCard: View {
    let measurements: [ROMeasurement]
    var onViewDetail: ((String) -> Void)?

    // Group measurements by joint
    private var jointGroups: [(String, [ROMeasurement])] {
        Dictionary(grouping: measurements, by: { $0.joint })
            .sorted { $0.key < $1.key }
    }

    // Get latest measurement per joint
    private func latestMeasurement(for joint: String) -> ROMeasurement? {
        measurements.filter { $0.joint == joint }.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "figure.stand")
                    .foregroundColor(.purple)
                Text("ROM Overview")
                    .font(.headline)
                Spacer()
            }

            if jointGroups.isEmpty {
                emptyState
            } else {
                ForEach(jointGroups, id: \.0) { joint, measurements in
                    if let latest = measurements.first {
                        jointRow(joint: joint, measurement: latest)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func jointRow(joint: String, measurement: ROMeasurement) -> some View {
        Button {
            onViewDetail?(joint)
        } label: {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(measurement.statusColor)
                    .frame(width: 10, height: 10)

                // Joint name and movement
                VStack(alignment: .leading, spacing: 2) {
                    Text(joint.capitalized)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)

                    Text(measurement.movement.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Current value
                HStack(spacing: 4) {
                    Text("\(measurement.degrees)\u{00B0}")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(measurement.statusColor)

                    Text("/ \(measurement.normalRangeMin)\u{00B0}")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "ruler")
                    .font(.title2)
                    .foregroundColor(.secondary.opacity(0.5))
                Text("No measurements yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Previews

#Preview("ROM Progress Card - With Data") {
    ScrollView {
        VStack(spacing: 20) {
            ROMProgressCard(
                measurements: [
                    ROMeasurement(
                        id: UUID(),
                        joint: "shoulder",
                        movement: "flexion",
                        degrees: 165,
                        normalRangeMin: 170,
                        normalRangeMax: 180,
                        side: .right
                    ),
                    ROMeasurement(
                        id: UUID(),
                        joint: "shoulder",
                        movement: "flexion",
                        degrees: 155,
                        normalRangeMin: 170,
                        normalRangeMax: 180,
                        side: .right
                    ),
                    ROMeasurement(
                        id: UUID(),
                        joint: "shoulder",
                        movement: "flexion",
                        degrees: 140,
                        normalRangeMin: 170,
                        normalRangeMax: 180,
                        side: .right
                    )
                ],
                targetJoint: "shoulder",
                targetMovement: "flexion",
                onViewDetail: { print("View detail") }
            )

            ROMProgressCard(
                measurements: [],
                targetJoint: nil,
                targetMovement: nil,
                onAddMeasurement: { print("Add measurement") }
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("ROM Summary Card") {
    ROMSummaryCard(
        measurements: [
            ROMeasurement(
                id: UUID(),
                joint: "shoulder",
                movement: "flexion",
                degrees: 165,
                normalRangeMin: 170,
                normalRangeMax: 180,
                side: .right
            ),
            ROMeasurement(
                id: UUID(),
                joint: "knee",
                movement: "flexion",
                degrees: 120,
                normalRangeMin: 130,
                normalRangeMax: 140,
                side: .left
            ),
            ROMeasurement(
                id: UUID(),
                joint: "hip",
                movement: "extension",
                degrees: 25,
                normalRangeMin: 20,
                normalRangeMax: 30,
                side: .right
            )
        ],
        onViewDetail: { joint in print("View \(joint)") }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
