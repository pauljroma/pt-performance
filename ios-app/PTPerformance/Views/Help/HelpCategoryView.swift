//
//  HelpCategoryView.swift
//  PTPerformance
//
//  Browse help articles organized by category
//

import SwiftUI

struct HelpCategoryView: View {
    @ObservedObject private var contentLoader = HelpContentLoader.shared
    @State private var selectedCategory: HelpCategory?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding(.top, 20)

                        Text("Help Center")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Browse articles by category")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)

                    // Category cards
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(HelpCategory.allCases, id: \.self) { category in
                            CategoryCard(
                                category: category,
                                articleCount: articleCount(for: category)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Browse Help")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func articleCount(for category: HelpCategory) -> Int {
        contentLoader.articles.filter { $0.category == category }.count
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: HelpCategory
    let articleCount: Int

    var body: some View {
        NavigationLink {
            CategoryArticleListView(category: category)
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

                // Article count
                Text("\(articleCount) article\(articleCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var categoryColor: Color {
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
}

// MARK: - Category Article List

struct CategoryArticleListView: View {
    let category: HelpCategory
    @ObservedObject private var contentLoader = HelpContentLoader.shared

    var filteredArticles: [HelpArticle] {
        contentLoader.articles.filter { $0.category == category }
    }

    var body: some View {
        List(filteredArticles) { article in
            NavigationLink {
                HelpArticleView(article: article)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(article.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    // Keywords preview
                    if !article.keywords.isEmpty {
                        Text(article.keywords.prefix(3).joined(separator: " • "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.large)
    }
}
