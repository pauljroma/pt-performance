import SwiftUI

struct UnifiedAICoachView: View {
    @StateObject private var viewModel = AICoachViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var insightsAppeared = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Error state with retry
                if let error = viewModel.error, !viewModel.isLoading {
                    errorBanner(error: error)
                }

                // Main Content
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            // Loading state with engaging message
                            if viewModel.isLoading && viewModel.messages.count <= 1 {
                                AICoachLoadingView()
                                    .transition(.opacity.combined(with: .scale))
                            }

                            // Proactive Insights Carousel (at top)
                            if !viewModel.insights.isEmpty && viewModel.messages.count <= 2 && !viewModel.isLoading {
                                insightsCarousel
                                    .opacity(insightsAppeared ? 1 : 0)
                                    .offset(y: insightsAppeared ? 0 : 20)
                                    .onAppear {
                                        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                                            insightsAppeared = true
                                        }
                                        // Haptic feedback for high priority insights
                                        if viewModel.highPriorityInsights.count > 0 {
                                            HapticFeedback.warning()
                                        }
                                    }
                            }

                            // Today's Focus Card
                            if !viewModel.todayFocus.isEmpty && viewModel.messages.count <= 2 && !viewModel.isLoading {
                                todayFocusCard
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            // Alerts Banner
                            if viewModel.hasAlerts && viewModel.messages.count <= 2 && !viewModel.isLoading {
                                alertsBanner
                                    .onAppear {
                                        // Important alert - use warning haptic
                                        HapticFeedback.warning()
                                    }
                            }

                            // Empty state when no insights and not loading
                            if viewModel.insights.isEmpty && !viewModel.isLoading && viewModel.messages.count <= 1 {
                                emptyInsightsState
                            }

                            // Chat Messages
                            ForEach(viewModel.messages) { message in
                                AICoachChatBubble(message: message, onQuestionTap: { question in
                                    Task { await viewModel.askQuestion(question) }
                                })
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                ))
                            }

                            // Typing Indicator with engaging messages
                            if viewModel.isTyping {
                                HStack {
                                    CoachTypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .scale))
                            }

                            // Suggested Questions (when few messages)
                            if viewModel.messages.count <= 3 && !viewModel.suggestedQuestions.isEmpty && !viewModel.isLoading {
                                suggestedQuestionsSection
                            }
                        }
                        .padding()
                        .animation(.easeInOut(duration: 0.3), value: viewModel.messages.count)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
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

    // MARK: - Error Banner

    private func errorBanner(error: String) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .accessibilityHidden(true)

                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Button {
                    HapticFeedback.light()
                    Task { await viewModel.refreshInsights() }
                } label: {
                    Text("Retry")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.modusCyan)
                }
                .accessibilityLabel("Retry loading")
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error). Tap retry to try again.")
    }

    // MARK: - Empty State

    private var emptyInsightsState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.modusCyan.opacity(0.6))
                .accessibilityHidden(true)

            Text("No Insights Yet")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Start a conversation or complete some workouts and recovery sessions to get personalized insights.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No insights available yet. Complete workouts and recovery sessions to get personalized insights.")
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
        .cornerRadius(CornerRadius.md)
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
        .cornerRadius(CornerRadius.md)
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
                .cornerRadius(CornerRadius.xl)
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

struct AICoachChatBubble: View {
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
                    .cornerRadius(CornerRadius.lg)

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
                                    .cornerRadius(CornerRadius.sm)
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
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with category and priority
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

                // Priority indicator with visual distinction
                PriorityBadge(priority: insight.priority)
            }

            Text(insight.insight)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(isExpanded ? nil : 3)

            if !insight.action.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption2)
                        .accessibilityHidden(true)
                    Text(insight.action)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.modusCyan)
            }

            // Rationale (expandable)
            if !insight.rationale.isEmpty && isExpanded {
                Divider()

                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    Text(insight.rationale)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(width: 240)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    // Priority accent border
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(priorityAccentColor.opacity(0.4), lineWidth: insight.priority == .high ? 2 : 0)
                )
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
            HapticFeedback.light()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.priority.rawValue) priority \(insight.category.displayName) insight: \(insight.insight). Action: \(insight.action)")
        .accessibilityHint("Tap to \(isExpanded ? "collapse" : "expand") details")
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

    private var priorityAccentColor: Color {
        switch insight.priority {
        case .high: return .orange
        case .medium: return .modusCyan
        case .low: return .clear
        }
    }
}

