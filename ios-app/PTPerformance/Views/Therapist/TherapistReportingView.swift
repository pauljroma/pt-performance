//
//  TherapistReportingView.swift
//  PTPerformance
//
//  Created by Build 291 Swarm Agent 2
//
//  Therapist-facing aggregate analytics/reporting dashboard
//  showing metrics across all their patients.
//

import SwiftUI

// MARK: - ViewModel

@MainActor
class TherapistReportingViewModel: ObservableObject {
    @Published var patients: [Patient] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = PTSupabaseClient.shared

    // MARK: - Aggregate Statistics

    var totalPatients: Int {
        patients.count
    }

    var averageAdherence: Double? {
        let values = patients.compactMap { $0.adherencePercentage }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    var totalActiveFlags: Int {
        patients.reduce(0) { $0 + ($1.flagCount ?? 0) }
    }

    var totalHighSeverityFlags: Int {
        patients.reduce(0) { $0 + ($1.highSeverityFlagCount ?? 0) }
    }

    // MARK: - Sorted / Filtered Lists

    var patientsByAdherence: [Patient] {
        patients.sorted { ($0.adherencePercentage ?? -1) > ($1.adherencePercentage ?? -1) }
    }

    var patientsByRecentActivity: [Patient] {
        patients.sorted { lhs, rhs in
            guard let lhsDate = lhs.lastSessionDate else { return false }
            guard let rhsDate = rhs.lastSessionDate else { return true }
            return lhsDate > rhsDate
        }
    }

    var patientsNeedingAttention: [Patient] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return patients.filter { patient in
            let hasHighFlags = (patient.highSeverityFlagCount ?? 0) > 0
            let lowAdherence = (patient.adherencePercentage ?? 0) < 50
            let inactive = patient.lastSessionDate == nil || (patient.lastSessionDate ?? Date()) < sevenDaysAgo
            return hasHighFlags || lowAdherence || inactive
        }
    }

    // MARK: - Data Fetching

    func fetchPatients(therapistId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await supabase.client
                .from("patients")
                .select()
                .eq("therapist_id", value: therapistId)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode([Patient].self, from: response.data)

            patients = decoded
        } catch {
            ErrorLogger.shared.logError(error, context: "TherapistReportingView.fetchPatients")
            errorMessage = "Failed to load reporting data. Please try again."
        }
    }

    func refresh(therapistId: String) async {
        await fetchPatients(therapistId: therapistId)
    }
}

// MARK: - Report View Mode

enum ReportViewMode: String, CaseIterable {
    case reports = "Reports"
    case caseloadGrid = "Caseload Grid"

    var icon: String {
        switch self {
        case .reports: return "chart.bar.doc.horizontal"
        case .caseloadGrid: return "square.grid.2x2"
        }
    }
}

// MARK: - TherapistReportingView

