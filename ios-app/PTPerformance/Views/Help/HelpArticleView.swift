//
//  HelpArticleView.swift
//  PTPerformance
//
//  Individual help article display with markdown rendering
//

import SwiftUI

struct HelpArticleView: View {
    let article: HelpArticle
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Article header
                VStack(alignment: .leading, spacing: 8) {
                    // Category badge
                    HStack {
                        Image(systemName: article.category.icon)
                            .font(.caption)
                        Text(article.category.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
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
                }
                .padding(.bottom, 8)

                Divider()

                // Markdown content
                MarkdownText(article.content)
                    .font(.body)
                    .lineSpacing(6)
            }
            .padding()
        }
        .navigationTitle("Help")
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
    }

    private var categoryColor: Color {
        switch article.category {
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

// MARK: - Markdown Text Renderer

/// Simple markdown text renderer using AttributedString
struct MarkdownText: View {
    let markdown: String

    init(_ markdown: String) {
        self.markdown = markdown
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseMarkdown(markdown), id: \.id) { element in
                renderElement(element)
            }
        }
    }

    private func renderElement(_ element: MarkdownElement) -> some View {
        Group {
            switch element.type {
            case .heading1:
                Text(element.text)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 8)
            case .heading2:
                Text(element.text)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top, 4)
            case .heading3:
                Text(element.text)
                    .font(.headline)
                    .fontWeight(.semibold)
            case .paragraph:
                Text(parseInlineMarkdown(element.text))
                    .fixedSize(horizontal: false, vertical: true)
            case .bulletPoint:
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.body)
                    Text(parseInlineMarkdown(element.text))
                        .fixedSize(horizontal: false, vertical: true)
                }
            case .numberedPoint:
                HStack(alignment: .top, spacing: 8) {
                    Text("\(element.number ?? 1).")
                        .font(.body)
                    Text(parseInlineMarkdown(element.text))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // Parse inline markdown (bold, italic)
    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        var result = AttributedString(text)

        // Bold (**text**)
        let boldPattern = "\\*\\*([^*]+)\\*\\*"
        if let regex = try? NSRegularExpression(pattern: boldPattern) {
            let nsString = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            for match in matches.reversed() {
                if match.numberOfRanges > 1 {
                    let range = match.range(at: 1)
                    let boldText = nsString.substring(with: range)
                    result = AttributedString(text.replacingOccurrences(of: "**\(boldText)**", with: boldText))
                    if let range = result.range(of: boldText) {
                        result[range].font = .body.bold()
                    }
                }
            }
        }

        return result
    }

    // Parse markdown into structured elements
    private func parseMarkdown(_ markdown: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        var currentNumber = 1

        let lines = markdown.components(separatedBy: .newlines)
        var skipNext = false

        for (_, line) in lines.enumerated() {
            if skipNext {
                skipNext = false
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            // Headings
            if trimmed.hasPrefix("# ") {
                elements.append(MarkdownElement(
                    id: UUID(),
                    type: .heading1,
                    text: String(trimmed.dropFirst(2))
                ))
                currentNumber = 1
            } else if trimmed.hasPrefix("## ") {
                elements.append(MarkdownElement(
                    id: UUID(),
                    type: .heading2,
                    text: String(trimmed.dropFirst(3))
                ))
                currentNumber = 1
            } else if trimmed.hasPrefix("### ") {
                elements.append(MarkdownElement(
                    id: UUID(),
                    type: .heading3,
                    text: String(trimmed.dropFirst(4))
                ))
                currentNumber = 1
            }
            // Bullet points
            else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                elements.append(MarkdownElement(
                    id: UUID(),
                    type: .bulletPoint,
                    text: String(trimmed.dropFirst(2))
                ))
            }
            // Numbered lists
            else if let range = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                let text = String(trimmed[range.upperBound...])
                elements.append(MarkdownElement(
                    id: UUID(),
                    type: .numberedPoint,
                    text: text,
                    number: currentNumber
                ))
                currentNumber += 1
            }
            // Regular paragraph
            else {
                elements.append(MarkdownElement(
                    id: UUID(),
                    type: .paragraph,
                    text: trimmed
                ))
            }
        }

        return elements
    }
}

// MARK: - Supporting Types

struct MarkdownElement {
    let id: UUID
    let type: MarkdownElementType
    let text: String
    let number: Int?

    init(id: UUID, type: MarkdownElementType, text: String, number: Int? = nil) {
        self.id = id
        self.type = type
        self.text = text
        self.number = number
    }
}

enum MarkdownElementType {
    case heading1
    case heading2
    case heading3
    case paragraph
    case bulletPoint
    case numberedPoint
}

// ShareSheet is defined in Utils/ShareSheet.swift
