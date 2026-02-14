//
//  EnhancedProgramBuilderView.swift
//  PTPerformance
//
//  Enhanced step-by-step wizard for building programs
//  7 steps: Start, Template (conditional), Patient, Basics, Phases, Workouts, Preview
//

import SwiftUI

struct EnhancedProgramBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TherapistProgramBuilderViewModel()

    @State private var showPhaseEditor = false
    @State private var editingPhaseIndex: Int?
    @State private var showPatientPicker = false
    @State private var showPublishConfirmation = false
    @State private var showDiscardChangesAlert = false
    @State private var showUnsavedWorkAlert = false
    @State private var pendingBackNavigation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator (hide on start, quickBuildPicker, templatePicker, and preview)
                    if viewModel.currentStep != .start && viewModel.currentStep != .quickBuildPicker && viewModel.currentStep != .templatePicker && viewModel.currentStep != .preview {
                        BuilderProgressIndicator(currentStep: viewModel.currentStep)
                            .padding(.top, 8)
                            .padding(.horizontal)
                    }

                    // Step content
                    TabView(selection: $viewModel.currentStep) {
                        StartStepView(
                            selectedMode: $viewModel.creationMode
                        )
                        .tag(TherapistProgramBuilderViewModel.BuilderStep.start)

                        QuickBuildPickerStepView(viewModel: viewModel)
                            .tag(TherapistProgramBuilderViewModel.BuilderStep.quickBuildPicker)

                        TemplatePickerStepView(viewModel: viewModel)
                            .tag(TherapistProgramBuilderViewModel.BuilderStep.templatePicker)

                        PatientStepView(
                            selectedPatient: $viewModel.selectedPatient,
                            showPatientPicker: $showPatientPicker
                        )
                        .tag(TherapistProgramBuilderViewModel.BuilderStep.patient)

                        BasicsStepView(viewModel: viewModel)
                            .tag(TherapistProgramBuilderViewModel.BuilderStep.basics)

                        PhasesStepView(
                            viewModel: viewModel,
                            showPhaseEditor: $showPhaseEditor,
                            editingPhaseIndex: $editingPhaseIndex
                        )
                        .tag(TherapistProgramBuilderViewModel.BuilderStep.phases)

                        WorkoutsStepView(
                            viewModel: viewModel,
                            showPhaseEditor: $showPhaseEditor,
                            editingPhaseIndex: $editingPhaseIndex
                        )
                        .tag(TherapistProgramBuilderViewModel.BuilderStep.workouts)

                        PreviewStepView(
                            viewModel: viewModel,
                            showPublishConfirmation: $showPublishConfirmation
                        )
                        .tag(TherapistProgramBuilderViewModel.BuilderStep.preview)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: viewModel.currentStep)

                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }

                    // Navigation buttons
                    navigationButtons
                }

                // Loading overlay for async operations
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(1.2)
                                    .tint(.white)

                                Text("Loading...")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding(Spacing.lg)
                            .background(Color(.systemGray3).opacity(0.9))
                            .cornerRadius(CornerRadius.lg)
                        )
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        handleCancel()
                    }
                }
            }
            .sheet(isPresented: $showPhaseEditor) {
                if let index = editingPhaseIndex, index < viewModel.phases.count {
                    PhaseEditorSheet(
                        phase: $viewModel.phases[index],
                        phaseNumber: index + 1,
                        isPresented: $showPhaseEditor
                    )
                }
            }
            .sheet(isPresented: $showPatientPicker) {
                PatientPickerSheet { patient in
                    viewModel.selectedPatient = patient
                }
            }
            .alert("Publish to Library?", isPresented: $showPublishConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Publish") {
                    Task {
                        await publishToLibrary()
                    }
                }
            } message: {
                Text("This will make the program available for patients to browse and enroll. You can edit or unpublish it later.")
            }
            .alert("Discard Changes?", isPresented: $showDiscardChangesAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard your program?")
            }
            .alert("Go Back?", isPresented: $showUnsavedWorkAlert) {
                Button("Cancel", role: .cancel) {
                    pendingBackNavigation = false
                }
                Button("Go Back", role: .destructive) {
                    pendingBackNavigation = false
                    viewModel.previousStep()
                }
            } message: {
                Text("Going back may lose some of your work on this step. Continue?")
            }
        }
    }

    // MARK: - Cancel with Confirmation

    private func handleCancel() {
        if viewModel.hasUnsavedChanges {
            showDiscardChangesAlert = true
        } else {
            dismiss()
        }
    }

    // MARK: - Back with Confirmation

    private func handleBack() {
        if viewModel.wouldLoseWorkGoingBack() {
            showUnsavedWorkAlert = true
        } else {
            viewModel.previousStep()
        }
    }

    // MARK: - Step Title

    private var stepTitle: String {
        switch viewModel.currentStep {
        case .start:
            return "Create Program"
        case .quickBuildPicker:
            return "Quick Build"
        case .templatePicker:
            return "Choose Template"
        case .patient:
            return "Select Patient"
        case .basics:
            return "Program Details"
        case .phases:
            return "Add Phases"
        case .workouts:
            return "Assign Workouts"
        case .preview:
            return "Review & Publish"
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back button
            if viewModel.currentStep != .start {
                Button(action: {
                    handleBack()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.modusCyan)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.md)
                }
                .accessibilityLabel("Go back to previous step")
            }

            // Continue/Finish button
            Button(action: {
                if viewModel.currentStep == .preview {
                    showPublishConfirmation = true
                } else {
                    viewModel.nextStep()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(continueButtonText)
                        if viewModel.currentStep != .preview {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(viewModel.canProceed ? Color.modusCyan : Color.gray)
                .cornerRadius(CornerRadius.md)
            }
            .disabled(!viewModel.canProceed || viewModel.isLoading)
            .accessibilityLabel(viewModel.currentStep == .preview ? "Publish program" : "Continue to next step")
            .accessibilityHint(viewModel.canProceed ? "" : "Complete required fields to continue")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }

    private var continueButtonText: String {
        switch viewModel.currentStep {
        case .start:
            return "Get Started"
        case .quickBuildPicker:
            return "Use Template"
        case .templatePicker:
            return "Use Template"
        case .preview:
            return "Publish Program"
        default:
            return "Continue"
        }
    }

    // MARK: - Actions

    private func publishToLibrary() async {
        do {
            try await viewModel.publishToLibrary()
            dismiss()
        } catch {
            // Error is already handled in viewModel
        }
    }
}

// MARK: - Start Step View

private struct StartStepView: View {
    @Binding var selectedMode: TherapistProgramBuilderViewModel.CreationMode

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.modusCyan)
                        .padding(.bottom, 8)
                        .accessibilityHidden(true)

                    Text("How would you like to build?")
                        .font(.system(size: 28, weight: .bold))
                        .accessibilityAddTraits(.isHeader)

                    Text("Choose a starting point for your program")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                // Mode cards
                VStack(spacing: 16) {
                    CreationModeCard(
                        mode: .quickBuild,
                        isSelected: selectedMode == .quickBuild,
                        onTap: { selectedMode = .quickBuild }
                    )

                    CreationModeCard(
                        mode: .fromTemplate,
                        isSelected: selectedMode == .fromTemplate,
                        onTap: { selectedMode = .fromTemplate }
                    )

                    CreationModeCard(
                        mode: .custom,
                        isSelected: selectedMode == .custom,
                        onTap: { selectedMode = .custom }
                    )
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Creation Mode Card

private struct CreationModeCard: View {
    let mode: TherapistProgramBuilderViewModel.CreationMode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: mode.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : .modusCyan)
                    .frame(width: 56, height: 56)
                    .background(isSelected ? Color.modusCyan : Color.modusCyan.opacity(0.1))
                    .cornerRadius(CornerRadius.md)

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(mode.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.modusCyan)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.modusCyan : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.title). \(mode.description)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Quick Build Picker Step View

private struct QuickBuildPickerStepView: View {
    @ObservedObject var viewModel: TherapistProgramBuilderViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundColor(.modusCyan)
                        .padding(.bottom, 8)
                        .accessibilityHidden(true)

                    Text("Quick Build Templates")
                        .font(.system(size: 28, weight: .bold))
                        .accessibilityAddTraits(.isHeader)

                    Text("Choose a pre-built template to get started quickly")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 24)

                // Template cards grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)], spacing: 16) {
                    ForEach(QuickBuildTemplate.templates) { template in
                        QuickBuildTemplateSelectionCard(
                            template: template,
                            isSelected: viewModel.selectedQuickBuildTemplate?.id == template.id,
                            onTap: {
                                viewModel.applyQuickBuildTemplate(template)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Quick Build Template Selection Card

private struct QuickBuildTemplateSelectionCard: View {
    let template: QuickBuildTemplate
    let isSelected: Bool
    let onTap: () -> Void

    private var typeColor: Color {
        switch template.type {
        case "rehab": return .blue
        case "performance": return .orange
        case "strength": return .green
        case "custom": return .purple
        default: return .gray
        }
    }

    private var difficultyColor: Color {
        switch template.difficultyLevel {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .gray
        }
    }

    private var difficultyIcon: String {
        switch template.difficultyLevel {
        case "beginner": return "1.circle.fill"
        case "intermediate": return "2.circle.fill"
        case "advanced": return "3.circle.fill"
        default: return "circle.fill"
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon and type badge
                HStack {
                    ZStack {
                        Circle()
                            .fill(isSelected ? typeColor : typeColor.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: template.icon)
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? .white : typeColor)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.modusCyan)
                    }
                }

                // Title
                Text(template.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Description
                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                Spacer(minLength: 0)

                // Template details
                if template.type != "custom" {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Label("\(template.durationWeeks)W", systemImage: "calendar")
                                .font(.caption2)
                            Label("\(template.phases.count) phases", systemImage: "list.bullet")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Label("\(template.workoutsPerWeek)x/week", systemImage: "figure.strengthtraining.traditional")
                                .font(.caption2)
                            Label(template.difficultyLevel.capitalized, systemImage: difficultyIcon)
                                .font(.caption2)
                                .foregroundColor(difficultyColor)
                        }
                        .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("Blank slate")
                            .font(.caption2)
                    }
                    .foregroundColor(.purple)
                }
            }
            .padding(Spacing.md)
            .frame(minHeight: 180)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.modusCyan : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(template.name). \(template.description)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Template Picker Step View

private struct TemplatePickerStepView: View {
    @ObservedObject var viewModel: TherapistProgramBuilderViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 60))
                    .foregroundColor(.modusCyan)
                    .padding(.bottom, 8)

                Text("Choose a Template")
                    .font(.system(size: 28, weight: .bold))

                Text("Select an existing program to use as your starting point")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search templates...", text: $viewModel.templateSearchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocorrectionDisabled()

                if !viewModel.templateSearchText.isEmpty {
                    Button {
                        viewModel.templateSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(Spacing.sm)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Content
            if viewModel.isLoadingTemplates {
                Spacer()
                ProgramLoadingView("Loading templates...")
                Spacer()
            } else if viewModel.templateLoadFailed {
                // Error state with retry button
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)

                    Text("Unable to Load Templates")
                        .font(.headline)

                    Text("Check your internet connection and try again.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button {
                        Task {
                            await viewModel.retryLoadTemplates()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.modusCyan)
                        .cornerRadius(CornerRadius.sm)
                    }
                    .accessibilityLabel("Retry loading templates")
                }
                Spacer()
            } else if viewModel.filteredTemplates.isEmpty {
                Spacer()
                ProgramEmptyStateView.noTemplates(searchText: viewModel.templateSearchText)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredTemplates) { template in
                            ProgramTemplateCard(
                                template: template,
                                isSelected: viewModel.selectedTemplate?.id == template.id,
                                onTap: {
                                    Task {
                                        await viewModel.applyTemplate(template)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .task {
            await viewModel.loadTemplates()
        }
    }
}

// MARK: - Template Card

private struct ProgramTemplateCard: View {
    let template: ProgramLibrary
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Category icon
                Image(systemName: template.categoryIcon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .modusCyan)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? Color.modusCyan : Color.modusCyan.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)

                // Template info
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        // Category badge
                        Text(template.category.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .cornerRadius(CornerRadius.xs)

                        // Difficulty badge
                        Text(template.difficultyLevel.capitalized)
                            .font(.caption)
                            .foregroundColor(template.difficultyColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(template.difficultyColor.opacity(0.1))
                            .cornerRadius(CornerRadius.xs)

                        // Duration
                        Text(template.formattedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let description = template.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.modusCyan)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.modusCyan : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(template.title). \(template.category) program. \(template.difficultyLevel) difficulty. \(template.formattedDuration).")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Patient Step View

private struct PatientStepView: View {
    @Binding var selectedPatient: Patient?
    @Binding var showPatientPicker: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.modusCyan)
                        .padding(.bottom, 8)

                    Text("Assign to Patient")
                        .font(.system(size: 28, weight: .bold))

                    Text("Optional: Create this program for a specific patient")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 32)

                // Selected patient or picker button
                VStack(spacing: 16) {
                    if let patient = selectedPatient {
                        // Selected patient card
                        SelectedPatientCard(patient: patient) {
                            selectedPatient = nil
                        }
                    }

                    Button(action: {
                        showPatientPicker = true
                    }) {
                        HStack {
                            Image(systemName: selectedPatient == nil ? "person.badge.plus" : "arrow.triangle.2.circlepath")
                            Text(selectedPatient == nil ? "Select a Patient" : "Change Patient")
                        }
                        .font(.headline)
                        .foregroundColor(.modusCyan)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.modusCyan.opacity(0.1))
                        .cornerRadius(CornerRadius.md)
                    }

                    // Skip option
                    Text("You can skip this step to create a general program for your library")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Selected Patient Card

private struct SelectedPatientCard: View {
    let patient: Patient
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(Color.modusCyan.opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(patient.initials)
                        .font(.title2.bold())
                        .foregroundColor(.modusCyan)
                )
                .accessibilityHidden(true)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(patient.fullName)
                    .font(.headline)

                if let condition = patient.injuryType {
                    Text(condition)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if let sport = patient.sport {
                    Text(sport)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Remove patient")
            .accessibilityHint("Deselects \(patient.fullName) from this program")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.modusCyan, lineWidth: 2)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Selected patient: \(patient.fullName)")
    }
}

// MARK: - Basics Step View

private struct BasicsStepView: View {
    @ObservedObject var viewModel: TherapistProgramBuilderViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Program Details")
                        .font(.system(size: 28, weight: .bold))
                        .accessibilityAddTraits(.isHeader)

                    Text("Enter the basic information for your program")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)

                // Form fields
                VStack(spacing: 16) {
                    // Program name
                    FormField(title: "Program Name") {
                        TextField("Enter program name", text: $viewModel.programName)
                            .textInputAutocapitalization(.words)
                            .accessibilityLabel("Program name")
                            .accessibilityHint("Enter a descriptive name for your program")
                    }

                    // Description
                    FormField(title: "Description") {
                        TextEditor(text: $viewModel.description)
                            .frame(minHeight: 80)
                            .padding(Spacing.xs)
                            .background(Color(.systemBackground))
                            .cornerRadius(CornerRadius.sm)
                            .accessibilityLabel("Program description")
                            .accessibilityHint("Optional description of the program goals")
                    }

                    // Category picker
                    FormField(title: "Category") {
                        Picker("Category", selection: $viewModel.category) {
                            ForEach(ProgramCategory.allCases, id: \.self) { category in
                                Label(category.displayName, systemImage: category.icon)
                                    .tag(category.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Difficulty picker
                    FormField(title: "Difficulty Level") {
                        Picker("Difficulty", selection: $viewModel.difficultyLevel) {
                            ForEach(DifficultyLevel.allCases, id: \.self) { level in
                                Text(level.displayName)
                                    .tag(level.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Difficulty level")
                        .accessibilityValue(viewModel.difficultyLevel.capitalized)
                    }

                    // Duration
                    FormField(title: "Duration") {
                        Stepper(
                            "\(viewModel.durationWeeks) \(viewModel.durationWeeks == 1 ? "week" : "weeks")",
                            value: $viewModel.durationWeeks,
                            in: 1...52
                        )
                        .accessibilityLabel("Program duration")
                        .accessibilityValue("\(viewModel.durationWeeks) weeks")
                        .accessibilityHint("Adjust duration between 1 and 52 weeks")
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Form Field Helper

private struct FormField<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            content
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Phases Step View

private struct PhasesStepView: View {
    @ObservedObject var viewModel: TherapistProgramBuilderViewModel
    @Binding var showPhaseEditor: Bool
    @Binding var editingPhaseIndex: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Program Phases")
                        .font(.system(size: 28, weight: .bold))
                        .accessibilityAddTraits(.isHeader)

                    Text("Add phases to structure your program progression")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                // Phases list
                VStack(spacing: 12) {
                    if viewModel.phases.isEmpty {
                        EmptyPhasesCard()
                    } else {
                        ForEach(Array(viewModel.phases.enumerated()), id: \.element.id) { index, phase in
                            PhaseCard(
                                phase: phase,
                                phaseNumber: index + 1,
                                onEdit: {
                                    editingPhaseIndex = index
                                    showPhaseEditor = true
                                },
                                onDelete: {
                                    viewModel.deletePhase(at: index)
                                }
                            )
                        }
                    }

                    // Add phase button
                    Button(action: {
                        viewModel.addPhase()
                        editingPhaseIndex = viewModel.phases.count - 1
                        showPhaseEditor = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Phase")
                        }
                        .font(.headline)
                        .foregroundColor(.modusCyan)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.modusCyan.opacity(0.1))
                        .cornerRadius(CornerRadius.md)
                    }
                    .accessibilityLabel("Add phase")
                    .accessibilityHint("Creates a new phase for your program")
                }
                .padding(.horizontal, 20)

                // Total duration
                if !viewModel.phases.isEmpty {
                    Text("Total Duration: \(viewModel.totalPhaseDuration) weeks")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Total program duration: \(viewModel.totalPhaseDuration) weeks")
                }

                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Empty Phases Card

private struct EmptyPhasesCard: View {
    var body: some View {
        ProgramEmptyStateView.noPhases()
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Phase Card

private struct PhaseCard: View {
    let phase: TherapistPhaseData
    let phaseNumber: Int
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var phaseColor: Color {
        let colors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal]
        return colors[(phaseNumber - 1) % colors.count]
    }

    private var phaseName: String {
        phase.name.isEmpty ? "Phase \(phaseNumber)" : phase.name
    }

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 16) {
                // Phase number badge
                Text("\(phaseNumber)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(phaseColor))
                    .accessibilityHidden(true)

                // Phase info
                VStack(alignment: .leading, spacing: 4) {
                    Text(phaseName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Label("\(phase.durationWeeks) weeks", systemImage: "calendar")
                        Label("\(phase.workoutAssignments.count) workouts", systemImage: "figure.strengthtraining.traditional")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Edit/delete actions
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Phase options")
                .accessibilityHint("Opens menu with edit and delete options")
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.lg)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(phaseName), \(phase.durationWeeks) weeks, \(phase.workoutAssignments.count) workouts")
        .accessibilityHint("Double tap to edit phase details")
    }
}

// MARK: - Workouts Step View

private struct WorkoutsStepView: View {
    @ObservedObject var viewModel: TherapistProgramBuilderViewModel
    @Binding var showPhaseEditor: Bool
    @Binding var editingPhaseIndex: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Assign Workouts")
                        .font(.system(size: 28, weight: .bold))
                        .accessibilityAddTraits(.isHeader)

                    Text("Add workouts to each phase of your program")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                // Phases with workout counts
                if viewModel.phases.isEmpty {
                    ProgramErrorView(
                        title: "No Phases Added",
                        message: "Go back and add phases before assigning workouts.",
                        icon: "exclamationmark.triangle",
                        iconColor: .orange
                    )
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)
                    .padding(.horizontal, 20)
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.phases.enumerated()), id: \.element.id) { index, phase in
                            PhaseWorkoutCard(
                                phase: phase,
                                phaseNumber: index + 1,
                                onTap: {
                                    editingPhaseIndex = index
                                    showPhaseEditor = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Total workouts
                let totalWorkouts = viewModel.phases.reduce(0) { $0 + $1.workoutAssignments.count }
                if totalWorkouts > 0 {
                    Text("Total Workouts: \(totalWorkouts)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Phase Workout Card

private struct PhaseWorkoutCard: View {
    let phase: TherapistPhaseData
    let phaseNumber: Int
    let onTap: () -> Void

    private var phaseColor: Color {
        let colors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal]
        return colors[(phaseNumber - 1) % colors.count]
    }

    private var phaseName: String {
        phase.name.isEmpty ? "Phase \(phaseNumber)" : phase.name
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text("\(phaseNumber)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(phaseColor))

                    Text(phaseName)
                        .font(.headline)

                    Spacer()

                    Text("\(phase.workoutAssignments.count) workouts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }

                // Workout summary or empty state
                if phase.workoutAssignments.isEmpty {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.modusCyan)
                        Text("Tap to add workouts")
                            .foregroundColor(.modusCyan)
                    }
                    .font(.subheadline)
                } else {
                    // Show first few workout names
                    let names = phase.workoutAssignments.prefix(3).map { $0.templateName }
                    Text(names.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.lg)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(phaseName), \(phase.workoutAssignments.count) workouts")
        .accessibilityHint(phase.workoutAssignments.isEmpty ? "Tap to add workouts" : "Tap to edit workouts")
    }
}

// MARK: - Preview Step View

private struct PreviewStepView: View {
    @ObservedObject var viewModel: TherapistProgramBuilderViewModel
    @Binding var showPublishConfirmation: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .padding(.bottom, 8)
                        .accessibilityHidden(true)

                    Text("Review Your Program")
                        .font(.system(size: 28, weight: .bold))
                        .accessibilityAddTraits(.isHeader)

                    Text("Make sure everything looks good before publishing")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                // Program summary
                VStack(spacing: 16) {
                    // Basic info
                    SummaryCard(title: "Program Details") {
                        SummaryRow(label: "Name", value: viewModel.programName)
                        if !viewModel.description.isEmpty {
                            SummaryRow(label: "Description", value: viewModel.description)
                        }
                        SummaryRow(label: "Category", value: viewModel.category.capitalized)
                        SummaryRow(label: "Difficulty", value: viewModel.difficultyLevel.capitalized)
                        SummaryRow(label: "Duration", value: "\(viewModel.totalPhaseDuration > 0 ? viewModel.totalPhaseDuration : viewModel.durationWeeks) weeks")
                    }

                    // Patient info (if selected)
                    if let patient = viewModel.selectedPatient {
                        SummaryCard(title: "Assigned Patient") {
                            SummaryRow(label: "Name", value: patient.fullName)
                            if let condition = patient.injuryType {
                                SummaryRow(label: "Condition", value: condition)
                            }
                        }
                    }

                    // Phases summary
                    SummaryCard(title: "Phases (\(viewModel.phases.count))") {
                        if viewModel.phases.isEmpty {
                            Text("No phases added")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(Array(viewModel.phases.enumerated()), id: \.element.id) { index, phase in
                                HStack {
                                    Text("Phase \(index + 1)")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(phase.durationWeeks) weeks, \(phase.workoutAssignments.count) workouts")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    // Validation warnings
                    if !viewModel.isReadyToPublish {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Add at least one phase with workouts to publish")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(CornerRadius.md)
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Summary Card

private struct SummaryCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Summary Row

private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Preview

#if DEBUG
struct EnhancedProgramBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedProgramBuilderView()
    }
}
#endif
