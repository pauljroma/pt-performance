import SwiftUI

/// Daily readiness check-in view
/// BUILD 116 - Agent 16: ReadinessCheckInView
///
/// Responsibilities:
/// - Daily wellness metrics input form
/// - Sleep, soreness, energy, stress tracking
/// - Live score preview as user inputs
/// - Integration with ReadinessCheckInViewModel
/// - Success/error feedback
///
/// Design:
/// - Clean medical-themed UI
/// - Color-coded sliders
/// - Live score calculation
/// - Validation feedback
struct ReadinessCheckInView: View {
    // MARK: - Dependencies

    @StateObject private var viewModel: ReadinessCheckInViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - UI State

    @State private var showingSuccessAnimation = false

    // MARK: - Initialization

    /// Initialize with patient ID
    /// - Parameter patientId: UUID of the patient
    init(patientId: UUID) {
        _viewModel = StateObject(wrappedValue: ReadinessCheckInViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                Form {
                    headerSection
                    sleepSection
                    sorenessSection
                    energySection
                    stressSection
                    notesSection
                    scorePreviewSection
                    submitSection
                }
                .navigationTitle("Daily Check-In")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .disabled(viewModel.isLoading)
                .alert("Error", isPresented: $viewModel.showError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(viewModel.errorMessage)
                }
                .task {
                    await viewModel.loadTodayEntry()
                }

                // Success overlay
                if viewModel.showSuccess {
                    successOverlay
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(dateString)
                    .font(.headline)
                    .foregroundColor(.primary)

                if viewModel.hasSubmittedToday {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("You've already checked in today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("How are you feeling today?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's date: \(dateString)")
    }

    // MARK: - Sleep Section

    private var sleepSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Text("Sleep")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.sleepHoursLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Slider(
                    value: $viewModel.sleepHours,
                    in: 0...12,
                    step: 0.5
                ) {
                    Text("Sleep Hours")
                } minimumValueLabel: {
                    Text("0")
                        .font(.caption)
                } maximumValueLabel: {
                    Text("12")
                        .font(.caption)
                }
                .tint(.blue)
                .accessibilityValue(viewModel.sleepHoursLabel)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Sleep Quality")
        } footer: {
            Text("How many hours did you sleep last night?")
        }
    }

    // MARK: - Soreness Section

    private var sorenessSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(viewModel.sorenessColor)
                        .frame(width: 24)
                    Text("Soreness")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.sorenessLevelLabel)
                        .font(.subheadline)
                        .foregroundColor(viewModel.sorenessColor)
                }

                HStack(spacing: 4) {
                    ForEach(1...10, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(level <= viewModel.sorenessLevel ? viewModel.sorenessColor : Color.gray.opacity(0.3))
                            .frame(height: 24)
                    }
                }

