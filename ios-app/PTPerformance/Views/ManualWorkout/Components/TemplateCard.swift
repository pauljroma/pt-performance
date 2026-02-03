//
//  TemplateCard.swift
//  PTPerformance
//
//  Reusable template card component for displaying workout templates
//

import SwiftUI

// MARK: - Template Card View

struct TemplateCardView: View {
    let template: AnyWorkoutTemplate
    var isFavorite: Bool = false
    var showFavoriteButton: Bool = false
    var onFavoriteToggle: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with category badge and favorite button
            HStack {
                if let category = template.category {
                    TemplateCategoryBadge(category: category)
                }
                Spacer()

                // Favorite button
                if showFavoriteButton {
                    Button {
                        onFavoriteToggle?()
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.body)
                            .foregroundColor(isFavorite ? .red : .secondary)
                    }
                    .buttonStyle(.plain)
                } else if template.isSystemTemplate {
                    Image(systemName: "building.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Template name
            Text(template.name)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Description preview
            if let description = template.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Exercise list - show first 5 exercises with sets/reps
            exerciseListPreview

            Spacer(minLength: 4)

            // Stats row
            statsRow
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .adaptiveShadow(Shadow.subtle)
        .contentShape(Rectangle())
        .contextMenu {
            contextMenuContent
        }
    }

    // MARK: - Exercise List Preview

    @ViewBuilder
    private var exerciseListPreview: some View {
        let allExercises = template.blocks.flatMap { $0.exercises }
        if !allExercises.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(allExercises.prefix(5).enumerated()), id: \.offset) { _, exercise in
                    // Use notes as name if exercise name is just a number
                    let displayName = exercise.name.count <= 2 && Int(exercise.name) != nil
                        ? (exercise.notes ?? exercise.name)
                        : exercise.name

                    HStack(spacing: 4) {
                        Text("\u{2022}")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text(displayName)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Spacer()
                        Text(exercise.setsRepsDisplay)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                if allExercises.count > 5 {
                    Text("+ \(allExercises.count - 5) more exercises")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 8) {
            // Compact stats with better spacing
            HStack(spacing: 6) {
                // Exercise count
                HStack(spacing: 2) {
                    Image(systemName: "figure.strengthtraining.traditional")
                    Text("\(template.exerciseCount)")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                Text("\u{00B7}")
                    .foregroundColor(.secondary.opacity(0.5))

                // Block count
                HStack(spacing: 2) {
                    Image(systemName: "square.stack.3d.up")
                    Text("\(template.blocks.count)")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                // Duration if available
                if let duration = template.durationDisplay {
                    Text("\u{00B7}")
                        .foregroundColor(.secondary.opacity(0.5))

                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                        Text(duration)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            Spacer(minLength: 4)

            // Difficulty badge if available
            if let difficulty = template.difficulty {
                TemplateDifficultyBadge(difficulty: difficulty)
            }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuContent: some View {
        Button {
            HapticFeedback.light()
            onFavoriteToggle?()
        } label: {
            Label(
                isFavorite ? "Remove from Favorites" : "Add to Favorites",
                systemImage: isFavorite ? "heart.slash" : "heart"
            )
        }

        Button {
            HapticFeedback.light()
            // Copy workout name
            UIPasteboard.general.string = template.name
        } label: {
            Label("Copy Name", systemImage: "doc.on.doc")
        }

        if let description = template.description, !description.isEmpty {
            Button {
                HapticFeedback.light()
                UIPasteboard.general.string = description
            } label: {
                Label("Copy Description", systemImage: "text.alignleft")
            }
        }

        Divider()

        // Exercise count info
        Button {
            HapticFeedback.light()
            let allExercises = template.blocks.flatMap { $0.exercises }
            let exerciseList = allExercises.map { $0.name }.joined(separator: "\n")
            UIPasteboard.general.string = "\(template.name)\n\nExercises:\n\(exerciseList)"
        } label: {
            Label("Copy Exercise List", systemImage: "list.bullet")
        }
    }
}

// MARK: - Template Category Badge

struct TemplateCategoryBadge: View {
    let category: String

    var body: some View {
        Text(category.capitalized)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(categoryColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(categoryColor.opacity(0.15))
            .cornerRadius(6)
    }

    private var categoryColor: Color {
        switch category.lowercased() {
        case "strength": return .blue
        case "mobility": return .green
        case "cardio": return .red
        case "rehab": return .orange
        case "hybrid": return .purple
        default: return .gray
        }
    }
}

// MARK: - Template Difficulty Badge

struct TemplateDifficultyBadge: View {
    let difficulty: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: difficultyIcon)
                .font(.caption2)

            Text(difficulty.capitalized)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(difficultyColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(difficultyColor.opacity(0.15))
        .cornerRadius(6)
    }

    private var difficultyIcon: String {
        switch difficulty.lowercased() {
        case "beginner": return "1.circle.fill"
        case "intermediate": return "2.circle.fill"
        case "advanced": return "3.circle.fill"
        default: return "circle.fill"
        }
    }

    private var difficultyColor: Color {
        switch difficulty.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .gray
        }
    }
}
