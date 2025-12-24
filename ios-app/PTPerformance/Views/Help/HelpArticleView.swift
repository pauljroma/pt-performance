import SwiftUI

/// Article detail view with markdown content rendering
struct HelpArticleView: View {
    let article: HelpArticle

    @StateObject private var dataManager = HelpDataManager.shared
    @State private var relatedArticles: [HelpArticle] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Article header
                ArticleHeaderView(article: article)

                Divider()

                // Article content (markdown rendered)
                MarkdownContentView(content: article.content)
                    .padding(.horizontal)

                // Related articles section
                if !relatedArticles.isEmpty {
                    Divider()
                        .padding(.top, 20)

                    RelatedArticlesSection(articles: relatedArticles)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadRelatedArticles()
        }
    }

    private func loadRelatedArticles() {
        relatedArticles = dataManager.getRelatedArticles(for: article)
    }
}

// MARK: - Article Header

struct ArticleHeaderView: View {
    let article: HelpArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category badge
            Text(article.category)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)

            // Title
            Text(article.title)
                .font(.title)
                .fontWeight(.bold)

            // Last updated
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                Text("Updated \(article.formattedLastUpdated)")
                    .font(.caption)
            }
            .foregroundColor(.secondary)

            // Tags
            if !article.tags.isEmpty {
                TagsView(tags: article.tags)
            }
        }
        .padding(.horizontal)
    }
}

struct TagsView: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .foregroundColor(.secondary)
                        .cornerRadius(6)
                }
            }
        }
    }
}

// MARK: - Markdown Content View

struct MarkdownContentView: View {
    let content: String

    private var parsedContent: [MarkdownElement] {
        parseMarkdown(content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parsedContent) { element in
                switch element.type {
                case .heading1:
                    Text(element.text)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 8)

                case .heading2:
                    Text(element.text)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 8)

                case .heading3:
                    Text(element.text)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 6)

                case .bulletPoint:
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .fontWeight(.bold)
                        Text(element.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, CGFloat(element.indentLevel) * 16)

                case .numberedPoint:
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(element.number ?? 0).")
                            .fontWeight(.bold)
                        Text(element.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, CGFloat(element.indentLevel) * 16)

                case .paragraph:
                    if !element.text.isEmpty {
                        Text(element.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                case .bold:
                    Text(element.text)
                        .fontWeight(.bold)

                case .italic:
                    Text(element.text)
                        .italic()

                case .code:
                    Text(element.text)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                }
            }
        }
    }

    // MARK: - Markdown Parser

    private func parseMarkdown(_ markdown: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = markdown.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.isEmpty {
                continue
            }

            // Heading 1
            if trimmedLine.hasPrefix("# ") {
                let text = String(trimmedLine.dropFirst(2))
                elements.append(MarkdownElement(id: "\(index)", type: .heading1, text: text))
            }
            // Heading 2
            else if trimmedLine.hasPrefix("## ") {
                let text = String(trimmedLine.dropFirst(3))
                elements.append(MarkdownElement(id: "\(index)", type: .heading2, text: text))
            }
            // Heading 3
            else if trimmedLine.hasPrefix("### ") {
                let text = String(trimmedLine.dropFirst(4))
                elements.append(MarkdownElement(id: "\(index)", type: .heading3, text: text))
            }
            // Bullet point
            else if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                let text = String(trimmedLine.dropFirst(2))
                let indentLevel = countLeadingSpaces(line) / 2
                elements.append(MarkdownElement(id: "\(index)", type: .bulletPoint, text: text, indentLevel: indentLevel))
            }
            // Numbered point
            else if let numberMatch = trimmedLine.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                let numberStr = trimmedLine[numberMatch].dropLast(2)
                let number = Int(numberStr) ?? 1
                let text = String(trimmedLine[numberMatch.upperBound...])
                let indentLevel = countLeadingSpaces(line) / 2
                elements.append(MarkdownElement(id: "\(index)", type: .numberedPoint, text: text, number: number, indentLevel: indentLevel))
            }
            // Paragraph
            else {
                elements.append(MarkdownElement(id: "\(index)", type: .paragraph, text: trimmedLine))
            }
        }

        return elements
    }

    private func countLeadingSpaces(_ str: String) -> Int {
        var count = 0
        for char in str {
            if char == " " {
                count += 1
            } else {
                break
            }
        }
        return count
    }
}

// MARK: - Markdown Element Model

struct MarkdownElement: Identifiable {
    let id: String
    let type: MarkdownElementType
    let text: String
    var number: Int?
    var indentLevel: Int = 0
}

enum MarkdownElementType {
    case heading1
    case heading2
    case heading3
    case bulletPoint
    case numberedPoint
    case paragraph
    case bold
    case italic
    case code
}

// MARK: - Related Articles Section

struct RelatedArticlesSection: View {
    let articles: [HelpArticle]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Related Articles")
                .font(.headline)
                .padding(.horizontal)

            ForEach(articles) { article in
                NavigationLink(destination: HelpArticleView(article: article)) {
                    RelatedArticleCard(article: article)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.bottom)
    }
}

struct RelatedArticleCard: View {
    let article: HelpArticle

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: categoryIcon(for: article.category))
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)

            // Article info
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(article.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "getting started": return "star.fill"
        case "exercises": return "figure.walk"
        case "programs": return "list.bullet.clipboard.fill"
        case "readiness": return "heart.fill"
        case "scheduling": return "calendar"
        case "troubleshooting": return "wrench.fill"
        default: return "doc.text.fill"
        }
    }
}

// MARK: - Preview

struct HelpArticleView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HelpArticleView(article: HelpArticle(
                id: "test-1",
                title: "Test Article",
                category: "Getting Started",
                content: """
                # Welcome to PT Performance

                This is a test article with markdown content.

                ## Key Features

                - Feature 1
                - Feature 2
                - Feature 3

                ### Getting Started

                1. First step
                2. Second step
                3. Third step

                Regular paragraph text here.
                """,
                tags: ["test", "demo"],
                relatedArticleIds: nil,
                lastUpdated: "2025-12-20"
            ))
        }
    }
}
