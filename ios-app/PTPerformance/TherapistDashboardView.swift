//
//  TherapistDashboardView.swift
//  PTPerformance
//
//  Therapist dashboard with patient list and workload flags
//

import SwiftUI

// MARK: - Dashboard View State

@MainActor
class TherapistDashboardViewState: ObservableObject {
    @Published var selectedPatient: Patient?
    @Published var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @Published var showDebugLogs = false
    @Published var showAddPatient = false
    @Published var showCreateProgram = false
    @Published var showCreateTemplate = false
    @Published var showReports = false
    @Published var showEscalationQueue = false
    @Published var showProgramAnalytics = false
    @Published var selectedEscalation: RiskEscalation?

    func handlePatientSelection(_ patient: Patient, shouldUseSplitView: Bool) {
        HapticFeedback.selectionChanged()
        selectedPatient = patient

        // On iPad, ensure detail is visible
        if shouldUseSplitView {
            columnVisibility = .doubleColumn
        }
    }
}

// MARK: - TherapistDashboardView

struct TherapistDashboardView: View {
    @StateObject private var state = TherapistDashboardViewState()
    @StateObject private var viewModel = PatientListViewModel()
    @StateObject private var schedulingViewModel = TherapistSchedulingViewModel()
    @StateObject private var escalationService = RiskEscalationService.shared
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var appState: AppState

