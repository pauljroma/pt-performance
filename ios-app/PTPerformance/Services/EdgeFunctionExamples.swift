//
//  EdgeFunctionExamples.swift
//  PTPerformance
//
//  BUILD 138 - Edge Functions Integration Examples
//  Created: 2026-01-04
//
//  This file contains Swift examples for calling all 5 Edge Functions deployed in BUILD 138.
//  Use these as reference implementations in your ViewModels and Services.
//

import Foundation
import Supabase

// MARK: - Example 1: Equipment Substitution Service

/// Service for generating and applying exercise substitutions when equipment is unavailable
class EquipmentSubstitutionService {
    let supabase: SupabaseClient

    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    /// Generate AI-powered equipment substitution recommendation
    /// - Parameters:
    ///   - patientId: UUID of the patient
    ///   - sessionId: UUID of the session template
    ///   - scheduledDate: Date when session is scheduled
    ///   - availableEquipment: Array of available equipment (e.g., ["dumbbells", "resistance_bands"])
    ///   - intensityPreference: Desired intensity level
    ///   - readinessScore: Optional readiness score (0-100)
    ///   - whoopRecoveryScore: Optional WHOOP recovery score (0-100)
    /// - Returns: Substitution recommendation with exercises and intensity adjustments
    func generateSubstitution(
        patientId: UUID,
        sessionId: UUID,
        scheduledDate: Date,
        availableEquipment: [String],
        intensityPreference: IntensityPreference = .standard,
        readinessScore: Int? = nil,
        whoopRecoveryScore: Int? = nil
    ) async throws -> SubstitutionRecommendation {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var request: [String: Any] = [
            "patient_id": patientId.uuidString,
            "session_id": sessionId.uuidString,
            "scheduled_date": dateFormatter.string(from: scheduledDate),
            "equipment_available": availableEquipment,
            "intensity_preference": intensityPreference.rawValue
        ]

        if let readiness = readinessScore {
            request["readiness_score"] = readiness
        }

        if let whoopScore = whoopRecoveryScore {
            request["whoop_recovery_score"] = whoopScore
        }

        let response: SubstitutionResponse = try await supabase.functions
            .invoke("generate-equipment-substitution", options: FunctionInvokeOptions(
                body: request
            ))

        guard response.success else {
            throw EdgeFunctionError.requestFailed(response.error ?? "Unknown error")
        }

        return SubstitutionRecommendation(
            recommendationId: response.recommendationId,
            patch: response.patch,
            rationale: response.rationale,
            tokensUsed: response.tokensUsed,
            exercisesSubstituted: response.exercisesSubstituted
        )
    }

    /// Apply an approved substitution recommendation
    /// - Parameter recommendationId: UUID of the recommendation to apply
    /// - Returns: Session instance ID and applied timestamp
    func applySubstitution(recommendationId: UUID) async throws -> AppliedSubstitution {
        let request = ["recommendation_id": recommendationId.uuidString]

        let response: ApplySubstitutionResponse = try await supabase.functions
            .invoke("apply-substitution", options: FunctionInvokeOptions(
                body: request
            ))

        guard response.success else {
            throw EdgeFunctionError.requestFailed(response.error ?? "Unknown error")
        }

        return response.data
    }
}

// MARK: - Example 2: WHOOP Recovery Service

/// Service for syncing WHOOP recovery data
class WHOOPRecoveryService {
    let supabase: SupabaseClient

    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    /// Sync WHOOP recovery data for a patient
    /// - Parameter patientId: UUID of the patient
    /// - Returns: WHOOP recovery data (or mock data if WHOOP not connected)
    /// - Note: Results are cached for 1 hour to avoid excessive API calls
    func syncRecovery(for patientId: UUID) async throws -> WHOOPRecoveryData {
        let request = ["patient_id": patientId.uuidString]

        let response: WHOOPSyncResponse = try await supabase.functions
            .invoke("sync-whoop-recovery", options: FunctionInvokeOptions(
                body: request
            ))

        guard response.success else {
            throw EdgeFunctionError.requestFailed(response.error ?? "Unknown error")
        }

        // Check if using cached data
        if response.cached == true {
            print("ℹ️ Using cached WHOOP data (synced \(response.nextSyncAvailableInMinutes ?? 0) minutes ago)")
        }

        // Check if using mock data (WHOOP not connected)
        if response.mock == true {
            print("⚠️ Using mock WHOOP data. Patient needs to connect WHOOP account.")
        }

        return WHOOPRecoveryData(
            recoveryScore: response.data.recoveryScore,
            sleepPerformancePercentage: response.data.sleepPerformancePercentage,
            hrvRmssd: response.data.hrvRmssd,
            strain: response.data.strain,
            syncedAt: response.data.syncedAt,
            isCached: response.cached ?? false,
            isMock: response.mock ?? false
        )
    }

