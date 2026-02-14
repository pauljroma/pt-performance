//
//  SmartSchedulingSuggestionCard.swift
//  PTPerformance
//
//  Created for ACP-1034: Smart Scheduling Suggestions
//  Card component displaying AI-powered workout scheduling recommendations
//

import SwiftUI

/// Card displaying smart scheduling suggestions based on recovery and readiness
struct SmartSchedulingSuggestionCard: View {

    let suggestion: SchedulingSuggestion
    let onSchedule: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header with date and muscle group
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundColor(.modusCyan)
                            .accessibilityHidden(true)

                        Text(headerText)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.modusCyan)
                    }

                    Text(suggestion.muscleGroup.displayName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.modusDeepTeal)
                }

                Spacer()

                // Readiness indicator
                readinessIndicator
            }

            // Intensity and time recommendation
            HStack(spacing: Spacing.md) {
                intensityBadge

                Divider()
                    .frame(height: 24)

                timeRecommendation
            }

            // Reason
            Text(suggestion.reason)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Action button
            Button(action: {
                HapticFeedback.medium()
                onSchedule()
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .accessibilityHidden(true)
                    Text("Schedule Workout")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(Color.modusCyan)
                .cornerRadius(CornerRadius.sm)
            }
            .accessibilityLabel("Schedule \(suggestion.muscleGroup.displayName) workout for \(suggestion.formattedDate)")
        }
        .padding(Spacing.md)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.modusLightTeal.opacity(0.3),
                    Color.modusLightTeal.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.modusCyan.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.medium)
    }

    // MARK: - Subviews

    private var headerText: String {
        if suggestion.isToday {
            return "RECOMMENDED TODAY"
        } else {
            return "RECOMMENDED: \(suggestion.formattedDate.uppercased())"
        }
    }

    private var readinessIndicator: some View {
        VStack(spacing: 2) {
            Text("\(Int(suggestion.predictedReadiness))%")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(readinessColor)

            Text("Readiness")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(readinessColor.opacity(0.1))
        .cornerRadius(CornerRadius.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Predicted readiness \(Int(suggestion.predictedReadiness)) percent")
    }

    private var readinessColor: Color {
        if suggestion.predictedReadiness >= 80 {
            return .modusTealAccent
        } else if suggestion.predictedReadiness >= 65 {
            return .modusCyan
        } else {
            return DesignTokens.statusWarning
        }
    }

    private var intensityBadge: some View {
        HStack(spacing: 4) {
            intensityIcon
                .accessibilityHidden(true)

            Text(suggestion.intensity.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(intensityColor)
        .accessibilityLabel("\(suggestion.intensity.displayName) intensity")
    }

    private var intensityIcon: some View {
        HStack(spacing: 2) {
            ForEach(0..<intensityLevel, id: \.self) { _ in
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
            }
        }
    }

    private var intensityLevel: Int {
        switch suggestion.intensity {
        case .light: return 1
        case .moderate: return 2
        case .high: return 3
        }
    }

    private var intensityColor: Color {
        switch suggestion.intensity {
        case .light: return .modusTealAccent
        case .moderate: return .modusCyan
        case .high: return DesignTokens.statusWarning
        }
    }

    private var timeRecommendation: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption)
                .accessibilityHidden(true)

            Text(suggestion.suggestedTime.formatted)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.modusDeepTeal)
        .accessibilityLabel("Suggested time \(suggestion.suggestedTime.formatted)")
    }
}

// MARK: - Best Time to Train Widget

/// Widget displaying optimal training time windows
struct BestTimeToTrainWidget: View {

