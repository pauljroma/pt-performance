// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  PatientProgressReportView.swift
//  PTPerformance
//
//  Comprehensive patient progress report view for therapists
//  Supports documentation and sharing of patient progress
//

import SwiftUI
import Charts

// MARK: - Static Formatters

private enum ReportFormatters {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

// MARK: - Date Range Options

enum ReportDateRange: Int, CaseIterable, Identifiable {
    case week = 7
    case twoWeeks = 14
    case month = 30
    case threeMonths = 90

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .week: return "7 Days"
        case .twoWeeks: return "14 Days"
        case .month: return "30 Days"
        case .threeMonths: return "90 Days"
        }
    }

    var shortName: String {
        switch self {
        case .week: return "7d"
        case .twoWeeks: return "14d"
        case .month: return "30d"
        case .threeMonths: return "90d"
        }
    }
}

// MARK: - Milestone Model

struct ProgressMilestone: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let achievedDate: Date
    let icon: String
    let color: Color

}

// MARK: - View Model

@MainActor
class PatientProgressReportViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Data
    @Published var painTrend: [PainDataPoint] = []
    @Published var adherence: AdherenceData?
    @Published var volumeData: VolumeChartData?
    @Published var recentSessions: [SessionSummary] = []
    @Published var notes: [SessionNote] = []
    @Published var milestones: [ProgressMilestone] = []
    @Published var program: Program?

    private let analyticsService = AnalyticsService.shared

    func fetchData(for patientId: String, days: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            async let painTrendTask = analyticsService.fetchPainTrend(patientId: patientId, days: days)
            async let adherenceTask = analyticsService.fetchAdherence(patientId: patientId, days: days)
            async let sessionsTask = analyticsService.fetchRecentSessions(patientId: patientId, limit: 20)

            let (painResult, adherenceResult, sessionsResult) = try await (painTrendTask, adherenceTask, sessionsTask)

            painTrend = painResult
            adherence = adherenceResult
            recentSessions = sessionsResult.filter { session in
                guard let sessionDate = session.completedAt ?? Optional(session.sessionDate) else { return false }
                let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
                return sessionDate >= startDate
            }

            // Fetch volume data
            let period: TimePeriod = days <= 7 ? .week : days <= 30 ? .month : .threeMonths
            volumeData = try? await analyticsService.calculateVolumeData(for: patientId, period: period)

            // Generate milestones based on data
            milestones = generateMilestones()

            isLoading = false
        } catch {
            errorMessage = "Failed to load report data: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func generateMilestones() -> [ProgressMilestone] {
        var milestones: [ProgressMilestone] = []

        // Check adherence milestone
        if let adherence = adherence {
            if adherence.adherencePercentage >= 90 {
                milestones.append(ProgressMilestone(
                    title: "Excellent Adherence",
                    description: "Maintained \(Int(adherence.adherencePercentage))% completion rate",
                    achievedDate: Date(),
                    icon: "star.fill",
                    color: .green
                ))
            } else if adherence.adherencePercentage >= 75 {
                milestones.append(ProgressMilestone(
                    title: "Good Adherence",
                    description: "Maintained \(Int(adherence.adherencePercentage))% completion rate",
                    achievedDate: Date(),
                    icon: "checkmark.circle.fill",
                    color: .blue
                ))
            }

            // Sessions milestone
            if adherence.completedSessions >= 10 {
                milestones.append(ProgressMilestone(
                    title: "10+ Sessions Complete",
                    description: "Completed \(adherence.completedSessions) sessions",
                    achievedDate: Date(),
                    icon: "flame.fill",
                    color: .orange
                ))
            }
        }

        // Check pain improvement
        if painTrend.count >= 2 {
            let firstPain = painTrend.first?.painScore ?? 0
            let lastPain = painTrend.last?.painScore ?? 0
            if lastPain < firstPain && lastPain < 5 {
                milestones.append(ProgressMilestone(
                    title: "Pain Reduced",
                    description: "Pain decreased from \(String(format: "%.1f", firstPain)) to \(String(format: "%.1f", lastPain))",
                    achievedDate: Date(),
                    icon: "heart.fill",
                    color: .green
                ))
            }
        }

        return milestones
    }

    // MARK: - Generate Shareable Report

    func generateShareableReport(patient: Patient, dateRange: ReportDateRange) -> String {
        var report = """
        =====================================
        PATIENT PROGRESS REPORT
        =====================================

        Patient: \(patient.fullName)
        """

        if let injury = patient.injuryType {
            report += "\nInjury Type: \(injury)"
        }

        if let program = program {
            report += "\nProgram: \(program.name)"
        }

        report += """

        Report Period: Last \(dateRange.displayName)
        Generated: \(formatDate(Date()))

        -------------------------------------
        PROGRESS SUMMARY
        -------------------------------------
        """

        if let adherence = adherence {
            report += """

            Sessions Completed: \(adherence.completedSessions) / \(adherence.totalSessions)
            Adherence Rate: \(Int(adherence.adherencePercentage))%
            """
        }

        if !painTrend.isEmpty {
            let avgPain = painTrend.map { $0.painScore }.reduce(0, +) / Double(painTrend.count)
            let latestPain = painTrend.last?.painScore ?? 0
            let firstPain = painTrend.first?.painScore ?? 0
            let painChange = latestPain - firstPain

            report += """

            Average Pain Score: \(String(format: "%.1f", avgPain)) / 10
            Latest Pain Score: \(String(format: "%.1f", latestPain)) / 10
            Pain Change: \(painChange >= 0 ? "+" : "")\(String(format: "%.1f", painChange))
            """
        }

        if let volumeData = volumeData, volumeData.totalVolume > 0 {
            report += """

            Total Volume: \(formatVolume(volumeData.totalVolume))
            Avg Volume/Week: \(formatVolume(volumeData.averageVolume))
            """
        }

        if !milestones.isEmpty {
            report += """

            -------------------------------------
            MILESTONES ACHIEVED
            -------------------------------------
            """
            for milestone in milestones {
                report += "\n- \(milestone.title): \(milestone.description)"
            }
        }

        if !notes.isEmpty {
            report += """

            -------------------------------------
            THERAPIST NOTES
            -------------------------------------
            """
            for note in notes.prefix(5) {
                report += "\n[\(formatDate(note.createdAt))] \(note.noteText)"
            }
        }

        report += """

        -------------------------------------
        Generated by Modus
        =====================================
        """

        return report
    }

    private func formatDate(_ date: Date) -> String {
        ReportFormatters.mediumDate.string(from: date)
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK lbs", volume / 1000)
        } else {
            return String(format: "%.0f lbs", volume)
        }
    }
}

