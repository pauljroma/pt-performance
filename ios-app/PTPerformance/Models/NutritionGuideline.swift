//
//  NutritionGuideline.swift
//  PTPerformance
//
//  Modus Nutrition Module - Sport-specific nutrition guidelines
//  Based on Modus Nutrition Guidelines spreadsheet
//

import Foundation
import SwiftUI

// MARK: - Athlete Type Nutrition

/// Sport-specific nutrition guidelines for each athlete type
struct AthleteTypeNutrition: Codable, Identifiable, Hashable, Equatable, Sendable {
    var id: String { athleteType }

    let athleteType: String
    let proteinMinGPerLb: Double
    let proteinMaxGPerLb: Double
    let carbFocus: CarbFocus
    let fatPercent: String
    let hydrationModifier: String
    let keyNutrients: [String]
    let timingNotes: String

    enum CodingKeys: String, CodingKey {
        case athleteType = "athlete_type"
        case proteinMinGPerLb = "protein_min_g_per_lb"
        case proteinMaxGPerLb = "protein_max_g_per_lb"
        case carbFocus = "carb_focus"
        case fatPercent = "fat_percent"
        case hydrationModifier = "hydration_modifier"
        case keyNutrients = "key_nutrients"
        case timingNotes = "timing_notes"
    }

    /// Average protein g/lb recommendation
    var avgProteinGPerLb: Double {
        (proteinMinGPerLb + proteinMaxGPerLb) / 2
    }

    /// Protein range as formatted string
    var proteinRangeString: String {
        "\(String(format: "%.1f", proteinMinGPerLb))-\(String(format: "%.1f", proteinMaxGPerLb)) g/lb"
    }

    /// Display color for athlete type
    var themeColor: Color {
        switch athleteType.uppercased() {
        case "BASE": return .blue
        case "BASEBALL": return .orange
        case "TACTICAL": return .green
        case "GOLF": return .mint
        case "PICKLEBALL": return .yellow
        case "MASTERS": return .purple
        case "RUNNING": return .red
        case "CROSSFIT": return .indigo
        case "SWIMMING": return .cyan
        case "BASKETBALL": return .orange
        case "SOCCER": return .green
        case "TENNIS": return .yellow
        case "REHAB": return .teal
        case "PRENATAL": return .pink
        case "POSTPARTUM": return .pink
        case "YOUTH12", "YOUTH16": return .blue
        case "GOALS-FATLOSS": return .orange
        case "GOALS-MUSCLE": return .green
        case "EXPRESS": return .gray
        default: return .blue
        }
    }
}

/// Carbohydrate focus level
enum CarbFocus: String, Codable, CaseIterable, Hashable, Sendable {
    case low = "Low"
    case lowModerate = "Low-Mod"
    case moderate = "Moderate"
    case moderateHigh = "Moderate-High"
    case high = "High"

    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .low: return "Minimal carbs, focus on protein and fats"
        case .lowModerate: return "Lower carbs with emphasis on timing"
        case .moderate: return "Balanced carb intake throughout day"
        case .moderateHigh: return "Higher carbs around training"
        case .high: return "Prioritize carbs for energy and recovery"
        }
    }
}

// MARK: - Age Modification

/// Age-based nutrition adjustments
struct AgeModification: Codable, Identifiable, Hashable, Equatable, Sendable {
    var id: String { ageGroup }

    let ageGroup: String
    let minAge: Int
    let maxAge: Int
    let calorieAdjustment: String
    let proteinAdjustment: String
    let keyConsiderations: [String]
    let priorityNutrients: [String]

    enum CodingKeys: String, CodingKey {
        case ageGroup = "age_group"
        case minAge = "min_age"
        case maxAge = "max_age"
        case calorieAdjustment = "calorie_adjustment"
        case proteinAdjustment = "protein_adjustment"
        case keyConsiderations = "key_considerations"
        case priorityNutrients = "priority_nutrients"
    }

