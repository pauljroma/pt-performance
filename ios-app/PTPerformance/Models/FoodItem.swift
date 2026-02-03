//
//  FoodItem.swift
//  PTPerformance
//
//  Nutrition Module - Food database model
//

import Foundation

/// Food item from the database for nutrition tracking
struct FoodItem: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let name: String
    let brand: String?
    let servingSize: String
    let servingGrams: Double?
    let calories: Int
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let fiberG: Double?
    let sugarG: Double?
    let sodiumMg: Double?
    let category: FoodCategory?
    let subcategory: String?
    let barcode: String?
    let isVerified: Bool
    let isSystem: Bool
    let createdBy: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case servingSize = "serving_size"
        case servingGrams = "serving_grams"
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
        case sugarG = "sugar_g"
        case sodiumMg = "sodium_mg"
        case category
        case subcategory
        case barcode
        case isVerified = "is_verified"
        case isSystem = "is_system"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Food categories for organization
enum FoodCategory: String, Codable, CaseIterable, Hashable {
    case protein
    case vegetable
    case fruit
    case grain
    case dairy
    case fat
    case supplement
    case beverage
    case snack
    case condiment

    var displayName: String {
        switch self {
        case .protein: return "Protein"
        case .vegetable: return "Vegetable"
        case .fruit: return "Fruit"
        case .grain: return "Grain"
        case .dairy: return "Dairy"
        case .fat: return "Fat"
        case .supplement: return "Supplement"
        case .beverage: return "Beverage"
        case .snack: return "Snack"
        case .condiment: return "Condiment"
        }
    }

    var icon: String {
        switch self {
        case .protein: return "fish.fill"
        case .vegetable: return "leaf.fill"
        case .fruit: return "apple.logo"
        case .grain: return "takeoutbag.and.cup.and.straw.fill"
        case .dairy: return "drop.fill"
        case .fat: return "drop.triangle.fill"
        case .supplement: return "pills.fill"
        case .beverage: return "cup.and.saucer.fill"
        case .snack: return "birthday.cake.fill"
        case .condiment: return "salt.fill"
        }
    }

    var color: String {
        switch self {
        case .protein: return "red"
        case .vegetable: return "green"
        case .fruit: return "orange"
        case .grain: return "brown"
        case .dairy: return "blue"
        case .fat: return "yellow"
        case .supplement: return "purple"
        case .beverage: return "cyan"
        case .snack: return "pink"
        case .condiment: return "gray"
        }
    }
}

// MARK: - Convenience Extensions

extension FoodItem {
    /// Display string combining name and brand
    var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(name) (\(brand))"
        }
        return name
    }

    /// Macro summary string
    var macroSummary: String {
        "P: \(Int(proteinG))g | C: \(Int(carbsG))g | F: \(Int(fatG))g"
    }

    /// Convert to LoggedFoodItem with specified servings
    func toLoggedItem(servings: Double = 1.0) -> LoggedFoodItem {
        LoggedFoodItem(
            foodItemId: id,
            name: name,
            servings: servings,
            servingSize: servingSize,
            calories: calories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            fiberG: fiberG
        )
    }
}

// MARK: - Create Custom Food DTO

struct CreateFoodItemDTO: Codable {
    let name: String
    let brand: String?
    let servingSize: String
    let servingGrams: Double?
    let calories: Int
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let fiberG: Double?
    let sugarG: Double?
    let sodiumMg: Double?
    let category: String?
    let subcategory: String?
    let barcode: String?
    let isSystem: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case brand
        case servingSize = "serving_size"
        case servingGrams = "serving_grams"
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
        case sugarG = "sugar_g"
        case sodiumMg = "sodium_mg"
        case category
        case subcategory
        case barcode
        case isSystem = "is_system"
    }

    init(name: String, brand: String? = nil, servingSize: String, servingGrams: Double? = nil, calories: Int, proteinG: Double, carbsG: Double, fatG: Double, fiberG: Double? = nil, sugarG: Double? = nil, sodiumMg: Double? = nil, category: String? = nil, subcategory: String? = nil, barcode: String? = nil) {
        self.name = name
        self.brand = brand
        self.servingSize = servingSize
        self.servingGrams = servingGrams
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.fiberG = fiberG
        self.sugarG = sugarG
        self.sodiumMg = sodiumMg
        self.category = category
        self.subcategory = subcategory
        self.barcode = barcode
        self.isSystem = false // User-created items are never system
    }
}

// MARK: - Search Results

struct FoodSearchResult: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let name: String
    let brand: String?
    let servingSize: String
    let calories: Int
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let category: String?
    let isVerified: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case servingSize = "serving_size"
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case category
        case isVerified = "is_verified"
    }

    init(id: UUID = UUID(), name: String, brand: String? = nil, servingSize: String, calories: Int, proteinG: Double, carbsG: Double, fatG: Double, category: String? = nil, isVerified: Bool = false) {
        self.id = id
        self.name = name
        self.brand = brand
        self.servingSize = servingSize
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.category = category
        self.isVerified = isVerified
    }
}
