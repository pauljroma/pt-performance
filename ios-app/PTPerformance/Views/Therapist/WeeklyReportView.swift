// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  WeeklyReportView.swift
//  PTPerformance
//
//  M7 - PT Weekly Report System
//  In-app weekly report viewer for therapists
//

import SwiftUI

// MARK: - Weekly Report View

/// Detailed view for displaying a weekly patient report
struct WeeklyReportView: View {
    let report: WeeklyReport
    let patientName: String

    @StateObject private var viewModel = WeeklyReportViewModel()
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header
                reportHeader

                // Status Card
                statusCard

                // Key Metrics
                metricsSection

                // Goals Progress
                if !report.goalsProgress.isEmpty {
                    goalsSection
                }

                // AI Recommendations
                aiRecommendationsSection

                // Achievements
                if !report.achievements.isEmpty {
                    highlightSection(
                        title: "Achievements",
                        items: report.achievements,
                        icon: "star.fill",
                        color: .green
                    )
                }

                // Concerns
                if !report.concerns.isEmpty {
                    highlightSection(
                        title: "Concerns",
                        items: report.concerns,
                        icon: "exclamationmark.triangle.fill",
                        color: .orange
                    )
                }

                // Recommendations
                if !report.recommendations.isEmpty {
                    highlightSection(
                        title: "Recommendations",
                        items: report.recommendations,
                        icon: "lightbulb.fill",
                        color: .blue
                    )
                }

                // Export Button
                exportButton
            }
            .padding()
        }
        .navigationTitle("Weekly Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    exportReport()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Export Report")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                WeeklyReportShareSheet(items: [url])
            }
        }
        .overlay {
            if viewModel.isExporting {
                exportingOverlay
            }
        }
    }

    // MARK: - Report Header

    private var reportHeader: some View {
        VStack(spacing: Spacing.sm) {
            // Patient Avatar
            Circle()
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(patientName.prefix(2).uppercased())
                        .font(.title)
                        .foregroundColor(.white)
                )

            // Patient Name
            Text(patientName)
                .font(.title2)
                .bold()

            // Date Range
            Text("Week of \(report.dateRangeString)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Generated Date
            Text("Generated \(formattedDate(report.generatedAt))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly report for \(patientName), week of \(report.dateRangeString)")
    }

    // MARK: - Status Card

    private var statusCard: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: report.overallStatus.icon)
                .font(.title2)
                .foregroundColor(report.overallStatus.color)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(report.overallStatus.displayName)
                    .font(.headline)
                    .foregroundColor(report.overallStatus.color)

                Text("Based on session completion, adherence, and recovery metrics")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(report.overallStatus.color.opacity(0.1))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(report.overallStatus.color.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Overall status: \(report.overallStatus.displayName)")
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Key Metrics")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                // Session Completion
                ReportMetricCard(
                    title: "Sessions",
                    value: "\(report.totalSessionsCompleted)/\(report.totalSessionsScheduled)",
                    subtitle: report.completionRateDisplay,
                    trend: nil,
                    color: .blue
                )

                // Adherence
                ReportMetricCard(
                    title: "Adherence",
                    value: report.adherenceDisplay,
                    subtitle: "Compliance",
                    trend: nil,
                    color: .green
                )

                // Pain Level
                ReportMetricCard(
                    title: "Avg Pain",
                    value: report.averagePainLevel.map { String(format: "%.1f", $0) } ?? "N/A",
                    subtitle: report.painTrend.displayName,
                    trend: report.painTrend,
                    color: painColor
                )

                // Recovery
                ReportMetricCard(
                    title: "Recovery",
                    value: report.averageRecoveryScore.map { String(format: "%.0f", $0) } ?? "N/A",
                    subtitle: report.recoveryTrend.displayName,
                    trend: report.recoveryTrend,
                    color: recoveryColor
                )
            }
        }
    }

    private var painColor: Color {
        guard let pain = report.averagePainLevel else { return .gray }
        if pain <= 3 { return .green }
        if pain <= 6 { return .orange }
        return .red
    }

    private var recoveryColor: Color {
        guard let recovery = report.averageRecoveryScore else { return .gray }
        if recovery >= 75 { return .green }
        if recovery >= 50 { return .orange }
        return .red
    }

    // MARK: - Goals Section

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Goals Progress")
                    .font(.headline)

                Spacer()

                Text("\(report.goalsOnTrack)/\(report.goalsProgress.count) on track")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Goals Progress, \(report.goalsOnTrack) of \(report.goalsProgress.count) on track")

            VStack(spacing: Spacing.sm) {
                ForEach(report.goalsProgress) { goal in
                    GoalProgressRow(goal: goal)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - AI Recommendations Section

    private var aiRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("AI Recommendations")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: Spacing.sm) {
                HStack {
                    Image(systemName: "brain")
                        .font(.title3)
                        .foregroundColor(.purple)

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("\(report.aiRecommendationsAdopted) of \(report.aiRecommendationsTotal) adopted")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(String(format: "%.0f%% adoption rate", report.aiAdoptionRate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.tertiarySystemGroupedBackground))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.purple)
                            .frame(
                                width: geometry.size.width * CGFloat(report.aiAdoptionRate / 100),
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Highlight Section

    private func highlightSection(title: String, items: [String], icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Export Button

    private var exportButton: some View {
        Button {
            exportReport()
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Export PDF Report")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(CornerRadius.md)
        }
        .accessibilityLabel("Export PDF Report")
        .accessibilityHint("Generates and shares a PDF version of this report")
    }

    // MARK: - Exporting Overlay

    private var exportingOverlay: some View {
        ZStack {
            Color(.label).opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Generating PDF...")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(Spacing.xl)
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.lg)
        }
    }

    // MARK: - Actions

    private func exportReport() {
        Task {
            viewModel.isExporting = true

            do {
                let pdfData = try await WeeklyReportService.shared.exportToPDF(report, patientName: patientName)
                let url = try WeeklyReportService.shared.savePDFToTempFile(pdfData, report: report, patientName: patientName)

                await MainActor.run {
                    pdfURL = url
                    viewModel.isExporting = false
                    showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    viewModel.isExporting = false
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private static let mediumDateShortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Helpers

    private func formattedDate(_ date: Date) -> String {
        Self.mediumDateShortTimeFormatter.string(from: date)
    }
}

// MARK: - Goal Progress Row

struct GoalProgressRow: View {
    let goal: GoalProgress

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(goal.goalName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                HStack(spacing: Spacing.xxs) {
                    Image(systemName: goal.trend.iconName)
                        .font(.caption)
                        .foregroundColor(goal.trend.color)

                    Text(goal.percentDisplay)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(goal.statusColor)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(goal.statusColor)
                        .frame(
                            width: geometry.size.width * CGFloat(goal.progressFraction),
                            height: 6
                        )
                }
            }
            .frame(height: 6)

            HStack {
                Text("Current: \(String(format: "%.1f", goal.currentValue))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("Target: \(String(format: "%.1f", goal.targetValue))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goal.goalName), \(goal.percentDisplay) complete, trend \(goal.trend.displayName)")
    }
}

// MARK: - Share Sheet

private struct WeeklyReportShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#if DEBUG
struct WeeklyReportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WeeklyReportView(
                report: WeeklyReport.sample,
                patientName: "John Brebbia"
            )
        }
    }
}
#endif
