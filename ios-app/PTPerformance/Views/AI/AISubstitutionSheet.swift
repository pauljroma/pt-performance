//
//  AISubstitutionSheet.swift
//  PTPerformance
//
//  Build 77 - AI Helper MVP
//

import SwiftUI

struct AISubstitutionSheet: View {
    let sessionExerciseId: UUID  // The session_exercise row to substitute
    let exerciseTemplateId: UUID // The current exercise template
    let exerciseName: String
    let patientId: UUID
    let sessionId: UUID
    var onSubstitutionApplied: (() -> Void)? = nil  // Callback to refresh session
    @State private var reason = ""
    @State private var isApplying = false
    @StateObject private var substitutionService = ExerciseSubstitutionService()
    @Environment(\.dismiss) var dismiss

    // Filter to show only substitution for THIS exercise
    private var relevantSubstitution: ExerciseSubstitution? {
        substitutionService.substitutions.first { sub in
            sub.originalExerciseId == exerciseTemplateId
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Find Alternative for:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(exerciseName)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                // Reason Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why do you need a substitute?")
                        .font(.headline)

                    VStack(spacing: 12) {
                        ReasonButton(icon: "figure.run", text: "Injury/Pain", reason: $reason, value: "Injury or pain prevents this exercise")
                        ReasonButton(icon: "dumbbell", text: "No Equipment", reason: $reason, value: "Equipment not available")
                        ReasonButton(icon: "hand.raised", text: "Too Difficult", reason: $reason, value: "Exercise too challenging currently")
                    }
                }
                .padding()

                // BUILD 185: Show only the substitution for THIS specific exercise
                if let substitution = relevantSubstitution {
                    // Show the specific substitution
                    VStack(alignment: .leading, spacing: 12) {
                        // Original exercise being replaced
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.orange)
                            Text("Replacing: \(exerciseName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        // The substitution card
                        SubstitutionCard(substitution: substitution)
                            .padding(.horizontal)

                        // Use This button
                        Button {
                            Task {
                                await applyAllSubstitutions()
                            }
                        } label: {
                            HStack {
                                if isApplying {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Use \(substitution.exerciseName)")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(CornerRadius.md)
                        }
                        .disabled(isApplying)
                        .padding(.horizontal)
                    }
                } else if !substitutionService.substitutions.isEmpty {
                    // Edge function returned results but none match this exercise
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        Text("No substitution needed!")
                            .font(.headline)
                        Text("\(exerciseName) can be performed as-is.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }

                // Error Display
                if let error = substitutionService.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }

                // Success message when no substitutions needed
                if !substitutionService.isLoading &&
                   substitutionService.substitutions.isEmpty &&
                   substitutionService.error == nil &&
                   !reason.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        Text("All exercises can be performed!")
                            .font(.headline)
                        Text("No substitutions needed with your available equipment.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }

                Spacer()

                // Get Suggestions Button
                if substitutionService.substitutions.isEmpty && !reason.isEmpty {
                    Button {
                        Task {
                            await getSuggestions()
                        }
                    } label: {
                        HStack {
                            if substitutionService.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                                Text("Get AI Suggestions")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(CornerRadius.md)
                    }
                    .disabled(substitutionService.isLoading)
                    .padding()
                }
            }
            .navigationTitle("AI Exercise Swap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func getSuggestions() async {
        do {
            // Map reason to equipment_available and intensity_preference
            let equipmentAvailable: [String]
            let intensityPreference: String

            if reason.contains("Equipment not available") {
                // User has no equipment - pass empty array
                equipmentAvailable = []
                intensityPreference = "standard"
            } else if reason.contains("Injury or pain") {
                // NOTE: Using general substitution with recovery intensity for injury/pain cases
                // — a dedicated injury/pain edge function enhancement is pending
                equipmentAvailable = []
                intensityPreference = "recovery"
            } else {
                // Too difficult - use recovery mode
                equipmentAvailable = []
                intensityPreference = "recovery"
            }

            _ = try await substitutionService.getSubstitutions(
                patientId: patientId,
                sessionId: sessionId,
                scheduledDate: ISO8601DateFormatter().string(from: Date()),
                equipmentAvailable: equipmentAvailable,
                intensityPreference: intensityPreference
            )
        } catch {
            // Error is already set in service
        }
    }

    private func applyAllSubstitutions() async {
        isApplying = true
        defer { isApplying = false }

        do {
            try await substitutionService.applySubstitution()

            // Notify parent to refresh and dismiss
            await MainActor.run {
                onSubstitutionApplied?()
                dismiss()
            }
        } catch {
            substitutionService.error = "Failed to apply: \(error.localizedDescription)"
        }
    }
}

struct ReasonButton: View {
    let icon: String
    let text: String
    @Binding var reason: String
    let value: String

    var body: some View {
        Button {
            reason = value
        } label: {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(text)
                Spacer()
                if reason == value {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(reason == value ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(reason == value ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SubstitutionCard: View {
    let substitution: ExerciseSubstitution
    @State private var showingDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Substitution header with arrow
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Replace with:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(substitution.exerciseName)
                        .font(.headline)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("\(substitution.confidence)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(substitution.rationale)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Equipment and Muscles row
            HStack(spacing: 12) {
                if let equipment = substitution.equipment, !equipment.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "dumbbell")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(equipment.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.raised.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("No equipment needed")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                if let muscles = substitution.musclesTargeted, !muscles.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Text(muscles.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.purple)
                            .lineLimit(1)
                    }
                }
            }

            // Difficulty level
            if let difficulty = substitution.difficultyLevel {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(difficulty)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            // View Details button
            Button {
                showingDetail = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                    Text("View Details")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(CornerRadius.sm)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.md)
        .sheet(isPresented: $showingDetail) {
            ExerciseDetailSheet(substitution: substitution)
        }
    }
}
