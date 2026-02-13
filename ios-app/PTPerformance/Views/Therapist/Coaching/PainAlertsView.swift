//
//  PainAlertsView.swift
//  PTPerformance
//
//  Pain-specific alerts list with trend visualization.
//  Shows patients with pain spikes, elevated pain, and pain trends.
//

import SwiftUI

// MARK: - PainAlertsView

struct PainAlertsView: View {
    let exceptions: [PatientException]
    var onSelectPatient: ((Patient) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var sortOption: SortOption = .severity
    @State private var selectedTimeframe: Timeframe = .week

    enum SortOption: String, CaseIterable {
        case severity = "Severity"
        case painLevel = "Pain Level"
        case name = "Name"
        case recent = "Most Recent"
    }

    enum Timeframe: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
    }

    private var sortedExceptions: [PatientException] {
        switch sortOption {
        case .severity:
            return exceptions.sorted { $0.severity > $1.severity }
        case .painLevel:
            return exceptions.sorted { ($0.currentPain ?? 0) > ($1.currentPain ?? 0) }
        case .name:
            return exceptions.sorted { $0.patient.fullName < $1.patient.fullName }
        case .recent:
            return exceptions.sorted { $0.createdAt > $1.createdAt }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Spacing.lg) {
                    // Summary Card
                    painSummaryCard

                    // Timeframe selector
                    timeframeSelector

                    // Pain distribution chart
                    painDistributionChart

                    // Patient list
                    if exceptions.isEmpty {
                        emptyState
                    } else {
                        patientList
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Pain Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    sortMenu
                }
            }
        }
    }

    // MARK: - Summary Card

    private var painSummaryCard: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pain Alerts")
                        .font(.headline)

                    Text("\(exceptions.count) patient\(exceptions.count == 1 ? "" : "s") with pain concerns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Critical count
                if criticalCount > 0 {
                    VStack(alignment: .trailing) {
                        Text("\(criticalCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)

                        Text("Critical")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // Stats row
            HStack(spacing: Spacing.lg) {
                statItem(
                    title: "High Pain",
                    value: "\(highPainCount)",
                    icon: "bolt.fill",
                    color: .red
                )

                statItem(
                    title: "Elevated",
                    value: "\(elevatedCount)",
                    icon: "waveform.path.ecg",
                    color: .orange
                )

                statItem(
                    title: "Trending Up",
                    value: "\(trendingUpCount)",
                    icon: "arrow.up.right",
                    color: .yellow
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
        .padding(.horizontal)
    }

    private func statItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)
            }

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Timeframe Selector

    private var timeframeSelector: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Button(action: {
                    HapticFeedback.selectionChanged()
                    withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                        selectedTimeframe = timeframe
                    }
                }) {
                    Text(timeframe.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedTimeframe == timeframe ? .semibold : .regular)
                        .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(selectedTimeframe == timeframe ? Color.red : Color(.secondarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Pain Distribution Chart

    private var painDistributionChart: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Pain Level Distribution")
                .font(.subheadline)
                .fontWeight(.semibold)

            // Simple bar chart showing pain distribution
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(1...10, id: \.self) { level in
                    let count = countForPainLevel(level)
                    let maxCount = maxPainLevelCount

                    VStack(spacing: 4) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorForPainLevel(level))
                            .frame(width: 24, height: max(8, CGFloat(count) / CGFloat(max(maxCount, 1)) * 80))

                        // Label
                        Text("\(level)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)

            // Legend
            HStack(spacing: Spacing.md) {
                legendItem(color: .green, label: "Low (1-3)")
                legendItem(color: .yellow, label: "Moderate (4-6)")
                legendItem(color: .red, label: "High (7-10)")
            }
            .font(.caption2)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
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

    private func countForPainLevel(_ level: Int) -> Int {
        exceptions.filter { exception in
            guard let pain = exception.currentPain else { return false }
            return Int(pain.rounded()) == level
        }.count
    }

    private var maxPainLevelCount: Int {
        (1...10).map { countForPainLevel($0) }.max() ?? 1
    }

    private func colorForPainLevel(_ level: Int) -> Color {
        switch level {
        case 1...3: return .green
        case 4...6: return .yellow
        default: return .red
        }
    }

    // MARK: - Patient List

    private var patientList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Patients")
                .font(.headline)
                .padding(.horizontal)

            ForEach(sortedExceptions) { exception in
                PainAlertPatientRow(
                    exception: exception,
                    onTap: {
                        onSelectPatient?(exception.patient)
                    }
                )
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("No Pain Alerts")
                .font(.headline)

            Text("All patients are reporting acceptable pain levels.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button {
                    sortOption = option
                } label: {
                    HStack {
                        Text(option.rawValue)
                        if sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }

    // MARK: - Computed Properties

    private var criticalCount: Int {
        exceptions.filter { $0.severity == .critical }.count
    }

    private var highPainCount: Int {
        exceptions.filter { ($0.currentPain ?? 0) >= 7 }.count
    }

    private var elevatedCount: Int {
        exceptions.filter { exception in
            let pain = exception.currentPain ?? 0
            return pain >= 4 && pain < 7
        }.count
    }

    private var trendingUpCount: Int {
        exceptions.filter { $0.painTrend == .up }.count
    }
}

// MARK: - Pain Alert Patient Row

struct PainAlertPatientRow: View {
    let exception: PatientException
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap?()
        }) {
            HStack(spacing: Spacing.md) {
                // Pain level indicator
                painLevelCircle

                // Patient info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exception.patient.fullName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: Spacing.xs) {
                        // Exception type
                        Text(exception.exceptionType.rawValue)
                            .font(.caption)
                            .foregroundColor(exception.exceptionType.color)

                        if exception.painTrend != nil {
                            Text("·")
                                .foregroundColor(.secondary)

                            // Trend indicator
                            trendBadge
                        }
                    }
                }

                Spacer()

                // Pain value
                if let pain = exception.currentPain {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(pain))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(painColor(for: pain))

                        Text("/10")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var painLevelCircle: some View {
        ZStack {
            Circle()
                .fill(painColor(for: exception.currentPain ?? 0).opacity(0.2))
                .frame(width: 44, height: 44)

            Image(systemName: "waveform.path.ecg")
                .font(.title3)
                .foregroundColor(painColor(for: exception.currentPain ?? 0))
        }
    }

    private var trendBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: exception.painTrend?.icon ?? "arrow.right")
                .font(.caption2)
            Text(trendText)
                .font(.caption2)
        }
        .foregroundColor(exception.painTrend == .up ? .red : .green)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background((exception.painTrend == .up ? Color.red : Color.green).opacity(0.15))
        .cornerRadius(CornerRadius.xs)
    }

    private var trendText: String {
        switch exception.painTrend {
        case .up: return "Increasing"
        case .down: return "Decreasing"
        case .stable, .none: return "Stable"
        }
    }

    private func painColor(for pain: Double) -> Color {
        switch pain {
        case 0..<4: return .green
        case 4..<7: return .yellow
        default: return .red
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PainAlertsView_Previews: PreviewProvider {
    static var sampleExceptions: [PatientException] = [
        PatientException(
            id: UUID(),
            patient: Patient(
                id: UUID(),
                therapistId: UUID(),
                firstName: "Mike",
                lastName: "Williams",
                email: "mike@example.com",
                sport: "Football",
                position: "QB",
                injuryType: "Shoulder",
                targetLevel: "Pro",
                profileImageUrl: nil,
                createdAt: Date(),
                flagCount: 2,
                highSeverityFlagCount: 1,
                adherencePercentage: 75.0,
                lastSessionDate: Date()
            ),
            exceptionType: .painSpike,
            severity: .critical,
            message: "Reported severe pain during session",
            daysSinceLastSession: 0,
            painTrend: .up,
            adherenceTrend: nil,
            currentPain: 9.0,
            currentAdherence: 75.0,
            createdAt: Date().addingTimeInterval(-3600)
        ),
        PatientException(
            id: UUID(),
            patient: Patient(
                id: UUID(),
                therapistId: UUID(),
                firstName: "Sarah",
                lastName: "Johnson",
                email: "sarah@example.com",
                sport: "Basketball",
                position: "Guard",
                injuryType: "ACL",
                targetLevel: "College",
                profileImageUrl: nil,
                createdAt: Date(),
                flagCount: 0,
                highSeverityFlagCount: 0,
                adherencePercentage: 85.0,
                lastSessionDate: Date()
            ),
            exceptionType: .painElevated,
            severity: .medium,
            message: "Pain levels elevated this week",
            daysSinceLastSession: 1,
            painTrend: .stable,
            adherenceTrend: nil,
            currentPain: 5.0,
            currentAdherence: 85.0,
            createdAt: Date().addingTimeInterval(-7200)
        )
    ]

    static var previews: some View {
        PainAlertsView(
            exceptions: sampleExceptions,
            onSelectPatient: { _ in }
        )
    }
}
#endif
