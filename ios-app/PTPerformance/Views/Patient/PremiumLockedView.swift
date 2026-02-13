import SwiftUI

// MARK: - Premium Locked View

struct PremiumLockedView: View {
    let feature: String
    let icon: String
    let description: String

    @EnvironmentObject var storeKit: StoreKitService
    @State private var showSubscription: Bool = false

    init(feature: String, icon: String = "lock.fill", description: String = "") {
        self.feature = feature
        self.icon = icon
        self.description = description
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // MARK: - Icon
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // MARK: - Feature Name
                Text(feature)
                    .font(.title)
                    .fontWeight(.bold)

                // MARK: - Description
                if !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                // MARK: - Unlock Button
                Button {
                    HapticFeedback.light()
                    showSubscription = true
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Unlock with Premium")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
                }
                .padding(.horizontal, Spacing.xl)
                .accessibilityLabel("Unlock \(feature) with Premium subscription")

                // MARK: - Restore Purchases
                Button {
                    HapticFeedback.light()
                    Task {
                        await storeKit.restorePurchases()
                    }
                } label: {
                    Text("Restore Purchases")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Restore previous purchases")

                Spacer()
            }
            .navigationTitle(feature)
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
                .environmentObject(storeKit)
        }
    }
}
