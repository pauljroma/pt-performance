//
//  ProgramPreviewView.swift
//  PTPerformance
//
//  Preview of a program before publishing.
//  Shows program summary, timeline, phase cards, and publish action.
//

import SwiftUI

// MARK: - Program Preview View

struct ProgramPreviewView: View {
    @ObservedObject var viewModel: TherapistProgramBuilderViewModel
    @Binding var isPresented: Bool

    @State private var showPublishConfirmation = false
    @State private var isPublishing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection

                    // Timeline Section
                    timelineSection

                    // Phase Cards Section
                    phaseCardsSection

                    // Summary Stats Section
                    summaryStatsSection

                    // Publish Button
                    publishButton
                        .padding(.top, 8)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Program Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") {
                        isPresented = false
                    }
                }
            }
            .alert("Publish Program?", isPresented: $showPublishConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Publish") {
                    Task {
                        await publishProgram()
                    }
                }
            } message: {
                Text("This will make '\(viewModel.programName)' available in the program library for patients to browse and enroll.")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Program name
            Text(viewModel.programName.isEmpty ? "Untitled Program" : viewModel.programName)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Type badge and duration
            HStack(spacing: 12) {
                // Category badge
                categoryBadge

                // Duration pill
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(viewModel.totalPhaseDuration) weeks")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(8)

                // Difficulty badge
                difficultyBadge
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var categoryBadge: some View {
        let category = ProgramCategory(rawValue: viewModel.category) ?? .strength
        return HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption)
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(category.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(category.color.opacity(0.15))
        .cornerRadius(8)
    }

    private var difficultyBadge: some View {
        let difficulty = DifficultyLevel(rawValue: viewModel.difficultyLevel) ?? .intermediate
        return Text(difficulty.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(difficulty.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(difficulty.color.opacity(0.15))
            .cornerRadius(8)
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Program Timeline")
                .font(.headline)
                .fontWeight(.semibold)

            // Horizontal timeline
            if !viewModel.phases.isEmpty {
                ProgramTimelineView(phases: viewModel.phases)
            } else {
                Text("No phases defined")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Phase Cards Section

    private var phaseCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Phases (\(viewModel.phases.count))")
                .font(.headline)
                .fontWeight(.semibold)

            if viewModel.phases.isEmpty {
                emptyPhasesCard
            } else {
                ForEach(Array(viewModel.phases.enumerated()), id: \.element.id) { index, phase in
                    PhasePreviewCard(phase: phase, phaseNumber: index + 1)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var emptyPhasesCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No phases added yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Go back to add phases before publishing")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Summary Stats Section

    private var summaryStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                SummaryStatCard(
                    title: "Total Weeks",
                    value: "\(viewModel.totalPhaseDuration)",
                    icon: "calendar",
                    color: .blue
                )

                SummaryStatCard(
                    title: "Phases",
                    value: "\(viewModel.phases.count)",
                    icon: "chart.bar.fill",
                    color: .purple
                )

                SummaryStatCard(
                    title: "Workouts",
                    value: "\(totalWorkouts)",
                    icon: "dumbbell.fill",
                    color: .green
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var totalWorkouts: Int {
        viewModel.phases.reduce(0) { $0 + $1.workoutAssignments.count }
    }

    // MARK: - Publish Button

    private var publishButton: some View {
        Button {
            showPublishConfirmation = true
        } label: {
            HStack(spacing: 8) {
                if isPublishing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.up.doc.fill")
                }
                Text(isPublishing ? "Publishing..." : "Publish to Library")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canPublish ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canPublish || isPublishing)
        .accessibilityLabel(canPublish ? "Publish program to library" : "Cannot publish - program is incomplete")
        .accessibilityHint(canPublish ? "Double tap to publish this program" : "Add phases with workouts to enable publishing")
    }

    private var canPublish: Bool {
        viewModel.isReadyToPublish
    }

    // MARK: - Actions

    private func publishProgram() async {
        isPublishing = true

        do {
            try await viewModel.publishToLibrary()
            isPresented = false
        } catch {
            // Error is handled in viewModel
        }

        isPublishing = false
    }
}

// MARK: - Program Timeline View

private struct ProgramTimelineView: View {
    let phases: [TherapistPhaseData]

    private let phaseColors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                    TimelinePhaseSegment(
                        phase: phase,
                        phaseNumber: index + 1,
                        color: phaseColors[index % phaseColors.count],
                        isLast: index == phases.count - 1,
                        totalWeeks: totalDuration
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var totalDuration: Int {
        phases.reduce(0) { $0 + $1.durationWeeks }
    }
}

private struct TimelinePhaseSegment: View {
    let phase: TherapistPhaseData
    let phaseNumber: Int
    let color: Color
    let isLast: Bool
    let totalWeeks: Int

    private var widthRatio: CGFloat {
        guard totalWeeks > 0 else { return 1.0 }
        return CGFloat(phase.durationWeeks) / CGFloat(totalWeeks)
    }

    var body: some View {
        VStack(spacing: 4) {
            // Phase bar
            HStack(spacing: 0) {
                Rectangle()
                    .fill(color)
                    .frame(width: max(60, 200 * widthRatio), height: 24)
                    .cornerRadius(isLast ? 4 : 0, corners: isLast ? [.topRight, .bottomRight] : [])
                    .cornerRadius(phaseNumber == 1 ? 4 : 0, corners: phaseNumber == 1 ? [.topLeft, .bottomLeft] : [])
                    .overlay(
                        Text("\(phase.durationWeeks)w")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }

            // Phase name
            Text(phase.name.isEmpty ? "Phase \(phaseNumber)" : phase.name)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: max(60, 200 * widthRatio))
        }
    }
}

// MARK: - Phase Preview Card

private struct PhasePreviewCard: View {
    let phase: TherapistPhaseData
    let phaseNumber: Int

    private let phaseColors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal]

    private var phaseColor: Color {
        phaseColors[(phaseNumber - 1) % phaseColors.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                // Phase number badge
                Text("\(phaseNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(phaseColor))

                // Phase name
                Text(phase.name.isEmpty ? "Phase \(phaseNumber)" : phase.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                // Duration
                Text("\(phase.durationWeeks) weeks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(6)
            }

            // Goals (if any)
            if !phase.goals.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "target")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(phase.goals)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            // Workout count
            HStack(spacing: 4) {
                Image(systemName: "dumbbell.fill")
                    .font(.caption)
                    .foregroundColor(phaseColor)

                Text("\(phase.workoutAssignments.count) workouts assigned")
                    .font(.caption)
                    .foregroundColor(phase.workoutAssignments.isEmpty ? .orange : .secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Summary Stat Card

private struct SummaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#if DEBUG
struct ProgramPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TherapistProgramBuilderViewModel()
        viewModel.programName = "12-Week Strength Foundation"
        viewModel.category = "strength"
        viewModel.difficultyLevel = "intermediate"
        viewModel.phases = [
            TherapistPhaseData(
                name: "Adaptation",
                sequence: 1,
                durationWeeks: 3,
                goals: "Movement proficiency, work capacity, tissue preparation",
                workoutAssignments: [
                    TherapistWorkoutAssignment(
                        templateId: UUID(),
                        templateName: "Lower Body A",
                        weekNumber: 1,
                        dayOfWeek: 1
                    ),
                    TherapistWorkoutAssignment(
                        templateId: UUID(),
                        templateName: "Upper Body A",
                        weekNumber: 1,
                        dayOfWeek: 3
                    )
                ]
            ),
            TherapistPhaseData(
                name: "Hypertrophy",
                sequence: 2,
                durationWeeks: 3,
                goals: "Muscle growth, increased volume, progressive overload",
                workoutAssignments: []
            ),
            TherapistPhaseData(
                name: "Strength",
                sequence: 3,
                durationWeeks: 3,
                goals: "Maximal strength development, neural adaptations",
                workoutAssignments: []
            ),
            TherapistPhaseData(
                name: "Power",
                sequence: 4,
                durationWeeks: 3,
                goals: "Rate of force development, explosive training",
                workoutAssignments: []
            )
        ]

        return ProgramPreviewView(viewModel: viewModel, isPresented: .constant(true))
    }
}
#endif