    /// Connect WHOOP account via OAuth
    /// - Parameters:
    ///   - patientId: UUID of the patient
    ///   - presentationContext: View controller to present Safari view
    func connectWHOOPAccount(for patientId: UUID, from presentationContext: UIViewController) {
        // Build OAuth URL
        let clientId = "your-whoop-client-id" // Get from environment
        let redirectUri = "ptperformance://whoop/callback"
        let state = patientId.uuidString // Pass patient ID as state for callback

        let authURL = URL(string: "https://api.prod.whoop.com/oauth/oauth2/auth?" +
                          "client_id=\\(clientId)&" +
                          "redirect_uri=\\(redirectUri)&" +
                          "response_type=code&" +
                          "scope=read:recovery,read:sleep&" +
                          "state=\\(state)")!

        // Present Safari view controller for OAuth
        let safariVC = SFSafariViewController(url: authURL)
        presentationContext.present(safariVC, animated: true)
    }
}

// MARK: - Example 3: Nutrition Recommendation Service

/// Service for AI-powered nutrition recommendations
class NutritionRecommendationService {
    let supabase: SupabaseClient

    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    /// Get personalized nutrition recommendation
    /// - Parameters:
    ///   - patientId: UUID of the patient
    ///   - timeOfDay: Current time (e.g., "2:00 PM")
    ///   - availableFoods: Optional list of available foods
    ///   - nextWorkout: Optional upcoming workout details
    /// - Returns: Meal recommendation with macros and timing
    /// - Note: Results are cached for 30 minutes
    func getRecommendation(
        for patientId: UUID,
        timeOfDay: String,
        availableFoods: [String]? = nil,
        nextWorkout: (time: String, type: String)? = nil
    ) async throws -> NutritionRecommendation {

        var request: [String: Any] = [
            "patient_id": patientId.uuidString,
            "time_of_day": timeOfDay
        ]

        if let foods = availableFoods {
            request["available_foods"] = foods
        }

        if let workout = nextWorkout {
            request["context"] = [
                "next_workout_time": workout.time,
                "workout_type": workout.type
            ]
        }

        let response: NutritionRecommendationResponse = try await supabase.functions
            .invoke("ai-nutrition-recommendation", options: FunctionInvokeOptions(
                body: request
            ))

        if response.cached == true {
            print("ℹ️ Using cached nutrition recommendation")
        }

        return NutritionRecommendation(
            recommendationId: response.recommendationId,
            recommendationText: response.recommendationText,
            targetMacros: response.targetMacros,
            reasoning: response.reasoning,
            suggestedTiming: response.suggestedTiming,
            isCached: response.cached ?? false
        )
    }
}

// MARK: - Example 4: Meal Parsing Service

/// Service for parsing meal descriptions into structured macro data
class MealParsingService {
    let supabase: SupabaseClient

    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    /// Parse meal description (text-only)
    /// - Parameter description: Natural language meal description (e.g., "chicken and rice")
    /// - Returns: Parsed meal with foods, macros, and confidence level
    func parseMeal(description: String) async throws -> ParsedMeal {
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw EdgeFunctionError.invalidInput("Meal description cannot be empty")
        }

        let request = ["description": description]

        let response: MealParserResponse = try await supabase.functions
            .invoke("ai-meal-parser", options: FunctionInvokeOptions(
                body: request
            ))

        guard response.success else {
            throw EdgeFunctionError.requestFailed(response.error ?? "Unknown error")
        }

