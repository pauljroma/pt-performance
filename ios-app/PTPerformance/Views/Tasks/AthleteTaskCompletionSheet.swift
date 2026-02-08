//
//  AthleteTaskCompletionSheet.swift
//  PTPerformance
//
//  Sheet for completing a task with optional notes.
//  Athletes can mark tasks complete or skip them.
//

import SwiftUI

struct AthleteTaskCompletionSheet: View {
    let task: AssignedTask
    let onComplete: (String?) -> Void
    let onSkip: () -> Void

    @State private var notes: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                // Task info
                VStack(spacing: Spacing.sm) {
                    Image(systemName: task.taskType.icon)
                        .font(.system(size: 48))
                        .foregroundColor(task.taskType.swiftUIColor)

                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let instructions = task.notes {
                        Text(instructions)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Task metadata
                    HStack(spacing: Spacing.md) {
                        Label(task.taskType.displayName, systemImage: task.taskType.iconName)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let time = task.formattedDueTime {
                            Text("|")
                                .foregroundColor(.secondary)
                            Text(time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, Spacing.xs)
                }
                .padding(.top, Spacing.xl)

                // Notes input
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Notes (optional)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("How did it go?", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                .padding(.horizontal)

                Spacer()

                // Action buttons
                VStack(spacing: Spacing.sm) {
                    Button(action: {
                        HapticFeedback.success()
                        onComplete(notes.isEmpty ? nil : notes)
                    }) {
                        Label("Mark Complete", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.modusTealAccent)
                            .foregroundColor(.white)
                            .cornerRadius(CornerRadius.md)
                    }

                    Button(action: {
                        HapticFeedback.light()
                        onSkip()
                    }) {
                        Text("Skip Task")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Complete Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AthleteTaskCompletionSheet(
        task: AssignedTask(
            id: UUID(),
            planId: UUID(),
            title: "Morning Stretches",
            taskType: .stretch,
            dueDate: Date(),
            dueTime: "08:00",
            status: .pending,
            completedAt: nil,
            notes: "Hold each stretch for 30 seconds. Focus on hamstrings and hip flexors."
        ),
        onComplete: { _ in },
        onSkip: {}
    )
}
