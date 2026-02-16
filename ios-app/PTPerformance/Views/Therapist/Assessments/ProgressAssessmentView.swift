//
//  ProgressAssessmentView.swift
//  PTPerformance
//
//  Progress note and re-evaluation view with baseline comparison,
//  ROM/pain change highlighting, and goal progress tracking.
//

import SwiftUI

/// Progress assessment view for re-evaluations and progress notes
/// Compares current status with baseline and previous assessments
struct ProgressAssessmentView: View {
    // MARK: - Properties

    @StateObject private var viewModel: AssessmentProgressViewModel
    @StateObject private var formViewModel: IntakeAssessmentViewModel
    @Environment(\.dismiss) private var dismiss

    let patientId: UUID
    let therapistId: UUID
    let baselineAssessment: ClinicalAssessment?

    // UI State
    @State private var selectedTab: ProgressTab = .summary
    @State private var showingAddMeasurementSheet = false
    @State private var showingSubmitConfirmation = false

    // MARK: - Initialization

    init(patientId: UUID, therapistId: UUID, baselineAssessment: ClinicalAssessment? = nil) {
        self.patientId = patientId
        self.therapistId = therapistId
        self.baselineAssessment = baselineAssessment

        _viewModel = StateObject(wrappedValue: AssessmentProgressViewModel())
        _formViewModel = StateObject(wrappedValue: {
            let vm = IntakeAssessmentViewModel()
            vm.initializeNewAssessment(patientId: patientId, therapistId: therapistId)
            return vm
        }())
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                tabSelector

                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    summaryView
                        .tag(ProgressTab.summary)

                    romComparisonView
                        .tag(ProgressTab.rom)

                    painComparisonView
                        .tag(ProgressTab.pain)

                    goalsProgressView
                        .tag(ProgressTab.goals)

                    notesView
                        .tag(ProgressTab.notes)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Progress Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Submit") {
                        showingSubmitConfirmation = true
                    }
                    .disabled(!formViewModel.canSubmit)
                }
            }
            .task {
                await viewModel.initialize(patientId: patientId)
            }
            .alert("Submit Progress Note", isPresented: $showingSubmitConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Submit") {
                    Task { await formViewModel.submitAssessment() }
                }
            } message: {
                Text("Submit this progress note for the patient record?")
            }
            .alert("Success", isPresented: .constant(formViewModel.successMessage != nil)) {
                Button("OK") {
                    formViewModel.clearMessages()
                    dismiss()
                }
            } message: {
                Text(formViewModel.successMessage ?? "")
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ProgressTab.allCases) { tab in
                    Button {
                        withAnimation { selectedTab = tab }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                            Text(tab.title)
                        }
                        .font(.subheadline.weight(selectedTab == tab ? .semibold : .regular))
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab ? Color.modusCyan : Color(.secondarySystemGroupedBackground))
                        )
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Spacing.sm)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Summary View

    private var summaryView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overall Progress Card
                overallProgressCard

                // Quick Stats Grid
                quickStatsGrid

                // Recent Changes Summary
                recentChangesSection

                // MCID Achievement Section
                mcidAchievementSection
            }
            .padding()
        }
    }

    private var overallProgressCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Progress")
                        .font(.headline)
                    Text(viewModel.progressSummary.summaryText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status indicator
                ZStack {
                    Circle()
                        .fill(viewModel.statusColor.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: viewModel.statusIcon)
                        .font(.title2)
                        .foregroundColor(viewModel.statusColor)
                }
            }

            // Progress bars
            VStack(spacing: 12) {
                progressBar(
                    title: "ROM Improvements",
                    current: viewModel.progressSummary.romImprovements,
                    total: viewModel.romProgress.count,
                    color: .green
                )

                progressBar(
                    title: "Pain Reduction",
                    current: viewModel.progressSummary.painImprovements,
                    total: viewModel.painProgress.count,
                    color: .blue
                )

                progressBar(
                    title: "MCID Achievement",
                    current: viewModel.progressSummary.mcidAchievements,
                    total: viewModel.progressSummary.totalOutcomeMeasures,
                    color: .purple
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func progressBar(title: String, current: Int, total: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(current)/\(total)")
                    .font(.caption.weight(.semibold))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(color.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(color)
                        .frame(width: total > 0 ? geometry.size.width * (Double(current) / Double(total)) : 0, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private var quickStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                title: "Days in Tx",
                value: "\(viewModel.progressSummary.daysInTreatment)",
                icon: "calendar",
                color: .blue
            )

            StatCard(
                title: "Total Visits",
                value: "\(viewModel.progressSummary.totalVisits)",
                icon: "person.fill.checkmark",
                color: .green
            )

            StatCard(
                title: "MCID Rate",
                value: String(format: "%.0f%%", viewModel.mcidAchievementRate),
                icon: "chart.line.uptrend.xyaxis",
                color: .purple
            )
        }
    }

    private var recentChangesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Changes")
                .font(.headline)

            if viewModel.romProgress.isEmpty && viewModel.painProgress.isEmpty {
                Text("No previous assessments to compare")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Show significant changes
                ForEach(viewModel.romProgress.prefix(3)) { item in
                    ChangeRow(
                        title: item.displayTitle,
                        change: "\(item.change > 0 ? "+" : "")\(item.change) degrees",
                        status: item.progressStatus
                    )
                }

                ForEach(viewModel.painProgress.prefix(2)) { item in
                    ChangeRow(
                        title: item.displayTitle,
                        change: "\(item.change > 0 ? "+" : "")\(item.change) points",
                        status: item.progressStatus
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var mcidAchievementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MCID Achievements")
                    .font(.headline)
                Spacer()
                Text("Minimal Clinically Important Difference")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.outcomeProgress.isEmpty {
                Text("No outcome measures recorded yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.outcomeProgress) { item in
                    MCIDAchievementRow(item: item)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - ROM Comparison View

    private var romComparisonView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Time range selector
                Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                    ForEach(AssessmentProgressViewModel.TimeRange.allCases) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if viewModel.isLoadingROM {
                    ProgressView("Loading ROM data...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.romProgress.isEmpty {
                    PAEmptyStateCard(
                        icon: "ruler",
                        title: "No ROM Data",
                        message: "ROM measurements will appear here once recorded in assessments."
                    )
                } else {
                    // ROM comparison cards
                    ForEach(viewModel.romProgress) { item in
                        ROMComparisonCard(item: item)
                    }
                }

                // Add new measurement button
                Button {
                    showingAddMeasurementSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Today's Measurement")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.modusCyan)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Pain Comparison View

    private var painComparisonView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Current pain input
                currentPainInputCard

                Divider()
                    .padding(.horizontal)

                // Pain trend section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pain Trends")
                        .font(.headline)
                        .padding(.horizontal)

                    if viewModel.isLoadingPain {
                        ProgressView("Loading pain data...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if viewModel.painProgress.isEmpty {
                        PAEmptyStateCard(
                            icon: "bolt.slash",
                            title: "No Pain Data",
                            message: "Pain scores will be compared once multiple assessments are recorded."
                        )
                    } else {
                        ForEach(viewModel.painProgress) { item in
                            PainComparisonCard(item: item)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private var currentPainInputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Pain Levels")
                .font(.headline)

            VStack(spacing: 12) {
                ComparisonPainSlider(
                    title: "Pain at Rest",
                    currentValue: $formViewModel.painAtRest,
                    previousValue: baselineAssessment?.painAtRest
                )

                ComparisonPainSlider(
                    title: "Pain with Activity",
                    currentValue: $formViewModel.painWithActivity,
                    previousValue: baselineAssessment?.painWithActivity
                )

                ComparisonPainSlider(
                    title: "Worst Pain",
                    currentValue: $formViewModel.painWorst,
                    previousValue: baselineAssessment?.painWorst
                )
            }

            // Pain change summary
            if let baseline = baselineAssessment {
                let avgChange = calculatePainChange(from: baseline)
                HStack {
                    Image(systemName: avgChange < 0 ? "arrow.down.circle.fill" : avgChange > 0 ? "arrow.up.circle.fill" : "equal.circle.fill")
                        .foregroundColor(avgChange < 0 ? .green : avgChange > 0 ? .red : .orange)
                    Text(avgChange < 0 ? "Pain has decreased since baseline" : avgChange > 0 ? "Pain has increased since baseline" : "Pain is unchanged from baseline")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color(.tertiarySystemGroupedBackground))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }

    private func calculatePainChange(from baseline: ClinicalAssessment) -> Int {
        let baselineAvg = ((baseline.painAtRest ?? 0) + (baseline.painWithActivity ?? 0) + (baseline.painWorst ?? 0)) / 3
        let currentAvg = (formViewModel.painAtRest + formViewModel.painWithActivity + formViewModel.painWorst) / 3
        return currentAvg - baselineAvg
    }

    // MARK: - Goals Progress View

    private var goalsProgressView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Active Goals
                VStack(alignment: .leading, spacing: 12) {
                    Text("Treatment Goals")
                        .font(.headline)
                        .padding(.horizontal)

                    if let baseline = baselineAssessment, let goals = baseline.functionalGoals {
                        ForEach(Array(goals.enumerated()), id: \.offset) { index, goal in
                            PAGoalProgressCard(
                                goalNumber: index + 1,
                                goalText: goal,
                                progressPercentage: 0 // No tracked progress data available yet
                            )
                        }
                    } else {
                        PAEmptyStateCard(
                            icon: "target",
                            title: "No Goals Set",
                            message: "Treatment goals from the initial evaluation will appear here."
                        )
                    }
                }

                Divider()
                    .padding(.horizontal)

                // Add progress notes for goals
                VStack(alignment: .leading, spacing: 12) {
                    Text("Goal Progress Notes")
                        .font(.headline)
                        .padding(.horizontal)

                    TextEditor(text: $formViewModel.objectiveFindings)
                        .frame(minHeight: 120)
                        .padding(Spacing.xs)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.sm)
                        .padding(.horizontal)

                    Text("Document progress toward each treatment goal.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Notes View

    private var notesView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Subjective section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Subjective")
                        .font(.headline)

                    Text("Patient report since last visit:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: $formViewModel.chiefComplaint)
                        .frame(minHeight: 100)
                        .padding(Spacing.xs)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.sm)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(Color(.secondarySystemGroupedBackground))
                )

                // Objective section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Objective")
                        .font(.headline)

                    Text("Clinical observations and measurements:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: $formViewModel.objectiveFindings)
                        .frame(minHeight: 100)
                        .padding(Spacing.xs)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.sm)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(Color(.secondarySystemGroupedBackground))
                )

                // Assessment section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Assessment")
                        .font(.headline)

                    Text("Clinical interpretation and progress summary:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: $formViewModel.assessmentSummary)
                        .frame(minHeight: 100)
                        .padding(Spacing.xs)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.sm)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(Color(.secondarySystemGroupedBackground))
                )

                // Plan section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Plan")
                        .font(.headline)

                    Text("Treatment modifications and next steps:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: $formViewModel.treatmentPlan)
                        .frame(minHeight: 100)
                        .padding(Spacing.xs)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.sm)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
            .padding()
        }
    }
}

// MARK: - Progress Tab Enum

private enum ProgressTab: String, CaseIterable, Identifiable {
    case summary = "summary"
    case rom = "rom"
    case pain = "pain"
    case goals = "goals"
    case notes = "notes"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .summary: return "Summary"
        case .rom: return "ROM"
        case .pain: return "Pain"
        case .goals: return "Goals"
        case .notes: return "SOAP Notes"
        }
    }

    var icon: String {
        switch self {
        case .summary: return "chart.bar.fill"
        case .rom: return "ruler"
        case .pain: return "bolt.fill"
        case .goals: return "target"
        case .notes: return "doc.text.fill"
        }
    }
}

// MARK: - Supporting Views

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2.weight(.bold))

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct ChangeRow: View {
    let title: String
    let change: String
    let status: ProgressStatus

    var body: some View {
        HStack {
            Image(systemName: status.iconName)
                .foregroundColor(status.color)

            Text(title)
                .font(.subheadline)

            Spacer()

            Text(change)
                .font(.subheadline.weight(.medium))
                .foregroundColor(status.color)
        }
        .padding(.vertical, Spacing.xxs)
    }
}

private struct MCIDAchievementRow: View {
    let item: OutcomeProgressItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.measureType.displayName)
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 8) {
                    Text("Initial: \(String(format: "%.1f", item.initialScore))")
                    Text("-")
                    Text("Current: \(String(format: "%.1f", item.currentScore))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            if item.meetsMcid {
                Label("MCID Met", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.green)
            } else {
                Text(String(format: "%.1f to MCID", item.mcidThreshold - abs(item.change)))
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(item.meetsMcid ? Color.green.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
        )
    }
}

private struct ROMComparisonCard: View {
    let item: ROMProgressItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.displayTitle)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Image(systemName: item.progressStatus.iconName)
                    .foregroundColor(item.progressStatus.color)
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Initial")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(item.initialDegrees) degrees")
                        .font(.headline)
                }

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(item.currentDegrees) degrees")
                        .font(.headline)
                        .foregroundColor(item.progressStatus.color)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Change")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(item.change > 0 ? "+" : "")\(item.change) deg")
                        .font(.headline)
                        .foregroundColor(item.progressStatus.color)
                }
            }

            // Normal range indicator
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Normal: \(item.normalRange.lowerBound)-\(item.normalRange.upperBound) deg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%% of normal", item.percentageOfNormal))
                        .font(.caption.weight(.medium))
                        .foregroundColor(item.progressStatus.color)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(item.progressStatus.color)
                            .frame(width: geometry.size.width * min(item.percentageOfNormal / 100, 1.0), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }
}

