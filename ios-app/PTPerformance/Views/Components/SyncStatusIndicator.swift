// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  SyncStatusIndicator.swift
//  PTPerformance
//
//  ACP-516: Sub-100ms Interaction Response
//  Visual indicator for background sync status
//

import SwiftUI
import Combine

/// Displays the current sync status of pending changes
/// Shows when changes are pending, syncing, or if errors occurred
struct SyncStatusIndicator: View {
    @ObservedObject var pendingQueue = PendingChangesQueue.shared

    @State private var showDetails = false
    @State private var isAnimating = false

    var body: some View {
        if pendingQueue.hasPendingChanges || pendingQueue.hasFailedChanges {
            Button {
                HapticService.light()
                showDetails = true
            } label: {
                statusBadge
            }
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Shows sync status details")
            .sheet(isPresented: $showDetails) {
                SyncStatusDetailView()
            }
        }
    }

    private var accessibilityLabel: String {
        if pendingQueue.isSyncing {
            return "Syncing changes"
        } else if pendingQueue.hasFailedChanges {
            return "Sync issue detected"
        } else {
            return "\(pendingQueue.pendingCount) changes pending sync"
        }
    }

    private var statusBadge: some View {
        HStack(spacing: Spacing.xs - 2) {
            statusIcon
            statusText
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs - 2)
        .background(backgroundColor)
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var statusIcon: some View {
        Group {
            if pendingQueue.isSyncing {
                ProgressView()
                    .scaleEffect(0.7)
            } else if pendingQueue.hasFailedChanges {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            } else {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.modusCyan)
                    .font(.caption)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .onAppear {
                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                            isAnimating = true
                        }
                    }
            }
        }
    }

    private var statusText: some View {
        Text(statusMessage)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(textColor)
    }

    private var statusMessage: String {
        if pendingQueue.isSyncing {
            return "Syncing..."
        } else if pendingQueue.hasFailedChanges {
            return "Sync issue"
        } else {
            return "\(pendingQueue.pendingCount) pending"
        }
    }

    private var backgroundColor: Color {
        if pendingQueue.hasFailedChanges {
            return Color(.systemOrange).opacity(0.15)
        }
        return Color.modusCyan.opacity(0.15)
    }

    private var borderColor: Color {
        if pendingQueue.hasFailedChanges {
            return Color(.systemOrange).opacity(0.3)
        }
        return Color.modusCyan.opacity(0.3)
    }

    private var textColor: Color {
        if pendingQueue.hasFailedChanges {
            return Color(.systemOrange)
        }
        return .modusCyan
    }
}

// MARK: - Sync Status Detail View

struct SyncStatusDetailView: View {
    @ObservedObject var pendingQueue = PendingChangesQueue.shared
    @ObservedObject var optimisticManager = OptimisticUpdateManager.shared

    @Environment(\.dismiss) var dismiss
    @State private var isSyncing = false

