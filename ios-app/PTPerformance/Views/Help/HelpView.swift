//
//  HelpView.swift
//  PTPerformance
//
//  Main help interface with search and category filtering
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var contentLoader = HelpContentLoader.shared
    @State private var searchText = ""
    @State private var selectedCategory: HelpCategory?
    @State private var showCategoryBrowser = false

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
                if filteredArticles.isEmpty {
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
                            title: "All",
                            icon: "square.stack.3d.up.fill",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }

                        // Category chips
                        ForEach(HelpCategory.allCases, id: \.self) { category in
                            FilterChip(
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

// MARK: - Filter Chip

struct FilterChip: View {
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