private struct PainComparisonCard: View {
    let item: PainProgressItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.displayTitle)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Image(systemName: item.progressStatus.iconName)
                    .foregroundColor(item.progressStatus.color)
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Initial")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(item.initialScore)/10")
                        .font(.headline)
                }

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(item.currentScore)/10")
                        .font(.headline)
                        .foregroundColor(item.progressStatus.color)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Change")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(item.change > 0 ? "+" : "")\(item.change) pts")
                        .font(.headline)
                        .foregroundColor(item.progressStatus.color)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }
}

private struct ComparisonPainSlider: View {
    let title: String
    @Binding var currentValue: Int
    let previousValue: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)

                Spacer()

                if let previous = previousValue {
                    HStack(spacing: 4) {
                        Text("was \(previous)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if currentValue < previous {
                            Image(systemName: "arrow.down")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else if currentValue > previous {
                            Image(systemName: "arrow.up")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }

                Text("\(currentValue)/10")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(painColor(currentValue))
            }

            Slider(value: Binding(
                get: { Double(currentValue) },
                set: { currentValue = Int($0) }
            ), in: 0...10, step: 1)
            .tint(painColor(currentValue))
        }
    }

    private func painColor(_ score: Int) -> Color {
        switch score {
        case 0...3: return .green
        case 4...6: return .orange
        default: return .red
        }
    }
}

private struct PAGoalProgressCard: View {
    let goalNumber: Int
    let goalText: String
    let progressPercentage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Goal \(goalNumber)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background(Capsule().fill(Color.modusCyan.opacity(0.2)))
                    .foregroundColor(.modusCyan)

                Spacer()

                Text(String(format: "%.0f%%", progressPercentage))
                    .font(.headline)
                    .foregroundColor(progressColor)
            }

            Text(goalText)
                .font(.subheadline)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * (progressPercentage / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }

    private var progressColor: Color {
        switch progressPercentage {
        case 80...100: return .green
        case 50..<80: return .orange
        default: return .blue
        }
    }
}

private struct PAEmptyStateCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }
}

// MARK: - Preview

#if DEBUG
struct ProgressAssessmentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProgressAssessmentView(
                patientId: UUID(),
                therapistId: UUID(),
                baselineAssessment: ClinicalAssessment.sample
            )
            .previewDisplayName("With Baseline")

            ProgressAssessmentView(
                patientId: UUID(),
                therapistId: UUID()
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
#endif
