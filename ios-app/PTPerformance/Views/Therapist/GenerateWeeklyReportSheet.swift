//
//  GenerateWeeklyReportSheet.swift
//  PTPerformance
//
//  M7 - PT Weekly Report System
//  Sheet for generating a new weekly report
//

import SwiftUI

// MARK: - Generate Weekly Report Sheet

/// Sheet for generating a new weekly report for a patient
struct GenerateWeeklyReportSheet: View {
    let patient: Patient
    let onDismiss: () -> Void

    @StateObject private var viewModel = WeeklyReportViewModel()
    @State private var selectedDate = Date()
    @State private var showGeneratedReport = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Header
            headerSection

            // Date Picker
            datePickerSection

            // Week Summary
            weekSummarySection

            Spacer()

            // Action Buttons
            actionButtons
        }
        .padding()
        .navigationTitle("Generate Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                    onDismiss()
                }
            }
        }
        .overlay {
            if viewModel.isGenerating {
                generatingOverlay
            }
        }
        .sheet(isPresented: $showGeneratedReport) {
            if let report = viewModel.report {
                NavigationView {
                    WeeklyReportView(report: report, patientName: patient.fullName)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Done") {
                                    showGeneratedReport = false
                                    dismiss()
                                    onDismiss()
                                }
                            }
                        }
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearMessages()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            // Patient Avatar
            Circle()
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(patient.initials)
                        .font(.title2)
                        .foregroundColor(.white)
                )

            Text(patient.fullName)
                .font(.headline)

            if let injury = patient.injuryType {
                Text(injury)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Date Picker Section

    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Select Week")
                .font(.headline)

            DatePicker(
                "Week containing",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)

            Text("Report will cover the week containing the selected date")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Week Summary Section

    private var weekSummarySection: some View {
        let weekBounds = getWeekBoundaries(for: selectedDate)

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Report Period")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                VStack(alignment: .leading) {
                    Text("Week of")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedDate(weekBounds.start))
                        .font(.headline)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Through")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedDate(weekBounds.end))
                        .font(.headline)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                generateReport()
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("Generate Report")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(CornerRadius.md)
            }
            .disabled(viewModel.isGenerating)

            Text("This will aggregate patient data for the selected week and generate a comprehensive progress report.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Generating Overlay

    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.5)

                Text(viewModel.currentStep.isEmpty ? "Generating report..." : viewModel.currentStep)
                    .font(.headline)
                    .foregroundColor(.white)

                if viewModel.generationProgress > 0 {
                    ProgressView(value: viewModel.generationProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 200)
                }
            }
            .padding(Spacing.xl)
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.lg)
        }
    }

    // MARK: - Actions

    private func generateReport() {
        Task {
            await viewModel.generateReport(patientId: patient.id, weekOf: selectedDate)

            if viewModel.report != nil {
                showGeneratedReport = true
            }
        }
    }

    // MARK: - Helpers

    private func getWeekBoundaries(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date)
        let start = weekInterval?.start ?? date
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? date
        return (start, end)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#if DEBUG
struct GenerateWeeklyReportSheet_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GenerateWeeklyReportSheet(
                patient: Patient.samplePatients[0],
                onDismiss: {}
            )
        }
    }
}
#endif
