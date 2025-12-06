import SwiftUI

/// Therapist's patient list view with search and filtering
struct PatientListView: View {
    let therapistId: String

    @StateObject private var viewModel = PatientListViewModel()
    @State private var showFilterSheet = false

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading patients...")
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await viewModel.refresh(for: therapistId)
                    }
                }
            } else {
                patientList
            }
        }
        .navigationTitle("Patients")
        .searchable(text: $viewModel.searchText, prompt: "Search patients")
        .onChange(of: viewModel.searchText) { _ in
            viewModel.applyFilters()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showFilterSheet = true }) {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(viewModel: viewModel)
        }
        .refreshable {
            await viewModel.refresh(for: therapistId)
        }
        .task {
            await viewModel.fetchPatients(for: therapistId)
        }
    }

    private var patientList: some View {
        List {
            if viewModel.filteredPatients.isEmpty {
                ContentUnavailableView(
                    "No patients found",
                    systemImage: "person.slash",
                    description: Text("Try adjusting your search or filters")
                )
            } else {
                ForEach(viewModel.filteredPatients) { patient in
                    NavigationLink(destination: PatientDetailView(patient: patient)) {
                        PatientRowCard(patient: patient)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Patient Row Card

struct PatientRowCard: View {
    let patient: Patient

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(avatarColor)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(patient.firstName.prefix(1) + patient.lastName.prefix(1))
                        .font(.headline)
                        .foregroundColor(.white)
                )

            // Patient info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(patient.fullName)
                        .font(.headline)

                    if patient.hasHighSeverityFlags {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                if let sport = patient.sport, let position = patient.position {
                    Text("\(sport) - \(position)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    // Flag count
                    if let flagCount = patient.flagCount, flagCount > 0 {
                        Label("\(flagCount)", systemImage: "flag.fill")
                            .font(.caption)
                            .foregroundColor(patient.hasHighSeverityFlags ? .red : .orange)
                    }

                    // Adherence
                    if let adherence = patient.adherencePercentage {
                        Label("\(Int(adherence))%", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(adherenceColor(adherence))
                    }

                    // Last session
                    if let lastSession = patient.lastSessionDate {
                        Text(lastSession, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }

    private var avatarColor: Color {
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .indigo]
        let index = abs(patient.id.hashValue) % colors.count
        return colors[index]
    }

    private func adherenceColor(_ percentage: Double) -> Color {
        switch percentage {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @ObservedObject var viewModel: PatientListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                // Flag filter
                Section("Risk Level") {
                    Picker("Filter", selection: $viewModel.selectedFlagFilter) {
                        ForEach(PatientListViewModel.FlagFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Sport filter
                Section("Sport") {
                    Picker("Sport", selection: $viewModel.selectedSport) {
                        Text("All Sports").tag(nil as String?)
                        ForEach(viewModel.availableSports, id: \.self) { sport in
                            Text(sport).tag(sport as String?)
                        }
                    }
                }

                // Active filters summary
                Section("Active Filters") {
                    if viewModel.selectedFlagFilter != .all {
                        HStack {
                            Text("Risk Level")
                            Spacer()
                            Text(viewModel.selectedFlagFilter.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let sport = viewModel.selectedSport {
                        HStack {
                            Text("Sport")
                            Spacer()
                            Text(sport)
                                .foregroundColor(.secondary)
                        }
                    }

                    if viewModel.selectedFlagFilter == .all && viewModel.selectedSport == nil {
                        Text("No filters applied")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .navigationTitle("Filter Patients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        viewModel.selectedFlagFilter = .all
                        viewModel.selectedSport = nil
                        viewModel.applyFilters()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.applyFilters()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct PatientListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PatientListView(therapistId: "therapist-1")
        }
    }
}
