//
//  ArticleDetailView.swift
//  PTPerformance
//
//  Display full article content with markdown rendering
//  Created: 2025-12-20
//

import SwiftUI
import MarkdownUI

struct ArticleDetailView: View {
    let articleSlug: String

    @StateObject private var viewModel = ArticlesViewModel(supabase: SupabaseManager.shared.client)
    @EnvironmentObject var appState: AppState
    @State private var article: ContentItem?
    @State private var userProgress: UserProgress?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showShareSheet = false
    @State private var isBookmarked = false
    @State private var hasMarkedHelpful = false

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading article...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else if let article = article {
                articleContent(article)
            } else if let error = errorMessage {
                ContentUnavailableView {
                    Label("Error Loading Article", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try Again") {
                        Task {
                            await loadArticle()
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Bookmark button
                    Button {
                        toggleBookmark()
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(isBookmarked ? .blue : .gray)
                    }

                    // Share button
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let article = article {
                ShareSheet(items: ["\(article.title)\n\nRead more in PT Performance app"])
            }
        }
        .task {
            await loadArticle()
            if let userId = appState.userId, let articleId = article?.id {
                await trackView(articleId: articleId, userId: userId)
                await loadUserProgress(articleId: articleId, userId: userId)
            }
        }
    }

    @ViewBuilder
    private func articleContent(_ article: ContentItem) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                // Category and difficulty
                HStack {
                    Text(article.category.capitalized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(categoryColor(article.category))
                        .cornerRadius(6)

                    if let difficulty = article.difficulty {
                        DifficultyBadge(difficulty: difficulty)
                    }

                    Spacer()

                    if let duration = article.estimatedDurationMinutes {
                        Label("\(duration) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Title
                Text(article.title)
                    .font(.title)
                    .fontWeight(.bold)

                // Meta info
                HStack {
                    if let author = article.author {
                        Text(author)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Label("\(article.viewCount)", systemImage: "eye")
                    Label("\(article.helpfulCount)", systemImage: "hand.thumbsup")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                // Progress indicator
                if let progress = userProgress {
                    ProgressBar(progress: progress)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            Divider()

            // Markdown content
            Markdown(article.content.markdown)
                .padding(.horizontal)
                .textSelection(.enabled)

            // References section
            if let references = article.content.references, !references.isEmpty {
                referencesSection(references)
            }

            Divider()

            // Action buttons
            actionButtons
                .padding(.horizontal)

            // Related articles (if available)
            if let relatedIds = article.relatedItems, !relatedIds.isEmpty {
                relatedArticlesSection(relatedIds)
            }
        }
        .padding(.bottom, 30)
    }

    private func referencesSection(_ references: [Reference]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("References")
                .font(.headline)
                .padding(.horizontal)

            ForEach(references) { reference in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(reference.order).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20, alignment: .trailing)

                    Text(reference.citation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Mark as Helpful button
            Button {
                markAsHelpful()
            } label: {
                Label(
                    hasMarkedHelpful ? "Marked Helpful" : "Mark Helpful",
                    systemImage: hasMarkedHelpful ? "hand.thumbsup.fill" : "hand.thumbsup"
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(hasMarkedHelpful ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
                .foregroundColor(hasMarkedHelpful ? .white : .primary)
                .cornerRadius(10)
            }
            .disabled(hasMarkedHelpful)

            // Mark as Complete button
            if let progress = userProgress {
                Button {
                    markAsComplete()
                } label: {
                    Label(
                        progress.status == .completed ? "Completed" : "Mark Complete",
                        systemImage: progress.status == .completed ? "checkmark.circle.fill" : "checkmark.circle"
                    )
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(progress.status == .completed ? Color.green : Color(UIColor.secondarySystemGroupedBackground))
                    .foregroundColor(progress.status == .completed ? .white : .primary)
                    .cornerRadius(10)
                }
                .disabled(progress.status == .completed)
            }
        }
    }

    private func relatedArticlesSection(_ relatedIds: [UUID]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Articles")
                .font(.headline)
                .padding(.horizontal)

            // Note: Would need to fetch these articles
            // For now, show placeholder
            Text("Related articles coming soon")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }

    // MARK: - Helper Functions

    private func categoryColor(_ category: String) -> Color {
        guard let cat = ArticleCategory(rawValue: category) else {
            return .blue
        }

        switch cat.color {
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

    private func loadArticle() async {
        isLoading = true
        errorMessage = nil

        do {
            article = try await viewModel.getArticle(slug: articleSlug)
            isLoading = false
        } catch {
            errorMessage = "Failed to load article: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func trackView(articleId: UUID, userId: UUID) async {
        await viewModel.trackView(
            articleId: articleId,
            userId: UUID(uuidString: userId) ?? articleId,
            searchQuery: nil
        )
    }

    private func loadUserProgress(articleId: UUID, userId: UUID) async {
        do {
            userProgress = try await viewModel.getUserProgress(
                articleId: articleId,
                userId: UUID(uuidString: userId) ?? articleId
            )

            // If no progress exists, mark as started
            if userProgress == nil {
                try await viewModel.markStarted(
                    articleId: articleId,
                    userId: UUID(uuidString: userId) ?? articleId
                )
                userProgress = try await viewModel.getUserProgress(
                    articleId: articleId,
                    userId: UUID(uuidString: userId) ?? articleId
                )
            }
        } catch {
            print("Error loading progress: \(error)")
        }
    }

    private func toggleBookmark() {
        guard let userId = appState.userId, let articleId = article?.id else { return }

        isBookmarked.toggle()

        Task {
            do {
                try await viewModel.bookmarkArticle(
                    articleId: articleId,
                    userId: UUID(uuidString: userId) ?? articleId
                )
            } catch {
                print("Error bookmarking: \(error)")
                isBookmarked.toggle() // Revert on error
            }
        }
    }

    private func markAsHelpful() {
        guard let userId = appState.userId, let articleId = article?.id else { return }

        hasMarkedHelpful = true

        Task {
            do {
                try await viewModel.markHelpful(
                    articleId: articleId,
                    userId: UUID(uuidString: userId) ?? articleId
                )

                // Update local article helpful count
                if var updatedArticle = article {
                    updatedArticle = ContentItem(
                        id: updatedArticle.id,
                        contentTypeId: updatedArticle.contentTypeId,
                        slug: updatedArticle.slug,
                        title: updatedArticle.title,
                        category: updatedArticle.category,
                        subcategory: updatedArticle.subcategory,
                        tags: updatedArticle.tags,
                        difficulty: updatedArticle.difficulty,
                        content: updatedArticle.content,
                        metadata: updatedArticle.metadata,
                        excerpt: updatedArticle.excerpt,
                        estimatedDurationMinutes: updatedArticle.estimatedDurationMinutes,
                        thumbnailUrl: updatedArticle.thumbnailUrl,
                        prerequisites: updatedArticle.prerequisites,
                        relatedItems: updatedArticle.relatedItems,
                        partOfSeries: updatedArticle.partOfSeries,
                        sequenceNumber: updatedArticle.sequenceNumber,
                        isPublished: updatedArticle.isPublished,
                        publishedAt: updatedArticle.publishedAt,
                        author: updatedArticle.author,
                        reviewedBy: updatedArticle.reviewedBy,
                        viewCount: updatedArticle.viewCount,
                        completionCount: updatedArticle.completionCount,
                        helpfulCount: updatedArticle.helpfulCount + 1,
                        averageRating: updatedArticle.averageRating,
                        createdAt: updatedArticle.createdAt,
                        updatedAt: updatedArticle.updatedAt
                    )
                    article = updatedArticle
                }
            } catch {
                print("Error marking helpful: \(error)")
                hasMarkedHelpful = false
            }
        }
    }

    private func markAsComplete() {
        guard let userId = appState.userId, let articleId = article?.id else { return }

        Task {
            do {
                try await viewModel.markCompleted(
                    articleId: articleId,
                    userId: UUID(uuidString: userId) ?? articleId
                )

                // Reload progress
                userProgress = try await viewModel.getUserProgress(
                    articleId: articleId,
                    userId: UUID(uuidString: userId) ?? articleId
                )
            } catch {
                print("Error marking complete: \(error)")
            }
        }
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let progress: UserProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()

                Text("\(progress.progressPercentage)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)

                    Rectangle()
                        .fill(statusColor)
                        .frame(width: geometry.size.width * CGFloat(progress.progressPercentage) / 100, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 8)
    }

    private var statusText: String {
        switch progress.status {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .skipped: return "Skipped"
        }
    }

    private var statusColor: Color {
        switch progress.status {
        case .notStarted: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        case .skipped: return .orange
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ArticleDetailView(articleSlug: "j-band-routine")
            .environmentObject(AppState())
    }
}
