//
//  CheckInPromptCard.swift
//  PTPerformance
//
//  Daily Check-in prompt card for main athlete navigation
//  Shows check-in status, streak, and quick access to start check-in
//

import SwiftUI

/// Prominent entry point for Daily Check-in on the main athlete dashboard
///
/// Features:
/// - Shows whether today's check-in is complete
/// - Displays current streak
/// - Quick access to start check-in
/// - Animated status indicator
struct CheckInPromptCard: View {

    // MARK: - Properties

    @StateObject private var checkInService = CheckInService.shared
    @State private var hasCheckedInToday = false
    @State private var streak: CheckInStreak?
    @State private var showingCheckIn = false
    @State private var isLoading = true

    // MARK: - Body

    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            showingCheckIn = true
        }) {
            HStack(spacing: Spacing.md) {
                // Status Icon
                statusIcon

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(hasCheckedInToday ? "Check-in Complete" : "Daily Check-in")
                        .font(.headline)
                        .foregroundColor(.primary)

                    if isLoading {
                        Text("Loading...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if hasCheckedInToday {
                        if let currentStreak = streak?.currentStreak, currentStreak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("\(currentStreak) day streak!")
                                    .font(.subheadline)
                                    .foregroundColor(.modusTealAccent)
                            }
                        } else {
                            Text("Great job today!")
                                .font(.subheadline)
                                .foregroundColor(.modusTealAccent)
                        }
                    } else {
                        Text("How are you feeling today?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Action indicator
                if !hasCheckedInToday && !isLoading {
                    Text("Start")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.modusTealAccent)
                        .cornerRadius(CornerRadius.md)
                } else if hasCheckedInToday {
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.lg)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingCheckIn) {
            DailyCheckInView(onComplete: {
                // Refresh status after check-in completion
                Task {
                    await loadStatus()
                }
            })
        }
        .task {
            await loadStatus()
        }
    }

    // MARK: - Status Icon

    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(hasCheckedInToday ? Color.modusTealAccent : Color.orange)
                .frame(width: 50, height: 50)

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            } else {
                Image(systemName: hasCheckedInToday ? "checkmark.circle.fill" : "sun.max.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Load Status

    private func loadStatus() async {
        isLoading = true
        defer { isLoading = false }

        hasCheckedInToday = await checkInService.hasCheckedInToday()
        streak = await checkInService.getStreak()
    }
}

// MARK: - Preview

#if DEBUG
struct CheckInPromptCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CheckInPromptCard()

            // Mock completed state
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.modusTealAccent)
                        .frame(width: 50, height: 50)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Check-in Complete")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("7 day streak!")
                            .font(.subheadline)
                            .foregroundColor(.modusTealAccent)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.lg)

            // Mock incomplete state
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 50, height: 50)

                    Image(systemName: "sun.max.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Check-in")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("How are you feeling today?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("Start")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.modusTealAccent)
                    .cornerRadius(CornerRadius.md)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.lg)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
