// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  DebugLogView.swift
//  PTPerformance
//
//  Build 94: Enhanced debug log viewer with persistence
//

import SwiftUI

/// Enhanced debug log viewer with file persistence and export
struct DebugLogView: View {
    @ObservedObject var logger = LoggingService.shared
    @Environment(\.dismiss) var dismiss

    @State private var selectedFilter: LogFilter = .all
    @State private var showShareSheet = false
    @State private var searchText = ""

    enum LogFilter: String, CaseIterable {
        case all = "All"
        case error = "Errors"
        case warning = "Warnings"
        case success = "Success"
        case diagnostic = "Diagnostic"

        var level: LoggingService.LogLevel? {
            switch self {
            case .all: return nil
            case .error: return .error
            case .warning: return .warning
            case .success: return .success
            case .diagnostic: return .diagnostic
            }
        }
    }

    var filteredMessages: [LoggingService.LogMessage] {
        var messages = logger.messages

        // Apply level filter
        if let level = selectedFilter.level {
            messages = messages.filter { $0.level == level }
        }

        // Apply search filter
        if !searchText.isEmpty {
            messages = messages.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }

        return messages
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(.secondaryLabel))
                        .accessibilityHidden(true)
                    TextField("Search logs...", text: $searchText)
                        .textFieldStyle(.plain)
                        .accessibilityLabel("Search logs")
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        .accessibilityLabel("Clear search")
                        .accessibilityHint("Clears the search text")
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))

                // Filter picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(LogFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .accessibilityLabel("Log filter")
                .accessibilityHint("Filter logs by type")

                // Stats bar
                statsBar

                Divider()

                // Log messages
                logMessagesView

                Divider()

                // Action buttons
                actionButtons
            }
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    exportButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Done")
                    .accessibilityHint("Closes the debug log view")
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let fileURL = logger.exportLogs() {
                    ShareSheet(items: [fileURL])
                }
            }
        }
    }

    private var statsBar: some View {
        let stats = logger.logStats
        return HStack(spacing: 12) {
            statItem(icon: "doc.text", value: "\(filteredMessages.count)/\(stats.totalMessages)", label: "Total")
            if stats.errorCount > 0 {
                statItem(icon: "xmark.circle.fill", value: "\(stats.errorCount)", label: "Errors", color: .red)
            }
            if stats.warningCount > 0 {
                statItem(icon: "exclamationmark.triangle.fill", value: "\(stats.warningCount)", label: "Warnings", color: .orange)
            }
            Spacer()
            Text(stats.fileSizeFormatted)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
    }

    private func statItem(icon: String, value: String, label: String, color: Color = .primary) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption2)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var logMessagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if filteredMessages.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 48))
                                .foregroundColor(Color(.secondaryLabel))
                                .accessibilityHidden(true)
                            Text(searchText.isEmpty ? "No logs yet" : "No matching logs")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(searchText.isEmpty ? "No logs yet" : "No matching logs")
                    } else {
                        ForEach(filteredMessages) { message in
                            logRow(for: message)
                                .id(message.id)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: logger.messages.count) { _, _ in
                if let lastMessage = logger.messages.last, searchText.isEmpty, selectedFilter == .all {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func logRow(for message: LoggingService.LogMessage) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(message.formatted)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(colorForLevel(message.level))
                .textSelection(.enabled)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(backgroundColorForLevel(message.level))
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                logger.clear()
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear All")
                }
                .font(.caption)
                .foregroundColor(DesignTokens.statusError)
            }
            .accessibilityLabel("Clear All")
            .accessibilityHint("Removes all log messages")

            Button(action: {
                UIPasteboard.general.string = logger.getAllLogs()
            }) {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy All")
                }
                .font(.caption)
                .foregroundColor(DesignTokens.statusInfo)
            }
            .accessibilityLabel("Copy All")
            .accessibilityHint("Copies all log messages to clipboard")

            Spacer()

            Text("\(filteredMessages.count) messages")
                .font(.caption2)
                .foregroundColor(.secondary)
                .accessibilityLabel("\(filteredMessages.count) messages displayed")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
    }

    private var exportButton: some View {
        Button(action: {
            showShareSheet = true
        }) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Export")
            }
            .font(.caption)
        }
        .accessibilityLabel("Export")
        .accessibilityHint("Exports log messages to a file for sharing")
    }

    private func colorForLevel(_ level: LoggingService.LogLevel) -> Color {
        switch level {
        case .diagnostic: return Color(.label)
        case .success: return DesignTokens.statusSuccess
        case .error: return DesignTokens.statusError
        case .warning: return DesignTokens.statusWarning
        }
    }

    private func backgroundColorForLevel(_ level: LoggingService.LogLevel) -> Color {
        switch level {
        case .error: return DesignTokens.statusError.opacity(0.1)
        case .warning: return DesignTokens.statusWarning.opacity(0.1)
        default: return Color.clear
        }
    }
}

// MARK: - Preview

#Preview {
    DebugLogView()
}
