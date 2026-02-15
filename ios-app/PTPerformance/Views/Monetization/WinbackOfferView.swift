//
//  WinbackOfferView.swift
//  PTPerformance
//
//  ACP-993: Winback Offers — Premium "We Miss You!" UI for churned subscribers.
//  Displays a time-limited discount offer with emotional header, feature
//  highlights, countdown timer, and a prominent CTA.
//

import SwiftUI

// MARK: - Winback Offer View

struct WinbackOfferView: View {
    @ObservedObject var winbackService = WinbackService.shared
    @EnvironmentObject var storeKit: StoreKitService
    @Environment(\.dismiss) private var dismiss

    let offer: WinbackOffer

    @State private var remainingTime: TimeInterval
    @State private var isPurchasing: Bool = false
    @State private var timerTask: Task<Void, Never>?
    @State private var animateIn: Bool = false

    init(offer: WinbackOffer) {
        self.offer = offer
        self._remainingTime = State(initialValue: offer.remainingSeconds)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {

                    // MARK: - Emotional Header
                    headerSection

                    // MARK: - Discount Badge
                    discountBadge

                    // MARK: - Offer Message
                    Text(offer.message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)

                    // MARK: - What's New
                    whatsNewSection

                    // MARK: - Countdown Timer
                    countdownSection

                    // MARK: - CTA Button
                    ctaButton

                    // MARK: - Error Message
                    if let error = winbackService.redeemError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }

                    // MARK: - Dismiss
                    Button {
                        winbackService.dismissOffer()
                        dismiss()
                    } label: {
                        Text("No thanks, maybe later")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, Spacing.lg)
                }
                .padding(.top, Spacing.md)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.modusCyan.opacity(0.05),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        winbackService.dismissOffer()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                    .accessibilityLabel("Close winback offer")
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateIn = true
            }
            startCountdownTimer()
        }
        .onDisappear {
            timerTask?.cancel()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            // Animated wave emoji or icon
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.modusCyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(animateIn ? 1.0 : 0.5)
                .opacity(animateIn ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateIn)

            Text("We Miss You!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .opacity(animateIn ? 1.0 : 0.0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: animateIn)

            Text("Your training journey is waiting")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .opacity(animateIn ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: animateIn)
        }
    }

    // MARK: - Discount Badge

    private var discountBadge: some View {
        VStack(spacing: Spacing.xxs) {
            Text("\(offer.discountPercent)%")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.modusCyan, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("OFF")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.modusCyan)

            if offer.durationMonths > 1 {
                Text("for \(offer.durationMonths) months")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, Spacing.xxs)
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.modusCyan.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.modusCyan.opacity(0.4), .purple.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .padding(.horizontal, Spacing.xl)
        .scaleEffect(animateIn ? 1.0 : 0.8)
        .opacity(animateIn ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: animateIn)
    }

    // MARK: - What's New Section

    private var whatsNewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("What is new since you left")
                .font(.headline)
                .padding(.horizontal, Spacing.lg)

            VStack(spacing: Spacing.xs) {
                WhatsNewRow(icon: "brain.head.profile", text: "Enhanced AI coaching with personalized insights")
                WhatsNewRow(icon: "chart.line.uptrend.xyaxis", text: "Redesigned analytics dashboard")
                WhatsNewRow(icon: "figure.run", text: "New workout programs and templates")
                WhatsNewRow(icon: "bell.badge.fill", text: "Smart training notifications")
            }
            .padding(.horizontal, Spacing.lg)
        }
        .opacity(animateIn ? 1.0 : 0.0)
        .offset(y: animateIn ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: animateIn)
    }

    // MARK: - Countdown Section

    private var countdownSection: some View {
        VStack(spacing: Spacing.xs) {
            Text("Offer expires in")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: Spacing.sm) {
                TimeUnitBlock(value: hours, label: "HRS")
                Text(":")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.modusCyan)
                TimeUnitBlock(value: minutes, label: "MIN")
                Text(":")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.modusCyan)
                TimeUnitBlock(value: seconds, label: "SEC")
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        Button {
            Task {
                await redeemOffer()
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                if isPurchasing || winbackService.isRedeeming {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Come Back for \(offer.discountPercent)% Off")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                LinearGradient(
                    colors: [.modusCyan, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.lg)
        }
        .disabled(isPurchasing || winbackService.isRedeeming)
        .padding(.horizontal, Spacing.lg)
        .accessibilityLabel("Redeem winback offer for \(offer.discountPercent) percent off")
    }

    // MARK: - Timer Logic

    private var hours: Int {
        Int(remainingTime) / 3600
    }

    private var minutes: Int {
        (Int(remainingTime) % 3600) / 60
    }

    private var seconds: Int {
        Int(remainingTime) % 60
    }

    private func startCountdownTimer() {
        timerTask = Task {
            while !Task.isCancelled && remainingTime > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled {
                    remainingTime = max(0, offer.expiresAt.timeIntervalSince(Date()))
                }
            }
        }
    }

    // MARK: - Redeem

    private func redeemOffer() async {
        isPurchasing = true
        defer { isPurchasing = false }

        HapticFeedback.medium()

        do {
            try await winbackService.redeemWinbackOffer(offer)
            HapticFeedback.success()
            dismiss()
        } catch {
            HapticFeedback.error()
        }
    }
}

// MARK: - What's New Row

private struct WhatsNewRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.modusCyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 28)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.vertical, Spacing.xxs)
    }
}

// MARK: - Time Unit Block

private struct TimeUnitBlock: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
                .contentTransition(.numericText())

            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .frame(width: 56)
        .padding(.vertical, Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Preview

#if DEBUG
struct WinbackOfferView_Previews: PreviewProvider {
    static var previews: some View {
        WinbackOfferView(
            offer: WinbackOffer(
                id: "preview-001",
                discountPercent: 50,
                durationMonths: 3,
                productId: Config.Subscription.monthlyProductID,
                expiresAt: Date().addingTimeInterval(72 * 3600),
                message: "Welcome back! Here is an exclusive 50% discount for 3 months."
            )
        )
        .environmentObject(StoreKitService.shared)
    }
}
#endif