    var body: some View {
        NavigationStack {
            List {
                // Summary Section
                Section {
                    statusSummaryRow
                } header: {
                    Text("Status")
                }

                // Pending Changes Section
                if pendingQueue.pendingCount > 0 {
                    Section {
                        ForEach(groupedChanges, id: \.0) { (type, count) in
                            changeTypeRow(type: type, count: count)
                        }
                    } header: {
                        Text("Pending Changes")
                    }
                }

                // Failed Changes Section
                if pendingQueue.hasFailedChanges {
                    Section {
                        Text("Some changes failed to sync. They will be retried automatically when connectivity improves.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button(role: .destructive) {
                            HapticService.warning()
                            pendingQueue.clearFailedChanges()
                        } label: {
                            Label("Clear Failed Changes", systemImage: "trash")
                        }
                    } header: {
                        Text("Failed Changes")
                    } footer: {
                        Text("Clearing failed changes means those updates will be lost.")
                    }
                }

                // Actions Section
                Section {
                    Button {
                        Task {
                            isSyncing = true
                            HapticService.medium()
                            await pendingQueue.forceSync()
                            isSyncing = false
                        }
                    } label: {
                        HStack {
                            Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            if isSyncing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isSyncing || pendingQueue.pendingCount == 0)
                } header: {
                    Text("Actions")
                }

                #if DEBUG
                // Debug Section
                Section {
                    Button("Print Queue Status") {
                        pendingQueue.printStatus()
                    }

                    Button("Print Response Time Report") {
                        ResponseTimeMonitor.shared.printStats()
                    }

                    Button(role: .destructive) {
                        pendingQueue.clearQueue()
                    } label: {
                        Text("Clear All Pending")
                    }
                } header: {
                    Text("Debug")
                }
                #endif
            }
            .navigationTitle("Sync Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Done")
                    .accessibilityHint("Closes sync status details")
                }
            }
        }
    }

    private var statusSummaryRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(overallStatus)
                    .font(.headline)

                if let lastSync = pendingQueue.lastSyncTime {
                    Text("Last sync: \(lastSync, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            statusIndicator
        }
    }

    private var overallStatus: String {
        if pendingQueue.isSyncing {
            return "Syncing..."
        } else if pendingQueue.hasFailedChanges {
            return "Sync Issues"
        } else if pendingQueue.hasPendingChanges {
            return "Changes Pending"
        } else {
            return "All Synced"
        }
    }

    private var statusIndicator: some View {
        Group {
            if pendingQueue.isSyncing {
                ProgressView()
            } else if pendingQueue.hasFailedChanges {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            } else if pendingQueue.hasPendingChanges {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.modusCyan)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .font(.title2)
    }

    private var groupedChanges: [(PendingChangeType, Int)] {
        let stats = pendingQueue.statistics()
        return stats.byType.sorted { $0.value > $1.value }
    }

    private func changeTypeRow(type: PendingChangeType, count: Int) -> some View {
        HStack {
            Image(systemName: iconForType(type))
                .foregroundColor(.modusCyan)
                .frame(width: 24)

            Text(labelForType(type))

            Spacer()

            Text("\(count)")
                .foregroundColor(.secondary)
        }
    }

    private func iconForType(_ type: PendingChangeType) -> String {
        switch type {
        case .exerciseLog: return "dumbbell.fill"
        case .sessionCompletion: return "checkmark.circle.fill"
        case .workoutProgress: return "chart.line.uptrend.xyaxis"
        case .exerciseModification: return "arrow.triangle.swap"
        case .notesUpdate: return "note.text"
        case .rpeUpdate: return "gauge"
        case .painScoreUpdate: return "waveform.path.ecg"
        }
    }

    private func labelForType(_ type: PendingChangeType) -> String {
        switch type {
        case .exerciseLog: return "Exercise Logs"
        case .sessionCompletion: return "Workout Completions"
        case .workoutProgress: return "Progress Updates"
        case .exerciseModification: return "Exercise Changes"
        case .notesUpdate: return "Notes"
        case .rpeUpdate: return "RPE Updates"
        case .painScoreUpdate: return "Pain Scores"
        }
    }
}

// MARK: - Compact Sync Badge

/// Minimal sync indicator for toolbar or small spaces
struct CompactSyncBadge: View {
    @ObservedObject var pendingQueue = PendingChangesQueue.shared

    var body: some View {
        if pendingQueue.hasPendingChanges || pendingQueue.hasFailedChanges {
            ZStack {
                Circle()
                    .fill(badgeColor)
                    .frame(width: 8, height: 8)

                if pendingQueue.isSyncing {
                    Circle()
                        .stroke(badgeColor, lineWidth: 2)
                        .frame(width: 14, height: 14)
                        .opacity(0.5)
                }
            }
        }
    }

    private var badgeColor: Color {
        if pendingQueue.hasFailedChanges {
            return Color(.systemOrange)
        }
        return .modusCyan
    }
}

// MARK: - Preview

#if DEBUG
struct SyncStatusIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SyncStatusIndicator()

            HStack {
                Text("Toolbar Item")
                Spacer()
                CompactSyncBadge()
            }
            .padding()
        }
    }
}
#endif