struct TherapistReportingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = TherapistReportingViewModel()
    @State private var selectedMode: ReportViewMode = .reports
    @State private var selectedPatient: Patient?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // Responsive grid columns: 3 on iPad, 2 on iPhone
    private var gridColumns: [GridItem] {
        let columnCount = horizontalSizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control for view mode
                Picker("View Mode", selection: $selectedMode) {
                    ForEach(ReportViewMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Content based on selected mode
                ZStack {
                    if viewModel.isLoading && viewModel.patients.isEmpty {
                        ProgressView("Loading...")
                    } else if let error = viewModel.errorMessage, viewModel.patients.isEmpty {
                        errorView(message: error)
                    } else if viewModel.patients.isEmpty {
                        emptyStateView
                    } else {
                        switch selectedMode {
                        case .reports:
                            reportContent
                        case .caseloadGrid:
                            caseloadGridContent
                        }
                    }
                }
            }
            .navigationTitle("Reports")
            .refreshable {
                if let therapistId = appState.userId {
                    await viewModel.refresh(therapistId: therapistId)
                }
            }
            .task {
                if let therapistId = appState.userId {
                    await viewModel.fetchPatients(therapistId: therapistId)
                } else {
                    viewModel.errorMessage = "Unable to identify therapist. Please sign in again."
                }
            }
            .navigationDestination(item: $selectedPatient) { patient in
                PatientDetailView(patient: patient)
            }
        }
    }

    // MARK: - Report Content

    private var reportContent: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Summary Cards
                summaryCardsSection

                // Adherence Leaderboard
                adherenceSection

                // Recent Activity
                recentActivitySection

                // Needs Attention
                if !viewModel.patientsNeedingAttention.isEmpty {
                    needsAttentionSection
                }
            }
            .padding()
        }
    }

    // MARK: - Caseload Grid Content

    private var caseloadGridContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Summary bar at top
                CaseloadStatusSummary(patients: viewModel.patients)
                    .padding(.horizontal)

                // Legend
                CaseloadStatusLegend()

                // Patient grid
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(sortedPatientsByStatus) { patient in
                        CaseloadStatusCard(patient: patient) {
                            selectedPatient = patient
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    /// Patients sorted by status priority (critical first, then attention, then good)
    private var sortedPatientsByStatus: [Patient] {
        viewModel.patients.sorted { lhs, rhs in
            let lhsPriority = statusPriority(lhs.calculatedStatus)
            let rhsPriority = statusPriority(rhs.calculatedStatus)
            if lhsPriority != rhsPriority {
                return lhsPriority < rhsPriority
            }
            return lhs.fullName < rhs.fullName
        }
    }

    private func statusPriority(_ status: PatientStatus) -> Int {
        switch status {
        case .critical: return 0
        case .attention: return 1
        case .good: return 2
        }
    }

    // MARK: - Summary Cards Section

    private var summaryCardsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ReportSummaryCard(
                icon: "person.2.fill",
                label: "Total Patients",
                value: "\(viewModel.totalPatients)",
                color: .blue
            )

            ReportSummaryCard(
                icon: "checkmark.circle.fill",
                label: "Avg Adherence",
                value: viewModel.averageAdherence != nil
                    ? "\(Int(viewModel.averageAdherence!))%"
                    : "N/A",
                color: .green
            )

            ReportSummaryCard(
                icon: "flag.fill",
                label: "Active Flags",
                value: "\(viewModel.totalActiveFlags)",
                color: .orange
            )

            ReportSummaryCard(
                icon: "exclamationmark.triangle.fill",
                label: "High Severity",
                value: "\(viewModel.totalHighSeverityFlags)",
                color: .red
            )
        }
    }

    // MARK: - Adherence Leaderboard Section

    private var adherenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patient Adherence")
                .font(.title2)
                .fontWeight(.bold)

            ForEach(viewModel.patientsByAdherence) { patient in
                AdherenceRow(patient: patient)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.title2)
                .fontWeight(.bold)

            ForEach(viewModel.patientsByRecentActivity) { patient in
                RecentActivityRow(patient: patient)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Needs Attention Section

    private var needsAttentionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Needs Attention")
                .font(.title2)
                .fontWeight(.bold)

            ForEach(viewModel.patientsNeedingAttention) { patient in
                NeedsAttentionRow(patient: patient)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            title: "No Patient Reports",
            message: "Reports and analytics will appear here once patients are assigned to your caseload. Track adherence, progress trends, and patient outcomes.",
            icon: "chart.bar.doc.horizontal",
            iconColor: .purple,
            action: nil
        )
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text("Error")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task {
                    if let therapistId = appState.userId {
                        await viewModel.fetchPatients(therapistId: therapistId)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Summary Card

struct ReportSummaryCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.gradient)
        .cornerRadius(12)
    }
}

// MARK: - Adherence Row

struct AdherenceRow: View {
    let patient: Patient

    var body: some View {
        HStack(spacing: 12) {
            Text(patient.fullName)
                .font(.subheadline)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)

            if let adherence = patient.adherencePercentage {
                ProgressView(value: min(adherence, 100), total: 100)
                    .tint(adherenceColor(adherence))

                Text("\(Int(adherence))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(adherenceColor(adherence))
                    .frame(width: 48, alignment: .trailing)
            } else {
                Spacer()

                Text("No data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }

    private func adherenceColor(_ percentage: Double) -> Color {
        switch percentage {
        case 80...: return .green
        case 50..<80: return .yellow
        default: return .red
        }
    }
}

// MARK: - Recent Activity Row

struct RecentActivityRow: View {
    let patient: Patient

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title3)
                .foregroundColor(.blue)

            Text(patient.fullName)
                .font(.subheadline)

            Spacer()

            if let lastSession = patient.lastSessionDate {
                Text(relativeTimeString(from: lastSession))
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("No sessions yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }

    private func relativeTimeString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        let components = calendar.dateComponents([.day, .hour], from: date, to: now)
        let days = components.day ?? 0
        let hours = components.hour ?? 0

        if days == 0 && hours < 24 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days) days ago"
        } else if days < 30 {
            let weeks = days / 7
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        } else {
            let months = days / 30
            return months == 1 ? "1 month ago" : "\(months) months ago"
        }
    }
}

// MARK: - Needs Attention Row

struct NeedsAttentionRow: View {
    let patient: Patient

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title3)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(patient.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if (patient.highSeverityFlagCount ?? 0) > 0 {
                        attentionBadge(
                            text: "\(patient.highSeverityFlagCount!) High Severity",
                            color: .red
                        )
                    }

                    if (patient.adherencePercentage ?? 100) < 50 {
                        attentionBadge(
                            text: "Low Adherence",
                            color: .yellow
                        )
                    }

                    if isInactive(patient) {
                        attentionBadge(
                            text: "Inactive",
                            color: .gray
                        )
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func attentionBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(color == .yellow ? .black : .white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .cornerRadius(6)
    }

    private func isInactive(_ patient: Patient) -> Bool {
        guard let lastSession = patient.lastSessionDate else { return true }
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return lastSession < sevenDaysAgo
    }
}

// MARK: - Preview

#if DEBUG
struct TherapistReportingView_Previews: PreviewProvider {
    static var previews: some View {
        TherapistReportingView()
            .environmentObject(AppState())
    }
}
#endif
