//
//  NutritionProfile.swift
//  PTPerformance
//
//  Modus Nutrition Module - User nutrition profile model with BMR/TDEE calculations
//  Based on Modus Nutrition Guidelines (Mifflin-St Jeor formula)
//

import Foundation
import SwiftUI

// MARK: - Activity Level

/// Activity level for TDEE calculation
enum ActivityLevel: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case sedentary = "sedentary"
    case light = "light"
    case moderate = "moderate"
    case active = "active"
    case veryActive = "very_active"
    case athlete = "athlete"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .active: return "Active"
        case .veryActive: return "Very Active"
        case .athlete: return "Athlete"
        }
    }

    var description: String {
        switch self {
        case .sedentary: return "Desk job, little exercise"
        case .light: return "1-3 days/week light exercise"
        case .moderate: return "3-5 days/week moderate exercise"
        case .active: return "6-7 days/week hard exercise"
        case .veryActive: return "2x/day training or physical job"
        case .athlete: return "Professional/elite athlete"
        }
    }

    /// TDEE multiplier based on Modus guidelines
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        case .athlete: return 2.0
        }
    }

    var icon: String {
        switch self {
        case .sedentary: return "figure.stand"
        case .light: return "figure.walk"
        case .moderate: return "figure.run"
        case .active: return "figure.highintensity.intervaltraining"
        case .veryActive: return "figure.strengthtraining.traditional"
        case .athlete: return "medal.fill"
        }
    }
}

// MARK: - Nutrition Goal Type

/// Primary nutrition goal
enum NutritionGoalType: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case maintain = "maintain"
    case fatLoss = "fat_loss"
    case muscleGain = "muscle_gain"
    case performance = "performance"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .maintain: return "Maintenance"
        case .fatLoss: return "Fat Loss"
        case .muscleGain: return "Muscle Gain"
        case .performance: return "Performance"
        }
    }

    var description: String {
        switch self {
        case .maintain: return "Maintain current weight"
        case .fatLoss: return "20% caloric deficit"
        case .muscleGain: return "10% caloric surplus"
        case .performance: return "15% surplus for athletes"
        }
    }

    /// Calorie adjustment multiplier
    var calorieMultiplier: Double {
        switch self {
        case .maintain: return 1.0
        case .fatLoss: return 0.8
        case .muscleGain: return 1.1
        case .performance: return 1.15
        }
    }

    var icon: String {
        switch self {
        case .maintain: return "equal.circle.fill"
        case .fatLoss: return "arrow.down.circle.fill"
        case .muscleGain: return "arrow.up.circle.fill"
        case .performance: return "bolt.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .maintain: return .blue
        case .fatLoss: return .orange
        case .muscleGain: return .green
        case .performance: return .purple
        }
    }
}

// MARK: - Gender

/// Biological gender for BMR calculation
enum BiologicalGender: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case male = "male"
    case female = "female"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        }
    }
}

// MARK: - Nutrition Profile

/// User's nutrition profile with BMR/TDEE calculations based on Modus guidelines
struct NutritionProfile: Codable, Identifiable, Hashable, Equatable, Sendable {
    let id: UUID
    let userId: UUID
    var athleteType: String  // Matches pack code (BASE, BASEBALL, etc.)
    var age: Int
    var weightLbs: Double
    var heightInches: Double
    var gender: BiologicalGender
    var activityLevel: ActivityLevel
    var goal: NutritionGoalType
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case athleteType = "athlete_type"
        case age
        case weightLbs = "weight_lbs"
        case heightInches = "height_inches"
        case gender
        case activityLevel = "activity_level"
        case goal
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Weight in kilograms
    var weightKg: Double {
        weightLbs / 2.205
    }

    /// Height in centimeters
    var heightCm: Double {
        heightInches * 2.54
    }