// MARK: - Main View

struct PatientProgressReportView: View {
    let patient: Patient

    @StateObject private var viewModel = PatientProgressReportViewModel()
    @State private var selectedDateRange: ReportDateRange = .month
    @State private var showShareSheet = false
    @State private var shareText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else {
                    // Patient Header
                    ReportPatientHeader(patient: patient, program: viewModel.program)

                    // Date Range Selector
                    dateRangeSelector

                    // Progress Summary Section
                    progressSummarySection

                    // Charts Section
                    chartsSection

                    // Volume/Strength Section
                    if let volumeData = viewModel.volumeData, !volumeData.dataPoints.isEmpty {
                        volumeSection(volumeData)
                    }

                    // Milestones Section
                    if !viewModel.milestones.isEmpty {
                        milestonesSection
                    }

                    // Notes Summary Section
                    if !viewModel.notes.isEmpty {
                        notesSummarySection
                    }

                    // Share Button
                    shareButton
                }
            }
            .padding()
        }
        .navigationTitle("Progress Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    prepareAndShare()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share Report")
                .accessibilityHint("Share patient progress report")
            }
        }
        .task {
            await viewModel.fetchData(for: patient.id.uuidString, days: selectedDateRange.rawValue)
        }
        .onChange(of: selectedDateRange) { _, newValue in
            Task {
                await viewModel.fetchData(for: patient.id.uuidString, days: newValue.rawValue)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Generating report...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading progress report")
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Load Report")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.fetchData(for: patient.id.uuidString, days: selectedDateRange.rawValue)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error loading report: \(message)")
    }

    // MARK: - Date Range Selector

    private var dateRangeSelector: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Report Period")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: Spacing.xs) {
                ForEach(ReportDateRange.allCases) { range in
                    Button {
                        HapticFeedback.selectionChanged()
                        selectedDateRange = range
                    } label: {
                        Text(range.shortName)
                            .font(.subheadline)
                            .fontWeight(selectedDateRange == range ? .semibold : .regular)
                            .foregroundColor(selectedDateRange == range ? .white : .primary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(selectedDateRange == range ? Color.modusCyan : Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.sm)
                    }
                    .accessibilityLabel("\(range.displayName)")
                    .accessibilityAddTraits(selectedDateRange == range ? .isSelected : [])
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Progress Summary Section

    private var progressSummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Progress Summary")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: Spacing.sm) {
                // Sessions completed
                if let adherence = viewModel.adherence {
                    ReportStatRow(
                        icon: "checkmark.circle.fill",
                        iconColor: .green,
                        title: "Sessions Completed",
                        value: "\(adherence.completedSessions) / \(adherence.totalSessions)"
                    )

                    ReportStatRow(
                        icon: "chart.bar.fill",
                        iconColor: adherenceColor(adherence.adherencePercentage),
                        title: "Overall Adherence",
                        value: "\(Int(adherence.adherencePercentage))%"
                    )
                }

                // Pain trend summary
                if !viewModel.painTrend.isEmpty {
                    let avgPain = viewModel.painTrend.map { $0.painScore }.reduce(0, +) / Double(viewModel.painTrend.count)
                    let latestPain = viewModel.painTrend.last?.painScore ?? 0
                    let trend = calculatePainTrend()

                    ReportStatRow(
                        icon: "heart.fill",
                        iconColor: painColor(latestPain),
                        title: "Current Pain Level",
                        value: String(format: "%.1f / 10", latestPain),
                        trend: trend
                    )

                    ReportStatRow(
                        icon: "waveform.path.ecg",
                        iconColor: .purple,
                        title: "Average Pain",
                        value: String(format: "%.1f / 10", avgPain)
                    )
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    private func calculatePainTrend() -> TrendIndicator? {
        guard viewModel.painTrend.count >= 2 else { return nil }
        let firstPain = viewModel.painTrend.first?.painScore ?? 0
        let lastPain = viewModel.painTrend.last?.painScore ?? 0
        let change = lastPain - firstPain

        if abs(change) < 0.5 {
            return TrendIndicator(direction: .stable, value: change)
        } else if change < 0 {
            return TrendIndicator(direction: .decreasing, value: change) // Pain decreasing is good
        } else {
            return TrendIndicator(direction: .increasing, value: change) // Pain increasing is concerning
        }
    }

    // MARK: - Charts Section

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Trends")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            // Pain Trend Chart
            if !viewModel.painTrend.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Pain Trend")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    PainTrendChart(dataPoints: viewModel.painTrend, height: 180)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.md)
                }
            }

            // Adherence Chart
            if let adherence = viewModel.adherence {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Adherence")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    AdherenceCompactCard(adherence: adherence)
                }
            }
        }
    }

    // MARK: - Volume Section

    private func volumeSection(_ volumeData: VolumeChartData) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Training Volume")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VolumeChart(dataPoints: volumeData.dataPoints, height: 180)
        }
    }

    // MARK: - Milestones Section

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Milestones Achieved")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.milestones) { milestone in
                    MilestoneRow(milestone: milestone)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Notes Summary Section

    private var notesSummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recent Notes")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.notes.prefix(3)) { note in
                    NoteRow(note: note)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button {
            prepareAndShare()
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share Report")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.modusCyan)
            .cornerRadius(CornerRadius.md)
        }
        .accessibilityLabel("Share Report")
        .accessibilityHint("Opens share sheet with text summary of patient progress")
    }

    // MARK: - Helper Methods

    private func prepareAndShare() {
        HapticFeedback.medium()
        shareText = viewModel.generateShareableReport(patient: patient, dateRange: selectedDateRange)
        showShareSheet = true
    }

    private func adherenceColor(_ percentage: Double) -> Color {
        switch percentage {
        case 90...: return .green
        case 75..<90: return .blue
        case 60..<75: return .yellow
        default: return .red
        }
    }

    private func painColor(_ pain: Double) -> Color {
        switch pain {
        case 0...2: return .green
        case 2...5: return .yellow
        default: return .red
        }
    }
}

