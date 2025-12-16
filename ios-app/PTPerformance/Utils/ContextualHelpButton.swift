//
//  ContextualHelpButton.swift
//  PTPerformance
//
//  Reusable help button component for contextual help
//

import SwiftUI

/// Reusable help button that opens help system with specific article
struct ContextualHelpButton: View {
    let articleId: String?
    @State private var showHelp = false

    var body: some View {
        Button {
            showHelp = true
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 20))
                .foregroundColor(.blue)
        }
        .sheet(isPresented: $showHelp) {
            if let articleId = articleId {
                HelpArticleDeepLinkView(articleId: articleId)
            } else {
                HelpView()
            }
        }
    }
}

/// Deep link view that opens help with specific article pre-selected
struct HelpArticleDeepLinkView: View {
    let articleId: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            if let article = HelpContentLoader.shared.articles.first(where: { $0.id == articleId }) {
                HelpArticleView(article: article)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                dismiss()
                            }
                        }
                    }
            } else {
                // Fallback to main help view if article not found
                HelpView()
            }
        }
    }
}

/// Helper to load help content from JSON
class HelpContentLoader: ObservableObject {
    static let shared = HelpContentLoader()

    @Published var articles: [HelpArticle] = []

    init() {
        loadArticles()
    }

    private func loadArticles() {
        guard let url = Bundle.main.url(forResource: "HelpContent", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load HelpContent.json")
            return
        }

        let decoder = JSONDecoder()
        do {
            articles = try decoder.decode([HelpArticle].self, from: data)
        } catch {
            print("Failed to decode HelpContent.json: \(error)")
        }
    }
}
