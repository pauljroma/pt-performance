import SwiftUI

@main
struct PTPerformanceApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userRole: UserRole? = nil   // .patient or .therapist
    @Published var userId: String? = nil       // Authenticated user ID
}

// MARK: - Debug Logger for On-Screen Diagnostics

/// Shared debug logger that captures all diagnostic messages
class DebugLogger: ObservableObject {
    static let shared = DebugLogger()

    @Published var messages: [LogMessage] = []
    @Published var isEnabled = true

    private let maxMessages = 500

    struct LogMessage: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let level: LogLevel

        var formatted: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return "[\(formatter.string(from: timestamp))] \(level.emoji) \(message)"
        }
    }

    enum LogLevel {
        case diagnostic
        case success
        case error
        case warning

        var emoji: String {
            switch self {
            case .diagnostic: return "🔍"
            case .success: return "✅"
            case .error: return "❌"
            case .warning: return "⚠️"
            }
        }
    }

    private init() {}

    func log(_ message: String, level: LogLevel = .diagnostic) {
        guard isEnabled else { return }

        DispatchQueue.main.async {
            // Also print to console
            print("\(level.emoji) [\(level)] \(message)")

            // Add to messages array
            let logMessage = LogMessage(timestamp: Date(), message: message, level: level)
            self.messages.append(logMessage)

            // Keep only last N messages
            if self.messages.count > self.maxMessages {
                self.messages.removeFirst(self.messages.count - self.maxMessages)
            }
        }
    }

    func clear() {
        DispatchQueue.main.async {
            self.messages.removeAll()
        }
    }

    func getAllLogs() -> String {
        messages.map { $0.formatted }.joined(separator: "\n")
    }
}

/// Debug log viewer that can be shown as an overlay
struct DebugLogView: View {
    @ObservedObject var logger = DebugLogger.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Stats bar
                HStack {
                    Text("\(logger.messages.count) messages")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Clear") {
                        logger.clear()
                    }
                    .font(.caption)

                    Button("Copy All") {
                        UIPasteboard.general.string = logger.getAllLogs()
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))

                Divider()

                // Log messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(logger.messages) { message in
                                Text(message.formatted)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(colorForLevel(message.level))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .id(message.id)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: logger.messages.count) { _ in
                        if let lastMessage = logger.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func colorForLevel(_ level: DebugLogger.LogLevel) -> Color {
        switch level {
        case .diagnostic: return .primary
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        }
    }
}
