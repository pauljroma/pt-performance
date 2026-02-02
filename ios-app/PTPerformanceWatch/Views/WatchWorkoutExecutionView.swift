//
//  WatchWorkoutExecutionView.swift
//  PTPerformanceWatch
//
//  Workout execution view for logging sets and tracking progress
//  ACP-824: Apple Watch Standalone App
//

import SwiftUI
import WatchKit

struct WatchWorkoutExecutionView: View {
    let session: WatchWorkoutSession
    @ObservedObject var viewModel: WatchWorkoutViewModel
    @StateObject private var voiceService = VoiceLoggingService()

    @State private var currentExerciseIndex = 0
    @State private var isResting = false
    @State private var restTimeRemaining = 60
    @State private var showingSetLogger = false
    @State private var showingVoiceInput = false
    @State private var showingCompletionAlert = false

    @Environment(\.dismiss) private var dismiss

    private var currentExercise: WatchExercise? {
        guard currentExerciseIndex < session.exercises.count else { return nil }
        return session.exercises[currentExerciseIndex]
    }

    var body: some View {
        Group {
            if isResting {
                WatchRestTimerView(
                    duration: currentExercise?.restSeconds ?? 60,
                    onComplete: handleRestComplete,
                    onSkip: handleRestSkip
                )
            } else if let exercise = currentExercise {
                exerciseView(exercise)
            } else {
                workoutCompleteView
            }
        }
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSetLogger) {
            if let exercise = currentExercise {
                WatchSetLoggerView(
                    exercise: exercise,
                    onLog: { reps, weight, rpe in
                        logSet(reps: reps, weight: weight, rpe: rpe)
                    }
                )
            }
        }
        .sheet(isPresented: $showingVoiceInput) {
            WatchVoiceInputView(voiceService: voiceService) { result in
                if let result = result, result.isValid {
                    logSet(
                        reps: result.reps ?? 0,
                        weight: result.weight,
                        rpe: result.rpe
                    )
                }
            }
        }
        .alert("Workout Complete!", isPresented: $showingCompletionAlert) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("Great job! Your workout has been logged.")
        }
    }

    // MARK: - Exercise View

    private func exerciseView(_ exercise: WatchExercise) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                // Exercise name and progress
                VStack(spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text("Set \(exercise.currentSetNumber) of \(exercise.prescribedSets)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Prescription display
                HStack(spacing: 16) {
                    VStack {
                        Text(exercise.prescribedReps)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("reps")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack {
                        Text(exercise.loadDisplay)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("load")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)

                // Progress dots
                HStack(spacing: 4) {
                    ForEach(0..<exercise.prescribedSets, id: \.self) { setIndex in
                        Circle()
                            .fill(setIndex < exercise.completedSets.count ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                // Action buttons
                VStack(spacing: 8) {
                    // Log set button
                    Button {
                        showingSetLogger = true
                    } label: {
                        Label("Log Set", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    // Voice input button
                    Button {
                        showingVoiceInput = true
                    } label: {
                        Label("Voice", systemImage: "mic.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    // Skip exercise button
                    if exercise.setsRemaining > 0 {
                        Button {
                            moveToNextExercise()
                        } label: {
                            Text("Skip Exercise")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Workout Complete View

    private var workoutCompleteView: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 50))
                .foregroundStyle(.yellow)

            Text("Workout Complete!")
                .font(.headline)

            Text("\(session.completedExercises) exercises logged")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Done") {
                Task {
                    await viewModel.completeSession(session.id)
                }
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Actions

    private func logSet(reps: Int, weight: Double?, rpe: Int?) {
        guard let exercise = currentExercise else { return }

        let completedSet = WatchCompletedSet(
            setNumber: exercise.currentSetNumber,
            reps: reps,
            weight: weight ?? exercise.prescribedLoad,
            rpe: rpe
        )

        Task {
            await viewModel.logSet(completedSet, for: exercise.id, in: session.id)

            // Trigger haptic feedback
            WatchHapticService.shared.setLogged()

            // Check if exercise is complete
            if exercise.currentSetNumber >= exercise.prescribedSets {
                moveToNextExercise()
            } else {
                // Start rest timer
                restTimeRemaining = exercise.restSeconds
                isResting = true
            }
        }
    }

    private func handleRestComplete() {
        isResting = false
        WatchHapticService.shared.restComplete()
    }

    private func handleRestSkip() {
        isResting = false
    }

    private func moveToNextExercise() {
        if currentExerciseIndex < session.exercises.count - 1 {
            currentExerciseIndex += 1
        } else {
            // Workout complete
            WatchHapticService.shared.workoutComplete()
            showingCompletionAlert = true
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WatchWorkoutExecutionView(
            session: WatchWorkoutSession(
                id: UUID(),
                sessionId: UUID(),
                name: "Upper Body",
                scheduledDate: Date(),
                scheduledTime: Date(),
                status: .inProgress,
                exercises: [
                    WatchExercise(
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
                    )
                ]
            ),
            viewModel: WatchWorkoutViewModel()
        )
    }
}
