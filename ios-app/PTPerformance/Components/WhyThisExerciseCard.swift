//
//  WhyThisExerciseCard.swift
//  PTPerformance
//
//  ACP-816: "Why This Exercise" Explanations Feature
//  Displays baseball-specific benefits, muscle groups, and performance connections
//

import SwiftUI

/// Card component displaying "Why This Exercise" explanation with baseball-specific content
/// Shows baseball benefit, muscle groups targeted, and performance connection
struct WhyThisExerciseCard: View {
    let explanation: ExerciseExplanation

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            headerSection

            // Baseball benefit section
            if let baseballBenefit = explanation.baseballBenefit, !baseballBenefit.isEmpty {
                baseballBenefitSection(baseballBenefit)
            }

            // Muscle groups section
            if explanation.hasMuscleInfo {
                muscleGroupsSection
            }

            // Performance connection section
            if let performanceConnection = explanation.performanceConnection, !performanceConnection.isEmpty {
                performanceConnectionSection(performanceConnection)
            }

            // Movement pattern badge
            if let pattern = explanation.movementPatternDisplay {
                movementPatternBadge(pattern)
            }

            // Research note (if available)
            if let researchNote = explanation.researchNote, !researchNote.isEmpty {
                researchNoteSection(researchNote)
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "baseball.fill")
                .font(.title2)
                .foregroundColor(.orange)
                .accessibilityHidden(true)

            Text("Why This Exercise")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Why This Exercise section")
    }

    // MARK: - Baseball Benefit Section

    private func baseballBenefitSection(_ benefit: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .accessibilityHidden(true)

                Text("Baseball Benefit")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            Text(benefit)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Baseball benefit: \(benefit)")
    }

    // MARK: - Muscle Groups Section

    private var muscleGroupsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Primary muscles
            if let primaryMuscles = explanation.primaryMuscles, !primaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "figure.arms.open")
                            .font(.caption)
                            .foregroundColor(.modusCyan)
                            .accessibilityHidden(true)

                        Text("Primary Muscles")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }

                    FlowLayoutView(spacing: Spacing.xs) {
                        ForEach(primaryMuscles, id: \.self) { muscle in
                            MuscleTag(name: muscle, isPrimary: true)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Primary muscles: \(explanation.formattedPrimaryMuscles)")
            }

            // Secondary muscles
            if let secondaryMuscles = explanation.secondaryMuscles, !secondaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "figure.walk")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .accessibilityHidden(true)

                        Text("Secondary Muscles")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }

                    FlowLayoutView(spacing: Spacing.xs) {
                        ForEach(secondaryMuscles, id: \.self) { muscle in
                            MuscleTag(name: muscle, isPrimary: false)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Secondary muscles: \(explanation.formattedSecondaryMuscles)")
            }
        }
    }

    // MARK: - Performance Connection Section

    private func performanceConnectionSection(_ connection: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "arrow.up.forward.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                    .accessibilityHidden(true)

                Text("On-Field Performance")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            Text(connection)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.08))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("On-field performance: \(connection)")
    }

    // MARK: - Movement Pattern Badge

    private func movementPatternBadge(_ pattern: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: movementPatternIcon(pattern))
                .font(.caption)
                .foregroundColor(.purple)

            Text(pattern)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.purple)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(CornerRadius.xs)
        .accessibilityLabel("Movement pattern: \(pattern)")
    }

    // MARK: - Research Note Section

    private func researchNoteSection(_ note: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: "book.fill")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text(note)
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Research note: \(note)")
    }

    // MARK: - Helper Methods

    private func movementPatternIcon(_ pattern: String) -> String {
        switch pattern.lowercased() {
        case "hip hinge": return "arrow.up.and.down"
        case "rotation": return "arrow.triangle.2.circlepath"
        case "push": return "arrow.right"
        case "pull": return "arrow.left"
        case "squat": return "arrow.down"
        case "lunge": return "figure.walk"
        case "carry": return "hand.raised.fill"
        case "core stability": return "circle.grid.cross"
        default: return "figure.strengthtraining.traditional"
        }
    }
}

// MARK: - Muscle Tag Component

/// Tag component for displaying muscle names with primary/secondary styling
struct MuscleTag: View {
    let name: String
    let isPrimary: Bool

    var body: some View {
        Text(formattedName)
            .font(.caption)
            .fontWeight(isPrimary ? .semibold : .regular)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(isPrimary ? Color.modusCyan.opacity(0.15) : Color.gray.opacity(0.1))
            .foregroundColor(isPrimary ? .modusCyan : .secondary)
            .cornerRadius(CornerRadius.xs)
            .accessibilityLabel("\(formattedName), \(isPrimary ? "primary" : "secondary") muscle")
    }

