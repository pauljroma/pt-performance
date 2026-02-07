//
//  AssessmentHistoryView.swift
//  PTPerformance
//
//  List view of all assessments for a patient with filtering,
//  ROM/pain trend charts, and MCID achievement highlights.
//

import SwiftUI
import Charts

/// Assessment history view showing all assessments for a patient
/// Features filtering, trend charts, and MCID achievement tracking
struct AssessmentHistoryView: View {
    // MARK: - Properties

    @StateObject private var viewModel: AssessmentProgressViewModel
    @Environment(\.dismiss) private var dismiss

    let patientId: UUID
    let patientName: String

    // UI State
    @State private var selectedFilter: AssessmentFilter = .all
    @State private var selectedChartMetric: AHChartMetric = .pain
    @State private var selectedAssessment: ClinicalAssessment?
    @State private var showingAssessmentDetail = false
    @State private var assessments: [ClinicalAssessment] = []
    @State private var isLoadingAssessments = false

    // MARK: - Initialization

    init(patientId: UUID, patientName: String = "Patient") {
        self.patientId = patientId
        self.patientName = patientName
        _viewModel = StateObject(wrappedValue: AssessmentProgressViewModel())
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // MCID Achievement Banner
                    mcidBanner

                    // Trend Charts Section
                    trendChartsSection

                    // Filter Tabs
                    filterTabs

                    // Assessment List
                    assessmentListSection
                }
                .padding()
            }
            .navigationTitle("Assessment History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            // Export action
                        } label: {
                            Label("Export Report", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            Task { await refreshData() }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await refreshData()
            }
            .sheet(isPresented: $showingAssessmentDetail) {
                if let assessment = selectedAssessment {
                    AssessmentDetailSheet(assessment: assessment)
                }
            }
        }
    }

    // MARK: - MCID Achievement Banner

    private var mcidBanner: some View {
        Group {
            if viewModel.progressSummary.mcidAchievements > 0 {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 50, height: 50)

                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("MCID Achievements")
                            .font(.headline)

                        Text("\(viewModel.progressSummary.mcidAchievements) of \(viewModel.progressSummary.totalOutcomeMeasures) outcome measures show clinically meaningful improvement")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Trend Charts Section

    private var trendChartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart metric selector
            HStack {
                Text("Trends")
                    .font(.headline)

                Spacer()

                Picker("Metric", selection: $selectedChartMetric) {
                    ForEach(AHChartMetric.allCases) { metric in
                        Text(metric.title).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            // Time range selector
            Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                ForEach(AssessmentProgressViewModel.TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)

            // Chart
            chartView
                .frame(height: 200)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
    }

    @ViewBuilder
    private var chartView: some View {
        switch selectedChartMetric {
        case .pain:
            painTrendChart
        case .rom:
            romTrendChart
        case .outcomes:
            outcomesTrendChart
        }
    }

    private var painTrendChart: some View {
        Group {
            if viewModel.painTrend.isEmpty {
                EmptyChartView(message: "No pain data available")
            } else {
                Chart {
                    ForEach(viewModel.painTrend) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Pain", point.value)
                        )
                        .foregroundStyle(Color.red)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Pain", point.value)
                        )
                        .foregroundStyle(Color.red)
                    }
                }
                .chartYScale(domain: 0...10)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 2, 4, 6, 8, 10]) { value in
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
            }
        }
    }

    private var romTrendChart: some View {
        Group {
            if viewModel.romProgress.isEmpty {
                EmptyChartView(message: "No ROM data available")
            } else {
                // Show first ROM measurement trend as example
                let firstROM = viewModel.romProgress.first!
                Chart {
                    ForEach(firstROM.measurements) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Degrees", point.value)
                        )
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Degrees", point.value)
                        )
                        .foregroundStyle(Color.blue)
                    }

                    // Normal range area
                    RuleMark(y: .value("Normal Min", firstROM.normalRange.lowerBound))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(Color.green.opacity(0.5))

                    RuleMark(y: .value("Normal Max", firstROM.normalRange.upperBound))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(Color.green.opacity(0.5))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
            }
        }
    }

    private var outcomesTrendChart: some View {
        Group {
            if viewModel.outcomeProgress.isEmpty {
                EmptyChartView(message: "No outcome measure data available")
            } else {
                Chart {
                    ForEach(viewModel.outcomeProgress) { item in
                        ForEach(item.measurements) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Score", point.value)
                            )
                            .foregroundStyle(by: .value("Measure", item.measureType.rawValue))
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("Score", point.value)
                            )
                            .foregroundStyle(by: .value("Measure", item.measureType.rawValue))
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartLegend(position: .bottom)
            }
        }
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AssessmentFilter.allCases) { filter in
                    AHFilterChip(
                        title: filter.title,
                        count: countForFilter(filter),
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
        }
    }

    private func countForFilter(_ filter: AssessmentFilter) -> Int {
        switch filter {
        case .all:
            return assessments.count
        case .intake:
            return assessments.filter { $0.assessmentType == .intake }.count
        case .progress:
            return assessments.filter { $0.assessmentType == .progress }.count
        case .discharge:
            return assessments.filter { $0.assessmentType == .discharge }.count
        case .outcomes:
            return viewModel.outcomeProgress.count
        }
    }

    // MARK: - Assessment List Section

    private var assessmentListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Assessments")
                    .font(.headline)

                Spacer()

                Text("\(filteredAssessments.count) records")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if isLoadingAssessments {
                ProgressView("Loading assessments...")
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if filteredAssessments.isEmpty {
                EmptyAssessmentView(filter: selectedFilter)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredAssessments) { assessment in
                        AssessmentHistoryCard(assessment: assessment) {
                            selectedAssessment = assessment
                            showingAssessmentDetail = true
                        }
                    }
                }
            }
        }
    }

    private var filteredAssessments: [ClinicalAssessment] {
        switch selectedFilter {
        case .all:
            return assessments
        case .intake:
            return assessments.filter { $0.assessmentType == .intake }
        case .progress:
            return assessments.filter { $0.assessmentType == .progress }
        case .discharge:
            return assessments.filter { $0.assessmentType == .discharge }
        case .outcomes:
            return [] // Outcomes are shown separately
        }
    }

    // MARK: - Helpers

    private func refreshData() async {
        await viewModel.initialize(patientId: patientId)
        await loadAssessments()
    }

    private func loadAssessments() async {
        isLoadingAssessments = true

        // This would normally call the assessment service
        // For now, we'll use sample data in preview
        #if DEBUG
        assessments = [
            ClinicalAssessment.sample,
            ClinicalAssessment.draftSample
        ]
        #endif

        isLoadingAssessments = false
    }
}