        return response.parsedMeal
    }

    /// Parse meal description with photo
    /// - Parameters:
    ///   - description: Natural language meal description
    ///   - image: UIImage of the meal
    /// - Returns: Parsed meal with foods, macros, and confidence level
    /// - Note: Photo parsing costs 100x more than text-only, but provides better accuracy
    func parseMeal(description: String, image: UIImage) async throws -> ParsedMeal {
        // 1. Upload image to Supabase Storage
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw EdgeFunctionError.invalidInput("Failed to convert image to JPEG")
        }

        let fileName = "meal_\\(UUID().uuidString).jpg"

        let uploadedFile = try await supabase.storage
            .from("meal-photos")
            .upload(path: fileName, file: imageData, options: FileOptions(
                contentType: "image/jpeg"
            ))

        // 2. Get public URL
        let publicURL = try supabase.storage
            .from("meal-photos")
            .getPublicURL(path: fileName)

        // 3. Call parser with image URL
        let request: [String: Any] = [
            "description": description,
            "image_url": publicURL
        ]

        let response: MealParserResponse = try await supabase.functions
            .invoke("ai-meal-parser", options: FunctionInvokeOptions(
                body: request
            ))

        guard response.success else {
            throw EdgeFunctionError.requestFailed(response.error ?? "Unknown error")
        }

        return response.parsedMeal
    }

    /// Save parsed meal to database
    /// - Parameters:
    ///   - patientId: UUID of the patient
    ///   - parsedMeal: Meal data from parser
    ///   - mealTime: Time meal was eaten
    /// - Returns: Saved meal record ID
    func saveMeal(
        patientId: UUID,
        parsedMeal: ParsedMeal,
        mealTime: Date
    ) async throws -> UUID {

        let mealRecord: [String: Any] = [
            "patient_id": patientId.uuidString,
            "meal_type": parsedMeal.mealType,
            "meal_time": ISO8601DateFormatter().string(from: mealTime),
            "foods": parsedMeal.foods,
            "calories": parsedMeal.calories,
            "protein": parsedMeal.protein,
            "carbs": parsedMeal.carbs,
            "fats": parsedMeal.fats,
            "parsed_meal": [
                "ai_confidence": parsedMeal.aiConfidence,
                "meal_type": parsedMeal.mealType,
                "foods": parsedMeal.foods,
                "calories": parsedMeal.calories,
                "protein": parsedMeal.protein,
                "carbs": parsedMeal.carbs,
                "fats": parsedMeal.fats
            ]
        ]

        let response = try await supabase
            .from("daily_meals")
            .insert(mealRecord)
            .select("id")
            .single()
            .execute()

        guard let idString = response.value["id"] as? String,
              let mealId = UUID(uuidString: idString) else {
            throw EdgeFunctionError.requestFailed("Failed to get meal ID from response")
        }

        return mealId
    }
}

// MARK: - Data Models

struct SubstitutionRecommendation {
    let recommendationId: String
    let patch: SubstitutionPatch
    let rationale: String
    let tokensUsed: Int?
    let exercisesSubstituted: Int?
}

struct SubstitutionPatch: Codable {
    let exerciseSubstitutions: [ExerciseSubstitution]
    let intensityAdjustments: [IntensityAdjustment]

    enum CodingKeys: String, CodingKey {
        case exerciseSubstitutions = "exercise_substitutions"
        case intensityAdjustments = "intensity_adjustments"
    }
}

struct ExerciseSubstitution: Codable {
    let originalExerciseId: String
    let originalExerciseName: String
    let substituteExerciseId: String
    let substituteExerciseName: String
    let reason: String

    enum CodingKeys: String, CodingKey {
        case originalExerciseId = "original_exercise_id"
        case originalExerciseName = "original_exercise_name"
        case substituteExerciseId = "substitute_exercise_id"
        case substituteExerciseName = "substitute_exercise_name"
        case reason
    }
}

struct IntensityAdjustment: Codable {
    let exerciseId: String
    let exerciseName: String
    let originalSets: Int
    let adjustedSets: Int
    let originalReps: Int
    let adjustedReps: Int
    let originalRpe: Int?
    let adjustedRpe: Int?
    let reason: String

    enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case exerciseName = "exercise_name"
        case originalSets = "original_sets"
        case adjustedSets = "adjusted_sets"
        case originalReps = "original_reps"
        case adjustedReps = "adjusted_reps"
        case originalRpe = "original_rpe"
        case adjustedRpe = "adjusted_rpe"
        case reason
    }
}

struct AppliedSubstitution: Codable {
    let sessionInstanceId: String
    let recommendationId: String
    let appliedAt: String

    enum CodingKeys: String, CodingKey {
        case sessionInstanceId = "session_instance_id"
        case recommendationId = "recommendation_id"
        case appliedAt = "applied_at"
    }
}

struct WHOOPRecoveryData {
    let recoveryScore: Double
    let sleepPerformancePercentage: Double
    let hrvRmssd: Double
    let strain: Double
    let syncedAt: String
    let isCached: Bool
    let isMock: Bool

    /// Get recovery level category
    var recoveryLevel: RecoveryLevel {
        switch recoveryScore {
        case 0..<33:
            return .poor
        case 33..<66:
            return .moderate
        case 66...100:
            return .good
        default:
            return .unknown
        }
    }

    enum RecoveryLevel {
        case poor, moderate, good, unknown

