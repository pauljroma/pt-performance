//
//  TherapistPatientSetupView.swift
//  PTPerformance
//
//  Patient setup flow for therapists - create and configure new patients
//

import SwiftUI

/// Main therapist patient setup container view
struct TherapistPatientSetupView: View {
    @StateObject private var viewModel = TherapistPatientSetupViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    if viewModel.currentStep != .complete {
                        PatientSetupProgressView(currentStep: viewModel.currentStep)
                            .padding(.top, 8)
                            .padding(.horizontal)
                    }

                    // Content
                    TabView(selection: $viewModel.currentStep) {
                        BasicInfoStepView(viewModel: viewModel)
                            .tag(TherapistPatientSetupViewModel.SetupStep.basicInfo)

                        TherapistModeSelectionView(selectedMode: $viewModel.selectedMode)
                            .tag(TherapistPatientSetupViewModel.SetupStep.modeSelection)

                        TherapistGoalSelectionView(
                            availableGoals: viewModel.availableGoals,
                            selectedGoals: $viewModel.selectedGoals,
                            customGoalTitle: $viewModel.customGoalTitle,
                            customGoalDescription: $viewModel.customGoalDescription
                        )
                        .tag(TherapistPatientSetupViewModel.SetupStep.goalSelection)

                        TrainingContextStepView(viewModel: viewModel)
                            .tag(TherapistPatientSetupViewModel.SetupStep.trainingContext)

                        ReviewStepView(viewModel: viewModel)
                            .tag(TherapistPatientSetupViewModel.SetupStep.review)

                        PatientCreatedStepView(viewModel: viewModel)
                            .tag(TherapistPatientSetupViewModel.SetupStep.complete)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: viewModel.currentStep)

                    // Error message
                    if let error = viewModel.error {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }

