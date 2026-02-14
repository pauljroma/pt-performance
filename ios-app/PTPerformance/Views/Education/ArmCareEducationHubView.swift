//
//  ArmCareEducationHubView.swift
//  PTPerformance
//
//  Created by Content & Polish Sprint Agent 7
//  Hub view for Arm Care educational content
//  Organizes articles by category with search and featured content
//

import SwiftUI

// MARK: - Main Hub View

/// Hub view for Arm Care educational content
/// Organizes articles by category with search and featured content
struct ArmCareEducationHubView: View {

    // MARK: - State

    @StateObject private var service = ArmCareEducationService.shared
    @State private var searchText = ""
    @State private var selectedCategory: ArmCareCategory?
    @State private var hasLoadedInitialData = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if service.isLoading && !hasLoadedInitialData {
                    loadingState
                } else if let errorMessage = service.error {
                    errorState(message: errorMessage)
                } else if service.articles.isEmpty && hasLoadedInitialData {
                    emptyState
                } else {
                    contentView
                }
            }
            .navigationTitle("Arm Care Education")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search articles..."
            )
            .task {
                await loadData()
            }
            .refreshable {
                await refreshData()
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Featured articles (if not searching)
                if searchText.isEmpty && selectedCategory == nil && !service.featuredArticles.isEmpty {
                    featuredSection
                }

                // Category filter chips
                categoryFilterSection

                // Articles list
                articlesSection
            }
            .padding(.horizontal)
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - Featured Section

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Featured")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(service.featuredArticles) { article in
                        NavigationLink {
                            ArmCareArticleDetailView(article: article)
                        } label: {
                            FeaturedArticleCard(article: article)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: - Category Filter Section

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                // "All" chip
                ArmCareCategoryChip(
                    title: "All",
                    icon: "square.stack.3d.up.fill",
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                        selectedCategory = nil
                    }
                    HapticFeedback.selectionChanged()
                }

                ForEach(ArmCareCategory.allCases) { category in
                    ArmCareCategoryChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                            selectedCategory = category
                        }
                        HapticFeedback.selectionChanged()
                    }
                }
            }
        }
    }

    // MARK: - Articles Section

    private var articlesSection: some View {
        LazyVStack(spacing: Spacing.md) {
            if filteredArticles.isEmpty {
                noResultsView
            } else {
                ForEach(filteredArticles) { article in
                    NavigationLink {
                        ArmCareArticleDetailView(article: article)
                    } label: {
                        ArticleCard(article: article)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Filtered Articles

    private var filteredArticles: [ArmCareArticle] {
        var articles = service.articles

        if let category = selectedCategory {
            articles = articles.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            articles = articles.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.summary.localizedCaseInsensitiveContains(searchText)
            }
        }

        return articles
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading articles...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error State

    private func errorState(message: String) -> some View {
        EmptyStateView(
            title: "Unable to Load",
            message: message,
            icon: "exclamationmark.triangle.fill",
            iconColor: .orange,
            action: EmptyStateView.EmptyStateAction(
                title: "Try Again",
                icon: "arrow.clockwise",
                action: {
                    Task {
                        await refreshData()
                    }
                }
            )
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            title: "No Articles Yet",
            message: "Educational content on arm care, injury prevention, and recovery techniques will appear here.",
            icon: "book.closed.fill",
            iconColor: .blue
        )
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Results")
                .font(.headline)

            if !searchText.isEmpty {
                Text("No articles match '\(searchText)'")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else if let category = selectedCategory {
                Text("No articles in \(category.displayName) category")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                searchText = ""
                selectedCategory = nil
                HapticFeedback.light()
            } label: {
                Text("Clear Filters")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.top, Spacing.xs)
        }
        .padding(.vertical, Spacing.xl)
    }

    // MARK: - Data Loading

    private func loadData() async {
        guard !hasLoadedInitialData else { return }

        do {
            try await service.fetchAllArticles()
            try await service.fetchFeaturedArticles()
            hasLoadedInitialData = true
        } catch {
            // Error is handled by service.error
        }
    }

    private func refreshData() async {
        service.clearCache()
        do {
            try await service.fetchAllArticles()
            try await service.fetchFeaturedArticles()
        } catch {
            // Error is handled by service.error
        }
    }
}

// MARK: - Featured Article Card

/// Large horizontal card for featured articles in carousel
struct FeaturedArticleCard: View {
    let article: ArmCareArticle
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Featured image or gradient placeholder
            ZStack(alignment: .bottomLeading) {
                if let imageUrl = article.featuredImageUrl,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            gradientPlaceholder
                        case .empty:
                            gradientPlaceholder
                                .overlay(ProgressView())
                        @unknown default:
                            gradientPlaceholder
                        }
                    }
                } else {
                    gradientPlaceholder
                }

                // Category badge overlay
                HStack(spacing: 4) {
                    Image(systemName: article.category.icon)
                        .font(.caption2)
                    Text(article.category.displayName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(Color.black.opacity(0.6))
                .cornerRadius(CornerRadius.xs)
                .padding(Spacing.xs)
            }
            .frame(width: 260, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

            // Title
            Text(article.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Reading time and video indicator
            HStack(spacing: Spacing.sm) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(article.estimatedReadingTime) min")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)

                if article.hasVideo {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                            .font(.caption2)
                        Text("Video")
                            .font(.caption2)
                    }
                    .foregroundColor(.modusCyan)
                }
            }
        }
        .frame(width: 260)
        .padding(Spacing.sm)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
    }

    private var gradientPlaceholder: some View {
        LinearGradient(
            gradient: Gradient(colors: [categoryColor.opacity(0.8), categoryColor]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: article.category.icon)
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.4))
        )
    }

    private var categoryColor: Color {
        switch article.category {
        case .anatomy:
            return .blue
        case .injuryPrevention:
            return .red
        case .recovery:
            return .indigo
        case .technique:
            return .green
        case .programming:
            return .orange
        }
    }
}

