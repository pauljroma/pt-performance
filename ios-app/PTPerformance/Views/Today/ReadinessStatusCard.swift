import SwiftUI

/// Card component displaying daily readiness check-in status
/// Shows either the readiness score with category or a prompt to check in
struct ReadinessStatusCard: View {
    let todayReadiness: DailyReadiness?
    let isLoading: Bool
    let onCheckIn: () -> Void
    let onShowDashboard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title
            Text("Daily Readiness")
                .font(.headline)
                .foregroundColor(.secondary)

            if isLoading {
                loadingView
            } else if let readiness = todayReadiness,
                      let score = readiness.readinessScore,
                      let category = readiness.category {
                // Checked in today - show score card
                readinessScoreCard(score: score, category: category)
            } else {
                // Not checked in - show prompt
                readinessCheckInPrompt
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Loading View

    @ViewBuilder
    private var loadingView: some View {
        ProgressView("Loading readiness...")
            .frame(maxWidth: .infinity)
            .padding()
    }

    // MARK: - Score Card

    @ViewBuilder
    private func readinessScoreCard(score: Double, category: ReadinessCategory) -> some View {
        Button(action: onShowDashboard) {
            HStack(spacing: 16) {
                // Score circle
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.2))
                        .frame(width: DesignTokens.iconSizeXXLarge, height: DesignTokens.iconSizeXXLarge)

                    VStack(spacing: 2) {
                        Text(String(format: "%.0f", score))
                            .font(.title2)
                            .bold()
                            .foregroundColor(category.color)

                        Text("/ 100")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Category and recommendation
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.displayName)
                        .font(.headline)
                        .foregroundColor(category.color)

                    Text(category.recommendation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Readiness score \(String(format: "%.0f", score)) out of 100, \(category.displayName)")
        .accessibilityHint("Opens readiness dashboard with detailed trends")
    }

    // MARK: - Check-In Prompt

    @ViewBuilder
    private var readinessCheckInPrompt: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square")
                    .font(.title2)
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("How are you feeling today?")
                        .font(.headline)

                    Text("Complete your daily check-in")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Button(action: {
                HapticFeedback.light()
                onCheckIn()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Check In Now")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.modusCyan)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.sm + 2)
            }
            .accessibilityLabel("Check In Now")
            .accessibilityHint("Opens daily readiness check-in form")
        }
    }
}

#if DEBUG
struct ReadinessStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Loading state
            ReadinessStatusCard(
                todayReadiness: nil,
                isLoading: true,
                onCheckIn: {},
                onShowDashboard: {}
            )

            // No check-in state
            ReadinessStatusCard(
                todayReadiness: nil,
                isLoading: false,
                onCheckIn: {},
                onShowDashboard: {}
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
