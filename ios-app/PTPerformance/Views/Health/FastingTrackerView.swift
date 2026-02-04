import SwiftUI

/// Main Fasting Tracker Dashboard (ACP-1001)
/// Provides a comprehensive overview of fasting status, timer, and quick actions
struct FastingTrackerView: View {
    @StateObject private var viewModel = FastingTrackerViewModel()
    @State private var showingProtocolPicker = false
    @State private var showingHistory = false
    @State private var showingEndFastSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Current Fasting Status Card
                    statusCard

                    // Timer View
                    FastingTimerView(
                        isActive: viewModel.isFasting,
                        elapsedSeconds: viewModel.elapsedSeconds,
                        targetSeconds: viewModel.targetSeconds,
                        currentPhase: viewModel.currentPhase
                    )
                    .padding(.vertical, Spacing.md)

                    // Start/Stop Button
                    actionButton

                    // Current Protocol Display
                    if let protocol_ = viewModel.currentProtocol {
                        protocolCard(protocol_)
                    }

                    // Streak Counter
                    streakCard

                    // Quick Stats
                    quickStatsSection

                    // Navigation Links
                    navigationSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Fasting Tracker")
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
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Circle()
                    .fill(viewModel.isFasting ? Color.modusTealAccent : Color.orange.opacity(0.8))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(viewModel.isFasting ? Color.modusTealAccent.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 3)
                            .scaleEffect(viewModel.isFasting ? 1.5 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.isFasting)
                    )

                Text(viewModel.isFasting ? "Fasting" : "Eating Window")
                    .font(.headline)
                    .foregroundColor(viewModel.isFasting ? .modusTealAccent : .orange)

                Spacer()

                if viewModel.isFasting, let startTime = viewModel.fastStartTime {
                    Text("Started \(startTime.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if viewModel.isFasting {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Time Elapsed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.formattedElapsedTime)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.modusCyan)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Time Remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.formattedRemainingTime)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.remainingSeconds > 0 ? .primary : .modusTealAccent)
                    }
                }
            } else {
                Text("Tap below to start your fasting window")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button {
            HapticFeedback.medium()
            if viewModel.isFasting {
                showingEndFastSheet = true
            } else {
                Task {
                    await viewModel.startFast()
                }
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: viewModel.isFasting ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                Text(viewModel.isFasting ? "End Fast" : "Start Fast")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                viewModel.isFasting
                    ? LinearGradient(colors: [.orange, .red.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [.modusCyan, .modusTealAccent], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.lg)
        }
        .buttonStyle(.plain)
        .shadow(color: (viewModel.isFasting ? Color.orange : Color.modusCyan).opacity(0.3), radius: 8, x: 0, y: 4)
    }

    // MARK: - Protocol Card

    private func protocolCard(_ protocol_: FastingProtocolType) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Protocol")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(protocol_.displayName)
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Target")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(protocol_.fastingHours)h fast / \(protocol_.eatingHours)h eat")
                    .font(.subheadline)
                    .foregroundColor(.modusCyan)
            }

            Button {
                showingProtocolPicker = true
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .foregroundColor(.modusCyan.opacity(0.6))
            }
        }
        .padding()
        .background(Color.modusLightTeal.opacity(0.5))
        .cornerRadius(CornerRadius.md)
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

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                StatCard(
                    title: "Completed",
                    value: "\(viewModel.weeklyCompletedFasts)",
                    icon: "checkmark.circle.fill",
                    color: .modusTealAccent
                )

                StatCard(
                    title: "Avg Hours",
                    value: String(format: "%.1f", viewModel.weeklyAverageHours),
                    icon: "clock.fill",
                    color: .modusCyan
                )

                StatCard(
                    title: "Compliance",
                    value: "\(Int(viewModel.weeklyCompliance * 100))%",
                    icon: "chart.bar.fill",
                    color: .modusDeepTeal
                )
            }
        }
    }

    // MARK: - Navigation Section

    private var navigationSection: some View {
        VStack(spacing: Spacing.sm) {
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
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .accessibilityHidden(true)

            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
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

                        if viewModel.elapsedSeconds >= viewModel.targetSeconds {
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
            }
            .navigationTitle("End Fast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Complete") {
                        Task {
                            await viewModel.endFast(
                                energyLevel: energyLevel,
                                notes: notes.isEmpty ? nil : notes,
                                moodEnd: moodEnd,
                                hungerLevel: hungerLevel
                            )
                            onDismiss()
                        }
                    }
                    .fontWeight(.semibold)
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
