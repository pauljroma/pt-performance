//
//  RTSPhaseProgressView.swift
//  PTPerformance
//
//  Visual timeline showing phase progression for Return-to-Sport protocols
//  Displays phases as nodes with traffic light colors and connection lines
//

import SwiftUI

// MARK: - RTS Phase Progress View

/// Visual timeline showing phase progression
struct RTSPhaseProgressView: View {
    let phases: [RTSPhase]
    let currentPhaseId: UUID?
    var onPhaseSelect: ((RTSPhase) -> Void)?

    @State private var selectedPhaseId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Phase Progress")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if phases.isEmpty {
                emptyState
            } else {
                timelineContent
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        VStack(spacing: 0) {
            ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                RTSPhaseNode(
                    phase: phase,
                    isFirst: index == 0,
                    isLast: index == phases.count - 1,
                    isCurrent: phase.id == currentPhaseId,
                    isSelected: phase.id == selectedPhaseId,
                    showConnector: index < phases.count - 1,
                    nextPhaseStatus: index < phases.count - 1 ? phases[index + 1].phaseStatus : nil
                )
                .onTapGesture {
                    HapticFeedback.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPhaseId = phase.id
                    }
                    onPhaseSelect?(phase)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(phaseAccessibilityLabel(for: phase, at: index))
                .accessibilityHint("Double tap to view phase details")
                .accessibilityAddTraits(phase.id == currentPhaseId ? .isSelected : [])
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: Spacing.sm) {
                Image(systemName: "timeline.selection")
                    .font(.title2)
                    .foregroundColor(.secondary)

                Text("No phases defined")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.lg)
            Spacer()
        }
    }

    // MARK: - Accessibility

    private func phaseAccessibilityLabel(for phase: RTSPhase, at index: Int) -> String {
        var label = "Phase \(index + 1) of \(phases.count): \(phase.phaseName)"
        label += ", \(phase.activityLevel.displayName)"

        if phase.isCompleted {
            label += ", completed"
        } else if phase.isActive {
            label += ", current phase"
            if let days = phase.daysInPhase {
                label += ", day \(days + 1)"
            }
        } else {
            label += ", pending"
        }

        return label
    }
}

// MARK: - RTS Phase Node

/// Single phase node in the timeline
struct RTSPhaseNode: View {
    let phase: RTSPhase
    let isFirst: Bool
    let isLast: Bool
    let isCurrent: Bool
    let isSelected: Bool
    let showConnector: Bool
    let nextPhaseStatus: PhaseStatus?

    enum PhaseStatus {
        case completed, active, pending
    }

    private var phaseStatus: PhaseStatus {
        phase.phaseStatus
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Timeline indicator
            VStack(spacing: 0) {
                // Top connector line
                if !isFirst {
                    Rectangle()
                        .fill(connectorColor(for: phaseStatus))
                        .frame(width: 3, height: 12)
                }

                // Node circle
                nodeCircle

                // Bottom connector line
                if showConnector {
                    Rectangle()
                        .fill(connectorColor(for: nextPhaseStatus ?? .pending))
                        .frame(width: 3)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 32)

            // Phase content
            phaseContent
                .padding(.bottom, showConnector ? Spacing.md : 0)
        }
    }

    // MARK: - Node Circle