    /// Basal Metabolic Rate using Mifflin-St Jeor formula
    /// Male: BMR = 10*weight(kg) + 6.25*height(cm) - 5*age + 5
    /// Female: BMR = 10*weight(kg) + 6.25*height(cm) - 5*age - 161
    var bmr: Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(age)
        switch gender {
        case .male:
            return base + 5
        case .female:
            return base - 161
        }
    }

    /// Total Daily Energy Expenditure (maintenance calories)
    var tdee: Double {
        bmr * activityLevel.multiplier
    }

    /// Goal-adjusted daily calories
    var targetCalories: Int {
        Int(round(tdee * goal.calorieMultiplier))
    }

    /// Fat loss calories (20% deficit)
    var fatLossCalories: Int {
        Int(round(tdee * 0.8))
    }

    /// Muscle gain calories (10% surplus)
    var muscleGainCalories: Int {
        Int(round(tdee * 1.1))
    }

    /// Performance calories (15% surplus)
    var performanceCalories: Int {
        Int(round(tdee * 1.15))
    }
}

// MARK: - Macro Targets

/// Calculated macro targets based on profile
struct MacroTargets: Codable, Hashable, Equatable, Sendable {
    let calories: Int
    let proteinGrams: Int
    let carbsGrams: Int
    let fatGrams: Int

    /// Protein calories (4 cal/g)
    var proteinCalories: Int {
        proteinGrams * 4
    }

    /// Carb calories (4 cal/g)
    var carbsCalories: Int {
        carbsGrams * 4
    }

    /// Fat calories (9 cal/g)
    var fatCalories: Int {
        fatGrams * 9
    }

    /// Protein percentage of total
    var proteinPercent: Double {
        guard calories > 0 else { return 0 }
        return Double(proteinCalories) / Double(calories) * 100
    }

    /// Carbs percentage of total
    var carbsPercent: Double {
        guard calories > 0 else { return 0 }
        return Double(carbsCalories) / Double(calories) * 100
    }

    /// Fat percentage of total
    var fatPercent: Double {
        guard calories > 0 else { return 0 }
        return Double(fatCalories) / Double(calories) * 100
    }

    /// Protein range string (g/lb based on athlete type)
    func proteinRangeString(weightLbs: Double, minGPerLb: Double, maxGPerLb: Double) -> String {
        let min = Int(weightLbs * minGPerLb)
        let max = Int(weightLbs * maxGPerLb)
        return "\(min) - \(max) g"
    }
}

// MARK: - Create/Update DTOs

struct CreateNutritionProfileDTO: Codable, Sendable {
    let userId: UUID
    let athleteType: String
    let age: Int
    let weightLbs: Double
    let heightInches: Double
    let gender: String
    let activityLevel: String
    let goal: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case athleteType = "athlete_type"
        case age
        case weightLbs = "weight_lbs"
        case heightInches = "height_inches"
        case gender
        case activityLevel = "activity_level"
        case goal
    }
}

struct UpdateNutritionProfileDTO: Codable, Sendable {
    let athleteType: String?
    let age: Int?
    let weightLbs: Double?
    let heightInches: Double?
    let gender: String?
    let activityLevel: String?
    let goal: String?

    enum CodingKeys: String, CodingKey {
        case athleteType = "athlete_type"
        case age
        case weightLbs = "weight_lbs"
        case heightInches = "height_inches"
        case gender
        case activityLevel = "activity_level"
        case goal
    }
}

// MARK: - Preview Support

#if DEBUG
extension NutritionProfile {
    static let preview = NutritionProfile(
        id: UUID(),
        userId: UUID(),
        athleteType: "BASE",
        age: 30,
        weightLbs: 180,
        heightInches: 70,
        gender: .male,
        activityLevel: .moderate,
        goal: .maintain,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let previewFemale = NutritionProfile(
        id: UUID(),
        userId: UUID(),
        athleteType: "RUNNING",
        age: 28,
        weightLbs: 140,
        heightInches: 65,
        gender: .female,
        activityLevel: .active,
        goal: .performance,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let previewBaseball = NutritionProfile(
        id: UUID(),
        userId: UUID(),
        athleteType: "BASEBALL",
        age: 22,
        weightLbs: 195,
        heightInches: 73,
        gender: .male,
        activityLevel: .veryActive,
        goal: .performance,
        createdAt: Date(),
        updatedAt: Date()
    )
}

extension MacroTargets {
    static let preview = MacroTargets(
        calories: 2500,
        proteinGrams: 180,
        carbsGrams: 280,
        fatGrams: 70
    )
}
#endif
