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
    let sessionId: UUID
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

                // BUILD 175 DEBUG: Show substitution count always
                VStack(alignment: .leading, spacing: 4) {
                    Text("DEBUG: substitutions.count = \(substitutionService.substitutions.count)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("DEBUG: isLoading = \(substitutionService.isLoading ? "true" : "false")")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("DEBUG: error = \(substitutionService.error ?? "nil")")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal)

                if !substitutionService.substitutions.isEmpty {
                    // Results
                    Text("Showing \(substitutionService.substitutions.count) results:")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(substitutionService.substitutions) { substitution in
                                SubstitutionCard(substitution: substitution)
                            }
                        }
                        .padding()
                    }
                    .frame(minHeight: 200) // Ensure ScrollView has minimum height
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
            .onAppear {
                print("BUILD 176 DEBUG: AISubstitutionSheet appeared")
                print("BUILD 176 DEBUG: exerciseId = \(exerciseId)")
                print("BUILD 176 DEBUG: patientId = \(patientId)")
                print("BUILD 176 DEBUG: sessionId = \(sessionId)")
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
                // Recovery mode - but equipment function won't help with pain-based substitutions
                // TODO: Need different edge function for injury/pain substitutions
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
    @State private var showingDetail = false

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
                }

                if let muscles = substitution.musclesTargeted, !muscles.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(muscles.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.green)
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

            // Action buttons
            HStack(spacing: 12) {
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
                    .cornerRadius(8)
                }

                Button {
                    // TODO: Wire up apply-substitution
                    // This would call substitutionService.applySubstitution()
                } label: {
                    Text("Use This")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingDetail) {
            ExerciseDetailSheet(substitution: substitution)
        }
    }
}
