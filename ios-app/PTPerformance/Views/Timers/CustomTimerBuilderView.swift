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
    @StateObject private var timerService: IntervalTimerService
    private let patientId: UUID
    private let onTimerCreated: ((IntervalTemplate) -> Void)?

    // MARK: - Form State

    @State private var templateName: String = ""
    @State private var timerType: TimerType = .custom
    @State private var workSeconds: Int = 30
    @State private var restSeconds: Int = 30
    @State private var rounds: Int = 5
    @State private var cycles: Int = 1
    @State private var cycleRestSeconds: Int = 60
    @State private var saveAsTemplate: Bool = false
    @State private var makePublic: Bool = false

    // MARK: - UI State

    @State private var isCreating: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showValidationError: Bool = false
    @State private var validationError: String = ""

    // MARK: - Initialization

    init(
        patientId: UUID,
        onTimerCreated: ((IntervalTemplate) -> Void)? = nil
    ) {
        self.patientId = patientId
        self.onTimerCreated = onTimerCreated
        // Initialize StateObject with new IntervalTimerService instance
        _timerService = StateObject(wrappedValue: IntervalTimerService())
    }

    // MARK: - Computed Properties

    /// Total duration for a single cycle (work + rest) × rounds
    private var singleCycleDuration: Int {
        (workSeconds + restSeconds) * rounds
    }

    /// Total duration including all cycles and cycle rest
    private var totalDuration: Int {
        if cycles == 1 {
            return singleCycleDuration
        } else {
            // Multi-cycle: (cycle + cycle rest) × cycles - final cycle rest
            return (singleCycleDuration + cycleRestSeconds) * cycles - cycleRestSeconds
        }
    }

    /// Formatted total time string (e.g., "5m 30s")
    private var formattedTotalTime: String {
        let minutes = totalDuration / 60
        let seconds = totalDuration % 60

        if minutes > 0 {
            if seconds > 0 {
                return "\(minutes)m \(seconds)s"
            }
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }

    /// Whether the current configuration is valid
    private var isValid: Bool {
        // Template name validation
        let trimmedName = templateName.trimmingCharacters(in: .whitespaces)
        guard trimmedName.count >= 2 && trimmedName.count <= 50 else {
            return false
        }

        // Work duration validation
        guard workSeconds > 0 else {
            return false
        }

        // Rest duration validation
        guard restSeconds >= 0 else {
            return false
        }

        // Rounds validation
        guard rounds >= 1 && rounds <= 50 else {
            return false
        }

        // Cycles validation
        guard cycles >= 1 && cycles <= 10 else {
            return false
        }

        // Type-specific validation
        if timerType == .emom {
            // EMOM should have rest = 0 or work + rest = 60
            if restSeconds != 0 && (workSeconds + restSeconds) != 60 {
                return false
            }
        }

        return true
    }

    /// Validation error message (if invalid)
    private var validationMessage: String? {
        let trimmedName = templateName.trimmingCharacters(in: .whitespaces)

        if trimmedName.isEmpty {
            return "Template name is required"
        }
        if trimmedName.count < 2 {
            return "Template name must be at least 2 characters"
        }
        if trimmedName.count > 50 {
            return "Template name must be 50 characters or less"
        }
        if workSeconds <= 0 {
            return "Work duration must be greater than 0"
        }
        if restSeconds < 0 {
            return "Rest duration cannot be negative"
        }
        if rounds < 1 {
            return "Rounds must be at least 1"
        }
        if rounds > 50 {
            return "Rounds cannot exceed 50"
        }
        if cycles < 1 {
            return "Cycles must be at least 1"
        }
        if cycles > 10 {
            return "Cycles cannot exceed 10"
        }
        if totalDuration > 7200 {
            return "Total duration cannot exceed 2 hours"
        }

        return nil
    }

    /// Whether to show cycle rest field
    private var showCycleRest: Bool {
        cycles > 1 && timerType != .tabata
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                templateInfoSection
                timerTypeSection
                durationSection
                roundsAndCyclesSection
                if showCycleRest {
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
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create & Start") {
                        Task {
                            await createAndStartTimer()
                        }
                    }
                    .disabled(!isValid || isCreating)
                    .fontWeight(.semibold)
                }
            }
            .alert("Validation Error", isPresented: $showValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationError)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isCreating {
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
            TextField("Template Name", text: $templateName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        } header: {
            Text("Template Info")
        } footer: {
            if let error = validationMessage, !templateName.isEmpty {
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
            Picker("Type", selection: $timerType) {
                ForEach(TimerType.allCases, id: \.self) { type in
                    HStack {
                        Image(systemName: type.iconName)
                        Text(type.displayName)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: timerType) { _, newType in
                applyTypeDefaults(newType)
            }
        } header: {
            Text("Timer Type")
        } footer: {
            Text(timerType.description)
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
                    value: $workSeconds,
                    in: 5...300,
                    step: 5
                ) {
                    Text("\(workSeconds)s")
                        .font(.body.monospacedDigit())
                        .foregroundColor(.primary)
                }
            }

            // Rest Duration
            HStack {
                Label("Rest", systemImage: "pause.fill")
                    .foregroundColor(.green)
                Spacer()
                Stepper(
                    value: $restSeconds,
                    in: 0...300,
                    step: 5
                ) {
                    Text(restSeconds == 0 ? "None" : "\(restSeconds)s")
                        .font(.body.monospacedDigit())
                        .foregroundColor(.primary)
                }
            }
            .disabled(timerType == .emom && restSeconds == 0)
        } header: {
            Text("Duration")
        } footer: {
            if timerType == .emom {
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
                    value: $rounds,
                    in: 1...50
                ) {
                    Text("\(rounds)")
                        .font(.body.monospacedDigit())
                        .foregroundColor(.primary)
                }
            }

            // Cycles (if not Tabata)
            if timerType != .tabata {
                HStack {
                    Label("Cycles", systemImage: "arrow.triangle.2.circlepath")
                        .foregroundColor(.purple)
                    Spacer()
                    Stepper(
                        value: $cycles,
                        in: 1...10
                    ) {
                        Text("\(cycles)")
                            .font(.body.monospacedDigit())
                            .foregroundColor(.primary)
                    }
                }
            }
        } header: {
            Text("Rounds & Cycles")
        } footer: {
            if timerType == .tabata {
                Text("Classic Tabata uses 8 rounds in a single cycle")
                    .font(.caption)
            } else if timerType == .amrap {
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
                    value: $cycleRestSeconds,
                    in: 10...600,
                    step: 10
                ) {
                    Text("\(cycleRestSeconds)s")
                        .font(.body.monospacedDigit())
                        .foregroundColor(.primary)
                }
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
                    Text("Total Time:")
                        .font(.headline)
                    Spacer()
                    Text(formattedTotalTime)
                        .font(.title2.monospacedDigit())
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                Divider()

                // Breakdown
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Work × Rest:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(workSeconds)s × \(restSeconds)s")
                            .font(.subheadline.monospacedDigit())
                    }

                    HStack {
                        Text("Rounds:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(rounds)")
                            .font(.subheadline.monospacedDigit())
                    }

                    if cycles > 1 {
                        HStack {
                            Text("Cycles:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(cycles)")
                                .font(.subheadline.monospacedDigit())
                        }

                        HStack {
                            Text("Cycle Rest:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(cycleRestSeconds)s")
                                .font(.subheadline.monospacedDigit())
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Preview")
        } footer: {
            if cycles > 1 {
                Text("Total: (\(singleCycleDuration)s cycle + \(cycleRestSeconds)s rest) × \(cycles) cycles")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("(\(workSeconds)s work + \(restSeconds)s rest) × \(rounds) rounds = \(totalDuration)s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    /// Save options section
    private var saveOptionsSection: some View {
        Section {
            Toggle(isOn: $saveAsTemplate) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Save as Template")
                        .font(.body)
                    Text("Reuse this timer configuration later")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if saveAsTemplate {
                Toggle(isOn: $makePublic) {
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

    /// Apply default values when timer type changes
    private func applyTypeDefaults(_ type: TimerType) {
        switch type {
        case .tabata:
            workSeconds = 20
            restSeconds = 10
            rounds = 8
            cycles = 1

        case .emom:
            workSeconds = 40
            restSeconds = 20
            rounds = 10
            cycles = 1

        case .amrap:
            workSeconds = 30
            restSeconds = 30
            rounds = 10
            cycles = 1

        case .intervals:
            workSeconds = 40
            restSeconds = 20
            rounds = 8
            cycles = 1

        case .custom:
            // No defaults for custom - keep current values
            break
        }
    }

    /// Create timer and start it
    private func createAndStartTimer() async {
        // Validate
        if let error = validationMessage {
            validationError = error
            showValidationError = true
            return
        }

        guard isValid else {
            validationError = "Invalid timer configuration"
            showValidationError = true
            return
        }

        isCreating = true

        do {
            // Create template (save to database if saveAsTemplate is enabled)
            let template: IntervalTemplate

            if saveAsTemplate {
                // Save to database
                template = try await timerService.createTemplate(
                    name: templateName.trimmingCharacters(in: .whitespaces),
                    type: timerType,
                    workSeconds: workSeconds,
                    restSeconds: restSeconds,
                    rounds: rounds,
                    cycles: cycles,
                    isPublic: makePublic
                )

                #if DEBUG
                print("✅ Template saved to database: \(template.id)")
                #endif
            } else {
                // Create temporary template (not saved to database)
                template = IntervalTemplate(
                    id: UUID(),
                    name: templateName.trimmingCharacters(in: .whitespaces),
                    type: timerType,
                    workSeconds: workSeconds,
                    restSeconds: restSeconds,
                    rounds: rounds,
                    cycles: cycles,
                    createdBy: nil,
                    isPublic: false,
                    createdAt: Date(),
                    updatedAt: Date()
                )

                #if DEBUG
                print("✅ Temporary template created: \(template.id)")
                #endif
            }

            // Start timer with template
            try await timerService.startTimer(template: template, patientId: patientId)

            #if DEBUG
            print("✅ Timer started with template: \(template.name)")
            #endif

            // Notify callback
            onTimerCreated?(template)

            // Dismiss sheet
            dismiss()

        } catch {
            isCreating = false
            errorMessage = error.localizedDescription
            showError = true

            DebugLogger.shared.error("CUSTOM_TIMER", """
                Failed to create timer:
                Template name: \(templateName)
                Error: \(error.localizedDescription)
                Type: \(type(of: error))
                """)
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
