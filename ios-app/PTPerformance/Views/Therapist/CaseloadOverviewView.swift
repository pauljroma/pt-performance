//
//  CaseloadOverviewView.swift
//  PTPerformance
//
//  Created by Build 291 Swarm Agent 5
//
//  Visual grid/heatmap view showing patient status at a glance.
//  Provides therapists with a quick overview of their entire caseload.
//

import SwiftUI

// MARK: - ViewModel

@MainActor
class CaseloadOverviewViewModel: ObservableObject {
    @Published var patients: [Patient] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filterStatus: PatientStatus? = nil
    @Published var sortOption: SortOption = .status

    private let supabase = PTSupabaseClient.shared

    enum SortOption: String, CaseIterable {
        case status = "Status"
        case name = "Name"
        case adherence = "Adherence"
        case lastActive = "Last Active"
    }

    // MARK: - Filtered & Sorted Patients

    var filteredPatients: [Patient] {
        var result = patients

        // Apply filter
        if let filter = filterStatus {
            result = result.filter { $0.calculatedStatus == filter }
        }

        // Apply sort
        switch sortOption {
        case .status:
            result.sort { lhs, rhs in
                let lhsPriority = statusPriority(lhs.calculatedStatus)
                let rhsPriority = statusPriority(rhs.calculatedStatus)
                if lhsPriority != rhsPriority {
                    return lhsPriority < rhsPriority
                }
                return lhs.fullName < rhs.fullName
            }
        case .name:
            result.sort { $0.fullName < $1.fullName }
        case .adherence:
            result.sort { ($0.adherencePercentage ?? 0) > ($1.adherencePercentage ?? 0) }
        case .lastActive:
            result.sort { $0.daysSinceLastSession < $1.daysSinceLastSession }
        }

        return result
    }

    private func statusPriority(_ status: PatientStatus) -> Int {
        switch status {
        case .critical: return 0
        case .attention: return 1
        case .good: return 2
        }
    }

    // MARK: - Status Counts

    var goodCount: Int {
        patients.filter { $0.calculatedStatus == .good }.count
    }

    var attentionCount: Int {
        patients.filter { $0.calculatedStatus == .attention }.count
    }

    var criticalCount: Int {
        patients.filter { $0.calculatedStatus == .critical }.count
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
            ErrorLogger.shared.logError(error, context: "CaseloadOverviewView.fetchPatients")
            errorMessage = "Failed to load caseload data. Please try again."
        }
    }

    func refresh(therapistId: String) async {
        await fetchPatients(therapistId: therapistId)
    }
}

// MARK: - CaseloadOverviewView

struct CaseloadOverviewView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = CaseloadOverviewViewModel()
    @State private var selectedPatient: Patient?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // Responsive grid columns: 3 on iPad, 2 on iPhone
    private var columns: [GridItem] {
        let columnCount = horizontalSizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.patients.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage, viewModel.patients.isEmpty {
                    errorView(message: error)
                } else if viewModel.patients.isEmpty {
                    emptyStateView
                } else {
                    gridContent
                }
            }
            .navigationTitle("Caseload Overview")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    sortMenu
                }
            }
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

    // MARK: - Grid Content

    private var gridContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Summary bar at top
                CaseloadStatusSummary(patients: viewModel.patients)
                    .padding(.horizontal)

                // Filter chips
                filterChips
                    .padding(.horizontal)

                // Legend
                CaseloadStatusLegend()

                // Patient grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.filteredPatients) { patient in
                        CaseloadStatusCard(patient: patient) {
                            selectedPatient = patient
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.3), value: viewModel.filterStatus)
                .animation(.easeInOut(duration: 0.3), value: viewModel.sortOption)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    label: "All (\(viewModel.patients.count))",
                    color: .blue,
                    isSelected: viewModel.filterStatus == nil,
                    action: { viewModel.filterStatus = nil }
                )

                FilterChip(
                    label: "Critical (\(viewModel.criticalCount))",
                    color: .red,
                    isSelected: viewModel.filterStatus == .critical,
                    action: { viewModel.filterStatus = viewModel.filterStatus == .critical ? nil : .critical }
                )

                FilterChip(
                    label: "Attention (\(viewModel.attentionCount))",
                    color: .yellow,
                    isSelected: viewModel.filterStatus == .attention,
                    action: { viewModel.filterStatus = viewModel.filterStatus == .attention ? nil : .attention }
                )

                FilterChip(
                    label: "Good (\(viewModel.goodCount))",
                    color: .green,
                    isSelected: viewModel.filterStatus == .good,
                    action: { viewModel.filterStatus = viewModel.filterStatus == .good ? nil : .good }
                )
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(CaseloadOverviewViewModel.SortOption.allCases, id: \.self) { option in
                Button {
                    viewModel.sortOption = option
                } label: {
                    HStack {
                        Text(option.rawValue)
                        if viewModel.sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading caseload...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Patients",
            systemImage: "person.3.fill",
            description: Text("Your caseload will appear here once patients have been added.")
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

// FilterChip is defined in Components/FilterChip.swift

// MARK: - Preview

#if DEBUG
struct CaseloadOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        CaseloadOverviewView()
            .environmentObject(AppState())
    }
}
#endif
