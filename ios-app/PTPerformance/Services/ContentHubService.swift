//
//  ContentHubService.swift
//  PTPerformance
//
//  ACP-1001: Content Marketing Engine — In-app content/education hub
//  Manages educational articles with premium gating and category filtering.
//

import Foundation

// MARK: - Content Hub Service

/// Manages the in-app content and education hub.
///
/// Fetches educational articles from Supabase, supports category filtering,
/// and enforces premium gating (free users see a limited number of articles).
/// Articles are sorted by publication date with featured content prioritized.
///
/// ## Content Strategy
/// - Free users: 3 articles visible (tease premium content)
/// - Premium users: Full access to all articles
/// - Featured articles rotate based on recency and editorial curation
///
/// ## Usage
/// ```swift
/// let service = ContentHubService.shared
/// await service.fetchArticles()
///
/// // Filter by category
/// await service.fetchArticles(category: .recovery)
///
/// // Check premium gating
/// let visibleArticles = service.visibleArticles(isPremium: storeKit.isPremium)
/// ```
@MainActor
class ContentHubService: ObservableObject {

    // MARK: - Singleton

    static let shared = ContentHubService()

    // MARK: - Dependencies

    private let supabase: PTSupabaseClient
    private let logger: DebugLogger

    // MARK: - Constants

    private enum Constants {
        static let articlesTable = "content_articles"
        static let freeArticleLimit = 3
        static let cacheKey = "cached_content_articles"
        static let cacheExpirySeconds: TimeInterval = 3600 // 1 hour
    }

    // MARK: - Published Properties

    /// All fetched articles
    @Published var articles: [ContentArticle] = []

    /// The featured article (highest priority for display)
    @Published var featuredArticle: ContentArticle?

    /// Currently selected category filter
    @Published var selectedCategory: ContentCategory?

    /// Loading state
    @Published var isLoading = false

    /// Error message
    @Published var errorMessage: String?

    // MARK: - Computed Properties

    /// Articles filtered by the selected category
    var filteredArticles: [ContentArticle] {
        guard let category = selectedCategory else {
            return articles
        }
        return articles.filter { $0.category == category }
    }

    /// Total article count
    var totalCount: Int {
        articles.count
    }

    /// Count of premium-only articles
    var premiumCount: Int {
        articles.filter { $0.isPremium }.count
    }

    // MARK: - Initialization

    init(
        supabase: PTSupabaseClient = .shared,
        logger: DebugLogger = .shared
    ) {
        self.supabase = supabase
        self.logger = logger
        logger.info("ContentHubService", "Initializing content hub service")
    }

    // MARK: - Fetch Articles