        var description: String {
            switch self {
            case .poor: return "Poor Recovery"
            case .moderate: return "Moderate Recovery"
            case .good: return "Good Recovery"
            case .unknown: return "Unknown"
            }
        }

        var color: Color {
            switch self {
            case .poor: return .red
            case .moderate: return .yellow
            case .good: return .green
            case .unknown: return .gray
            }
        }
    }
}

struct NutritionRecommendation {
    let recommendationId: String
    let recommendationText: String
    let targetMacros: Macros
    let reasoning: String
    let suggestedTiming: String
    let isCached: Bool
}

struct Macros: Codable {
    let protein: Double
    let carbs: Double
    let fats: Double
    let calories: Int
}

struct ParsedMeal: Codable {
    let mealType: String
    let foods: [String]
    let calories: Int
    let protein: Double
    let carbs: Double
    let fats: Double
    let aiConfidence: String

    enum CodingKeys: String, CodingKey {
        case mealType = "meal_type"
        case foods, calories, protein, carbs, fats
        case aiConfidence = "ai_confidence"
    }

    var confidenceLevel: ConfidenceLevel {
        switch aiConfidence.lowercased() {
        case "high": return .high
        case "medium": return .medium
        case "low": return .low
        default: return .unknown
        }
    }

    enum ConfidenceLevel {
        case high, medium, low, unknown

        var color: Color {
            switch self {
            case .high: return .green
            case .medium: return .yellow
            case .low: return .red
            case .unknown: return .gray
            }
        }

        var description: String {
            switch self {
            case .high: return "High Confidence"
            case .medium: return "Medium Confidence"
            case .low: return "Low Confidence - Review Recommended"
            case .unknown: return "Unknown"
            }
        }
    }
}

enum IntensityPreference: String, Codable {
    case recovery = "recovery"
    case standard = "standard"
    case goHard = "go_hard"
}

enum EdgeFunctionError: LocalizedError {
    case requestFailed(String)
    case invalidInput(String)
    case networkError
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .requestFailed(let message):
            return "Request failed: \\(message)"
        case .invalidInput(let message):
            return "Invalid input: \\(message)"
        case .networkError:
            return "Network error occurred. Please check your connection."
        case .unauthorized:
            return "Unauthorized. Please log in again."
        }
    }
}

// MARK: - Response Types (Internal)

private struct SubstitutionResponse: Codable {
    let success: Bool
    let recommendationId: String
    let patch: SubstitutionPatch
    let rationale: String
    let tokensUsed: Int?
    let exercisesSubstituted: Int?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case success
        case recommendationId = "recommendation_id"
        case patch, rationale
        case tokensUsed = "tokens_used"
        case exercisesSubstituted = "exercises_substituted"
        case error
    }
}

private struct ApplySubstitutionResponse: Codable {
    let success: Bool
    let data: AppliedSubstitution
    let message: String?
    let error: String?
}

private struct WHOOPSyncResponse: Codable {
    let success: Bool
    let data: WHOOPRecoveryResponseData
    let cached: Bool?
    let mock: Bool?
    let message: String?
    let nextSyncAvailableInMinutes: Int?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case success, data, cached, mock, message, error
        case nextSyncAvailableInMinutes = "next_sync_available_in_minutes"
    }
}

private struct WHOOPRecoveryResponseData: Codable {
    let recoveryScore: Double
    let sleepPerformancePercentage: Double
    let hrvRmssd: Double
    let strain: Double
    let syncedAt: String

    enum CodingKeys: String, CodingKey {
        case recoveryScore = "recovery_score"
        case sleepPerformancePercentage = "sleep_performance_percentage"
        case hrvRmssd = "hrv_rmssd"
        case strain
        case syncedAt = "synced_at"
    }
}

private struct NutritionRecommendationResponse: Codable {
    let recommendationId: String
    let recommendationText: String
    let targetMacros: Macros
    let reasoning: String
    let suggestedTiming: String
    let cached: Bool?

    enum CodingKeys: String, CodingKey {
        case recommendationId = "recommendation_id"
        case recommendationText = "recommendation_text"
        case targetMacros = "target_macros"
        case reasoning
        case suggestedTiming = "suggested_timing"
        case cached
    }
}

private struct MealParserResponse: Codable {
    let success: Bool
    let parsedMeal: ParsedMeal
    let modelUsed: String?
    let tokensUsed: Int?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case success
        case parsedMeal = "parsed_meal"
        case modelUsed = "model_used"
        case tokensUsed = "tokens_used"
        case error
    }
}

// MARK: - Usage Examples in SwiftUI

import SwiftUI
import SafariServices

