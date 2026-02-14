//
//  RestTimerOverlay.swift
//  PTPerformance
//
//  ACP-1015: Rest Timer UX Overhaul
//  Compact floating overlay for rest timer between exercises
//

import SwiftUI

/// Compact floating overlay for rest timer between exercises
/// ACP-1015: Redesigned as bottom sheet with smart suggestions and on-the-fly adjustments
struct RestTimerOverlay: View {
    let timeRemaining: TimeInterval
    let totalTime: TimeInterval
    let onSkip: () -> Void
    let onAdjust: ((TimeInterval) -> Void)?
    let exerciseCategory: String?

    @AppStorage("restTimerAutoDismiss") private var autoDismiss: Bool = false
    @State private var hasTriggeredTenSecondHaptic = false
    @State private var showSettings = false
    @Environment(\.colorScheme) private var colorScheme

    init(
        timeRemaining: TimeInterval,
        totalTime: TimeInterval,
        onSkip: @escaping () -> Void,
        onAdjust: ((TimeInterval) -> Void)? = nil,
        exerciseCategory: String? = nil
    ) {
        self.timeRemaining = timeRemaining
        self.totalTime = totalTime
        self.onSkip = onSkip
        self.onAdjust = onAdjust
        self.exerciseCategory = exerciseCategory
    }

