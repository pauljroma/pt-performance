//
//  ContextualHelpButton.swift
//  PTPerformance
//
//  Reusable help button component for contextual help
//

import SwiftUI

/// Reusable help button that opens help system with specific article
struct ContextualHelpButton: View {
    let articleId: UUID?
    @State private var showHelp = false

    var body: some View {
        Button {
            showHelp = true
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 20))
                .foregroundColor(.blue)
        }
        .accessibilityLabel("Help")
        .accessibilityHint("Opens help and support articles")
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
    let articleId: UUID
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
// HelpContentLoader moved to Services/HelpContentLoader.swift
// This duplicate class was causing the app to load from JSON instead of Supabase
