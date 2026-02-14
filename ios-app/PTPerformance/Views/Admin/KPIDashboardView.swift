//
//  KPIDashboardView.swift
//  PTPerformance
//
//  KPI Dashboard View for X2Index
//  M10: KPI dashboard tracks PT prep time, WAU, adherence, citation coverage, latency, safety events
//
//  North Star Guardrails:
//  - PT weekly active usage >= 65%
//  - Athlete weekly active usage >= 60%
//  - Citation coverage for AI claims >= 95%
//  - p95 summary latency <= 5s
//  - Unresolved high-severity safety incidents = 0
//
//  Features:
//  - Trend charts for each metric
//  - Time period selector (7d, 30d, 90d)
//  - Export functionality
//  - Auto-refresh indicator
//  - Pull-to-refresh
//

import SwiftUI
import Charts

// MARK: - KPI Dashboard View

struct KPIDashboardView: View {
    @StateObject private var viewModel = KPIDashboardViewModel()
    @StateObject private var kpiService = KPITrackingService.shared
    @State private var selectedPeriod: DateRangePeriod = .lastWeek
    @State private var showingExport = false
    @State private var selectedIncident: SafetyIncident?
    @State private var showTrendCharts = true
    @State private var autoRefreshEnabled = true
    @State private var refreshCountdown: Int = 60

    // Timer for auto-refresh countdown
    private let refreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Period Selector and Controls
                    controlsSection

                    // Auto-refresh indicator
                    if autoRefreshEnabled {
                        autoRefreshIndicator
                    }

