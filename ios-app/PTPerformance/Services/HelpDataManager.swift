import Foundation

/// Service for managing help article data
/// Loads articles from local JSON and provides search/filter functionality
@MainActor
class HelpDataManager: ObservableObject {
    // MARK: - Published Properties

    @Published var articles: [HelpArticle] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private var allArticles: [HelpArticle] = []
    private let cacheKey = "cached_help_articles"
    private let cacheTimestampKey = "help_articles_cache_timestamp"
    private let cacheValidityHours: Double = 24

    // MARK: - Singleton

    static let shared = HelpDataManager()

    private init() {
        loadArticles()
    }

    // MARK: - Public Methods

    /// Load articles from JSON file
    func loadArticles() {
        isLoading = true
        error = nil

        // Check cache first
        if let cachedArticles = loadFromCache(), !cachedArticles.isEmpty {
            self.articles = cachedArticles
            self.allArticles = cachedArticles
            self.isLoading = false
            return
        }

        // Load from JSON file
        guard let url = Bundle.main.url(forResource: "help_articles", withExtension: "json") else {
            self.error = HelpDataError.fileNotFound
            self.isLoading = false
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let loadedArticles = try decoder.decode([HelpArticle].self, from: data)

            self.articles = loadedArticles
            self.allArticles = loadedArticles
            self.isLoading = false

            // Cache the loaded articles
            saveToCache(loadedArticles)

            print("[HelpDataManager] Loaded \(loadedArticles.count) help articles")
        } catch {
            self.error = HelpDataError.decodingFailed(error)
            self.isLoading = false
            print("[HelpDataManager] Error loading articles: \(error)")
        }
    }

    /// Search articles by term with relevance scoring
    /// - Parameter searchTerm: The search term to filter by
    /// - Returns: Array of articles sorted by relevance
    func search(term searchTerm: String) -> [HelpArticle] {
        guard !searchTerm.isEmpty else {
            return allArticles
        }

        // Filter articles that match the search term
        let matchingArticles = allArticles.filter { article in
            article.matches(searchTerm: searchTerm)
        }

        // Sort by relevance score (highest first)
        let sortedArticles = matchingArticles.sorted { article1, article2 in
            let score1 = article1.relevanceScore(for: searchTerm)
            let score2 = article2.relevanceScore(for: searchTerm)
            return score1 > score2
        }

        return sortedArticles
    }

    /// Filter articles by category
    /// - Parameter category: Category to filter by
    /// - Returns: Array of articles in the specified category
    func filterByCategory(_ category: String) -> [HelpArticle] {
        guard !category.isEmpty else {
            return allArticles
        }

        return allArticles.filter { $0.category.lowercased() == category.lowercased() }
    }

    /// Get article by ID
    /// - Parameter id: Article ID
    /// - Returns: Article if found, nil otherwise
    func getArticle(by id: String) -> HelpArticle? {
        return allArticles.first { $0.id == id }
    }

    /// Get related articles for a given article
    /// - Parameter article: The article to find related articles for
    /// - Returns: Array of related articles
    func getRelatedArticles(for article: HelpArticle) -> [HelpArticle] {
        guard let relatedIds = article.relatedArticleIds else {
            return []
        }

        return relatedIds.compactMap { id in
            getArticle(by: id)
        }
    }

    /// Get all unique categories
    /// - Returns: Array of category names
    func getCategories() -> [String] {
        let categories = Set(allArticles.map { $0.category })
        return Array(categories).sorted()
    }

    /// Refresh articles from JSON (bypasses cache)
    func refresh() {
        clearCache()
        loadArticles()
    }

    // MARK: - Private Methods - Caching

    private func loadFromCache() -> [HelpArticle]? {
        // Check if cache is still valid
        if let timestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date {
            let hoursSinceCache = Date().timeIntervalSince(timestamp) / 3600
            if hoursSinceCache > cacheValidityHours {
                return nil // Cache expired
            }
        } else {
            return nil // No timestamp, cache invalid
        }

        // Load from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let articles = try decoder.decode([HelpArticle].self, from: data)
            print("[HelpDataManager] Loaded \(articles.count) articles from cache")
            return articles
        } catch {
            print("[HelpDataManager] Cache decode error: \(error)")
            return nil
        }
    }

    private func saveToCache(_ articles: [HelpArticle]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(articles)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
            print("[HelpDataManager] Cached \(articles.count) articles")
        } catch {
            print("[HelpDataManager] Cache save error: \(error)")
        }
    }

    private func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
        print("[HelpDataManager] Cache cleared")
    }
}

// MARK: - Error Types

enum HelpDataError: LocalizedError {
    case fileNotFound
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Help articles file not found. Please contact support."
        case .decodingFailed(let error):
            return "Failed to load help articles: \(error.localizedDescription)"
        }
    }
}

// MARK: - Performance Metrics

extension HelpDataManager {
    /// Measure search performance
    func measureSearchPerformance(for term: String) -> (results: [HelpArticle], duration: TimeInterval) {
        let startTime = Date()
        let results = search(term: term)
        let duration = Date().timeIntervalSince(startTime)

        print("[HelpDataManager] Search for '\(term)' took \(String(format: "%.3f", duration))s, found \(results.count) results")

        return (results, duration)
    }
}
