//
//  LearningView.swift
//  PTPerformance
//
//  Main learning interface with search and category filtering
//  Updated: Added error state and improved loading skeleton
//

import SwiftUI

struct LearningView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var contentLoader = LearningContentLoader.shared
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
                if contentLoader.isLoading && contentLoader.articles.isEmpty {
                    // Show skeleton loading state
                    learningLoadingState
                } else if let error = contentLoader.error, contentLoader.articles.isEmpty {
                    // Show error state when loading failed and no cached articles
                    learningErrorState(error)
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
                    .accessibilityLabel("Browse categories")
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

    // MARK: - Loading State (Skeleton)

    private var learningLoadingState: some View {
        List {
            // Header section skeleton
            Section {
                HStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 18)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 160, height: 12)
                    }

                    Spacer()
                }
                .padding(.vertical, Spacing.xs)
            }

            // Quick access skeleton
            Section {
                LearningArticleSkeletonRow()
            } header: {
                Text("Quick Access")
            }

            // Category chips skeleton
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 90, height: 32)
                        }
                    }
                    .padding(.horizontal, Spacing.xxs)
                }
                .listRowInsets(EdgeInsets())
            }

            // Article sections skeleton
            ForEach(0..<3, id: \.self) { _ in
                Section {
                    ForEach(0..<3, id: \.self) { _ in
                        LearningArticleSkeletonRow()
                    }
                } header: {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 16, height: 16)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 12)
                    }
                }
            }
        }
    }

    // MARK: - Error State

    private func learningErrorState(_ error: String) -> some View {
        ContentUnavailableView {
            Label("Unable to Load Articles", systemImage: "exclamationmark.triangle")
        } description: {
            Text("We couldn't load learning articles. Please check your connection and try again.")
        } actions: {
            Button {
                contentLoader.reload()
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
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
                            .foregroundColor(.modusCyan)

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
                    .padding(.vertical, Spacing.xs)
                }
            }

            // Quick actions
            Section {
                NavigationLink {
                    LearningCategoryView()
                } label: {
                    Label("Browse by Category", systemImage: "square.grid.2x2.fill")
                        .foregroundColor(.modusCyan)
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
                    .padding(.horizontal, Spacing.xxs)
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
                .padding(.vertical, Spacing.xs)
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
                        .padding(.vertical, Spacing.xxs)
                    }
                }
            } header: {
                Text("\(filteredArticles.count) result\(filteredArticles.count == 1 ? "" : "s")")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        Group {
            if !searchText.isEmpty {
                // Search has no matches - show query in message
                ContentUnavailableView {
                    Label("No Results for '\(searchText)'", systemImage: "magnifyingglass")
                } description: {
                    Text("No articles match your search. Try different keywords or browse by category.")
                } actions: {
                    Button("Clear Search") {
                        searchText = ""
                        selectedCategory = nil
                    }
                    .buttonStyle(.bordered)
                }
            } else if let category = selectedCategory {
                // Category filter has no results
                ContentUnavailableView {
                    Label("No Articles in \(category.rawValue)", systemImage: "folder")
                } description: {
                    Text("No articles are available in this category yet. Try browsing other categories.")
                } actions: {
                    Button("Clear Filter") {
                        selectedCategory = nil
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                // No articles loaded at all
                ContentUnavailableView {
                    Label("Learning Center", systemImage: "book.closed.fill")
                } description: {
                    Text("Educational articles about baseball training, performance, recovery, and injury prevention will appear here. Check back soon for new content.")
                } actions: {
                    Button {
                        showCategoryBrowser = true
                    } label: {
                        Label("Browse Categories", systemImage: "square.grid.2x2")
                    }
                    .buttonStyle(.bordered)
                }
            }
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
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? color : Color(.tertiarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(CornerRadius.xl)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Skeleton View

struct LearningArticleSkeletonRow: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Title skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 14)
                    .shimmer(isAnimating: isAnimating)

                Spacer()

                // Reading time skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 30, height: 10)
                    .shimmer(isAnimating: isAnimating)
            }

            // Subcategory skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 10)
                .shimmer(isAnimating: isAnimating)

            // Keywords skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 140, height: 10)
                .shimmer(isAnimating: isAnimating)
        }
        .padding(.vertical, 2)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}
