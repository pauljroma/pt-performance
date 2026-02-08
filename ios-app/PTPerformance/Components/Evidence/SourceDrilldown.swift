//
//  SourceDrilldown.swift
//  PTPerformance
//
//  X2Index Phase 2 - M6: AI Provenance and Evidence Linking
//  Drill-down view showing full source data context
//
//  Features:
//  - Full source data (check-in values, HRV, etc.)
//  - Timestamp and recency
//  - Data quality indicators
//  - Navigation to original record
//

import SwiftUI

// MARK: - Source Drilldown View

/// Drill-down view showing detailed evidence source data
struct SourceDrilldown: View {
    let source: EvidenceSource
    var onNavigateToOriginal: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Source header
                    sourceHeader

                    // Quality indicators
                    qualityIndicators

                    // Source-specific data
                    sourceDataSection

                    // Navigation to original
                    if onNavigateToOriginal != nil {
                        navigateButton
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Evidence Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Source Header

    @ViewBuilder
    private var sourceHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                // Source type icon
                ZStack {
                    Circle()
                        .fill(Color.modusCyan.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: source.sourceType.icon)
                        .font(.title2)
                        .foregroundColor(.modusCyan)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(source.sourceType.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(source.timestamp.formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Recency badge
                    recencyBadge
                }

                Spacer()
            }

            // Snippet
            Text(source.snippet)
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)

            // Data value if present
            if let value = source.dataValue {
                HStack {
                    Text("Value:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.modusTealAccent)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    @ViewBuilder
    private var recencyBadge: some View {
        let recencyText = recencyDescription
        let recencyColor = recencyColor

        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.caption2)
            Text(recencyText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(recencyColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(recencyColor.opacity(0.15))
        .cornerRadius(CornerRadius.xs)
    }

    private var recencyDescription: String {
        let ageInDays = Date().timeIntervalSince(source.timestamp) / (24 * 3600)
        switch ageInDays {
        case 0..<1: return "Today"
        case 1..<2: return "Yesterday"
        case 2..<7: return "\(Int(ageInDays)) days ago"
        case 7..<14: return "1 week ago"
        case 14..<30: return "\(Int(ageInDays / 7)) weeks ago"
        default: return "\(Int(ageInDays / 30)) months ago"
        }
    }

    private var recencyColor: Color {
        switch source.recencyScore {
        case 0.8...1.0: return .modusTealAccent
        case 0.5..<0.8: return .modusCyan
        case 0.3..<0.5: return .orange
        default: return .red
        }
    }

    // MARK: - Quality Indicators

    @ViewBuilder
    private var qualityIndicators: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Data Quality")
                .font(.headline)

            HStack(spacing: Spacing.lg) {
                // Quality score
                QualityIndicator(
                    title: "Reliability",
                    value: source.qualityScore,
                    icon: "checkmark.shield.fill"
                )

                Divider()
                    .frame(height: 50)

                // Recency score
                QualityIndicator(
                    title: "Recency",
                    value: source.recencyScore,
                    icon: "clock.fill"
                )

                Divider()
                    .frame(height: 50)

                // Combined score
                QualityIndicator(
                    title: "Combined",
                    value: (source.qualityScore + source.recencyScore) / 2,
                    icon: "star.fill"
                )
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)

            // Explanation
            Text(qualityExplanation)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var qualityExplanation: String {
        let avgScore = (source.qualityScore + source.recencyScore) / 2
        if avgScore >= 0.8 {
            return "This is a high-quality, recent data source that strongly supports the claim."
        } else if avgScore >= 0.6 {
            return "This is a reliable data source with good recency."
        } else if avgScore >= 0.4 {
            return "This data source has moderate reliability or is somewhat dated."
        } else {
            return "This data source may be outdated or have limited reliability."
        }
    }

    // MARK: - Source Data Section

    @ViewBuilder
    private var sourceDataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Source Data")
                .font(.headline)

            if let rawData = source.rawData {
                sourceDataContent(rawData)
            } else {
                // Generic data display
                VStack(spacing: Spacing.xs) {
                    dataRow(label: "Source ID", value: source.sourceId)
                    dataRow(label: "Type", value: source.sourceType.rawValue)
                    dataRow(label: "Captured", value: source.timestamp.formatted())
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    @ViewBuilder
    private func sourceDataContent(_ data: EvidenceSource.SourceData) -> some View {
        switch data {
        case .checkIn(let checkIn):
            checkInDataView(checkIn)
        case .exerciseLog(let exercise):
            exerciseLogDataView(exercise)
        case .hrvReading(let hrv):
            hrvDataView(hrv)
        case .sleepData(let sleep):
            sleepDataView(sleep)
        case .labResult(let lab):
            labResultDataView(lab)
        case .dailyReadiness(let readiness):
            readinessDataView(readiness)
        case .generic(let dict):
            genericDataView(dict)
        }
    }

    @ViewBuilder
    private func checkInDataView(_ checkIn: EvidenceSource.CheckInData) -> some View {
        VStack(spacing: Spacing.xs) {
            dataRow(label: "Sleep Quality", value: "\(checkIn.sleepQuality)/5")
            dataRow(label: "Energy", value: "\(checkIn.energy)/10")
            dataRow(label: "Soreness", value: "\(checkIn.soreness)/10")
            dataRow(label: "Stress", value: "\(checkIn.stress)/10")
            dataRow(label: "Mood", value: "\(checkIn.mood)/5")
            if let pain = checkIn.painScore {
                dataRow(label: "Pain", value: "\(pain)/10")
            }
            if let notes = checkIn.freeText, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    @ViewBuilder
    private func exerciseLogDataView(_ exercise: EvidenceSource.ExerciseLogData) -> some View {
        VStack(spacing: Spacing.xs) {
            dataRow(label: "Exercise", value: exercise.exerciseName)
            dataRow(label: "Sets", value: "\(exercise.sets)")
            if let reps = exercise.reps {
                dataRow(label: "Reps", value: "\(reps)")
            }
            if let weight = exercise.weight {
                dataRow(label: "Weight", value: String(format: "%.1f lbs", weight))
            }
            if let rpe = exercise.rpe {
                dataRow(label: "RPE", value: "\(rpe)/10")
            }
            dataRow(label: "Completed", value: exercise.completedAt.formatted())
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    @ViewBuilder
    private func hrvDataView(_ hrv: EvidenceSource.HRVData) -> some View {
        VStack(spacing: Spacing.xs) {
            dataRow(label: "HRV", value: String(format: "%.0f ms", hrv.hrvValue))
            if let rhr = hrv.restingHeartRate {
                dataRow(label: "Resting HR", value: String(format: "%.0f bpm", rhr))
            }
            dataRow(label: "Source", value: hrv.source.capitalized)
            dataRow(label: "Measured", value: hrv.timestamp.formatted())
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    @ViewBuilder
    private func sleepDataView(_ sleep: EvidenceSource.SleepDataRecord) -> some View {
        VStack(spacing: Spacing.xs) {
            dataRow(label: "Total Sleep", value: String(format: "%.1f hours", sleep.totalSleep))
            if let deep = sleep.deepSleep {
                dataRow(label: "Deep Sleep", value: String(format: "%.1f hours", deep))
            }
            if let rem = sleep.remSleep {
                dataRow(label: "REM Sleep", value: String(format: "%.1f hours", rem))
            }
            if let efficiency = sleep.sleepEfficiency {
                dataRow(label: "Efficiency", value: String(format: "%.0f%%", efficiency))
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    @ViewBuilder
    private func labResultDataView(_ lab: EvidenceSource.LabResultData) -> some View {
        VStack(spacing: Spacing.xs) {
            dataRow(label: "Test", value: lab.testName)
            dataRow(label: "Value", value: "\(lab.value) \(lab.unit)")
            if let range = lab.referenceRange {
                dataRow(label: "Reference Range", value: range)
            }

            HStack {
                Text("Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(lab.status.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(labStatusColor(lab.status))
            }

            dataRow(label: "Collected", value: lab.collectedAt.formatted())
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func labStatusColor(_ status: EvidenceSource.LabResultData.LabStatus) -> Color {
        switch status {
        case .normal: return .modusTealAccent
        case .low, .high: return .orange
        case .critical: return .red
        }
    }

    @ViewBuilder
    private func readinessDataView(_ readiness: EvidenceSource.DailyReadinessData) -> some View {
        VStack(spacing: Spacing.xs) {
            if let score = readiness.readinessScore {
                dataRow(label: "Readiness Score", value: String(format: "%.0f", score))
            }
            if let sleep = readiness.sleepHours {
                dataRow(label: "Sleep", value: String(format: "%.1f hours", sleep))
            }
            if let energy = readiness.energyLevel {
                dataRow(label: "Energy", value: "\(energy)/10")
            }
            if let soreness = readiness.sorenessLevel {
                dataRow(label: "Soreness", value: "\(soreness)/10")
            }
            if let stress = readiness.stressLevel {
                dataRow(label: "Stress", value: "\(stress)/10")
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    @ViewBuilder
    private func genericDataView(_ dict: [String: String]) -> some View {
        VStack(spacing: Spacing.xs) {
            ForEach(Array(dict.keys.sorted()), id: \.self) { key in
                if let value = dict[key], !value.isEmpty {
                    dataRow(label: key.capitalized, value: value)
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    @ViewBuilder
    private func dataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }

    // MARK: - Navigate Button

    @ViewBuilder
    private var navigateButton: some View {
        Button {
            HapticFeedback.medium()
            onNavigateToOriginal?()
        } label: {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                Text("View Original Record")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.modusCyan)
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Quality Indicator

/// Individual quality indicator with score
struct QualityIndicator: View {
    let title: String
    let value: Double
    let icon: String

    private var color: Color {
        switch value {
        case 0.8...1.0: return .modusTealAccent
        case 0.5..<0.8: return .modusCyan
        case 0.3..<0.5: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text("\(Int(value * 100))%")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("\(title): \(Int(value * 100)) percent")
    }
}

// MARK: - Source Drilldown Sheet

/// Convenience wrapper for presenting as a sheet
struct SourceDrilldownSheet: View {
    let evidenceRef: EvidenceClaim.EvidenceRef
    var onNavigateToOriginal: (() -> Void)?

    @EnvironmentObject private var provenanceService: ProvenanceService
    @State private var source: EvidenceSource?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading source data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let source = source {
                SourceDrilldown(
                    source: source,
                    onNavigateToOriginal: onNavigateToOriginal
                )
            } else {
                // Fallback with basic info
                SourceDrilldown(
                    source: EvidenceSource(
                        id: evidenceRef.id,
                        sourceType: evidenceRef.sourceType,
                        sourceId: evidenceRef.sourceId,
                        timestamp: evidenceRef.timestamp,
                        snippet: evidenceRef.snippet,
                        dataValue: evidenceRef.dataValue,
                        rawData: nil,
                        qualityScore: evidenceRef.sourceType.reliabilityWeight,
                        recencyScore: 0.5
                    ),
                    onNavigateToOriginal: onNavigateToOriginal
                )
            }
        }
        .task {
            await loadSourceData()
        }
    }

    private func loadSourceData() async {
        let sources = await provenanceService.getClaimSources(claimId: evidenceRef.id)
        source = sources.first { $0.id == evidenceRef.id }
        isLoading = false
    }
}

// MARK: - Preview

#if DEBUG
struct SourceDrilldown_Previews: PreviewProvider {
    static var sampleCheckInSource: EvidenceSource {
        EvidenceSource(
            id: UUID(),
            sourceType: .checkIn,
            sourceId: UUID().uuidString,
            timestamp: Date().addingTimeInterval(-86400),
            snippet: "Reported feeling well-rested, low stress",
            dataValue: "82",
            rawData: .checkIn(EvidenceSource.CheckInData(
                id: UUID(),
                date: Date().addingTimeInterval(-86400),
                sleepQuality: 4,
                soreness: 3,
                stress: 2,
                energy: 8,
                mood: 4,
                painScore: nil,
                freeText: "Feeling good today, ready to train hard!"
            )),
            qualityScore: 0.65,
            recencyScore: 0.9
        )
    }

    static var sampleHRVSource: EvidenceSource {
        EvidenceSource(
            id: UUID(),
            sourceType: .hrvReading,
            sourceId: UUID().uuidString,
            timestamp: Date().addingTimeInterval(-43200),
            snippet: "Morning HRV reading",
            dataValue: "65 ms",
            rawData: .hrvReading(EvidenceSource.HRVData(
                id: UUID(),
                timestamp: Date().addingTimeInterval(-43200),
                hrvValue: 65,
                restingHeartRate: 58,
                source: "apple_watch"
            )),
            qualityScore: 0.85,
            recencyScore: 0.95
        )
    }

    static var previews: some View {
        Group {
            SourceDrilldown(source: sampleCheckInSource)
                .previewDisplayName("Check-In Source")

            SourceDrilldown(source: sampleHRVSource)
                .previewDisplayName("HRV Source")
        }
    }
}
#endif
