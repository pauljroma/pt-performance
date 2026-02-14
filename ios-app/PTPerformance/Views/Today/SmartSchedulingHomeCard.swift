//
//  SmartSchedulingHomeCard.swift
//  PTPerformance
//
//  Created for ACP-1034: Smart Scheduling Suggestions
//  Compact card for displaying smart scheduling on the home/today view
//

import SwiftUI

/// Compact card showing today's smart scheduling suggestion on home view
struct SmartSchedulingHomeCard: View {

    let patientId: UUID
    let onSchedule: (SchedulingSuggestion) -> Void
    let onViewAll: () -> Void

    @StateObject private var smartSchedulingService = SmartSchedulingService.shared
    @State private var todaySuggestion: SchedulingSuggestion?
    @State private var isLoading = false

    var body: some View {
        if let suggestion = todaySuggestion {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(.modusCyan)
                        .accessibilityHidden(true)

                    Text("Recommended for Today")
                        .font(.headline)
                        .foregroundColor(.modusDeepTeal)

                    Spacer()

                    Button(action: {
                        HapticFeedback.light()
                        onViewAll()
                    }) {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(.caption)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                        }
                        .foregroundColor(.modusCyan)
                    }
                    .accessibilityLabel("View all scheduling suggestions")
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.sm)

                // Suggestion content
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestion.muscleGroup.displayName)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.modusDeepTeal)

                            HStack(spacing: Spacing.sm) {
                                // Intensity badge
                                HStack(spacing: 4) {
                                    intensityIcon(for: suggestion.intensity)
                                        .accessibilityHidden(true)
                                    Text(suggestion.intensity.displayName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(intensityColor(for: suggestion.intensity))

                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                // Time
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.caption)
                                        .accessibilityHidden(true)
                                    Text(suggestion.suggestedTime.formatted)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.modusDeepTeal)
                            }
                        }

                        Spacer()

                        // Readiness indicator
                        VStack(spacing: 2) {
                            Text("\(Int(suggestion.predictedReadiness))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(readinessColor(for: suggestion.predictedReadiness))

                            Text("Ready")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(readinessColor(for: suggestion.predictedReadiness).opacity(0.1))
                        .cornerRadius(CornerRadius.xs)
                    }

                    // Reason
                    Text(suggestion.reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    // Schedule button
                    Button(action: {
                        HapticFeedback.medium()
                        onSchedule(suggestion)
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
                    .accessibilityLabel("Schedule \(suggestion.muscleGroup.displayName) workout for today")
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
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
        } else if isLoading {
            loadingState
        }
    }

    private var loadingState: some View {
        VStack(spacing: Spacing.sm) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .modusCyan))

            Text("Analyzing optimal training times...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Lifecycle

    init(patientId: UUID, onSchedule: @escaping (SchedulingSuggestion) -> Void, onViewAll: @escaping () -> Void) {
        self.patientId = patientId
        self.onSchedule = onSchedule
        self.onViewAll = onViewAll
    }

    var bodyContent: some View {
        body
            .onAppear {
                loadSuggestion()
            }
    }

    // MARK: - Data Loading

    private func loadSuggestion() {
        isLoading = true

        Task {
            do {
                let suggestion = try await smartSchedulingService.getTodaySuggestion(for: patientId)

                await MainActor.run {
                    todaySuggestion = suggestion
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    // MARK: - Helpers

    private func intensityIcon(for intensity: WorkoutIntensity) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<intensityLevel(for: intensity), id: \.self) { _ in
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
            }
        }
    }

    private func intensityLevel(for intensity: WorkoutIntensity) -> Int {
        switch intensity {
        case .light: return 1
        case .moderate: return 2
        case .high: return 3
        }
    }

    private func intensityColor(for intensity: WorkoutIntensity) -> Color {
        switch intensity {
        case .light: return .modusTealAccent
        case .moderate: return .modusCyan
        case .high: return DesignTokens.statusWarning
        }
    }

    private func readinessColor(for score: Double) -> Color {
        if score >= 80 {
            return .modusTealAccent
        } else if score >= 65 {
            return .modusCyan
        } else {
            return DesignTokens.statusWarning
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SmartSchedulingHomeCard_Previews: PreviewProvider {
    static var previews: some View {
        SmartSchedulingHomeCard(
            patientId: UUID(),
            onSchedule: { _ in },
            onViewAll: {}
        )
        .bodyContent
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