// MARK: - Article Card

/// Standard article card for list view
struct ArticleCard: View {
    let article: ArmCareArticle
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Thumbnail
            articleThumbnail
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))

            // Content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Category badge
                HStack(spacing: 4) {
                    Image(systemName: article.category.icon)
                        .font(.caption2)
                    Text(article.category.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(categoryColor)

                // Title
                Text(article.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Summary
                Text(article.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Metadata
                HStack(spacing: Spacing.sm) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(article.estimatedReadingTime) min")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)

                    if article.hasVideo {
                        HStack(spacing: 4) {
                            Image(systemName: "play.circle.fill")
                                .font(.caption2)
                            Text("Video")
                                .font(.caption2)
                        }
                        .foregroundColor(.modusCyan)
                    }

                    if article.hasRelatedExercises {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.caption2)
                            Text("Exercises")
                                .font(.caption2)
                        }
                        .foregroundColor(.green)
                    }

                    Spacer()
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    @ViewBuilder
    private var articleThumbnail: some View {
        if let imageUrl = article.featuredImageUrl,
           let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    thumbnailPlaceholder
                @unknown default:
                    thumbnailPlaceholder
                }
            }
        } else {
            thumbnailPlaceholder
        }
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            categoryColor.opacity(0.2)
            Image(systemName: article.category.icon)
                .font(.title2)
                .foregroundColor(categoryColor)
        }
    }

    private var categoryColor: Color {
        switch article.category {
        case .anatomy:
            return .blue
        case .injuryPrevention:
            return .red
        case .recovery:
            return .indigo
        case .technique:
            return .green
        case .programming:
            return .orange
        }
    }
}

// MARK: - Category Chip

/// Filter chip for category selection
struct ArmCareCategoryChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? Color.modusCyan : Color(.tertiarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(CornerRadius.xl)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) category")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Article Detail View

/// Full article detail view with markdown rendering
struct ArmCareArticleDetailView: View {
    let article: ArmCareArticle
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Hero image
                heroImage

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Header
                    articleHeader

                    Divider()

                    // Key points (if available)
                    if let keyPoints = article.keyPoints, !keyPoints.isEmpty {
                        keyPointsSection(keyPoints)
                        Divider()
                    }

                    // Video section (if available)
                    if article.hasVideo {
                        videoSection
                        Divider()
                    }

                    // Main content
                    MarkdownText(article.content)
                        .font(.body)
                        .lineSpacing(6)

                    // Related exercises indicator
                    if article.hasRelatedExercises {
                        relatedExercisesSection
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, Spacing.xl)
        }
        .navigationTitle("Article")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share article")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [article.title, article.summary])
        }
        .onAppear {
            // Track article view
            AnalyticsTracker.shared.trackArticleViewed(
                articleId: article.id.uuidString,
                articleTitle: article.title,
                category: article.category.rawValue
            )
        }
    }

    // MARK: - Hero Image

    @ViewBuilder
    private var heroImage: some View {
        if let imageUrl = article.featuredImageUrl,
           let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                case .failure, .empty:
                    heroPlaceholder
                @unknown default:
                    heroPlaceholder
                }
            }
        } else {
            heroPlaceholder
        }
    }

    private var heroPlaceholder: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [categoryColor.opacity(0.6), categoryColor]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: article.category.icon)
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(height: 200)
    }

    // MARK: - Article Header

    private var articleHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Category badge
            HStack(spacing: 6) {
                Image(systemName: article.category.icon)
                    .font(.caption)
                Text(article.category.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(categoryColor)
            .cornerRadius(CornerRadius.sm)

            // Title
            Text(article.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // Summary
            Text(article.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Metadata row
            HStack(spacing: Spacing.md) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(article.estimatedReadingTime) min read")
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                if article.hasVideo {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                            .font(.caption)
                        Text("Includes video")
                            .font(.caption)
                    }
                    .foregroundColor(.modusCyan)
                }

                Spacer()
            }
        }
    }

    // MARK: - Key Points Section

    private func keyPointsSection(_ keyPoints: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Key Points")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(keyPoints, id: \.self) { point in
                    HStack(alignment: .top, spacing: Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.top, 2)
                        Text(point)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Video Section

    private var videoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .foregroundColor(.modusCyan)
                Text("Video Content")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .accessibilityAddTraits(.isHeader)

            if let videoUrl = article.videoUrl, let url = URL(string: videoUrl) {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Watch Video")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Opens in browser")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.modusCyan.opacity(0.1))
                    .foregroundColor(.modusCyan)
                    .cornerRadius(CornerRadius.md)
                }
            }
        }
    }

    // MARK: - Related Exercises Section

    private var relatedExercisesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Divider()

            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.green)
                Text("Related Exercises")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(article.relatedExercises?.count ?? 0) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityAddTraits(.isHeader)

            Text("This article includes related exercises you can practice. Look for them in the arm care exercise library.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Helpers

    private var categoryColor: Color {
        switch article.category {
        case .anatomy:
            return .blue
        case .injuryPrevention:
            return .red
        case .recovery:
            return .indigo
        case .technique:
            return .green
        case .programming:
            return .orange
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ArmCareEducationHubView_Previews: PreviewProvider {
    static var previews: some View {
        ArmCareEducationHubView()
    }
}
#endif
