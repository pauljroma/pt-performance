//
//  TaskRow.swift
//  PTPerformance
//
//  Individual task row with task type icon, title, time,
//  and completion button for quick task completion.
//

import SwiftUI

struct TaskRow: View {
    let task: AssignedTask
    var isOverdue: Bool = false
    let onTap: () -> Void
    let onComplete: (() -> Void)?

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Task type icon
                Image(systemName: task.taskType.icon)
                    .font(.title3)
                    .foregroundColor(task.taskType.swiftUIColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    if let time = task.formattedDueTime {
                        Text(time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Complete button
                if let onComplete = onComplete {
                    Button(action: {
                        HapticFeedback.medium()
                        onComplete()
                    }) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(.modusTealAccent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Mark as complete")
                    .accessibilityHint("Double tap to mark this task as completed")
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(isOverdue ? Color.red.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.sm) {
        TaskRow(
            task: AssignedTask(
                id: UUID(),
                planId: UUID(),
                title: "Morning Stretches",
                taskType: .stretch,
                dueDate: Date(),
                dueTime: "08:00",
                status: .pending,
                completedAt: nil,
                notes: nil
            ),
            onTap: {},
            onComplete: {}
        )

        TaskRow(
            task: AssignedTask(
                id: UUID(),
                planId: UUID(),
                title: "Ice Therapy",
                taskType: .ice,
                dueDate: Date(),
                dueTime: "12:00",
                status: .pending,
                completedAt: nil,
                notes: nil
            ),
            isOverdue: true,
            onTap: {},
            onComplete: {}
        )

        TaskRow(
            task: AssignedTask(
                id: UUID(),
                planId: UUID(),
                title: "Upcoming Exercise",
                taskType: .exercise,
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                dueTime: "10:00",
                status: .pending,
                completedAt: nil,
                notes: nil
            ),
            onTap: {},
            onComplete: nil
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
