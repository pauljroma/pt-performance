//
//  AddOnStoreView.swift
//  PTPerformance
//
//  ACP-1009: Premium Add-Ons — Marketplace view for browsing and purchasing add-ons
//

import SwiftUI

// MARK: - Add-On Store View

/// Marketplace view for browsing and purchasing premium add-on features.
///
/// Displays a grid of add-on cards with category filtering, purchased badges,
/// and a detail sheet with full description and purchase capability.
struct AddOnStoreView: View {

    @StateObject private var service = AddOnService.shared
    @ObservedObject private var storeKit = StoreKitService.shared

    @State private var selectedAddOn: PremiumAddOn?
    @State private var showingDetail = false
    @State private var purchaseError: String?
    @State private var showingError = false

    // MARK: - Grid Layout

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header
                headerSection

                // Category filter tabs
                categoryTabs

                // Add-on grid
                if service.isLoading {
                    loadingState
                } else if service.filteredAddOns.isEmpty {
                    emptyState
                } else {
                    addOnGrid
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .navigationTitle("Add-On Store")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await service.fetchAddOns()
        }
        .sheet(isPresented: $showingDetail) {
            if let addOn = selectedAddOn {
                AddOnDetailSheet(
                    addOn: addOn,
                    isPurchased: service.hasAddOn(addOn.productId),
                    onPurchase: {
                        Task {
                            await purchaseAddOn(addOn)
                        }
                    }
                )
            }
        }
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseError ?? "An unexpected error occurred.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Unlock More Features")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("Individual features to enhance your training experience")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if service.purchasedCount > 0 {
                Text("\(service.purchasedCount) add-on\(service.purchasedCount == 1 ? "" : "s") purchased")
                    .font(.caption)
                    .foregroundColor(.modusCyan)
                    .padding(.top, Spacing.xxs)
            }
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: - Category Tabs

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                // "All" tab
                categoryChip(title: "All", icon: "square.grid.2x2.fill", isSelected: service.selectedCategory == nil) {
                    service.selectedCategory = nil
                }

                ForEach(AddOnCategory.allCases) { category in
                    categoryChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: service.selectedCategory == category
                    ) {
                        service.selectedCategory = category
                    }
                }
            }
            .padding(.vertical, Spacing.xxs)
        }
    }

    private func categoryChip(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? Color.modusCyan.opacity(0.15) : Color(.systemGray6))
            .foregroundColor(isSelected ? .modusCyan : .secondary)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .strokeBorder(isSelected ? Color.modusCyan.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add-On Grid

    private var addOnGrid: some View {
        LazyVGrid(columns: columns, spacing: Spacing.md) {
            ForEach(service.filteredAddOns) { addOn in
                AddOnCardView(
                    addOn: addOn,
                    isPurchased: service.hasAddOn(addOn.productId)
                )
                .onTapGesture {
                    selectedAddOn = addOn
                    showingDetail = true
                }
            }
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading add-ons...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "bag")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Add-Ons Available")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Check back soon for new features and enhancements.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Purchase

    private func purchaseAddOn(_ addOn: PremiumAddOn) async {
        do {
            try await service.purchaseAddOn(addOn)
            showingDetail = false
        } catch {
            purchaseError = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Add-On Card View

/// Individual add-on card for the grid display.
struct AddOnCardView: View {
    let addOn: PremiumAddOn
    let isPurchased: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Icon and badge
            ZStack(alignment: .topTrailing) {
                HStack {
                    Image(systemName: addOn.iconName)
                        .font(.title2)
                        .foregroundColor(.modusCyan)
                        .frame(width: 40, height: 40)
                        .background(Color.modusCyan.opacity(0.12))
                        .cornerRadius(CornerRadius.sm)

                    Spacer()
                }

                if isPurchased {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(DesignTokens.statusSuccess)
                        .font(.title3)
                }

                if let badge = addOn.badgeText, !isPurchased {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xxs)
                        .padding(.vertical, Spacing.xxs)
                        .background(DesignTokens.statusWarning)
                        .cornerRadius(CornerRadius.xs)
                }
            }

            // Name
            Text(addOn.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Description
            Text(addOn.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            Spacer(minLength: Spacing.xxs)

            // Price
            if isPurchased {
                Text("Purchased")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.statusSuccess)
            } else {
                Text(addOn.formattedPrice)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.modusCyan)
            }
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .strokeBorder(
                    isPurchased ? DesignTokens.statusSuccess.opacity(0.3) : Color(.systemGray5),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Add-On Detail Sheet

/// Detail sheet showing full description and purchase button for an add-on.
struct AddOnDetailSheet: View {
    let addOn: PremiumAddOn
    let isPurchased: Bool
    let onPurchase: () -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var service = AddOnService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Hero section
                    VStack(spacing: Spacing.md) {
                        Image(systemName: addOn.iconName)
                            .font(.system(size: 48))
                            .foregroundColor(.modusCyan)
                            .frame(width: 80, height: 80)
                            .background(Color.modusCyan.opacity(0.1))
                            .cornerRadius(CornerRadius.lg)

                        Text(addOn.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(addOn.category.displayName)
                            .font(.caption)
                            .foregroundColor(.modusCyan)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(Color.modusCyan.opacity(0.1))
                            .cornerRadius(CornerRadius.lg)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.md)

                    // Full description
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("About")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(addOn.fullDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Divider()

                    // Price and purchase
                    if isPurchased {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(DesignTokens.statusSuccess)
                            Text("You own this add-on")
                                .font(.headline)
                                .foregroundColor(DesignTokens.statusSuccess)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                    } else {
                        VStack(spacing: Spacing.md) {
                            Text(addOn.formattedPrice)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("One-time purchase")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button {
                                HapticFeedback.medium()
                                onPurchase()
                            } label: {
                                HStack {
                                    if service.isPurchasing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Purchase")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.modusCyan)
                                .foregroundColor(.white)
                                .cornerRadius(CornerRadius.md)
                            }
                            .disabled(service.isPurchasing)
                            .accessibilityLabel("Purchase \(addOn.name) for \(addOn.formattedPrice)")
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        AddOnStoreView()
    }
}
#endif
