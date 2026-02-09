//
//  VisualWorkoutGrid.swift
//  PTPerformance
//
//  A simple calendar-style grid for viewing workout assignments.
//  Horizontal scroll with weeks as columns.
//  Shows workout count per week in a compact, read-only format.
//

import SwiftUI

// MARK: - Visual Workout Grid View

/// A simple calendar-style grid for viewing workout assignments.
/// Displays weeks as columns with workout counts per week.
struct VisualWorkoutGrid: View {
    let phases: [TherapistPhaseData]

    private let phaseColors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Workout Schedule")
                .font(.headline)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)

            if phases.isEmpty {
                emptyState
            } else {
                // Grid content
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Week headers
                        weekHeadersRow

                        // Phase rows
                        ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                            phaseRow(phase: phase, phaseNumber: index + 1)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No workout schedule")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Add phases and workouts to see the schedule")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Week Headers Row

    private var weekHeadersRow: some View {
        HStack(spacing: 0) {
            // Phase label column
            Text("Phase")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            // Week columns
            ForEach(1...totalWeeks, id: \.self) { week in
                Text("W\(week)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(width: 44)
            }
        }
    }

    // MARK: - Phase Row

    private func phaseRow(phase: TherapistPhaseData, phaseNumber: Int) -> some View {
        let color = phaseColors[(phaseNumber - 1) % phaseColors.count]
        let startWeek = calculateStartWeek(for: phaseNumber - 1)

        return HStack(spacing: 0) {
            // Phase name
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text(phase.name.isEmpty ? "Phase \(phaseNumber)" : phase.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .frame(width: 80, alignment: .leading)

            // Week cells
            ForEach(1...totalWeeks, id: \.self) { week in
                weekCell(
                    phase: phase,
                    week: week,
                    phaseStartWeek: startWeek,
                    phaseDuration: phase.durationWeeks,
                    color: color
                )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(phase.name.isEmpty ? "Phase \(phaseNumber)" : phase.name), \(phase.durationWeeks) weeks, \(phase.workoutAssignments.count) workouts")
    }

    // MARK: - Week Cell

    private func weekCell(
        phase: TherapistPhaseData,
        week: Int,
        phaseStartWeek: Int,
        phaseDuration: Int,
        color: Color
    ) -> some View {
        let phaseEndWeek = phaseStartWeek + phaseDuration - 1
        let isInPhase = week >= phaseStartWeek && week <= phaseEndWeek
        let phaseWeek = week - phaseStartWeek + 1
        let workoutCount = isInPhase ? countWorkouts(in: phase, forWeek: phaseWeek) : 0

        return ZStack {
            if isInPhase {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color.opacity(0.3), lineWidth: 0.5)
                    )

                if workoutCount > 0 {
                    Text("\(workoutCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                } else {
                    Text("-")
                        .font(.caption2)
                        .foregroundColor(color.opacity(0.5))
                }
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray6))
            }
        }
        .frame(width: 40, height: 32)
        .padding(.horizontal, 2)
    }

    // MARK: - Helper Methods

    private var totalWeeks: Int {
        max(1, phases.reduce(0) { $0 + $1.durationWeeks })
    }

    private func calculateStartWeek(for phaseIndex: Int) -> Int {
        var startWeek = 1
        for i in 0..<phaseIndex {
            startWeek += phases[i].durationWeeks
        }
        return startWeek
    }

    private func countWorkouts(in phase: TherapistPhaseData, forWeek week: Int) -> Int {
        phase.workoutAssignments.filter { $0.weekNumber == week }.count
    }
}

// MARK: - Compact Workout Grid

/// A more compact version of the workout grid showing just summary stats
struct CompactWorkoutGrid: View {
    let phases: [TherapistPhaseData]

