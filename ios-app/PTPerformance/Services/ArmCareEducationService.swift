//
//  ArmCareEducationService.swift
//  PTPerformance
//
//  Created by Content & Polish Sprint Agent 4
//  Service for fetching arm care educational articles
//

import Foundation
import Supabase

/// Service for fetching arm care educational content from the database
/// Provides articles on anatomy, injury prevention, recovery, and technique
@MainActor
class ArmCareEducationService: ObservableObject {

    // MARK: - Singleton

    static let shared = ArmCareEducationService()

    // MARK: - Published State

    @Published var articles: [ArmCareArticle] = []
    @Published var featuredArticles: [ArmCareArticle] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Dependencies

    private let client = PTSupabaseClient.shared
    private let errorLogger = ErrorLogger.shared

    // MARK: - Cache

    private var articlesCache: [ArmCareCategory: [ArmCareArticle]] = [:]
    private var lastCacheUpdate: Date?
    private let cacheDuration: TimeInterval = 300 // 5 minutes

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Fetch all published articles
    func fetchAllArticles() async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let fetchedArticles: [ArmCareArticle] = try await client.client
                .from("arm_care_education")
                .select()
                .eq("is_published", value: true)
                .order("sort_order", ascending: true)
                .execute()
                .value

            articles = fetchedArticles

            // Update cache for each category
            articlesCache.removeAll()
            for article in fetchedArticles {
                articlesCache[article.category, default: []].append(article)
            }
            lastCacheUpdate = Date()

        } catch {
            let errorMessage = "Failed to fetch arm care articles"
            self.error = errorMessage
            errorLogger.logDatabaseError(error, table: "arm_care_education")
            throw ArmCareEducationError.fetchFailed(error)
        }
    }

    /// Fetch articles by category
    /// - Parameter category: The article category to filter by
    /// - Returns: Array of articles in the specified category
    func fetchArticles(category: ArmCareCategory) async throws -> [ArmCareArticle] {
        // Check cache first
        if let cached = articlesCache[category],
           let lastUpdate = lastCacheUpdate,
           Date().timeIntervalSince(lastUpdate) < cacheDuration {
            return cached
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let fetchedArticles: [ArmCareArticle] = try await client.client
                .from("arm_care_education")
                .select()
                .eq("category", value: category.rawValue)
                .eq("is_published", value: true)
                .order("sort_order", ascending: true)
                .execute()
                .value

            // Update cache
            articlesCache[category] = fetchedArticles

            return fetchedArticles
        } catch {
            let errorMessage = "Failed to fetch articles for category: \(category.displayName)"
            self.error = errorMessage
            errorLogger.logDatabaseError(error, table: "arm_care_education")
            throw ArmCareEducationError.fetchFailed(error)
        }
    }

    /// Fetch featured articles for display on home/education screens
    func fetchFeaturedArticles() async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let featured: [ArmCareArticle] = try await client.client
                .from("arm_care_education")
                .select()
                .eq("is_featured", value: true)
                .eq("is_published", value: true)
                .order("sort_order", ascending: true)
                .execute()
                .value

            featuredArticles = featured
        } catch {
            let errorMessage = "Failed to fetch featured articles"
            self.error = errorMessage
            errorLogger.logDatabaseError(error, table: "arm_care_education")
            throw ArmCareEducationError.fetchFailed(error)
        }
    }

    /// Fetch a single article by its slug
    /// - Parameter slug: The URL-friendly slug for the article
    /// - Returns: The article if found
    func fetchArticle(slug: String) async throws -> ArmCareArticle? {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let articles: [ArmCareArticle] = try await client.client
                .from("arm_care_education")
                .select()
                .eq("slug", value: slug)
                .eq("is_published", value: true)
                .execute()
                .value

            return articles.first
        } catch {
            let errorMessage = "Failed to fetch article: \(slug)"
            self.error = errorMessage
            errorLogger.logDatabaseError(error, table: "arm_care_education")
            throw ArmCareEducationError.fetchFailed(error)
        }
    }

    /// Fetch a single article by its UUID
    /// - Parameter id: The article UUID
    /// - Returns: The article if found
    func fetchArticle(id: UUID) async throws -> ArmCareArticle? {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let articles: [ArmCareArticle] = try await client.client
                .from("arm_care_education")
                .select()
                .eq("id", value: id.uuidString)
                .eq("is_published", value: true)
                .execute()
                .value

            return articles.first
        } catch {
            let errorMessage = "Failed to fetch article by ID"
            self.error = errorMessage
            errorLogger.logDatabaseError(error, table: "arm_care_education")
            throw ArmCareEducationError.fetchFailed(error)
        }
    }

    /// Search articles by query text
    /// Searches in title, summary, and content fields
    /// - Parameter query: The search query
    /// - Returns: Array of matching articles
    func searchArticles(query: String) async throws -> [ArmCareArticle] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return articles
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Use ilike for case-insensitive search across multiple fields
            let searchPattern = "%\(query)%"

            let results: [ArmCareArticle] = try await client.client
                .from("arm_care_education")
                .select()
                .eq("is_published", value: true)
                .or("title.ilike.\(searchPattern),summary.ilike.\(searchPattern),content.ilike.\(searchPattern)")
                .order("sort_order", ascending: true)
                .execute()
                .value

            return results
        } catch {
            let errorMessage = "Failed to search articles"
            self.error = errorMessage
            errorLogger.logDatabaseError(error, table: "arm_care_education")
            throw ArmCareEducationError.searchFailed(error)
        }
    }

    /// Fetch articles related to specific exercises
    /// - Parameter exerciseIds: Array of exercise template UUIDs
    /// - Returns: Array of articles that reference these exercises
    func fetchArticles(relatedTo exerciseIds: [UUID]) async throws -> [ArmCareArticle] {
        guard !exerciseIds.isEmpty else {
            return []
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Use contains operator for JSON array column
            let idStrings = exerciseIds.map { $0.uuidString }

            let results: [ArmCareArticle] = try await client.client
                .from("arm_care_education")
                .select()
                .eq("is_published", value: true)
                .contains("related_exercises", value: idStrings)
                .order("sort_order", ascending: true)
                .execute()
                .value

            return results
        } catch {
            let errorMessage = "Failed to fetch related articles"
            self.error = errorMessage
            errorLogger.logDatabaseError(error, table: "arm_care_education")
            throw ArmCareEducationError.fetchFailed(error)
        }
    }

    /// Clear the articles cache
    func clearCache() {
        articlesCache.removeAll()
        lastCacheUpdate = nil
    }

    /// Get articles grouped by category
    /// - Returns: Dictionary mapping categories to their articles
    func getArticlesByCategory() async throws -> [ArmCareCategory: [ArmCareArticle]] {
        if articles.isEmpty {
            try await fetchAllArticles()
        }

        var grouped: [ArmCareCategory: [ArmCareArticle]] = [:]
        for article in articles {
            grouped[article.category, default: []].append(article)
        }

        return grouped
    }
}

