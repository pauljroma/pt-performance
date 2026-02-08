//
//  ReportHistoryView.swift
//  PTPerformance
//
//  M7 - PT Weekly Report System
//  Historical weekly report listing and comparison
//

import SwiftUI

// MARK: - Report History View

/// View for browsing and comparing historical weekly reports
struct ReportHistoryView: View {
    let patient: Patient

    @StateObject private var viewModel = ReportHistoryViewModel()
    @State private var selectedReport: WeeklyReport?
    @State private var showReportDetail = false
    @State private var showWeekPicker = false
    @State private var selectedWeekDate = Date()
    @State private var showCompareSheet = false
    @State private var compareReports: [WeeklyReport] = []
    @State private var showGenerateConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with actions
            headerSection

            // Content
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if viewModel.reports.isEmpty {
                emptyView
            } else {
                reportsList
            }
        }
        .navigationTitle("Weekly Reports")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showWeekPicker = true
                    } label: {
                        Label("Generate Report", systemImage: "plus.circle")
                    }

                    Button {
                        if compareReports.count >= 2 {
                            showCompareSheet = true
                        }
                    } label: {
                        Label("Compare Selected", systemImage: "arrow.left.arrow.right")
                    }
                    .disabled(compareReports.count < 2)

                    Divider()

                    Button {
                        Task {
                            await viewModel.refreshReports(patientId: patient.id)
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.loadReports(patientId: patient.id)
        }
        .refreshable {
            await viewModel.refreshReports(patientId: patient.id)
        }
        .sheet(isPresented: $showReportDetail) {
            if let report = selectedReport {
                NavigationView {
                    WeeklyReportView(report: report, patientName: patient.fullName)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") {
                                    showReportDetail = false
                                }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showWeekPicker) {
            weekPickerSheet
        }
        .sheet(isPresented: $showCompareSheet) {
            if compareReports.count >= 2 {
                NavigationView {
                    ReportComparisonView(
                        reports: Array(compareReports.prefix(2)),
                        patientName: patient.fullName
                    )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                showCompareSheet = false
                            }
                        }
                    }
                }
            }
        }
        .alert("Generate Report", isPresented: $showGenerateConfirmation) {
            Button("Generate") {
                generateReport()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Generate a weekly report for \(formattedWeek(selectedWeekDate))?")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            // Patient info
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(patient.initials)
                            .font(.headline)
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(patient.fullName)
                        .font(.headline)

                    if let injury = patient.injuryType {
                        Text(injury)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Report count
                VStack(alignment: .trailing) {
                    Text("\(viewModel.reports.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Reports")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading reports...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Load Reports")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.loadReports(patientId: patient.id)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Reports Yet")
                .font(.headline)

            Text("Generate the first weekly report for this patient")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showWeekPicker = true
            } label: {
                Label("Generate Report", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Reports List

    private var reportsList: some View {
        List {
            ForEach(viewModel.reports) { report in
                ReportHistoryRow(
                    report: report,
                    isSelected: compareReports.contains(where: { $0.id == report.id }),
                    onTap: {
                        selectedReport = report
                        showReportDetail = true
                    },
                    onToggleCompare: {
                        toggleCompareSelection(report)
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Week Picker Sheet

    private var weekPickerSheet: some View {
        NavigationView {
            VStack(spacing: Spacing.lg) {
                Text("Select Week")
                    .font(.headline)

                DatePicker(
                    "Week of",
                    selection: $selectedWeekDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()

                Text("Report will cover: \(formattedWeek(selectedWeekDate))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button {
                    showWeekPicker = false
                    showGenerateConfirmation = true
                } label: {
                    Text("Generate Report")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(CornerRadius.md)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Generate Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showWeekPicker = false
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleCompareSelection(_ report: WeeklyReport) {
        if let index = compareReports.firstIndex(where: { $0.id == report.id }) {
            compareReports.remove(at: index)
        } else if compareReports.count < 2 {
            compareReports.append(report)
        } else {
            // Replace the oldest selection
            compareReports.removeFirst()
            compareReports.append(report)
        }
    }

    private func generateReport() {
        Task {
            do {
                let report = try await WeeklyReportService.shared.generateReport(
                    patientId: patient.id,
                    weekOf: selectedWeekDate
                )
                await MainActor.run {
                    viewModel.reports.insert(report, at: 0)
                    selectedReport = report
                    showReportDetail = true
                }
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func formattedWeek(_ date: Date) -> String {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? date

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
    }
}

// MARK: - Report History Row

struct ReportHistoryRow: View {
    let report: WeeklyReport
    let isSelected: Bool
    let onTap: () -> Void
    let onToggleCompare: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Selection indicator for compare
            Button {
                onToggleCompare()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .buttonStyle(.plain)

            // Report info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(report.dateRangeString)
                    .font(.headline)

                Text("Week \(report.weekNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status indicator
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: report.overallStatus.icon)
                        .font(.caption)
                        .foregroundColor(report.overallStatus.color)

                    Text(report.completionRateDisplay)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Text(report.overallStatus.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Report for \(report.dateRangeString), \(report.overallStatus.displayName)")
        .accessibilityHint("Double tap to view details")
    }
}

// MARK: - Report History View Model

@MainActor
class ReportHistoryViewModel: ObservableObject {
    @Published var reports: [WeeklyReport] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadReports(patientId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            reports = try await WeeklyReportService.shared.fetchReports(patientId: patientId, limit: 24)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func refreshReports(patientId: UUID) async {
        WeeklyReportService.shared.clearCache(patientId: patientId)
        await loadReports(patientId: patientId)
    }
}

// MARK: - Report Comparison View

struct ReportComparisonView: View {
    let reports: [WeeklyReport]
    let patientName: String

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header
                Text("Report Comparison")
                    .font(.title2)
                    .bold()

                Text(patientName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Date comparison
                HStack {
                    ForEach(reports.indices, id: \.self) { index in
                        VStack {
                            Text("Week \(index + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(reports[index].dateRangeString)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)

                        if index < reports.count - 1 {
                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)

                // Metrics comparison
                comparisonSection(
                    title: "Session Completion",
                    values: reports.map { $0.completionRateDisplay },
                    trend: calculateTrend(values: reports.map { $0.sessionCompletionRate })
                )

                comparisonSection(
                    title: "Adherence",
                    values: reports.map { $0.adherenceDisplay },
                    trend: calculateTrend(values: reports.map { $0.adherenceScore })
                )

                if let firstPain = reports.first?.averagePainLevel,
                   let lastPain = reports.last?.averagePainLevel {
                    comparisonSection(
                        title: "Average Pain",
                        values: reports.map { $0.averagePainLevel.map { String(format: "%.1f", $0) } ?? "N/A" },
                        trend: calculatePainTrend(first: firstPain, last: lastPain)
                    )
                }

                if let firstRecovery = reports.first?.averageRecoveryScore,
                   let lastRecovery = reports.last?.averageRecoveryScore {
                    comparisonSection(
                        title: "Recovery Score",
                        values: reports.map { $0.averageRecoveryScore.map { String(format: "%.0f", $0) } ?? "N/A" },
                        trend: calculateTrend(values: [firstRecovery, lastRecovery])
                    )
                }

                // Goals comparison
                comparisonSection(
                    title: "Goals Completion",
                    values: reports.map { String(format: "%.0f%%", $0.goalsCompletionPercentage) },
                    trend: calculateTrend(values: reports.map { $0.goalsCompletionPercentage })
                )

                // AI Adoption
                comparisonSection(
                    title: "AI Adoption",
                    values: reports.map { String(format: "%.0f%%", $0.aiAdoptionRate) },
                    trend: calculateTrend(values: reports.map { $0.aiAdoptionRate })
                )
            }
            .padding()
        }
        .navigationTitle("Compare Reports")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func comparisonSection(title: String, values: [String], trend: TrendDirection?) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.headline)

            HStack {
                ForEach(values.indices, id: \.self) { index in
                    VStack {
                        Text(values[index])
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)

                    if index < values.count - 1 {
                        if let trend = trend {
                            Image(systemName: trend.iconName)
                                .foregroundColor(trend.color)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    private func calculateTrend(values: [Double]) -> TrendDirection? {
        guard values.count >= 2,
              let first = values.first,
              let last = values.last else { return nil }

        let change = last - first
        if change > 0.05 { return .improving }
        if change < -0.05 { return .declining }
        return .stable
    }

    private func calculatePainTrend(first: Double, last: Double) -> TrendDirection {
        // For pain, lower is better
        let change = last - first
        if change < -0.5 { return .improving }
        if change > 0.5 { return .declining }
        return .stable
    }
}

// MARK: - Preview

#if DEBUG
struct ReportHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReportHistoryView(patient: Patient.samplePatients[0])
        }
    }
}
#endif
