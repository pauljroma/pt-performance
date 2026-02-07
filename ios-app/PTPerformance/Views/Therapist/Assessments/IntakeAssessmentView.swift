//
//  IntakeAssessmentView.swift
//  PTPerformance
//
//  Multi-section form for initial patient evaluation including
//  patient history, physical examination, ROM measurements, pain assessment,
//  functional tests, goals, and assessment summary.
//

import SwiftUI

/// Initial evaluation view for comprehensive patient intake assessment
/// Includes progress tracking, auto-save, and sign workflow
struct IntakeAssessmentView: View {
    // MARK: - Properties

    @StateObject private var viewModel: IntakeAssessmentViewModel
    @Environment(\.dismiss) private var dismiss

    // Section expansion state
    @State private var expandedSections: Set<AssessmentFormSection> = [.patientHistory]
    @State private var showingROMSheet = false
    @State private var showingFunctionalTestSheet = false
    @State private var showingSignatureConfirmation = false

    // MARK: - Initialization

    init(patientId: UUID, therapistId: UUID) {
        _viewModel = StateObject(wrappedValue: {
            let vm = IntakeAssessmentViewModel()
            vm.initializeNewAssessment(patientId: patientId, therapistId: therapistId)
            return vm
        }())
    }

    init(assessment: ClinicalAssessment) {
        _viewModel = StateObject(wrappedValue: {
            let vm = IntakeAssessmentViewModel()
            vm.loadAssessment(assessment)
            return vm
        }())
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Progress indicator
                        progressSection

                        // Form sections
                        patientHistorySection

                        physicalExamSection

                        romSection

                        painAssessmentSection

                        functionalTestsSection

                        goalsSection

                        assessmentSummarySection

                        // Action buttons
                        actionButtonsSection
                    }
                    .padding()
                }
                .disabled(viewModel.isSaving)

                // Loading overlay
                if viewModel.isSaving {
                    savingOverlay
                }
            }
            .navigationTitle("Initial Evaluation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            Task { await viewModel.saveDraft() }
                        } label: {
                            Label("Save Draft", systemImage: "square.and.arrow.down")
                        }

                        if viewModel.canSign {
                            Button {
                                showingSignatureConfirmation = true
                            } label: {
                                Label("Sign Assessment", systemImage: "signature")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingROMSheet) {
                AddROMMeasurementSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingFunctionalTestSheet) {
                AddFunctionalTestSheet(viewModel: viewModel)
            }
            .alert("Sign Assessment", isPresented: $showingSignatureConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign") {
                    Task { await viewModel.signAssessment() }
                }
            } message: {
                Text("Once signed, this assessment cannot be edited. Are you sure you want to sign?")
            }
            .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
                Button("OK") {
                    viewModel.clearMessages()
                    if viewModel.currentAssessment?.status == .signed {
                        dismiss()
                    }
                }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) {
                    viewModel.clearMessages()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Completion Progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(viewModel.sectionStatus.completionPercentage))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(progressColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * (viewModel.sectionStatus.completionPercentage / 100), height: 8)
                        .animation(.easeInOut, value: viewModel.sectionStatus.completionPercentage)
                }
            }
            .frame(height: 8)

            // Section completion indicators
            HStack(spacing: 8) {
                completionIndicator(title: "Subjective", isComplete: viewModel.sectionStatus.subjectiveComplete)
                completionIndicator(title: "Objective", isComplete: viewModel.sectionStatus.objectiveComplete)
                completionIndicator(title: "Pain", isComplete: viewModel.sectionStatus.painComplete)
                completionIndicator(title: "ROM", isComplete: viewModel.sectionStatus.romComplete)
                completionIndicator(title: "Tests", isComplete: viewModel.sectionStatus.functionalTestsComplete)
                completionIndicator(title: "A/P", isComplete: viewModel.sectionStatus.assessmentComplete && viewModel.sectionStatus.planComplete)
            }

            // Auto-save indicator
            if let lastSave = viewModel.lastAutoSaveDate {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Auto-saved \(lastSave, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func completionIndicator(title: String, isComplete: Bool) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isComplete ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 12, height: 12)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var progressColor: Color {
        let percentage = viewModel.sectionStatus.completionPercentage
        if percentage >= 80 { return .green }
        if percentage >= 50 { return .orange }
        return .red
    }

    // MARK: - Patient History Section

    private var patientHistorySection: some View {
        CollapsibleSection(
            title: "Patient History",
            icon: "person.text.rectangle",
            isExpanded: expandedSections.contains(.patientHistory),
            hasError: viewModel.subjectiveError != nil
        ) {
            toggleSection(.patientHistory)
        } content: {
            VStack(alignment: .leading, spacing: 16) {
                // Chief Complaint
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chief Complaint")
                        .font(.subheadline.weight(.medium))
                    TextEditor(text: $viewModel.chiefComplaint)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                    if let error = viewModel.subjectiveError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                // History of Present Illness
                VStack(alignment: .leading, spacing: 8) {
                    Text("History of Present Illness")
                        .font(.subheadline.weight(.medium))
                    TextEditor(text: $viewModel.historyOfPresentIllness)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                }

                // Past Medical History
                VStack(alignment: .leading, spacing: 8) {
                    Text("Past Medical History")
                        .font(.subheadline.weight(.medium))
                    TextEditor(text: $viewModel.pastMedicalHistory)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Physical Exam Section

    private var physicalExamSection: some View {
        CollapsibleSection(
            title: "Physical Examination",
            icon: "stethoscope",
            isExpanded: expandedSections.contains(.physicalExam),
            hasError: viewModel.objectiveError != nil
        ) {
            toggleSection(.physicalExam)
        } content: {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Objective Findings")
                        .font(.subheadline.weight(.medium))
                    TextEditor(text: $viewModel.objectiveFindings)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                    if let error = viewModel.objectiveError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Text("Include observation, palpation, special tests, and neurological findings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - ROM Section

    private var romSection: some View {
        CollapsibleSection(
            title: "ROM Measurements",
            icon: "ruler",
            isExpanded: expandedSections.contains(.rom),
            hasError: viewModel.romError != nil,
            badge: viewModel.romMeasurements.isEmpty ? nil : "\(viewModel.romMeasurements.count)"
        ) {
            toggleSection(.rom)
        } content: {
            VStack(alignment: .leading, spacing: 16) {
                // ROM measurement list
                if viewModel.romMeasurements.isEmpty {
                    EmptyMeasurementCard(
                        title: "No ROM Measurements",
                        message: "Add range of motion measurements to document joint mobility.",
                        action: { showingROMSheet = true }
                    )
                } else {
                    ForEach(viewModel.romMeasurements) { measurement in
                        ROMMeasurementCard(measurement: measurement) {
                            viewModel.removeROMMeasurement(measurement)
                        }
                    }

                    // Summary
                    if viewModel.romLimitationsCount > 0 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("\(viewModel.romLimitationsCount) limitation(s) identified")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }

                // Add button
                Button {
                    showingROMSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add ROM Measurement")
                    }
                    .font(.subheadline.weight(.medium))
                }
            }
        }
    }

    // MARK: - Pain Assessment Section

    private var painAssessmentSection: some View {
        CollapsibleSection(
            title: "Pain Assessment",
            icon: "bolt.fill",
            isExpanded: expandedSections.contains(.pain),
            hasError: viewModel.painError != nil
        ) {
            toggleSection(.pain)
        } content: {
            VStack(alignment: .leading, spacing: 20) {
                // Pain scales
                VStack(spacing: 16) {
                    painSlider(title: "Pain at Rest", value: $viewModel.painAtRest, color: .blue)
                    painSlider(title: "Pain with Activity", value: $viewModel.painWithActivity, color: .orange)
                    painSlider(title: "Worst Pain", value: $viewModel.painWorst, color: .red)
                }

                // Pain concern indicator
                if viewModel.isPainConcerning {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("High pain levels may require additional intervention")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
                }

                Divider()

                // Pain locations
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pain Locations")
                        .font(.subheadline.weight(.medium))

                    // Existing locations
                    FlowLayout(spacing: 8) {
                        ForEach(Array(viewModel.painLocations.enumerated()), id: \.offset) { index, location in
                            HStack(spacing: 4) {
                                Text(location)
                                    .font(.caption)
                                Button {
                                    viewModel.removePainLocation(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.red.opacity(0.15))
                            )
                            .foregroundColor(.red)
                        }
                    }

                    // Add new location
                    HStack {
                        TextField("Add pain location...", text: $viewModel.newPainLocation)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            viewModel.addPainLocation()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(viewModel.newPainLocation.isEmpty)
                    }
                }
            }
        }
    }

    private func painSlider(title: String, value: Binding<Int>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(value.wrappedValue)/10")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(painScoreColor(value.wrappedValue))
            }

            Slider(value: Binding(
                get: { Double(value.wrappedValue) },
                set: { value.wrappedValue = Int($0) }
            ), in: 0...10, step: 1)
            .tint(painScoreColor(value.wrappedValue))
        }
    }

    private func painScoreColor(_ score: Int) -> Color {
        switch score {
        case 0...3: return .green
        case 4...6: return .orange
        default: return .red
        }
    }

    // MARK: - Functional Tests Section

    private var functionalTestsSection: some View {
        CollapsibleSection(
            title: "Functional Tests",
            icon: "figure.walk",
            isExpanded: expandedSections.contains(.functionalTests),
            badge: viewModel.functionalTests.isEmpty ? nil : "\(viewModel.functionalTests.count)"
        ) {
            toggleSection(.functionalTests)
        } content: {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.functionalTests.isEmpty {
                    EmptyMeasurementCard(
                        title: "No Functional Tests",
                        message: "Add special tests and functional assessments.",
                        action: { showingFunctionalTestSheet = true }
                    )
                } else {
                    ForEach(viewModel.functionalTests) { test in
                        FunctionalTestCard(test: test) {
                            viewModel.removeFunctionalTest(test)
                        }
                    }

                    // Abnormal tests summary
                    if viewModel.abnormalTestsCount > 0 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("\(viewModel.abnormalTestsCount) abnormal finding(s)")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }

                Button {
                    showingFunctionalTestSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Functional Test")
                    }
                    .font(.subheadline.weight(.medium))
                }
            }
        }
    }

    // MARK: - Goals Section

    private var goalsSection: some View {
        CollapsibleSection(
            title: "Functional Goals",
            icon: "target",
            isExpanded: expandedSections.contains(.goals),
            badge: viewModel.functionalGoals.isEmpty ? nil : "\(viewModel.functionalGoals.count)"
        ) {
            toggleSection(.goals)
        } content: {
            VStack(alignment: .leading, spacing: 16) {
                // Existing goals
                if !viewModel.functionalGoals.isEmpty {
                    ForEach(Array(viewModel.functionalGoals.enumerated()), id: \.offset) { index, goal in
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                            Text(goal)
                                .font(.subheadline)
                            Spacer()
                            Button {
                                viewModel.removeGoal(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.tertiarySystemGroupedBackground))
                        )
                    }
                }

                // Add new goal
                HStack {
                    TextField("Add functional goal...", text: $viewModel.newGoal)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        viewModel.addGoal()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.newGoal.isEmpty)
                }

                Text("Goals should be specific, measurable, and patient-centered.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Assessment Summary Section

    private var assessmentSummarySection: some View {
        CollapsibleSection(
            title: "Assessment & Plan",
            icon: "doc.text.fill",
            isExpanded: expandedSections.contains(.assessmentSummary),
            hasError: viewModel.assessmentError != nil
        ) {
            toggleSection(.assessmentSummary)
        } content: {
            VStack(alignment: .leading, spacing: 16) {
                // Assessment Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Assessment Summary")
                        .font(.subheadline.weight(.medium))
                    TextEditor(text: $viewModel.assessmentSummary)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                }

                // Treatment Plan
                VStack(alignment: .leading, spacing: 8) {
                    Text("Treatment Plan")
                        .font(.subheadline.weight(.medium))
                    TextEditor(text: $viewModel.treatmentPlan)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                    if let error = viewModel.assessmentError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Text("Include diagnosis, prognosis, recommended frequency, and expected duration.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Status indicator
            if let assessment = viewModel.currentAssessment {
                HStack {
                    Image(systemName: assessment.status.iconName)
                        .foregroundColor(assessment.status.color)
                    Text("Status: \(assessment.status.displayName)")
                        .font(.subheadline)
                        .foregroundColor(assessment.status.color)
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(assessment.status.color.opacity(0.1))
                )
            }

            // Save Draft Button
            Button {
                Task { await viewModel.saveDraft() }
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save Draft")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canSaveDraft)

            // Submit Button
            Button {
                Task { await viewModel.submitAssessment() }
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Submit Assessment")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canSubmit ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canSubmit)

            // Sign Button
            if viewModel.canSign {
                Button {
                    showingSignatureConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "signature")
                        Text("Sign Assessment")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Saving Overlay

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Saving...")
                    .font(.headline)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
        }
    }

    // MARK: - Helpers

    private func toggleSection(_ section: AssessmentFormSection) {
        withAnimation {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }
}

// MARK: - Assessment Form Section Enum

private enum AssessmentFormSection: Hashable {
    case patientHistory
    case physicalExam
    case rom
    case pain
    case functionalTests
    case goals
    case assessmentSummary
}

// MARK: - Collapsible Section

private struct CollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    let isExpanded: Bool
    var hasError: Bool = false
    var badge: String? = nil
    let toggleAction: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Button(action: toggleAction) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(hasError ? .red : .blue)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let badge = badge {
                        Text(badge)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.blue.opacity(0.2)))
                            .foregroundColor(.blue)
                    }

                    if hasError {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    content
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
            }
        }
        .cornerRadius(12)
    }
}

// MARK: - Empty Measurement Card

private struct EmptyMeasurementCard: View {
    let title: String
    let message: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.dashed")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(title)
                .font(.subheadline.weight(.medium))
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Add", action: action)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundColor(.secondary.opacity(0.5))
        )
    }
}

// MARK: - ROM Measurement Card

private struct ROMMeasurementCard: View {
    let measurement: ROMeasurement
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(measurement.displayTitle)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 8) {
                    Text(measurement.formattedMeasurement)
                        .font(.headline)
                        .foregroundColor(measurement.statusColor)
                    Text("/ \(measurement.formattedNormalRange)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if measurement.painWithMovement == true {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                        Text("Pain with movement")
                            .font(.caption)
                    }
                    .foregroundColor(.red)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(measurement.limitationSeverity.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(measurement.statusColor.opacity(0.2))
                    )
                    .foregroundColor(measurement.statusColor)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }
}

// MARK: - Functional Test Card

private struct FunctionalTestCard: View {
    let test: FunctionalTest
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(test.testName)
                    .font(.subheadline.weight(.medium))
                Text("Result: \(test.result)")
                    .font(.caption)
                    .foregroundColor(test.isAbnormal ? .red : .green)
                if let interpretation = test.interpretation {
                    Text(interpretation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }
}

// MARK: - Add ROM Measurement Sheet

private struct AddROMMeasurementSheet: View {
    @ObservedObject var viewModel: IntakeAssessmentViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedJoint: JointType = .shoulder
    @State private var selectedMovement: MovementType = .flexion
    @State private var degrees: Int = 90
    @State private var side: Side = .right
    @State private var painWithMovement = false
    @State private var endFeel = ""
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Joint & Movement") {
                    Picker("Joint", selection: $selectedJoint) {
                        ForEach(JointType.allCases) { joint in
                            Text(joint.displayName).tag(joint)
                        }
                    }

                    Picker("Movement", selection: $selectedMovement) {
                        ForEach(selectedJoint.availableMovements) { movement in
                            Text(movement.displayName).tag(movement)
                        }
                    }

                    Picker("Side", selection: $side) {
                        ForEach(Side.allCases) { sideOption in
                            Text(sideOption.displayName).tag(sideOption)
                        }
                    }
                }

                Section("Measurement") {
                    Stepper("Degrees: \(degrees)", value: $degrees, in: 0...180, step: 5)

                    if let normalRange = ROMNormalReference.normalRange(joint: selectedJoint.rawValue, movement: selectedMovement.rawValue) {
                        HStack {
                            Text("Normal Range")
                            Spacer()
                            Text("\(normalRange.lowerBound) - \(normalRange.upperBound)")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Additional Information") {
                    Toggle("Pain with Movement", isOn: $painWithMovement)

                    TextField("End Feel", text: $endFeel)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add ROM Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") {
                        viewModel.addROMMeasurement(
                            joint: selectedJoint.rawValue,
                            movement: selectedMovement.rawValue,
                            degrees: degrees,
                            side: side,
                            painWithMovement: painWithMovement,
                            endFeel: endFeel.isEmpty ? nil : endFeel,
                            notes: notes.isEmpty ? nil : notes
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Functional Test Sheet

private struct AddFunctionalTestSheet: View {
    @ObservedObject var viewModel: IntakeAssessmentViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var testName = ""
    @State private var result = "Negative"
    @State private var interpretation = ""
    @State private var notes = ""

    let commonTests = [
        "Hawkins-Kennedy Test",
        "Neer Test",
        "Empty Can Test",
        "Apprehension Test",
        "Lachman Test",
        "Anterior Drawer Test",
        "McMurray Test",
        "Thomas Test",
        "FABER Test",
        "Spurling Test",
        "Straight Leg Raise"
    ]

    var body: some View {
        NavigationView {
            Form {
                Section("Test Information") {
                    Picker("Test Name", selection: $testName) {
                        Text("Select a test").tag("")
                        ForEach(commonTests, id: \.self) { test in
                            Text(test).tag(test)
                        }
                    }

                    if testName.isEmpty {
                        TextField("Or enter custom test name", text: $testName)
                    }
                }

                Section("Result") {
                    Picker("Result", selection: $result) {
                        Text("Positive").tag("Positive")
                        Text("Negative").tag("Negative")
                        Text("Equivocal").tag("Equivocal")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Interpretation") {
                    TextField("Clinical interpretation...", text: $interpretation, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Notes") {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Functional Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") {
                        viewModel.addFunctionalTest(
                            testName: testName,
                            result: result,
                            interpretation: interpretation.isEmpty ? nil : interpretation,
                            notes: notes.isEmpty ? nil : notes
                        )
                        dismiss()
                    }
                    .disabled(testName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Flow Layout

private struct IAFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return CGSize(width: containerWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}

// MARK: - Preview

#if DEBUG
struct IntakeAssessmentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            IntakeAssessmentView(patientId: UUID(), therapistId: UUID())
                .previewDisplayName("New Assessment")

            IntakeAssessmentView(patientId: UUID(), therapistId: UUID())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif
