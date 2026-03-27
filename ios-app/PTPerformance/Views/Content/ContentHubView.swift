//
//  ContentHubView.swift
//  PTPerformance
//
//  ACP-1001: Content Marketing Engine — In-app education hub
//  Displays educational articles with premium gating and category filtering.
//

import SwiftUI

// MARK: - Content Hub View

/// The main content and education hub view.
///
/// Features a featured article banner, category filter chips, and an article
/// list with thumbnails, read times, and premium badges. Free users see a
/// limited number of articles with an upsell prompt for more.
struct ContentHubView: View {

    @StateObject private var service = ContentHubService.shared
    @StateObject private var storeKit = StoreKitService.shared

    @State private var selectedArticle: ContentArticle?
    @State private var searchText = ""
    @State private var showingPaywall = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Featured article banner
                if let featured = service.featuredArticle {
                    featuredBanner(article: featured)
                }

                // Category filter chips
                categoryChips

                // Article list
                if service.isLoading {
                    loadingState
                } else if displayedArticles.isEmpty {
                    emptyState
                } else {
                    articleList
                }

                // Premium upsell (if applicable)
                if !storeKit.isPremium {
                    premiumUpsell
                }
            }
            .padding(.bottom, Spacing.xl)
        }
        .navigationTitle("Learn")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search articles")
        .task {
            await service.fetchArticles()
        }
        .sheet(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
        }
    }

    // MARK: - Displayed Articles

    private var displayedArticles: [ContentArticle] {
        if !searchText.isEmpty {
            return service.searchArticles(query: searchText)
        }
        return service.visibleArticles(isPremium: storeKit.isPremium)
    }

    // MARK: - Featured Banner

    private func featuredBanner(article: ContentArticle) -> some View {
        Button {
            selectedArticle = article
            service.trackArticleRead(article)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Category + Read time
                HStack {
                    Label(article.category.displayName, systemImage: article.category.icon)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))

                    Spacer()

                    Text(article.formattedReadTime)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                Text("FEATURED")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(1.5)

                Text(article.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                Text(article.summary)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)

                if let author = article.author {
                    Text("By \(author)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, Spacing.xxs)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.modusCyan.opacity(0.9),
                        Color(red: 0.05, green: 0.35, blue: 0.45)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(CornerRadius.lg)
            .padding(.horizontal, Spacing.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                // All tab
                chipButton(title: "All", icon: "square.grid.2x2", isSelected: service.selectedCategory == nil) {
                    service.selectedCategory = nil
                }

                ForEach(ContentCategory.allCases) { category in
                    chipButton(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: service.selectedCategory == category
                    ) {
                        service.selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    private func chipButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? Color.modusCyan.opacity(0.15) : Color(.systemGray6))
            .foregroundColor(isSelected ? .modusCyan : .secondary)
            .cornerRadius(CornerRadius.lg)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Article List

    private var articleList: some View {
        LazyVStack(spacing: Spacing.sm) {
            ForEach(displayedArticles) { article in
                ArticleRowView(
                    article: article,
                    isPremiumUser: storeKit.isPremium
                )
                .onTapGesture {
                    if article.isPremium && !storeKit.isPremium {
                        showingPaywall = true
                    } else {
                        selectedArticle = article
                        service.trackArticleRead(article)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading articles...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text(searchText.isEmpty ? "No Articles Available" : "No Results")
                .font(.headline)
                .foregroundColor(.primary)

            Text(searchText.isEmpty
                 ? "Check back soon for new educational content."
                 : "Try a different search term.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // v1.0: All features free — premium upsell removed
    private var premiumUpsell: some View {
        EmptyView()
    }
}

// MARK: - Article Row View

/// A single article row in the content hub list.
struct ArticleRowView: View {
    let article: ContentArticle
    let isPremiumUser: Bool

    private var isLocked: Bool {
        article.isPremium && !isPremiumUser
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Thumbnail placeholder
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color(.systemGray6))
                    .frame(width: 64, height: 64)

                Image(systemName: article.category.icon)
                    .font(.title3)
                    .foregroundColor(.modusCyan.opacity(isLocked ? 0.4 : 1.0))
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Title
                Text(article.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isLocked ? .secondary : .primary)
                    .lineLimit(2)

                // Summary
                Text(article.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Metadata row
                HStack(spacing: Spacing.sm) {
                    // Read time
                    Label(article.formattedReadTime, systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    // Category
                    Text(article.category.displayName)
                        .font(.caption2)
                        .foregroundColor(.modusCyan)

                    Spacer()

                    // v1.0: Premium badge removed — all content free
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .strokeBorder(Color(.systemGray5), lineWidth: 1)
        )
        .opacity(isLocked ? 0.7 : 1.0)
    }
}

// MARK: - Article Detail View

/// Full article detail view with rich text content.
struct ArticleDetailView: View {
    let article: ContentArticle

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        // Category + read time
                        HStack {
                            Label(article.category.displayName, systemImage: article.category.icon)
                                .font(.caption)
                                .foregroundColor(.modusCyan)

                            Spacer()

                            Label(article.formattedReadTime, systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // Title
                        Text(article.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        // Author + date
                        HStack {
                            if let author = article.author {
                                Text("By \(author)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(article.publishedAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Content
                    Text(article.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)

                    // Tags
                    if !article.tags.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Tags")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            FlowLayout(spacing: Spacing.xs) {
                                ForEach(article.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption2)
                                        .foregroundColor(.modusCyan)
                                        .padding(.horizontal, Spacing.xs)
                                        .padding(.vertical, Spacing.xxs)
                                        .background(Color.modusCyan.opacity(0.1))
                                        .cornerRadius(CornerRadius.sm)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// FlowLayout is defined in Components/FlowLayout.swift

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        ContentHubView()
    }
}
#endif
