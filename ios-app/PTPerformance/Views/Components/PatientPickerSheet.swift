// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  PatientPickerSheet.swift
//  PTPerformance
//
//  Phase 4 Integration - Patient Picker Sheet
//  Allows therapists to quickly select a patient for various actions
//

import SwiftUI

// MARK: - Patient Picker Sheet

struct PatientPickerSheet: View {
    let onSelect: (Patient) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PatientPickerViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SheetDragIndicator()

                Group {
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.patients.isEmpty {
                        emptyStateView
                    } else {
                        patientListView
                    }
                }
                .springPresentation()
            }
            .searchable(text: $searchText, prompt: "Search patients")
            .navigationTitle("Select Patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel")
                        .accessibilityHint("Closes patient picker without selecting")
                }
            }
            .task {
                await viewModel.loadPatients()
            }
        }
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Patient List View

    private var patientListView: some View {
        List {
            ForEach(filteredPatients) { patient in
                Button {
                    HapticService.selection()
                    onSelect(patient)
                    dismiss()
                } label: {
                    PatientRow(patient: patient)
                }
                .accessibilityLabel("Select \(patient.fullName)")
                .accessibilityHint(patient.hasHighSeverityFlags ? "Patient has high severity flags" : "Double tap to select this patient")
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg - 4) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading patients...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading patients")
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Patients Found")
                .font(.headline)

            Text("Add patients to your caseload to get started.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl + Spacing.xs)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No patients found. Add patients to your caseload to get started.")
    }

    // MARK: - Filtered Patients

    private var filteredPatients: [Patient] {
        if searchText.isEmpty {
            return viewModel.patients
        }
        return viewModel.patients.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Patient Row

private struct PatientRow: View {
    let patient: Patient

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Avatar
            Circle()
                .fill(Color.modusCyan.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(patient.initials)
                        .font(.headline)
                        .foregroundColor(.modusCyan)
                )

            // Patient info
            VStack(alignment: .leading, spacing: Spacing.xxs - 2) {
                Text(patient.fullName)
                    .font(.body)
                    .foregroundColor(.primary)

                if let condition = patient.injuryType {
                    Text(condition)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let sport = patient.sport {
                    Text(sport)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Status indicators
            if patient.hasHighSeverityFlags {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Patient Picker ViewModel

@MainActor
class PatientPickerViewModel: ObservableObject {
    @Published var patients: [Patient] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = PTSupabaseClient.shared

    func loadPatients() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Try to get therapist ID from app state
            guard let therapistId = await getTherapistId() else {
                // Use mock data for development
                patients = Patient.mockPatients
                return
            }

            // Load from therapist's caseload
            let response = try await supabase.client
                .from("patients")
                .select()
                .eq("therapist_id", value: therapistId)
                .order("last_name", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            patients = try decoder.decode([Patient].self, from: response.data)

        } catch {
            ErrorLogger.shared.logError(error, context: "PatientPickerViewModel.loadPatients")
            // Use mock data for development if API fails
            patients = Patient.mockPatients
        }
    }

    private func getTherapistId() async -> String? {
        // Try to get the current user ID from Supabase auth
        do {
            let session = try await supabase.client.auth.session
            return session.user.id.uuidString
        } catch {
            return nil
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PatientPickerSheet_Previews: PreviewProvider {
    static var previews: some View {
        PatientPickerSheet { patient in
            print("Selected: \(patient.fullName)")
        }
    }
}
#endif
