//
//  ExerciseExplanationView.swift
//  PTPerformance
//
//  Created by Content & Polish Sprint Agent 6
//  View displaying "Why This Exercise" educational content
//

import SwiftUI

/// View displaying "Why This Exercise" educational content
/// Shows program-specific context for why an exercise is included
struct ExerciseExplanationView: View {
    let exerciseTemplateId: UUID
    let exerciseName: String
    var programId: UUID? = nil

    @StateObject private var service = ExerciseExplanationService.shared
    @State private var explanation: ExerciseExplanation?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header with exercise name
                headerSection

                if isLoading {
                    loadingState
                } else if let explanation = explanation {
                    explanationContent(explanation)
                } else if let error = error {
                    errorState(message: error)
                } else {
                    noExplanationState
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("About This Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadExplanation()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text(exerciseName)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()
            }

            Text("Learn why this exercise is part of your program")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading explanation...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Explanation Content

    @ViewBuilder
    private func explanationContent(_ explanation: ExerciseExplanation) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Why Included
            if !explanation.whyIncluded.isEmpty {
                ExplanationSection(
                    title: "Why This Exercise?",
                    icon: "questionmark.circle.fill",
                    iconColor: .blue,
                    content: explanation.whyIncluded
                )
            }

            // What It Targets
            if let targets = explanation.whatItTargets, !targets.isEmpty {
                ExplanationSection(
                    title: "What It Targets",
                    icon: "target",
                    iconColor: .orange,
                    content: targets
                )
            }

            // How It Helps
            if let helps = explanation.howItHelps, !helps.isEmpty {
                ExplanationSection(
                    title: "How It Helps You",
                    icon: "arrow.up.circle.fill",
                    iconColor: .green,
                    content: helps
                )
            }

            // Where to Feel It
            if let feelIt = explanation.whenToFeelIt, !feelIt.isEmpty {
                ExplanationSection(
                    title: "Where You Should Feel It",
                    icon: "hand.point.up.fill",
                    iconColor: .purple,
                    content: feelIt
                )
            }

            // Signs of Progress
            if let signs = explanation.signsOfProgress, !signs.isEmpty {
                ProgressSignsSection(signs: signs)
            }

            // Warning Signs
            if let warnings = explanation.warningSigns, !warnings.isEmpty {
                WarningSignsSection(warnings: warnings)
            }

            // Variations Section
            variationsSection(explanation)
        }
    }

    // MARK: - Variations Section

    @ViewBuilder
    private func variationsSection(_ explanation: ExerciseExplanation) -> some View {
        let hasVariations = explanation.easierVariation != nil ||
                           explanation.harderVariation != nil ||
                           explanation.equipmentAlternatives != nil

        if hasVariations {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.title3)
                        .foregroundColor(.cyan)

                    Text("Variations & Alternatives")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(.bottom, Spacing.xxs)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    if let easier = explanation.easierVariation, !easier.isEmpty {
                        VariationRow(
                            label: "Easier Option",
                            value: easier,
                            icon: "arrow.down.circle.fill",
                            color: .green
                        )
                    }

                    if let harder = explanation.harderVariation, !harder.isEmpty {
                        VariationRow(
                            label: "Harder Option",
                            value: harder,
                            icon: "arrow.up.circle.fill",
                            color: .red
                        )
                    }

                    if let equipment = explanation.equipmentAlternatives, !equipment.isEmpty {
                        VariationRow(
                            label: "Equipment Alternatives",
                            value: equipment,
                            icon: "dumbbell.fill",
                            color: .gray
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(CornerRadius.md)
            }
        }
    }

    // MARK: - Error State

    private func errorState(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Load")
                .font(.headline)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task {
                    await loadExplanation()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.sm)
            }
            .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - No Explanation State

    private var noExplanationState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Explanation Available")
                .font(.headline)
                .fontWeight(.semibold)

            Text("Detailed information about this exercise hasn't been added yet. Your therapist may provide specific guidance during your sessions.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Load Explanation

    private func loadExplanation() async {
        isLoading = true
        error = nil

        do {
            explanation = try await service.fetchExplanation(
                exerciseTemplateId: exerciseTemplateId,
                programId: programId
            )
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Explanation Section

/// Reusable section for displaying explanation content
private struct ExplanationSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Progress Signs Section

/// Section displaying signs of progress as a bulleted list
private struct ProgressSignsSection: View {
    let signs: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundColor(.mint)

                Text("Signs of Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(signs, id: \.self) { sign in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.mint)
                            .padding(.top, 2)

                        Text(sign)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Warning Signs Section

/// Section displaying warning signs with appropriate styling
private struct WarningSignsSection: View {
    let warnings: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(.red)

                Text("Warning Signs")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Text("Stop and consult your therapist if you experience:")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, Spacing.xxs)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(warnings, id: \.self) { warning in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding(.top, 2)

                        Text(warning)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Variation Row

/// Row displaying a variation option
private struct VariationRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Spacing.xxs)
    }
}

// MARK: - Preview

#if DEBUG
struct ExerciseExplanationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ExerciseExplanationView(
                exerciseTemplateId: UUID(),
                exerciseName: "Romanian Deadlift",
                programId: UUID()
            )
        }
        .previewDisplayName("Standard View")

        NavigationStack {
            // Preview with mock loaded state
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    ExplanationSection(
                        title: "Why This Exercise?",
                        icon: "questionmark.circle.fill",
                        iconColor: .blue,
                        content: "The Romanian Deadlift is included in your program to strengthen your posterior chain, improve hip hinge mechanics, and build foundational strength for athletic performance."
                    )

                    ExplanationSection(
                        title: "What It Targets",
                        icon: "target",
                        iconColor: .orange,
                        content: "Primary: Hamstrings, Glutes, Lower Back. Secondary: Core stability, Grip strength"
                    )

                    ExplanationSection(
                        title: "How It Helps You",
                        icon: "arrow.up.circle.fill",
                        iconColor: .green,
                        content: "This exercise improves your ability to maintain spinal position under load, directly transferring to better performance in squats, deadlifts, and athletic movements like jumping and sprinting."
                    )

                    ProgressSignsSection(signs: [
                        "Feeling hamstring stretch at bottom position",
                        "Better control during eccentric (lowering) phase",
                        "Increased weight while maintaining form",
                        "Reduced lower back fatigue"
                    ])

                    WarningSignsSection(warnings: [
                        "Sharp pain in lower back",
                        "Numbness or tingling in legs",
                        "Unable to maintain neutral spine"
                    ])
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("About This Exercise")
            .navigationBarTitleDisplayMode(.inline)
        }
        .previewDisplayName("Loaded State")
    }
}
#endif
