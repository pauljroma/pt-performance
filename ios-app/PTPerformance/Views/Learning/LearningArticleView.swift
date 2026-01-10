//
//  LearningArticleView.swift
//  PTPerformance
//
//  Individual learning article display with markdown rendering
//

import SwiftUI

struct LearningArticleView: View {
    let article: LearningArticle
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Article header
                VStack(alignment: .leading, spacing: 12) {
                    // Category badge
                    HStack {
                        Image(systemName: article.category.icon)
                            .font(.caption)
                        Text(article.category.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)

                        if let subcategory = article.subcategory {
                            Text("•")
                                .font(.caption)
                            Text(subcategory)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(categoryColor)
                    .cornerRadius(8)

                    // Title
                    Text(article.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    // Metadata
                    HStack(spacing: 12) {
                        if let readingTime = article.readingTimeMinutes {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text("\(readingTime) min read")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }

                        if let difficulty = article.difficulty {
                            HStack(spacing: 4) {
                                Image(systemName: "chart.bar")
                                    .font(.caption)
                                Text(difficulty)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }

                    // Excerpt (if available)
                    if let excerpt = article.excerpt {
                        Text(excerpt)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.bottom, 8)

                Divider()

                // Markdown content
                MarkdownText(article.content)
                    .font(.body)
                    .lineSpacing(6)

                // Keywords/Tags
                if !article.keywords.isEmpty {
                    Divider()
                        .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Related Topics")
                            .font(.headline)
                            .foregroundColor(.primary)

                        FlowLayout(spacing: 8) {
                            ForEach(article.keywords, id: \.self) { keyword in
                                Text(keyword)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray6))
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
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
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [article.title, article.content])
        }
        .onAppear {
            // Track article viewed - BUILD 95
            AnalyticsTracker.shared.trackArticleViewed(
                articleId: article.id,
                articleTitle: article.title,
                category: article.category.rawValue
            )
        }
    }

    private var categoryColor: Color {
        switch article.category {
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

// MARK: - Flow Layout (for tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            let absolutePosition = CGPoint(
                x: position.x + bounds.origin.x,
                y: position.y + bounds.origin.y
            )
            subview.place(at: absolutePosition, proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    // Start new line
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
