//
//  TherapistDashboardView.swift
//  PTPerformance
//
//  Therapist dashboard with patient list and workload flags
//

import SwiftUI

struct TherapistDashboardView: View {
    @StateObject private var viewModel = PatientListViewModel()
    @State private var selectedPatient: Patient?
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

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
        .task {
            await viewModel.loadPatients()
            await viewModel.loadActiveFlags()
        }
    }

    // MARK: - iPad Split View Layout

    private var iPadLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            patientListContent
                .navigationTitle("Dashboard")
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
        }
    }

    // MARK: - Shared Content

    @ViewBuilder
    private var patientListContent: some View {
        ScrollView {
            VStack(spacing: 20) {
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
                    .padding(.top)
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
            await viewModel.refresh()
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
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
