//
//  StandaloneTimerView.swift
//  PTPerformance
//
//  Created by Build 94 Agent 2
//  Standalone access to Tabata and EMOM timers
//

import SwiftUI

/// Standalone timer picker view for accessing Tabata and EMOM timers
struct StandaloneTimerView: View {
    @State private var selectedTemplate: IntervalTimerTemplate?
    @State private var showTimer = false
    @State private var customTemplate: IntervalTimerTemplate?
    @State private var showCustomBuilder = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interval Timers")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Choose a preset timer or create your own custom interval workout")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Preset Timers
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preset Timers")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            // Tabata Timer
                            TimerTemplateCard(
                                template: .tabata,
                                onSelect: {
                                    selectedTemplate = .tabata
                                    showTimer = true
                                }
                            )

                            // EMOM Timer
                            TimerTemplateCard(
                                template: .emom,
                                onSelect: {
                                    selectedTemplate = .emom
                                    showTimer = true
                                }
                            )

                            // Cardio Timer
                            TimerTemplateCard(
                                template: .cardio,
                                onSelect: {
                                    selectedTemplate = .cardio
                                    showTimer = true
                                }
                            )

                            // Recovery Timer
                            TimerTemplateCard(
                                template: .recovery,
                                onSelect: {
                                    selectedTemplate = .recovery
                                    showTimer = true
                                }
                            )
                        }
                        .padding(.horizontal)
                    }

                    Divider()
                        .padding(.vertical)

                    // Custom Timer Builder
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Custom Timer")
                            .font(.headline)
                            .padding(.horizontal)

                        Button(action: {
                            showCustomBuilder = true
                        }) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                                    .frame(width: 50)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Build Custom Timer")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text("Create your own interval protocol")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .adaptiveShadow(Shadow.subtle)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showTimer) {
                if let template = selectedTemplate {
                    StandaloneIntervalTimerWrapper(template: template)
                }
            }
            .sheet(isPresented: $showCustomBuilder) {
                StandaloneCustomTimerBuilder { template in
                    customTemplate = template
                    selectedTemplate = template
                    showCustomBuilder = false
                    showTimer = true
                }
            }
        }
    }
}

/// Card displaying a timer template
struct TimerTemplateCard: View {
    let template: IntervalTimerTemplate
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: template.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(template.color)
                    .frame(width: 50, height: 50)
                    .background(template.color.opacity(0.15))
                    .cornerRadius(10)

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(template.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    // Timing info
                    HStack(spacing: 12) {
                        Label(template.timingDisplay, systemImage: "clock.fill")
                        Label("\(template.rounds) rounds", systemImage: "repeat")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Play button
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(template.color)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .adaptiveShadow(Shadow.subtle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(template.color.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Wrapper to convert IntervalTimerTemplate to SessionIntervalBlock
struct StandaloneIntervalTimerWrapper: View {
    let template: IntervalTimerTemplate
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        IntervalTimerView(
            intervalBlock: template.toSessionBlock(),
            onComplete: { duration, rpe in
                // For standalone timers, just dismiss (no saving to database)
                print("✅ Timer completed: \(duration)s, RPE: \(rpe)")
                dismiss()
            }
        )
    }
}

/// Standalone custom timer builder (for quick timer creation)
struct StandaloneCustomTimerBuilder: View {
    let onComplete: (IntervalTimerTemplate) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var workDuration = 20
    @State private var restDuration = 10
    @State private var rounds = 8

    var body: some View {
        NavigationStack {
            Form {
                Section("Timer Name") {
                    TextField("E.g., My Custom Tabata", text: $name)
                }

                Section("Work Interval") {
                    Stepper("\(workDuration) seconds", value: $workDuration, in: 5...120, step: 5)
                }

                Section("Rest Interval") {
                    Stepper("\(restDuration) seconds", value: $restDuration, in: 5...120, step: 5)
                }

                Section("Rounds") {
                    Stepper("\(rounds) rounds", value: $rounds, in: 1...20)
                }

                Section {
                    // Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.headline)

                        Text("\(workDuration)s work / \(restDuration)s rest × \(rounds) rounds")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        let totalTime = (workDuration + restDuration) * rounds
                        let minutes = totalTime / 60
                        let seconds = totalTime % 60
                        Text("Total duration: \(minutes)m \(seconds)s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Custom Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start") {
                        let template = IntervalTimerTemplate.custom(
                            name: name.isEmpty ? "Custom Timer" : name,
                            workDuration: workDuration,
                            restDuration: restDuration,
                            rounds: rounds
                        )
                        onComplete(template)
                        dismiss()
                    }
                    .disabled(workDuration < 5 || restDuration < 5 || rounds < 1)
                }
            }
        }
    }
}

// MARK: - Timer Template Model

/// Interval timer template for preset and custom timers
enum IntervalTimerTemplate {
    case tabata
    case emom
    case cardio
    case recovery
    case custom(name: String, workDuration: Int, restDuration: Int, rounds: Int)

    var name: String {
        switch self {
        case .tabata:
            return "Tabata Timer"
        case .emom:
            return "EMOM Timer"
        case .cardio:
            return "Cardio Timer"
        case .recovery:
            return "Active Recovery"
        case .custom(let name, _, _, _):
            return name
        }
    }

    var description: String {
        switch self {
        case .tabata:
            return "Classic Tabata protocol - high intensity intervals for maximum calorie burn"
        case .emom:
            return "Every Minute On the Minute - complete work at the start of each minute"
        case .cardio:
            return "Extended cardio intervals for endurance training"
        case .recovery:
            return "Light movement intervals for active recovery days"
        case .custom:
            return "Custom interval protocol"
        }
    }

    var workDuration: Int {
        switch self {
        case .tabata:
            return 20
        case .emom:
            return 40
        case .cardio:
            return 60
        case .recovery:
            return 30
        case .custom(_, let work, _, _):
            return work
        }
    }

    var restDuration: Int {
        switch self {
        case .tabata:
            return 10
        case .emom:
            return 20
        case .cardio:
            return 30
        case .recovery:
            return 30
        case .custom(_, _, let rest, _):
            return rest
        }
    }

    var rounds: Int {
        switch self {
        case .tabata:
            return 8
        case .emom:
            return 10
        case .cardio:
            return 6
        case .recovery:
            return 5
        case .custom(_, _, _, let rounds):
            return rounds
        }
    }

    var iconName: String {
        switch self {
        case .tabata:
            return "flame.fill"
        case .emom:
            return "clock.fill"
        case .cardio:
            return "heart.fill"
        case .recovery:
            return "wind"
        case .custom:
            return "slider.horizontal.3"
        }
    }

    var color: Color {
        switch self {
        case .tabata:
            return .orange
        case .emom:
            return .blue
        case .cardio:
            return .red
        case .recovery:
            return .green
        case .custom:
            return .purple
        }
    }

    var timingDisplay: String {
        "\(workDuration)s / \(restDuration)s"
    }

    /// Convert to SessionIntervalBlock for use with IntervalTimerView
    func toSessionBlock() -> SessionIntervalBlock {
        SessionIntervalBlock(
            name: name,
            blockType: "standalone",
            description: description,
            workDuration: workDuration,
            restDuration: restDuration,
            rounds: rounds,
            exercises: []  // No specific exercises for standalone timers
        )
    }
}

// MARK: - Preview

#if DEBUG
struct StandaloneTimerView_Previews: PreviewProvider {
    static var previews: some View {
        StandaloneTimerView()
    }
}
#endif
