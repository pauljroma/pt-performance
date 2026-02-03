//
//  CustomTimerBuilderView.swift
//  PTPerformance
//
//  Created by BUILD 116 Agent 21 (Custom Timer Builder)
//  UI for building custom interval timers with user-defined parameters
//

import SwiftUI

/// Custom timer builder view for creating interval templates
/// Allows users to configure work/rest/rounds/cycles and save as templates
struct CustomTimerBuilderView: View {
    // MARK: - Dependencies

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CustomTimerBuilderViewModel
    private let onTimerCreated: ((IntervalTemplate) -> Void)?

    // MARK: - Initialization

    init(
        patientId: UUID,
        onTimerCreated: ((IntervalTemplate) -> Void)? = nil
    ) {
        self.onTimerCreated = onTimerCreated
        _viewModel = StateObject(wrappedValue: CustomTimerBuilderViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                templateInfoSection
                timerTypeSection
                durationSection
                roundsAndCyclesSection
                if viewModel.showCycleRest {
                    cycleRestSection
                }
                previewSection
                saveOptionsSection
            }
            .navigationTitle("Custom Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Discards timer and returns to previous screen")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create & Start") {
                        Task {
                            await createAndStartTimer()
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isCreating)
                    .fontWeight(.semibold)
                    .accessibilityLabel("Create and start timer")
                    .accessibilityHint(viewModel.isValid ? "Creates timer and starts it immediately" : "Complete the form to create timer")
                }
            }
            .alert("Validation Error", isPresented: $viewModel.showValidationError) {
                Button("OK", role: .cancel) {
                    viewModel.dismissValidationError()
                }
            } message: {
                Text(viewModel.validationError)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {
                    viewModel.dismissError()
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            .overlay {
                if viewModel.isCreating {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }

    // MARK: - Sections

    /// Template info section (name)
    private var templateInfoSection: some View {
        Section {
            TextField("Template Name", text: $viewModel.templateName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .accessibilityLabel("Timer name")
                .accessibilityHint("Enter a descriptive name for your timer")
        } header: {
            Text("Template Info")
        } footer: {
            if let error = viewModel.validationMessage, !viewModel.templateName.isEmpty {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            } else {
                Text("Give your timer a descriptive name (2-50 characters)")
                    .font(.caption)
            }
        }
    }

    /// Timer type picker section
    private var timerTypeSection: some View {
        Section {
            Picker("Type", selection: $viewModel.timerType) {
                ForEach(TimerType.allCases, id: \.self) { type in
                    HStack {
                        Image(systemName: type.iconName)
                        Text(type.displayName)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Timer Type")
        } footer: {
            Text(viewModel.timerType.description)
                .font(.caption)
        }
    }

    /// Duration configuration section (work/rest)
    private var durationSection: some View {
        Section {
            // Work Duration
            HStack {
                Label("Work", systemImage: "flame.fill")
                    .foregroundColor(.red)
                Spacer()
                Stepper(
                    value: $viewModel.workSeconds,
                    in: 5...300,
                    step: 5
                ) {
                    Text("\(viewModel.workSeconds)s")
                        .font(.body.monospacedDigit())
                        .foregroundColor(.primary)
                }
                .accessibilityLabel("Work duration")
                .accessibilityValue("\(viewModel.workSeconds) seconds")
                .accessibilityHint("Adjust work interval duration in 5-second increments")
            }

            // Rest Duration
            HStack {
                Label("Rest", systemImage: "pause.fill")
                    .foregroundColor(.green)
                Spacer()
                Stepper(
                    value: $viewModel.restSeconds,
                    in: 0...300,
                    step: 5
                ) {
                    Text(viewModel.restSeconds == 0 ? "None" : "\(viewModel.restSeconds)s")
                        .font(.body.monospacedDigit())
                        .foregroundColor(.primary)
                }
                .accessibilityLabel("Rest duration")
                .accessibilityValue(viewModel.restSeconds == 0 ? "No rest" : "\(viewModel.restSeconds) seconds")
                .accessibilityHint("Adjust rest interval duration in 5-second increments")
            }
            .disabled(viewModel.timerType == .emom && viewModel.restSeconds == 0)
        } header: {
            Text("Duration")
        } footer: {
            if viewModel.timerType == .emom {
                Text("EMOM: Work duration + rest should equal 60s, or set rest to 0 for continuous work")
                    .font(.caption)
            } else {
                Text("Configure work and rest periods in 5-second increments")
                    .font(.caption)
            }
        }
    }

    /// Rounds and cycles section
    private var roundsAndCyclesSection: some View {
        Section {
            // Rounds
            HStack {
                Label("Rounds", systemImage: "repeat")
                    .foregroundColor(.blue)
                Spacer()
                Stepper(
                    value: $viewModel.rounds,
                    in: 1...50
                ) {
                    Text("\(viewModel.rounds)")
                        .font(.body.monospacedDigit())
                        .foregroundColor(.primary)
                }
                .accessibilityLabel("Number of rounds")
                .accessibilityValue("\(viewModel.rounds) rounds")
                .accessibilityHint("Adjust the number of work-rest intervals")
            }

            // Cycles (if not Tabata)
            if viewModel.timerType != .tabata {
                HStack {
                    Label("Cycles", systemImage: "arrow.triangle.2.circlepath")
                        .foregroundColor(.purple)
                    Spacer()
                    Stepper(
                        value: $viewModel.cycles,
                        in: 1...10
                    ) {
                        Text("\(viewModel.cycles)")
                            .font(.body.monospacedDigit())
                            .foregroundColor(.primary)
                    }
                    .accessibilityLabel("Number of cycles")
                    .accessibilityValue("\(viewModel.cycles) cycles")
                    .accessibilityHint("Adjust the number of complete round sets")
                }
            }
        } header: {
            Text("Rounds & Cycles")
        } footer: {
            if viewModel.timerType == .tabata {
                Text("Classic Tabata uses 8 rounds in a single cycle")
                    .font(.caption)
            } else if viewModel.timerType == .amrap {
                Text("AMRAP: Complete as many rounds as possible in the time limit")
                    .font(.caption)
            } else {
                Text("A cycle is a complete set of all rounds. Add cycles for multi-set workouts.")
                    .font(.caption)
            }
        }
    }

    /// Cycle rest section (only shown if cycles > 1)
    private var cycleRestSection: some View {
        Section {
            HStack {
                Label("Cycle Rest", systemImage: "bed.double.fill")
                    .foregroundColor(.orange)
                Spacer()
                Stepper(
                    value: $viewModel.cycleRestSeconds,
                    in: 10...600,
                    step: 10
                ) {
                    Text("\(viewModel.cycleRestSeconds)s")
                        .font(.body.monospacedDigit())
                        .foregroundColor(.primary)
                }
                .accessibilityLabel("Rest between cycles")
                .accessibilityValue("\(viewModel.cycleRestSeconds) seconds")
                .accessibilityHint("Adjust rest duration between complete cycles")
            }
        } header: {
            Text("Rest Between Cycles")
        } footer: {
            Text("Rest period between each complete cycle (10-600 seconds)")
                .font(.caption)
        }
    }

    /// Preview section showing total time and breakdown
    private var previewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // Total Time
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)
                    Text("Total Time:")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.formattedTotalTime)
                        .font(.title2.monospacedDigit())
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Total time: \(viewModel.formattedTotalTime)")

                Divider()

                // Breakdown
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Work x Rest:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.workSeconds)s x \(viewModel.restSeconds)s")
                            .font(.subheadline.monospacedDigit())
                    }

                    HStack {
                        Text("Rounds:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.rounds)")
                            .font(.subheadline.monospacedDigit())
                    }

                    if viewModel.cycles > 1 {
                        HStack {
                            Text("Cycles:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(viewModel.cycles)")
                                .font(.subheadline.monospacedDigit())
                        }

                        HStack {
                            Text("Cycle Rest:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(viewModel.cycleRestSeconds)s")
                                .font(.subheadline.monospacedDigit())
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Preview")
        } footer: {
            if viewModel.cycles > 1 {
                Text("Total: (\(viewModel.singleCycleDuration)s cycle + \(viewModel.cycleRestSeconds)s rest) x \(viewModel.cycles) cycles")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("(\(viewModel.workSeconds)s work + \(viewModel.restSeconds)s rest) x \(viewModel.rounds) rounds = \(viewModel.totalDuration)s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    /// Save options section
    private var saveOptionsSection: some View {
        Section {
            Toggle(isOn: $viewModel.saveAsTemplate) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Save as Template")
                        .font(.body)
                    Text("Reuse this timer configuration later")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if viewModel.saveAsTemplate {
                Toggle(isOn: $viewModel.makePublic) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Make Public")
                            .font(.body)
                        Text("Share this template with other users")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("Save Options")
        }
    }

    // MARK: - Actions

    /// Create timer and start it via ViewModel
    private func createAndStartTimer() async {
        if let template = await viewModel.createAndStartTimer() {
            // Notify callback
            onTimerCreated?(template)

            // Dismiss sheet
            dismiss()
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct CustomTimerBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default state
            CustomTimerBuilderView(patientId: UUID())
                .previewDisplayName("Default")

            // With Tabata type selected
            CustomTimerBuilderView(patientId: UUID())
                .onAppear {
                    // Preview can't modify @State, so this is for display only
                }
                .previewDisplayName("Tabata")

            // Multi-cycle configuration
            CustomTimerBuilderView(patientId: UUID())
                .previewDisplayName("Multi-Cycle")
        }
    }
}
#endif
