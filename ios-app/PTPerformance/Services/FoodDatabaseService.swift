//
//  FoodDatabaseService.swift
//  PTPerformance
//
//  Nutrition Module - Food database service
//

import Foundation

// MARK: - Input Models

/// Input for creating a custom food item
struct CreateFoodItemInput: Codable {
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
    let createdBy: String?

    enum CodingKeys: String, CodingKey {
        case name, brand, calories, category, subcategory, barcode
        case servingSize = "serving_size"
        case servingGrams = "serving_grams"
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
        case sugarG = "sugar_g"
        case sodiumMg = "sodium_mg"
        case isSystem = "is_system"
        case createdBy = "created_by"
    }

    init(from dto: CreateFoodItemDTO, createdBy: String?) {
        self.name = dto.name
        self.brand = dto.brand
        self.servingSize = dto.servingSize
        self.servingGrams = dto.servingGrams
        self.calories = dto.calories
        self.proteinG = dto.proteinG
        self.carbsG = dto.carbsG
        self.fatG = dto.fatG
        self.fiberG = dto.fiberG
        self.sugarG = dto.sugarG
        self.sodiumMg = dto.sodiumMg
        self.category = dto.category
        self.subcategory = dto.subcategory
        self.barcode = dto.barcode
        self.isSystem = false
        self.createdBy = createdBy
    }
}

/// Input for updating a custom food item
struct UpdateFoodItemInput: Codable {
    let name: String?
    let brand: String?
    let servingSize: String?
    let servingGrams: Double?
    let calories: Int?
    let proteinG: Double?
    let carbsG: Double?
    let fatG: Double?
    let fiberG: Double?
    let sugarG: Double?
    let sodiumMg: Double?
    let category: String?
    let subcategory: String?
    let barcode: String?

    enum CodingKeys: String, CodingKey {
        case name, brand, calories, category, subcategory, barcode
        case servingSize = "serving_size"
        case servingGrams = "serving_grams"
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
        case sugarG = "sugar_g"
        case sodiumMg = "sodium_mg"
    }
}

/// Service for searching and managing food items in the database
@MainActor
class FoodDatabaseService {
    static let shared = FoodDatabaseService()
    private let supabase = PTSupabaseClient.shared

    // Cache for frequently accessed foods
    private var recentFoods: [FoodItem] = []
    private var favoriteFoods: [FoodItem] = []

    private init() {}

    // MARK: - Search

    /// Search food items by name
    func searchFoods(query: String, limit: Int = 50) async throws -> [FoodSearchResult] {
        guard !query.isEmpty else { return [] }

        // Use ilike for case-insensitive search
        let response = try await supabase.client
            .from("food_items")
            .select("id, name, brand, serving_size, calories, protein_g, carbs_g, fat_g, category, is_verified")
            .or("is_system.eq.true,created_by.eq.\(supabase.userId ?? "")")
            .ilike("name", pattern: "%\(query)%")
            .order("is_verified", ascending: false)
            .order("name", ascending: true)
            .limit(limit)
            .execute()

        let decoder = JSONDecoder()
        return try decoder.decode([FoodSearchResult].self, from: response.data)
    }

    /// Search food items by category
    func searchByCategory(_ category: FoodCategory, limit: Int = 50) async throws -> [FoodSearchResult] {
        let response = try await supabase.client
            .from("food_items")
            .select("id, name, brand, serving_size, calories, protein_g, carbs_g, fat_g, category, is_verified")
            .or("is_system.eq.true,created_by.eq.\(supabase.userId ?? "")")
            .eq("category", value: category.rawValue)
            .order("is_verified", ascending: false)
            .order("name", ascending: true)
            .limit(limit)
            .execute()

        let decoder = JSONDecoder()
        return try decoder.decode([FoodSearchResult].self, from: response.data)
    }

    /// Search food items by barcode
    func searchByBarcode(_ barcode: String) async throws -> FoodItem? {
        let response = try await supabase.client
            .from("food_items")
            .select()
            .eq("barcode", value: barcode)
            .limit(1)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let items = try decoder.decode([FoodItem].self, from: response.data)
        return items.first
    }

    // MARK: - Food Item Details

    /// Fetch full food item details by ID
    func fetchFoodItem(id: UUID) async throws -> FoodItem? {
        let response = try await supabase.client
            .from("food_items")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let items = try decoder.decode([FoodItem].self, from: response.data)
        return items.first
    }

    /// Fetch multiple food items by IDs
    func fetchFoodItems(ids: [UUID]) async throws -> [FoodItem] {
        guard !ids.isEmpty else { return [] }

        let idStrings = ids.map { $0.uuidString }
        let response = try await supabase.client
            .from("food_items")
            .select()
            .in("id", values: idStrings)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([FoodItem].self, from: response.data)
    }

    // MARK: - Custom Foods

    /// Create a custom food item
    func createCustomFood(_ food: CreateFoodItemDTO) async throws -> FoodItem {
        let input = CreateFoodItemInput(from: food, createdBy: supabase.userId)

        let response = try await supabase.client
            .from("food_items")
            .insert(input)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(FoodItem.self, from: response.data)
    }