// MARK: - Assessment Filter Enum

private enum AssessmentFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case intake = "intake"
    case progress = "progress"
    case discharge = "discharge"
    case outcomes = "outcomes"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .intake: return "Initial Evals"
        case .progress: return "Progress"
        case .discharge: return "Discharge"
        case .outcomes: return "Outcomes"
        }
    }
}

// MARK: - Chart Metric Enum

private enum AHChartMetric: String, CaseIterable, Identifiable {
    case pain = "pain"
    case rom = "rom"
    case outcomes = "outcomes"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pain: return "Pain"
        case .rom: return "ROM"
        case .outcomes: return "Outcomes"
        }
    }
}

// MARK: - Supporting Views

private struct AHFilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.2))
                        )
                }
            }
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

private struct AssessmentHistoryCard: View {
    let assessment: ClinicalAssessment
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Type icon
                ZStack {
                    Circle()
                        .fill(assessment.assessmentType.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: assessment.assessmentType.iconName)
                        .font(.title3)
                        .foregroundColor(assessment.assessmentType.color)
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(assessment.assessmentType.displayName)
                            .font(.subheadline.weight(.semibold))

                        Spacer()

                        // Status badge
                        Text(assessment.status.displayName)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(assessment.status.color.opacity(0.2))
                            )
                            .foregroundColor(assessment.status.color)
                    }

                    Text(assessment.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Quick stats
                    HStack(spacing: 12) {
                        if let pain = assessment.averagePainScore {
                            Label(String(format: "Pain: %.1f", pain), systemImage: "bolt.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        if assessment.romLimitationsCount > 0 {
                            Label("\(assessment.romLimitationsCount) ROM limits", systemImage: "ruler")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyChartView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct EmptyAssessmentView: View {
    let filter: AssessmentFilter

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No \(filter.title.lowercased()) assessments found")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct AssessmentDetailSheet: View {
    let assessment: ClinicalAssessment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: assessment.assessmentType.iconName)
                                .foregroundColor(assessment.assessmentType.color)
                            Text(assessment.assessmentType.displayName)
                                .font(.headline)
                        }

                        Text(assessment.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: assessment.status.iconName)
                            Text(assessment.status.displayName)
                        }
                        .font(.caption)
                        .foregroundColor(assessment.status.color)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(assessment.assessmentType.color.opacity(0.1))
                    )

                    // Pain Summary
                    if assessment.painAtRest != nil || assessment.painWithActivity != nil {
                        DetailSection(title: "Pain Assessment", icon: "bolt.fill") {
                            VStack(spacing: 12) {
                                if let rest = assessment.painAtRest {
                                    AHDetailRow(label: "Pain at Rest", value: "\(rest)/10")
                                }
                                if let activity = assessment.painWithActivity {
                                    AHDetailRow(label: "Pain with Activity", value: "\(activity)/10")
                                }
                                if let worst = assessment.painWorst {
                                    AHDetailRow(label: "Worst Pain", value: "\(worst)/10")
                                }
                            }
                        }
                    }

                    // ROM Summary
                    if let romMeasurements = assessment.romMeasurements, !romMeasurements.isEmpty {
                        DetailSection(title: "ROM Measurements", icon: "ruler") {
                            VStack(spacing: 8) {
                                ForEach(romMeasurements) { rom in
                                    HStack {
                                        Text(rom.displayTitle)
                                            .font(.subheadline)
                                        Spacer()
                                        Text(rom.formattedMeasurement)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(rom.statusColor)
                                    }
                                }
                            }
                        }
                    }

                    // Chief Complaint
                    if let complaint = assessment.chiefComplaint {
                        DetailSection(title: "Chief Complaint", icon: "quote.bubble") {
                            Text(complaint)
                                .font(.subheadline)
                        }
                    }

                    // Assessment Summary
                    if let summary = assessment.assessmentSummary {
                        DetailSection(title: "Assessment Summary", icon: "doc.text") {
                            Text(summary)
                                .font(.subheadline)
                        }
                    }

                    // Treatment Plan
                    if let plan = assessment.treatmentPlan {
                        DetailSection(title: "Treatment Plan", icon: "list.bullet.clipboard") {
                            Text(plan)
                                .font(.subheadline)
                        }
                    }

                    // Goals
                    if let goals = assessment.functionalGoals, !goals.isEmpty {
                        DetailSection(title: "Functional Goals", icon: "target") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(goals.enumerated()), id: \.offset) { index, goal in
                                    HStack(alignment: .top) {
                                        Text("\(index + 1).")
                                            .font(.subheadline.weight(.semibold))
                                        Text(goal)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Assessment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct AHDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AssessmentHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AssessmentHistoryView(patientId: UUID(), patientName: "John Smith")
                .previewDisplayName("Default")

            AssessmentHistoryView(patientId: UUID(), patientName: "Jane Doe")
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif
