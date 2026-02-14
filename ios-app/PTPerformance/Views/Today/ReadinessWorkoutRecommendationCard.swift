import SwiftUI

/// Card showing readiness-based workout recommendations
/// Part of Recovery Intelligence feature - displays in TodaySessionView
struct ReadinessWorkoutRecommendationCard: View {

    // MARK: - Properties

    let adaptation: WorkoutAdaptation
    let onViewRecoveryProtocol: () -> Void
    let onViewInsights: () -> Void
    let onStartAlternative: (AlternativeWorkout) -> Void

    @State private var isExpanded = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with recommendation
            headerSection

            // Quick recommendation message
            recommendationBanner

            // ACP-1025: AI Transparency - expandable reasoning section
            AIRecommendationTransparencyCard(
                recommendationId: "readiness-\(adaptation.recommendationType.rawValue)-\(Date().formatted(.iso8601.year().month().day()))",
                recommendationType: .workoutAdaptation,
                reasoningSummary: adaptation.detailedRecommendation,
                drivingFactors: buildDrivingFactors(),
                confidenceLevel: .high
            )

            // Expandable content
            if isExpanded {
                expandedContent
            }

            // Action buttons
            actionButtons
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .adaptiveShadow(Shadow.medium)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(adaptation.recommendationType.color.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(adaptation.recommendationType.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: adaptation.recommendationType.icon)
                        .font(.title3)
                        .foregroundColor(adaptation.recommendationType.color)
                }

                // Title
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Recommendation")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(adaptation.recommendationType.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Expand/collapse indicator
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recommendation Banner

    private var recommendationBanner: some View {
        Text(adaptation.message)
            .font(.subheadline)
            .foregroundColor(.primary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(adaptation.recommendationType.color.opacity(0.1))
            )
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()

            // Detailed recommendation
            Text(adaptation.detailedRecommendation)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Scaling factors (if workout is modified, not rest)
            if adaptation.recommendationType != .restDay {
                scalingFactorsSection
            }

            // Alternative workouts (if low readiness)
            if !adaptation.alternativeWorkouts.isEmpty {
                alternativeWorkoutsSection
            }

            // Top recovery tips
            if !adaptation.recoveryTips.isEmpty {
                recoveryTipsSection
            }
        }
    }

    // MARK: - Scaling Factors Section

    private var scalingFactorsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workout Adjustments")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 16) {
                AdjustmentPill(
                    title: "Intensity",
                    value: adaptation.scalingFactors.intensityReductionText,
                    icon: "scalemass"
                )

                AdjustmentPill(
                    title: "Volume",
                    value: adaptation.scalingFactors.volumeReductionText,
                    icon: "list.number"
                )

                if let rpe = adaptation.scalingFactors.rpeTarget {
                    AdjustmentPill(
                        title: "RPE Target",
                        value: "\(rpe)",
                        icon: "gauge"
                    )
                }
            }
        }
    }

    // MARK: - Alternative Workouts Section

    private var alternativeWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Try Instead")
                .font(.subheadline.weight(.medium))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(adaptation.alternativeWorkouts.prefix(3)) { workout in
                        AlternativeWorkoutPill(workout: workout) {
                            onStartAlternative(workout)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recovery Tips Section

    private var recoveryTipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recovery Tips")
                .font(.subheadline.weight(.medium))

            ForEach(adaptation.recoveryTips.prefix(2)) { tip in
                QuickRecoveryTipRow(tip: tip)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                HapticFeedback.light()
                onViewRecoveryProtocol()
            } label: {
                Label("Full Protocol", systemImage: "doc.text")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
            }

            Button {
                HapticFeedback.light()
                onViewInsights()
            } label: {
                Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.purple.opacity(0.1))
                    )
            }

            Spacer()
        }
    }

    // MARK: - ACP-1025 Driving Factors Builder

    /// Builds driving factors from the workout adaptation data for transparency display
    private func buildDrivingFactors() -> [RecommendationDrivingFactor] {
        var factors: [RecommendationDrivingFactor] = []

        // Derive approximate readiness from intensity multiplier
        // (full intensity = high readiness, low multiplier = low readiness)
        let approxReadiness = adaptation.scalingFactors.intensityMultiplier * 100
        factors.append(.readinessScore(score: approxReadiness))

        // Add intensity factor if workout is modified
        if adaptation.recommendationType != .restDay {
            let intensityReduction = adaptation.scalingFactors.intensityMultiplier
            if intensityReduction < 1.0 {
                let changePercent = (1.0 - intensityReduction) * 100
                factors.append(RecommendationDrivingFactor(
                    icon: "scalemass",
                    iconColor: changePercent > 15 ? .orange : .blue,
                    metric: "Intensity reduced by \(Int(changePercent))%",
                    detail: "Based on today's readiness assessment",
                    category: .training
                ))
            }

            let volumeReduction = adaptation.scalingFactors.volumeMultiplier
            if volumeReduction < 1.0 {
                let changePercent = (1.0 - volumeReduction) * 100
                factors.append(RecommendationDrivingFactor(
                    icon: "list.number",
                    iconColor: changePercent > 25 ? .orange : .blue,
                    metric: "Volume reduced by \(Int(changePercent))%",
                    detail: "Fewer sets to manage fatigue",
                    category: .training
                ))
            }
        }

        // Add rest day factor
        if adaptation.recommendationType == .restDay {
            factors.append(RecommendationDrivingFactor(
                icon: "bed.double.fill",
                iconColor: .indigo,
                metric: "Rest day recommended",
                detail: "Recovery takes priority today",
                category: .recovery
            ))
        }

        return factors
    }

    // MARK: - Loading Placeholder

    static var loadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 12)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 150, height: 16)
                }

                Spacer()
            }

            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 50)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .redacted(reason: .placeholder)
    }
}

// MARK: - Supporting Views

struct AdjustmentPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.05))
        )
    }
}

struct AlternativeWorkoutPill: View {
    let workout: AlternativeWorkout
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: workout.type.icon)
                    .font(.caption)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.name)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.primary)

                    Text("\(workout.duration) min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

struct QuickRecoveryTipRow: View {
    let tip: RecoveryTip

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: tip.category.icon)
                .font(.caption)
                .foregroundColor(tip.category.color)
                .frame(width: 20)

            Text(tip.title)
                .font(.caption)
                .foregroundColor(.primary)

            Spacer()

            if tip.priority == .high {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("High Readiness") {
    ReadinessWorkoutRecommendationCard(
        adaptation: .sampleHighReadiness,
        onViewRecoveryProtocol: {},
        onViewInsights: {},
        onStartAlternative: { _ in }
    )
    .padding()
}

#Preview("Low Readiness") {
    ReadinessWorkoutRecommendationCard(
        adaptation: .sampleLowReadiness,
        onViewRecoveryProtocol: {},
        onViewInsights: {},
        onStartAlternative: { _ in }
    )
    .padding()
}

#Preview("Loading") {
    ReadinessWorkoutRecommendationCard.loadingPlaceholder
        .padding()
}
#endif
