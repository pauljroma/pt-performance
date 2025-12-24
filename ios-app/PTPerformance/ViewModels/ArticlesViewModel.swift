//
//  ArticlesViewModel.swift
//  PTPerformance
//
//  Manages article browsing, search, and interactions
//  Created: 2025-12-20
//

import Foundation
import Supabase
import Combine

@MainActor
class ArticlesViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var searchResults: [ContentSearchResult] = []
    @Published var featuredArticles: [ContentSearchResult] = []
    @Published var recentlyViewed: [ContentSearchResult] = []
    @Published var selectedCategory: ArticleCategory?
    @Published var selectedDifficulty: ContentItem.Difficulty?
    @Published var searchQuery: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let supabase: SupabaseClient
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(supabase: SupabaseClient) {
        self.supabase = supabase
        setupSearchDebounce()
    }

    // MARK: - Setup

    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                Task {
                    await self?.performSearch()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Load featured articles (high view count, high helpful rating)
    func loadFeaturedArticles() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await supabase
                .rpc("search_content", params: [
                    "p_query": "",
                    "p_content_type": "article",
                    "p_category": nil as String?,
                    "p_difficulty": nil as String?,
                    "p_tags": nil as [String]?,
                    "p_limit": 10,
                    "p_offset": 0
                ])
                .execute()

            let articles = try JSONDecoder().decode([ContentSearchResult].self, from: response.data)

            // Sort by view count and helpful count
            featuredArticles = articles.sorted { a, b in
                (a.viewCount + a.helpfulCount) > (b.viewCount + b.helpfulCount)
            }

            isLoading = false
        } catch {
            errorMessage = "Failed to load featured articles: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Perform search with filters
    func performSearch() async {
        // Cancel previous search
        searchTask?.cancel()

        searchTask = Task {
            isLoading = true
            errorMessage = nil

            do {
                let response = try await supabase
                    .rpc("search_content", params: [
                        "p_query": searchQuery.isEmpty ? nil : searchQuery,
                        "p_content_type": "article",
                        "p_category": selectedCategory?.rawValue,
                        "p_difficulty": selectedDifficulty?.rawValue,
                        "p_tags": nil as [String]?,
                        "p_limit": 50,
                        "p_offset": 0
                    ])
                    .execute()

                if !Task.isCancelled {
                    searchResults = try JSONDecoder().decode([ContentSearchResult].self, from: response.data)
                }

                isLoading = false
            } catch {
                if !Task.isCancelled {
                    errorMessage = "Search failed: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    /// Get full article detail
    func getArticle(slug: String) async throws -> ContentItem {
        let response = try await supabase
            .from("content_items")
            .select("*")
            .eq("slug", value: slug)
            .single()
            .execute()

        return try JSONDecoder().decode(ContentItem.self, from: response.data)
    }

    /// Track article view
    func trackView(articleId: UUID, userId: UUID?, searchQuery: String?) async {
        do {
            // Insert interaction
            try await supabase
                .from("content_interactions")
                .insert([
                    "content_item_id": articleId.uuidString,
                    "user_id": userId?.uuidString as Any,
                    "interaction_type": "view",
                    "search_query": searchQuery as Any
                ])
                .execute()

            // Increment view count (optimistic)
            if let index = searchResults.firstIndex(where: { $0.id == articleId }) {
                searchResults[index] = ContentSearchResult(
                    id: searchResults[index].id,
                    slug: searchResults[index].slug,
                    title: searchResults[index].title,
                    category: searchResults[index].category,
                    excerpt: searchResults[index].excerpt,
                    difficulty: searchResults[index].difficulty,
                    estimatedDurationMinutes: searchResults[index].estimatedDurationMinutes,
                    viewCount: searchResults[index].viewCount + 1,
                    helpfulCount: searchResults[index].helpfulCount,
                    rank: searchResults[index].rank
                )
            }
        } catch {
            print("Failed to track view: \(error)")
        }
    }

    /// Mark article as helpful
    func markHelpful(articleId: UUID, userId: UUID) async throws {
        // Insert helpful interaction
        try await supabase
            .from("content_interactions")
            .insert([
                "content_item_id": articleId.uuidString,
                "user_id": userId.uuidString,
                "interaction_type": "helpful"
            ])
            .execute()

        // Increment helpful count on the article
        try await supabase
            .from("content_items")
            .update(["helpful_count": ["increment": 1]])
            .eq("id", value: articleId)
            .execute()

        // Update local cache optimistically
        if let index = searchResults.firstIndex(where: { $0.id == articleId }) {
            searchResults[index] = ContentSearchResult(
                id: searchResults[index].id,
                slug: searchResults[index].slug,
                title: searchResults[index].title,
                category: searchResults[index].category,
                excerpt: searchResults[index].excerpt,
                difficulty: searchResults[index].difficulty,
                estimatedDurationMinutes: searchResults[index].estimatedDurationMinutes,
                viewCount: searchResults[index].viewCount,
                helpfulCount: searchResults[index].helpfulCount + 1,
                rank: searchResults[index].rank
            )
        }
    }

    /// Bookmark article
    func bookmarkArticle(articleId: UUID, userId: UUID) async throws {
        try await supabase
            .from("content_interactions")
            .insert([
                "content_item_id": articleId.uuidString,
                "user_id": userId.uuidString,
                "interaction_type": "bookmark"
            ])
            .execute()
    }

    /// Get user's bookmarked articles
    func getBookmarkedArticles(userId: UUID) async throws -> [ContentSearchResult] {
        // Get bookmarked content item IDs
        let interactionsResponse = try await supabase
            .from("content_interactions")
            .select("content_item_id")
            .eq("user_id", value: userId)
            .eq("interaction_type", value: "bookmark")
            .execute()

        struct BookmarkInteraction: Codable {
            let contentItemId: UUID

            enum CodingKeys: String, CodingKey {
                case contentItemId = "content_item_id"
            }
        }

        let interactions = try JSONDecoder().decode([BookmarkInteraction].self, from: interactionsResponse.data)
        let articleIds = interactions.map { $0.contentItemId.uuidString }

        if articleIds.isEmpty {
            return []
        }

        // Get the articles
        let articlesResponse = try await supabase
            .from("content_items")
            .select("""
                id, slug, title, category, excerpt, difficulty,
                estimated_duration_minutes, view_count, helpful_count
            """)
            .in("id", values: articleIds)
            .execute()

        return try JSONDecoder().decode([ContentSearchResult].self, from: articlesResponse.data)
    }

    /// Clear filters
    func clearFilters() {
        selectedCategory = nil
        selectedDifficulty = nil
        searchQuery = ""
        Task {
            await performSearch()
        }
    }

    /// Get articles by category
    func getArticlesByCategory(_ category: ArticleCategory) async {
        selectedCategory = category
        await performSearch()
    }
}

// MARK: - Progress Tracking Extension

extension ArticlesViewModel {
    /// Get user progress for an article
    func getUserProgress(articleId: UUID, userId: UUID) async throws -> UserProgress? {
        let response = try await supabase
            .from("user_progress")
            .select("*")
            .eq("user_id", value: userId)
            .eq("content_item_id", value: articleId)
            .maybeSingle()
            .execute()

        guard !response.data.isEmpty else {
            return nil
        }

        return try JSONDecoder().decode(UserProgress.self, from: response.data)
    }

    /// Update user progress
    func updateProgress(
        articleId: UUID,
        userId: UUID,
        status: UserProgress.ProgressStatus,
        percentage: Int = 0
    ) async throws {
        let now = ISO8601DateFormatter().string(from: Date())

        var updateData: [String: Any] = [
            "user_id": userId.uuidString,
            "content_item_id": articleId.uuidString,
            "status": status.rawValue,
            "progress_percentage": percentage,
            "last_accessed_at": now
        ]

        if status == .inProgress, percentage == 0 {
            updateData["started_at"] = now
        }

        if status == .completed {
            updateData["completed_at"] = now
            updateData["progress_percentage"] = 100
        }

        try await supabase
            .from("user_progress")
            .upsert(updateData)
            .execute()
    }

    /// Mark article as started
    func markStarted(articleId: UUID, userId: UUID) async throws {
        try await updateProgress(articleId: articleId, userId: userId, status: .inProgress, percentage: 0)
    }

    /// Mark article as completed
    func markCompleted(articleId: UUID, userId: UUID) async throws {
        try await updateProgress(articleId: articleId, userId: userId, status: .completed, percentage: 100)
    }
}
