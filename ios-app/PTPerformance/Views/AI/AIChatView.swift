//
//  AIChatView.swift
//  PTPerformance
//
//  Build 77 - AI Helper MVP
//  ACP-1024 - Chat UI Polish: typing indicator, message animations,
//  quick action chips, pin/bookmark, search, Modus brand styling
//

import SwiftUI

struct AIChatView: View {
    @ObservedObject private var chatService = AIChatService.shared
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy?
    @State private var errorMessage: String?
    @State private var showErrorBanner = false
    @State private var lastFailedMessage: String?
    @State private var showSearch = false
    @State private var showPinnedSection = false
    @State private var appearedMessageIds: Set<UUID> = []
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            chatHeader

            // Search Bar
            if showSearch {
                searchBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Pinned Messages Section
            if showPinnedSection && !chatService.pinnedMessages.isEmpty {
                pinnedMessagesSection
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Error Banner
            if showErrorBanner, let error = errorMessage {
                errorBannerView(error)
            }

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        if chatService.filteredMessages.isEmpty && chatService.searchQuery.isEmpty {
                            emptyStateView
                        } else if chatService.filteredMessages.isEmpty && !chatService.searchQuery.isEmpty {
                            noSearchResultsView
                        } else {
                            ForEach(chatService.filteredMessages) { message in
                                ChatBubblePolished(
                                    message: message,
                                    isPinned: chatService.isPinned(message.id),
                                    isLastAssistantMessage: isLastAssistantMessage(message),
                                    quickActions: isLastAssistantMessage(message) ? chatService.latestQuickActions : [],
                                    onPin: {
                                        withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                                            chatService.togglePin(for: message.id)
                                        }
                                        HapticFeedback.medium()
                                    },
                                    onQuickAction: { action in
                                        messageText = action.prompt
                                        sendMessage()
                                    }
                                )
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                            }

                            // ACP-1023: Follow-up suggestions from AI response
                            if !chatService.followUpSuggestions.isEmpty && !chatService.isLoading {
                                followUpSuggestionsView
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }

                            // Typing Indicator
                            if chatService.isLoading {
                                AIChatTypingIndicator()
                                    .id("typing-indicator")
                                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            }

                            // Show inline error after last message if needed
                            if let error = errorMessage, !showErrorBanner {
                                inlineErrorView(error)
                            }
                        }
                    }
                    .padding()
                    .animation(.easeInOut(duration: AnimationDuration.standard), value: chatService.messages.count)
                    .animation(.easeInOut(duration: AnimationDuration.standard), value: chatService.isLoading)
                }
                .onAppear {
                    scrollProxy = proxy
                }
                .onChange(of: chatService.messages.count) { _, _ in
                    if let lastMessage = chatService.messages.last {
                        withAnimation(.easeOut(duration: AnimationDuration.standard)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: chatService.isLoading) { _, newValue in
                    if newValue {
                        withAnimation(.easeOut(duration: AnimationDuration.standard)) {
                            proxy.scrollTo("typing-indicator", anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input
            chatInputField
        }
        .task {
            await chatService.loadHistory()
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: Spacing.sm) {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(Color.modusCyan.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16))
                    .foregroundColor(.modusCyan)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("AI Assistant")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)

                if chatService.isLoading {
                    Text("Thinking...")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                } else {
                    Text("Online")
                        .font(.caption)
                        .foregroundColor(.modusTealAccent)
                }
            }

            Spacer()

            // Search toggle
            Button {
                withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                    showSearch.toggle()
                    if !showSearch {
                        chatService.searchQuery = ""
                    }
                }
                HapticFeedback.light()
            } label: {
                Image(systemName: showSearch ? "magnifyingglass.circle.fill" : "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(.modusCyan)
            }
            .accessibilityLabel(showSearch ? "Close search" : "Search messages")

            // Pinned toggle
            Button {
                withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                    showPinnedSection.toggle()
                }
                HapticFeedback.light()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: showPinnedSection ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 20))
                        .foregroundColor(.modusCyan)

                    if !chatService.pinnedMessages.isEmpty {
                        Text("\(chatService.pinnedMessages.count)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Color.modusTealAccent)
                            .clipShape(Circle())
                            .offset(x: 6, y: -6)
                    }
                }
            }
            .accessibilityLabel("Pinned messages (\(chatService.pinnedMessages.count))")

            // New Chat
            Button {
                chatService.startNewSession()
                errorMessage = nil
                showErrorBanner = false
                HapticFeedback.medium()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20))
                    .foregroundColor(.modusCyan)
            }
            .accessibilityLabel("Start new chat")
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.sm)
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            TextField("Search messages...", text: $chatService.searchQuery)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .accessibilityLabel("Search conversation history")

            if !chatService.searchQuery.isEmpty {
                Button {
                    chatService.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .padding(.horizontal)
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Pinned Messages Section

    private var pinnedMessagesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "bookmark.fill")
                    .font(.caption)
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)

                Text("Pinned Messages")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.modusDeepTeal)

                Spacer()

                Text("\(chatService.pinnedMessages.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(chatService.pinnedMessages) { message in
                        PinnedMessageCard(
                            message: message,
                            onUnpin: {
                                withAnimation {
                                    chatService.togglePin(for: message.id)
                                }
                                HapticFeedback.light()
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, Spacing.xs)
        .background(Color.modusLightTeal)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
                .frame(height: 40)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.modusCyan.opacity(0.15), Color.modusTealAccent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 36))
                    .foregroundColor(.modusCyan)
            }
            .accessibilityHidden(true)

            Text("Ask me anything about your program!")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)

            Text("I can help with exercises, form, programming, recovery, and more.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)

            VStack(spacing: Spacing.xs) {
                AIChatSuggestionChip(text: "How do I do a goblet squat?", icon: "figure.strengthtraining.traditional") {
                    messageText = "How do I do a goblet squat?"
                    sendMessage()
                }
                AIChatSuggestionChip(text: "Why was I assigned this exercise?", icon: "questionmark.circle") {
                    messageText = "Why was I assigned this exercise?"
                    sendMessage()
                }
                AIChatSuggestionChip(text: "What if I can't complete my session?", icon: "exclamationmark.triangle") {
                    messageText = "What if I can't complete my session?"
                    sendMessage()
                }
            }
            .padding(.top, Spacing.xs)
        }
        .padding()
        .accessibilityElement(children: .contain)
    }

    // MARK: - No Search Results

    private var noSearchResultsView: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text("No messages found")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Try a different search term")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, Spacing.xxl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No messages found for search query: \(chatService.searchQuery)")
    }

    // MARK: - Error Banner View

    private func errorBannerView(_ error: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Message Failed")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(error)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }

            Spacer()

            if let failedText = lastFailedMessage {
                Button {
                    retryMessage(failedText)
                } label: {
                    Text("Retry")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(CornerRadius.sm)
                }
            }

            Button {
                withAnimation {
                    showErrorBanner = false
                    errorMessage = nil
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(Color.orange)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error). Tap retry to try again.")
    }

    // MARK: - Inline Error View

    private func inlineErrorView(_ error: String) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                    .accessibilityHidden(true)

                Text("Unable to get a response")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let failedText = lastFailedMessage {
                Button {
                    retryMessage(failedText)
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(CornerRadius.md)
        .padding(.horizontal)
    }

    // MARK: - Chat Input Field

    private var chatInputField: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Ask a question...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.xl)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .disabled(chatService.isLoading)
                .submitLabel(.send)
                .onSubmit {
                    sendMessage()
                }
                .accessibilityLabel("Message input")
                .accessibilityHint("Type your question for the AI assistant")

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatService.isLoading ? .gray : .modusCyan)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatService.isLoading)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.sm)
        .background(Color(.systemBackground))
    }

    // MARK: - Send Message

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messageText = ""
        lastFailedMessage = text
        errorMessage = nil
        showErrorBanner = false

        Task {
            do {
                _ = try await chatService.sendMessage(text)
                lastFailedMessage = nil
                HapticFeedback.success()
            } catch {
                DebugLogger.shared.error("AIChatView", "Failed to send message: \(error.localizedDescription)")

                // Determine user-friendly error message
                let userMessage: String
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet, .networkConnectionLost:
                        userMessage = "No internet connection. Please check your network and try again."
                    case .timedOut:
                        userMessage = "The request timed out. The AI service may be busy."
                    default:
                        userMessage = "Network error. Please try again."
                    }
                } else if error.localizedDescription.contains("Invalid response") {
                    userMessage = "Received an invalid response. Please try again."
                } else {
                    userMessage = "Something went wrong. Please try again."
                }

                await MainActor.run {
                    errorMessage = userMessage
                    // Show inline error if there are messages, banner if empty
                    showErrorBanner = chatService.messages.isEmpty
                }
                HapticFeedback.error()
            }
        }
    }

    // MARK: - Retry Message

    private func retryMessage(_ text: String) {
        messageText = text
        sendMessage()
    }

    // MARK: - Follow-up Suggestions (ACP-1023)

    private var followUpSuggestionsView: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Suggested follow-ups")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 44) // Align with message content (avatar + spacing)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(chatService.followUpSuggestions.prefix(3), id: \.self) { suggestion in
                        Button {
                            HapticFeedback.light()
                            messageText = suggestion
                            sendMessage()
                        } label: {
                            Text(suggestion)
                                .font(.caption)
                                .foregroundColor(.modusCyan)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.modusCyan.opacity(0.1))
                                .cornerRadius(CornerRadius.lg)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                                        .stroke(Color.modusCyan.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Ask: \(suggestion)")
                    }
                }
                .padding(.horizontal, 44)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }

    // MARK: - Helpers

    private func isLastAssistantMessage(_ message: ChatMessage) -> Bool {
        guard message.role == "assistant" else { return false }
        guard let lastAssistant = chatService.messages.last(where: { $0.role == "assistant" }) else { return false }
        return lastAssistant.id == message.id
    }
}

