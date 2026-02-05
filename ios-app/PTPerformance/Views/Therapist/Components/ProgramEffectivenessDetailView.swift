//
//  ProgramEffectivenessDetailView.swift
//  PTPerformance
//
//  Detailed analytics view for a single program
//  Shows heatmap, dropoff analysis, outcomes, and patient list
//

import SwiftUI
import Charts

// MARK: - Program Effectiveness Detail View

struct ProgramEffectivenessDetailView: View {
    let program: ProgramMetrics
    @ObservedObject var viewModel: ProgramEffectivenessViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: DetailTab = .overview
    @State private var selectedPatient: ProgramPatient?

    enum DetailTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case phases = "Phases"
        case patients = "Patients"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .overview: return "chart.pie"
            case .phases: return "rectangle.stack"
            case .patients: return "person.2"
            }
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if viewModel.isLoadingDetails {
                loadingView
            } else {
                detailContent
            }
        }
        .navigationTitle(program.programName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(item: $selectedPatient) { patient in
            NavigationStack {
                PatientDetailSheet(patient: patient)
            }
        }
    }

    // MARK: - Detail Content

    private var detailContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Program summary header
                programSummaryCard

                // Tab selector
                tabSelector

                // Tab content
                tabContent
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Program Summary Card

    private var programSummaryCard: some View {
        VStack(spacing: 16) {
            // Effectiveness score
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Effectiveness Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.0f", program.effectivenessScore * 100))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(program.effectivenessRating.color)

                        Text("%")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(program.effectivenessRating.color)
                    }
                }

                Spacer()

                // Rating badge
                VStack(spacing: 4) {
                    Image(systemName: program.effectivenessRating.icon)
                        .font(.title)
                        .foregroundColor(program.effectivenessRating.color)

                    Text(program.effectivenessRating.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Key metrics
            HStack(spacing: 16) {
                SummaryMetric(
                    label: "Completion",
                    value: program.formattedCompletionRate,
                    icon: "checkmark.circle",
                    color: .green
                )

                SummaryMetric(
                    label: "Adherence",
                    value: program.formattedAdherence,
                    icon: "calendar",
                    color: .blue
                )

                SummaryMetric(
                    label: "Pain Relief",
                    value: program.formattedPainReduction,
                    icon: "bolt.slash",
                    color: .orange
                )

                SummaryMetric(
                    label: "Strength",
                    value: program.formattedStrengthGain,
                    icon: "arrow.up",
                    color: .purple
                )
            }

            // Enrollment stats
            HStack(spacing: 16) {
                VStack {
                    Text("\(program.totalEnrollments)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Total")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack {
                    Text("\(program.activeEnrollments)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Active")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack {
                    Text("\(program.completedEnrollments)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Completed")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack {
                    Text("\(program.droppedEnrollments)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("Dropped")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 60)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DetailTab.allCases) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal)
        }
    }

    private func tabButton(_ tab: DetailTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
            HapticFeedback.selectionChanged()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.caption)

                Text(tab.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            overviewContent
        case .phases:
            phasesContent
        case .patients:
            patientsContent
        }
    }

    // MARK: - Overview Content

    private var overviewContent: some View {
        VStack(spacing: 16) {
            // Outcome distribution
            if let distribution = viewModel.outcomeDistribution {
                OutcomeDistributionChart(distribution: distribution)
                    .padding(.horizontal)
            }

            // Metrics breakdown chart
            metricsBreakdownChart

            // Average duration
            avgDurationCard
        }
    }

    private var metricsBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)

            Chart {
                BarMark(
                    x: .value("Value", program.completionRateValue * 100),
                    y: .value("Metric", "Completion")
                )
                .foregroundStyle(.green)

                BarMark(
                    x: .value("Value", program.averageAdherenceValue * 100),
                    y: .value("Metric", "Adherence")
                )
                .foregroundStyle(.blue)

                BarMark(
                    x: .value("Value", min(program.averagePainReductionValue * 10, 100)),
                    y: .value("Metric", "Pain Relief")
                )
                .foregroundStyle(.orange)

                BarMark(
                    x: .value("Value", min(program.averageStrengthGainValue * 200, 100)),
                    y: .value("Metric", "Strength")
                )
                .foregroundStyle(.purple)
            }
            .frame(height: 160)
            .chartXScale(domain: 0...100)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)%")
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
    }

    private var avgDurationCard: some View {
        HStack {
            Image(systemName: "clock")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("Average Duration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(String(format: "%.1f weeks", program.averageDurationWeeksValue))
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Spacer()

            Text("from enrollment to completion")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
    }

    // MARK: - Phases Content

    private var phasesContent: some View {
        VStack(spacing: 16) {
            // Heatmap
            if !viewModel.heatmapData.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    // Metric selector
                    HStack {
                        Text("Metric:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Metric", selection: Binding(
                            get: { viewModel.selectedHeatmapMetric },
                            set: { newValue in
                                Task {
                                    await viewModel.updateHeatmapMetric(newValue)
                                }
                            }
                        )) {
                            ForEach(HeatmapMetricType.allCases) { metric in
                                Text(metric.displayName).tag(metric)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)

                    ProgramHeatmapChart(
                        dataPoints: viewModel.heatmapData,
                        metricType: viewModel.selectedHeatmapMetric
                    )
                    .padding(.horizontal)
                }
            }

            // Dropoff funnel
            if !viewModel.dropoffData.isEmpty {
                DropoffFunnelChart(dropoffData: viewModel.dropoffData)
                    .padding(.horizontal)
            }

            // Phase details
            phaseDetailsList
        }
    }

    private var phaseDetailsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Phase Details")
                .font(.headline)
                .padding(.horizontal)

            ForEach(viewModel.dropoffData) { phase in
                EffectivenessPhaseCard(phase: phase)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Patients Content

    private var patientsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Summary
            HStack {
                Text("\(viewModel.programPatients.count) Patients")
                    .font(.headline)

                Spacer()

                // Sort options
                Menu {
                    Button("By Progress") {}
                    Button("By Adherence") {}
                    Button("By Name") {}
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                        .font(.caption)
                }
            }
            .padding(.horizontal)

            if viewModel.programPatients.isEmpty {
                emptyPatientsState
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.programPatients) { patient in
                        PatientProgressCard(patient: patient) {
                            selectedPatient = patient
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var emptyPatientsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No patients found")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading details...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Supporting Views

private struct SummaryMetric: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct EffectivenessPhaseCard: View {
    let phase: PhaseDropoffData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Phase \(phase.phaseNumber): \(phase.phaseName)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                // Risk indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(phase.riskLevel.color)
                        .frame(width: 8, height: 8)
                    Text(phase.riskLevel.displayName)
                        .font(.caption2)
                        .foregroundColor(phase.riskLevel.color)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(phase.completingPatients)/\(phase.startingPatients)")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("Completed")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(phase.formattedCompletionRate)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    Text("Rate")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.0f days", phase.averageCompletionDays))
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("Avg Time")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if phase.droppedPatients > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(phase.droppedPatients)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        Text("Dropped")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !phase.commonDropoffReasons.isEmpty {
                Text("Common reasons: \(phase.commonDropoffReasons.prefix(2).joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
    }
}

private struct PatientProgressCard: View {
    let patient: ProgramPatient
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Text(patient.initials)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(patient.fullName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Label("Phase \(patient.currentPhase)", systemImage: "rectangle.stack")
                        Label(String(format: "%.0f%%", patient.completionPercentage * 100), systemImage: "checkmark.circle")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Status badge
                Text(patient.enrollmentStatus.displayName)
                    .font(.caption2)
                    .foregroundColor(patient.enrollmentStatus.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(patient.enrollmentStatus.color.opacity(0.15))
                    .cornerRadius(8)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Patient Detail Sheet

private struct PatientDetailSheet: View {
    let patient: ProgramPatient
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 60, height: 60)

                        Text(patient.initials)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(patient.fullName)
                            .font(.headline)

                        Text("Enrolled \(patient.enrollmentDate, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Progress") {
                HStack {
                    Text("Current Phase")
                    Spacer()
                    Text("Phase \(patient.currentPhase)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Completion")
                    Spacer()
                    Text(String(format: "%.0f%%", patient.completionPercentage * 100))
                        .foregroundColor(.green)
                }

                HStack {
                    Text("Adherence")
                    Spacer()
                    Text(String(format: "%.0f%%", patient.adherenceRate * 100))
                        .foregroundColor(.blue)
                }

                if let painReduction = patient.painReduction {
                    HStack {
                        Text("Pain Reduction")
                        Spacer()
                        Text(String(format: "%.1f pts", painReduction))
                            .foregroundColor(.orange)
                    }
                }
            }

            Section("Status") {
                HStack {
                    Text("Current Status")
                    Spacer()
                    Text(patient.enrollmentStatus.displayName)
                        .foregroundColor(patient.enrollmentStatus.color)
                }
            }
        }
        .navigationTitle("Patient Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ProgramEffectivenessDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProgramEffectivenessDetailView(
                program: ProgramMetrics.sample,
                viewModel: {
                    let vm = ProgramEffectivenessViewModel()
                    vm.outcomeDistribution = OutcomeDistribution.sample
                    vm.dropoffData = PhaseDropoffData.sampleList
                    return vm
                }()
            )
        }
    }
}
#endif
