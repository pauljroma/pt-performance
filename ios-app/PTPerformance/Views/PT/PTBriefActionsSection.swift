//
//  PTBriefActionsSection.swift
//  PTPerformance
//
//  PT Brief Actions Section - AI-suggested next actions based on readiness
//  Part of the 60-Second Athlete Brief workflow
//
//  Features:
//  - AI-suggested next actions based on readiness data
//  - Each action has rationale with evidence
//  - Quick approve/reject buttons
//  - Link to full protocol builder
//  - Priority indicators (suggested/recommended/urgent)
//

import SwiftUI

struct PTBriefActionsSection: View {
    let actions: [PTBriefAction]
    let isLoading: Bool
    let onApprove: (PTBriefAction) -> Void
    let onReject: (PTBriefAction) -> Void
    let onViewProtocol: (PTBriefAction) -> Void
    let onOpenProtocolBuilder: () -> Void

    private var pendingActions: [PTBriefAction] {
        actions.filter { $0.status == .pending }
    }

    private var processedActions: [PTBriefAction] {
        actions.filter { $0.status != .pending }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section Header
            sectionHeader

            if isLoading {
                loadingState
            } else if actions.isEmpty {
                noActionsState
            } else {
                actionsContent
            }
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(.modusCyan)
                .accessibilityHidden(true)

            Text("Suggested Actions")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            if !pendingActions.isEmpty {
                Text("(\(pendingActions.count) pending)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                HapticFeedback.light()
                onOpenProtocolBuilder()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)

                    Text("Customize")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.modusCyan)
            }
            .accessibilityLabel("Customize plan")
            .accessibilityHint("Opens the protocol builder")
        }
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Actions Content

    private var actionsContent: some View {
        VStack(spacing: Spacing.sm) {
            // Pending actions
            ForEach(pendingActions.sorted(by: { $0.priority > $1.priority })) { action in
                ActionCard(
                    action: action,
                    onApprove: { onApprove(action) },
                    onReject: { onReject(action) },
                    onViewProtocol: { onViewProtocol(action) }
                )
            }

            // Processed actions (collapsed)
            if !processedActions.isEmpty {
                processedActionsSection
            }
        }
    }

    // MARK: - Processed Actions Section

    @State private var showProcessed = false

    private var processedActionsSection: some View {
        VStack(spacing: Spacing.xs) {
            Button(action: {
                withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                    showProcessed.toggle()
                }
            }) {
                HStack {
                    Text("\(processedActions.count) processed")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Image(systemName: showProcessed ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, Spacing.xs)
            }

            if showProcessed {
                ForEach(processedActions) { action in
                    ProcessedActionRow(action: action)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: Spacing.md) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 14)
                            .frame(maxWidth: 150)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 10)
                            .frame(maxWidth: 200)
                    }

                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)
            }
        }
        .pulse()
    }

    // MARK: - No Actions State

    private var noActionsState: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.modusCyan.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(.modusCyan)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("No Actions Suggested")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Current plan appears optimal based on readiness")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No actions suggested. Current plan appears optimal based on readiness.")
    }
}

// MARK: - Action Card

private struct ActionCard: View {
    let action: PTBriefAction
    let onApprove: () -> Void
    let onReject: () -> Void
    let onViewProtocol: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header row
            HStack(spacing: Spacing.sm) {
                priorityBadge

                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(action.priority.displayName)
                        .font(.caption2)
                        .foregroundColor(action.priority.color)
                }

                Spacer()

                citationBadge

