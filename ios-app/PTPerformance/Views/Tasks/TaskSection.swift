//
//  TaskSection.swift
//  PTPerformance
//
//  Reusable section component for displaying groups of tasks
//  with a header showing title and task count.
//

import SwiftUI

struct TaskSection: View {
    let title: String
    let tasks: [AssignedTask]
    var isOverdue: Bool = false
    let onTaskTap: (AssignedTask) -> Void
    let onComplete: ((AssignedTask) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isOverdue ? .red : .primary)

                if isOverdue {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }

                Spacer()

                Text("\(tasks.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ForEach(tasks) { task in
                TaskRow(
                    task: task,
                    isOverdue: isOverdue,
                    onTap: { onTaskTap(task) },
                    onComplete: onComplete != nil ? { onComplete?(task) } : nil
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.lg) {
        TaskSection(
            title: "Today",
            tasks: [
                AssignedTask(
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
                AssignedTask(
                    id: UUID(),
                    planId: UUID(),
                    title: "Ice Application",
                    taskType: .ice,
                    dueDate: Date(),
                    dueTime: "12:00",
                    status: .pending,
                    completedAt: nil,
                    notes: nil
                )
            ],
            onTaskTap: { _ in },
            onComplete: { _ in }
        )

        TaskSection(
            title: "Overdue",
            tasks: [
                AssignedTask(
                    id: UUID(),
                    planId: UUID(),
                    title: "PT Check-In",
                    taskType: .checkIn,
                    dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                    dueTime: "09:00",
                    status: .pending,
                    completedAt: nil,
                    notes: nil
                )
            ],
            isOverdue: true,
            onTaskTap: { _ in },
            onComplete: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
