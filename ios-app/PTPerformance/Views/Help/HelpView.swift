//
//  HelpView.swift
//  PTPerformance
//
//  Main help interface with search and category filtering
//  Updated: Added error fallback and improved loading states
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var contentLoader = HelpContentLoader.shared
    @State private var searchText = ""
    @State private var selectedCategory: HelpCategory?
    @State private var showCategoryBrowser = false
    @State private var isSearching = false

    var filteredArticles: [HelpArticle] {
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

    var articlesByCategory: [HelpCategory: [HelpArticle]] {
        Dictionary(grouping: filteredArticles) { $0.category }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if contentLoader.isLoading && contentLoader.articles.isEmpty {
                    // Show skeleton loading state while initially loading articles
                    helpLoadingState
                } else if let error = contentLoader.error, contentLoader.articles.isEmpty {
                    // Show error state when loading failed and no cached articles
                    helpErrorState(error)
                } else if isSearching {
                    // Show loading state while searching
                    searchLoadingState
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
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search help articles..."
            )
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCategoryBrowser = true
                    } label: {
                        Image(systemName: "square.grid.2x2")
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCategoryBrowser) {
                HelpCategoryView()
            }
        }
    }

    // MARK: - Loading State

    private var helpLoadingState: some View {
        List {
            // Skeleton for quick access section
            Section {
                ForEach(0..<2, id: \.self) { _ in
                    HelpArticleSkeletonRow()
                }
            } header: {
                Text("Quick Access")
            }

            // Skeleton for category filter
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 16)
                                .fill(skeletonColor)
                                .frame(width: 80, height: 32)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .listRowInsets(EdgeInsets())
            }

            // Skeleton for article sections
            ForEach(0..<3, id: \.self) { _ in
                Section {
                    ForEach(0..<3, id: \.self) { _ in
                        HelpArticleSkeletonRow()
                    }
                } header: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(skeletonColor)
                        .frame(width: 100, height: 12)
                }
            }
        }
    }

    // MARK: - Search Loading State

    private var searchLoadingState: some View {
        List {
            Section {
                ForEach(0..<5, id: \.self) { _ in
                    HelpSearchResultSkeletonRow()
                }
            } header: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonColor)
                    .frame(width: 80, height: 12)
            }
        }
    }

    // MARK: - Error State

    private func helpErrorState(_ error: String) -> some View {
        ContentUnavailableView {
            Label("Unable to Load Help", systemImage: "exclamationmark.triangle")
        } description: {
            Text("We couldn't load help articles. Please check your connection and try again.")
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
            // Quick actions
            Section {
                NavigationLink {
                    HelpCategoryView()
                } label: {
                    Label("Browse by Category", systemImage: "square.grid.2x2.fill")
                        .foregroundColor(.blue)
                }

                if let firstArticle = contentLoader.articles.first(where: { $0.category == .gettingStarted }) {
                    NavigationLink {
                        HelpArticleView(article: firstArticle)
                    } label: {
                        Label("Getting Started Guide", systemImage: "play.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            } header: {
                Text("Quick Access")
            }

            // Category filter chips
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // All categories chip
                        FilterChip(
                            label: "All",
                            icon: "square.stack.3d.up.fill",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }

                        // Category chips
                        ForEach(HelpCategory.allCases, id: \.self) { category in
                            FilterChip(
                                label: category.rawValue,
                                icon: category.icon,
                                color: categoryColor(category),
                                isSelected: selectedCategory == category
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
            ForEach(HelpCategory.allCases, id: \.self) { category in
                if let articles = articlesByCategory[category], !articles.isEmpty {
                    Section {
                        ForEach(articles) { article in
                            NavigationLink {
                                HelpArticleView(article: article)
                            } label: {
                                ArticleRowView(article: article)
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

            // Footer with support info
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Need More Help?")
                        .font(.headline)

                    Text("If you can't find what you're looking for, contact your therapist directly through the app or reach out to our support team.")
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
                        HelpArticleView(article: article)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            // Category badge
                            HStack {
                                Image(systemName: article.category.icon)
                                    .font(.caption2)
                                Text(article.category.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(categoryColor(article.category))

                            // Article title
                            Text(article.title)
                                .font(.headline)
                                .foregroundColor(.primary)

                            // Content preview
                            Text(contentPreview(article))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
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
        Group {
            if !searchText.isEmpty {
                // Search has no matches - show query in message
                ContentUnavailableView {
                    Label("No Results for '\(searchText)'", systemImage: "magnifyingglass")
                } description: {
                    Text("No help articles match your search. Try different keywords or browse by category.")
                } actions: {
                    Button("Clear Search") {
                        searchText = ""
                        selectedCategory = nil
                    }
                    .buttonStyle(.bordered)
                }
            } else if selectedCategory != nil {
                // Category filter has no results
                ContentUnavailableView {
                    Label("No Articles in Category", systemImage: "folder")
                } description: {
                    Text("No help articles are available in this category yet. Try browsing other categories.")
                } actions: {
                    Button("Clear Filter") {
                        selectedCategory = nil
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                // No articles loaded at all
                ContentUnavailableView {
                    Label("No Help Articles", systemImage: "questionmark.circle")
                } description: {
                    Text("Help articles are not available at the moment. Please try again later or contact support directly.")
                }
            }
        }
    }

    // MARK: - Helpers

    private func categoryColor(_ category: HelpCategory) -> Color {
        switch category {
        case .gettingStarted:
            return .green
        case .programs:
            return .blue
        case .workouts:
            return .orange
        case .analytics:
            return .purple
        }
    }

    private func contentPreview(_ article: HelpArticle) -> String {
        // Extract first paragraph from content
        let lines = article.content.components(separatedBy: .newlines)
        let paragraphs = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return !trimmed.isEmpty &&
                   !trimmed.hasPrefix("#") &&
                   !trimmed.hasPrefix("-") &&
                   !trimmed.hasPrefix("*")
        }
        return paragraphs.first ?? ""
    }
}

// MARK: - Article Row View

struct ArticleRowView: View {
    let article: HelpArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(article.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            if !article.keywords.isEmpty {
                Text(article.keywords.prefix(3).joined(separator: " • "))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Skeleton Views

private let skeletonColor = Color.gray.opacity(0.3)

struct HelpArticleSkeletonRow: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(skeletonColor)
                .frame(width: 24, height: 24)
                .shimmer(isAnimating: isAnimating)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonColor)
                    .frame(width: 180, height: 14)
                    .shimmer(isAnimating: isAnimating)

                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonColor)
                    .frame(width: 120, height: 10)
                    .shimmer(isAnimating: isAnimating)
            }
        }
        .padding(.vertical, 4)
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

struct HelpSearchResultSkeletonRow: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category badge skeleton
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonColor)
                    .frame(width: 14, height: 14)
                    .shimmer(isAnimating: isAnimating)

                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonColor)
                    .frame(width: 60, height: 10)
                    .shimmer(isAnimating: isAnimating)
            }

            // Title skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(skeletonColor)
                .frame(width: 200, height: 16)
                .shimmer(isAnimating: isAnimating)

            // Content preview skeleton
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonColor)
                    .frame(height: 10)
                    .shimmer(isAnimating: isAnimating)

                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonColor)
                    .frame(width: 180, height: 10)
                    .shimmer(isAnimating: isAnimating)
            }
        }
        .padding(.vertical, 4)
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