                    if viewModel.isLoading && viewModel.dashboard == nil {
                        ProgressView("Loading KPI Dashboard...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let dashboard = viewModel.dashboard {
                        // Overview Status
                        overviewStatusCard(dashboard: dashboard)

                        // Trend Charts Section (collapsible)
                        if showTrendCharts {
                            trendChartsSection
                        }

                        // PT Metrics Section
                        ptMetricsSection(dashboard: dashboard)

                        // Athlete Metrics Section
                        athleteMetricsSection(dashboard: dashboard)

                        // AI Metrics Section
                        aiMetricsSection(dashboard: dashboard)

                        // Safety Section
                        safetySection(dashboard: dashboard)

                        // Safety Incidents List
                        if !viewModel.openIncidents.isEmpty {
                            safetyIncidentsSection
                        }

                        // Last updated timestamp
                        lastUpdatedFooter
                    } else if let error = viewModel.lastError {
                        errorView(error: error)
                    }
                }
                .padding()
            }
            .navigationTitle("KPI Dashboard")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    // Toggle trend charts
                    Button {
                        withAnimation {
                            showTrendCharts.toggle()
                        }
                    } label: {
                        Image(systemName: showTrendCharts ? "chart.line.uptrend.xyaxis" : "chart.line.uptrend.xyaxis.circle")
                    }
                    .accessibilityLabel(showTrendCharts ? "Hide Charts" : "Show Charts")

                    // Export
                    Button {
                        showingExport = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }

                    // Manual refresh
                    Button {
                        Task {
                            await viewModel.refresh()
                            refreshCountdown = 60
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }

                ToolbarItem(placement: .topBarLeading) {
                    // Auto-refresh toggle
                    Button {
                        autoRefreshEnabled.toggle()
                        if autoRefreshEnabled {
                            kpiService.startAutoRefresh(intervalSeconds: 60)
                            refreshCountdown = 60
                        } else {
                            kpiService.stopAutoRefresh()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: autoRefreshEnabled ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.triangle.2.circlepath.circle")
                            if autoRefreshEnabled {
                                Text("Auto")
                                    .font(.caption)
                            }
                        }
                    }
                    .tint(autoRefreshEnabled ? .green : .secondary)
                }
            }
            .refreshable {
                await viewModel.refresh()
                refreshCountdown = 60
            }
            .task {
                await viewModel.loadDashboard(period: selectedPeriod)
                if autoRefreshEnabled {
                    kpiService.startAutoRefresh(intervalSeconds: 60)
                }
            }
            .onChange(of: selectedPeriod) { _, newPeriod in
                Task {
                    await viewModel.loadDashboard(period: newPeriod)
                }
            }
            .onReceive(refreshTimer) { _ in
                if autoRefreshEnabled && refreshCountdown > 0 {
                    refreshCountdown -= 1
                }
                if refreshCountdown == 0 {
                    refreshCountdown = 60
                }
            }
            .onDisappear {
                kpiService.stopAutoRefresh()
            }
            .sheet(item: $selectedIncident) { incident in
                SafetyIncidentDetailSheet(incident: incident, onDismiss: {
                    Task {
                        await viewModel.refresh()
                    }
                })
            }
            .sheet(isPresented: $showingExport) {
                KPIExportSheet(dashboard: viewModel.dashboard, viewModel: viewModel)
            }
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(spacing: 12) {
            periodSelector

            // View options
            HStack {
                Picker("Display", selection: $showTrendCharts) {
                    Text("Summary").tag(false)
                    Text("With Trends").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)

                Spacer()
            }
        }
    }

    // MARK: - Auto-Refresh Indicator

    private var autoRefreshIndicator: some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.7)
                .opacity(viewModel.isLoading ? 1 : 0)

            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.caption2)
                .foregroundColor(.green)

            Text("Auto-refresh in \(refreshCountdown)s")
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()

            if let lastRefresh = kpiService.lastRefreshTime {
                Text("Last: \(lastRefresh.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Trend Charts Section

    private var trendChartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Trend Analysis", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)

                Spacer()

                Text(selectedPeriod.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.sm)
            }

            // PT WAU Trend
            PercentageTrendChart(
                title: "PT Weekly Active Usage",
                data: kpiService.ptWauTrendData,
                targetPercentage: KPITargets.ptWauTarget,
                trendColor: .blue
            )

            // Athlete WAU Trend
            PercentageTrendChart(
                title: "Athlete Weekly Active Usage",
                data: kpiService.athleteWauTrendData,
                targetPercentage: KPITargets.athleteWauTarget,
                trendColor: .purple
            )

            // Citation Coverage Trend
            PercentageTrendChart(
                title: "Citation Coverage",
                data: kpiService.citationTrendData,
                targetPercentage: KPITargets.citationCoverageTarget,
                trendColor: .green
            )

            // Latency Trend
            LatencyTrendChart(
                title: "p95 Latency",
                data: kpiService.latencyTrendData,
                targetMs: KPITargets.p95LatencyTargetMs
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Last Updated Footer

    private var lastUpdatedFooter: some View {
        HStack {
            Spacer()

            if let dashboard = viewModel.dashboard {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Period: \(formatDate(dashboard.periodStart)) - \(formatDate(dashboard.periodEnd))")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let lastRefresh = kpiService.lastRefreshTime {
                        Text("Updated: \(lastRefresh.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.top, Spacing.xs)
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()

    private func formatDate(_ date: Date) -> String {
        Self.shortDateFormatter.string(from: date)
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(DateRangePeriod.allCases, id: \.self) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Overview Status Card

    private func overviewStatusCard(dashboard: KPIDashboard) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("System Health")
                    .font(.headline)
                Spacer()
                overallStatusBadge(dashboard: dashboard)
            }

            HStack(spacing: 16) {
                statusIndicator(
                    title: "PT WAU",
                    status: dashboard.ptMetrics.status,
                    value: "\(Int(dashboard.ptMetrics.wauPercentage * 100))%",
                    target: "\(Int(KPITargets.ptWauTarget * 100))%"
                )

                statusIndicator(
                    title: "Athlete WAU",
                    status: dashboard.athleteMetrics.status,
                    value: "\(Int(dashboard.athleteMetrics.wauPercentage * 100))%",
                    target: "\(Int(KPITargets.athleteWauTarget * 100))%"
                )

                statusIndicator(
                    title: "Citations",
                    status: dashboard.aiMetrics.citationStatus,
                    value: "\(Int(dashboard.aiMetrics.citationCoverage * 100))%",
                    target: "\(Int(KPITargets.citationCoverageTarget * 100))%"
                )

                statusIndicator(
                    title: "Safety",
                    status: dashboard.safetyMetrics.status,
                    value: "\(dashboard.safetyMetrics.unresolvedHighSeverity)",
                    target: "0"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func overallStatusBadge(dashboard: KPIDashboard) -> some View {
        let allOnTarget = dashboard.ptMetrics.meetsTarget &&
                          dashboard.athleteMetrics.meetsTarget &&
                          dashboard.aiMetrics.citationMeetsTarget &&
                          dashboard.aiMetrics.latencyMeetsTarget &&
                          dashboard.safetyMetrics.meetsTarget

        let hasCritical = !dashboard.safetyMetrics.meetsTarget ||
                          dashboard.ptMetrics.status == .critical ||
                          dashboard.athleteMetrics.status == .critical

        let status: KPIStatus = allOnTarget ? .onTarget : (hasCritical ? .critical : .warning)

        return HStack(spacing: 4) {
            Image(systemName: status.iconName)
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(statusColor(status))
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 6)
        .background(statusColor(status).opacity(0.15))
        .cornerRadius(CornerRadius.sm)
    }

    private func statusIndicator(title: String, status: KPIStatus, value: String, target: String) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(statusColor(status))
                .frame(width: 12, height: 12)

            Text(value)
                .font(.headline)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("(\(target))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - PT Metrics Section

    private func ptMetricsSection(dashboard: KPIDashboard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "PT Engagement", icon: "person.2.fill", status: dashboard.ptMetrics.status)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                metricCard(
                    title: "Weekly Active",
                    value: "\(dashboard.ptMetrics.weeklyActivePTs)/\(dashboard.ptMetrics.totalPTs)",
                    subtitle: "\(Int(dashboard.ptMetrics.wauPercentage * 100))% WAU",
                    status: dashboard.ptMetrics.status,
                    trend: viewModel.ptWauTrend
                )

                metricCard(
                    title: "Avg Prep Time",
                    value: formatDuration(seconds: dashboard.ptMetrics.avgPrepTimeSeconds),
                    subtitle: "per athlete",
                    status: .onTarget,
                    trend: nil
                )

                metricCard(
                    title: "Briefs Opened",
                    value: "\(dashboard.ptMetrics.briefsOpened)",
                    subtitle: "this period",
                    status: .onTarget,
                    trend: nil
                )

                metricCard(
                    title: "Plans Assigned",
                    value: "\(dashboard.ptMetrics.plansAssigned)",
                    subtitle: "this period",
                    status: .onTarget,
                    trend: nil
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Athlete Metrics Section

    private func athleteMetricsSection(dashboard: KPIDashboard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Athlete Engagement", icon: "figure.run", status: dashboard.athleteMetrics.status)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                metricCard(
                    title: "Weekly Active",
                    value: "\(dashboard.athleteMetrics.weeklyActiveAthletes)/\(dashboard.athleteMetrics.totalAthletes)",
                    subtitle: "\(Int(dashboard.athleteMetrics.wauPercentage * 100))% WAU",
                    status: dashboard.athleteMetrics.status,
                    trend: viewModel.athleteWauTrend
                )

                metricCard(
                    title: "Check-ins",
                    value: "\(dashboard.athleteMetrics.checkInsCompleted)",
                    subtitle: "completed",
                    status: .onTarget,
                    trend: nil
                )

                metricCard(
                    title: "Task Completion",
                    value: "\(Int(dashboard.athleteMetrics.taskCompletionRate * 100))%",
                    subtitle: "adherence rate",
                    status: dashboard.athleteMetrics.taskCompletionRate >= 0.7 ? .onTarget : .warning,
                    trend: nil
                )

                metricCard(
                    title: "Avg Streak",
                    value: String(format: "%.1f", dashboard.athleteMetrics.avgStreakDays),
                    subtitle: "days",
                    status: .onTarget,
                    trend: nil
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - AI Metrics Section

    private func aiMetricsSection(dashboard: KPIDashboard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            let aiStatus = dashboard.aiMetrics.citationStatus == .critical || dashboard.aiMetrics.latencyStatus == .critical
                ? KPIStatus.critical
                : (dashboard.aiMetrics.citationStatus == .warning || dashboard.aiMetrics.latencyStatus == .warning ? .warning : .onTarget)

            sectionHeader(title: "AI Performance", icon: "cpu", status: aiStatus)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                metricCard(
                    title: "Citation Coverage",
                    value: "\(Int(dashboard.aiMetrics.citationCoverage * 100))%",
                    subtitle: "target: \(Int(KPITargets.citationCoverageTarget * 100))%",
                    status: dashboard.aiMetrics.citationStatus,
                    trend: viewModel.citationTrend
                )

                metricCard(
                    title: "p95 Latency",
                    value: formatLatency(ms: dashboard.aiMetrics.p95LatencyMs),
                    subtitle: "target: \(KPITargets.p95LatencyTargetMs / 1000)s",
                    status: dashboard.aiMetrics.latencyStatus,
                    trend: viewModel.latencyTrend
                )

                metricCard(
                    title: "Claims Generated",
                    value: "\(dashboard.aiMetrics.claimsGenerated)",
                    subtitle: "this period",
                    status: .onTarget,
                    trend: nil
                )

                metricCard(
                    title: "Avg Confidence",
                    value: "\(Int(dashboard.aiMetrics.avgConfidence * 100))%",
                    subtitle: "\(dashboard.aiMetrics.abstentions) abstentions",
                    status: dashboard.aiMetrics.avgConfidence >= 0.7 ? .onTarget : .warning,
                    trend: nil
                )
            }

            // Abstention and uncertainty info
            if dashboard.aiMetrics.abstentions > 0 || dashboard.aiMetrics.uncertaintyFlags > 0 {
                HStack(spacing: 16) {
                    Label("\(dashboard.aiMetrics.abstentions) abstentions", systemImage: "hand.raised.fill")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Label("\(dashboard.aiMetrics.uncertaintyFlags) uncertainty flags", systemImage: "questionmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                .padding(.top, Spacing.xxs)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Safety Section

    private func safetySection(dashboard: KPIDashboard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Safety", icon: "shield.fill", status: dashboard.safetyMetrics.status)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                metricCard(
                    title: "Unresolved High",
                    value: "\(dashboard.safetyMetrics.unresolvedHighSeverity)",
                    subtitle: "target: 0",
                    status: dashboard.safetyMetrics.status,
                    trend: nil,
                    highlight: dashboard.safetyMetrics.unresolvedHighSeverity > 0
                )

                metricCard(
                    title: "Total Incidents",
                    value: "\(dashboard.safetyMetrics.totalIncidents)",
                    subtitle: "this period",
                    status: .onTarget,
                    trend: nil
                )

                metricCard(
                    title: "Escalations",
                    value: "\(dashboard.safetyMetrics.escalationsTriggered)",
                    subtitle: "triggered",
                    status: .onTarget,
                    trend: nil
                )

                metricCard(
                    title: "Threshold Breaches",
                    value: "\(dashboard.safetyMetrics.thresholdBreaches)",
                    subtitle: "detected",
                    status: dashboard.safetyMetrics.thresholdBreaches > 20 ? .warning : .onTarget,
                    trend: nil
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Safety Incidents Section

    private var safetyIncidentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Open Incidents", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundColor(.red)

                Spacer()

                Text("\(viewModel.openIncidents.count)")
                    .font(.headline)
                    .foregroundColor(.red)
            }

            ForEach(viewModel.openIncidents) { incident in
                SafetyIncidentRow(incident: incident) {
                    selectedIncident = incident
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Helper Views

    private func sectionHeader(title: String, icon: String, status: KPIStatus) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.headline)

            Spacer()

            Image(systemName: status.iconName)
                .foregroundColor(statusColor(status))
        }
    }

    private func metricCard(
        title: String,
        value: String,
        subtitle: String,
        status: KPIStatus,
        trend: KPITrend?,
        highlight: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if let trend = trend {
                    Image(systemName: trend.iconName)
                        .font(.caption2)
                        .foregroundColor(trend == .up ? .green : (trend == .down ? .red : .gray))
                }
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(highlight ? .red : .primary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(statusColor(status).opacity(0.1))
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(statusColor(status).opacity(0.3), lineWidth: 1)
        )
    }

    private func errorView(error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text("Error Loading Dashboard")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task {
                    await viewModel.refresh()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Helpers

    private func statusColor(_ status: KPIStatus) -> Color {
        switch status {
        case .onTarget: return .green
        case .warning: return .yellow
        case .critical: return .red
        }
    }

    private func formatDuration(seconds: Double) -> String {
        if seconds < 60 {
            return "\(Int(seconds))s"
        } else {
            let minutes = Int(seconds / 60)
            let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(secs)s"
        }
    }

    private func formatLatency(ms: Int) -> String {
        if ms < 1000 {
            return "\(ms)ms"
        } else {
            return String(format: "%.1fs", Double(ms) / 1000)
        }
    }
}

// MARK: - Date Range Period

enum DateRangePeriod: String, CaseIterable {
    case today = "today"
    case lastWeek = "last_week"
    case lastMonth = "last_month"
    case lastQuarter = "last_quarter"

    var displayName: String {
        switch self {
        case .today: return "Today"
        case .lastWeek: return "Week"
        case .lastMonth: return "Month"
        case .lastQuarter: return "Quarter"
        }
    }

    var days: Int {
        switch self {
        case .today: return 1
        case .lastWeek: return 7
        case .lastMonth: return 30
        case .lastQuarter: return 90
        }
    }
}

// MARK: - KPI Export Sheet

struct KPIExportSheet: View {
    let dashboard: KPIDashboard?
    let viewModel: KPIDashboardViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: ExportFormat = .text
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportedContent: String = ""

    enum ExportFormat: String, CaseIterable {
        case text = "Text"
        case json = "JSON"
        case csv = "CSV"

        var icon: String {
            switch self {
            case .text: return "doc.text"
            case .json: return "curlybraces"
            case .csv: return "tablecells"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "doc.text")
                    .font(.system(size: 60))
                    .foregroundColor(.modusCyan)

                Text("Export KPI Report")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Generate a shareable KPI report for the current period.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                // Format selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Export Format")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Label(format.rawValue, systemImage: format.icon)
                                .tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)

                // Preview
                if let dashboard = dashboard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Report Preview")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        ScrollView {
                            Text(generatePreview())
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Spacing.sm)
                                .background(Color(.tertiarySystemGroupedBackground))
                                .cornerRadius(CornerRadius.sm)
                        }
                        .frame(height: 200)
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    Button {
                        copyToClipboard()
                    } label: {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(dashboard == nil)

                    Button {
                        shareReport()
                    } label: {
                        Label("Share Report", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(dashboard == nil || isExporting)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if !exportedContent.isEmpty {
                    ShareSheet(items: [exportedContent])
                }
            }
        }
    }

    private func generatePreview() -> String {
        switch exportFormat {
        case .text:
            return viewModel.generateTextSummary()
        case .json:
            return generateJSONPreview()
        case .csv:
            return generateCSVPreview()
        }
    }

    private func generateJSONPreview() -> String {
        guard let data = viewModel.generateExportData() else {
            return "{}"
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            // Truncate for preview
            if jsonString.count > 500 {
                return String(jsonString.prefix(500)) + "\n..."
            }
            return jsonString
        }
        return "{}"
    }

    private func generateCSVPreview() -> String {
        guard let dashboard = dashboard else { return "" }

        var lines: [String] = []
        lines.append("Metric,Value,Target,Status")
        lines.append("PT WAU,\(Int(dashboard.ptMetrics.wauPercentage * 100))%,65%,\(dashboard.ptMetrics.status.rawValue)")
        lines.append("Athlete WAU,\(Int(dashboard.athleteMetrics.wauPercentage * 100))%,60%,\(dashboard.athleteMetrics.status.rawValue)")
        lines.append("Citation Coverage,\(Int(dashboard.aiMetrics.citationCoverage * 100))%,95%,\(dashboard.aiMetrics.citationStatus.rawValue)")
        lines.append("p95 Latency,\(dashboard.aiMetrics.p95LatencyMs)ms,5000ms,\(dashboard.aiMetrics.latencyStatus.rawValue)")
        lines.append("Unresolved High Severity,\(dashboard.safetyMetrics.unresolvedHighSeverity),0,\(dashboard.safetyMetrics.status.rawValue)")

        return lines.joined(separator: "\n")
    }

    private func copyToClipboard() {
        let content = generateFullExport()
        UIPasteboard.general.string = content

        // Show feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func shareReport() {
        exportedContent = generateFullExport()
        showShareSheet = true
    }

    private func generateFullExport() -> String {
        switch exportFormat {
        case .text:
            return viewModel.generateTextSummary()
        case .json:
            guard let data = viewModel.generateExportData(),
                  let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .sortedKeys]),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                return "{}"
            }
            return jsonString
        case .csv:
            return generateCSVPreview()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct KPIDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        KPIDashboardView()
    }
}
#endif