    private var nodeCircle: some View {
        ZStack {
            // Outer glow for current phase
            if isCurrent {
                Circle()
                    .fill(phase.activityLevel.color.opacity(0.3))
                    .frame(width: 32, height: 32)
            }

            // Main circle
            Circle()
                .fill(circleBackgroundColor)
                .frame(width: 24, height: 24)

            // Icon or number
            if phase.isCompleted {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            } else {
                Text("\(phase.phaseNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(circleTextColor)
            }
        }
    }

    private var circleBackgroundColor: Color {
        if phase.isCompleted {
            return phase.activityLevel.color
        } else if phase.isActive {
            return phase.activityLevel.color
        } else {
            return Color(.systemGray5)
        }
    }

    private var circleTextColor: Color {
        if phase.isCompleted || phase.isActive {
            return .white
        } else {
            return .secondary
        }
    }

    private func connectorColor(for status: PhaseStatus) -> Color {
        switch status {
        case .completed:
            return .green
        case .active:
            return Color(.systemGray4)
        case .pending:
            return Color(.systemGray5)
        }
    }

    // MARK: - Phase Content

    private var phaseContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            // Phase name with status badge
            HStack(spacing: Spacing.xs) {
                Text(phase.phaseName)
                    .font(.subheadline)
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .foregroundColor(phase.isPending ? .secondary : .primary)

                Spacer()

                // Traffic light badge
                RTSTrafficLightBadge(
                    level: phase.activityLevel,
                    size: .small
                )
                .opacity(phase.isPending ? 0.5 : 1.0)
            }

            // Status and dates
            HStack(spacing: Spacing.sm) {
                Text(phase.statusText)
                    .font(.caption)
                    .foregroundColor(statusColor)

                if let startDate = phase.formattedStartDate {
                    Text("Started \(startDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let completedDate = phase.formattedCompletionDate {
                    Text("Completed \(completedDate)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            // Progress indicator for active phase
            if phase.isActive, let progress = phase.progressPercentage, let target = phase.targetDurationDays {
                VStack(alignment: .leading, spacing: 2) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(.systemGray5))

                            RoundedRectangle(cornerRadius: 2)
                                .fill(phase.activityLevel.color)
                                .frame(width: geometry.size.width * progress)
                        }
                    }
                    .frame(height: 4)

                    Text("Target: \(target) days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(isSelected ? Color(.systemGray6) : Color.clear)
        )
    }

    private var statusColor: Color {
        if phase.isCompleted {
            return .green
        } else if phase.isActive {
            return .blue
        } else {
            return .secondary
        }
    }
}

// MARK: - Phase Status Extension

extension RTSPhase {
    var phaseStatus: RTSPhaseNode.PhaseStatus {
        if isCompleted {
            return .completed
        } else if isActive {
            return .active
        } else {
            return .pending
        }
    }
}

// MARK: - Horizontal Timeline View (Alternative)

/// Horizontal timeline variant for compact displays
struct RTSPhaseProgressHorizontalView: View {
    let phases: [RTSPhase]
    let currentPhaseId: UUID?
    var onPhaseSelect: ((RTSPhase) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                    HStack(spacing: 0) {
                        // Phase node
                        VStack(spacing: Spacing.xs) {
                            // Traffic light node
                            ZStack {
                                if phase.id == currentPhaseId {
                                    Circle()
                                        .fill(phase.activityLevel.color.opacity(0.3))
                                        .frame(width: 44, height: 44)
                                }

                                Circle()
                                    .fill(nodeColor(for: phase))
                                    .frame(width: 32, height: 32)

                                if phase.isCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                } else {
                                    Text("\(phase.phaseNumber)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(phase.isPending ? .secondary : .white)
                                }
                            }

                            // Phase name
                            Text(phase.phaseName)
                                .font(.caption2)
                                .foregroundColor(phase.isPending ? .secondary : .primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                        }
                        .onTapGesture {
                            HapticFeedback.light()
                            onPhaseSelect?(phase)
                        }

                        // Connector line
                        if index < phases.count - 1 {
                            Rectangle()
                                .fill(connectorColor(currentIndex: index))
                                .frame(width: 24, height: 3)
                                .padding(.bottom, 20)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }

    private func nodeColor(for phase: RTSPhase) -> Color {
        if phase.isCompleted || phase.isActive {
            return phase.activityLevel.color
        }
        return Color(.systemGray5)
    }

    private func connectorColor(currentIndex: Int) -> Color {
        let phase = phases[currentIndex]
        if phase.isCompleted {
            return .green
        }
        return Color(.systemGray4)
    }
}

// MARK: - Preview

#if DEBUG
struct RTSPhaseProgressView_Previews: PreviewProvider {
    static var samplePhases: [RTSPhase] {
        let protocolId = UUID()
        return [
            RTSPhase(
                protocolId: protocolId,
                phaseNumber: 1,
                phaseName: "Protected Motion",
                activityLevel: .red,
                description: "Focus on healing and pain-free ROM",
                startedAt: Calendar.current.date(byAdding: .day, value: -21, to: Date()),
                completedAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
                targetDurationDays: 14
            ),
            RTSPhase(
                protocolId: protocolId,
                phaseNumber: 2,
                phaseName: "Light Activity",
                activityLevel: .yellow,
                description: "Begin light sport-specific movements",
                startedAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
                targetDurationDays: 21
            ),
            RTSPhase(
                protocolId: protocolId,
                phaseNumber: 3,
                phaseName: "Progressive Return",
                activityLevel: .yellow,
                description: "Increase intensity gradually",
                targetDurationDays: 28
            ),
            RTSPhase(
                protocolId: protocolId,
                phaseNumber: 4,
                phaseName: "Full Clearance",
                activityLevel: .green,
                description: "Return to unrestricted activity",
                targetDurationDays: 14
            )
        ]
    }

    static var previews: some View {
        Group {
            // Vertical timeline
            ScrollView {
                RTSPhaseProgressView(
                    phases: samplePhases,
                    currentPhaseId: samplePhases[1].id,
                    onPhaseSelect: { phase in
                        print("Selected: \(phase.phaseName)")
                    }
                )
                .padding()
            }
            .previewDisplayName("Vertical Timeline")

            // Horizontal timeline
            RTSPhaseProgressHorizontalView(
                phases: samplePhases,
                currentPhaseId: samplePhases[1].id,
                onPhaseSelect: { phase in
                    print("Selected: \(phase.phaseName)")
                }
            )
            .previewDisplayName("Horizontal Timeline")

            // Empty state
            RTSPhaseProgressView(
                phases: [],
                currentPhaseId: nil
            )
            .padding()
            .previewDisplayName("Empty State")
        }
    }
}
#endif
