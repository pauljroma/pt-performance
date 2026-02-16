import SwiftUI

/// Card component displaying arm care assessment status for baseball/throwing athletes
/// Shows traffic light indicator (green/yellow/red) with throwing recommendations
struct ArmCareStatusCard: View {
    let todayArmCare: ArmCareAssessment?
    let isLoading: Bool
    let onCheckIn: () -> Void
    let onShowDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title
            Text("Arm Care Status")
                .font(.headline)
                .foregroundColor(.secondary)

            if isLoading {
                loadingView
            } else if let armCare = todayArmCare {
                // Checked in today - show traffic light card
                armCareStatusCard(assessment: armCare)
            } else {
                // Not checked in - show prompt
                armCareCheckInPrompt
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
        ProgressView("Checking arm status...")
            .frame(maxWidth: .infinity)
            .padding()
    }

    // MARK: - Status Card

    @ViewBuilder
    private func armCareStatusCard(assessment: ArmCareAssessment) -> some View {
        Button(action: onShowDetails) {
            HStack(spacing: 16) {
                // Traffic light indicator
                ZStack {
                    Circle()
                        .fill(assessment.trafficLight.color.opacity(0.2))
                        .frame(width: DesignTokens.iconSizeXXLarge, height: DesignTokens.iconSizeXXLarge)

                    Image(systemName: assessment.trafficLight.iconName)
                        .font(.title)
                        .foregroundColor(assessment.trafficLight.color)
                }

                // Status and recommendation
                VStack(alignment: .leading, spacing: 4) {
                    Text(assessment.trafficLight.displayName)
                        .font(.headline)
                        .foregroundColor(assessment.trafficLight.color)

                    Text(armCareRecommendation(for: assessment.trafficLight))
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
        .accessibilityLabel("Arm care status: \(assessment.trafficLight.displayName)")
        .accessibilityHint("Opens arm care assessment details")
    }

    // MARK: - Check-In Prompt

    @ViewBuilder
    private var armCareCheckInPrompt: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "figure.baseball")
                    .font(.title2)
                    .foregroundColor(.orange)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("How's your arm today?")
                        .font(.headline)

                    Text("30-second shoulder/elbow check")
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
                    Text("Quick Arm Check")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.sm + 2)
            }
            .accessibilityLabel("Quick Arm Check")
            .accessibilityHint("Opens 30-second arm care assessment")
        }
    }

    // MARK: - Helper

    private func armCareRecommendation(for trafficLight: ArmCareTrafficLight) -> String {
        switch trafficLight {
        case .green:
            return "Full throwing program OK"
        case .yellow:
            return "Reduce throwing 50%, add arm care"
        case .red:
            return "No throwing - recovery only"
        case .unknown:
            return "Status unknown - complete assessment"
        }
    }
}

#if DEBUG
struct ArmCareStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Loading state
            ArmCareStatusCard(
                todayArmCare: nil,
                isLoading: true,
                onCheckIn: {},
                onShowDetails: {}
            )

            // No check-in state
            ArmCareStatusCard(
                todayArmCare: nil,
                isLoading: false,
                onCheckIn: {},
                onShowDetails: {}
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
