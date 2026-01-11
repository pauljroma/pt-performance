//
//  NutritionRecommendationView.swift
//  PTPerformance
//
//  Created by Swarm Agent (Nutrition Integration)
//  AI-powered nutrition recommendations
//

import SwiftUI

struct NutritionRecommendationView: View {
    @State private var patientId: UUID
    @StateObject private var nutritionService = NutritionService()
    @State private var showRecommendation = false

    init(patientId: UUID) {
        self._patientId = State(initialValue: patientId)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Nutrition Coach")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Get personalized nutrition recommendations based on your workout schedule and recovery needs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Get Recommendation Button
                Button(action: {
                    Task {
                        await getRecommendation()
                    }
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Get AI Recommendation")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(nutritionService.isLoading)
                .padding(.horizontal)

                // Loading State
                if nutritionService.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Spacer()
                    }
                    .padding(.vertical, 40)
                }

                // Recommendation Display
                if let recommendation = nutritionService.lastRecommendation {
                    VStack(alignment: .leading, spacing: 16) {
                        // Recommendation Text
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Recommendation", systemImage: "text.bubble")
                                .font(.headline)
                                .foregroundColor(.blue)

                            Text(recommendation.recommendationText)
                                .font(.body)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }

                        // Target Macros
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Target Macros", systemImage: "chart.pie")
                                .font(.headline)
                                .foregroundColor(.green)

                            VStack(spacing: 8) {
                                MacroRow(label: "Calories", value: "\(Int(recommendation.targetMacros.calories))", unit: "kcal", color: .orange)
                                MacroRow(label: "Protein", value: "\(Int(recommendation.targetMacros.protein))", unit: "g", color: .red)
                                MacroRow(label: "Carbs", value: "\(Int(recommendation.targetMacros.carbs))", unit: "g", color: .blue)
                                MacroRow(label: "Fats", value: "\(Int(recommendation.targetMacros.fats))", unit: "g", color: .purple)
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)

                        // Reasoning
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Why This Recommendation?", systemImage: "lightbulb")
                                .font(.headline)
                                .foregroundColor(.orange)

                            Text(recommendation.reasoning)
                                .font(.body)
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                        }

                        // Timing (optional)
                        if let timing = recommendation.suggestedTiming {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Best Timing", systemImage: "clock")
                                    .font(.headline)
                                    .foregroundColor(.purple)

                                Text(timing)
                                    .font(.body)
                                    .padding()
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Error Display
                if let error = nutritionService.error {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Error", systemImage: "exclamationmark.triangle")
                            .font(.headline)
                            .foregroundColor(.red)

                        Text(error)
                            .font(.body)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("Nutrition AI")
    }

    // MARK: - Helper Functions

    private func getRecommendation() async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        let timeOfDay = dateFormatter.string(from: Date())

        do {
            _ = try await nutritionService.getRecommendation(
                patientId: patientId,
                timeOfDay: timeOfDay,
                availableFoods: nil,  // Could be enhanced to let user select foods
                nextWorkoutTime: nil,  // Could be enhanced to check schedule
                workoutType: nil
            )
        } catch {
            // Error is already set in service
        }
    }
}

// MARK: - Supporting Views

struct MacroRow: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(.body)
                .fontWeight(.medium)

            Spacer()

            Text("\(value) \(unit)")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct NutritionRecommendationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NutritionRecommendationView(patientId: UUID())
        }
    }
}
