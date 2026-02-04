//
//  CohortAnalyticsDashboardView.swift
//  PTPerformance
//
//  Dashboard for therapists to view cohort analytics and patient benchmarks
//  Shows KPIs, patient rankings, compliance distribution, and retention curves
//

import SwiftUI
import Charts

// MARK: - Cohort Analytics Dashboard View

struct CohortAnalyticsDashboardView: View {
    @StateObject private var viewModel = CohortAnalyticsViewModel()
    @EnvironmentObject var appState: AppState

    @State private var selectedSection: DashboardSection = .overview
    @State private var showPatientDetail = false
    @State private var selectedPatientId: UUID?
    @State private var showFilterSheet = false

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    enum DashboardSection: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case rankings = "Rankings"
        case distribution = "Distribution"
        case retention = "Retention"
        case programs = "Programs"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .overview: return "chart.bar.xaxis"
            case .rankings: return "list.number"
            case .distribution: return "chart.bar"
            case .retention: return "person.3.sequence"
            case .programs: return "doc.text.magnifyingglass"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading && !viewModel.hasData {
                    loadingView
                } else if let error = viewModel.errorMessage, !viewModel.hasData {
                    errorView(error)
                } else {
                    mainContent
                }
            }
            .navigationTitle("Practice Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    refreshButton
                }
            }
            .refreshable {
                await refreshData()
            }
            .task {
                await loadData()
            }
            .onAppear {
                if let therapistId = appState.userId {
                    viewModel.startAutoRefresh(therapistId: therapistId, interval: 120)
                }
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
            .sheet(isPresented: $showPatientDetail) {
                if let comparison = viewModel.selectedPatientComparison,
                   let benchmarks = viewModel.benchmarks {
                    PatientComparisonDetailSheet(
                        comparison: comparison,
                        benchmarks: benchmarks,
                        onDismiss: {
                            showPatientDetail = false
                            viewModel.clearSelectedPatient()
                        }
                    )
                }
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Cohort health indicator
                cohortHealthCard

                // Section selector
                sectionSelector

                // Section content
                sectionContent
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Cohort Health Card

    private var cohortHealthCard: some View {
        VStack(spacing: 16) {
            // Header with status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cohort Health")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        Image(systemName: viewModel.cohortHealthStatus.iconName)
                            .font(.title2)
                            .foregroundColor(viewModel.cohortHealthStatus.color)

                        Text(viewModel.cohortHealthStatus.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(viewModel.cohortHealthStatus.color)
                    }
                }

                Spacer()

                // Patient count
                if let benchmarks = viewModel.benchmarks {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(benchmarks.totalPatients)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("patients")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // KPI row
            if let benchmarks = viewModel.benchmarks {
                kpiRow(benchmarks: benchmarks)
            }

            // Patients below benchmark indicator
            if viewModel.patientsBelowBenchmark > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Text("\(viewModel.patientsBelowBenchmark) patients below 50% adherence")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Spacer()

                    Button(action: {
                        selectedSection = .rankings
                    }) {
                        Text("View")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
                .padding(10)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }

            // Last updated
            if let lastRefresh = viewModel.lastRefreshDate {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                    Text("Updated \(lastRefresh, style: .relative) ago")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
        .padding(.horizontal)
        .padding(.top)
    }

    private func kpiRow(benchmarks: CohortBenchmarks) -> some View {
        HStack(spacing: 16) {
            kpiItem(
                title: "Avg Adherence",
                value: benchmarks.formattedAdherence,
                icon: "checkmark.circle",
                color: benchmarks.averageAdherence >= 70 ? .green : .orange
            )

            Divider()
                .frame(height: 40)

            kpiItem(
                title: "Pain Reduction",
                value: benchmarks.formattedPainReduction,
                icon: "heart.circle",
                color: benchmarks.averagePainReduction >= 30 ? .green : .blue
            )

            Divider()
                .frame(height: 40)

            kpiItem(
                title: "Sessions/Wk",
                value: benchmarks.formattedSessionsPerWeek,
                icon: "calendar.circle",
                color: benchmarks.averageSessionsPerWeek >= 3 ? .green : .orange
            )
        }
    }

    private func kpiItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Section Selector

    private var sectionSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DashboardSection.allCases) { section in
                    sectionButton(section)
                }
            }
            .padding(.horizontal)
        }
    }

    private func sectionButton(_ section: DashboardSection) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSection = section
            }
            HapticFeedback.selectionChanged()
        }) {
            HStack(spacing: 6) {
                Image(systemName: section.icon)
                    .font(.caption)

                Text(section.rawValue)
                    .font(.subheadline)
                    .fontWeight(selectedSection == section ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selectedSection == section ? Color.blue : Color(.secondarySystemGroupedBackground))
            .foregroundColor(selectedSection == section ? .white : .primary)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Section Content

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .overview:
            overviewSection
        case .rankings:
            rankingsSection
        case .distribution:
            distributionSection
        case .retention:
            retentionSection
        case .programs:
            programsSection
        }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(spacing: 16) {
            // Top performers
            CompactRankingList(
                title: "Top Performers",
                icon: "star.fill",
                iconColor: .yellow,
                rankings: viewModel.topPerformers,
                onPatientTap: { entry in
                    handlePatientTap(entry)
                },
                onViewAll: {
                    selectedSection = .rankings
                }
            )
            .padding(.horizontal)

            // Needs attention
            CompactRankingList(
                title: "Needs Attention",
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange,
                rankings: viewModel.patientsNeedingAttention,
                onPatientTap: { entry in
                    handlePatientTap(entry)
                },
                onViewAll: {
                    selectedSection = .rankings
                }
            )
            .padding(.horizontal)

            // Quick comparison cards (if patient selected)
            if let comparison = viewModel.selectedPatientComparison,
               let benchmarks = viewModel.benchmarks {
                ComparisonSummaryCard(
                    comparison: comparison,
                    benchmarks: benchmarks,
                    onViewDetails: {
                        showPatientDetail = true
                    }
                )
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Rankings Section

    private var rankingsSection: some View {
        VStack(spacing: 16) {
            // Sort controls
            HStack {
                Text("Sort by:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Menu {
                    ForEach(CohortAnalyticsService.PatientRankingSortKey.allCases, id: \.self) { key in
                        Button(action: {
                            Task {
                                if let therapistId = appState.userId {
                                    await viewModel.updateSort(sortKey: key, therapistId: therapistId)
                                }
                            }
                        }) {
                            HStack {
                                Text(key.displayName)
                                if viewModel.rankingSortKey == key {
                                    Image(systemName: viewModel.rankingSortAscending ? "chevron.up" : "chevron.down")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.rankingSortKey.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Image(systemName: viewModel.rankingSortAscending ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            // Rankings table
            PatientRankingTable(
                rankings: viewModel.filteredRankings,
                sortKey: viewModel.rankingSortKey,
                sortAscending: viewModel.rankingSortAscending,
                onSortChange: { key in
                    Task {
                        if let therapistId = appState.userId {
                            await viewModel.updateSort(sortKey: key, therapistId: therapistId)
                        }
                    }
                },
                onPatientTap: { entry in
                    handlePatientTap(entry)
                }
            )
            .padding(.horizontal)
        }
        .searchable(text: $viewModel.searchText, prompt: "Search patients")
    }

    // MARK: - Distribution Section

    private var distributionSection: some View {
        VStack(spacing: 16) {
            if let distribution = viewModel.complianceDistribution {
                // Stats summary
                HStack(spacing: 24) {
                    statItem(title: "Average", value: String(format: "%.0f%%", distribution.averageAdherence))
                    statItem(title: "Median", value: String(format: "%.0f%%", distribution.medianAdherence))
                    statItem(title: "Std Dev", value: String(format: "%.1f", distribution.standardDeviation))
                }
                .padding(.horizontal)

                // Histogram chart
                complianceHistogramChart(distribution: distribution)
                    .padding(.horizontal)
            } else if viewModel.isLoadingDistribution {
                ProgressView("Loading distribution...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                emptyDataView(message: "No compliance data available")
            }
        }
    }

    @ViewBuilder
    private func complianceHistogramChart(distribution: ComplianceDistribution) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Adherence Distribution")
                .font(.headline)

            if #available(iOS 16.0, *) {
                Chart(distribution.buckets) { bucket in
                    BarMark(
                        x: .value("Range", bucket.label),
                        y: .value("Patients", bucket.patientCount)
                    )
                    .foregroundStyle(barColor(for: bucket.rangeStart))
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartXAxisLabel("Adherence Range")
                .chartYAxisLabel("Patients")
            } else {
                // Fallback for older iOS versions
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(distribution.buckets) { bucket in
                        VStack(spacing: 4) {
                            Text("\(bucket.patientCount)")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Rectangle()
                                .fill(barColor(for: bucket.rangeStart))
                                .frame(
                                    width: 40,
                                    height: max(20, CGFloat(bucket.patientCount) / CGFloat(distribution.totalPatients) * 150)
                                )
                                .cornerRadius(4)

                            Text(bucket.label)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
    }

    private func barColor(for rangeStart: Int) -> Color {
        switch rangeStart {
        case 80...: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Retention Section

    private var retentionSection: some View {
        VStack(spacing: 16) {
            if let retention = viewModel.retentionData {
                // Summary stats
                HStack(spacing: 16) {
                    retentionStatCard(
                        title: "Retention Rate",
                        value: retention.formattedRetentionRate,
                        icon: "person.3.fill",
                        color: retention.overallRetentionRate >= 70 ? .green : .orange
                    )

                    retentionStatCard(
                        title: "Completed",
                        value: "\(retention.completedPatients)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )

                    retentionStatCard(
                        title: "Dropped",
                        value: "\(retention.droppedPatients)",
                        icon: "xmark.circle.fill",
                        color: .red
                    )
                }
                .padding(.horizontal)

                // Retention curve chart
                retentionCurveChart(retention: retention)
                    .padding(.horizontal)
            } else if viewModel.isLoadingRetention {
                ProgressView("Loading retention data...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                emptyDataView(message: "No retention data available")
            }
        }
    }

    private func retentionStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    @ViewBuilder
    private func retentionCurveChart(retention: RetentionData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Retention Curve")
                .font(.headline)

            if #available(iOS 16.0, *) {
                Chart(retention.weeklyData) { point in
                    LineMark(
                        x: .value("Week", point.weekNumber),
                        y: .value("Retention", point.retentionRate)
                    )
                    .foregroundStyle(Color.blue)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Week", point.weekNumber),
                        y: .value("Retention", point.retentionRate)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .chartXAxisLabel("Week")
                .chartYAxisLabel("Retention %")
                .chartYScale(domain: 0...100)
            } else {
                // Fallback visualization
                GeometryReader { geometry in
                    Path { path in
                        let points = retention.weeklyData
                        guard points.count > 1 else { return }

                        let xStep = geometry.size.width / CGFloat(points.count - 1)
                        let yScale = geometry.size.height / 100

                        path.move(to: CGPoint(
                            x: 0,
                            y: geometry.size.height - CGFloat(points[0].retentionRate) * yScale
                        ))

                        for (index, point) in points.enumerated() {
                            path.addLine(to: CGPoint(
                                x: CGFloat(index) * xStep,
                                y: geometry.size.height - CGFloat(point.retentionRate) * yScale
                            ))
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2)
                }
                .frame(height: 200)
            }

            if let avgDropOff = retention.averageDropOffWeek {
                Text("Average drop-off: Week \(String(format: "%.1f", avgDropOff))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
    }

    // MARK: - Programs Section

    private var programsSection: some View {
        VStack(spacing: 16) {
            if let outcomes = viewModel.programOutcomes, !outcomes.programs.isEmpty {
                ForEach(outcomes.programs) { program in
                    programOutcomeCard(program: program)
                }
            } else if viewModel.isLoadingPrograms {
                ProgressView("Loading program data...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                emptyDataView(message: "No program outcome data available")
            }
        }
        .padding(.horizontal)
    }

    private func programOutcomeCard(program: ProgramOutcomeSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(program.programName)
                        .font(.headline)

                    Text(program.programType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Rating badge
                HStack(spacing: 4) {
                    Image(systemName: program.outcomeRating.iconName)
                        .font(.caption)

                    Text(program.outcomeRating.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ratingColor(program.outcomeRating).opacity(0.15))
                .foregroundColor(ratingColor(program.outcomeRating))
                .cornerRadius(CornerRadius.sm)
            }

            // Metrics
            HStack(spacing: 16) {
                programMetric(title: "Enrolled", value: "\(program.enrolledPatients)", icon: "person.3")
                programMetric(title: "Completion", value: program.formattedCompletionRate, icon: "checkmark.circle")
                programMetric(title: "Adherence", value: program.formattedAdherence, icon: "chart.line.uptrend.xyaxis")
            }

            // Completion bar
            VStack(alignment: .leading, spacing: 4) {
                Text("Completion Rate")
                    .font(.caption)
                    .foregroundColor(.secondary)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(ratingColor(program.outcomeRating))
                            .frame(width: geometry.size.width * min(program.completionRate / 100, 1.0))
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
    }

    private func programMetric(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func ratingColor(_ rating: ProgramOutcomeSummary.OutcomeRating) -> Color {
        switch rating {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .needsImprovement: return .red
        }
    }

    // MARK: - Helper Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading analytics...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Load")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task { await loadData() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.md)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func emptyDataView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var refreshButton: some View {
        Button {
            Task { await refreshData() }
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(viewModel.isLoading)
    }

    // MARK: - Actions

    private func loadData() async {
        guard let therapistId = appState.userId else {
            viewModel.errorMessage = "Unable to verify your account. Please sign in again."
            return
        }
        await viewModel.loadAllData(therapistId: therapistId)
    }

    private func refreshData() async {
        guard let therapistId = appState.userId else { return }
        await viewModel.refresh(therapistId: therapistId)
    }

    private func handlePatientTap(_ entry: PatientRankingEntry) {
        Task {
            await viewModel.loadPatientComparison(patientId: entry.patientId.uuidString)
            showPatientDetail = true
        }
    }
}

// MARK: - Patient Comparison Detail Sheet

struct PatientComparisonDetailSheet: View {
    let comparison: PatientComparison
    let benchmarks: CohortBenchmarks
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(comparison.patientName)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 8) {
                            Image(systemName: comparison.comparisonStatus.iconName)
                            Text(comparison.comparisonStatus.displayName)
                        }
                        .font(.subheadline)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(statusColor.opacity(0.15))
                        .cornerRadius(CornerRadius.md)
                    }
                    .padding(.top)

                    // Overall percentile gauge
                    overallPercentileGauge

                    // Metric comparison cards
                    VStack(spacing: 12) {
                        CohortComparisonCard(
                            patientName: comparison.patientName,
                            patientValue: comparison.adherence,
                            cohortAverage: benchmarks.averageAdherence,
                            percentile: comparison.adherencePercentile,
                            metricName: "Adherence Rate",
                            unit: "%",
                            onTap: {}
                        )

                        CohortComparisonCard(
                            patientName: comparison.patientName,
                            patientValue: comparison.painReduction,
                            cohortAverage: benchmarks.averagePainReduction,
                            percentile: comparison.painReductionPercentile,
                            metricName: "Pain Reduction",
                            unit: "%",
                            onTap: {}
                        )

                        CohortComparisonCard(
                            patientName: comparison.patientName,
                            patientValue: comparison.strengthGains,
                            cohortAverage: benchmarks.averageStrengthGains,
                            percentile: comparison.strengthGainsPercentile,
                            metricName: "Strength Gains",
                            unit: "%",
                            onTap: {}
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Patient vs Cohort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }

    private var overallPercentileGauge: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(comparison.overallPercentile) / 100)
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(comparison.overallPercentile)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(statusColor)

                    Text("percentile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("Overall Rank: \(comparison.overallPercentile)th percentile")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var statusColor: Color {
        switch comparison.comparisonStatus {
        case .aboveAverage: return .green
        case .average: return .blue
        case .belowAverage: return .orange
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CohortAnalyticsDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        CohortAnalyticsDashboardView()
            .environmentObject(AppState())
    }
}
#endif
