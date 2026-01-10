//
//  LearningCategoryView.swift
//  PTPerformance
//
//  Browse learning articles organized by category
//

import SwiftUI

struct LearningCategoryView: View {
    @ObservedObject private var contentLoader = LearningContentLoader.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "baseball.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding(.top, 20)

                        Text("Learning Center")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Browse articles by category")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("\(contentLoader.articles.count) total articles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.bottom, 20)

                    // Category cards
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(LearningCategory.allCases, id: \.self) { category in
                            LearningCategoryCard(
                                category: category,
                                articleCount: articleCount(for: category)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func articleCount(for category: LearningCategory) -> Int {
        contentLoader.articles.filter { $0.category == category }.count
    }
}

// MARK: - Category Card

struct LearningCategoryCard: View {
    let category: LearningCategory
    let articleCount: Int

    var body: some View {
        NavigationLink {
            LearningCategoryArticleListView(category: category)
        } label: {
            VStack(spacing: 12) {
                // Icon
                Image(systemName: category.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(categoryColor)
                    .cornerRadius(16)

                // Category name
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // Article count
                Text("\(articleCount) article\(articleCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var categoryColor: Color {
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

// MARK: - Category Article List

struct LearningCategoryArticleListView: View {
    let category: LearningCategory
    @ObservedObject private var contentLoader = LearningContentLoader.shared

    var filteredArticles: [LearningArticle] {
        contentLoader.articles.filter { $0.category == category }
    }

    // Group articles by subcategory
    var articlesBySubcategory: [(String, [LearningArticle])] {
        let grouped = Dictionary(grouping: filteredArticles) { article -> String in
            article.subcategory ?? "General"
        }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        List {
            // Category header
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: category.icon)
                            .font(.title)
                            .foregroundColor(categoryColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("\(filteredArticles.count) article\(filteredArticles.count == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }

            // Articles grouped by subcategory
            ForEach(articlesBySubcategory, id: \.0) { subcategory, articles in
                Section {
                    ForEach(articles) { article in
                        NavigationLink {
                            LearningArticleView(article: article)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(article.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                HStack {
                                    if let readingTime = article.readingTimeMinutes {
                                        Text("\(readingTime) min read")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    if let difficulty = article.difficulty {
                                        Text("•")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(difficulty)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                if !article.keywords.isEmpty {
                                    Text(article.keywords.prefix(3).joined(separator: " • "))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    if subcategory != "General" {
                        Text(subcategory)
                    }
                }
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.large)
    }

    private var categoryColor: Color {
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