    /// Update a custom food item
    func updateCustomFood(id: UUID, updates: UpdateFoodItemInput) async throws {
        // Verify ownership before updating
        guard let food = try await fetchFoodItem(id: id),
              food.createdBy == supabase.userId,
              !food.isSystem else {
            throw FoodDatabaseError.unauthorized
        }

        _ = try await supabase.client
            .from("food_items")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Delete a custom food item
    func deleteCustomFood(id: UUID) async throws {
        // Verify ownership before deleting
        guard let food = try await fetchFoodItem(id: id),
              food.createdBy == supabase.userId,
              !food.isSystem else {
            throw FoodDatabaseError.unauthorized
        }

        _ = try await supabase.client
            .from("food_items")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Popular/Recent Foods

    /// Fetch popular system foods
    func fetchPopularFoods(limit: Int = 20) async throws -> [FoodSearchResult] {
        #if DEBUG
        print("🍎 [FOOD DB] Fetching popular foods, limit: \(limit)")
        #endif

        do {
            let response = try await supabase.client
                .from("food_items")
                .select("id, name, brand, serving_size, calories, protein_g, carbs_g, fat_g, category, is_verified")
                .eq("is_system", value: true)
                .eq("is_verified", value: true)
                .order("name", ascending: true)
                .limit(limit)
                .execute()

            #if DEBUG
            if let json = String(data: response.data, encoding: .utf8) {
                print("🍎 [FOOD DB] Popular foods response: \(json.prefix(500))")
            }
            #endif

            let decoder = JSONDecoder()
            let results = try decoder.decode([FoodSearchResult].self, from: response.data)

            #if DEBUG
            print("🍎 [FOOD DB] ✓ Fetched \(results.count) popular foods")
            #endif

            return results
        } catch {
            DebugLogger.shared.error("FoodDatabaseService", "Popular foods error: \(error.localizedDescription)")
            throw error
        }
    }

    /// Fetch user's custom foods
    func fetchUserFoods() async throws -> [FoodItem] {
        guard let userId = supabase.userId else { return [] }

        let response = try await supabase.client
            .from("food_items")
            .select()
            .eq("created_by", value: userId)
            .eq("is_system", value: false)
            .order("name", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([FoodItem].self, from: response.data)
    }

    /// Fetch recently logged foods for quick access
    func fetchRecentlyLoggedFoods(patientId: String, limit: Int = 10) async throws -> [FoodSearchResult] {
        // Get recent nutrition logs and extract unique food item IDs
        let logsResponse = try await supabase.client
            .from("nutrition_logs")
            .select("food_items")
            .eq("patient_id", value: patientId)
            .order("logged_at", ascending: false)
            .limit(20)
            .execute()

        let decoder = JSONDecoder()

        struct FoodItemsWrapper: Codable {
            let foodItems: [LoggedFoodItem]

            enum CodingKeys: String, CodingKey {
                case foodItems = "food_items"
            }
        }

        let logs = try decoder.decode([FoodItemsWrapper].self, from: logsResponse.data)

        // Extract unique food item IDs
        var seenIds = Set<UUID>()
        var uniqueIds: [UUID] = []

        for log in logs {
            for item in log.foodItems {
                if let foodItemId = item.foodItemId, !seenIds.contains(foodItemId) {
                    seenIds.insert(foodItemId)
                    uniqueIds.append(foodItemId)
                    if uniqueIds.count >= limit { break }
                }
            }
            if uniqueIds.count >= limit { break }
        }

        guard !uniqueIds.isEmpty else { return [] }

        // Fetch the food items
        let idStrings = uniqueIds.map { $0.uuidString }
        let foodsResponse = try await supabase.client
            .from("food_items")
            .select("id, name, brand, serving_size, calories, protein_g, carbs_g, fat_g, category, is_verified")
            .in("id", values: idStrings)
            .execute()

        return try decoder.decode([FoodSearchResult].self, from: foodsResponse.data)
    }

    // MARK: - Categories

    /// Fetch all available food categories with counts
    func fetchCategoryCounts() async throws -> [String: Int] {
        let response = try await supabase.client
            .from("food_items")
            .select("category")
            .or("is_system.eq.true,created_by.eq.\(supabase.userId ?? "")")
            .execute()

        struct CategoryRow: Codable {
            let category: String?
        }

        let decoder = JSONDecoder()
        let rows = try decoder.decode([CategoryRow].self, from: response.data)

        var counts: [String: Int] = [:]
        for row in rows {
            if let category = row.category {
                counts[category, default: 0] += 1
            }
        }
        return counts
    }
}

// MARK: - Errors

enum FoodDatabaseError: LocalizedError {
    case unauthorized
    case notFound
    case invalidBarcode

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "You don't have permission to modify this food item"
        case .notFound:
            return "Food item not found"
        case .invalidBarcode:
            return "Invalid barcode format"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .unauthorized:
            return "You can only edit food items you've created. Try creating a new custom food instead."
        case .notFound:
            return "This food may have been deleted. Try searching for a similar item."
        case .invalidBarcode:
            return "Please scan the barcode again or enter the food details manually."
        }
    }
}
