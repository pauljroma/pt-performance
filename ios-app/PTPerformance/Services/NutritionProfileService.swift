//
//  NutritionProfileService.swift
//  PTPerformance
//
//  Modus Nutrition Module - Service for nutrition profile calculations and data
//  Based on Modus Nutrition Guidelines (Mifflin-St Jeor formula)
//

import Foundation
import Supabase

/// Service for managing nutrition profiles and calculating macro targets
@MainActor
class NutritionProfileService: ObservableObject {

    // MARK: - Singleton

    static let shared = NutritionProfileService()

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let logger = DebugLogger.shared

    // MARK: - Published Properties

    @Published var currentProfile: NutritionProfile?
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Initialization

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
        logger.info("NutritionProfileService", "Initializing NutritionProfileService")
    }

    // MARK: - BMR Calculation

    /// Calculate Basal Metabolic Rate using Mifflin-St Jeor formula
    /// Male: BMR = 10*weight(kg) + 6.25*height(cm) - 5*age + 5
    /// Female: BMR = 10*weight(kg) + 6.25*height(cm) - 5*age - 161
    func calculateBMR(
        weightLbs: Double,
        heightInches: Double,
        age: Int,
        gender: BiologicalGender
    ) -> Double {
        let weightKg = weightLbs / 2.205
        let heightCm = heightInches * 2.54
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(age)

        switch gender {
        case .male:
            return base + 5
        case .female:
            return base - 161
        }
    }

    /// Calculate BMR from a profile
    func calculateBMR(profile: NutritionProfile) -> Double {
        return calculateBMR(
            weightLbs: profile.weightLbs,
            heightInches: profile.heightInches,
            age: profile.age,
            gender: profile.gender
        )
    }

    // MARK: - TDEE Calculation

    /// Calculate Total Daily Energy Expenditure (maintenance calories)
    func calculateTDEE(bmr: Double, activityLevel: ActivityLevel) -> Double {
        return bmr * activityLevel.multiplier
    }

    /// Calculate TDEE from a profile
    func calculateTDEE(profile: NutritionProfile) -> Double {
        let bmr = calculateBMR(profile: profile)
        return calculateTDEE(bmr: bmr, activityLevel: profile.activityLevel)
    }

    // MARK: - Macro Calculation

    /// Calculate macro targets based on profile and athlete type guidelines
    func calculateMacros(profile: NutritionProfile) -> MacroTargets {
        let tdee = calculateTDEE(profile: profile)
        let targetCalories = Int(round(tdee * profile.goal.calorieMultiplier))

        // Get athlete type specific guidelines
        let athleteGuidelines = getGuidelinesForAthleteType(code: profile.athleteType)

        // Get age modifications
        let ageModification = getAgeModifications(age: profile.age)

        // Calculate protein (g/lb * weight)
        let proteinGPerLb = athleteGuidelines?.avgProteinGPerLb ?? 0.9
        var proteinGrams = Int(round(profile.weightLbs * proteinGPerLb))

        // Apply age adjustment if available (higher protein for older adults)
        if let ageMod = ageModification {
            if ageMod.ageGroup.contains("Masters") || ageMod.ageGroup.contains("60") || ageMod.ageGroup.contains("70") {
                // Increase protein for older adults
                proteinGrams = Int(Double(proteinGrams) * 1.1)
            }
        }

        // Calculate fat (percentage of total calories)
        let fatPercent = parseFatPercent(athleteGuidelines?.fatPercent ?? "25%")
        let fatCalories = Double(targetCalories) * (fatPercent / 100)
        let fatGrams = Int(round(fatCalories / 9))

        // Calculate carbs (remaining calories)
        let proteinCalories = proteinGrams * 4
        let carbCalories = targetCalories - proteinCalories - Int(fatCalories)
        let carbGrams = max(0, carbCalories / 4)

        return MacroTargets(
            calories: targetCalories,
            proteinGrams: proteinGrams,
            carbsGrams: carbGrams,
            fatGrams: fatGrams
        )
    }

    /// Parse fat percentage from string like "25%" or "25-30%"
    private func parseFatPercent(_ fatString: String) -> Double {
        // Remove % and take first number if range
        let cleaned = fatString
            .replacingOccurrences(of: "%", with: "")
            .components(separatedBy: "-")
            .first ?? "25"
        return Double(cleaned) ?? 25
    }

    // MARK: - Guidelines Lookup

    /// Get athlete type nutrition guidelines by pack code
    func getGuidelinesForAthleteType(code: String) -> AthleteTypeNutrition? {
        return NutritionGuidelinesData.getAthleteTypeNutrition(code: code)
    }

    /// Get all athlete type guidelines
    func getAllAthleteTypeGuidelines() -> [AthleteTypeNutrition] {
        return NutritionGuidelinesData.athleteTypes
    }

    /// Get age-based modifications
    func getAgeModifications(age: Int) -> AgeModification? {
        return NutritionGuidelinesData.getAgeModification(age: age)
    }

    /// Get all age modifications
    func getAllAgeModifications() -> [AgeModification] {
        return NutritionGuidelinesData.ageModifications
    }

    /// Get meal timing guidelines
    func getMealTimingGuidelines() -> [MealTiming] {
        return NutritionGuidelinesData.mealTimings
    }

    /// Get portion guides
    func getPortionGuides() -> [PortionGuide] {
        return NutritionGuidelinesData.portionGuides
    }

    /// Get meal template for gender and goal
    func getMealTemplate(gender: BiologicalGender, goal: NutritionGoalType) -> MealTemplate? {
        let genderString = gender == .male ? "Male" : "Female"
        let goalString: String
        switch goal {
        case .maintain:
            goalString = "Maintenance"
        case .fatLoss:
            goalString = "Fat Loss"
        case .muscleGain:
            goalString = "Muscle Gain"
        case .performance:
            goalString = "Maintenance" // Use maintenance template for performance
        }
        return NutritionGuidelinesData.getMealTemplate(gender: genderString, goal: goalString)
    }

    /// Get food lists by category
    func getFoodLists() -> [FoodList] {
        return NutritionGuidelinesData.foodLists
    }

    /// Get base nutrition principles
    func getBasePrinciples() -> [NutritionPrinciple] {
        return NutritionGuidelinesData.basePrinciples
    }

    // MARK: - Hydration Calculation

    /// Calculate daily hydration target in ounces
    func calculateHydrationOz(weightLbs: Double, athleteType: String) -> Int {
        // Baseline: 0.5-1 oz per lb (use 0.75 as middle ground)
        var baseOz = weightLbs * 0.75

        // Apply athlete type modifier
        if let guidelines = getGuidelinesForAthleteType(code: athleteType) {
            let modifier = parseHydrationModifier(guidelines.hydrationModifier)
            baseOz *= (1.0 + modifier / 100.0)
        }

        return Int(round(baseOz))
    }

    /// Parse hydration modifier from string like "+20%" or "Critical"
    private func parseHydrationModifier(_ hydrationString: String) -> Double {
        if hydrationString.contains("Critical") {
            return 30 // Treat critical as +30%
        }
        if hydrationString.contains("Standard") {
            return 0
        }
        // Parse percentage like "+20%" or "+50%"
        let cleaned = hydrationString
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "%", with: "")
        return Double(cleaned) ?? 0
    }

    // MARK: - Profile CRUD Operations

    /// Fetch nutrition profile for current user
    func fetchProfile() async throws -> NutritionProfile? {
        // Use auth user ID directly from Supabase session, not the patient record ID
        guard let authUserId = supabase.client.auth.currentUser?.id else {
            logger.warning("NutritionProfileService", "No user logged in - cannot fetch profile")
            return nil
        }
        let userId = authUserId.uuidString

        #if DEBUG
        logger.diagnostic("NutritionProfileService: Fetching profile for auth user: \(userId)")
        #endif
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let profiles: [NutritionProfile] = try await supabase.client
                .from("nutrition_profiles")
                .select()
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value

            let profile = profiles.first
            await MainActor.run {
                self.currentProfile = profile
            }

            logger.success("NutritionProfileService", "Fetched profile: \(profile != nil ? "found" : "not found")")
            return profile
        } catch {
            let errorMessage = "Failed to fetch nutrition profile: \(error.localizedDescription)"
            logger.error("NutritionProfileService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    /// Create a new nutrition profile
    func createProfile(_ dto: CreateNutritionProfileDTO) async throws -> NutritionProfile {
        logger.diagnostic("NutritionProfileService: Creating nutrition profile")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let result: NutritionProfile = try await supabase.client
                .from("nutrition_profiles")
                .insert(dto)
                .select()
                .single()
                .execute()
                .value

            await MainActor.run {
                self.currentProfile = result
            }

            logger.success("NutritionProfileService", "Created nutrition profile: \(result.id)")
            return result
        } catch {
            let errorMessage = "Failed to create nutrition profile: \(error.localizedDescription)"
            logger.error("NutritionProfileService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    /// Update an existing nutrition profile
    func updateProfile(id: UUID, updates: UpdateNutritionProfileDTO) async throws -> NutritionProfile {
        logger.diagnostic("NutritionProfileService: Updating nutrition profile: \(id)")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let result: NutritionProfile = try await supabase.client
                .from("nutrition_profiles")
                .update(updates)
                .eq("id", value: id.uuidString)
                .select()
                .single()
                .execute()
                .value

            await MainActor.run {
                self.currentProfile = result
            }

            logger.success("NutritionProfileService", "Updated nutrition profile: \(result.id)")
            return result
        } catch {
            let errorMessage = "Failed to update nutrition profile: \(error.localizedDescription)"
            logger.error("NutritionProfileService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    /// Create or update profile (upsert)
    func saveProfile(
        athleteType: String,
        age: Int,
        weightLbs: Double,
        heightInches: Double,
        gender: BiologicalGender,
        activityLevel: ActivityLevel,
        goal: NutritionGoalType
    ) async throws -> NutritionProfile {
        // Use auth user ID directly from Supabase session, not the patient record ID
        guard let userId = supabase.client.auth.currentUser?.id else {
            throw NSError(domain: "NutritionProfileService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])
        }

        // Check if profile exists
        var existingProfile = currentProfile
        if existingProfile == nil {
            existingProfile = try await fetchProfile()
        }
        if let profile = existingProfile {
            // Update existing
            let updates = UpdateNutritionProfileDTO(
                athleteType: athleteType,
                age: age,
                weightLbs: weightLbs,
                heightInches: heightInches,
                gender: gender.rawValue,
                activityLevel: activityLevel.rawValue,
                goal: goal.rawValue
            )
            return try await updateProfile(id: profile.id, updates: updates)
        } else {
            // Create new
            let dto = CreateNutritionProfileDTO(
                userId: userId,
                athleteType: athleteType,
                age: age,
                weightLbs: weightLbs,
                heightInches: heightInches,
                gender: gender.rawValue,
                activityLevel: activityLevel.rawValue,
                goal: goal.rawValue
            )
            return try await createProfile(dto)
        }
    }

    /// Delete nutrition profile
    func deleteProfile(id: UUID) async throws {
        logger.diagnostic("NutritionProfileService: Deleting nutrition profile: \(id)")
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            _ = try await supabase.client
                .from("nutrition_profiles")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()

            await MainActor.run {
                if self.currentProfile?.id == id {
                    self.currentProfile = nil
                }
            }

            logger.success("NutritionProfileService", "Deleted nutrition profile: \(id)")
        } catch {
            let errorMessage = "Failed to delete nutrition profile: \(error.localizedDescription)"
            logger.error("NutritionProfileService", errorMessage)
            self.error = errorMessage
            throw error
        }
    }

    // MARK: - Athlete Type Detection

    /// Detect athlete type from user's pack subscriptions
    func detectAthleteTypeFromSubscriptions() async -> String {
        let packService = PremiumPackService.shared

        // Check for specific pack subscriptions
        let subscribedCodes = packService.getSubscribedPackCodes()

        // Priority order for athlete type detection
        if subscribedCodes.contains("BASEBALL") {
            return "BASEBALL"
        }
        if subscribedCodes.contains("RUNNING") {
            return "RUNNING"
        }
        if subscribedCodes.contains("CROSSFIT") {
            return "CROSSFIT"
        }
        if subscribedCodes.contains("SWIMMING") {
            return "SWIMMING"
        }
        if subscribedCodes.contains("BASKETBALL") {
            return "BASKETBALL"
        }
        if subscribedCodes.contains("SOCCER") {
            return "SOCCER"
        }
        if subscribedCodes.contains("TENNIS") {
            return "TENNIS"
        }
        if subscribedCodes.contains("GOLF") {
            return "GOLF"
        }
        if subscribedCodes.contains("PICKLEBALL") {
            return "PICKLEBALL"
        }
        if subscribedCodes.contains("TACTICAL") {
            return "TACTICAL"
        }
        if subscribedCodes.contains("REHAB") {
            return "REHAB"
        }
        if subscribedCodes.contains("PRENATAL") {
            return "PRENATAL"
        }
        if subscribedCodes.contains("POSTPARTUM") {
            return "POSTPARTUM"
        }

        // Default to BASE
        return "BASE"
    }

    // MARK: - Clear Data

    /// Clear cached profile data
    func clearCache() {
        currentProfile = nil
        error = nil
    }
}