// MARK: - Polished Chat Bubble

struct ChatBubblePolished: View {
    let message: ChatMessage
    let isPinned: Bool
    let isLastAssistantMessage: Bool
    let quickActions: [ChatQuickAction]
    let onPin: () -> Void
    let onQuickAction: (ChatQuickAction) -> Void

    @State private var appeared = false
    @State private var showContextMenu = false

    private var isUser: Bool {
        message.role == "user"
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            if isUser {
                Spacer(minLength: 60)
            } else {
                // AI Avatar
                ZStack {
                    Circle()
                        .fill(Color.modusCyan.opacity(0.2))
                        .frame(width: 32, height: 32)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14))
                        .foregroundColor(.modusCyan)
                }
                .accessibilityHidden(true)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: Spacing.xxs) {
                // Message Content
                Text(message.content)
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? Color.modusCyan : Color(.secondarySystemGroupedBackground))
                    .foregroundColor(isUser ? .white : .primary)
                    .cornerRadius(CornerRadius.lg)
                    .contextMenu {
                        Button {
                            onPin()
                        } label: {
                            Label(
                                isPinned ? "Unpin Message" : "Pin Message",
                                systemImage: isPinned ? "bookmark.slash" : "bookmark"
                            )
                        }

                        Button {
                            UIPasteboard.general.string = message.content
                            HapticFeedback.light()
                        } label: {
                            Label("Copy Text", systemImage: "doc.on.doc")
                        }
                    }

                // Pinned indicator
                if isPinned {
                    HStack(spacing: 4) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.modusTealAccent)
                        Text("Pinned")
                            .font(.caption2)
                            .foregroundColor(.modusTealAccent)
                    }
                }

                // Quick Action Chips (only on last assistant message)
                if isLastAssistantMessage && !quickActions.isEmpty {
                    quickActionChips
                        .padding(.top, Spacing.xxs)
                }

                // Timestamp
                Text(timeAgo(message.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !isUser {
                Spacer(minLength: 40)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: AnimationDuration.standard).delay(0.05)) {
                appeared = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isUser ? "You" : "AI Assistant") said: \(message.content), \(timeAgo(message.createdAt))\(isPinned ? ", pinned" : "")")
        .accessibilityHint("Long press for options")
    }

    // MARK: - Quick Action Chips

    private var quickActionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(quickActions) { action in
                    Button {
                        HapticFeedback.light()
                        onQuickAction(action)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: action.icon)
                                .font(.caption2)
                            Text(action.title)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.modusCyan.opacity(0.1))
                        .foregroundColor(.modusCyan)
                        .cornerRadius(CornerRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.lg)
                                .stroke(Color.modusCyan.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Quick action: \(action.title)")
                }
            }
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - AI Chat Typing Indicator (Three Bouncing Dots)

