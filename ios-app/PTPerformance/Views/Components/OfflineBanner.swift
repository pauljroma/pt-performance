// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  OfflineBanner.swift
//  PTPerformance
//
//  Build 95 - Agent 9: Offline mode indicator banner
//  Updated: Added pending sync indicator for offline queue
//

import SwiftUI

/// Banner that appears when the app is offline or has pending sync items
/// Shows user-friendly message, pending count, and retry option
struct OfflineBanner: View {
    @ObservedObject var supabase = PTSupabaseClient.shared
    @ObservedObject var offlineQueue = OfflineQueueManager.shared
    @State private var isCheckingConnection = false

    /// Show banner when offline OR when there are pending sync items
    private var shouldShowBanner: Bool {
        supabase.isOffline || offlineQueue.hasPendingItems
    }

    var body: some View {
        if shouldShowBanner {
            VStack(spacing: 0) {
                HStack(spacing: Spacing.sm) {
                    // Icon - different based on state
                    if supabase.isOffline {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    } else if offlineQueue.isSyncing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        // Title based on state
                        if supabase.isOffline {
                            Text("You're Offline")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        } else if offlineQueue.isSyncing {
                            Text("Syncing...")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        } else {
                            Text("Pending Sync")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        // Subtitle with pending count
                        if offlineQueue.pendingCount > 0 {
                            Text("\(offlineQueue.pendingCount) exercise log\(offlineQueue.pendingCount == 1 ? "" : "s") waiting to sync")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                        } else if supabase.isOffline {
                            Text("Some features may not be available")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                        }

                        // Show sync error if present
                        if let error = offlineQueue.lastSyncError {
                            Text(error)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    Spacer()

                    // Action button - Retry or Sync Now
                    Button(action: handleAction) {
                        if isCheckingConnection || offlineQueue.isSyncing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text(supabase.isOffline ? "Retry" : "Sync Now")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs - 2)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(CornerRadius.xs + 2)
                        }
                    }
                    .disabled(isCheckingConnection || offlineQueue.isSyncing)
                    .accessibilityLabel(supabase.isOffline ? "Retry connection" : "Sync pending changes now")
                    .accessibilityHint(supabase.isOffline ? "Attempts to reconnect to the server" : "Syncs all pending changes immediately")
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(bannerColor)
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: shouldShowBanner)
        }
    }

    /// Banner color based on state
    private var bannerColor: Color {
        if supabase.isOffline {
            return Color(.systemOrange)
        } else if offlineQueue.lastSyncError != nil {
            return Color(.systemRed)
        } else {
            return .modusCyan
        }
    }

    // MARK: - Actions

    private func handleAction() {
        if supabase.isOffline {
            checkConnection()
        } else {
            syncPending()
        }
    }

    private func checkConnection() {
        isCheckingConnection = true

        Task {
            let isOnline = await supabase.checkNetworkStatus()

            await MainActor.run {
                isCheckingConnection = false

                if isOnline {
                    // Show success feedback
                    withAnimation {
                        supabase.isOffline = false
                    }

                    // Trigger sync of pending items
                    Task {
                        await offlineQueue.syncPendingLogs()
                    }
                }
            }
        }
    }

    private func syncPending() {
        Task {
            await offlineQueue.forcSync()
        }
    }
}

// MARK: - Compact Sync Indicator

/// Small indicator showing pending sync count for use in toolbars/headers
struct PendingSyncIndicator: View {
    @ObservedObject var offlineQueue = OfflineQueueManager.shared

    var body: some View {
        if offlineQueue.pendingCount > 0 {
            HStack(spacing: Spacing.xxs) {
                if offlineQueue.isSyncing {
                    ProgressView()
                        .scaleEffect(0.6)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption2)
                }

                Text("\(offlineQueue.pendingCount)")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(offlineQueue.isSyncing ? Color.modusCyan : Color(.systemOrange))
            .clipShape(Capsule())
            .accessibilityLabel("\(offlineQueue.pendingCount) items pending sync")
            .accessibilityHint(offlineQueue.isSyncing ? "Currently syncing" : "Waiting to sync")
        }
    }
}

// MARK: - Preview

#if DEBUG
struct OfflineBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Offline state
            Group {
                OfflineBanner()
            }
            .onAppear {
                PTSupabaseClient.shared.isOffline = true
            }

            Divider()

            // Pending sync indicator
            PendingSyncIndicator()

            Spacer()
        }
    }
}
#endif