                Slider(
                    value: Binding(
                        get: { Double(viewModel.sorenessLevel) },
                        set: { viewModel.sorenessLevel = Int($0) }
                    ),
                    in: 1...10,
                    step: 1
                ) {
                    Text("Soreness Level")
                } minimumValueLabel: {
                    VStack {
                        Text("😊")
                        Text("None")
                            .font(.caption2)
                    }
                } maximumValueLabel: {
                    VStack {
                        Text("😣")
                        Text("Severe")
                            .font(.caption2)
                    }
                }
                .tint(viewModel.sorenessColor)
                .accessibilityValue(viewModel.sorenessLevelLabel)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Muscle Soreness")
        } footer: {
            Text("Rate your overall muscle soreness (1 = no soreness, 10 = extreme)")
        }
    }

    // MARK: - Energy Section

    private var energySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(viewModel.energyColor)
                        .frame(width: 24)
                    Text("Energy")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.energyLevelLabel)
                        .font(.subheadline)
                        .foregroundColor(viewModel.energyColor)
                }

                HStack(spacing: 4) {
                    ForEach(1...10, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(level <= viewModel.energyLevel ? viewModel.energyColor : Color.gray.opacity(0.3))
                            .frame(height: 24)
                    }
                }

                Slider(
                    value: Binding(
                        get: { Double(viewModel.energyLevel) },
                        set: { viewModel.energyLevel = Int($0) }
                    ),
                    in: 1...10,
                    step: 1
                ) {
                    Text("Energy Level")
                } minimumValueLabel: {
                    VStack {
                        Text("😴")
                        Text("Low")
                            .font(.caption2)
                    }
                } maximumValueLabel: {
                    VStack {
                        Text("⚡️")
                        Text("High")
                            .font(.caption2)
                    }
                }
                .tint(viewModel.energyColor)
                .accessibilityValue(viewModel.energyLevelLabel)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Energy Level")
        } footer: {
            Text("How energized do you feel? (1 = exhausted, 10 = fully energized)")
        }
    }

    // MARK: - Stress Section

    private var stressSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(viewModel.stressColor)
                        .frame(width: 24)
                    Text("Stress")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.stressLevelLabel)
                        .font(.subheadline)
                        .foregroundColor(viewModel.stressColor)
                }

                HStack(spacing: 4) {
                    ForEach(1...10, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(level <= viewModel.stressLevel ? viewModel.stressColor : Color.gray.opacity(0.3))
                            .frame(height: 24)
                    }
                }

                Slider(
                    value: Binding(
                        get: { Double(viewModel.stressLevel) },
                        set: { viewModel.stressLevel = Int($0) }
                    ),
                    in: 1...10,
                    step: 1
                ) {
                    Text("Stress Level")
                } minimumValueLabel: {
                    VStack {
                        Text("😌")
                        Text("Calm")
                            .font(.caption2)
                    }
                } maximumValueLabel: {
                    VStack {
                        Text("😰")
                        Text("High")
                            .font(.caption2)
                    }
                }
                .tint(viewModel.stressColor)
                .accessibilityValue(viewModel.stressLevelLabel)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Stress Level")
        } footer: {
            Text("How stressed do you feel? (1 = no stress, 10 = extreme stress)")
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section {
            TextField("Add any notes...", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.plain)
                .accessibilityLabel("Notes")
                .accessibilityHint("Optional notes about your wellness today")
        } header: {
            Text("Notes (Optional)")
        } footer: {
            Text("Any additional details about how you're feeling?")
        }
    }

    // MARK: - Score Preview Section

    private var scorePreviewSection: some View {
        Section {
            // BUILD 123: Show live score preview during form entry
            if let entry = viewModel.todayEntry, let score = entry.readinessScore {
                // Submitted entry - show actual score from database
                scorePreviewCard(score: score)
            } else {
                // No submission yet - show live calculated score
                liveScorePreviewCard
            }
        } header: {
            Text("Readiness Score Preview")
        }
    }

    /// BUILD 123: Live score preview card with battery visualization
    private var liveScorePreviewCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Battery-style circle indicator
                ZStack {
                    Circle()
                        .fill(viewModel.liveScoreCategory.color)
                        .frame(width: 80, height: 80)

                    Text(viewModel.liveScoreFormatted)
                        .font(.title.bold())
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.liveScoreCategory.displayName)
                        .font(.title2.bold())
                        .foregroundColor(viewModel.liveScoreCategory.color)

                    Text("Live Preview")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Updates as you adjust sliders")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(viewModel.liveScoreCategory.color.opacity(0.1))
            .cornerRadius(12)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Live readiness score preview: \(viewModel.liveScoreFormatted), \(viewModel.liveScoreCategory.displayName)")
            .accessibilityHint("Score updates automatically as you adjust the sliders")
        }
    }

    // MARK: - Submit Section

    private var submitSection: some View {
        Section {
            Button {
                Task {
                    await submitCheckIn()
                }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text(viewModel.hasSubmittedToday ? "Update Check-In" : "Submit Check-In")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(!viewModel.canSubmit)
            .buttonStyle(.borderedProminent)
            .listRowBackground(viewModel.canSubmit ? Color.accentColor : Color.gray.opacity(0.3))
            .accessibilityLabel(viewModel.hasSubmittedToday ? "Update today's check-in" : "Submit today's check-in")
            .accessibilityHint(viewModel.canSubmit ? "Tap to submit" : "Complete all required fields to enable")
        }
    }

    // MARK: - Score Preview Card

    private func scorePreviewCard(score: Double) -> some View {
        let category = ReadinessCategory.category(for: score)

        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", score))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(category.color)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(category.displayName)
                        .font(.headline)
                        .foregroundColor(category.color)
                    Text("Readiness")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            HStack {
                Image(systemName: category.recommendsRest ? "bed.double.fill" : "figure.run")
                    .foregroundColor(category.color)
                Text(category.recommendation)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(category.color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(category.color.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Readiness score: \(String(format: "%.1f", score)), \(category.displayName). \(category.recommendation)")
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .scaleEffect(showingSuccessAnimation ? 1.0 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showingSuccessAnimation)

                Text(viewModel.hasSubmittedToday ? "Check-In Updated!" : "Check-In Submitted!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
            .onAppear {
                showingSuccessAnimation = true

                // Auto-dismiss after success animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
        .transition(.opacity)
    }

    // MARK: - Helper Methods

    /// Submit the check-in
    private func submitCheckIn() async {
        await viewModel.submitReadiness()
    }

    /// Format today's date
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ReadinessCheckInView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Empty check-in (new entry)
            ReadinessCheckInView(patientId: UUID())
                .previewDisplayName("New Check-In")

            // Existing check-in (update)
            ReadinessCheckInView(patientId: UUID())
                .previewDisplayName("Update Check-In")
                .onAppear {
                    // Simulate existing entry in preview
                }

            // Dark mode
            ReadinessCheckInView(patientId: UUID())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")

            // iPad
            ReadinessCheckInView(patientId: UUID())
                .previewDevice("iPad Pro (12.9-inch) (6th generation)")
                .previewDisplayName("iPad")
        }
    }
}
#endif
