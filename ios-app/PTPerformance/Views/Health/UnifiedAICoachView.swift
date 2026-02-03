import SwiftUI

struct UnifiedAICoachView: View {
    @StateObject private var viewModel = AICoachViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main Content
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            // Proactive Insights Carousel (at top)
                            if !viewModel.insights.isEmpty && viewModel.messages.count <= 2 {
                                insightsCarousel
                            }

                            // Today's Focus Card
                            if !viewModel.todayFocus.isEmpty && viewModel.messages.count <= 2 {
                                todayFocusCard
                            }

                            // Alerts Banner
                            if viewModel.hasAlerts && viewModel.messages.count <= 2 {
                                alertsBanner
                            }

                            // Chat Messages
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message, onQuestionTap: { question in
                                    Task { await viewModel.askQuestion(question) }
                                })
                                .id(message.id)
                            }

                            // Typing Indicator
                            if viewModel.isTyping {
                                HStack {
                                    CoachTypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }

                            // Suggested Questions (when few messages)
                            if viewModel.messages.count <= 3 && !viewModel.suggestedQuestions.isEmpty {
                                suggestedQuestionsSection
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input Field
                chatInputField
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await viewModel.refreshInsights() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                    .accessibilityLabel("Refresh insights")
                }
            }
            .task {
                await viewModel.loadInitialInsights()
            }
        }
    }

    // MARK: - Insights Carousel

    private var insightsCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)
                Text("Proactive Insights")
                    .font(.headline)
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.highPriorityInsights) { insight in
                        InsightCard(insight: insight)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Today's Focus Card

    private var todayFocusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)
                Text("Today's Focus")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(viewModel.todayFocus)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.modusCyan.opacity(0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's focus: \(viewModel.todayFocus)")
    }

    // MARK: - Alerts Banner

    private var alertsBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .accessibilityHidden(true)
                Text("Attention")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            ForEach(viewModel.proactiveAlerts, id: \.self) { alert in
                Text("- \(alert)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Alerts: \(viewModel.proactiveAlerts.joined(separator: ". "))")
    }

    // MARK: - Suggested Questions

    private var suggestedQuestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ask me about...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            FlowLayout(spacing: 8) {
                ForEach(viewModel.suggestedQuestions.prefix(6), id: \.self) { question in
                    SuggestedQuestionChip(question: question) {
                        Task { await viewModel.askQuestion(question) }
                    }
                }
            }
        }
    }

    // MARK: - Chat Input Field

    private var chatInputField: some View {
        HStack(spacing: 12) {
            TextField("Ask your AI coach...", text: $viewModel.inputMessage, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(20)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    Task { await viewModel.sendMessage() }
                }
                .accessibilityLabel("Message input")
                .accessibilityHint("Type your question for the AI coach")

            Button {
                Task { await viewModel.sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundColor(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .modusCyan)
            }
            .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isTyping)
            .accessibilityLabel("Send message")
            .accessibilityHint(viewModel.inputMessage.isEmpty ? "Enter a message first" : "Sends your question to the AI coach")
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: AICoachMessage
    let onQuestionTap: (String) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user {
                Spacer(minLength: 60)
            } else {
                // Coach avatar
                ZStack {
                    Circle()
                        .fill(Color.modusCyan.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16))
                        .foregroundColor(.modusCyan)
                }
                .accessibilityHidden(true)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // Message Content
                Text(message.content)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(message.role == .user ? Color.modusCyan : Color.modusLightTeal)
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(18)
                    .cornerRadius(message.role == .user ? 18 : 4, corners: message.role == .user ? [.bottomRight] : [.bottomLeft])

                // Inline Insights (for coach messages)
                if let insights = message.insights, !insights.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(insights) { insight in
                            InlineInsightCard(insight: insight)
                        }
                    }
                }

                // Follow-up Questions (for coach messages)
                if let questions = message.suggestedQuestions, !questions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Related questions:")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        ForEach(questions.prefix(3), id: \.self) { question in
                            Button {
                                onQuestionTap(question)
                            } label: {
                                Text(question)
                                    .font(.caption)
                                    .foregroundColor(.modusCyan)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.modusCyan.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .accessibilityLabel("Ask: \(question)")
                        }
                    }
                }

                // Timestamp
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if message.role == .coach {
                Spacer(minLength: 40)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: CoachingInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: insight.category.icon)
                    .font(.caption)
                    .foregroundColor(categoryColor)
                    .accessibilityHidden(true)

                Text(insight.category.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(categoryColor)

                Spacer()

                if insight.priority == .high {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .accessibilityLabel("High priority")
                }
            }

            Text(insight.insight)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(3)

            if !insight.action.isEmpty {
                Text(insight.action)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.modusCyan)
            }
        }
        .frame(width: 220)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.category.displayName) insight: \(insight.insight). Action: \(insight.action)")
    }

    private var categoryColor: Color {
        switch insight.category.color {
        case "blue": return .blue
        case "pink": return .pink
        case "green": return .green
        case "purple": return .purple
        case "red": return .red
        case "orange": return .orange
        default: return .gray
        }
    }
}

// MARK: - Inline Insight Card

struct InlineInsightCard: View {
    let insight: CoachingInsight

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: insight.category.icon)
                .font(.caption)
                .foregroundColor(.modusCyan)
                .frame(width: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.insight)
                    .font(.caption)
                    .foregroundColor(.primary)

                if !insight.action.isEmpty {
                    Text(insight.action)
                        .font(.caption2)
                        .foregroundColor(.modusCyan)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(10)
        .background(Color.modusLightTeal)
        .cornerRadius(10)
    }
}

// MARK: - Suggested Question Chip

struct SuggestedQuestionChip: View {
    let question: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(question)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                .foregroundColor(.primary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.modusCyan.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ask: \(question)")
    }
}

// MARK: - Coach Typing Indicator

struct CoachTypingIndicator: View {
    @State private var dotIndex = 0

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.modusCyan.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16))
                    .foregroundColor(.modusCyan)
            }

            // Dots
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.modusCyan.opacity(dotIndex == index ? 1 : 0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.modusLightTeal)
            .cornerRadius(18)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: false)) {
                startAnimation()
            }
        }
        .accessibilityLabel("AI Coach is thinking")
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            dotIndex = (dotIndex + 1) % 3
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    UnifiedAICoachView()
}