// MARK: - Supporting Views

struct ReportPatientHeader: View {
    let patient: Patient
    let program: Program?

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Avatar
            Circle()
                .fill(LinearGradient(
                    colors: [.modusCyan, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(patient.initials)
                        .font(.title)
                        .foregroundColor(.white)
                )

            // Name
            Text(patient.fullName)
                .font(.title2)
                .bold()

            // Injury type
            if let injury = patient.injuryType {
                Label(injury, systemImage: "cross.case")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Program name
            if let program = program {
                Label(program.name, systemImage: "doc.text")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Patient: \(patient.fullName), \(patient.injuryType ?? "No injury type specified")")
    }
}

struct ReportStatRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var trend: TrendIndicator? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: Spacing.xxs) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let trend = trend {
                    TrendBadge(trend: trend)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct TrendIndicator {
    enum Direction {
        case increasing, decreasing, stable
    }

    let direction: Direction
    let value: Double
}

struct TrendBadge: View {
    let trend: TrendIndicator

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trendIcon)
                .font(.caption2)
            Text(String(format: "%.1f", abs(trend.value)))
                .font(.caption2)
        }
        .foregroundColor(trendColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(trendColor.opacity(0.15))
        .cornerRadius(CornerRadius.xs)
    }

    private var trendIcon: String {
        switch trend.direction {
        case .increasing: return "arrow.up"
        case .decreasing: return "arrow.down"
        case .stable: return "minus"
        }
    }

    private var trendColor: Color {
        // For pain: decreasing is good (green), increasing is bad (red)
        switch trend.direction {
        case .increasing: return .red
        case .decreasing: return .green
        case .stable: return .gray
        }
    }
}

struct MilestoneRow: View {
    let milestone: ProgressMilestone

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: milestone.icon)
                .font(.title3)
                .foregroundColor(milestone.color)
                .frame(width: 32, height: 32)
                .background(milestone.color.opacity(0.15))
                .cornerRadius(CornerRadius.sm)

            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(milestone.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(formattedDate(milestone.achievedDate))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(milestone.title): \(milestone.description), achieved \(formattedDate(milestone.achievedDate))")
    }

    private func formattedDate(_ date: Date) -> String {
        ReportFormatters.shortDate.string(from: date)
    }
}

struct NoteRow: View {
    let note: SessionNote

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack {
                Image(systemName: note.typeIcon)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(note.noteType.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(formattedDate(note.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(note.noteText)
                .font(.subheadline)
                .lineLimit(3)
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(note.noteType) note from \(formattedDate(note.createdAt)): \(note.noteText)")
    }

    private func formattedDate(_ date: Date) -> String {
        ReportFormatters.shortDate.string(from: date)
    }
}

// MARK: - Preview

#if DEBUG
struct PatientProgressReportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PatientProgressReportView(patient: Patient(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                therapistId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
                firstName: "John",
                lastName: "Brebbia",
                email: "john@example.com",
                sport: "Baseball",
                position: "Pitcher",
                injuryType: "Tommy John Recovery",
                targetLevel: "MLB",
                profileImageUrl: nil,
                createdAt: Date(),
                flagCount: 0,
                highSeverityFlagCount: 0,
                adherencePercentage: 92.5,
                lastSessionDate: Date()
            ))
        }
    }
}
#endif
