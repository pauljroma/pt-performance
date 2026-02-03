//
//  QuickWorkoutExecutionView.swift
//  PTPerformance
//
//  ACP-842: Streak Protection Alerts
//  Streamlined workout execution view for quick workouts
//

import SwiftUI
import Combine

// MARK: - Quick Workout Execution View

/// Streamlined full-screen view for executing quick workouts
struct QuickWorkoutExecutionView: View {
    // MARK: - Properties

    let workout: QuickWorkout
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentExerciseIndex: Int = 0
    @State private var isTimerRunning: Bool = false
    @State private var timeRemaining: Int = 0
    @State private var completedExercises: Set<UUID> = []
    @State private var showCompleteConfirmation: Bool = false
    @State private var showCancelConfirmation: Bool = false
    @State private var workoutStartTime: Date = Date()

    // Timer publisher
    @State private var timerCancellable: AnyCancellable?

    // MARK: - Computed Properties

    private var currentExercise: QuickWorkoutExercise? {
        guard currentExerciseIndex < workout.exercises.count else { return nil }
        return workout.exercises[currentExerciseIndex]
    }

    private var progress: Double {
        guard !workout.exercises.isEmpty else { return 0 }
        return Double(completedExercises.count) / Double(workout.exercises.count)
    }

    private var isLastExercise: Bool {
        currentExerciseIndex == workout.exercises.count - 1
    }

