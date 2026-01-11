//
//  AISubstitutionSheet.swift
//  PTPerformance
//
//  Build 77 - AI Helper MVP
//

import SwiftUI

struct AISubstitutionSheet: View {
    let exerciseId: UUID
    let exerciseName: String
    let patientId: UUID
    @State private var reason = ""
    @StateObject private var substitutionService = ExerciseSubstitutionService()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
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

                if !substitutionService.substitutions.isEmpty {
                    // Results
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(substitutionService.substitutions) { substitution in
                                SubstitutionCard(substitution: substitution)
                            }
                        }
                        .padding()
                    }
                }

                // Error Display
                if let error = substitutionService.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
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
                        .cornerRadius(12)
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
            _ = try await substitutionService.getSubstitutions(
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                reason: reason,
                patientId: patientId
            )
        } catch {
            // Error is already set in service
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
            .cornerRadius(12)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(substitution.exerciseName)
                    .font(.headline)
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

            if let equipment = substitution.equipment, !equipment.isEmpty {
                HStack {
                    Image(systemName: "dumbbell")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(equipment.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            if let muscles = substitution.musclesTargeted, !muscles.isEmpty {
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(muscles.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Button("Use This Exercise") {
                // TODO: Wire up apply-substitution
                // This would call substitutionService.applySubstitution()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
