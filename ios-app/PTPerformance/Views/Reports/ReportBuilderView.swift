//
//  ReportBuilderView.swift
//  PTPerformance
//
//  Therapist interface for building and generating patient reports
//  Supports multiple report types, custom date ranges, and section selection
//

import SwiftUI

// MARK: - Report Builder View

struct ReportBuilderView: View {
    let patient: Patient

    @StateObject private var reportService = ReportGenerationService.shared
    @StateObject private var brandingService = TherapistBrandingService.shared
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // Configuration state
    @State private var selectedReportType: ReportType = .progress
    @State private var selectedPeriod: ReportPeriod = .oneMonth
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()
    @State private var selectedSections: Set<ReportSection> = []
    @State private var includeCharts: Bool = true
    @State private var includeClinicBranding: Bool = true

    // UI state
    @State private var showPreview = false
    @State private var showEmailComposer = false
    @State private var showError = false
    @State private var showSuccessAlert = false
    @State private var generatedReport: GeneratedReport?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Patient header
                    patientHeaderSection

                    // Quick presets
                    quickPresetsSection

                    // Report type selection
                    reportTypeSection

                    // Date range selection
                    dateRangeSection

                    // Section selection
                    sectionSelectionSection

                    // Options
                    optionsSection

                    // Generate button
                    generateButton
                }
                .padding()
            }
            .navigationTitle("Generate Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                // Initialize selected sections based on report type
                selectedSections = Set(selectedReportType.defaultSections)

                // Load therapist branding
                if let therapistId = appState.userId {
                    await brandingService.loadBranding(therapistId: therapistId)
                }
            }
            .onChange(of: selectedReportType) { _, newType in
                // Update sections when report type changes
                selectedSections = Set(newType.defaultSections)
            }
            .sheet(isPresented: $showPreview) {
                if let report = generatedReport {
                    ReportPreviewView(
                        report: report,
                        patient: patient,
                        therapistEmail: brandingService.branding?.clinicEmail
                    )
                }
            }
            .sheet(isPresented: $showEmailComposer) {
                if let report = generatedReport {
                    EmailComposerSheet(
                        report: report,
                        patient: patient,
                        therapistEmail: brandingService.branding?.clinicEmail,
                        onSuccess: { _ in
                            dismiss()
                        }
                    )
                }
            }
            .alert("Report Generated", isPresented: $showSuccessAlert) {
                Button("Email Report") {
                    showEmailComposer = true
                }
                .keyboardShortcut(.defaultAction)
                Button("Preview") {
                    showPreview = true
                }
                Button("Done", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Your report has been generated successfully. Would you like to email it to the patient?")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(reportService.errorMessage ?? "An unknown error occurred")
            }
        }
    }

    // MARK: - Patient Header Section

    private var patientHeaderSection: some View {
        HStack(spacing: Spacing.md) {
            // Avatar
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
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(patient.fullName)
                    .font(.headline)

                if let injury = patient.injuryType {
                    Text(injury)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let adherence = patient.adherencePercentage {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(adherenceColor(adherence))
                            .font(.caption)
                        Text("\(Int(adherence))% adherence")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Patient: \(patient.fullName)")
    }

    // MARK: - Quick Presets Section

    private var quickPresetsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick Presets")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(ReportPreset.allPresets) { preset in
                        QuickPresetButton(preset: preset) {
                            applyPreset(preset)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Report Type Section

    private var reportTypeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Report Type")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                ForEach(ReportType.allCases) { type in
                    ReportTypeCard(
                        type: type,
                        isSelected: selectedReportType == type
                    ) {
                        HapticFeedback.selectionChanged()
                        selectedReportType = type
                    }
                }
            }
        }
    }

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Date Range")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            // Period picker
            Picker("Period", selection: $selectedPeriod) {
                ForEach(ReportPeriod.allCases) { period in
                    Text(period.displayName).tag(period)
                }
            }
            .pickerStyle(.segmented)

            // Custom date pickers (shown when custom is selected)
            if selectedPeriod == .custom {
                VStack(spacing: Spacing.sm) {
                    DatePicker(
                        "Start Date",
                        selection: $customStartDate,
                        in: ...customEndDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)

                    DatePicker(
                        "End Date",
                        selection: $customEndDate,
                        in: customStartDate...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.sm)
            }

            // Date range display
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text(dateRangeDisplayText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Section Selection

    private var sectionSelectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Include Sections")
                    .font(.headline)

                Spacer()

                Button("Select All") {
                    selectedSections = Set(ReportSection.allCases)
                }
                .font(.subheadline)
            }
            .accessibilityElement(children: .combine)

            VStack(spacing: Spacing.xs) {
                ForEach(ReportSection.allCases) { section in
                    SectionToggleRow(
                        section: section,
                        isSelected: selectedSections.contains(section)
                    ) {
                        HapticFeedback.selectionChanged()
                        if selectedSections.contains(section) {
                            selectedSections.remove(section)
                        } else {
                            selectedSections.insert(section)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Options")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                Toggle(isOn: $includeCharts) {
                    Label("Include Charts", systemImage: "chart.line.uptrend.xyaxis")
                }
                .padding()

                Divider()

                Toggle(isOn: $includeClinicBranding) {
                    Label("Include Clinic Branding", systemImage: "building.2")
                }
                .padding()
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            generateReport()
        } label: {
            HStack {
                if reportService.isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)

                    Text(reportService.currentStep)
                        .font(.headline)
                } else {
                    Image(systemName: "doc.text.fill")
                    Text("Generate Report")
                        .font(.headline)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                reportService.isGenerating || selectedSections.isEmpty
                    ? Color.gray
                    : Color.blue
            )
            .cornerRadius(CornerRadius.md)
        }
        .disabled(reportService.isGenerating || selectedSections.isEmpty)
        .accessibilityLabel(reportService.isGenerating ? "Generating report: \(reportService.currentStep)" : "Generate report")
        .accessibilityHint("Creates a PDF report with the selected options")
    }

    // MARK: - Computed Properties

    private var dateRangeDisplayText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        let startDate: Date
        let endDate: Date

        if selectedPeriod == .custom {
            startDate = customStartDate
            endDate = customEndDate
        } else {
            endDate = Date()
            startDate = Calendar.current.date(byAdding: .day, value: -selectedPeriod.rawValue, to: endDate) ?? endDate
        }

        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    private func adherenceColor(_ percentage: Double) -> Color {
        switch percentage {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }

    // MARK: - Actions

    private func applyPreset(_ preset: ReportPreset) {
        HapticFeedback.selectionChanged()
        selectedReportType = preset.reportType
        selectedPeriod = preset.period
        selectedSections = Set(preset.sections)
    }

    private func generateReport() {
        HapticFeedback.medium()

        Task {
            let startDate: Date
            let endDate: Date

            if selectedPeriod == .custom {
                startDate = customStartDate
                endDate = customEndDate
            } else {
                endDate = Date()
                startDate = Calendar.current.date(byAdding: .day, value: -selectedPeriod.rawValue, to: endDate) ?? endDate
            }

            let configuration = ReportConfiguration(
                reportType: selectedReportType,
                patientId: patient.id,
                startDate: startDate,
                endDate: endDate,
                includedSections: Array(selectedSections),
                includeCharts: includeCharts,
                includeClinicBranding: includeClinicBranding
            )

            do {
                let report = try await reportService.generateReport(
                    configuration: configuration,
                    patient: patient,
                    branding: includeClinicBranding ? brandingService.branding : nil
                )

                generatedReport = report
                showSuccessAlert = true
            } catch {
                showError = true
            }
        }
    }
}

// MARK: - Quick Preset Button

struct QuickPresetButton: View {
    let preset: ReportPreset
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: preset.icon)
                    .font(.title2)
                    .foregroundColor(preset.reportType.color)

                Text(preset.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 90, height: 80)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
        .accessibilityLabel("\(preset.name): \(preset.description)")
        .accessibilityHint("Applies this preset configuration")
    }
}

// MARK: - Report Type Card

struct ReportTypeCard: View {
    let type: ReportType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Image(systemName: type.icon)
                        .font(.title2)
                        .foregroundColor(type.color)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }

                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(type.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            .padding()
            .background(isSelected ? type.color.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
            )
        }
        .accessibilityLabel("\(type.displayName): \(type.description)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Section Toggle Row

struct SectionToggleRow: View {
    let section: ReportSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: section.icon)
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 24)

                Text(section.displayName)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)
        }
        .accessibilityLabel("\(section.displayName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Toggle to \(isSelected ? "exclude" : "include") this section")
    }
}

// MARK: - Preview

#if DEBUG
struct ReportBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        ReportBuilderView(patient: Patient.samplePatients[0])
            .environmentObject(AppState())
    }
}
#endif