// MARK: - Priority Badge

/// Visual badge showing priority level with appropriate styling
struct PriorityBadge: View {
    let priority: CoachingPriority

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: iconName)
                .font(.system(size: 8))
            Text(priority.rawValue.capitalized)
                .font(.system(size: 9, weight: .medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(backgroundColor.opacity(0.15))
        .foregroundColor(backgroundColor)
        .cornerRadius(CornerRadius.xs)
        .accessibilityLabel("\(priority.rawValue) priority")
    }

    private var iconName: String {
        switch priority {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "circle.fill"
        case .low: return "checkmark.circle"
        }
    }

    private var backgroundColor: Color {
        switch priority {
        case .high: return .orange
        case .medium: return .modusCyan
        case .low: return .green
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
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Suggested Question Chip

struct SuggestedQuestionChip: View {
    let question: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            Text(question)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                .foregroundColor(.primary)
                .cornerRadius(CornerRadius.lg)
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
    @State private var dotAnimations = [false, false, false]

    /// Engaging messages shown while AI is thinking
    private static let thinkingMessages = [
        "Analyzing your health data...",
        "Reviewing your recent progress...",
        "Considering your goals...",
        "Checking your training patterns...",
        "Evaluating your recovery status..."
    ]

    @State private var currentMessageIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
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
                .accessibilityHidden(true)

                // Dots with proper SwiftUI animation
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.modusCyan)
                            .frame(width: 8, height: 8)
                            .scaleEffect(dotAnimations[index] ? 1.2 : 0.8)
                            .opacity(dotAnimations[index] ? 1 : 0.4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.modusLightTeal)
                .cornerRadius(CornerRadius.lg)
            }

            // Engaging thinking message
            Text(Self.thinkingMessages[currentMessageIndex])
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 48) // Align with bubble
                .transition(.opacity)
        }
        .onAppear {
            startDotAnimation()
            startMessageRotation()
        }
        .accessibilityLabel("AI Coach is thinking. \(Self.thinkingMessages[currentMessageIndex])")
    }

    private func startDotAnimation() {
        // Staggered animation for each dot
        for index in 0..<3 {
            withAnimation(
                Animation
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.2)
            ) {
                dotAnimations[index] = true
            }
        }
    }

    private func startMessageRotation() {
        // Rotate through messages every 2.5 seconds using a task
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentMessageIndex = (currentMessageIndex + 1) % Self.thinkingMessages.count
                }
            }
        }
    }
}

// MARK: - AI Coach Loading View

/// Engaging loading view shown while initial insights are being fetched
struct AICoachLoadingView: View {
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Animated brain icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.modusCyan.opacity(0.2), Color.modusTealAccent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 36))
                    .foregroundColor(.modusCyan)
                    .symbolEffect(.pulse, options: .repeating)
            }
            .accessibilityHidden(true)

            VStack(spacing: Spacing.xs) {
                Text("Preparing Your Insights")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Analyzing your health data, workouts, and recovery patterns...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Shimmer placeholder cards
            VStack(spacing: Spacing.sm) {
                ForEach(0..<3, id: \.self) { _ in
                    ShimmerPlaceholderCard()
                }
            }
        }
        .padding(.vertical, Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading your personalized health insights")
    }
}

/// Shimmer placeholder card for loading states
private struct ShimmerPlaceholderCard: View {
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        RoundedRectangle(cornerRadius: CornerRadius.md)
            .fill(Color(.secondarySystemGroupedBackground))
            .frame(height: 80)
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 100)
                        .offset(x: shimmerOffset)
                        .onAppear {
                            withAnimation(
                                Animation
                                    .linear(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                            ) {
                                shimmerOffset = geometry.size.width + 100
                            }
                        }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}

// FlowLayout and RoundedCorner defined in ExerciseDetailSheet.swift and ExerciseVideoView.swift

#Preview {
    UnifiedAICoachView()
}
