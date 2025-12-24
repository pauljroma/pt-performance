//
//  AIChatView.swift
//  PTPerformance
//
//  Build 77 - AI Helper MVP
//

import SwiftUI

struct AIChatView: View {
    @StateObject private var chatService = AIChatService.shared
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy?

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
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(radius: 1)

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if chatService.messages.isEmpty {
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
                        } else {
                            ForEach(chatService.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    scrollProxy = proxy
                }
                .onChange(of: chatService.messages.count) { _ in
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

    private func sendMessage() {
        let text = messageText
        messageText = ""

        Task {
            do {
                _ = try await chatService.sendMessage(text)
            } catch {
                print("❌ Failed to send message: \(error)")
            }
        }
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
                    .cornerRadius(16)

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