    private var formattedName: String {
        name.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Flow Layout View

/// A view that arranges its children in a flow layout (wrapping horizontally)
struct FlowLayoutView<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content

    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: spacing) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Compact Why This Exercise Card

/// A more compact version of the card for inline use
struct WhyThisExerciseCompactCard: View {
    let explanation: ExerciseExplanation
    var onTapShowMore: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Baseball benefit with icon
            if let baseballBenefit = explanation.baseballBenefit, !baseballBenefit.isEmpty {
                HStack(alignment: .top, spacing: Spacing.xs) {
                    Image(systemName: "baseball.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)

                    Text(baseballBenefit)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
            }

            // Muscle groups (compact)
            if let primaryMuscles = explanation.primaryMuscles, !primaryMuscles.isEmpty {
                HStack(spacing: Spacing.xxs) {
                    ForEach(primaryMuscles.prefix(3), id: \.self) { muscle in
                        MuscleTag(name: muscle, isPrimary: true)
                    }
                    if primaryMuscles.count > 3 {
                        Text("+\(primaryMuscles.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Performance connection
            if let performanceConnection = explanation.performanceConnection, !performanceConnection.isEmpty {
                Text(performanceConnection)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            // Show more button
            if let onTapShowMore = onTapShowMore {
                Button(action: onTapShowMore) {
                    HStack(spacing: Spacing.xxs) {
                        Text("Learn More")
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.modusCyan)
                }
                .accessibilityLabel("Learn more about this exercise")
            }
        }
        .padding(Spacing.sm)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Preview

#if DEBUG
// Preview-only extension to provide a fallback explanation
private extension ExerciseExplanation {
    static var previewFallback: ExerciseExplanation {
        ExerciseExplanation(
            id: UUID(),
            exerciseTemplateId: UUID(),
            programId: nil,
            whyIncluded: "Sample exercise explanation",
            whatItTargets: nil,
            howItHelps: nil,
            whenToFeelIt: nil,
            signsOfProgress: nil,
            warningSigns: nil,
            easierVariation: nil,
            harderVariation: nil,
            equipmentAlternatives: nil,
            baseballBenefit: "Sample baseball benefit",
            performanceConnection: "Sample performance connection",
            primaryMuscles: ["core"],
            secondaryMuscles: nil,
            movementPattern: nil,
            researchNote: nil
        )
    }
}

struct WhyThisExerciseCard_Previews: PreviewProvider {
    static var sampleExplanation: ExerciseExplanation {
        // Create a sample explanation for preview using JSON decoding
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "exercise_template_id": "550e8400-e29b-41d4-a716-446655440001",
            "program_id": null,
            "why_included": "Develops the rotational strength needed for explosive athletic movements",
            "what_it_targets": "Core and hip rotational muscles",
            "how_it_helps": "Improves rotational power for hitting and throwing",
            "when_to_feel_it": "You should feel this in your obliques and hip flexors",
            "signs_of_progress": ["Increased rotation range", "Better control"],
            "warning_signs": ["Lower back pain", "Hip discomfort"],
            "easier_variation": "Standing rotation with lighter band",
            "harder_variation": "Add explosive component",
            "equipment_alternatives": "Medicine ball rotation",
            "baseball_benefit": "Builds rotational power essential for throwing and hitting",
            "performance_connection": "The same hip rotation pattern used in your swing and throw",
            "primary_muscles": ["obliques", "core", "hip_flexors"],
            "secondary_muscles": ["shoulders", "glutes"],
            "movement_pattern": "rotation",
            "research_note": "Studies show rotational power correlates strongly with bat speed (Szymanski et al., 2007)"
        }
        """.data(using: .utf8)!

        do {
            return try JSONDecoder().decode(ExerciseExplanation.self, from: json)
        } catch {
            // Preview-only fallback: return a minimal explanation if decoding fails
            // This allows previews to render even if the model changes
            assertionFailure("Preview sample data failed to decode: \(error)")
            return ExerciseExplanation.previewFallback
        }
    }

    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                Text("Full Card")
                    .font(.headline)

                WhyThisExerciseCard(explanation: sampleExplanation)

                Divider()

                Text("Compact Card")
                    .font(.headline)

                WhyThisExerciseCompactCard(
                    explanation: sampleExplanation,
                    onTapShowMore: {}
                )

                Divider()

                Text("Muscle Tags")
                    .font(.headline)

                HStack(spacing: Spacing.xs) {
                    MuscleTag(name: "glutes", isPrimary: true)
                    MuscleTag(name: "core", isPrimary: true)
                    MuscleTag(name: "hip_flexors", isPrimary: false)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Why This Exercise Components")
    }
}
#endif
