import SwiftUI
import AppIntents

/// View showing available Siri commands and shortcuts
/// Helps users discover and set up voice control for the app
@available(iOS 16.0, *)
struct SiriTipsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expandedSection: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Shortcut Cards
                    VStack(spacing: 16) {
                        workoutShortcutCard
                        exerciseLoggingCard
                        readinessCard
                        progressCard
                        timerCard
                    }
                    .padding(.horizontal)

                    // Setup Instructions
                    setupInstructionsSection

                    // Tips Section
                    tipsSection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Siri Shortcuts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Done")
                    .accessibilityHint("Closes the Siri Shortcuts view")
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .accessibilityHidden(true)

            Text("Hey Siri, let's train!")
                .font(.title2.bold())

            Text("Control PT Performance with your voice. Use these phrases to start workouts, log exercises, and track your progress hands-free.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Hey Siri, let's train! Control PT Performance with your voice. Use these phrases to start workouts, log exercises, and track your progress hands-free.")
    }

    // MARK: - Shortcut Cards

    private var workoutShortcutCard: some View {
        ShortcutCard(
            icon: "figure.strengthtraining.traditional",
            iconColor: .orange,
            title: "Start Workout",
            isExpanded: expandedSection == "workout",
            phrases: [
                "Hey Siri, start my workout in PT Performance",
                "Hey Siri, begin training in PT Performance",
                "Hey Siri, start today's workout in PT Performance"
            ],
            description: "Opens your scheduled workout for today and gets you ready to train."
        ) {
            withAnimation {
                expandedSection = expandedSection == "workout" ? nil : "workout"
            }
        }
    }

    private var exerciseLoggingCard: some View {
        ShortcutCard(
            icon: "checklist",
            iconColor: .green,
            title: "Log Exercise",
            isExpanded: expandedSection == "exercise",
            phrases: [
                "Hey Siri, log 3 sets of 10 in PT Performance",
                "Hey Siri, log exercise in PT Performance",
                "Hey Siri, record my sets in PT Performance"
            ],
            description: "Quickly log sets and reps for your current exercise without touching your phone."
        ) {
            withAnimation {
                expandedSection = expandedSection == "exercise" ? nil : "exercise"
            }
        }
    }

    private var readinessCard: some View {
        ShortcutCard(
            icon: "gauge.with.dots.needle.33percent",
            iconColor: .blue,
            title: "Check Readiness",
            isExpanded: expandedSection == "readiness",
            phrases: [
                "Hey Siri, check my readiness in PT Performance",
                "Hey Siri, am I ready to train in PT Performance",
                "Hey Siri, log my readiness in PT Performance"
            ],
            description: "Check your daily readiness score or complete your morning check-in."
        ) {
            withAnimation {
                expandedSection = expandedSection == "readiness" ? nil : "readiness"
            }
        }
    }

    private var progressCard: some View {
        ShortcutCard(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .purple,
            title: "View Progress",
            isExpanded: expandedSection == "progress",
            phrases: [
                "Hey Siri, show my progress in PT Performance",
                "Hey Siri, check my streak in PT Performance",
                "Hey Siri, view workout stats in PT Performance"
            ],
            description: "See your workout streak, completed sessions, and overall progress."
        ) {
            withAnimation {
                expandedSection = expandedSection == "progress" ? nil : "progress"
            }
        }
    }

    private var timerCard: some View {
        ShortcutCard(
            icon: "timer",
            iconColor: .red,
            title: "Rest Timer",
            isExpanded: expandedSection == "timer",
            phrases: [
                "Hey Siri, start rest timer in PT Performance",
                "Hey Siri, start 90 second rest in PT Performance",
                "Hey Siri, time my rest in PT Performance"
            ],
            description: "Start a rest timer between sets without interrupting your flow."
        ) {
            withAnimation {
                expandedSection = expandedSection == "timer" ? nil : "timer"
            }
        }
    }

    // MARK: - Setup Instructions

    private var setupInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Setting Up Shortcuts")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 12) {
                SetupStepRow(
                    number: 1,
                    title: "Open Shortcuts App",
                    description: "Go to Settings > Siri & Search or open the Shortcuts app"
                )

                SetupStepRow(
                    number: 2,
                    title: "Find PT Performance",
                    description: "Search for PT Performance shortcuts in the app gallery"
                )

                SetupStepRow(
                    number: 3,
                    title: "Add to Siri",
                    description: "Tap on a shortcut and follow the prompts to add it"
                )

                SetupStepRow(
                    number: 4,
                    title: "Customize Phrases",
                    description: "You can customize the trigger phrase to anything you like"
                )
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pro Tips")
                .font(.headline)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                TipRow(icon: "apple.watch", text: "Use with Apple Watch for hands-free logging during workouts")
                TipRow(icon: "car.fill", text: "Set up CarPlay shortcuts to start your workout on the way to the gym")
                TipRow(icon: "airpodspro", text: "Works great with AirPods - just say \"Hey Siri\"")
                TipRow(icon: "moon.fill", text: "Create bedtime routines that include logging tomorrow's readiness")
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

// MARK: - Supporting Views

@available(iOS 16.0, *)
struct ShortcutCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let isExpanded: Bool
    let phrases: [String]
    let description: String
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onTap) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(iconColor)
                        .cornerRadius(10)
                        .accessibilityHidden(true)

                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .animation(.easeInOut, value: isExpanded)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel(title)
            .accessibilityHint(isExpanded ? "Collapse to hide Siri phrases" : "Expand to see Siri phrases")
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Divider()

                    Text("Try saying:")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    ForEach(phrases, id: \.self) { phrase in
                        HStack(alignment: .top) {
                            Image(systemName: "quote.bubble.fill")
                                .font(.caption)
                                .foregroundColor(iconColor.opacity(0.7))
                            Text(phrase)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct SetupStepRow: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number): \(title). \(description)")
    }
}

struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

// MARK: - Siri Tips Button (for use in other views)

@available(iOS 16.0, *)
struct SiriTipsButton: View {
    @State private var showingSiriTips = false

    var body: some View {
        Button(action: {
            showingSiriTips = true
        }) {
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .foregroundColor(.purple)
                Text("Siri Shortcuts")
            }
        }
        .accessibilityLabel("Siri Shortcuts")
        .accessibilityHint("Opens a list of available Siri voice commands")
        .sheet(isPresented: $showingSiriTips) {
            SiriTipsView()
        }
    }
}

// MARK: - Compact Siri Tip Card (for onboarding)

@available(iOS 16.0, *)
struct CompactSiriTipCard: View {
    @State private var showingSiriTips = false

    var body: some View {
        Button(action: {
            showingSiriTips = true
        }) {
            HStack(spacing: 16) {
                Image(systemName: "waveform.circle.fill")
                    .font(.title)
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Use Siri Shortcuts")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("\"Hey Siri, start my workout\"")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Use Siri Shortcuts")
        .accessibilityHint("Opens Siri voice command options. Example: Hey Siri, start my workout")
        .sheet(isPresented: $showingSiriTips) {
            SiriTipsView()
        }
    }
}

// MARK: - Preview

@available(iOS 16.0, *)
#Preview {
    SiriTipsView()
}