    /// Fetches articles from Supabase with optional category filtering.
    ///
    /// - Parameter category: Optional category to filter by. Pass `nil` for all articles.
    func fetchArticles(category: ContentCategory? = nil) async {
        logger.diagnostic("ContentHubService: Fetching articles (category: \(category?.displayName ?? "all"))")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var query = supabase.client
                .from(Constants.articlesTable)
                .select()

            if let category = category {
                query = query.eq("category", value: category.rawValue)
            }

            let response = try await query
                .order("is_featured", ascending: false)
                .order("published_at", ascending: false)
                .execute()

            let decoder = PTSupabaseClient.flexibleDecoder
            let fetched = try decoder.decode([ContentArticle].self, from: response.data)

            articles = fetched
            featuredArticle = fetched.first(where: { $0.isFeatured })

            // Cache articles for offline access
            cacheArticles(fetched)

            logger.success("ContentHubService", "Fetched \(fetched.count) articles")
        } catch {
            logger.warning("ContentHubService", "Failed to fetch articles: \(error.localizedDescription). Using cached/demo data.")

            // Try cached data first
            if let cached = loadCachedArticles() {
                articles = cached
                featuredArticle = cached.first(where: { $0.isFeatured })
                logger.info("ContentHubService", "Loaded \(cached.count) cached articles")
            } else {
                articles = ContentArticle.demoArticles
                featuredArticle = ContentArticle.demoArticles.first(where: { $0.isFeatured })
                logger.info("ContentHubService", "Using demo articles")
            }
        }
    }

    // MARK: - Visible Articles (Premium Gating)

    /// Returns the articles visible to the current user based on their premium status.
    ///
    /// Free users see up to `Constants.freeArticleLimit` free articles.
    /// Premium users see all articles.
    ///
    /// - Parameter isPremium: Whether the user has a premium subscription
    /// - Returns: Array of visible articles
    func visibleArticles(isPremium: Bool) -> [ContentArticle] {
        let filtered = filteredArticles

        if isPremium {
            return filtered
        }

        // Free users: show only free articles, limited to freeArticleLimit
        let freeArticles = filtered.filter { !$0.isPremium }
        return Array(freeArticles.prefix(Constants.freeArticleLimit))
    }

    /// Returns the count of articles locked behind premium for the current filter.
    ///
    /// - Parameter isPremium: Whether the user has a premium subscription
    /// - Returns: Number of locked articles
    func lockedArticleCount(isPremium: Bool) -> Int {
        if isPremium { return 0 }
        let filtered = filteredArticles
        let freeCount = min(filtered.filter({ !$0.isPremium }).count, Constants.freeArticleLimit)
        return filtered.count - freeCount
    }

    // MARK: - Search

    /// Searches articles by title, summary, and tags.
    ///
    /// - Parameter query: Search query string
    /// - Returns: Matching articles sorted by relevance
    func searchArticles(query: String) -> [ContentArticle] {
        let lowercased = query.lowercased()
        return articles.filter { article in
            article.title.lowercased().contains(lowercased) ||
            article.summary.lowercased().contains(lowercased) ||
            article.tags.contains(where: { $0.lowercased().contains(lowercased) })
        }
    }

    // MARK: - Track Read

    /// Records that a user read an article, for analytics and recommendation tuning.
    ///
    /// - Parameter article: The article that was read
    func trackArticleRead(_ article: ContentArticle) {
        logger.info("ContentHubService", "User read article: \(article.title)")

        Task {
            guard let userId = supabase.userId else { return }

            do {
                try await supabase.client
                    .from("article_read_events")
                    .insert([
                        "user_id": userId,
                        "article_id": article.id,
                        "category": article.category.rawValue,
                        "is_premium": article.isPremium ? "true" : "false",
                        "read_at": ISO8601DateFormatter().string(from: Date())
                    ])
                    .execute()

                logger.success("ContentHubService", "Tracked article read: \(article.id)")
            } catch {
                logger.warning("ContentHubService", "Failed to track article read: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private: Caching

    private func cacheArticles(_ articles: [ContentArticle]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(articles)
            UserDefaults.standard.set(data, forKey: Constants.cacheKey)
            UserDefaults.standard.set(Date(), forKey: Constants.cacheKey + "_timestamp")
            logger.diagnostic("ContentHubService: Cached \(articles.count) articles")
        } catch {
            logger.warning("ContentHubService", "Failed to cache articles: \(error.localizedDescription)")
        }
    }

    private func loadCachedArticles() -> [ContentArticle]? {
        guard let data = UserDefaults.standard.data(forKey: Constants.cacheKey),
              let timestamp = UserDefaults.standard.object(forKey: Constants.cacheKey + "_timestamp") as? Date,
              Date().timeIntervalSince(timestamp) < Constants.cacheExpirySeconds else {
            return nil
        }

        do {
            let decoder = PTSupabaseClient.flexibleDecoder
            return try decoder.decode([ContentArticle].self, from: data)
        } catch {
            logger.warning("ContentHubService", "Failed to decode cached articles: \(error.localizedDescription)")
            return nil
        }
    }
}