    private var workoutTypeColor: Color {
        switch workout.type {
        case .armCare: return .orange
        case .mobility: return .green
        case .express: return .blue
        case .stretching: return .purple
        case .warmup: return .red
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            workoutTypeColor.opacity(0.1)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with progress
                topBar

                // Main content
                if let exercise = currentExercise {
                    exerciseContent(exercise)
                } else {
                    completionView
                }

                // Bottom controls
                bottomControls
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            workoutStartTime = Date()
            setupExercise()
        }
        .onDisappear {
            stopTimer()
        }
        .alert("Cancel Workout?", isPresented: $showCancelConfirmation) {
            Button("Continue Workout", role: .cancel) { }
            Button("Cancel", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Your progress will not be saved.")
        }
        .alert("Complete Workout?", isPresented: $showCompleteConfirmation) {
            Button("Keep Going", role: .cancel) { }
            Button("Complete") {
                finishWorkout()
            }
        } message: {
            Text("You've completed \(completedExercises.count) of \(workout.exercises.count) exercises.")
        }
    }

    // MARK: - Subviews

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    showCancelConfirmation = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(workout.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("\(completedExercises.count)/\(workout.exercises.count) exercises")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Timer/Skip button
                if completedExercises.count == workout.exercises.count {
                    Button("Done") {
                        finishWorkout()
                    }
                    .font(.headline)
                    .foregroundColor(workoutTypeColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
                } else {
                    Button {
                        showCompleteConfirmation = true
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)

                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 12)
        .background(workoutTypeColor)
    }

    private func exerciseContent(_ exercise: QuickWorkoutExercise) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Exercise number
            Text("Exercise \(currentExerciseIndex + 1)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Exercise name
            Text(exercise.name)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Prescription
            if let duration = exercise.durationSeconds {
                // Timer-based exercise
                timerView(duration: duration, exercise: exercise)
            } else if let reps = exercise.reps {
                // Rep-based exercise
                repView(reps: reps, sets: exercise.sets, exercise: exercise)
            } else {
                // Set-based only
                setView(sets: exercise.sets, exercise: exercise)
            }

            // Notes
            if let notes = exercise.notes {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
    }

    private func timerView(duration: Int, exercise: QuickWorkoutExercise) -> some View {
        VStack(spacing: 20) {
            // Timer display
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 200, height: 200)

                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(duration))
                    .stroke(workoutTypeColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: timeRemaining)

                // Time text
                VStack(spacing: 4) {
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)

                    if exercise.sets > 1 {
                        Text("x \(exercise.sets) sets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Timer controls
            HStack(spacing: 20) {
                Button {
                    if isTimerRunning {
                        pauseTimer()
                    } else {
                        startTimer(duration: duration)
                    }
                } label: {
                    Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(workoutTypeColor)
                        .clipShape(Circle())
                }

                Button {
                    timeRemaining = duration
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(width: 50, height: 50)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(Circle())
                }
            }
        }
        .onAppear {
            timeRemaining = duration
        }
    }

    private func repView(reps: Int, sets: Int, exercise: QuickWorkoutExercise) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                if sets > 1 {
                    Text("\(sets) x")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Text("\(reps)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(workoutTypeColor)

                Text("reps")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }

            // Complete button
            completeExerciseButton(exercise)
        }
    }

    private func setView(sets: Int, exercise: QuickWorkoutExercise) -> some View {
        VStack(spacing: 16) {
            Text("\(sets)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(workoutTypeColor)

            Text("set\(sets == 1 ? "" : "s")")
                .font(.title2)
                .foregroundColor(.secondary)

            completeExerciseButton(exercise)
        }
    }

    private func completeExerciseButton(_ exercise: QuickWorkoutExercise) -> some View {
        Button {
            markExerciseComplete(exercise)
        } label: {
            HStack {
                Image(systemName: completedExercises.contains(exercise.id) ? "checkmark.circle.fill" : "circle")
                Text(completedExercises.contains(exercise.id) ? "Completed" : "Mark Complete")
            }
            .font(.headline)
            .foregroundColor(completedExercises.contains(exercise.id) ? .white : workoutTypeColor)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(completedExercises.contains(exercise.id) ? workoutTypeColor : Color(.tertiarySystemGroupedBackground))
            .cornerRadius(30)
        }
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Workout Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 8) {
                Text("Great job protecting your streak!")
                    .font(.title3)
                    .foregroundColor(.secondary)

                let duration = Int(Date().timeIntervalSince(workoutStartTime) / 60)
                Text("\(duration) minutes | \(workout.exercises.count) exercises")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                finishWorkout()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(workoutTypeColor)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    private var bottomControls: some View {
        Group {
            if currentExercise != nil {
                HStack(spacing: 20) {
                    // Previous button
                    Button {
                        goToPreviousExercise()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .font(.subheadline)
                        .foregroundColor(currentExerciseIndex > 0 ? .primary : .secondary)
                    }
                    .disabled(currentExerciseIndex == 0)

                    Spacer()

                    // Exercise dots
                    HStack(spacing: 6) {
                        ForEach(0..<workout.exercises.count, id: \.self) { index in
                            Circle()
                                .fill(
                                    completedExercises.contains(workout.exercises[index].id)
                                    ? workoutTypeColor
                                    : (index == currentExerciseIndex ? Color.primary : Color.gray.opacity(0.3))
                                )
                                .frame(width: 8, height: 8)
                        }
                    }

                    Spacer()

                    // Next button
                    Button {
                        goToNextExercise()
                    } label: {
                        HStack {
                            Text(isLastExercise ? "Finish" : "Next")
                            Image(systemName: isLastExercise ? "checkmark" : "chevron.right")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(workoutTypeColor)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
            }
        }
    }

    // MARK: - Helper Methods

    private func setupExercise() {
        if let exercise = currentExercise, let duration = exercise.durationSeconds {
            timeRemaining = duration
        }
    }

    private func startTimer(duration: Int) {
        isTimerRunning = true
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    // Timer complete
                    stopTimer()
                    HapticFeedback.success()
                    if let exercise = currentExercise {
                        markExerciseComplete(exercise)
                    }
                }
            }
    }

    private func pauseTimer() {
        isTimerRunning = false
        timerCancellable?.cancel()
    }

    private func stopTimer() {
        isTimerRunning = false
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func markExerciseComplete(_ exercise: QuickWorkoutExercise) {
        _ = withAnimation {
            completedExercises.insert(exercise.id)
        }
        HapticFeedback.light()

        // Auto-advance after short delay if not last exercise
        if !isLastExercise {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                goToNextExercise()
            }
        }
    }

    private func goToNextExercise() {
        stopTimer()
        if currentExerciseIndex < workout.exercises.count - 1 {
            withAnimation {
                currentExerciseIndex += 1
            }
            setupExercise()
        } else if completedExercises.count == workout.exercises.count {
            // All done
        } else {
            // Show completion even if not all marked
            withAnimation {
                currentExerciseIndex = workout.exercises.count
            }
        }
    }

    private func goToPreviousExercise() {
        stopTimer()
        if currentExerciseIndex > 0 {
            withAnimation {
                currentExerciseIndex -= 1
            }
            setupExercise()
        }
    }

    private func finishWorkout() {
        // Cancel any scheduled streak alerts
        StreakAlertService.shared.cancelScheduledAlerts()

        HapticFeedback.success()
        onComplete()
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Preview

struct QuickWorkoutExecutionView_Previews: PreviewProvider {
    static var previews: some View {
        QuickWorkoutExecutionView(
            workout: QuickWorkout.sample10MinMobility,
            onComplete: {}
        )
    }
}
