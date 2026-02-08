//
//  TherapistDashboardView.swift
//  PTPerformance
//
//  Therapist dashboard with patient list and workload flags
//

import SwiftUI

struct TherapistDashboardView: View {
    @StateObject private var viewModel = PatientListViewModel()
    @StateObject private var schedulingViewModel = TherapistSchedulingViewModel()
    @State private var selectedPatient: Patient?
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var showDebugLogs = false
    @State private var showAddPatient = false
    @State private var showCreateProgram = false
    @State private var showReports = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var appState: AppState

    var shouldUseSplitView: Bool {
        DeviceHelper.shouldUseSplitView(horizontalSizeClass: horizontalSizeClass)
    }

    var body: some View {
        Group {
            if shouldUseSplitView {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .sheet(isPresented: $showDebugLogs) {
            DebugLogView()
        }
        .sheet(isPresented: $showAddPatient) {
            TherapistPatientSetupView()
        }
        .sheet(isPresented: $showCreateProgram) {
            CreateProgramPlaceholderView()
        }
        .sheet(isPresented: $showReports) {
            TherapistReportingView()
                .environmentObject(appState)
        }
        .task {
            if let therapistId = appState.userId {
                await viewModel.loadPatients(therapistId: therapistId)
                await viewModel.loadActiveFlags(therapistId: therapistId)
                await schedulingViewModel.loadAllSessions(therapistId: therapistId)
            } else {
                // SECURITY: Do NOT load patients without therapist ID
                // This prevents unauthorized access to patient data
                viewModel.errorMessage = "Unable to identify therapist. Please sign in again."
                DebugLogger.shared.log("⚠️ SECURITY: Cannot load patients - no therapist ID", level: .error)
            }
        }
    }

    // MARK: - iPad Split View Layout

    private var iPadLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            patientListContent
                .navigationTitle("Dashboard")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showDebugLogs = true }) {
                            Image(systemName: "ant.circle")
                                .foregroundColor(.orange)
                        }
                    }
                }
                .navigationSplitViewColumnWidth(
                    min: DeviceHelper.sidebarWidth.min,
                    ideal: DeviceHelper.sidebarWidth.ideal,
                    max: DeviceHelper.sidebarWidth.max
                )
        } detail: {
            if let patient = selectedPatient {
                PatientDetailView(patient: patient)
            } else {
                placeholderDetailView
            }
        }
    }

    // MARK: - iPhone Stack Layout

    private var iPhoneLayout: some View {
        NavigationStack {
            patientListContent
                .navigationTitle("Dashboard")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showDebugLogs = true }) {
                            Image(systemName: "ant.circle")
                                .foregroundColor(.orange)
                        }
                    }
                }
        }
    }

    // MARK: - Shared Content

    @ViewBuilder
    private var patientListContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // KPI Section at the top
                DashboardKPISection(
                    patients: viewModel.patients,
                    activeFlags: viewModel.activeFlags,
                    upcomingSessions: schedulingViewModel.sessions,
                    onAddPatient: { showAddPatient = true },
                    onCreateProgram: { showCreateProgram = true },
                    onViewReports: { showReports = true },
                    onSessionTap: { item in
                        handlePatientSelection(item.patient)
                    }
                )
                .padding(.top)

                // Active Alerts Section
                if !viewModel.activeFlags.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Alerts (\(viewModel.activeFlags.count))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        WorkloadFlagsList(flags: viewModel.activeFlags) { flag in
                            if let patient = viewModel.patient(for: flag.patientId) {
                                handlePatientSelection(patient)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Patient List
                VStack(alignment: .leading, spacing: 12) {
                    Text("My Patients (\(viewModel.patients.count))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    ForEach(viewModel.patients) { patient in
                        if shouldUseSplitView {
                            // iPad: Direct selection
                            PatientCardView(patient: patient)
                                .padding(.horizontal)
                                .background(
                                    selectedPatient?.id == patient.id
                                        ? Color.blue.opacity(0.1)
                                        : Color.clear
                                )
                                .cornerRadius(12)
                                .onTapGesture {
                                    handlePatientSelection(patient)
                                }
                        } else {
                            // iPhone: Navigation Link
                            NavigationLink(value: patient) {
                                PatientCardView(patient: patient)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .padding(.bottom)
        }
        .refreshable {
            HapticFeedback.light()
            if let therapistId = appState.userId {
                await viewModel.refresh(therapistId: therapistId)
                await schedulingViewModel.refresh(therapistId: therapistId)
            } else {
                // SECURITY: Do NOT refresh without therapist ID
                // This prevents unauthorized access to patient data
                viewModel.errorMessage = "Unable to identify therapist. Please sign in again."
                DebugLogger.shared.log("⚠️ SECURITY: Cannot refresh patients - no therapist ID", level: .error)
            }
        }
        .navigationDestination(for: Patient.self) { patient in
            if !shouldUseSplitView {
                PatientDetailView(patient: patient)
            }
        }
    }

    private var placeholderDetailView: some View {
        ContentUnavailableView(
            "Select a Patient",
            systemImage: "person.circle",
            description: Text("Choose a patient from the list to view their details and progress")
        )
    }

    private func handlePatientSelection(_ patient: Patient) {
        HapticFeedback.selectionChanged()
        selectedPatient = patient

        // On iPad, ensure detail is visible
        if shouldUseSplitView {
            columnVisibility = .doubleColumn
        }
    }
}

struct PatientCardView: View {
    let patient: Patient

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(patient.initials)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(patient.fullName)
                    .font(.headline)

                HStack(spacing: 12) {
                    Label("\(Int((patient.adherencePercentage ?? 0.0)))%", systemImage: "checkmark.circle")
                        .font(.caption)

                    if let lastSession = patient.lastSessionDate {
                        Text(lastSession, style: .relative)
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            // Quick access to 60s Brief
            PTBriefButton(athleteId: patient.id, athleteName: patient.fullName, compact: true)

            // Flags indicator
            if patient.hasHighSeverityFlags {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Placeholder Views for Quick Actions

/// Placeholder view for Add Patient action
/// Replace with actual implementation when available
struct AddPatientPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Add Patient")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Patient registration form coming soon.\nThis feature will allow you to add new patients to your caseload.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Placeholder view for Create Program action
/// Replace with actual implementation when available
struct CreateProgramPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("Create Program")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Program builder coming soon.\nThis feature will allow you to create custom rehabilitation programs for your patients.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Create Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct TherapistDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        TherapistDashboardView()
            .environmentObject(AppState())
    }
}
#endif
