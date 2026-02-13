// DARK MODE: See ModeThemeModifier.swift for central theme control
import SwiftUI

/// Main Fasting Tracker Dashboard (ACP-1001)
/// Simplified and enhanced with training-aware features
struct FastingTrackerView: View {
    @StateObject private var viewModel = FastingTrackerViewModel()
    @State private var showingProtocolPicker = false
    @State private var showingHistory = false
    @State private var showingEndFastSheet = false
    @State private var showingErrorRecoverySheet = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if viewModel.isFasting {
                        // Active Fast Card
                        activeFastCard

                        // Fasting Zones Timeline
                        fastingZonesTimeline

                        // Training Sync (if upcoming workout)
                        if viewModel.upcomingWorkout != nil {
                            trainingSyncCard
                        }
                    } else {
                        // Not Fasting - Show Start Options
                        startFastCard

                        // Quick Protocol Buttons
                        quickProtocolButtons

                        // Training Sync Recommendation
                        if viewModel.trainingSyncRecommendation != nil {
                            trainingSyncCard
                        }
                    }

                    // Streak Display
                    streakCard

                    // Navigation to History
                    navigationSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Fasting")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingProtocolPicker = true
                        } label: {
                            Label("Change Protocol", systemImage: "slider.horizontal.3")
                        }

                        Button {
                            showingHistory = true
                        } label: {
                            Label("View History", systemImage: "calendar")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.modusCyan)
                    }
                }
            }
            .sheet(isPresented: $showingProtocolPicker) {
                FastingProtocolPickerView(
                    selectedProtocol: $viewModel.selectedProtocol,
                    customHours: $viewModel.customFastingHours
                ) {
                    showingProtocolPicker = false
                }
            }
            .sheet(isPresented: $showingHistory) {
                FastingHistoryView()
            }
            .sheet(isPresented: $showingEndFastSheet) {
                EndFastSheetView(viewModel: viewModel) {
                    showingEndFastSheet = false
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("Try Again") {
                    Task {
                        await viewModel.loadData()
                    }
                }
                Button("OK", role: .cancel) {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
            .overlay {
                // Celebration overlay when goal is reached
                if viewModel.showCelebration {
                    FastingGoalCelebrationView(
                        elapsedTime: viewModel.formattedElapsedTime,
                        onDismiss: { viewModel.dismissCelebration() }
                    )
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                    .zIndex(100)
                }
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Accessibility Helpers

    private var accessibleTimerLabel: String {
        let hours = Int(viewModel.elapsedHours)
        let minutes = Int((viewModel.elapsedHours - Double(hours)) * 60)

        var label = ""
        if hours > 0 {
            label += "\(hours) hour\(hours == 1 ? "" : "s")"
        }
        if minutes > 0 {
            if hours > 0 { label += " and " }
            label += "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
        if label.isEmpty {
            label = "Just started"
        }
        label += " elapsed"

        if viewModel.goalReached {
            label += ". Goal reached!"
        } else {
            let remainingHours = viewModel.targetHours - hours
            label += ". \(remainingHours) hour\(remainingHours == 1 ? "" : "s") remaining to goal."
        }

        return label
    }

    // MARK: - Active Fast Card

    private var activeFastCard: some View {
        VStack(spacing: Spacing.lg) {
            // Header
            HStack {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundColor(.modusCyan)
                Text("FASTING")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.modusDeepTeal)
                Spacer()
                if viewModel.goalReached {
                    Label("Goal Reached", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.modusTealAccent)
                }
            }

            // Large Timer Display
            VStack(spacing: Spacing.xs) {
                Text(viewModel.formattedElapsedTimeShort)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .accessibilityLabel(accessibleTimerLabel)
                    .accessibilityAddTraits(.updatesFrequently)

                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.modusCyan, .modusTealAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(viewModel.progress, 1.0), height: 8)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                    }
                }
                .frame(height: 8)
                .accessibilityLabel("Progress: \(Int(viewModel.progress * 100)) percent")

                Text("of \(viewModel.formattedTargetTime) goal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Zone Status Indicators
            HStack(spacing: Spacing.xl) {
                ZoneStatusIndicator(
                    icon: "flame.fill",
                    title: "Fat Burning",
                    status: viewModel.isFatBurningActive ? "Active" : "Soon",
                    isActive: viewModel.isFatBurningActive,
                    color: .orange
                )

                ZoneStatusIndicator(
                    icon: "brain.head.profile",
                    title: "Ketosis",
                    status: viewModel.isKetosisActive ? "Active" : (viewModel.isKetosisSoon ? "Soon" : "Later"),
                    isActive: viewModel.isKetosisActive,
                    color: .purple
                )
            }

            // Action Buttons
            HStack(spacing: Spacing.md) {
                // End Fast Button
                Button {
                    HapticFeedback.medium()
                    showingEndFastSheet = true
                } label: {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                        Text("End Fast")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .cornerRadius(CornerRadius.lg)
                }
                .buttonStyle(.plain)

                // Extend Fast Button
                Button {
                    Task {
                        await viewModel.extendFast(byHours: 2)
                    }
                } label: {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Extend +2hrs")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.modusCyan.opacity(0.15))
                    .foregroundColor(.modusCyan)
                    .cornerRadius(CornerRadius.lg)
                }
                .buttonStyle(.plain)
            }

            // Workout Status (if upcoming)
            if let workout = viewModel.upcomingWorkout {
                HStack {
                    Image(systemName: "figure.run")
                        .foregroundColor(.modusCyan)
                    Text("Next workout: \(workout.formattedTimeUntil)")
                        .font(.subheadline)
                    if workout.fastedTrainingOK {
                        Text("(fasted OK)")
                            .font(.caption)
                            .foregroundColor(.modusTealAccent)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.modusTealAccent)
                    }
                    Spacer()
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.modusCyan.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Active fast. Elapsed time: \(viewModel.formattedElapsedTime)")
    }

    // MARK: - Fasting Zones Timeline

    private var fastingZonesTimeline: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Fasting Zones")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            // Timeline visualization
            FastingZoneTimelineView(
                elapsedHours: viewModel.elapsedHours,
                targetHours: Double(viewModel.targetHours),
                currentZone: viewModel.currentZone
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Start Fast Card

    private var startFastCard: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "timer")
                .font(.system(size: 48))
                .foregroundColor(.modusCyan)

            Text("Ready to Start Fasting?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.modusDeepTeal)

            Text("Choose a protocol below or tap to start with \(viewModel.selectedProtocol.displayName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Large Start Button
            Button {
                HapticFeedback.medium()
                Task {
                    await viewModel.startFast()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                    }
                    Text("Start Fast")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .background(
                    LinearGradient(
                        colors: [.modusCyan, .modusTealAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.lg)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
            .shadow(color: Color.modusCyan.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Quick Protocol Buttons

    private var quickProtocolButtons: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Quick Start")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                QuickProtocolButton(
                    protocol_: .sixteen8,
                    isSelected: viewModel.selectedProtocol == .sixteen8
                ) {
                    HapticFeedback.medium()
                    Task {
                        await viewModel.startFastWithProtocol(.sixteen8)
                    }
                }

                QuickProtocolButton(
                    protocol_: .eighteen6,
                    isSelected: viewModel.selectedProtocol == .eighteen6
                ) {
                    HapticFeedback.medium()
                    Task {
                        await viewModel.startFastWithProtocol(.eighteen6)
                    }
                }

                QuickProtocolButton(
                    protocol_: .twenty4,
                    isSelected: viewModel.selectedProtocol == .twenty4
                ) {
                    HapticFeedback.medium()
                    Task {
                        await viewModel.startFastWithProtocol(.twenty4)
                    }
                }

                QuickProtocolButton(
                    protocol_: .omad,
                    isSelected: viewModel.selectedProtocol == .omad
                ) {
                    HapticFeedback.medium()
                    Task {
                        await viewModel.startFastWithProtocol(.omad)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Training Sync Card

    private var trainingSyncCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundColor(.modusCyan)
                Text("TRAINING SYNC")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.modusDeepTeal)
                Spacer()
            }

            if let recommendation = viewModel.trainingSyncRecommendation {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("You have a \(recommendation.workout.name) at \(recommendation.workout.scheduledTime.formatted(date: .omitted, time: .shortened))")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Text("Recommended eating window:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(recommendation.formattedWindow)
                        .font(.headline)
                        .foregroundColor(.modusCyan)

                    Text("(\(recommendation.protocolDisplay))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button {
                    HapticFeedback.medium()
                    viewModel.applyTrainingSyncSchedule()
                } label: {
                    Text("Apply This Schedule")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.modusCyan)
                        .foregroundColor(.white)
                        .cornerRadius(CornerRadius.md)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.modusLightTeal.opacity(0.5))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: Spacing.lg) {
            // Current Streak
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)
                    Text("\(viewModel.currentStreak)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.modusDeepTeal)
                }
                Text("Current Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Current streak: \(viewModel.currentStreak) days")

            Divider()
                .frame(height: 50)
                .accessibilityHidden(true)

            // Best Streak
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                        .accessibilityHidden(true)
                    Text("\(viewModel.bestStreak)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.modusDeepTeal)
                }
                Text("Best Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Best streak: \(viewModel.bestStreak) days")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Navigation Section

    private var navigationSection: some View {
        NavigationLink {
            FastingHistoryView()
        } label: {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.modusCyan)
                Text("View Full History")
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Zone Status Indicator

private struct ZoneStatusIndicator: View {
    let icon: String
    let title: String
    let status: String
    let isActive: Bool
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isActive ? color : .gray)
                .accessibilityHidden(true)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text(status)
                .font(.caption2)
                .foregroundColor(isActive ? color : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(isActive ? color.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(status)")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// MARK: - Quick Protocol Button

private struct QuickProtocolButton: View {
    let protocol_: FastingProtocolType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Text(protocol_.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .modusDeepTeal)

                Text("\(protocol_.fastingHours)h fast")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                isSelected
                    ? AnyShapeStyle(LinearGradient(colors: [.modusCyan, .modusTealAccent], startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(Color(.tertiarySystemGroupedBackground))
            )
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start \(protocol_.displayName) fast, \(protocol_.fastingHours) hours fasting")
        .accessibilityHint(isSelected ? "Currently selected protocol" : "Double tap to start this fast")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Fasting Zone Timeline View

private struct FastingZoneTimelineView: View {
    let elapsedHours: Double
    let targetHours: Double
    let currentZone: FastingZone

    // Timeline zones with hour markers
    private let zones: [(zone: FastingZone, startHour: Double, label: String)] = [
        (.fed, 0, "0hr"),
        (.burningSugar, 0, "4hr"),
        (.fatBurning, 4, "12hr"),
        (.ketosis, 12, "18hr"),
        (.deepKetosis, 18, "48hr"),
        (.autophagy, 48, "")
    ]

    private var maxDisplayHours: Double {
        max(targetHours, 24)
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Zone Labels
            HStack(spacing: 0) {
                Text("Fed")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Sugar")
                    .font(.caption2)
                    .foregroundColor(elapsedHours >= 0 ? .yellow : .secondary)
                Spacer()
                Text("Fat Burning")
                    .font(.caption2)
                    .foregroundColor(elapsedHours >= 4 ? .orange : .secondary)
                Spacer()
                Text("Ketosis")
                    .font(.caption2)
                    .foregroundColor(elapsedHours >= 12 ? .purple : .secondary)
                Spacer()
                Text("Autophagy")
                    .font(.caption2)
                    .foregroundColor(elapsedHours >= 48 ? .purple : .secondary)
            }

            // Timeline Bar
            GeometryReader { geometry in
                let width = geometry.size.width
                let hourWidth = width / maxDisplayHours

                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Zone segments (colored background)
                    HStack(spacing: 0) {
                        // Sugar burning (0-4h)
                        Rectangle()
                            .fill(Color.yellow.opacity(0.3))
                            .frame(width: min(4, maxDisplayHours) * hourWidth)

                        // Fat burning (4-12h)
                        Rectangle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: min(8, max(0, maxDisplayHours - 4)) * hourWidth)

                        // Ketosis (12-18h)
                        Rectangle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: min(6, max(0, maxDisplayHours - 12)) * hourWidth)

                        // Deep Ketosis (18-48h)
                        if maxDisplayHours > 18 {
                            Rectangle()
                                .fill(Color.modusCyan.opacity(0.3))
                                .frame(width: min(30, max(0, maxDisplayHours - 18)) * hourWidth)
                        }
                    }
                    .frame(height: 8)
                    .cornerRadius(CornerRadius.xs)

                    // Progress indicator
                    let progressWidth = min(elapsedHours, maxDisplayHours) * hourWidth
                    RoundedRectangle(cornerRadius: 4)
                        .fill(currentZone.color)
                        .frame(width: max(0, progressWidth), height: 8)

                    // Current position indicator
                    Circle()
                        .fill(currentZone.color)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                        .shadow(color: currentZone.color.opacity(0.5), radius: 4)
                        .offset(x: max(0, progressWidth - 8))
                }
            }
            .frame(height: 16)

            // Hour markers
            HStack(spacing: 0) {
                Text("0hr")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("4hr")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("12hr")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("18hr")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(maxDisplayHours))hr")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Current position label
            HStack {
                Spacer()
                Text("YOU ARE HERE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(currentZone.color)
                Spacer()
            }
        }
    }
}

// MARK: - End Fast Sheet

private struct EndFastSheetView: View {
    @ObservedObject var viewModel: FastingTrackerViewModel
    let onDismiss: () -> Void

    @State private var energyLevel: Int = 5
    @State private var moodEnd: Int = 5
    @State private var hungerLevel: Int = 5
    @State private var notes: String = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: Spacing.sm) {
                        Text("Fast Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.formattedElapsedTime)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.modusTealAccent)

                        if viewModel.goalReached {
                            Label("Goal Reached!", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.modusTealAccent)
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }

                Section("How do you feel?") {
                    Stepper("Energy Level: \(energyLevel)/10", value: $energyLevel, in: 1...10)
                    Stepper("Mood: \(moodEnd)/10", value: $moodEnd, in: 1...10)
                    Stepper("Hunger Level: \(hungerLevel)/10", value: $hungerLevel, in: 1...10)
                }

                Section("Notes") {
                    TextField("Any observations? (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Show error if any
                if let error = viewModel.error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("End Fast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        isSaving = true
                        HapticFeedback.light()
                        Task {
                            await viewModel.endFast(
                                energyLevel: energyLevel,
                                notes: notes.isEmpty ? nil : notes,
                                moodEnd: moodEnd,
                                hungerLevel: hungerLevel
                            )
                            isSaving = false
                            // Only dismiss if there was no error
                            if viewModel.error == nil {
                                HapticFeedback.success()
                                onDismiss()
                            } else {
                                HapticFeedback.error()
                            }
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Complete")
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving)
                }
            }
        }
    }
}

// MARK: - Goal Celebration View

private struct FastingGoalCelebrationView: View {
    let elapsedTime: String
    let onDismiss: () -> Void

    @State private var animateConfetti = false
    @State private var animateScale = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Celebration card
            VStack(spacing: Spacing.xl) {
                // Trophy icon with animation
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.yellow.opacity(0.6), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(animateScale ? 1.2 : 1.0)
                        .opacity(animateScale ? 0.8 : 0.4)

                    // Trophy
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(animateScale ? 1.1 : 1.0)
                }

                VStack(spacing: Spacing.sm) {
                    Text("Goal Reached!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("You fasted for \(elapsedTime)")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))

                    Text("Amazing discipline!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, Spacing.xs)
                }

                // Dismiss button
                Button {
                    onDismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.modusDeepTeal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.white)
                        .cornerRadius(CornerRadius.lg)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Spacing.xl)
            }
            .padding(Spacing.xl)

            // Confetti particles (if motion is not reduced)
            if !reduceMotion && animateConfetti {
                FastingConfettiView()
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    animateScale = true
                }
                animateConfetti = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Goal reached! You fasted for \(elapsedTime). Tap to continue.")
        .accessibilityAddTraits(.isModal)
    }
}

// MARK: - Confetti View

private struct FastingConfettiView: View {
    @State private var particles: [FastingConfettiParticle] = []

    private let colors: [Color] = [.yellow, .orange, .modusCyan, .modusTealAccent, .purple, .pink]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        for i in 0..<50 {
            let particle = FastingConfettiParticle(
                id: i,
                color: colors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 4...10),
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                opacity: 1.0
            )
            particles.append(particle)

            // Animate each particle falling
            withAnimation(
                .easeIn(duration: Double.random(in: 1.5...3.0))
                .delay(Double.random(in: 0...0.5))
            ) {
                if let index = particles.firstIndex(where: { $0.id == i }) {
                    particles[index].position.y = size.height + 20
                    particles[index].position.x += CGFloat.random(in: -50...50)
                    particles[index].opacity = 0
                }
            }
        }
    }
}

private struct FastingConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

// MARK: - Preview

#if DEBUG
struct FastingTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        FastingTrackerView()
    }
}
#endif
