import SwiftUI

/// Main Fasting Tracker Dashboard (ACP-1001)
/// Simplified and enhanced with training-aware features
struct FastingTrackerView: View {
    @StateObject private var viewModel = FastingTrackerViewModel()
    @State private var showingProtocolPicker = false
    @State private var showingHistory = false
    @State private var showingEndFastSheet = false

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
                Button("OK", role: .cancel) { }
            } message: {
                if let error = viewModel.error {
                    Text(error)
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
                    }
                }
                .frame(height: 8)

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
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: min(30, max(0, maxDisplayHours - 18)) * hourWidth)
                        }
                    }
                    .frame(height: 8)
                    .cornerRadius(4)

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
                                .stroke(Color.white, lineWidth: 2)
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
                                onDismiss()
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

// MARK: - Preview

#if DEBUG
struct FastingTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        FastingTrackerView()
    }
}
#endif