    /// Parse calorie adjustment percentage
    var calorieAdjustmentPercent: Double {
        // Parse strings like "+10-15%", "-5%", "Baseline"
        if calorieAdjustment.contains("Baseline") {
            return 0
        }
        let cleaned = calorieAdjustment
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "%", with: "")
            .components(separatedBy: "-")
            .first ?? "0"
        return Double(cleaned) ?? 0
    }
}

// MARK: - Gender Modification

/// Gender-specific nutrition considerations
struct GenderModification: Codable, Identifiable, Hashable, Equatable, Sendable {
    var id: String { gender }

    let gender: String
    let calorieNotes: String
    let proteinNotes: String
    let carbNotes: String
    let fatNotes: String
    let hydrationNotes: String
    let keyNutrients: [String]
    let commonGaps: String
    let timingNotes: String

    enum CodingKeys: String, CodingKey {
        case gender
        case calorieNotes = "calorie_notes"
        case proteinNotes = "protein_notes"
        case carbNotes = "carb_notes"
        case fatNotes = "fat_notes"
        case hydrationNotes = "hydration_notes"
        case keyNutrients = "key_nutrients"
        case commonGaps = "common_gaps"
        case timingNotes = "timing_notes"
    }
}

// MARK: - Meal Timing

/// Pre/post workout and competition day meal timing guidelines
struct MealTiming: Codable, Identifiable, Hashable, Equatable, Sendable {
    var id: String { timing }

    let timing: String
    let goal: String
    let whatToEat: String
    let examples: [String]

    enum CodingKeys: String, CodingKey {
        case timing
        case goal
        case whatToEat = "what_to_eat"
        case examples
    }

    var icon: String {
        switch timing.lowercased() {
        case _ where timing.contains("3-4"):
            return "clock.fill"
        case _ where timing.contains("1-2") && timing.contains("Pre"):
            return "clock.badge.fill"
        case _ where timing.contains("30-60"):
            return "bolt.fill"
        case _ where timing.contains("During"):
            return "figure.run"
        case _ where timing.contains("0-30") && timing.contains("Post"):
            return "checkmark.circle.fill"
        case _ where timing.contains("1-2") && timing.contains("Post"):
            return "fork.knife"
        case _ where timing.contains("Rest"):
            return "bed.double.fill"
        default:
            return "clock"
        }
    }
}

// MARK: - Portion Guide

/// Hand-based portion measurement system
struct PortionGuide: Codable, Identifiable, Hashable, Equatable, Sendable {
    var id: String { handMeasure }

    let handMeasure: String
    let foodType: String
    let approximateAmount: String
    let examples: [String]

    enum CodingKeys: String, CodingKey {
        case handMeasure = "hand_measure"
        case foodType = "food_type"
        case approximateAmount = "approximate_amount"
        case examples
    }

    var icon: String {
        switch handMeasure.uppercased() {
        case "PALM":
            return "hand.raised.fill"
        case "FIST":
            return "hand.point.up.fill"
        case "CUPPED HAND":
            return "hand.wave.fill"
        case "THUMB":
            return "hand.thumbsup.fill"
        default:
            return "hand.raised"
        }
    }

    var color: Color {
        switch foodType.lowercased() {
        case "protein":
            return .red
        case "vegetables":
            return .green
        case "carbs":
            return .blue
        case "fats":
            return .yellow
        default:
            return .gray
        }
    }
}

// MARK: - Meal Template

/// Portion-based meal template by goal and gender
struct MealTemplate: Codable, Identifiable, Hashable, Equatable, Sendable {
    var id: String { "\(gender)-\(goal)" }

    let gender: String
    let goal: String
    let proteinPortions: Double  // palms
    let vegetablePortions: Double  // fists
    let carbPortions: Double  // cupped hands
    let fatPortions: Double  // thumbs

    enum CodingKeys: String, CodingKey {
        case gender
        case goal
        case proteinPortions = "protein_portions"
        case vegetablePortions = "vegetable_portions"
        case carbPortions = "carb_portions"
        case fatPortions = "fat_portions"
    }

