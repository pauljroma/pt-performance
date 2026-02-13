// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  RTSPatientListView.swift
//  PTPerformance
//
//  List view showing all patients with Return-to-Sport protocols.
//  Displays patient info, current phase, traffic light status, and navigation to RTS dashboard.
//

import SwiftUI

// MARK: - RTS Patient List View

/// List all patients with RTS protocols for therapist management
struct RTSPatientListView: View {
    @StateObject private var viewModel = RTSPatientListViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPatient: Patient?
    @State private var showProtocolEditor = false
    @State private var patientForNewProtocol: Patient?
    @State private var searchText = ""
    @State private var selectedFilter: ProtocolFilter = .active

    enum ProtocolFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case draft = "Draft"
        case completed = "Completed"

        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.protocolSummaries.isEmpty {
                loadingView
            } else if viewModel.protocolSummaries.isEmpty {
                emptyStateView
            } else {
                mainContent
            }
        }
        .navigationTitle("RTS Tracking")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search patients")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
        }
        .sheet(isPresented: $showProtocolEditor) {
            if let patient = patientForNewProtocol {
                RTSProtocolEditorView(patient: patient)
            }
        }
        .navigationDestination(item: $selectedPatient) { patient in
            RTSDashboardView(patientId: patient.id)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Retry") {
                Task { await loadData() }
            }
            Button("Dismiss", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Filter picker
            filterPicker

            // Stats summary
            statsSummary

            // Patient list
            patientList
        }
    }

    // MARK: - Filter Picker

    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(ProtocolFilter.allCases) { filter in
                    RTSFilterChip(
                        title: filter.rawValue,
                        count: countForFilter(filter),
                        isSelected: selectedFilter == filter
                    ) {
                        HapticFeedback.selectionChanged()
                        withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Spacing.sm)
        }
        .background(Color(.systemBackground))
    }

    private func countForFilter(_ filter: ProtocolFilter) -> Int {
        switch filter {
        case .all:
            return viewModel.protocolSummaries.count
        case .active:
            return viewModel.protocolSummaries.filter { $0.status == .active }.count
        case .draft:
            return viewModel.protocolSummaries.filter { $0.status == .draft }.count
        case .completed:
            return viewModel.protocolSummaries.filter { $0.status == .completed }.count
        }
    }

    // MARK: - Stats Summary

    private var statsSummary: some View {
        let active = viewModel.protocolSummaries.filter { $0.status == .active }
        let greenCount = active.filter { $0.trafficLight == .green }.count
        let yellowCount = active.filter { $0.trafficLight == .yellow }.count
        let redCount = active.filter { $0.trafficLight == .red }.count

        return HStack(spacing: Spacing.md) {
            StatBadge(
                title: "Green",
                count: greenCount,
                color: .green
            )

            StatBadge(
                title: "Yellow",
                count: yellowCount,
                color: .yellow
            )

            StatBadge(
                title: "Red",
                count: redCount,
                color: .red
            )
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.sm)
        .background(Color(.systemBackground))
    }

    // MARK: - Patient List

    private var patientList: some View {
        List {
            ForEach(filteredSummaries) { summary in
                RTSPatientRow(summary: summary) {
                    HapticFeedback.light()
                    selectedPatient = summary.patient
                }
            }
        }
        .listStyle(.plain)
    }

    private var filteredSummaries: [RTSProtocolSummary] {
        var summaries = viewModel.protocolSummaries

        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            summaries = summaries.filter { $0.status == .active }
        case .draft:
            summaries = summaries.filter { $0.status == .draft }
        case .completed:
            summaries = summaries.filter { $0.status == .completed }
        }

        // Apply search
        if !searchText.isEmpty {
            summaries = summaries.filter {
                $0.patient.fullName.localizedCaseInsensitiveContains(searchText) ||
                $0.sportName.localizedCaseInsensitiveContains(searchText) ||
                $0.injuryType.localizedCaseInsensitiveContains(searchText)
            }
        }

        return summaries
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            title: "No RTS Protocols",
            message: "Create Return-to-Sport protocols for your patients to track their journey back to athletic activity.",
            icon: "figure.run",
            iconColor: .indigo
        )
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading RTS protocols...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadData() async {
        guard let userIdString = appState.userId,
              let therapistId = UUID(uuidString: userIdString) else {
            viewModel.errorMessage = "Unable to identify therapist"
            return
        }
        await viewModel.loadData(therapistId: therapistId)
    }
}

// MARK: - RTS Patient Row

