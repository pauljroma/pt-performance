import SwiftUI

/// View displaying workout recommendations based on fasting state
struct FastingWorkoutRecommendationView: View {
    let recommendation: FastingWorkoutRecommendation

    var body: some View {
        VStack(spacing: 20) {
            // Intensity Gauge Section
            intensityGaugeSection

            // Recommended Workout Types
            if !recommendation.recommendedWorkoutTypes.isEmpty {
                recommendedWorkoutsSection
            }

            // Safety Warnings
            if !recommendation.safetyWarnings.isEmpty {
                warningsSection
            }

            // Nutrition Timing
            nutritionTimingSection

            // Electrolyte Recommendations
            if !recommendation.electrolyteRecommendations.isEmpty {
                electrolyteSection
            }

            // Performance Notes
            if !recommendation.performanceNotes.isEmpty {
                performanceNotesSection
            }

            // Alternative Suggestion
            if let alternative = recommendation.alternativeWorkoutSuggestion {
                alternativeSuggestionCard(alternative)
            }
        }
        .padding()
    }

    // MARK: - Intensity Gauge

    private var intensityGaugeSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "gauge.with.needle.fill")
                    .foregroundColor(.modusCyan)
                Text("Training Intensity")
                    .font(.headline)
                Spacer()
            }

            ZStack {
                // Background gauge arc
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(135))

                // Filled gauge arc
                Circle()
                    .trim(from: 0, to: gaugeProgress)
                    .stroke(
                        gaugeGradient,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                    .animation(.easeInOut(duration: 0.8), value: gaugeProgress)

                // Center content
                VStack(spacing: 4) {
                    Text("\(recommendation.intensityPercentage)%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(intensityColor)

                    Text("Recommended")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 160, height: 160)

            // Intensity label
            Text(intensityLabel)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(intensityColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(intensityColor.opacity(0.15))
                .cornerRadius(CornerRadius.xl)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var gaugeProgress: CGFloat {
        CGFloat(recommendation.intensityModifier) * 0.75
    }

    private var gaugeGradient: LinearGradient {
        LinearGradient(
            colors: [.modusDeepTeal, .modusTealAccent],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var intensityColor: Color {
        let percentage = recommendation.intensityPercentage
        if percentage >= 90 {
            return .modusTealAccent
        } else if percentage >= 75 {
            return .modusCyan
        } else if percentage >= 60 {
            return .orange
        } else {
            return .red
        }
    }

    private var intensityLabel: String {
        let percentage = recommendation.intensityPercentage
        if percentage >= 90 {
            return "Train at full capacity"
        } else if percentage >= 75 {
            return "Train at \(percentage)% today"
        } else if percentage >= 60 {
            return "Light activity recommended"
        } else {
            return "Rest or very light movement"
        }
    }

    // MARK: - Recommended Workouts

    private var recommendedWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.run")
                    .foregroundColor(.modusCyan)
                Text("Recommended Activities")
                    .font(.headline)
                Spacer()
            }

            FlowLayout(spacing: 8) {
                ForEach(recommendation.recommendedWorkoutTypes, id: \.self) { workoutType in
                    workoutTypeChip(workoutType)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func workoutTypeChip(_ type: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: iconForWorkoutType(type))
                .font(.caption)
            Text(type)
                .font(.subheadline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.modusCyan.opacity(0.15))
        .foregroundColor(.modusCyan)
        .cornerRadius(CornerRadius.xl)
    }

    private func iconForWorkoutType(_ type: String) -> String {
        let lowercased = type.lowercased()
        if lowercased.contains("strength") {
            return "dumbbell.fill"
        } else if lowercased.contains("hiit") {
            return "bolt.fill"
        } else if lowercased.contains("cardio") {
            return "heart.fill"
        } else if lowercased.contains("walking") {
            return "figure.walk"
        } else if lowercased.contains("yoga") {
            return "figure.yoga"
        } else if lowercased.contains("mobility") || lowercased.contains("stretching") {
            return "figure.flexibility"
        } else {
            return "checkmark.circle.fill"
        }
    }

    // MARK: - Warnings Section

    private var warningsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Safety Warnings")
                    .font(.headline)
                Spacer()
            }

            ForEach(recommendation.safetyWarnings, id: \.self) { warning in
                WarningCard(message: warning, severity: warningSeverity(for: warning))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private func warningSeverity(for warning: String) -> WarningSeverity {
        let lowercased = warning.lowercased()
        if lowercased.contains("not recommended") || lowercased.contains("risk") || lowercased.contains("hypoglycemia") {
            return .high
        } else if lowercased.contains("reduce") || lowercased.contains("depleted") || lowercased.contains("impair") {
            return .medium
        }
        return .low
    }

    // MARK: - Nutrition Timing

    private var nutritionTimingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "fork.knife.circle.fill")
                    .foregroundColor(.modusTealAccent)
                Text("Nutrition Timing")
                    .font(.headline)
                Spacer()
            }

            Text(recommendation.nutritionTiming.recommendation)
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                if let preWorkout = recommendation.nutritionTiming.preWorkout {
                    NutritionTimingRow(
                        label: "Pre-Workout",
                        value: preWorkout,
                        icon: "arrow.right.circle.fill",
                        color: .blue
                    )
                }

                if let intraWorkout = recommendation.nutritionTiming.intraWorkout {
                    NutritionTimingRow(
                        label: "During",
                        value: intraWorkout,
                        icon: "circle.circle.fill",
                        color: .modusCyan
                    )
                }

                NutritionTimingRow(
                    label: "Post-Workout",
                    value: recommendation.nutritionTiming.postWorkout,
                    icon: "checkmark.circle.fill",
                    color: .modusTealAccent
                )
            }

            if !recommendation.nutritionTiming.timingNotes.isEmpty {
                Text(recommendation.nutritionTiming.timingNotes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Electrolytes

    private var electrolyteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.blue)
                Text("Hydration & Electrolytes")
                    .font(.headline)
                Spacer()
            }

            ForEach(recommendation.electrolyteRecommendations, id: \.self) { rec in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.modusTealAccent)
                        .font(.caption)
                    Text(rec)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Performance Notes

    private var performanceNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.modusDeepTeal)
                Text("Performance Notes")
                    .font(.headline)
                Spacer()
            }

            ForEach(recommendation.performanceNotes, id: \.self) { note in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.modusCyan)
                        .font(.caption)
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Alternative Suggestion

    private func alternativeSuggestionCard(_ suggestion: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Alternative")
                    .font(.headline)
                Spacer()
            }

            Text(suggestion)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Supporting Views

