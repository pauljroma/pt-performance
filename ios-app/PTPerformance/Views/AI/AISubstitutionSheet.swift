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
    @State private var reason = ""
    @State private var isLoading = false
    @State private var substitutions: [[String: Any]] = []
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

                if !substitutions.isEmpty {
                    // Results
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(substitutions.indices, id: \.self) { index in
                                SubstitutionCard(substitution: substitutions[index])
                            }
                        }
                        .padding()
                    }
                }

                Spacer()

                // Get Suggestions Button
                if substitutions.isEmpty && !reason.isEmpty {
                    Button {
                        getSuggestions()
                    } label: {
                        HStack {
                            if isLoading {
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
                    .disabled(isLoading)
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

    private func getSuggestions() {
        isLoading = true
        // This would call the ai-exercise-substitution Edge Function
        // For now, placeholder
        isLoading = false
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
    let substitution: [String: Any]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(substitution["exercise_name"] as? String ?? "Unknown")
                    .font(.headline)
                Spacer()
                Text("\(substitution["confidence"] as? Int ?? 0)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(substitution["rationale"] as? String ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Use This Exercise") {
                // Accept substitution
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
