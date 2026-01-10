//
//  LearningView.swift
//  PTPerformance
//
//  Main learning interface with search and category filtering
//

import SwiftUI

struct LearningView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var contentLoader = LearningContentLoader.shared
    @State private var searchText = ""
    @State private var selectedCategory: LearningCategory?
    @State private var showCategoryBrowser = false

    var filteredArticles: [LearningArticle] {
        var articles = contentLoader.articles

        // Filter by category if selected
        if let category = selectedCategory {
            articles = articles.filter { $0.category == category }
        }

        // Filter by search text
        if !searchText.isEmpty {
            articles = articles.filter { $0.matches(searchText: searchText) }
        }

        return articles
    }

    var articlesByCategory: [LearningCategory: [LearningArticle]] {
        Dictionary(grouping: filteredArticles) { $0.category }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if contentLoader.isLoading {
                    loadingState
                } else if filteredArticles.isEmpty {
                    emptyState
                } else if searchText.isEmpty && selectedCategory == nil {
                    // Show category sections when not searching
                    categorizedList
                } else {
                    // Show flat list when searching
                    searchResultsList
                }
            }
            .navigationTitle("Learning Center")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search articles..."
            )
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCategoryBrowser = true
                    } label: {
                        Image(systemName: "square.grid.2x2")
                    }
                }
            }
            .sheet(isPresented: $showCategoryBrowser) {
                LearningCategoryView()
            }
            .refreshable {
                contentLoader.reload()
            }
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading articles...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Categorized List (Default View)

    private var categorizedList: some View {
        List {
            // Header section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "book.fill")
                            .font(.title)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(contentLoader.articles.count) Articles")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Baseball training & performance")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }

            // Quick actions
            Section {
                NavigationLink {
                    LearningCategoryView()
                } label: {
                    Label("Browse by Category", systemImage: "square.grid.2x2.fill")
                        .foregroundColor(.blue)
                }
            } header: {
                Text("Quick Access")
            }

            // Category filter chips
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // All categories chip
                        LearningFilterChip(
                            title: "All",
                            icon: "square.stack.3d.up.fill",
                            isSelected: selectedCategory == nil,
                            color: .blue
                        ) {
                            selectedCategory = nil
                        }

                        // Category chips
                        ForEach(LearningCategory.allCases, id: \.self) { category in
                            LearningFilterChip(
                                title: category.rawValue,
                                icon: category.icon,
                                isSelected: selectedCategory == category,
                                color: categoryColor(category)
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .listRowInsets(EdgeInsets())
            }

            // Articles by category
            ForEach(LearningCategory.allCases, id: \.self) { category in
                if let articles = articlesByCategory[category], !articles.isEmpty {
                    Section {
                        ForEach(articles) { article in
                            NavigationLink {
                                LearningArticleView(article: article)
                            } label: {
                                LearningArticleRowView(article: article)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(categoryColor(category))
                            Text(category.rawValue)
                        }
                    }
                }
            }

            // Footer
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("About Learning Center")
                        .font(.headline)

                    Text("Access expert-written articles on baseball training, performance, recovery, and more. Content is regularly updated based on the latest research and best practices.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Search Results List

    private var searchResultsList: some View {
        List {
            Section {
                ForEach(filteredArticles) { article in
                    NavigationLink {
                        LearningArticleView(article: article)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            // Category badge
                            HStack {
                                Image(systemName: article.category.icon)
                                    .font(.caption2)
                                Text(article.category.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.medium)

                                if let subcategory = article.subcategory {
                                    Text("•")
                                        .font(.caption2)
                                    Text(subcategory)
                                        .font(.caption2)
                                }

                                Spacer()

                                if let readingTime = article.readingTimeMinutes {
                                    Text("\(readingTime) min")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .foregroundColor(categoryColor(article.category))

                            // Article title
                            Text(article.title)
                                .font(.headline)
                                .foregroundColor(.primary)

                            // Excerpt or keywords
                            if let excerpt = article.excerpt {
                                Text(excerpt)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            } else if !article.keywords.isEmpty {
                                Text(article.keywords.prefix(5).joined(separator: " • "))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("\(filteredArticles.count) result\(filteredArticles.count == 1 ? "" : "s")")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Articles Found", systemImage: "magnifyingglass")
        } description: {
            Text("Try adjusting your search or browse by category")
        } actions: {
            Button("Clear Search") {
                searchText = ""
                selectedCategory = nil
            }
            .buttonStyle(.borderedProminent)

            Button("Browse Categories") {
                showCategoryBrowser = true
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Helpers

    private func categoryColor(_ category: LearningCategory) -> Color {
        switch category {
        case .armCare:
            return .blue
        case .hitting:
            return .green
        case .injuryPrevention:
            return .red
        case .mental:
            return .purple
        case .mobility:
            return .orange
        case .nutrition:
            return .green
        case .preparation:
            return .cyan
        case .recovery:
            return .indigo
        case .speed:
            return .yellow
        case .training:
            return .red
        case .warmup:
            return .orange
        }
    }
}

// MARK: - Article Row View

struct LearningArticleRowView: View {
    let article: LearningArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(article.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                if let readingTime = article.readingTimeMinutes {
                    Text("\(readingTime)m")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if let subcategory = article.subcategory {
                Text(subcategory)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !article.keywords.isEmpty {
                Text(article.keywords.prefix(3).joined(separator: " • "))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Filter Chip

struct LearningFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
