import SwiftUI

/// Searchable help interface with category filtering
struct HelpSearchView: View {
    @StateObject private var dataManager = HelpDataManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: String = ""
    @State private var searchResults: [HelpArticle] = []
    @State private var isSearching = false
    @State private var searchDuration: TimeInterval = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if dataManager.isLoading {
                    ProgressView("Loading help articles...")
                        .padding()
                } else if let error = dataManager.error {
                    ErrorView(message: error.localizedDescription) {
                        dataManager.refresh()
                    }
                } else {
                    // Category filter
                    CategoryFilterView(
                        categories: dataManager.getCategories(),
                        selectedCategory: $selectedCategory
                    )

                    // Search results or article list
                    if isSearching || !searchText.isEmpty {
                        SearchResultsView(
                            results: searchResults,
                            searchTerm: searchText,
                            searchDuration: searchDuration
                        )
                    } else if !selectedCategory.isEmpty {
                        ArticleListView(
                            articles: dataManager.filterByCategory(selectedCategory),
                            title: selectedCategory
                        )
                    } else {
                        ArticlesByCategory(articles: dataManager.articles)
                    }
                }
            }
            .navigationTitle("Help & Support")
            .searchable(text: $searchText, prompt: "Search help articles")
            .onChange(of: searchText) { newValue in
                performSearch(newValue)
            }
            .onChange(of: selectedCategory) { _ in
                searchText = "" // Clear search when category changes
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dataManager.refresh()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }

    // MARK: - Search Logic

    private func performSearch(_ term: String) {
        guard !term.isEmpty else {
            isSearching = false
            searchResults = []
            searchDuration = 0
            return
        }

        isSearching = true

        // Measure search performance
        let startTime = Date()
        let results = dataManager.search(term: term)
        let duration = Date().timeIntervalSince(startTime)

        searchResults = results
        searchDuration = duration

        // Log performance (must be under 3 seconds)
        if duration > 3.0 {
            print("[HelpSearchView] WARNING: Search took \(String(format: "%.3f", duration))s (exceeds 3s requirement)")
        }
    }
}

// MARK: - Category Filter View

struct CategoryFilterView: View {
    let categories: [String]
    @Binding var selectedCategory: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All" button
                CategoryChip(
                    title: "All",
                    isSelected: selectedCategory.isEmpty
                ) {
                    selectedCategory = ""
                }

                // Category buttons
                ForEach(categories, id: \.self) { category in
                    CategoryChip(
                        title: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category == selectedCategory ? "" : category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Search Results View

struct SearchResultsView: View {
    let results: [HelpArticle]
    let searchTerm: String
    let searchDuration: TimeInterval

    var body: some View {
        VStack(spacing: 0) {
            // Search metadata
            HStack {
                Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if searchDuration > 0 {
                    Text(String(format: "%.2fs", searchDuration))
                        .font(.caption)
                        .foregroundColor(searchDuration > 3.0 ? .red : .secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))

            if results.isEmpty {
                EmptySearchView(searchTerm: searchTerm)
            } else {
                List(results) { article in
                    NavigationLink(destination: HelpArticleView(article: article)) {
                        SearchResultRow(article: article, searchTerm: searchTerm)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct SearchResultRow: View {
    let article: HelpArticle
    let searchTerm: String

    private var relevanceScore: Double {
        article.relevanceScore(for: searchTerm)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title with relevance indicator
            HStack {
                Text(article.title)
                    .font(.headline)

                Spacer()

                // Show relevance score for debugging (remove in production)
                if relevanceScore > 0 {
                    Text(String(format: "%.0f", relevanceScore))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
            }

            // Category badge
            Text(article.category)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)

            // Content preview (first 100 characters)
            let plainText = article.content.replacingOccurrences(of: "#", with: "")
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            Text(plainText.prefix(100) + (plainText.count > 100 ? "..." : ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

struct EmptySearchView: View {
    let searchTerm: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No results found")
                .font(.headline)

            Text("Try a different search term or browse by category")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Article List View

struct ArticleListView: View {
    let articles: [HelpArticle]
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            if articles.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("No articles in this category")
                        .font(.headline)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(articles) { article in
                    NavigationLink(destination: HelpArticleView(article: article)) {
                        ArticleRow(article: article)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct ArticleRow: View {
    let article: HelpArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(article.title)
                .font(.headline)

            HStack {
                Text(article.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)

                Spacer()

                Text("Updated \(article.formattedLastUpdated)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Articles by Category View

struct ArticlesByCategory: View {
    let articles: [HelpArticle]

    private var groupedArticles: [(category: String, articles: [HelpArticle])] {
        let grouped = Dictionary(grouping: articles) { $0.category }
        return grouped.map { (category: $0.key, articles: $0.value) }
            .sorted { $0.category < $1.category }
    }

    var body: some View {
        List {
            ForEach(groupedArticles, id: \.category) { group in
                Section(header: Text(group.category)) {
                    ForEach(group.articles) { article in
                        NavigationLink(destination: HelpArticleView(article: article)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(article.title)
                                    .font(.headline)

                                Text("Updated \(article.formattedLastUpdated)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Error Loading Help")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: retry) {
                Text("Retry")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

struct HelpSearchView_Previews: PreviewProvider {
    static var previews: some View {
        HelpSearchView()
    }
}
