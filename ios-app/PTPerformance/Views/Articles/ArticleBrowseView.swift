//
//  ArticleBrowseView.swift
//  PTPerformance
//
//  Browse and search baseball performance articles
//  Created: 2025-12-20
//

import SwiftUI

struct ArticleBrowseView: View {
    @StateObject private var viewModel = ArticlesViewModel(supabase: SupabaseManager.shared.client)
    @EnvironmentObject var appState: AppState
    @State private var showFilters = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.searchResults.isEmpty {
                    ProgressView("Loading articles...")
                } else {
                    articlesList
                }
            }
            .navigationTitle("Performance Library")
            .searchable(text: $viewModel.searchQuery, prompt: "Search articles...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFilters.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(hasActiveFilters ? .blue : .gray)
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FiltersSheet(viewModel: viewModel)
            }
            .task {
                await viewModel.loadFeaturedArticles()
                if viewModel.searchQuery.isEmpty {
                    await viewModel.performSearch()
                }
            }
        }
    }

    private var hasActiveFilters: Bool {
        viewModel.selectedCategory != nil || viewModel.selectedDifficulty != nil
    }

    private var articlesList: some View {
        List {
            // Featured Section
            if viewModel.searchQuery.isEmpty && viewModel.selectedCategory == nil {
                Section("Featured Articles") {
                    ForEach(viewModel.featuredArticles.prefix(3)) { article in
                        NavigationLink {
                            ArticleDetailView(articleSlug: article.slug)
                                .environmentObject(appState)
                        } label: {
                            FeaturedArticleCard(article: article)
                        }
                    }
                }
            }

            // Categories Grid (when no search)
            if viewModel.searchQuery.isEmpty && viewModel.selectedCategory == nil {
                Section("Browse by Category") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(ArticleCategory.allCases) { category in
                            CategoryCard(category: category) {
                                Task {
                                    await viewModel.getArticlesByCategory(category)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Search Results or Category Articles
            if !viewModel.searchResults.isEmpty {
                Section(searchResultsHeader) {
                    ForEach(viewModel.searchResults) { article in
                        NavigationLink {
                            ArticleDetailView(articleSlug: article.slug)
                                .environmentObject(appState)
                        } label: {
                            ArticleRowView(article: article)
                        }
                    }
                }
            } else if !viewModel.searchQuery.isEmpty || viewModel.selectedCategory != nil {
                ContentUnavailableView {
                    Label("No Articles Found", systemImage: "magnifyingglass")
                } description: {
                    Text("Try adjusting your search or filters")
                } actions: {
                    Button("Clear Filters") {
                        viewModel.clearFilters()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.performSearch()
        }
    }

    private var searchResultsHeader: String {
        if let category = viewModel.selectedCategory {
            return category.displayName
        } else if !viewModel.searchQuery.isEmpty {
            return "Search Results"
        } else {
            return "All Articles"
        }
    }
}

// MARK: - Featured Article Card

struct FeaturedArticleCard: View {
    let article: ContentSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(article.category.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor)
                    .cornerRadius(4)

                Spacer()

                if let difficulty = article.difficulty {
                    DifficultyBadge(difficulty: difficulty)
                }
            }

            Text(article.title)
                .font(.headline)
                .lineLimit(2)

            if let excerpt = article.excerpt {
                Text(excerpt)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                if let duration = article.estimatedDurationMinutes {
                    Label("\(duration) min", systemImage: "clock")
                }

                Spacer()

                Label("\(article.viewCount)", systemImage: "eye")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var categoryColor: Color {
        guard let category = ArticleCategory(rawValue: article.category) else {
            return .blue
        }

        switch category.color {
        case "blue": return .blue
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "green": return .green
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "pink": return .pink
        case "brown": return .brown
        default: return .blue
        }
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: ArticleCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 32))
                    .foregroundColor(categoryColor)

                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private var categoryColor: Color {
        switch category.color {
        case "blue": return .blue
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "green": return .green
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "pink": return .pink
        case "brown": return .brown
        default: return .blue
        }
    }
}

// MARK: - Article Row View

struct ArticleRowView: View {
    let article: ContentSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(article.category.capitalized)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                if let difficulty = article.difficulty {
                    DifficultyBadge(difficulty: difficulty)
                }

                Spacer()

                if let duration = article.estimatedDurationMinutes {
                    Label("\(duration) min", systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Text(article.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)

            if let excerpt = article.excerpt {
                Text(excerpt)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Label("\(article.viewCount)", systemImage: "eye")

                if article.helpfulCount > 0 {
                    Label("\(article.helpfulCount)", systemImage: "hand.thumbsup")
                }

                Spacer()
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Difficulty Badge

struct DifficultyBadge: View {
    let difficulty: ContentItem.Difficulty

    var body: some View {
        Text(difficulty.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor)
            .cornerRadius(4)
    }

    private var badgeColor: Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Filters Sheet

struct FiltersSheet: View {
    @ObservedObject var viewModel: ArticlesViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("All").tag(nil as ArticleCategory?)
                        ForEach(ArticleCategory.allCases) { category in
                            Text(category.displayName).tag(category as ArticleCategory?)
                        }
                    }
                }

                Section("Difficulty") {
                    Picker("Difficulty", selection: $viewModel.selectedDifficulty) {
                        Text("All").tag(nil as ContentItem.Difficulty?)
                        ForEach(ContentItem.Difficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.displayName).tag(difficulty as ContentItem.Difficulty?)
                        }
                    }
                }

                Section {
                    Button("Clear All Filters") {
                        viewModel.clearFilters()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                        Task {
                            await viewModel.performSearch()
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ArticleBrowseView()
            .environmentObject(AppState())
    }
}
