// DARK MODE: See ModeThemeModifier.swift for central theme control
import SwiftUI

/// Reusable onboarding page component
struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Icon
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .foregroundColor(accentColor)
                .padding(.bottom, 20)

            // Title
            Text(title)
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Description
            Text(description)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

struct OnboardingPage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingPage(
                icon: "figure.wave",
                title: "Your Recovery Starts Here",
                description: "Stop Guessing. Start Recovering.\n\nThe complete platform for physical therapy program management and patient progress tracking.",
                accentColor: .modusCyan
            )

            OnboardingPage(
                icon: "list.clipboard",
                title: "For Therapists",
                description: "Create custom exercise programs, track patient compliance, and monitor progress in real-time.",
                accentColor: .modusTealAccent
            )

            OnboardingPage(
                icon: "chart.bar.fill",
                title: "Analyze Progress",
                description: "View detailed analytics, track personal records, and monitor compliance trends over time.",
                accentColor: .modusDeepTeal
            )
        }
    }
}