private struct RTSPatientRow: View {
    let summary: RTSProtocolSummary
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Avatar with traffic light ring
                ZStack {
                    Circle()
                        .stroke(summary.trafficLight.color, lineWidth: 3)
                        .frame(width: 52, height: 52)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(summary.patient.initials)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )
                }

                // Patient info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack {
                        Text(summary.patient.fullName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        RTSTrafficLightBadge(level: summary.trafficLight, size: .small)
                    }

                    HStack(spacing: Spacing.sm) {
                        // Sport
                        Label(summary.sportName, systemImage: "sportscourt")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        // Current phase
                        Text(summary.currentPhaseName)
                            .font(.caption)
                            .foregroundColor(summary.trafficLight.color)
                    }

                    // Progress and days
                    HStack {
                        ProgressView(value: summary.progressPercentage)
                            .tint(summary.trafficLight.color)
                            .frame(width: 80)

                        Text("\(Int(summary.progressPercentage * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer()

                        if summary.daysUntilTarget >= 0 {
                            Text("\(summary.daysUntilTarget) days left")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(abs(summary.daysUntilTarget)) days over")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(summary.patient.fullName), \(summary.sportName), \(summary.currentPhaseName), \(summary.trafficLight.displayName)")
        .accessibilityHint("Double tap to view RTS dashboard")
    }
}

// MARK: - Filter Chip

private struct RTSFilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color(.systemGray5))
                    .cornerRadius(CornerRadius.sm)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? Color.indigo : Color(.secondarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)

                Text("\(count)")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(title)")
    }
}

// MARK: - RTS Patient List ViewModel

@MainActor
class RTSPatientListViewModel: ObservableObject {
    @Published var protocolSummaries: [RTSProtocolSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let rtsService = RTSService.shared

    func loadData(therapistId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            let protocols = try await rtsService.fetchProtocols(therapistId: therapistId)

            // Build summaries for each protocol
            var summaries: [RTSProtocolSummary] = []

            for rtsProtocol in protocols {
                // Fetch patient info (in real implementation, this would be a join or cached)
                // For now, create a minimal patient representation
                let patient = Patient(
                    id: rtsProtocol.patientId,
                    therapistId: therapistId,
                    firstName: "Patient",
                    lastName: "\(rtsProtocol.patientId.uuidString.prefix(4))",
                    email: "",
                    sport: nil,
                    position: nil,
                    injuryType: rtsProtocol.injuryType,
                    targetLevel: nil,
                    profileImageUrl: nil,
                    createdAt: rtsProtocol.createdAt,
                    flagCount: nil,
                    highSeverityFlagCount: nil,
                    adherencePercentage: nil,
                    lastSessionDate: nil
                )

                // Fetch phases
                let phases = try await rtsService.fetchPhases(protocolId: rtsProtocol.id)
                let currentPhase = phases.first { $0.id == rtsProtocol.currentPhaseId } ?? phases.first { $0.isActive }

                // Fetch latest readiness score
                let latestReadiness = try await rtsService.fetchLatestReadinessScore(protocolId: rtsProtocol.id)

                // Fetch sport
                let sport = try await rtsService.fetchSport(id: rtsProtocol.sportId)

                let summary = RTSProtocolSummary(
                    id: rtsProtocol.id,
                    patient: patient,
                    sportName: sport.name,
                    injuryType: rtsProtocol.injuryType,
                    status: rtsProtocol.status,
                    currentPhaseName: currentPhase?.phaseName ?? "Not Started",
                    trafficLight: latestReadiness?.trafficLight ?? currentPhase?.activityLevel ?? .red,
                    progressPercentage: rtsProtocol.progressPercentage,
                    daysUntilTarget: rtsProtocol.daysUntilTarget,
                    latestReadinessScore: latestReadiness?.overallScore
                )

                summaries.append(summary)
            }

            protocolSummaries = summaries

            DebugLogger.shared.log("[RTSPatientListVM] Loaded \(summaries.count) protocol summaries", level: .success)
        } catch {
            errorMessage = error.localizedDescription
            DebugLogger.shared.log("[RTSPatientListVM] Error loading data: \(error)", level: .error)
        }

        isLoading = false
    }
}

// MARK: - RTS Protocol Summary

struct RTSProtocolSummary: Identifiable {
    let id: UUID
    let patient: Patient
    let sportName: String
    let injuryType: String
    let status: RTSProtocolStatus
    let currentPhaseName: String
    let trafficLight: RTSTrafficLight
    let progressPercentage: Double
    let daysUntilTarget: Int
    let latestReadinessScore: Double?
}

// MARK: - Preview

#if DEBUG
struct RTSPatientListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RTSPatientListView()
                .environmentObject(AppState())
        }
    }
}
#endif
