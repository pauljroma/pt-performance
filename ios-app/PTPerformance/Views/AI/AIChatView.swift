//
//  AIChatView.swift
//  PTPerformance
//
//  Build 77 - AI Helper MVP
//  Updated: Added error handling for failed AI requests
//

import SwiftUI

struct AIChatView: View {
    @ObservedObject private var chatService = AIChatService.shared
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy?
    @State private var errorMessage: String?
    @State private var showErrorBanner = false
    @State private var lastFailedMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("AI Assistant")
                    .font(.headline)
                Spacer()
                Button("New Chat") {
                    chatService.startNewSession()
                    errorMessage = nil
                    showErrorBanner = false
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(radius: 1)

            // Error Banner
            if showErrorBanner, let error = errorMessage {
                errorBannerView(error)
            }

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if chatService.messages.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(chatService.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }

                            // Show inline error after last message if needed
                            if let error = errorMessage, !showErrorBanner {
                                inlineErrorView(error)
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    scrollProxy = proxy
                }
                .onChange(of: chatService.messages.count) { _, _ in
                    if let lastMessage = chatService.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input
            HStack(spacing: 12) {
                TextField("Ask a question...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(chatService.isLoading)

                Button {
                    sendMessage()
                } label: {
                    if chatService.isLoading {
                        ProgressView()
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(messageText.isEmpty ? .gray : .blue)
                    }
                }
                .disabled(messageText.isEmpty || chatService.isLoading)
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(radius: 1)
        }
        .task {
            await chatService.loadHistory()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Ask me anything about your program!")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                SuggestedQuestion(text: "How do I do a goblet squat?")
                SuggestedQuestion(text: "Why was I assigned this exercise?")
                SuggestedQuestion(text: "What if I can't complete my session?")
            }
        }
        .padding()
    }

    // MARK: - Error Banner View

    private func errorBannerView(_ error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)

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
                        .padding(.horizontal, 12)
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
    }

    // MARK: - Inline Error View

    private func inlineErrorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)

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

    // MARK: - Send Message

    private func sendMessage() {
        let text = messageText
        messageText = ""
        lastFailedMessage = text
        errorMessage = nil
        showErrorBanner = false

        Task {
            do {
                _ = try await chatService.sendMessage(text)
                lastFailedMessage = nil
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
            }
        }
    }

    // MARK: - Retry Message

    private func retryMessage(_ text: String) {
        messageText = text
        sendMessage()
    }
}

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
            }

            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.role == "user" ? Color.blue : Color(.secondarySystemBackground))
                    .foregroundColor(message.role == "user" ? .white : .primary)
                    .cornerRadius(CornerRadius.lg)

                Text(timeAgo(message.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity * 0.75, alignment: message.role == "user" ? .trailing : .leading)

            if message.role == "assistant" {
                Spacer()
            }
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct SuggestedQuestion: View {
    let text: String

    var body: some View {
        Text("💡 \(text)")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.vertical, 4)
    }
}

// Preview
struct AIChatView_Previews: PreviewProvider {
    static var previews: some View {
        AIChatView()
    }
}
