//
//  OfflineBanner.swift
//  PTPerformance
//
//  Build 95 - Agent 9: Offline mode indicator banner
//

import SwiftUI

/// Banner that appears when the app is offline
/// Shows user-friendly message and retry option
struct OfflineBanner: View {
    @ObservedObject var supabase = PTSupabaseClient.shared
    @State private var isCheckingConnection = false

    var body: some View {
        if supabase.isOffline {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("You're Offline")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Some features may not be available")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Spacer()

                    // Retry button
                    Button(action: checkConnection) {
                        if isCheckingConnection {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Retry")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    .disabled(isCheckingConnection)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.orange)
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: supabase.isOffline)
        }
    }

    // MARK: - Actions

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
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct OfflineBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            OfflineBanner()
            Spacer()
        }
        .onAppear {
            PTSupabaseClient.shared.isOffline = true
        }
    }
}
#endif
