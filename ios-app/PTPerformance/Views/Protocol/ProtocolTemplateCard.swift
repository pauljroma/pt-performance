//
//  ProtocolTemplateCard.swift
//  PTPerformance
//
//  Card component for displaying protocol templates in selection grid
//

import SwiftUI

struct ProtocolTemplateCard: View {
    let template: ProtocolTemplate
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with category badge
                HStack {
                    CategoryBadge(category: template.category)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }

                // Template name
                Text(template.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Description
                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                // Footer with stats
                HStack {
                    // Task count
                    Label("\(template.taskCount)", systemImage: "checklist")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Duration
                    Label(template.estimatedDuration, systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(minHeight: 160)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: isSelected ? 8 : 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Badge

struct CategoryBadge: View {
    let category: ProtocolTemplate.ProtocolCategory

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.iconName)
                .font(.caption2)
            Text(category.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(categoryColor.opacity(0.15))
        .foregroundColor(categoryColor)
        .cornerRadius(8)
    }

    private var categoryColor: Color {
        switch category.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        default: return .gray
        }
    }
}

// MARK: - Template Preview Sheet

struct TemplatePreviewSheet: View {
    let template: ProtocolTemplate
    let onSelect: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        CategoryBadge(category: template.category)

                        Text(template.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(template.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Duration info
                    HStack(spacing: 20) {
                        InfoCard(
                            title: "Duration",
                            value: template.estimatedDuration,
                            icon: "clock"
                        )

                        InfoCard(
                            title: "Tasks",
                            value: "\(template.taskCount)",
                            icon: "checklist"
                        )

                        InfoCard(
                            title: "Status",
                            value: template.isActive ? "Active" : "Inactive",
                            icon: template.isActive ? "checkmark.circle" : "xmark.circle"
                        )
                    }

                    // Tasks list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tasks Included")
                            .font(.headline)

                        ForEach(template.tasks) { task in
                            TaskPreviewRow(task: task)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Protocol Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Select") {
                        onSelect()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)

            Text(value)
                .font(.headline)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Task Preview Row

struct TaskPreviewRow: View {
    let task: ProtocolTask

    var body: some View {
        HStack(spacing: 12) {
            // Task type icon
            Image(systemName: task.taskType.iconName)
                .font(.title3)
                .foregroundColor(taskTypeColor)
                .frame(width: 32, height: 32)
                .background(taskTypeColor.opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(task.frequency.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let time = task.defaultTime {
                        Text("|")
                            .foregroundColor(.secondary)
                        Text(time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let duration = task.durationMinutes {
                        Text("|")
                            .foregroundColor(.secondary)
                        Text("\(duration) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private var taskTypeColor: Color {
        switch task.taskType.color {
        case "green": return .green
        case "purple": return .purple
        case "cyan": return .cyan
        case "orange": return .orange
        case "blue": return .blue
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ProtocolTemplateCard(
            template: .postWorkoutRecovery,
            isSelected: false,
            onSelect: {}
        )
        .frame(width: 180)

        ProtocolTemplateCard(
            template: .returnToTraining,
            isSelected: true,
            onSelect: {}
        )
        .frame(width: 180)
    }
    .padding()
    .background(Color(.systemGray5))
}