    var displayName: String {
        "\(gender) - \(goal)"
    }

    /// Format portions as string
    func formatPortions() -> String {
        var parts: [String] = []
        parts.append("\(formatPortion(proteinPortions)) palm\(proteinPortions == 1 ? "" : "s") protein")
        parts.append("\(formatPortion(vegetablePortions)) fist\(vegetablePortions == 1 ? "" : "s") vegetables")
        parts.append("\(formatPortion(carbPortions)) cupped hand\(carbPortions == 1 ? "" : "s") carbs")
        parts.append("\(formatPortion(fatPortions)) thumb\(fatPortions == 1 ? "" : "s") fat")
        return parts.joined(separator: " | ")
    }

    private func formatPortion(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - Food List

/// Recommended foods by category
struct FoodList: Codable, Identifiable, Hashable, Equatable, Sendable {
    var id: String { category }

    let category: String
    let foods: [String]

    var icon: String {
        switch category.lowercased() {
        case "lean proteins":
            return "fork.knife"
        case "complex carbs":
            return "leaf.fill"
        case "fruits":
            return "applelogo"
        case "vegetables":
            return "carrot.fill"
        case "healthy fats":
            return "drop.fill"
        case "dairy/alternatives":
            return "cup.and.saucer.fill"
        default:
            return "list.bullet"
        }
    }

    var color: Color {
        switch category.lowercased() {
        case "lean proteins":
            return .red
        case "complex carbs":
            return .brown
        case "fruits":
            return .orange
        case "vegetables":
            return .green
        case "healthy fats":
            return .yellow
        case "dairy/alternatives":
            return .blue
        default:
            return .gray
        }
    }
}

// MARK: - Base Principles

/// Core nutrition principles from Modus guidelines
struct NutritionPrinciple: Codable, Identifiable, Hashable, Equatable, Sendable {
    var id: String { title }

    let title: String
    let description: String
    let bulletPoints: [String]

    var icon: String {
        switch title.lowercased() {
        case "protein first":
            return "fork.knife"
        case "quality carbs":
            return "leaf.fill"
        case "healthy fats":
            return "drop.fill"
        case "hydration":
            return "drop.circle.fill"
        case "meal timing":
            return "clock.fill"
        case "flexibility":
            return "checkmark.circle.fill"
        case "listen to your body":
            return "ear.fill"
        case "supplements":
            return "pills.fill"
        default:
            return "info.circle"
        }
    }
}

// MARK: - Static Data

/// Pre-loaded Modus nutrition guidelines data
enum NutritionGuidelinesData {

    /// All athlete type nutrition profiles from spreadsheet
    static let athleteTypes: [AthleteTypeNutrition] = [
        AthleteTypeNutrition(
            athleteType: "BASE",
            proteinMinGPerLb: 0.8,
            proteinMaxGPerLb: 1.0,
            carbFocus: .moderate,
            fatPercent: "25-30%",
            hydrationModifier: "Standard",
            keyNutrients: ["Balanced micronutrients"],
            timingNotes: "Even distribution"
        ),
        AthleteTypeNutrition(
            athleteType: "BASEBALL",
            proteinMinGPerLb: 0.9,
            proteinMaxGPerLb: 1.1,
            carbFocus: .moderateHigh,
            fatPercent: "25%",
            hydrationModifier: "+20%",
            keyNutrients: ["Vitamin D", "Iron", "B12"],
            timingNotes: "Pre-game carb load"
        ),
        AthleteTypeNutrition(
            athleteType: "TACTICAL",
            proteinMinGPerLb: 1.0,
            proteinMaxGPerLb: 1.2,
            carbFocus: .high,
            fatPercent: "25-30%",
            hydrationModifier: "+30%",
            keyNutrients: ["Iron", "Magnesium", "Zinc"],
            timingNotes: "Sustained energy focus"
        ),
        AthleteTypeNutrition(
            athleteType: "GOLF",
            proteinMinGPerLb: 0.7,
            proteinMaxGPerLb: 0.9,
            carbFocus: .moderate,
            fatPercent: "30%",
            hydrationModifier: "+10%",
            keyNutrients: ["Omega-3s", "Antioxidants"],
            timingNotes: "Steady blood sugar"
        ),
        AthleteTypeNutrition(
            athleteType: "PICKLEBALL",
            proteinMinGPerLb: 0.8,
            proteinMaxGPerLb: 1.0,
            carbFocus: .moderate,
            fatPercent: "25-30%",
            hydrationModifier: "+15%",
            keyNutrients: ["Electrolytes", "Vitamin C"],
            timingNotes: "Quick digesting pre-play"
        ),
        AthleteTypeNutrition(
            athleteType: "MASTERS",
            proteinMinGPerLb: 1.0,
            proteinMaxGPerLb: 1.2,
            carbFocus: .moderate,
            fatPercent: "30%",
            hydrationModifier: "Critical",
            keyNutrients: ["Calcium", "Vitamin D", "B12", "Omega-3"],
            timingNotes: "Higher protein per meal"
        ),
        AthleteTypeNutrition(
            athleteType: "RUNNING",
            proteinMinGPerLb: 0.8,
            proteinMaxGPerLb: 1.0,
            carbFocus: .high,
            fatPercent: "20-25%",
            hydrationModifier: "+40%",
            keyNutrients: ["Iron", "B vitamins", "Calcium"],
            timingNotes: "Carb periodization"
        ),
        AthleteTypeNutrition(
            athleteType: "CROSSFIT",
            proteinMinGPerLb: 1.0,
            proteinMaxGPerLb: 1.2,
            carbFocus: .high,
            fatPercent: "25%",
            hydrationModifier: "+25%",
            keyNutrients: ["Creatine", "Magnesium"],
            timingNotes: "Post-WOD priority"
        ),
        AthleteTypeNutrition(
            athleteType: "SWIMMING",
            proteinMinGPerLb: 0.9,
            proteinMaxGPerLb: 1.1,
            carbFocus: .high,
            fatPercent: "25-30%",
            hydrationModifier: "+50%",
            keyNutrients: ["Iron", "Zinc", "Vitamin D"],
            timingNotes: "Pre-swim timing critical"
        ),
        AthleteTypeNutrition(
            athleteType: "BASKETBALL",
            proteinMinGPerLb: 0.9,
            proteinMaxGPerLb: 1.1,
            carbFocus: .high,
            fatPercent: "25%",
            hydrationModifier: "+30%",
            keyNutrients: ["Electrolytes", "Iron"],
            timingNotes: "Game day fueling"
        ),
        AthleteTypeNutrition(
            athleteType: "SOCCER",
            proteinMinGPerLb: 0.9,
            proteinMaxGPerLb: 1.0,
            carbFocus: .high,
            fatPercent: "25%",
            hydrationModifier: "+35%",
            keyNutrients: ["Iron", "B12", "Electrolytes"],
            timingNotes: "90-min fueling strategy"
        ),
        AthleteTypeNutrition(
            athleteType: "TENNIS",
            proteinMinGPerLb: 0.8,
            proteinMaxGPerLb: 1.0,
            carbFocus: .moderateHigh,
            fatPercent: "25%",
            hydrationModifier: "+25%",
            keyNutrients: ["Electrolytes", "Magnesium"],
            timingNotes: "Between-set nutrition"
        ),
        AthleteTypeNutrition(
            athleteType: "REHAB",
            proteinMinGPerLb: 1.0,
            proteinMaxGPerLb: 1.2,
            carbFocus: .moderate,
            fatPercent: "25-30%",
            hydrationModifier: "Standard",
            keyNutrients: ["Vitamin C", "Zinc", "Collagen"],
            timingNotes: "Anti-inflammatory focus"
        ),
        AthleteTypeNutrition(
            athleteType: "PRENATAL",
            proteinMinGPerLb: 1.0,
            proteinMaxGPerLb: 1.1,
            carbFocus: .moderate,
            fatPercent: "30%",
            hydrationModifier: "+25%",
            keyNutrients: ["Folate", "Iron", "DHA", "Calcium"],
            timingNotes: "Small frequent meals"
        ),
        AthleteTypeNutrition(
            athleteType: "POSTPARTUM",
            proteinMinGPerLb: 1.1,
            proteinMaxGPerLb: 1.2,
            carbFocus: .moderate,
            fatPercent: "30%",
            hydrationModifier: "+30%",
            keyNutrients: ["Iron", "Vitamin D", "B12", "Omega-3"],
            timingNotes: "Support recovery + nursing"
        ),
        AthleteTypeNutrition(
            athleteType: "YOUTH12",
            proteinMinGPerLb: 0.7,
            proteinMaxGPerLb: 0.9,
            carbFocus: .high,
            fatPercent: "25-30%",
            hydrationModifier: "Critical",
            keyNutrients: ["Calcium", "Iron", "Zinc"],
            timingNotes: "Growth support"
        ),
        AthleteTypeNutrition(
            athleteType: "YOUTH16",
            proteinMinGPerLb: 0.8,
            proteinMaxGPerLb: 1.0,
            carbFocus: .high,
            fatPercent: "25%",
            hydrationModifier: "+20%",
            keyNutrients: ["Calcium", "Iron", "Protein"],
            timingNotes: "Performance + growth"
        ),
        AthleteTypeNutrition(
            athleteType: "GOALS-FATLOSS",
            proteinMinGPerLb: 1.0,
            proteinMaxGPerLb: 1.2,
            carbFocus: .lowModerate,
            fatPercent: "30%",
            hydrationModifier: "Standard",
            keyNutrients: ["Fiber", "Protein"],
            timingNotes: "Protein every meal"
        ),
        AthleteTypeNutrition(
            athleteType: "GOALS-MUSCLE",
            proteinMinGPerLb: 1.0,
            proteinMaxGPerLb: 1.2,
            carbFocus: .high,
            fatPercent: "25%",
            hydrationModifier: "Standard",
            keyNutrients: ["Leucine", "Creatine"],
            timingNotes: "Post-workout window"
        ),
        AthleteTypeNutrition(
            athleteType: "EXPRESS",
            proteinMinGPerLb: 0.8,
            proteinMaxGPerLb: 1.0,
            carbFocus: .moderate,
            fatPercent: "25-30%",
            hydrationModifier: "Standard",
            keyNutrients: ["Balanced"],
            timingNotes: "Meal prep essential"
        )
    ]

    /// Age-based modifications
    static let ageModifications: [AgeModification] = [
        AgeModification(
            ageGroup: "Youth (12-16)",
            minAge: 12,
            maxAge: 16,
            calorieAdjustment: "+10-15%",
            proteinAdjustment: "0.7-0.9 g/lb",
            keyConsiderations: [
                "Support growth and development",
                "Avoid restriction",
                "Focus on food quality not quantity",
                "Regular eating schedule"
            ],
            priorityNutrients: ["Calcium", "Iron", "Zinc", "Vitamin D"]
        ),
        AgeModification(
            ageGroup: "Teen (16-18)",
            minAge: 16,
            maxAge: 18,
            calorieAdjustment: "+5-10%",
            proteinAdjustment: "0.8-1.0 g/lb",
            keyConsiderations: [
                "Peak growth period",
                "High energy demands",
                "May need 3000-4000+ cals/day",
                "Don't skip meals"
            ],
            priorityNutrients: ["Calcium", "Iron", "Protein", "B vitamins"]
        ),
        AgeModification(
            ageGroup: "Young Adult (18-30)",
            minAge: 18,
            maxAge: 30,
            calorieAdjustment: "Baseline",
            proteinAdjustment: "0.8-1.0 g/lb",
            keyConsiderations: [
                "Peak metabolism",
                "Recovery is fast",
                "Can handle higher volume",
                "Establish good habits"
            ],
            priorityNutrients: ["Balanced micronutrients"]
        ),
        AgeModification(
            ageGroup: "Adult (30-40)",
            minAge: 30,
            maxAge: 40,
            calorieAdjustment: "Baseline",
            proteinAdjustment: "0.9-1.0 g/lb",
            keyConsiderations: [
                "Metabolism starting to slow",
                "Recovery takes longer",
                "Quality over quantity",
                "Sleep becomes critical"
            ],
            priorityNutrients: ["Omega-3s", "Vitamin D", "Magnesium"]
        ),
        AgeModification(
            ageGroup: "Masters (40-50)",
            minAge: 40,
            maxAge: 50,
            calorieAdjustment: "-5%",
            proteinAdjustment: "1.0-1.1 g/lb",
            keyConsiderations: [
                "Increased protein for muscle retention",
                "More recovery time needed",
                "Anti-inflammatory foods",
                "Hormone changes begin"
            ],
            priorityNutrients: ["Protein", "Omega-3s", "Vitamin D", "Calcium"]
        ),
        AgeModification(
            ageGroup: "Masters (50-60)",
            minAge: 50,
            maxAge: 60,
            calorieAdjustment: "-10%",
            proteinAdjustment: "1.0-1.2 g/lb",
            keyConsiderations: [
                "Higher protein per meal (30-40g)",
                "Focus on muscle preservation",
                "Bone health priority",
                "May need B12 supplement"
            ],
            priorityNutrients: ["Protein", "B12", "Vitamin D", "Calcium", "Omega-3"]
        ),
        AgeModification(
            ageGroup: "Masters (60-70)",
            minAge: 60,
            maxAge: 70,
            calorieAdjustment: "-15%",
            proteinAdjustment: "1.1-1.2 g/lb",
            keyConsiderations: [
                "Distribute protein evenly across meals",
                "Appetite may decrease",
                "Nutrient density critical",
                "Hydration often overlooked"
            ],
            priorityNutrients: ["Protein", "B12", "Vitamin D", "Calcium", "Fiber"]
        ),
        AgeModification(
            ageGroup: "Masters (70+)",
            minAge: 70,
            maxAge: 120,
            calorieAdjustment: "-15-20%",
            proteinAdjustment: "1.2+ g/lb",
            keyConsiderations: [
                "Prioritize protein at every meal",
                "Smaller, frequent meals",
                "May need protein supplements",
                "Texture modifications if needed"
            ],
            priorityNutrients: ["Protein", "B12", "Vitamin D", "Calcium", "Zinc"]
        )
    ]

    /// Meal timing guidelines
    static let mealTimings: [MealTiming] = [
        MealTiming(
            timing: "3-4 Hours Pre-Workout",
            goal: "Full meal for sustained energy",
            whatToEat: "Balanced meal: protein + complex carbs + fat",
            examples: ["Chicken, rice, vegetables", "Salmon, sweet potato, salad"]
        ),
        MealTiming(
            timing: "1-2 Hours Pre-Workout",
            goal: "Top off energy stores",
            whatToEat: "Moderate carbs + light protein, low fat/fiber",
            examples: ["Oatmeal with banana", "Turkey sandwich", "Greek yogurt + fruit"]
        ),
        MealTiming(
            timing: "30-60 Min Pre-Workout",
            goal: "Quick energy if needed",
            whatToEat: "Simple carbs, minimal protein/fat",
            examples: ["Banana", "Rice cakes", "Sports drink", "Applesauce"]
        ),
        MealTiming(
            timing: "During (>60 min)",
            goal: "Sustain blood sugar",
            whatToEat: "30-60g carbs per hour for long sessions",
            examples: ["Sports drink", "Gels/chews", "Banana", "Dates"]
        ),
        MealTiming(
            timing: "0-30 Min Post-Workout",
            goal: "Start recovery window",
            whatToEat: "Quick protein + carbs (especially if training again soon)",
            examples: ["Chocolate milk", "Protein shake + banana", "Greek yogurt"]
        ),
        MealTiming(
            timing: "1-2 Hours Post-Workout",
            goal: "Complete recovery meal",
            whatToEat: "Balanced meal with protein emphasis",
            examples: ["Steak, potato, vegetables", "Salmon, quinoa, broccoli"]
        ),
        MealTiming(
            timing: "Rest Day",
            goal: "Maintain, don't overeat",
            whatToEat: "Slightly lower carbs, maintain protein",
            examples: ["Focus on protein + vegetables", "Healthy fats for satiety"]
        )
    ]

    /// Hand-based portion guides
    static let portionGuides: [PortionGuide] = [
        PortionGuide(
            handMeasure: "PALM",
            foodType: "Protein",
            approximateAmount: "3-4 oz / 20-30g protein",
            examples: ["Chicken", "Fish", "Beef", "Tofu"]
        ),
        PortionGuide(
            handMeasure: "FIST",
            foodType: "Vegetables",
            approximateAmount: "1 cup",
            examples: ["Broccoli", "Salad", "Peppers"]
        ),
        PortionGuide(
            handMeasure: "CUPPED HAND",
            foodType: "Carbs",
            approximateAmount: "1/2-3/4 cup / 20-30g carbs",
            examples: ["Rice", "Pasta", "Fruit"]
        ),
        PortionGuide(
            handMeasure: "THUMB",
            foodType: "Fats",
            approximateAmount: "1 tbsp",
            examples: ["Oils", "Nut butter", "Cheese"]
        )
    ]

    /// Meal templates by goal and gender
    static let mealTemplates: [MealTemplate] = [
        MealTemplate(gender: "Male", goal: "Maintenance", proteinPortions: 2, vegetablePortions: 2, carbPortions: 2, fatPortions: 2),
        MealTemplate(gender: "Male", goal: "Fat Loss", proteinPortions: 2, vegetablePortions: 2, carbPortions: 1, fatPortions: 1),
        MealTemplate(gender: "Male", goal: "Muscle Gain", proteinPortions: 2, vegetablePortions: 2, carbPortions: 3, fatPortions: 2),
        MealTemplate(gender: "Female", goal: "Maintenance", proteinPortions: 1, vegetablePortions: 2, carbPortions: 1, fatPortions: 1),
        MealTemplate(gender: "Female", goal: "Fat Loss", proteinPortions: 1, vegetablePortions: 2, carbPortions: 0.5, fatPortions: 1),
        MealTemplate(gender: "Female", goal: "Muscle Gain", proteinPortions: 1.5, vegetablePortions: 2, carbPortions: 2, fatPortions: 1)
    ]

    /// Food lists by category
    static let foodLists: [FoodList] = [
        FoodList(category: "Lean Proteins", foods: [
            "Chicken breast", "Turkey breast", "Lean beef (93%+)", "Pork tenderloin",
            "Fish (salmon, tuna, cod)", "Shrimp", "Eggs/egg whites", "Greek yogurt",
            "Cottage cheese", "Tofu", "Tempeh", "Protein powder"
        ]),
        FoodList(category: "Complex Carbs", foods: [
            "Oatmeal", "Brown rice", "Quinoa", "Sweet potato", "White potato",
            "Whole grain bread", "Whole grain pasta", "Beans/lentils",
            "Barley", "Farro", "Corn", "Peas"
        ]),
        FoodList(category: "Fruits", foods: [
            "Bananas", "Berries", "Apples", "Oranges", "Grapes", "Melon",
            "Mango", "Pineapple", "Peaches", "Pears", "Dried fruit (dates, raisins)"
        ]),
        FoodList(category: "Vegetables", foods: [
            "Broccoli", "Spinach", "Kale", "Peppers", "Carrots", "Tomatoes",
            "Zucchini", "Asparagus", "Green beans", "Brussels sprouts",
            "Cauliflower", "Mushrooms"
        ]),
        FoodList(category: "Healthy Fats", foods: [
            "Olive oil", "Avocado", "Nuts (almonds, walnuts)", "Nut butters",
            "Seeds (chia, flax, pumpkin)", "Fatty fish", "Coconut oil (limited)"
        ]),
        FoodList(category: "Dairy/Alternatives", foods: [
            "Greek yogurt", "Milk", "Cheese", "Cottage cheese",
            "Almond milk", "Soy milk", "Oat milk"
        ])
    ]

    /// Core nutrition principles
    static let basePrinciples: [NutritionPrinciple] = [
        NutritionPrinciple(
            title: "Protein First",
            description: "Anchor every meal around a quality protein source",
            bulletPoints: [
                "Aim for 25-40g protein per meal",
                "Include protein at every eating occasion",
                "Space protein throughout the day (not all at once)"
            ]
        ),
        NutritionPrinciple(
            title: "Quality Carbs",
            description: "Choose nutrient-dense carbohydrate sources",
            bulletPoints: [
                "Prioritize whole grains, fruits, vegetables",
                "Time higher carbs around training",
                "Minimize processed/refined carbs"
            ]
        ),
        NutritionPrinciple(
            title: "Healthy Fats",
            description: "Include fats for hormones and satiety",
            bulletPoints: [
                "Focus on unsaturated sources (olive oil, nuts, avocado)",
                "Include omega-3s (fatty fish, flax, walnuts)",
                "Limit saturated fats to <10% of calories"
            ]
        ),
        NutritionPrinciple(
            title: "Hydration",
            description: "Stay consistently hydrated throughout the day",
            bulletPoints: [
                "Baseline: 0.5-1 oz per lb bodyweight",
                "Add 16-24 oz per hour of exercise",
                "Monitor urine color (pale yellow = good)"
            ]
        ),
        NutritionPrinciple(
            title: "Meal Timing",
            description: "Eat consistently to support energy and recovery",
            bulletPoints: [
                "3-5 eating occasions per day",
                "Don't skip meals before training",
                "Post-workout nutrition within 2 hours"
            ]
        ),
        NutritionPrinciple(
            title: "Flexibility",
            description: "80/20 approach - consistency over perfection",
            bulletPoints: [
                "80% whole, nutrient-dense foods",
                "20% flexibility for life and enjoyment",
                "No food is \"forbidden\""
            ]
        ),
        NutritionPrinciple(
            title: "Listen to Your Body",
            description: "Use hunger and fullness cues",
            bulletPoints: [
                "Eat when hungry, stop when satisfied (not stuffed)",
                "Rate hunger 1-10 before eating",
                "Eat slowly, chew thoroughly"
            ]
        ),
        NutritionPrinciple(
            title: "Supplements",
            description: "Food first, supplements to fill gaps only",
            bulletPoints: [
                "Protein powder if struggling to meet targets",
                "Creatine for strength athletes",
                "Vitamin D if limited sun exposure",
                "Consult professional before adding"
            ]
        )
    ]

    /// Get athlete type nutrition by code
    static func getAthleteTypeNutrition(code: String) -> AthleteTypeNutrition? {
        athleteTypes.first { $0.athleteType.uppercased() == code.uppercased() }
    }

    /// Get age modification for a given age
    static func getAgeModification(age: Int) -> AgeModification? {
        ageModifications.first { age >= $0.minAge && age <= $0.maxAge }
    }

    /// Get meal template for gender and goal
    static func getMealTemplate(gender: String, goal: String) -> MealTemplate? {
        mealTemplates.first { $0.gender.lowercased() == gender.lowercased() && $0.goal.lowercased() == goal.lowercased() }
    }
}

// MARK: - Preview Support

#if DEBUG
extension AthleteTypeNutrition {
    static let preview = NutritionGuidelinesData.athleteTypes[0]
    static let previewBaseball = NutritionGuidelinesData.athleteTypes[1]
}

extension AgeModification {
    static let preview = NutritionGuidelinesData.ageModifications[2]
}

extension MealTiming {
    static let preview = NutritionGuidelinesData.mealTimings[0]
}

extension PortionGuide {
    static let preview = NutritionGuidelinesData.portionGuides[0]
}
#endif
