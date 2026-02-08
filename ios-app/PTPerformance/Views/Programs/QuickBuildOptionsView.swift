//
//  QuickBuildOptionsView.swift
//  PTPerformance
//
//  Quick Build templates feature for the enhanced program builder.
//  Provides pre-built program template cards for rapid program creation.
//

import SwiftUI

// MARK: - Quick Build Option Model

/// Represents a pre-built program template for quick creation
struct QuickBuildOption: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let estimatedSetupTime: String
    let category: ProgramCategory
    let difficulty: DifficultyLevel
    let phases: [QuickBuildPhase]
    let isCustom: Bool

    /// A phase definition for quick builds
    struct QuickBuildPhase {
        let name: String
        let durationWeeks: Int
        let goals: String
    }

    /// Total duration of all phases in weeks
    var totalDurationWeeks: Int {
        phases.reduce(0) { $0 + $1.durationWeeks }
    }
}

// MARK: - Quick Build Options View

struct QuickBuildOptionsView: View {
    @ObservedObject var viewModel: TherapistProgramBuilderViewModel
    var onQuickBuildSelected: ((QuickBuildOption) -> Void)?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Build Templates")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("Start with a pre-built template or create from scratch")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // Grid of options
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(QuickBuildOption.allOptions) { option in
                    QuickBuildCard(option: option) {
                        applyQuickBuild(option)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func applyQuickBuild(_ option: QuickBuildOption) {
        viewModel.applyQuickBuild(option)
        onQuickBuildSelected?(option)
    }
}

// MARK: - Quick Build Card

private struct QuickBuildCard: View {
    let option: QuickBuildOption
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon and category badge
                HStack {
                    Image(systemName: option.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(option.color)
                        .cornerRadius(10)

                    Spacer()

                    // Setup time badge
                    Text(option.estimatedSetupTime)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(6)
                }

                // Title
                Text(option.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Subtitle (duration)
                Text(option.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Category tag
                if !option.isCustom {
                    HStack(spacing: 4) {
                        Image(systemName: option.category.icon)
                            .font(.caption2)
                        Text(option.category.displayName)
                            .font(.caption2)
                    }
                    .foregroundColor(option.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(option.color.opacity(0.15))
                    .cornerRadius(6)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(option.title), \(option.subtitle)")
        .accessibilityHint("Double tap to start building with this template. Estimated setup time: \(option.estimatedSetupTime)")
    }
}

// MARK: - Predefined Quick Build Options

extension QuickBuildOption {
    /// All available quick build options
    static let allOptions: [QuickBuildOption] = [
        postOpRecovery,
        returnToSport,
        strengthFoundation,
        aclProtocol,
        customProgram
    ]

    /// 4-Week Post-Op Recovery (Rehab)
    static let postOpRecovery = QuickBuildOption(
        title: "4-Week Post-Op Recovery",
        subtitle: "4 weeks",
        icon: "cross.case.fill",
        color: .blue,
        estimatedSetupTime: "~2 min",
        category: .recovery,
        difficulty: .beginner,
        phases: [
            QuickBuildPhase(
                name: "Protection",
                durationWeeks: 1,
                goals: "Protect surgical site, manage pain and swelling, begin gentle ROM"
            ),
            QuickBuildPhase(
                name: "Early Motion",
                durationWeeks: 1,
                goals: "Restore ROM, reduce swelling, begin light activation exercises"
            ),
            QuickBuildPhase(
                name: "Strengthening",
                durationWeeks: 1,
                goals: "Progressive strengthening, improve stability, functional movements"
            ),
            QuickBuildPhase(
                name: "Return to Activity",
                durationWeeks: 1,
                goals: "Sport-specific preparation, full strength, gradual return to activities"
            )
        ],
        isCustom: false
    )

    /// 8-Week Return to Sport (Performance)
    static let returnToSport = QuickBuildOption(
        title: "8-Week Return to Sport",
        subtitle: "8 weeks",
        icon: "figure.run",
        color: .green,
        estimatedSetupTime: "~2 min",
        category: .sport,
        difficulty: .intermediate,
        phases: [
            QuickBuildPhase(
                name: "Foundation",
                durationWeeks: 2,
                goals: "Build aerobic base, movement quality, joint preparation"
            ),
            QuickBuildPhase(
                name: "Build",
                durationWeeks: 2,
                goals: "Increase training volume, sport-specific conditioning, strength development"
            ),
            QuickBuildPhase(
                name: "Peak",
                durationWeeks: 2,
                goals: "High-intensity training, competition simulation, performance optimization"
            ),
            QuickBuildPhase(
                name: "Taper",
                durationWeeks: 2,
                goals: "Reduce volume, maintain intensity, optimize recovery for competition"
            )
        ],
        isCustom: false
    )

    /// 12-Week Strength Foundation (Strength)
    static let strengthFoundation = QuickBuildOption(
        title: "12-Week Strength Foundation",
        subtitle: "12 weeks",
        icon: "dumbbell.fill",
        color: .orange,
        estimatedSetupTime: "~2 min",
        category: .strength,
        difficulty: .intermediate,
        phases: [
            QuickBuildPhase(
                name: "Adaptation",
                durationWeeks: 3,
                goals: "Movement proficiency, work capacity, tissue preparation"
            ),
            QuickBuildPhase(
                name: "Hypertrophy",
                durationWeeks: 3,
                goals: "Muscle growth, increased volume, progressive overload"
            ),
            QuickBuildPhase(
                name: "Strength",
                durationWeeks: 3,
                goals: "Maximal strength development, neural adaptations, compound lifts"
            ),
            QuickBuildPhase(
                name: "Power",
                durationWeeks: 3,
                goals: "Rate of force development, explosive training, sport transfer"
            )
        ],
        isCustom: false
    )

    /// 6-Week ACL Protocol (Rehab)
    static let aclProtocol = QuickBuildOption(
        title: "6-Week ACL Protocol",
        subtitle: "6 weeks",
        icon: "figure.walk",
        color: .purple,
        estimatedSetupTime: "~2 min",
        category: .recovery,
        difficulty: .beginner,
        phases: [
            QuickBuildPhase(
                name: "Early Rehab",
                durationWeeks: 2,
                goals: "Reduce swelling, restore ROM, quad activation, gait normalization"
            ),
            QuickBuildPhase(
                name: "Progressive Loading",
                durationWeeks: 2,
                goals: "Strength progression, single-leg stability, controlled loading"
            ),
            QuickBuildPhase(
                name: "Advanced Training",
                durationWeeks: 2,
                goals: "Plyometrics introduction, sport-specific movements, return to running"
            )
        ],
        isCustom: false
    )

    /// Custom Program (Blank slate)
    static let customProgram = QuickBuildOption(
        title: "Custom Program",
        subtitle: "Build from scratch",
        icon: "square.and.pencil",
        color: .gray,
        estimatedSetupTime: "~5 min",
        category: .strength,
        difficulty: .intermediate,
        phases: [],
        isCustom: true
    )
}

// MARK: - ViewModel Extension

extension TherapistProgramBuilderViewModel {
    /// Applies a quick build template to the current program
    func applyQuickBuild(_ option: QuickBuildOption) {
        // Clear existing data if this is a template (not custom)
        if !option.isCustom {
            // Set program name to template name
            programName = option.title

            // Set category
            category = option.category.rawValue

            // Set difficulty
            difficultyLevel = option.difficulty.rawValue

            // Set duration based on template
            durationWeeks = option.totalDurationWeeks

            // Pre-create phases with names and durations
            phases = option.phases.enumerated().map { index, phaseData in
                TherapistPhaseData(
                    name: phaseData.name,
                    sequence: index + 1,
                    durationWeeks: phaseData.durationWeeks,
                    goals: phaseData.goals,
                    workoutAssignments: []
                )
            }
        }

        // For custom programs, we don't pre-fill anything - let user start fresh
        // The calling view should handle navigation to the appropriate step
    }
}

// MARK: - Preview

#if DEBUG
struct QuickBuildOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            QuickBuildOptionsView(viewModel: TherapistProgramBuilderViewModel())
                .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