                expandButton
            }

            // Expanded content
            if isExpanded {
                expandedContent
            }

            // Action buttons
            actionButtons
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(action.priority == .urgent ? action.priority.color.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Priority Badge

    private var priorityBadge: some View {
        ZStack {
            Circle()
                .fill(action.priority.color.opacity(0.15))
                .frame(width: 32, height: 32)

            Image(systemName: priorityIcon)
                .font(.caption)
                .foregroundColor(action.priority.color)
        }
        .accessibilityHidden(true)
    }

    private var priorityIcon: String {
        switch action.priority {
        case .urgent: return "bolt.fill"
        case .recommended: return "hand.thumbsup.fill"
        case .suggested: return "lightbulb.fill"
        }
    }

    // MARK: - Citation Badge

    private var citationBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "doc.text")
                .font(.system(size: 8))

            Text("\(action.citationCount)")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.modusCyan)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.modusCyan.opacity(0.1))
        .cornerRadius(CornerRadius.xs)
    }

    // MARK: - Expand Button

    private var expandButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                isExpanded.toggle()
            }
        }) {
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
        }
        .accessibilityLabel(isExpanded ? "Collapse details" : "Expand details")
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Rationale
            VStack(alignment: .leading, spacing: 4) {
                Text("Rationale")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Text(action.rationale)
                    .font(.caption)
                    .foregroundColor(.primary)
            }

            // Evidence summary
            VStack(alignment: .leading, spacing: 4) {
                Text("Evidence")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Text(action.evidenceSummary)
                    .font(.caption)
                    .foregroundColor(.primary)
            }

            // Protocol link if available
            if action.protocolId != nil {
                Button(action: {
                    HapticFeedback.light()
                    onViewProtocol()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle")
                            .font(.caption)

                        Text("View Protocol Details")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.modusCyan)
                }
            }
        }
        .padding(.top, Spacing.xs)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: Spacing.sm) {
            // Reject button
            Button(action: {
                HapticFeedback.light()
                onReject()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.caption)

                    Text("Skip")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(CornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Skip this action")

            // Approve button
            Button(action: {
                HapticFeedback.success()
                onApprove()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.caption)

                    Text("Approve")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(action.priority.color)
                .cornerRadius(CornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Approve this action")
        }
    }
}

// MARK: - Processed Action Row

private struct ProcessedActionRow: View {
    let action: PTBriefAction

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: action.status == .approved ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(action.status == .approved ? .green : .secondary)
                .accessibilityHidden(true)

            Text(action.title)
                .font(.caption)
                .foregroundColor(.secondary)
                .strikethrough(action.status == .rejected)

            Spacer()

            Text(action.status == .approved ? "Approved" : "Skipped")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Preview

#if DEBUG
struct PTBriefActionsSection_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // With actions
            ScrollView {
                PTBriefActionsSection(
                    actions: [
                        PTBriefAction(
                            id: UUID(),
                            title: "Continue Current Program",
                            rationale: "Readiness score is within target range. Current progression is appropriate for this phase of recovery.",
                            evidenceSummary: "Based on HRV trend (+15%), sleep quality (75%), and subjective readiness (7/10)",
                            citationCount: 4,
                            protocolId: nil,
                            priority: .recommended,
                            status: .pending
                        ),
                        PTBriefAction(
                            id: UUID(),
                            title: "Add Recovery Session",
                            rationale: "Sleep quality decline suggests additional recovery modalities may benefit performance.",
                            evidenceSummary: "Sleep score dropped 12% vs 7-day average",
                            citationCount: 2,
                            protocolId: UUID(),
                            priority: .suggested,
                            status: .pending
                        ),
                        PTBriefAction(
                            id: UUID(),
                            title: "Reduce Volume 10%",
                            rationale: "Already approved adjustment",
                            evidenceSummary: "ACWR trending high",
                            citationCount: 3,
                            protocolId: nil,
                            priority: .recommended,
                            status: .approved
                        )
                    ],
                    isLoading: false,
                    onApprove: { _ in },
                    onReject: { _ in },
                    onViewProtocol: { _ in },
                    onOpenProtocolBuilder: {}
                )
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .previewDisplayName("With Actions")

            // Urgent action
            ScrollView {
                PTBriefActionsSection(
                    actions: [
                        PTBriefAction(
                            id: UUID(),
                            title: "Reduce Throwing Volume",
                            rationale: "Workload ratio exceeds safe threshold. Immediate volume reduction recommended.",
                            evidenceSummary: "ACWR at 1.52, threshold is 1.3",
                            citationCount: 5,
                            protocolId: UUID(),
                            priority: .urgent,
                            status: .pending
                        )
                    ],
                    isLoading: false,
                    onApprove: { _ in },
                    onReject: { _ in },
                    onViewProtocol: { _ in },
                    onOpenProtocolBuilder: {}
                )
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .previewDisplayName("Urgent Action")

            // Loading
            ScrollView {
                PTBriefActionsSection(
                    actions: [],
                    isLoading: true,
                    onApprove: { _ in },
                    onReject: { _ in },
                    onViewProtocol: { _ in },
                    onOpenProtocolBuilder: {}
                )
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .previewDisplayName("Loading")

            // No actions
            ScrollView {
                PTBriefActionsSection(
                    actions: [],
                    isLoading: false,
                    onApprove: { _ in },
                    onReject: { _ in },
                    onViewProtocol: { _ in },
                    onOpenProtocolBuilder: {}
                )
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .previewDisplayName("No Actions")

            // Dark mode
            ScrollView {
                PTBriefActionsSection(
                    actions: [
                        PTBriefAction(
                            id: UUID(),
                            title: "Maintain Current Plan",
                            rationale: "All metrics stable",
                            evidenceSummary: "HRV, sleep, readiness all within range",
                            citationCount: 3,
                            protocolId: nil,
                            priority: .recommended,
                            status: .pending
                        )
                    ],
                    isLoading: false,
                    onApprove: { _ in },
                    onReject: { _ in },
                    onViewProtocol: { _ in },
                    onOpenProtocolBuilder: {}
                )
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
#endif