/// Example: Equipment Substitution Flow
struct EquipmentSubstitutionView: View {
    @State private var substitutionService: EquipmentSubstitutionService
    @State private var recommendation: SubstitutionRecommendation?
    @State private var isLoading = false
    @State private var errorMessage: String?

    let patientId: UUID
    let sessionId: UUID
    let scheduledDate: Date

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView("Analyzing equipment and recovery...")
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    Task { await generateSubstitution() }
                }
            } else if let rec = recommendation {
                SubstitutionRecommendationCard(recommendation: rec) {
                    Task { await applyRecommendation(rec.recommendationId) }
                }
            } else {
                Button("Check Equipment Compatibility") {
                    Task { await generateSubstitution() }
                }
            }
        }
        .padding()
    }

    private func generateSubstitution() async {
        isLoading = true
        errorMessage = nil

        do {
            recommendation = try await substitutionService.generateSubstitution(
                patientId: patientId,
                sessionId: sessionId,
                scheduledDate: scheduledDate,
                availableEquipment: ["dumbbells", "resistance_bands"],
                intensityPreference: .standard,
                readinessScore: 75,
                whoopRecoveryScore: nil
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func applyRecommendation(_ recommendationId: String) async {
        guard let uuid = UUID(uuidString: recommendationId) else { return }

        do {
            _ = try await substitutionService.applySubstitution(recommendationId: uuid)
            // Navigate to updated workout
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// Example: Meal Logging Flow
struct MealLoggingView: View {
    @State private var mealService: MealParsingService
    @State private var mealDescription = ""
    @State private var parsedMeal: ParsedMeal?
    @State private var selectedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 16) {
            TextField("Describe your meal...", text: $mealDescription)
                .textFieldStyle(.roundedBorder)

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(12)
            }

            Button("Add Photo") {
                // Present image picker
            }

            Button("Parse Meal") {
                Task { await parseMeal() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(mealDescription.isEmpty || isLoading)

            if isLoading {
                ProgressView("Analyzing meal...")
            }

            if let meal = parsedMeal {
                ParsedMealCard(meal: meal)
            }
        }
        .padding()
    }

    private func parseMeal() async {
        isLoading = true

        do {
            if let image = selectedImage {
                parsedMeal = try await mealService.parseMeal(description: mealDescription, image: image)
            } else {
                parsedMeal = try await mealService.parseMeal(description: mealDescription)
            }
        } catch {
            print("Error parsing meal: \\(error)")
        }

        isLoading = false
    }
}

// MARK: - Helper Views

struct ParsedMealCard: View {
    let meal: ParsedMeal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(meal.mealType.capitalized)
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(meal.confidenceLevel.color)
                        .frame(width: 8, height: 8)
                    Text(meal.aiConfidence.uppercased())
                        .font(.caption)
                        .foregroundColor(meal.confidenceLevel.color)
                }
            }

            Text("Foods: \\(meal.foods.joined(separator: ", "))")
                .font(.subheadline)

            HStack(spacing: 20) {
                MacroView(name: "Protein", value: meal.protein, unit: "g", color: .blue)
                MacroView(name: "Carbs", value: meal.carbs, unit: "g", color: .orange)
                MacroView(name: "Fats", value: meal.fats, unit: "g", color: .purple)
            }

            Text("\\(meal.calories) calories")
                .font(.title3)
                .fontWeight(.bold)

            if meal.confidenceLevel != .high {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text("AI estimate - tap to edit manually")
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MacroView: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f", value))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Something went wrong")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                retry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct SubstitutionRecommendationCard: View {
    let recommendation: SubstitutionRecommendation
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercise Substitutions")
                .font(.headline)

            ForEach(recommendation.patch.exerciseSubstitutions, id: \\.originalExerciseId) { sub in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(sub.originalExerciseName)
                            .strikethrough()
                        Image(systemName: "arrow.right")
                        Text(sub.substituteExerciseName)
                            .fontWeight(.semibold)
                    }
                    Text(sub.reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            if !recommendation.patch.intensityAdjustments.isEmpty {
                Divider()

                Text("Intensity Adjustments")
                    .font(.headline)

                ForEach(recommendation.patch.intensityAdjustments, id: \\.exerciseId) { adj in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(adj.exerciseName)
                            .font(.subheadline)
                        Text("\\(adj.adjustedSets) sets × \\(adj.adjustedReps) reps @ RPE \\(adj.adjustedRpe ?? 0)")
                            .font(.caption)
                        Text(adj.reason)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            Text(recommendation.rationale)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Apply Substitution") {
                onApply()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}