    var body: some View {
        VStack {
            Spacer()

            // Compact floating card
            VStack(spacing: Spacing.md) {
                // Header with settings
                HStack {
                    Text("Rest Period")
                        .font(.headline)
                        .foregroundColor(.modusPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Spacer()

                    Button {
                        HapticFeedback.light()
                        showSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Rest timer settings")
                }

                // Circular countdown with time
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: totalTime > 0 ? timeRemaining / totalTime : 0)
                        .stroke(
                            Color.modusCyan,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timeRemaining)

                    // Time display
                    VStack(spacing: Spacing.xxs) {
                        Text(formatTime(timeRemaining))
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .monospacedDigit()

                        if let suggestion = smartSuggestion {
                            Text(suggestion)
                                .font(.caption2)
                                .foregroundColor(.modusTealAccent)
                        }
                    }
                }
                .frame(width: 160, height: 160)
                .padding(.vertical, Spacing.sm)

                // Adjustment buttons
                if onAdjust != nil {
                    HStack(spacing: Spacing.lg) {
                        adjustButton(seconds: -15, icon: "minus.circle.fill")
                        adjustButton(seconds: 15, icon: "plus.circle.fill")
                    }
                }

                // Skip rest button
                Button {
                    HapticFeedback.medium()
                    onSkip()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "forward.fill")
                        Text("Skip Rest")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.modusCyan)
                    .cornerRadius(CornerRadius.md)
                }
                .accessibilityLabel("Skip rest period")
                .accessibilityHint("Continue to next exercise immediately")
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(Color.modusLightTeal)
                    .shadow(
                        color: Shadow.prominent.color(for: colorScheme),
                        radius: Shadow.prominent.radius,
                        x: Shadow.prominent.x,
                        y: Shadow.prominent.y
                    )
            )
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss on background tap if auto-dismiss is enabled
                    if autoDismiss && timeRemaining <= 0 {
                        onSkip()
                    }
                }
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Rest timer")
        .accessibilityValue("\(Int(timeRemaining)) seconds remaining")
        .accessibilityHint("Use adjustment buttons to add or remove time, or skip to continue")
        .onChange(of: timeRemaining) { oldValue, newValue in
            // Trigger haptic pulse at 10 seconds
            if newValue <= 10 && oldValue > 10 && !hasTriggeredTenSecondHaptic {
                triggerTenSecondPulse()
                hasTriggeredTenSecondHaptic = true
            }

            // Reset haptic trigger if time was added back above 10
            if newValue > 10 {
                hasTriggeredTenSecondHaptic = false
            }

            // Auto-dismiss when timer reaches 0
            if autoDismiss && newValue <= 0 && oldValue > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    HapticFeedback.success()
                    onSkip()
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            RestTimerSettingsSheet(autoDismiss: $autoDismiss)
        }
    }

    // MARK: - Adjustment Button

    @ViewBuilder
    private func adjustButton(seconds: Int, icon: String) -> some View {
        Button {
            HapticFeedback.light()
            let adjustment = TimeInterval(seconds)
            onAdjust?(adjustment)
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                Text("\(abs(seconds))s")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.modusCyan)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(Color.modusCyan, lineWidth: 2)
            )
        }
        .accessibilityLabel(seconds > 0 ? "Add \(seconds) seconds" : "Remove \(abs(seconds)) seconds")
    }

    // MARK: - Smart Suggestions

    private var smartSuggestion: String? {
        guard let category = exerciseCategory?.lowercased() else { return nil }

        // Compound movements (90-180s)
        if category.contains("squat") || category.contains("deadlift") ||
           category.contains("bench") || category.contains("press") ||
           category == "push" || category == "pull" || category == "hinge" {
            return "Compound • 90-180s optimal"
        }

        // Isolation movements (60-90s)
        if category.contains("curl") || category.contains("extension") ||
           category.contains("raise") || category.contains("fly") ||
           category == "isolation" || category.contains("single") {
            return "Isolation • 60-90s optimal"
        }

        // Cardio/conditioning (30-60s)
        if category.contains("cardio") || category.contains("conditioning") ||
           category.contains("sprint") || category.contains("jump") {
            return "Cardio • 30-60s optimal"
        }

        return nil
    }

    // MARK: - Haptic Pulse Sequence

    private func triggerTenSecondPulse() {
        // Three quick light pulses
        HapticFeedback.light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            HapticFeedback.light()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            HapticFeedback.light()
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Settings Sheet

struct RestTimerSettingsSheet: View {
    @Binding var autoDismiss: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle(isOn: $autoDismiss) {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Auto-Dismiss")
                                .font(.body)
                            Text("Automatically continue when rest timer finishes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.modusCyan)
                    .onChange(of: autoDismiss) { _, _ in
                        HapticFeedback.toggle()
                    }
                    .accessibilityLabel("Auto-dismiss rest timer")
                    .accessibilityValue(autoDismiss ? "Enabled" : "Disabled")
                } header: {
                    Text("Timer Behavior")
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text("When enabled, the timer will automatically dismiss and continue to the next exercise when the rest period ends.")
                        .font(.caption)
                }

                Section {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        smartSuggestionRow(
                            title: "Compound Movements",
                            exercises: "Squat, Deadlift, Bench Press",
                            rest: "90-180s"
                        )
                        Divider()
                        smartSuggestionRow(
                            title: "Isolation Movements",
                            exercises: "Curls, Extensions, Raises",
                            rest: "60-90s"
                        )
                        Divider()
                        smartSuggestionRow(
                            title: "Cardio/Conditioning",
                            exercises: "Sprints, Jumps, Burpees",
                            rest: "30-60s"
                        )
                    }
                } header: {
                    Text("Smart Rest Suggestions")
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text("Rest periods are suggested based on exercise type. You can adjust them on-the-fly using the +15s / -15s buttons.")
                        .font(.caption)
                }
            }
            .navigationTitle("Rest Timer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        HapticFeedback.light()
                        dismiss()
                    }
                    .foregroundColor(.modusCyan)
                }
            }
        }
    }

    @ViewBuilder
    private func smartSuggestionRow(title: String, exercises: String, rest: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text(exercises)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(rest)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.modusTealAccent)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct RestTimerOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Compound exercise with adjustment
            RestTimerOverlay(
                timeRemaining: 105,
                totalTime: 120,
                onSkip: {},
                onAdjust: { _ in },
                exerciseCategory: "squat"
            )
            .previewDisplayName("Compound - Squat")

            // Isolation exercise
            RestTimerOverlay(
                timeRemaining: 45,
                totalTime: 60,
                onSkip: {},
                onAdjust: { _ in },
                exerciseCategory: "curl"
            )
            .previewDisplayName("Isolation - Curl")

            // Cardio
            RestTimerOverlay(
                timeRemaining: 30,
                totalTime: 45,
                onSkip: {},
                onAdjust: { _ in },
                exerciseCategory: "cardio"
            )
            .previewDisplayName("Cardio")

            // 10 seconds remaining (haptic trigger)
            RestTimerOverlay(
                timeRemaining: 8,
                totalTime: 90,
                onSkip: {},
                onAdjust: { _ in },
                exerciseCategory: "bench"
            )
            .previewDisplayName("Final Countdown")

            // Dark mode
            RestTimerOverlay(
                timeRemaining: 90,
                totalTime: 120,
                onSkip: {},
                onAdjust: { _ in },
                exerciseCategory: "deadlift"
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
#endif
