//
//  JaegerBandView.swift
//  PTPerformance
//
//  ACP-521: Jaeger Band Protocol Integration
//  Step-by-step guided J-Band routine with timer and video support
//

import SwiftUI
import AVKit

// MARK: - Main View

struct JaegerBandView: View {
    @StateObject private var viewModel = JaegerBandViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isSessionActive {
                    ActiveRoutineView(viewModel: viewModel)
                } else if viewModel.isSessionComplete {
                    SessionCompleteView(viewModel: viewModel, onDismiss: { dismiss() })
                } else {
                    ProtocolSelectionView(viewModel: viewModel)
                }
            }
            .navigationTitle("J-Band Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.isSessionActive {
                        Button("End") {
                            viewModel.endSession()
                        }
                        .foregroundColor(.red)
                    } else if !viewModel.isSessionComplete {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Protocol Selection View

private struct ProtocolSelectionView: View {
    @ObservedObject var viewModel: JaegerBandViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)

                    Text("Select Your Routine")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Choose the J-Band routine that fits your schedule")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Protocol Options
                ForEach(JaegerBandVariation.allCases) { variation in
                    ProtocolOptionCard(
                        variation: variation,
                        isSelected: viewModel.selectedVariation == variation,
                        onSelect: { viewModel.selectedVariation = variation }
                    )
                }

                // Arm Soreness Check (Optional)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pre-Routine Check (Optional)")
                        .font(.headline)
                        .padding(.horizontal)

                    HStack {
                        Text("Current arm soreness:")
                            .font(.subheadline)

                        Spacer()

                        Picker("Soreness", selection: $viewModel.armSorenessBefore) {
                            Text("None").tag(Optional<Int>.none)
                            ForEach(1...10, id: \.self) { level in
                                Text("\(level)").tag(Optional<Int>.some(level))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // Start Button
                Button(action: {
                    viewModel.startSession()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Routine")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Protocol Option Card

private struct ProtocolOptionCard: View {
    let variation: JaegerBandVariation
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: variation.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .orange)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.orange : Color.orange.opacity(0.1))
                    .cornerRadius(10)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(variation.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(variation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Duration
                VStack {
                    Text("\(variation.estimatedDuration)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .orange : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: isSelected ? Color.orange.opacity(0.3) : Color.black.opacity(0.1), radius: isSelected ? 8 : 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

// MARK: - Active Routine View

private struct ActiveRoutineView: View {
    @ObservedObject var viewModel: JaegerBandViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Progress Header
            ProgressHeaderView(viewModel: viewModel)

            // Exercise Content
            if let exercise = viewModel.currentExercise {
                ScrollView {
                    VStack(spacing: 20) {
                        // Exercise Card
                        ExerciseDetailCard(exercise: exercise)

                        // Timer Section
                        if let holdSeconds = exercise.holdSeconds {
                            TimerSection(
                                totalSeconds: holdSeconds,
                                isRunning: $viewModel.isTimerRunning,
                                remainingSeconds: $viewModel.timerRemainingSeconds,
                                onComplete: viewModel.timerCompleted
                            )
                        }

                        // Coaching Cues
                        CoachingCuesSection(cues: exercise.coachingCues)

                        // Common Mistakes
                        if !exercise.commonMistakes.isEmpty {
                            CommonMistakesSection(mistakes: exercise.commonMistakes)
                        }

                        // Target Muscles
                        TargetMusclesSection(muscles: exercise.targetMuscles)
                    }
                    .padding()
                }
            }

            // Navigation Buttons
            NavigationButtonsView(viewModel: viewModel)
        }
    }
}

// MARK: - Progress Header

private struct ProgressHeaderView: View {
    @ObservedObject var viewModel: JaegerBandViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * viewModel.progressPercentage, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progressPercentage)
                }
            }
            .frame(height: 8)

            // Exercise Counter
            HStack {
                Text("Exercise \(viewModel.currentExerciseIndex + 1) of \(viewModel.totalExercises)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                // Elapsed Time
                if let elapsed = viewModel.elapsedTimeString {
                    Label(elapsed, systemImage: "clock")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - Exercise Detail Card

private struct ExerciseDetailCard: View {
    let exercise: JaegerBandExercise

    var body: some View {
        VStack(spacing: 16) {
            // Video Thumbnail or Placeholder
            if let videoUrl = exercise.videoUrl {
                JaegerVideoThumbnailView(videoUrl: videoUrl)
            } else {
                ExercisePlaceholderView(category: exercise.category)
            }

            // Exercise Info
            VStack(spacing: 8) {
                Text(exercise.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                HStack(spacing: 16) {
                    // Prescription
                    Label(exercise.prescriptionDisplay, systemImage: "repeat")
                        .font(.subheadline)
                        .foregroundColor(.orange)

                    // Tempo
                    if let tempo = exercise.tempoDisplay {
                        Label(tempo, systemImage: "metronome")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Description
                Text(exercise.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Video Thumbnail View

private struct JaegerVideoThumbnailView: View {
    let videoUrl: String
    @State private var showVideo = false

    var body: some View {
        Button(action: { showVideo = true }) {
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(12)

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .shadow(radius: 4)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Watch Demo")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .padding(8)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showVideo) {
            VideoPlayerSheet(videoUrl: videoUrl)
        }
    }
}

// MARK: - Video Player Sheet

private struct VideoPlayerSheet: View {
    let videoUrl: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            if let url = URL(string: videoUrl) {
                VideoPlayer(player: AVPlayer(url: url))
                    .edgesIgnoringSafeArea(.all)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                dismiss()
                            }
                        }
                    }
            } else {
                Text("Video unavailable")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Exercise Placeholder View

private struct ExercisePlaceholderView: View {
    let category: JaegerBandExerciseCategory

    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(12)

            VStack(spacing: 8) {
                Image(systemName: iconForCategory(category))
                    .font(.system(size: 40))
                    .foregroundColor(.orange)

                Text(category.displayName)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

    private func iconForCategory(_ category: JaegerBandExerciseCategory) -> String {
        switch category {
        case .warmup: return "flame"
        case .wristFlexion, .wristExtension: return "hand.raised"
        case .internalRotation, .externalRotation: return "arrow.triangle.2.circlepath"
        case .shoulderFlexion, .shoulderExtension: return "figure.arms.open"
        case .scapularStability: return "shield.checkered"
        case .throwingPattern: return "baseball"
        }
    }
}

// MARK: - Timer Section

private struct TimerSection: View {
    let totalSeconds: Int
    @Binding var isRunning: Bool
    @Binding var remainingSeconds: Int
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Hold Timer")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Timer Display
            Text(timeString(from: remainingSeconds))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(remainingSeconds <= 5 ? .red : .primary)

            // Timer Controls
            HStack(spacing: 20) {
                Button(action: { resetTimer() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray5))
                        .cornerRadius(22)
                }

                Button(action: { toggleTimer() }) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(Color.orange)
                        .cornerRadius(32)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func timeString(from seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func toggleTimer() {
        isRunning.toggle()
    }

    private func resetTimer() {
        isRunning = false
        remainingSeconds = totalSeconds
    }
}

// MARK: - Coaching Cues Section

private struct CoachingCuesSection: View {
    let cues: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Coaching Cues")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(cues.enumerated()), id: \.offset) { index, cue in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.orange)
                            .cornerRadius(12)

                        Text(cue)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Common Mistakes Section

private struct CommonMistakesSection: View {
    let mistakes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Common Mistakes")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(mistakes, id: \.self) { mistake in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)

                        Text(mistake)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Target Muscles Section

private struct TargetMusclesSection: View {
    let muscles: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.arms.open")
                    .foregroundColor(.blue)
                Text("Target Muscles")
                    .font(.headline)
            }

            JaegerFlowLayout(spacing: 8) {
                ForEach(muscles, id: \.self) { muscle in
                    Text(muscle)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Flow Layout

private struct JaegerFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Navigation Buttons

private struct NavigationButtonsView: View {
    @ObservedObject var viewModel: JaegerBandViewModel

    var body: some View {
        HStack(spacing: 16) {
            // Previous Button
            Button(action: { viewModel.previousExercise() }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canGoPrevious)
            .opacity(viewModel.canGoPrevious ? 1 : 0.5)

            // Skip Button
            Button(action: { viewModel.skipExercise() }) {
                Text("Skip")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Next/Complete Button
            Button(action: {
                if viewModel.isLastExercise {
                    viewModel.completeSession()
                } else {
                    viewModel.nextExercise()
                }
            }) {
                HStack {
                    Text(viewModel.isLastExercise ? "Complete" : "Next")
                    Image(systemName: viewModel.isLastExercise ? "checkmark" : "chevron.right")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
    }
}

// MARK: - Session Complete View

private struct SessionCompleteView: View {
    @ObservedObject var viewModel: JaegerBandViewModel
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success Animation
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)

                    Text("Routine Complete!")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Great work on your arm care today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                // Stats
                VStack(spacing: 16) {
                    JaegerStatRow(title: "Duration", value: viewModel.sessionDurationString ?? "N/A", icon: "clock")
                    JaegerStatRow(title: "Exercises Completed", value: "\(viewModel.completedExerciseCount)", icon: "checkmark.circle")
                    JaegerStatRow(title: "Exercises Skipped", value: "\(viewModel.skippedExerciseCount)", icon: "forward")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)

                // Post-Routine Soreness
                VStack(alignment: .leading, spacing: 12) {
                    Text("How does your arm feel now?")
                        .font(.headline)

                    HStack {
                        Text("Soreness level:")
                            .font(.subheadline)

                        Spacer()

                        Picker("Soreness", selection: $viewModel.armSorenessAfter) {
                            Text("None").tag(Optional<Int>.none)
                            ForEach(1...10, id: \.self) { level in
                                Text("\(level)").tag(Optional<Int>.some(level))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)

                // Notes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes (Optional)")
                        .font(.headline)

                    TextField("How did the routine feel today?", text: $viewModel.sessionNotes, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)

                // Save Button
                Button(action: {
                    Task {
                        await viewModel.saveSession()
                        onDismiss()
                    }
                }) {
                    HStack {
                        if viewModel.isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                        Text(viewModel.isSaving ? "Saving..." : "Save & Close")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isSaving)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Stat Row

private struct JaegerStatRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 24)

            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - View Model

@MainActor
class JaegerBandViewModel: ObservableObject {
    // Session State
    @Published var selectedVariation: JaegerBandVariation = .full
    @Published var isSessionActive = false
    @Published var isSessionComplete = false
    @Published var currentExerciseIndex = 0

    // Timer State
    @Published var isTimerRunning = false
    @Published var timerRemainingSeconds = 0
    private var timerTask: Task<Void, Never>?

    // Progress Tracking
    @Published var progress = JaegerBandSessionProgress()
    @Published var armSorenessBefore: Int?
    @Published var armSorenessAfter: Int?
    @Published var sessionNotes: String = ""

    // Saving State
    @Published var isSaving = false
    @Published var saveError: Error?

    // Service
    private let service = JaegerBandService()

    // MARK: - Computed Properties

    var currentProtocol: JaegerBandProtocol {
        JaegerBandProtocol.protocolFor(variation: selectedVariation)
    }

    var currentExercise: JaegerBandExercise? {
        guard currentExerciseIndex < currentProtocol.exercises.count else { return nil }
        return currentProtocol.exercises[currentExerciseIndex]
    }

    var totalExercises: Int {
        currentProtocol.exercises.count
    }

    var progressPercentage: Double {
        guard totalExercises > 0 else { return 0 }
        return Double(currentExerciseIndex) / Double(totalExercises)
    }

    var canGoPrevious: Bool {
        currentExerciseIndex > 0
    }

    var isLastExercise: Bool {
        currentExerciseIndex >= totalExercises - 1
    }

    var completedExerciseCount: Int {
        progress.completedExercises.count
    }

    var skippedExerciseCount: Int {
        progress.skippedExercises.count
    }

    var elapsedTimeString: String? {
        guard let start = progress.startTime else { return nil }
        let elapsed = Int(Date().timeIntervalSince(start))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var sessionDurationString: String? {
        guard let start = progress.startTime else { return nil }
        let end = progress.endTime ?? Date()
        let duration = Int(end.timeIntervalSince(start))
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Actions

    func startSession() {
        progress = JaegerBandSessionProgress()
        progress.startTime = Date()
        currentExerciseIndex = 0
        isSessionActive = true
        isSessionComplete = false

        // Initialize timer for first exercise
        if let hold = currentExercise?.holdSeconds {
            timerRemainingSeconds = hold
        }
    }

    func nextExercise() {
        // Mark current as complete
        if let exercise = currentExercise {
            progress.completedExercises.insert(exercise.id)
        }

        // Stop timer
        stopTimer()

        // Move to next
        if currentExerciseIndex < totalExercises - 1 {
            currentExerciseIndex += 1
            // Initialize timer for new exercise
            if let hold = currentExercise?.holdSeconds {
                timerRemainingSeconds = hold
            }
        }
    }

    func previousExercise() {
        guard canGoPrevious else { return }
        stopTimer()
        currentExerciseIndex -= 1
        if let hold = currentExercise?.holdSeconds {
            timerRemainingSeconds = hold
        }
    }

    func skipExercise() {
        // Mark current as skipped
        if let exercise = currentExercise {
            progress.skippedExercises.insert(exercise.id)
        }

        stopTimer()

        if currentExerciseIndex < totalExercises - 1 {
            currentExerciseIndex += 1
            if let hold = currentExercise?.holdSeconds {
                timerRemainingSeconds = hold
            }
        } else {
            completeSession()
        }
    }

    func completeSession() {
        // Mark last exercise as complete
        if let exercise = currentExercise {
            progress.completedExercises.insert(exercise.id)
        }

        stopTimer()
        progress.endTime = Date()
        isSessionActive = false
        isSessionComplete = true
    }

    func endSession() {
        stopTimer()
        progress.endTime = Date()
        isSessionActive = false
        isSessionComplete = true
    }

    func timerCompleted() {
        isTimerRunning = false
        // Could auto-advance or play a sound here
    }

    private func stopTimer() {
        isTimerRunning = false
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Timer Logic

    func startTimer() {
        guard !isTimerRunning else { return }
        isTimerRunning = true

        timerTask = Task {
            while isTimerRunning && timerRemainingSeconds > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
                if isTimerRunning {
                    timerRemainingSeconds -= 1
                    if timerRemainingSeconds <= 0 {
                        timerCompleted()
                    }
                }
            }
        }
    }

    // MARK: - Save Session

    func saveSession() async {
        isSaving = true
        saveError = nil

        do {
            let duration = progress.durationMinutes ?? Int(Date().timeIntervalSince(progress.startTime ?? Date()) / 60)

            try await service.logSession(
                variation: selectedVariation,
                durationMinutes: duration,
                exercisesCompleted: completedExerciseCount,
                exercisesSkipped: skippedExerciseCount,
                notes: sessionNotes.isEmpty ? nil : sessionNotes,
                armSorenessBefore: armSorenessBefore,
                armSorenessAfter: armSorenessAfter,
                wasPreThrowingWarmup: selectedVariation == .preThrow
            )
        } catch {
            saveError = error
        }

        isSaving = false
    }
}

// MARK: - Preview

#if DEBUG
struct JaegerBandView_Previews: PreviewProvider {
    static var previews: some View {
        JaegerBandView()
    }
}
#endif
