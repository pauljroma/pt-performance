//
//  StreakAlertView.swift
//  PTPerformance
//
//  ACP-842: Streak Protection Alerts
//  Alert banner/sheet showing streak at risk notification
//

import SwiftUI

// MARK: - Streak Alert View

/// Alert view displayed when user's streak is at risk
struct StreakAlertView: View {
    // MARK: - Properties

    let streakStatus: StreakStatus
    let onStartWorkout: () -> Void
    let onRemindLater: () -> Void
    let onDismiss: () -> Void

    @State private var showQuickWorkoutPicker = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with flame icon
            headerView

            // Streak info
            streakInfoView

            // Quick workout suggestion
            quickWorkoutSuggestion

            // Action buttons
            actionButtons
        }
        .padding(20)
        .background(backgroundGradient)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .sheet(isPresented: $showQuickWorkoutPicker) {
            QuickWorkoutPickerView { workout in
                showQuickWorkoutPicker = false
                onStartWorkout()
            }
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            Image(systemName: streakStatus.riskLevel.alertEmoji)
                .font(.title)
                .foregroundColor(iconColor)
                .symbolEffect(.pulse, options: .repeating)

            VStack(alignment: .leading, spacing: 2) {
                Text(streakStatus.riskLevel.alertTitle)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(timeRemainingText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var streakInfoView: some View {
        HStack(spacing: 12) {
            // Streak count badge
            VStack(spacing: 4) {
                Text("\(streakStatus.currentStreak)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("day streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(streakStatus.protectionMessage)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                if streakStatus.currentStreak > 0 {
                    Text("Don't lose your progress!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }

    private var quickWorkoutSuggestion: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Options")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                quickOptionButton(minutes: 5, type: .armCare)
                quickOptionButton(minutes: 10, type: .mobility)
                quickOptionButton(minutes: 15, type: .express)
            }
        }
    }

    private func quickOptionButton(minutes: Int, type: QuickWorkoutType) -> some View {
        Button {
            showQuickWorkoutPicker = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: type.iconName)
                    .font(.title3)

                Text("\(minutes)m")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(.systemGray5))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            // Primary action - Start Quick Workout
            Button {
                showQuickWorkoutPicker = true
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Quick Workout")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(primaryButtonGradient)
                .cornerRadius(12)
            }

            // Secondary actions
            HStack(spacing: 12) {
                Button {
                    onRemindLater()
                } label: {
                    Text("Remind Later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                Button {
                    onDismiss()
                } label: {
                    Text("Skip Today")
                        .font(.subheadline)
                        .foregroundColor(.red.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var iconColor: Color {
        switch streakStatus.riskLevel {
        case .safe: return .green
        case .lowRisk: return .blue
        case .mediumRisk: return .yellow
        case .highRisk: return .orange
        case .critical: return .red
        }
    }

    private var borderColor: Color {
        iconColor.opacity(0.5)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                iconColor.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var primaryButtonGradient: LinearGradient {
        LinearGradient(
            colors: [iconColor, iconColor.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var timeRemainingText: String {
        let calendar = Calendar.current
        let now = Date()
        let endOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
        let hoursRemaining = calendar.dateComponents([.hour], from: now, to: endOfDay).hour ?? 0

        if hoursRemaining <= 1 {
            return "Less than 1 hour left today"
        } else if hoursRemaining <= 3 {
            return "\(hoursRemaining) hours left today"
        } else {
            return "Still time to train today"
        }
    }
}

// MARK: - Streak Alert Banner

/// Compact banner version for top of screen display
struct StreakAlertBanner: View {
    let streakCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                    .symbolEffect(.pulse, options: .repeating)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Streak at Risk!")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("Quick 10-min workout to save your \(streakCount)-day streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Streak Protected Badge

/// Badge shown after completing a streak-protecting workout
struct StreakProtectedBadge: View {
    let streakCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .font(.title3)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("Streak Protected!")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("\(streakCount)-day streak continues")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.green.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

struct StreakAlertView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            StreakAlertView(
                streakStatus: StreakStatus(
                    currentStreak: 12,
                    lastActivityDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
                    hasActivityToday: false,
                    riskLevel: .highRisk,
                    updatedAt: Date()
                ),
                onStartWorkout: {},
                onRemindLater: {},
                onDismiss: {}
            )
            .padding()

            StreakAlertBanner(streakCount: 12, onTap: {})
                .padding()

            StreakProtectedBadge(streakCount: 12)
                .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