enum WarningSeverity {
    case low, medium, high

    var color: Color {
        switch self {
        case .low: return .modusCyan
        case .medium: return .orange
        case .high: return .red
        }
    }

    var icon: String {
        switch self {
        case .low: return "info.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        }
    }
}

struct WarningCard: View {
    let message: String
    let severity: WarningSeverity

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: severity.icon)
                .foregroundColor(severity.color)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(severity.color.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }
}

struct NutritionTimingRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// FlowLayout is defined in ExerciseDetailSheet.swift

// MARK: - Compact View for Inline Display

/// Compact version of workout recommendation for embedding in other views
struct FastingWorkoutRecommendationCompactView: View {
    let recommendation: FastingWorkoutRecommendation
    var onTapExpand: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Intensity indicator
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: CGFloat(recommendation.intensityModifier))
                        .stroke(intensityColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))

                    Text("\(recommendation.intensityPercentage)%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(intensityColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(intensityLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if !recommendation.safetyWarnings.isEmpty {
                        Text("\(recommendation.safetyWarnings.count) warning\(recommendation.safetyWarnings.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Spacer()

                if let onTap = onTapExpand {
                    Button(action: onTap) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Quick workout types
            if !recommendation.recommendedWorkoutTypes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recommendation.recommendedWorkoutTypes.prefix(3), id: \.self) { type in
                            Text(type)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.modusCyan.opacity(0.15))
                                .foregroundColor(.modusCyan)
                                .cornerRadius(CornerRadius.md)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    private var intensityColor: Color {
        let percentage = recommendation.intensityPercentage
        if percentage >= 90 {
            return .modusTealAccent
        } else if percentage >= 75 {
            return .modusCyan
        } else if percentage >= 60 {
            return .orange
        } else {
            return .red
        }
    }

    private var intensityLabel: String {
        let percentage = recommendation.intensityPercentage
        if percentage >= 90 {
            return "Full Training Capacity"
        } else if percentage >= 75 {
            return "Train at \(percentage)%"
        } else if percentage >= 60 {
            return "Light Activity Only"
        } else {
            return "Rest Recommended"
        }
    }
}

// MARK: - Preview

#Preview("Full View") {
    ScrollView {
        FastingWorkoutRecommendationView(
            recommendation: FastingWorkoutRecommendation(
                optimizationId: UUID().uuidString,
                fastingState: FastingStateResponse(
                    isFasting: true,
                    startedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-17 * 3600)),
                    fastingHours: 17,
                    protocolType: "16_8",
                    plannedHours: 16
                ),
                workoutAllowed: true,
                workoutRecommended: true,
                modifications: [
                    FastingWorkoutModification(
                        type: "volume",
                        originalValue: "100%",
                        modifiedValue: "70-80%",
                        rationale: "Extended fast reduces muscle protein synthesis response."
                    )
                ],
                nutritionTiming: NutritionTiming(
                    recommendation: "Extended fasted state - plan your fast-breaking meal carefully.",
                    preWorkout: "Consider BCAAs or EAAs (5-10g)",
                    intraWorkout: "Essential: Electrolytes with sodium (1000mg+)",
                    postWorkout: "Break fast immediately with protein shake (40g)",
                    timingNotes: "The post-workout window becomes crucial after extended fasting."
                ),
                safetyWarnings: [
                    "Glycogen stores are depleted - expect reduced performance",
                    "Break fast within 1-2 hours post-workout"
                ],
                performanceNotes: [
                    "Expect 10-20% reduction in strength and power",
                    "Fat oxidation significantly elevated"
                ],
                electrolyteRecommendations: [
                    "Electrolytes are essential: sodium (1000-2000mg)",
                    "Use sugar-free electrolyte supplements"
                ],
                alternativeWorkoutSuggestion: nil,
                disclaimer: "Individual responses vary."
            )
        )
    }
}

#Preview("Compact View") {
    FastingWorkoutRecommendationCompactView(
        recommendation: FastingWorkoutRecommendation(
            optimizationId: UUID().uuidString,
            fastingState: FastingStateResponse(
                isFasting: true,
                startedAt: nil,
                fastingHours: 18,
                protocolType: nil,
                plannedHours: nil
            ),
            workoutAllowed: true,
            workoutRecommended: true,
            modifications: [],
            nutritionTiming: NutritionTiming(
                recommendation: "",
                preWorkout: nil,
                intraWorkout: nil,
                postWorkout: "",
                timingNotes: ""
            ),
            safetyWarnings: ["Stay hydrated", "Reduce intensity"],
            performanceNotes: [],
            electrolyteRecommendations: [],
            alternativeWorkoutSuggestion: nil,
            disclaimer: ""
        )
    )
    .padding()
}
