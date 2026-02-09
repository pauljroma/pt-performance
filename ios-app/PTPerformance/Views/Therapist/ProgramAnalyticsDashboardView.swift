//
//  ProgramAnalyticsDashboardView.swift
//  PTPerformance
//
//  Analytics dashboard for therapists to track program usage and patient progress
//  Shows program metrics, enrollment data, and completion rates
//

import SwiftUI

// MARK: - Program Analytics Dashboard View

struct ProgramAnalyticsDashboardView: View {
    @StateObject private var viewModel = ProgramAnalyticsViewModel()
    @EnvironmentObject var appState: AppState

    @State private var selectedProgram: ProgramAnalytics?
    @State private var showProgramDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.programs.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage, viewModel.programs.isEmpty {
                    errorView(error)
                } else if viewModel.programs.isEmpty {
                    emptyStateView
                } else {
                    mainContent
                }
            }
            .navigationTitle("Program Analytics")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshData()
            }
            .task {
                await loadData()
            }
            .sheet(item: $selectedProgram) { program in
                ProgramAnalyticsDetailSheet(program: program)
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary KPIs
                summarySection

                // Most Popular Programs
                popularProgramsSection

                // All Programs Performance
                allProgramsSection

                // Recent Enrollments
                recentEnrollmentsSection
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    AnalyticsKPICard(
                        icon: "doc.richtext.fill",
                        title: "Total Programs",
                        value: "\(viewModel.summary.totalPrograms)",
                        accentColor: .blue
                    )

                    AnalyticsKPICard(
                        icon: "person.2.fill",
                        title: "Total Enrollments",
                        value: "\(viewModel.summary.totalEnrollments)",
                        accentColor: .purple
                    )

                    AnalyticsKPICard(
                        icon: "play.circle.fill",
                        title: "Active",
                        value: "\(viewModel.summary.activeEnrollments)",
                        subtitle: "in progress",
                        accentColor: .green
                    )

                    AnalyticsKPICard(
                        icon: "checkmark.circle.fill",
                        title: "Completed",
                        value: "\(viewModel.summary.completedEnrollments)",
                        accentColor: .teal
                    )

                    AnalyticsKPICard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Avg Completion",
                        value: "\(Int(viewModel.summary.averageCompletionRate))%",
                        accentColor: completionRateColor(viewModel.summary.averageCompletionRate)
                    )
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Popular Programs Section

    private var popularProgramsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Most Popular Programs")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                if viewModel.programs.count > 5 {
                    Text("\(viewModel.programs.count) total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            if viewModel.topPrograms.isEmpty {
                Text("No programs with enrollments yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.topPrograms) { program in
                        PopularProgramCard(program: program)
                            .onTapGesture {
                                selectedProgram = program
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - All Programs Section

    private var allProgramsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Program Performance")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            LazyVStack(spacing: 8) {
                ForEach(viewModel.programs) { program in
                    ProgramPerformanceCard(program: program)
                        .onTapGesture {
                            selectedProgram = program
                        }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Recent Enrollments Section

    private var recentEnrollmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Enrollments")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            if viewModel.recentEnrollments.isEmpty {
                Text("No enrollments yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.recentEnrollments) { enrollment in
                        RecentEnrollmentCard(enrollment: enrollment)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Loading View

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

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Load Analytics")
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

    // MARK: - Empty State View

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Programs Yet", systemImage: "chart.bar.xaxis")
        } description: {
            Text("Create programs and publish them to the library to see analytics here.")
        } actions: {
            Button("Create Program") {
                // This would open the program builder
                // For now, just dismiss
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Helper Methods

    private func loadData() async {
        guard let therapistId = appState.userId else {
            viewModel.errorMessage = "Unable to verify your account. Please sign in again."
            return
        }
        await viewModel.loadAnalytics(therapistId: therapistId)
    }

    private func refreshData() async {
        guard let therapistId = appState.userId else { return }
        await viewModel.refresh(therapistId: therapistId)
    }

    private func completionRateColor(_ rate: Double) -> Color {
        switch rate {
        case 80...: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }
}

// MARK: - Analytics KPI Card

struct AnalyticsKPICard: View {
    let icon: String
    let title: String
    let value: String
    var subtitle: String? = nil
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(accentColor)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
        }
        .frame(width: 130)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
    }
}

// MARK: - Popular Program Card

struct PopularProgramCard: View {
    let program: ProgramAnalytics

    var body: some View {
        HStack(spacing: 12) {
            // Rank indicator
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Text("\(program.enrollmentCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(program.programName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label("\(program.enrollmentCount) enrolled", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("\(program.activeCount) active", systemImage: "play.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Spacer()

            // Completion rate gauge
            CompletionRateGauge(rate: program.completionRate)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Program Performance Card

struct ProgramPerformanceCard: View {
    let program: ProgramAnalytics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.programName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(program.category.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Category badge
                Text("\(program.durationWeeks)w")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(CornerRadius.xs)
            }

            // Stats row
            HStack(spacing: 16) {
                ProgramStatItem(label: "Enrolled", value: "\(program.enrollmentCount)", icon: "person.2.fill", color: .blue)
                ProgramStatItem(label: "Active", value: "\(program.activeCount)", icon: "play.circle.fill", color: .green)
                ProgramStatItem(label: "Completed", value: "\(program.completedCount)", icon: "checkmark.circle.fill", color: .teal)

                Spacer()

                // Completion rate
                VStack(alignment: .trailing, spacing: 2) {
                    Text(program.formattedCompletionRate)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(program.completionColor)

                    Text("completion")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                Text("Avg Progress: \(program.formattedAverageProgress)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * min(program.averageProgress / 100, 1.0), height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Program Stat Item

private struct ProgramStatItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Completion Rate Gauge

struct CompletionRateGauge: View {
    let rate: Double

    private var color: Color {
        switch rate {
        case 80...: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 4)
                .frame(width: 44, height: 44)

            Circle()
                .trim(from: 0, to: min(rate / 100, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-90))

            Text("\(Int(rate))%")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Completion rate \(Int(rate)) percent")
    }
}

// MARK: - Recent Enrollment Card

struct RecentEnrollmentCard: View {
    let enrollment: RecentEnrollment

    var body: some View {
        HStack(spacing: 12) {
            // Patient avatar
            Circle()
                .fill(Color.purple.gradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(enrollment.patientName.prefix(2).uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(enrollment.patientName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(enrollment.programName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: enrollment.status.icon)
                        .font(.caption2)
                    Text(enrollment.status.displayName)
                        .font(.caption2)
                }
                .foregroundColor(enrollment.status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(enrollment.status.color.opacity(0.15))
                .cornerRadius(CornerRadius.xs)

                // Enrolled date
                Text(enrollment.enrolledAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Program Analytics Detail Sheet

struct ProgramAnalyticsDetailSheet: View {
    let program: ProgramAnalytics
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(program.programName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 12) {
                            Label(program.category.capitalized, systemImage: "folder")
                            Label("\(program.durationWeeks) weeks", systemImage: "calendar")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding()

                    // Large completion rate display
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(Color(.systemGray5), lineWidth: 12)
                                .frame(width: 120, height: 120)

                            Circle()
                                .trim(from: 0, to: min(program.completionRate / 100, 1.0))
                                .stroke(program.completionColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 2) {
                                Text("\(Int(program.completionRate))%")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(program.completionColor)

                                Text("Completion")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()

                    // Stats grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        DetailStatCard(title: "Total Enrolled", value: "\(program.enrollmentCount)", icon: "person.2.fill", color: .blue)
                        DetailStatCard(title: "Active", value: "\(program.activeCount)", icon: "play.circle.fill", color: .green)
                        DetailStatCard(title: "Completed", value: "\(program.completedCount)", icon: "checkmark.circle.fill", color: .teal)
                        DetailStatCard(title: "Avg Progress", value: program.formattedAverageProgress, icon: "chart.line.uptrend.xyaxis", color: .purple)
                    }
                    .padding(.horizontal)

                    // Additional insights
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Insights")
                            .font(.headline)
                            .padding(.horizontal)

                        if program.enrollmentCount > 0 {
                            ProgramInsightRow(
                                icon: "lightbulb.fill",
                                text: "This program has \(program.enrollmentCount) enrollments",
                                color: .yellow
                            )

                            if program.activeCount > 0 {
                                ProgramInsightRow(
                                    icon: "person.fill.checkmark",
                                    text: "\(program.activeCount) patients are currently working through this program",
                                    color: .green
                                )
                            }

                            if program.completionRate >= 80 {
                                ProgramInsightRow(
                                    icon: "star.fill",
                                    text: "High completion rate indicates this program is well-structured",
                                    color: .orange
                                )
                            } else if program.completionRate < 50 && program.enrollmentCount >= 3 {
                                ProgramInsightRow(
                                    icon: "exclamationmark.triangle.fill",
                                    text: "Consider reviewing program content to improve completion rates",
                                    color: .red
                                )
                            }
                        } else {
                            ProgramInsightRow(
                                icon: "info.circle.fill",
                                text: "No enrollments yet. Consider promoting this program to patients.",
                                color: .blue
                            )
                        }
                    }
                    .padding(.bottom)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Detail Stat Card

struct DetailStatCard: View {
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
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Program Insight Row

private struct ProgramInsightRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .padding(.horizontal)
    }
}

// MARK: - Preview

#if DEBUG
struct ProgramAnalyticsDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramAnalyticsDashboardView()
            .environmentObject(AppState())
    }
}
#endif
