// ACP-1035: Streamlined Onboarding Flow
// DARK MODE: See ModeThemeModifier.swift for central theme control
import SwiftUI

/// Main onboarding view — reduced to 3 value-proposition pages + quick start option
/// Shows immediate value before asking for any data
struct OnboardingView: View {
    @ObservedObject private var coordinator = OnboardingCoordinator.shared
    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss

    private let totalPages = 3

    var body: some View {
        ZStack {
            // Background — Modus brand gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.modusLightTeal,
                    Color(.systemBackground)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with skip
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button(action: handleQuickStart) {
                            Text("Quick Start")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.modusCyan)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.modusCyan.opacity(0.12))
                                .cornerRadius(CornerRadius.xl)
                        }
                        .padding(.trailing, 20)
                    }
                }
                .frame(height: 52)
                .padding(.top, 4)

                // Page content
                TabView(selection: $currentPage) {
                    // Page 1: Value proposition — show what the app does
                    OnboardingValuePage()
                        .tag(0)

                    // Page 2: Key features with visual preview
                    OnboardingFeaturesPage()
                        .tag(1)

                    // Page 3: Get started with clear CTA
                    OnboardingGetStartedPage()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                // Bottom CTA area
                VStack(spacing: 12) {
                    if currentPage == totalPages - 1 {
                        // Final page — primary CTA
                        Button(action: handleGetStarted) {
                            Text("Set Up My Profile")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.modusCyan)
                                .cornerRadius(CornerRadius.md)
                        }

                        // Quick start bypass
                        Button(action: handleQuickStart) {
                            Text("Skip for Now — Explore First")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.modusCyan)
                        }
                        .padding(.bottom, 8)
                    } else {
                        // Non-final pages — subtle next hint
                        Color.clear
                            .frame(height: 80)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            logOnboardingStart()
        }
    }

    // MARK: - Actions

    /// Quick start: skip setup entirely, jump straight into the app
    private func handleQuickStart() {
        ErrorLogger.shared.logUserAction(
            action: "onboarding_quick_start",
            properties: ["page_at_skip": currentPage]
        )
        coordinator.quickStartOnboarding()
        dismiss()
    }

    /// Normal flow: complete onboarding, proceed to setup
    private func handleGetStarted() {
        ErrorLogger.shared.logUserAction(
            action: "onboarding_completed",
            properties: ["pages_viewed": totalPages]
        )
        coordinator.completeOnboarding()
        dismiss()
    }

    private func logOnboardingStart() {
        ErrorLogger.shared.logUserAction(
            action: "onboarding_started",
            properties: [:]
        )
    }
}

// MARK: - Page 1: Value Proposition

/// Shows immediate value — what the app does for the user — before any data collection
private struct OnboardingValuePage: View {
    @State private var animate = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero icon with animated glow
            ZStack {
                Circle()
                    .fill(Color.modusCyan.opacity(0.12))
                    .frame(width: 160, height: 160)
                    .scaleEffect(animate ? 1.08 : 1.0)

                Image(systemName: "figure.strengthtraining.traditional")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.modusCyan)
            }
            .padding(.bottom, 32)

            Text("Train Smarter.\nRecover Faster.")
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.modusDeepTeal)
                .padding(.horizontal, 32)

            Text("Your all-in-one platform for guided workouts, progress tracking, and recovery optimization.")
                .font(.system(size: 17))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 12)
                .lineSpacing(4)

            Spacer()

            // Mini preview cards — show value immediately
            HStack(spacing: 12) {
                ValuePreviewChip(icon: "chart.line.uptrend.xyaxis", label: "Track Progress")
                ValuePreviewChip(icon: "heart.circle", label: "Daily Readiness")
                ValuePreviewChip(icon: "star.fill", label: "Build Streaks")
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

/// Small chip showing an app capability
private struct ValuePreviewChip: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.modusCyan)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Page 2: Features Preview

/// Showcases key features with visual cards
private struct OnboardingFeaturesPage: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Everything You Need")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.modusDeepTeal)
                .padding(.bottom, 24)

            VStack(spacing: 14) {
                FeatureCard(
                    icon: "list.clipboard.fill",
                    iconColor: .modusCyan,
                    title: "Guided Programs",
                    subtitle: "Custom exercise plans from your therapist or built-in templates"
                )

                FeatureCard(
                    icon: "waveform.path.ecg",
                    iconColor: .modusTealAccent,
                    title: "Smart Recovery",
                    subtitle: "Readiness scores and recovery insights powered by your daily check-ins"
                )

                FeatureCard(
                    icon: "person.2.fill",
                    iconColor: .modusDeepTeal,
                    title: "Therapist Connection",
                    subtitle: "Real-time progress sharing with your care team"
                )
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

/// A visual feature card for the onboarding features page
private struct FeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(iconColor)
                .cornerRadius(CornerRadius.sm)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Page 3: Get Started

/// Final page with clear CTAs — setup vs quick start
private struct OnboardingGetStartedPage: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundColor(.modusTealAccent)
                .padding(.bottom, 24)

            Text("Ready When You Are")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.modusDeepTeal)
                .padding(.bottom, 8)

            Text("Set up your profile for personalized workouts and goals, or jump straight in and explore.")
                .font(.system(size: 17))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)

            Spacer()

            // What you get with setup
            VStack(alignment: .leading, spacing: 12) {
                Text("With a quick setup you get:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.modusDeepTeal)

                SetupBenefitRow(text: "Personalized workout mode")
                SetupBenefitRow(text: "Goal tracking tailored to you")
                SetupBenefitRow(text: "Takes less than 60 seconds")
            }
            .padding(20)
            .background(Color.modusLightTeal)
            .cornerRadius(CornerRadius.md)
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

/// A row showing a benefit of completing setup
private struct SetupBenefitRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.modusTealAccent)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