    /// Deep link patient ID binding — set by TherapistTabView when a `.patient` deep link arrives
    @Binding var deepLinkPatientId: String?

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
        .springSheet(isPresented: $state.showDebugLogs) {
            DebugLogView()
        }
        .springSheet(isPresented: $state.showAddPatient) {
            TherapistPatientSetupView()
        }
        .springSheet(isPresented: $state.showCreateProgram) {
            EnhancedProgramBuilderView()
        }
        .springSheet(isPresented: $state.showReports) {
            TherapistReportingView()
                .environmentObject(appState)
        }
        .springSheet(isPresented: $state.showEscalationQueue) {
            EscalationQueueView()
        }
        .springSheet(isPresented: $state.showCreateTemplate) {
            WorkoutTemplateBuilderView()
        }
        .springSheet(isPresented: $state.showProgramAnalytics) {
            ProgramAnalyticsDashboardView()
                .environmentObject(appState)
        }
        .springSheet(item: $state.selectedEscalation) { escalation in
            EscalationDetailSheet(
                escalation: escalation,
                patient: viewModel.patient(for: escalation.patientId),
                onAcknowledge: {
                    Task {
                        _ = try? await escalationService.acknowledgeEscalation(escalation.id)
                    }
                },
                onResolve: nil,
                onDismiss: nil
            )
        }
        .task {
            if let therapistId = appState.userId {
                async let patients: () = viewModel.loadPatients(therapistId: therapistId)
                async let flags: () = viewModel.loadActiveFlags(therapistId: therapistId)
                async let sessions: () = schedulingViewModel.loadAllSessions(therapistId: therapistId)
                async let escalations: () = { try? await escalationService.fetchActiveEscalations(for: therapistId) }()
                _ = await (patients, flags, sessions, escalations)
            } else {
                // SECURITY: Do NOT load patients without therapist ID
                // This prevents unauthorized access to patient data
                viewModel.errorMessage = "Unable to identify therapist. Please sign in again."
                DebugLogger.shared.log("⚠️ SECURITY: Cannot load patients - no therapist ID", level: .error)
            }
        }
        // Deep link: navigate to a specific patient when deepLinkPatientId is set
        .onChange(of: deepLinkPatientId) { _, newPatientId in
            guard let patientIdString = newPatientId,
                  let patientUUID = UUID(uuidString: patientIdString) else { return }

            // Clear the deep link so it doesn't fire again
            deepLinkPatientId = nil

            // Find the patient in the loaded list and select them
            if let patient = viewModel.patient(for: patientUUID) {
                state.handlePatientSelection(patient, shouldUseSplitView: shouldUseSplitView)
            } else {
                DebugLogger.shared.log("[TherapistDashboardView] Deep link patient not found: \(patientIdString)", level: .warning)
            }
        }
    }

    // MARK: - iPad Split View Layout

    private var iPadLayout: some View {
        NavigationSplitView(columnVisibility: $state.columnVisibility) {
            patientListContent
                .navigationTitle("Dashboard")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { state.showDebugLogs = true }) {
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
            if let patient = state.selectedPatient {
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
                        Button(action: { state.showDebugLogs = true }) {
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
                // Safety Alerts Section (prominent position for critical escalations)
                if !escalationService.activeEscalations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Safety Alerts")
                                .font(.title2)
                                .fontWeight(.bold)

                            Spacer()

                            if escalationService.unacknowledgedCount > 0 {
                                Button {
                                    state.showEscalationQueue = true
                                } label: {
                                    Text("View All (\(escalationService.activeEscalations.count))")
                                        .font(.subheadline)
                                        .foregroundColor(.modusCyan)
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Show top critical/high escalations
                        ForEach(escalationService.activeEscalations.filter { $0.severity >= .high }.prefix(3)) { escalation in
                            SafetyAlertCard(
                                escalation: escalation,
                                patient: viewModel.patient(for: escalation.patientId),
                                onAcknowledge: {
                                    Task {
                                        _ = try? await escalationService.acknowledgeEscalation(escalation.id)
                                    }
                                },
                                onCallPatient: {
                                    // Handle call action
                                    if let patient = viewModel.patient(for: escalation.patientId) {
                                        state.handlePatientSelection(patient, shouldUseSplitView: shouldUseSplitView)
                                    }
                                },
                                onViewDetails: {
                                    state.selectedEscalation = escalation
                                }
                            )
                            .padding(.horizontal)
                        }

                        // Summary banner for remaining alerts
                        if escalationService.activeEscalations.count > 3 {
                            SafetyAlertsBanner(summary: escalationService.summary) {
                                state.showEscalationQueue = true
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }

                // KPI Section at the top
                DashboardKPISection(
                    patients: viewModel.patients,
                    activeFlags: viewModel.activeFlags,
                    upcomingSessions: schedulingViewModel.sessions,
                    onAddPatient: { state.showAddPatient = true },
                    onCreateProgram: { state.showCreateProgram = true },
                    onCreateTemplate: { state.showCreateTemplate = true },
                    onViewReports: { state.showReports = true },
                    onViewAnalytics: { state.showProgramAnalytics = true },
                    onSessionTap: { item in
                        state.handlePatientSelection(item.patient, shouldUseSplitView: shouldUseSplitView)
                    }
                )

                // Active Alerts Section
                if !viewModel.activeFlags.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Alerts (\(viewModel.activeFlags.count))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        WorkloadFlagsList(flags: viewModel.activeFlags) { flag in
                            if let patient = viewModel.patient(for: flag.patientId) {
                                state.handlePatientSelection(patient, shouldUseSplitView: shouldUseSplitView)
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
                                    state.selectedPatient?.id == patient.id
                                        ? Color.modusCyan.opacity(0.1)
                                        : Color.clear
                                )
                                .cornerRadius(CornerRadius.md)
                                .onTapGesture {
                                    state.handlePatientSelection(patient, shouldUseSplitView: shouldUseSplitView)
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
        .refreshableWithHaptic {
            if let therapistId = appState.userId {
                async let refresh: () = viewModel.refresh(therapistId: therapistId)
                async let sessions: () = schedulingViewModel.refresh(therapistId: therapistId)
                async let escalations: () = { try? await escalationService.fetchActiveEscalations(for: therapistId) }()
                _ = await (refresh, sessions, escalations)
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

}

struct PatientCardView: View {
    let patient: Patient

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.modusCyan.gradient)
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
        .cornerRadius(CornerRadius.md)
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
                    .foregroundColor(.modusCyan)

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

// MARK: - Preview

#if DEBUG
struct TherapistDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        TherapistDashboardView(deepLinkPatientId: .constant(nil))
            .environmentObject(AppState())
    }
}
#endif