    let timeWindows: [TrainingTimeWindow]
    let onSchedule: (TrainingTimeWindow) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Image(systemName: "clock.badge.checkmark")
                    .font(.title3)
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)

                Text("Best Times to Train")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                Spacer()
            }

            if timeWindows.isEmpty {
                emptyState
            } else {
                ForEach(timeWindows.prefix(3)) { window in
                    TimeWindowRow(window: window) {
                        HapticFeedback.light()
                        onSchedule(window)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "clock")
                .font(.largeTitle)
                .foregroundColor(.secondary.opacity(0.5))
                .accessibilityHidden(true)

            Text("Building your training schedule insights...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
    }
}

/// Row displaying a training time window
struct TimeWindowRow: View {

    let window: TrainingTimeWindow
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                // Icon
                Circle()
                    .fill(Color.modusCyan.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: timeIcon)
                            .font(.title3)
                            .foregroundColor(.modusCyan)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(window.timeOfDay)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("\(window.startHour):00 - \(window.endHour):00")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(window.reason)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Readiness indicator
                VStack(spacing: 2) {
                    Text("\(Int(window.avgReadiness))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.modusTealAccent)

                    Text("Ready")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(Spacing.sm)
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(window.timeOfDay) training window, \(window.startHour) to \(window.endHour), average readiness \(Int(window.avgReadiness)) percent")
    }

    private var timeIcon: String {
        if window.startHour < 10 {
            return "sunrise.fill"
        } else if window.startHour < 14 {
            return "sun.max.fill"
        } else {
            return "sunset.fill"
        }
    }
}

// MARK: - Calendar Conflict Warning Badge

/// Badge displaying calendar conflict warning
struct CalendarConflictBadge: View {

    let conflicts: [CalendarConflictInfo]
    let onViewConflicts: () -> Void

    var body: some View {
        if !conflicts.isEmpty {
            Button(action: {
                HapticFeedback.light()
                onViewConflicts()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .accessibilityHidden(true)

                    Text("\(conflicts.count) Calendar Conflict\(conflicts.count > 1 ? "s" : "")")
                        .font(.caption)
                        .fontWeight(.medium)

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .accessibilityHidden(true)
                }
                .foregroundColor(DesignTokens.statusWarning)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(DesignTokens.statusWarning.opacity(0.1))
                .cornerRadius(CornerRadius.xs)
            }
            .accessibilityLabel("\(conflicts.count) calendar conflicts detected. Tap to view details.")
        }
    }
}

// MARK: - Missed Workout Auto-Reschedule Card

/// Card displaying auto-rescheduling suggestions for missed workouts
struct MissedWorkoutRescheduleCard: View {

    let proposal: ReschedulingProposal
    let onAccept: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Missed Workout")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignTokens.statusWarning)

                    Text(proposal.originalSession.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                Spacer()

                Button(action: {
                    HapticFeedback.light()
                    onDismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Dismiss suggestion")
            }

            Divider()

            // Suggestion
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                        .accessibilityHidden(true)

                    Text("Suggested reschedule")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.modusCyan)
                }

                Text(formattedSuggestedDate)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.modusDeepTeal)

                Text(proposal.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Actions
            HStack(spacing: Spacing.sm) {
                Button(action: {
                    HapticFeedback.medium()
                    onAccept()
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                            .accessibilityHidden(true)
                        Text("Reschedule")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.modusCyan)
                    .cornerRadius(CornerRadius.sm)
                }
                .accessibilityLabel("Reschedule to \(formattedSuggestedDate)")

                Button(action: {
                    HapticFeedback.light()
                    onDismiss()
                }) {
                    Text("Dismiss")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.sm)
                }
                .accessibilityLabel("Dismiss suggestion")
            }
        }
        .padding(Spacing.md)
        .background(DesignTokens.statusWarning.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(DesignTokens.statusWarning.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    private var formattedSuggestedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateStr = formatter.string(from: proposal.suggestedDate)
        return "\(dateStr) at \(proposal.suggestedTime.formatted)"
    }
}

// MARK: - Preview

#if DEBUG
struct SmartSchedulingSuggestionCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                SmartSchedulingSuggestionCard(
                    suggestion: SchedulingSuggestion(
                        date: Date(),
                        muscleGroup: .upper,
                        intensity: .moderate,
                        suggestedTime: TimeOfDay(hour: 17, minute: 0),
                        predictedReadiness: 85.0,
                        reason: "Your upper body is well-recovered and readiness is predicted at 85%",
                        priority: 0.85,
                        hasCalendarConflicts: false
                    ),
                    onSchedule: {}
                )

                BestTimeToTrainWidget(
                    timeWindows: [
                        TrainingTimeWindow(
                            timeOfDay: "Evening",
                            startHour: 17,
                            endHour: 20,
                            days: [.monday, .wednesday, .friday],
                            reason: "Strong completion rate in evenings",
                            avgReadiness: 82.0
                        ),
                        TrainingTimeWindow(
                            timeOfDay: "Morning",
                            startHour: 6,
                            endHour: 9,
                            days: [.tuesday, .thursday],
                            reason: "High readiness on these mornings",
                            avgReadiness: 78.0
                        )
                    ],
                    onSchedule: { _ in }
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