                    // Navigation buttons
                    HStack(spacing: 16) {
                        if viewModel.canGoBack {
                            Button(action: {
                                viewModel.goToPreviousStep()
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
                                .cornerRadius(12)
                            }
                        }

                        Button(action: {
                            Task {
                                await viewModel.handleContinue()
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(viewModel.continueButtonText)
                                    if viewModel.currentStep != .complete && viewModel.currentStep != .review {
                                        Image(systemName: "chevron.right")
                                    }
                                }
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(viewModel.canContinue ? Color.modusCyan : Color.gray)
                            .cornerRadius(12)
                        }
                        .disabled(!viewModel.canContinue || viewModel.isLoading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Add Patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: viewModel.isComplete) { _, complete in
            if complete {
                dismiss()
            }
        }
        .interactiveDismissDisabled(viewModel.currentStep == .review || viewModel.isLoading)
    }
}

// MARK: - Progress View

struct PatientSetupProgressView: View {
    let currentStep: TherapistPatientSetupViewModel.SetupStep

    private let totalSteps = 5

    private var progress: Double {
        Double(currentStep.rawValue) / Double(totalSteps)
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                        .cornerRadius(2)

                    Rectangle()
                        .fill(Color.modusCyan)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)

            Text("Step \(currentStep.rawValue + 1) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Basic Info Step

struct BasicInfoStepView: View {
    @ObservedObject var viewModel: TherapistPatientSetupViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Patient Information")
                        .font(.system(size: 28, weight: .bold))

                    Text("Enter the patient's details")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)

                VStack(spacing: 16) {
                    // Name fields
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("First Name *")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("First", text: $viewModel.firstName)
                                .textContentType(.givenName)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Name *")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Last", text: $viewModel.lastName)
                                .textContentType(.familyName)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                        }
                    }

                    // Email (optional)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email (optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("patient@email.com", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                    }

                    // Sport picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sport")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Menu {
                            ForEach(viewModel.commonSports, id: \.self) { sport in
                                Button(sport) {
                                    viewModel.sport = sport
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.sport.isEmpty ? "Select sport" : viewModel.sport)
                                    .foregroundColor(viewModel.sport.isEmpty ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                        }
                    }

                    // Position
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Position/Role")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("e.g., Pitcher, Point Guard", text: $viewModel.position)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                    }

                    // Injury type
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Injury/Condition")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("e.g., UCL Reconstruction, ACL Tear", text: $viewModel.injuryType)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                    }

                    // Target level picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Competition Level")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Menu {
                            ForEach(viewModel.targetLevelOptions, id: \.self) { level in
                                Button(level) {
                                    viewModel.targetLevel = level
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.targetLevel)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Mode Selection Step

struct TherapistModeSelectionView: View {
    @Binding var selectedMode: Mode

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Training Mode")
                    .font(.system(size: 28, weight: .bold))

                Text("Choose the patient's primary focus")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)

            VStack(spacing: 16) {
                ForEach(Mode.allCases, id: \.self) { mode in
                    TherapistModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        onTap: { selectedMode = mode }
                    )
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

struct TherapistModeCard: View {
    let mode: Mode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: mode.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .modusCyan)
                    .frame(width: 60, height: 60)
                    .background(isSelected ? Color.modusCyan : Color.modusCyan.opacity(0.1))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(modeDescription(mode))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.modusCyan)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.modusCyan : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func modeDescription(_ mode: Mode) -> String {
        switch mode {
        case .rehab:
            return "Post-injury/surgery recovery with pain tracking and ROM focus"
        case .strength:
            return "General fitness with strength, conditioning, and body composition"
        case .performance:
            return "Athletic performance with readiness-based training adjustments"
        }
    }
}

// MARK: - Goal Selection Step

struct TherapistGoalSelectionView: View {
    let availableGoals: [TherapistPatientSetupViewModel.PatientGoalTemplate]
    @Binding var selectedGoals: Set<TherapistPatientSetupViewModel.PatientGoalTemplate>
    @Binding var customGoalTitle: String
    @Binding var customGoalDescription: String

    @State private var showCustomGoal = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Set Goals")
                        .font(.system(size: 28, weight: .bold))

                    Text("Select goals for this patient")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)

                VStack(spacing: 12) {
                    ForEach(availableGoals) { goal in
                        TherapistGoalCard(
                            goal: goal,
                            isSelected: selectedGoals.contains(goal),
                            onTap: {
                                if selectedGoals.contains(goal) {
                                    selectedGoals.remove(goal)
                                } else {
                                    selectedGoals.insert(goal)
                                }
                            }
                        )
                    }

                    // Custom goal option
                    Button(action: { showCustomGoal.toggle() }) {
                        HStack {
                            Image(systemName: showCustomGoal ? "minus.circle.fill" : "plus.circle.fill")
                                .foregroundColor(.modusCyan)
                            Text(showCustomGoal ? "Hide Custom Goal" : "Add Custom Goal")
                                .foregroundColor(.modusCyan)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }

                    if showCustomGoal {
                        VStack(spacing: 12) {
                            TextField("Custom goal title", text: $customGoalTitle)
                                .padding()
                                .background(Color(.tertiarySystemGroupedBackground))
                                .cornerRadius(10)

                            TextField("Description (optional)", text: $customGoalDescription)
                                .padding()
                                .background(Color(.tertiarySystemGroupedBackground))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 20)

                Text("\(selectedGoals.count + (customGoalTitle.isEmpty ? 0 : 1)) goals selected")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Spacer(minLength: 40)
            }
        }
    }
}

struct TherapistGoalCard: View {
    let goal: TherapistPatientSetupViewModel.PatientGoalTemplate
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: goal.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : goal.color)
                    .frame(width: 48, height: 48)
                    .background(isSelected ? goal.color : goal.color.opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(goal.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? goal.color : .gray)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? goal.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Training Context Step

struct TrainingContextStepView: View {
    @ObservedObject var viewModel: TherapistPatientSetupViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Training Plan")
                        .font(.system(size: 28, weight: .bold))

                    Text("Set expectations and any restrictions")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)

                VStack(spacing: 20) {
                    // Frequency stepper
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weekly Sessions")
                                .font(.headline)
                            Text("Recommended training frequency")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Stepper("\(viewModel.weeklyFrequency)x/week", value: $viewModel.weeklyFrequency, in: 1...7)
                            .fixedSize()
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    // Session duration stepper
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Session Duration")
                                .font(.headline)
                            Text("Average workout length")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Stepper("\(viewModel.sessionDuration) min", value: $viewModel.sessionDuration, in: 15...120, step: 15)
                            .fixedSize()
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    // Training notes
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Training Notes")
                            .font(.headline)
                        Text("General instructions for the patient")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $viewModel.trainingNotes)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(10)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    // Restrictions
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Restrictions")
                                .font(.headline)
                        }
                        Text("Movements or activities to avoid")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $viewModel.restrictions)
                            .frame(minHeight: 60)
                            .padding(8)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(10)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    // Precautions
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "shield.fill")
                                .foregroundColor(.blue)
                            Text("Precautions")
                                .font(.headline)
                        }
                        Text("Things to be careful about")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $viewModel.precautions)
                            .frame(minHeight: 60)
                            .padding(8)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(10)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Review Step

