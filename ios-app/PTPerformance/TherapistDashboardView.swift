//
//  TherapistDashboardView.swift
//  PTPerformance
//
//  Therapist dashboard with patient list and workload flags
//

import SwiftUI

struct TherapistDashboardView: View {
    @StateObject private var viewModel = PatientListViewModel()
    @State private var showingPatientDetail: Patient?
    
    var body: some View {
        NavigationView {
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
                                // Navigate to patient with this flag
                                if let patient = viewModel.patient(for: flag.patientId) {
                                    showingPatientDetail = patient
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
                            PatientCardView(patient: patient)
                                .padding(.horizontal)
                                .onTapGesture {
                                    showingPatientDetail = patient
                                }
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadPatients()
                await viewModel.loadActiveFlags()
            }
            .sheet(item: $showingPatientDetail) { patient in
                PatientDetailView(patient: patient)
            }
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
                Text(patient.name)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label("\(Int(patient.adherence * 100))%", systemImage: "checkmark.circle")
                        .font(.caption)
                    
                    if let lastSession = patient.lastSessionDate {
                        Label(lastSession, style: .relative)
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Flags indicator
            if patient.hasActiveFlags {
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