struct AIChatTypingIndicator: View {
    @State private var dotAnimations = [false, false, false]

    private static let thinkingMessages = [
        "Analyzing your question...",
        "Reviewing your program...",
        "Preparing a response..."
    ]

    @State private var currentMessageIndex = 0

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(Color.modusCyan.opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundColor(.modusCyan)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Bouncing dots
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.modusCyan)
                            .frame(width: 8, height: 8)
                            .scaleEffect(dotAnimations[index] ? 1.3 : 0.7)
                            .opacity(dotAnimations[index] ? 1 : 0.4)
                            .offset(y: dotAnimations[index] ? -4 : 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.lg)

                // Thinking message
                Text(Self.thinkingMessages[currentMessageIndex])
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }

            Spacer(minLength: 40)
        }
        .onAppear {
            startDotAnimation()
            startMessageRotation()
        }
        .accessibilityLabel("AI Assistant is thinking. \(Self.thinkingMessages[currentMessageIndex])")
    }

    private func startDotAnimation() {
        for index in 0..<3 {
            withAnimation(
                Animation
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.15)
            ) {
                dotAnimations[index] = true
            }
        }
    }

    private func startMessageRotation() {
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentMessageIndex = (currentMessageIndex + 1) % Self.thinkingMessages.count
                }
            }
        }
    }
}

// MARK: - Suggestion Chip (for empty state)

struct AIChatSuggestionChip: View {
    let text: String
    let icon: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.modusCyan)
                    .frame(width: 20)
                    .accessibilityHidden(true)

                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.modusCyan.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
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
        .accessibilityLabel("Suggested question: \(text)")
        .accessibilityHint("Tap to ask this question")
    }
}

// MARK: - Pinned Message Card

struct PinnedMessageCard: View {
    let message: ChatMessage
    let onUnpin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: 4) {
                Image(systemName: message.role == "user" ? "person.fill" : "brain.head.profile")
                    .font(.system(size: 10))
                    .foregroundColor(message.role == "user" ? .modusCyan : .modusTealAccent)
                    .accessibilityHidden(true)

                Text(message.role == "user" ? "You" : "AI")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    onUnpin()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Unpin message")
            }

            Text(message.content)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(3)
        }
        .frame(width: 200)
        .padding(Spacing.sm)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.sm)
        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pinned message from \(message.role == "user" ? "you" : "AI Assistant"): \(message.content)")
    }
}

// Preview
struct AIChatView_Previews: PreviewProvider {
    static var previews: some View {
        AIChatView()
    }
}
