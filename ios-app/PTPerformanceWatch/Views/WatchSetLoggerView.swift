//
//  WatchSetLoggerView.swift
//  PTPerformanceWatch
//
//  Quick set logging interface with Digital Crown support
//  ACP-824: Apple Watch Standalone App
//

import SwiftUI

struct WatchSetLoggerView: View {
    let exercise: WatchExercise
    let onLog: (Int, Double?, Int?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var reps: Int
    @State private var weight: Double
    @State private var rpe: Int = 7
    @State private var showingRPE = false

    @FocusState private var focusedField: LoggerField?

    enum LoggerField {
        case reps, weight, rpe
    }

    init(exercise: WatchExercise, onLog: @escaping (Int, Double?, Int?) -> Void) {
        self.exercise = exercise
        self.onLog = onLog

        // Initialize with prescribed values
        let defaultReps = Int(exercise.prescribedReps.components(separatedBy: "-").first ?? "10") ?? 10
        self._reps = State(initialValue: defaultReps)
        self._weight = State(initialValue: exercise.prescribedLoad ?? 0)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Set number indicator
                Text("Set \(exercise.currentSetNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Reps picker
                VStack(spacing: 4) {
                    Text("REPS")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("\(reps)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(focusedField == .reps ? .modusCyan : .primary)
                        .focusable(true)
                        .focused($focusedField, equals: .reps)
                        .digitalCrownRotation(
                            $reps,
                            from: 1,
                            through: 50,
                            by: 1,
                            sensitivity: .medium,
                            isContinuous: false,
                            isHapticFeedbackEnabled: true
                        )
                        .onTapGesture {
                            focusedField = .reps
                        }

                    // Quick adjust buttons
                    HStack(spacing: 20) {
                        Button("-") { reps = max(1, reps - 1) }
                            .font(.title3)
                            .buttonStyle(.plain)

                        Button("+") { reps = min(50, reps + 1) }
                            .font(.title3)
                            .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)

                // Weight picker (if applicable)
                if exercise.prescribedLoad != nil {
                    VStack(spacing: 4) {
                        Text("WEIGHT")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 4) {
                            Text("\(Int(weight))")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(focusedField == .weight ? .modusCyan : .primary)

                            Text(exercise.loadUnit ?? "lbs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .focusable(true)
                        .focused($focusedField, equals: .weight)
                        .digitalCrownRotation(
                            $weight,
                            from: 0,
                            through: 500,
                            by: 5,
                            sensitivity: .medium,
                            isContinuous: false,
                            isHapticFeedbackEnabled: true
                        )
                        .onTapGesture {
                            focusedField = .weight
                        }

                        // Quick adjust buttons
                        HStack(spacing: 16) {
                            Button("-5") { weight = max(0, weight - 5) }
                                .font(.caption)
                                .buttonStyle(.plain)

                            Button("+5") { weight = min(500, weight + 5) }
                                .font(.caption)
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // RPE toggle
                Button {
                    showingRPE.toggle()
                } label: {
                    HStack {
                        Text("RPE")
                            .font(.caption)
                        if showingRPE {
                            Text("\(rpe)")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        Image(systemName: showingRPE ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                if showingRPE {
                    Picker("RPE", selection: $rpe) {
                        ForEach(1...10, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 50)
                }

                // Log button
                Button {
                    WatchHapticService.shared.success()
                    onLog(reps, weight > 0 ? weight : nil, showingRPE ? rpe : nil)
                    dismiss()
                } label: {
                    Label("Log Set", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
        }
        .onAppear {
            focusedField = .reps
        }
    }
}

// MARK: - Preview

#Preview {
    WatchSetLoggerView(
        exercise: WatchExercise(
            id: UUID(),
            templateId: UUID(),
            name: "Bench Press",
            prescribedSets: 3,
            prescribedReps: "8-10",
            prescribedLoad: 135,
            loadUnit: "lbs",
            restSeconds: 90,
            completedSets: [],
            sequence: 1
        ),
        onLog: { _, _, _ in }
    )
}
