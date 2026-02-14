// DARK MODE: See ModeThemeModifier.swift for central theme control
import SwiftUI

struct AIHealthCoachView: View {
    @StateObject private var viewModel = HealthCoachViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Error banner with retry
                if let error = viewModel.error, !viewModel.isLoading {
                    HealthCoachErrorBanner(
                        error: error,
                        onRetry: {
                            Task { await viewModel.retryLoad() }
                        }
                    )
                }

                // Health Score Summary
                if viewModel.isLoading && viewModel.healthScore == nil {
                    scoreLoadingHeader
                } else if let score = viewModel.healthScore {
                    scoreHeader(score)
                }

                Divider()

                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Quick Questions
                            if viewModel.messages.count <= 1 && !viewModel.isLoading {
                                quickQuestionsSection
                            }

                            // Messages
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                                        removal: .opacity
                                    ))
                            }

                            // Typing indicator with engaging message
                            if viewModel.isTyping {
                                HStack {
                                    HealthCoachTypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .padding()
                        .animation(.easeInOut(duration: 0.3), value: viewModel.messages.count)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input Field
                chatInputField
            }
            .navigationTitle("AI Health Coach")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Score Loading Header

    private var scoreLoadingHeader: some View {
        HStack(spacing: 16) {
            // Placeholder Score Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                ProgressView()
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text("Loading health score...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }

    private func scoreHeader(_ score: HealthScore) -> some View {
        HStack(spacing: 16) {
            // Score Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: Double(score.overallScore) / 100)
                    .stroke(viewModel.scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(score.overallScore)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("score")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.scoreDescription)
                    .font(.headline)

                HStack(spacing: 4) {
                    Image(systemName: viewModel.scoreTrend.icon)
                    Text(viewModel.scoreTrend == .improving ? "Improving" : viewModel.scoreTrend == .declining ? "Declining" : "Stable")
                }
                .font(.caption)
                .foregroundColor(Color(viewModel.scoreTrend.color))
            }

            Spacer()

            Button {
                Task {
                    await viewModel.calculateScore()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(viewModel.isLoading)
            .accessibilityLabel("Refresh health score")
            .accessibilityHint("Recalculates your health score based on latest data")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .accessibilityElement(children: .contain)
    }

    private var quickQuestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Questions")
                .font(.subheadline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                QuickQuestionButton(text: "How's my recovery?", icon: "heart.fill") {
                    Task { await viewModel.askQuickQuestion("How is my recovery looking based on my recent data?") }
                }
                QuickQuestionButton(text: "Sleep insights", icon: "moon.fill") {
                    Task { await viewModel.askQuickQuestion("What insights do you have about my sleep patterns?") }
                }
                QuickQuestionButton(text: "Training advice", icon: "figure.run") {
                    Task { await viewModel.askQuickQuestion("Based on my readiness, what training should I do today?") }
                }
                QuickQuestionButton(text: "Nutrition tips", icon: "leaf.fill") {
                    Task { await viewModel.askQuickQuestion("What nutrition recommendations do you have for me?") }
                }
            }
        }
        .padding(.vertical)
    }

    private var chatInputField: some View {
        HStack(spacing: 12) {
            TextField("Ask about your health...", text: $viewModel.inputMessage)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.send)
                .onSubmit {
                    Task { await viewModel.sendMessage() }
                }
                .accessibilityLabel("Message input")
                .accessibilityHint("Type your health question here")

            Button {
                Task { await viewModel.sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send message")
            .accessibilityHint("Sends your question to the AI Health Coach")
        }
        .padding()
    }
}

struct MessageBubble: View {
    let message: HealthCoachMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if let category = message.category {
                    Label(category.displayName, systemImage: category.icon)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Category: \(category.displayName)")
                }

                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.role == .user ? Color.modusCyan : Color(.tertiarySystemGroupedBackground))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(CornerRadius.lg)

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(message.role == .user ? "You" : "AI Coach") said: \(message.content), at \(message.timestamp.formatted(date: .omitted, time: .shortened))")

            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

struct QuickQuestionButton: View {
    let text: String
    let icon: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)
                Text(text)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, Spacing.xs)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.sm)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                        isPressed = false
                    }
                }
        )
        .accessibilityLabel("Ask: \(text)")
        .accessibilityHint("Sends this quick question to the AI Coach")
    }
}

// MARK: - Health Coach Error Banner

struct HealthCoachErrorBanner: View {
    let error: String
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .accessibilityHidden(true)

            Text(error)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)

            Spacer()

            Button {
                HapticFeedback.light()
                onRetry()
            } label: {
                Text("Retry")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.modusCyan)
            }
            .accessibilityLabel("Retry loading")
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error). Tap retry to try again.")
    }
}

// MARK: - Health Coach Typing Indicator

struct HealthCoachTypingIndicator: View {
    @State private var dotAnimations = [false, false, false]

    private static let thinkingMessages = [
        "Analyzing your health data...",
        "Reviewing your metrics...",
        "Preparing recommendations..."
    ]

    @State private var currentMessageIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.modusCyan)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotAnimations[index] ? 1.2 : 0.8)
                        .opacity(dotAnimations[index] ? 1 : 0.4)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, Spacing.sm)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(CornerRadius.lg)

            Text(Self.thinkingMessages[currentMessageIndex])
                .font(.caption)
                .foregroundColor(.secondary)
                .transition(.opacity)
        }
        .onAppear {
            startDotAnimation()
            startMessageRotation()
        }
        .accessibilityLabel("AI Coach is thinking. \(Self.thinkingMessages[currentMessageIndex])")
    }

    private func startDotAnimation() {
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
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentMessageIndex = (currentMessageIndex + 1) % Self.thinkingMessages.count
                }
            }
        }
    }
}

// Legacy TypingIndicator for backward compatibility
struct TypingIndicator: View {
    @State private var dotAnimations = [false, false, false]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotAnimations[index] ? 1.2 : 0.8)
                    .opacity(dotAnimations[index] ? 1 : 0.4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, Spacing.sm)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .onAppear {
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
        .accessibilityLabel("AI Coach is typing")
    }
}