    private let phaseColors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                compactPhaseRow(phase: phase, phaseNumber: index + 1)
            }
        }
    }

    private func compactPhaseRow(phase: TherapistPhaseData, phaseNumber: Int) -> some View {
        let color = phaseColors[(phaseNumber - 1) % phaseColors.count]
        let workoutsPerWeek = phase.durationWeeks > 0
            ? Double(phase.workoutAssignments.count) / Double(phase.durationWeeks)
            : 0

        return HStack(spacing: 12) {
            // Phase indicator
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            // Phase name
            Text(phase.name.isEmpty ? "Phase \(phaseNumber)" : phase.name)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            // Stats
            HStack(spacing: 16) {
                // Duration
                Label("\(phase.durationWeeks)w", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Total workouts
                Label("\(phase.workoutAssignments.count)", systemImage: "dumbbell.fill")
                    .font(.caption)
                    .foregroundColor(color)

                // Avg per week
                Text(String(format: "%.1f/wk", workoutsPerWeek))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(phase.name.isEmpty ? "Phase \(phaseNumber)" : phase.name), \(phase.durationWeeks) weeks, \(phase.workoutAssignments.count) workouts, \(String(format: "%.1f", workoutsPerWeek)) per week average")
    }
}

// MARK: - Week Summary Grid

/// A grid showing workout distribution across weeks
struct WeekSummaryGrid: View {
    let phases: [TherapistPhaseData]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Distribution")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            // Calculate total weeks
            let totalWeeks = max(1, phases.reduce(0) { $0 + $1.durationWeeks })

            LazyVGrid(columns: gridColumns(for: totalWeeks), spacing: 8) {
                ForEach(1...totalWeeks, id: \.self) { week in
                    weekSummaryCell(week: week)
                }
            }
        }
    }

    private func gridColumns(for weeks: Int) -> [GridItem] {
        let columnCount = min(7, weeks)
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount)
    }

    private func weekSummaryCell(week: Int) -> some View {
        let count = workoutCount(forWeek: week)
        let intensity = min(1.0, Double(count) / 5.0) // Normalize to 0-1 for color intensity

        return VStack(spacing: 4) {
            Text("W\(week)")
                .font(.caption2)
                .foregroundColor(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue.opacity(0.1 + intensity * 0.4))

                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(count > 0 ? .blue : .secondary)
            }
            .frame(height: 32)
        }
        .accessibilityLabel("Week \(week), \(count) workouts")
    }

    private func workoutCount(forWeek absoluteWeek: Int) -> Int {
        var currentWeek = 1

        for phase in phases {
            let phaseEndWeek = currentWeek + phase.durationWeeks - 1

            if absoluteWeek >= currentWeek && absoluteWeek <= phaseEndWeek {
                let phaseWeek = absoluteWeek - currentWeek + 1
                return phase.workoutAssignments.filter { $0.weekNumber == phaseWeek }.count
            }

            currentWeek = phaseEndWeek + 1
        }

        return 0
    }
}

// MARK: - Preview

#if DEBUG
struct VisualWorkoutGrid_Previews: PreviewProvider {
    static var samplePhases: [TherapistPhaseData] {
        [
            TherapistPhaseData(
                id: UUID(),
                name: "Foundation",
                sequence: 1,
                durationWeeks: 4,
                goals: "Build baseline strength",
                workoutAssignments: [
                    TherapistWorkoutAssignment(
                        id: UUID(),
                        templateId: UUID(),
                        templateName: "Lower Body A",
                        weekNumber: 1,
                        dayOfWeek: 1
                    ),
                    TherapistWorkoutAssignment(
                        id: UUID(),
                        templateId: UUID(),
                        templateName: "Upper Body A",
                        weekNumber: 1,
                        dayOfWeek: 3
                    ),
                    TherapistWorkoutAssignment(
                        id: UUID(),
                        templateId: UUID(),
                        templateName: "Full Body",
                        weekNumber: 1,
                        dayOfWeek: 5
                    ),
                    TherapistWorkoutAssignment(
                        id: UUID(),
                        templateId: UUID(),
                        templateName: "Lower Body B",
                        weekNumber: 2,
                        dayOfWeek: 1
                    ),
                    TherapistWorkoutAssignment(
                        id: UUID(),
                        templateId: UUID(),
                        templateName: "Upper Body B",
                        weekNumber: 2,
                        dayOfWeek: 3
                    )
                ]
            ),
            TherapistPhaseData(
                id: UUID(),
                name: "Strength",
                sequence: 2,
                durationWeeks: 3,
                goals: "Increase max strength",
                workoutAssignments: [
                    TherapistWorkoutAssignment(
                        id: UUID(),
                        templateId: UUID(),
                        templateName: "Heavy Legs",
                        weekNumber: 1,
                        dayOfWeek: 1
                    ),
                    TherapistWorkoutAssignment(
                        id: UUID(),
                        templateId: UUID(),
                        templateName: "Heavy Push",
                        weekNumber: 1,
                        dayOfWeek: 3
                    )
                ]
            ),
            TherapistPhaseData(
                id: UUID(),
                name: "Power",
                sequence: 3,
                durationWeeks: 2,
                goals: "Develop explosiveness",
                workoutAssignments: []
            )
        ]
    }

    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                VisualWorkoutGrid(phases: samplePhases)

                CompactWorkoutGrid(phases: samplePhases)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)

                WeekSummaryGrid(phases: samplePhases)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