struct ReviewStepView: View {
    @ObservedObject var viewModel: TherapistPatientSetupViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Review & Create")
                        .font(.system(size: 28, weight: .bold))

                    Text("Confirm the patient setup")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)

                VStack(alignment: .leading, spacing: 16) {
                    // Patient Info
                    ReviewSection(title: "Patient", icon: "person.fill") {
                        ReviewRow(label: "Name", value: "\(viewModel.firstName) \(viewModel.lastName)")
                        if !viewModel.email.isEmpty {
                            ReviewRow(label: "Email", value: viewModel.email)
                        }
                        if !viewModel.sport.isEmpty {
                            ReviewRow(label: "Sport", value: viewModel.sport)
                        }
                        if !viewModel.position.isEmpty {
                            ReviewRow(label: "Position", value: viewModel.position)
                        }
                        if !viewModel.injuryType.isEmpty {
                            ReviewRow(label: "Condition", value: viewModel.injuryType)
                        }
                        ReviewRow(label: "Level", value: viewModel.targetLevel)
                    }

                    // Mode
                    ReviewSection(title: "Training Mode", icon: viewModel.selectedMode.iconName) {
                        ReviewRow(label: "Mode", value: viewModel.selectedMode.displayName)
                    }

                    // Goals
                    ReviewSection(title: "Goals", icon: "target") {
                        ForEach(Array(viewModel.selectedGoals), id: \.id) { goal in
                            Text("• \(goal.title)")
                                .font(.subheadline)
                        }
                        if !viewModel.customGoalTitle.isEmpty {
                            Text("• \(viewModel.customGoalTitle)")
                                .font(.subheadline)
                        }
                    }

                    // Training Plan
                    ReviewSection(title: "Training Plan", icon: "calendar") {
                        ReviewRow(label: "Frequency", value: "\(viewModel.weeklyFrequency)x per week")
                        ReviewRow(label: "Duration", value: "\(viewModel.sessionDuration) min/session")
                        if !viewModel.restrictions.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Restrictions:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(viewModel.restrictions)
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
    }
}

struct ReviewSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.modusCyan)
                Text(title)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

struct ReviewRow: View {
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
        }
    }
}

// MARK: - Patient Created Step

struct PatientCreatedStepView: View {
    @ObservedObject var viewModel: TherapistPatientSetupViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Patient Created!")
                .font(.system(size: 28, weight: .bold))

            Text("\(viewModel.firstName) \(viewModel.lastName)")
                .font(.title3)
                .foregroundColor(.secondary)

            if let code = viewModel.linkingCode {
                VStack(spacing: 12) {
                    Text("Share this code with your patient:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(code)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.modusCyan)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)

                    Button(action: {
                        viewModel.copyLinkingCode()
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Code")
                        }
                        .font(.headline)
                        .foregroundColor(.modusCyan)
                    }

                    Text("Code expires in 7 days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 16)
            }

            Spacer()

            VStack(spacing: 12) {
                Text("Next Steps")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    NextStepItem(number: 1, text: "Share the linking code with your patient")
                    NextStepItem(number: 2, text: "Patient enters code in their app to connect")
                    NextStepItem(number: 3, text: "Assign programs and prescribe workouts")
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding()
    }
}

struct NextStepItem: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.modusCyan)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Preview

#Preview {
    TherapistPatientSetupView()
}
