//
//  BaseballPackMarketingView.swift
//  PTPerformance
//
//  Premium marketing/paywall view for the Baseball Pack
//  Displays features, pricing, and purchase options
//

import SwiftUI
import StoreKit

struct BaseballPackMarketingView: View {
    @StateObject private var storeKit = StoreKitService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing: Bool = false
    @State private var errorMessage: String?
    @State private var showRestoreSuccess: Bool = false

    // MARK: - Baseball Theme Colors

    private let baseballNavy = Color(red: 0.07, green: 0.14, blue: 0.28)
    private let baseballRed = Color(red: 0.80, green: 0.16, blue: 0.22)

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Section
                heroSection

                // Features Section
                featuresSection
                    .padding(.top, 32)

                // What's Included Section
                whatsIncludedSection
                    .padding(.top, 32)

                // Pricing Section
                pricingSection
                    .padding(.top, 32)

                // Purchase Button
                purchaseButton
                    .padding(.top, 24)

                // Restore Purchases
                restorePurchasesButton
                    .padding(.top, 16)

                // Legal Text
                legalText
                    .padding(.top, 24)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), baseballNavy.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .alert("Purchases Restored", isPresented: $showRestoreSuccess) {
            Button("OK") { }
        } message: {
            Text("Your purchases have been restored successfully.")
        }
        .task {
            await storeKit.loadProducts()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Baseball icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [baseballNavy, baseballNavy.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "baseball.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white)
            }
            .shadow(color: baseballNavy.opacity(0.3), radius: 12, x: 0, y: 6)
            .padding(.top, 24)

            Text("Baseball Performance Pack")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(baseballNavy)
                .multilineTextAlignment(.center)

            Text("Elite training programs designed specifically for baseball athletes at every level")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: 16) {
            BaseballFeatureRow(
                icon: "figure.baseball",
                title: "12+ Position-Specific Programs",
                description: "Tailored training for pitchers, catchers, infielders, and outfielders",
                accentColor: baseballNavy
            )

            BaseballFeatureRow(
                icon: "scalemass.fill",
                title: "Weighted Ball Progressions",
                description: "Science-based protocols for arm strength and velocity development",
                accentColor: baseballRed
            )

            BaseballFeatureRow(
                icon: "calendar.badge.clock",
                title: "Seasonal Periodization",
                description: "Off-season, pre-season, and in-season programming",
                accentColor: baseballNavy
            )

            BaseballFeatureRow(
                icon: "flag.checkered",
                title: "Game-Day Protocols",
                description: "Warm-up routines and preparation for optimal performance",
                accentColor: baseballRed
            )

            BaseballFeatureRow(
                icon: "bandage.fill",
                title: "Arm Care & Recovery",
                description: "Injury prevention and recovery protocols for throwing athletes",
                accentColor: baseballNavy
            )
        }
    }

    // MARK: - What's Included Section

    private var whatsIncludedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's Included")
                .font(.headline)
                .foregroundColor(baseballNavy)

            VStack(spacing: 12) {
                WhatsIncludedItem(text: "Complete off-season velocity program")
                WhatsIncludedItem(text: "Position-specific arm care routines")
                WhatsIncludedItem(text: "Pre-game throwing protocols")
                WhatsIncludedItem(text: "Recovery and maintenance programs")
                WhatsIncludedItem(text: "Video demonstrations for all exercises")
                WhatsIncludedItem(text: "Progress tracking and analytics")
                WhatsIncludedItem(text: "Lifetime access with all future updates")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: 12) {
            if let product = storeKit.baseballPackProduct {
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text(product.displayPrice)
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(baseballNavy)

                        Text("one-time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 12)
                    }

                    Text("Lifetime Access")
                        .font(.headline)
                        .foregroundColor(baseballRed)

                    Text("No subscription required")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if storeKit.isLoading {
                ProgressView("Loading pricing...")
                    .padding()
            } else {
                VStack(spacing: 8) {
                    Text("$29.99")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(baseballNavy)

                    Text("Lifetime Access")
                        .font(.headline)
                        .foregroundColor(baseballRed)
                }
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [baseballNavy.opacity(0.05), baseballRed.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task {
                await purchaseBaseballPack()
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "baseball.fill")
                    Text("Unlock Baseball Pack")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [baseballNavy, baseballNavy.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(isPurchasing || storeKit.baseballPackProduct == nil)
    }

    // MARK: - Restore Purchases Button

    private var restorePurchasesButton: some View {
        Button {
            Task {
                await restorePurchases()
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundColor(baseballNavy)
        }
    }

    // MARK: - Legal Text

    private var legalText: some View {
        Text("This is a one-time purchase. Payment will be charged to your Apple ID account at confirmation. The Baseball Pack provides lifetime access to all included content and future updates.")
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Actions

    private func purchaseBaseballPack() async {
        isPurchasing = true
        errorMessage = nil

        do {
            try await storeKit.purchaseBaseballPack()
        } catch {
            errorMessage = error.localizedDescription
        }

        isPurchasing = false
    }

    private func restorePurchases() async {
        await storeKit.restorePurchases()

        if storeKit.hasBaseballAccess {
            showRestoreSuccess = true
        }
    }
}

// MARK: - Baseball Feature Row

private struct BaseballFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - What's Included Item

private struct WhatsIncludedItem: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundColor(.green)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BaseballPackMarketingView()
            .navigationTitle("Baseball Pack")
    }
}
