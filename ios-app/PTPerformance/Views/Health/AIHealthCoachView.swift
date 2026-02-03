import SwiftUI

struct AIHealthCoachView: View {
    @StateObject private var viewModel = HealthCoachViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Health Score Summary
                if let score = viewModel.healthScore {
                    scoreHeader(score)
                }

                Divider()

                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Quick Questions
                            if viewModel.messages.count <= 1 {
                                quickQuestionsSection
                            }

                            // Messages
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            // Typing indicator
                            if viewModel.isTyping {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
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
        }
        .padding()
        .background(Color(.systemGray6))
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

            Button {
                Task { await viewModel.sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
                }

                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.role == .user ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(18)

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

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

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(text)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct TypingIndicator: View {
    @State private var animationOffset = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .offset(y: animationOffset == index ? -4 : 0)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.systemGray5))
        .cornerRadius(18)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever()) {
                animationOffset = (animationOffset + 1) % 3
            }
        }
    }
}