// MARK: - Models

/// Category types for arm care education articles
enum ArmCareCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case anatomy = "anatomy"
    case injuryPrevention = "injury_prevention"
    case recovery = "recovery"
    case technique = "technique"
    case programming = "programming"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anatomy: return "Anatomy"
        case .injuryPrevention: return "Injury Prevention"
        case .recovery: return "Recovery"
        case .technique: return "Technique"
        case .programming: return "Programming"
        }
    }

    var icon: String {
        switch self {
        case .anatomy: return "figure.arms.open"
        case .injuryPrevention: return "shield.checkered"
        case .recovery: return "bed.double.fill"
        case .technique: return "figure.baseball"
        case .programming: return "calendar"
        }
    }

    var description: String {
        switch self {
        case .anatomy:
            return "Learn about the muscles, joints, and structures involved in throwing"
        case .injuryPrevention:
            return "Strategies and exercises to keep your arm healthy"
        case .recovery:
            return "Post-throwing recovery protocols and techniques"
        case .technique:
            return "Proper form and mechanics for arm care exercises"
        case .programming:
            return "How to structure your arm care routine"
        }
    }
}

/// Arm care education article from the arm_care_education table
struct ArmCareArticle: Codable, Identifiable, Hashable {
    let id: UUID
    let category: ArmCareCategory
    let title: String
    let slug: String
    let summary: String
    let content: String
    let keyPoints: [String]?
    let featuredImageUrl: String?
    let videoUrl: String?
    let relatedExercises: [UUID]?
    let relatedArticles: [UUID]?
    let sortOrder: Int
    let isFeatured: Bool
    let isPublished: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case title
        case slug
        case summary
        case content
        case keyPoints = "key_points"
        case featuredImageUrl = "featured_image_url"
        case videoUrl = "video_url"
        case relatedExercises = "related_exercises"
        case relatedArticles = "related_articles"
        case sortOrder = "sort_order"
        case isFeatured = "is_featured"
        case isPublished = "is_published"
    }

    /// Estimated reading time in minutes based on word count
    var estimatedReadingTime: Int {
        let wordCount = content.split(separator: " ").count
        let wordsPerMinute = 200
        return max(1, wordCount / wordsPerMinute)
    }

    /// Whether the article has video content
    var hasVideo: Bool {
        videoUrl != nil && !videoUrl!.isEmpty
    }

    /// Whether the article has related exercises
    var hasRelatedExercises: Bool {
        guard let exercises = relatedExercises else { return false }
        return !exercises.isEmpty
    }
}

// MARK: - Errors

/// Errors for ArmCareEducationService operations
enum ArmCareEducationError: LocalizedError {
    case fetchFailed(Error)
    case searchFailed(Error)
    case notFound

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch arm care content: \(error.localizedDescription)"
        case .searchFailed(let error):
            return "Failed to search arm care content: \(error.localizedDescription)"
        case .notFound:
            return "Article not found"
        }
    }
}
