//
//  PremiumPacksBrowserView.swift
//  PTPerformance
//
//  Browse and discover premium content packs
//

import SwiftUI

// MARK: - Main View

struct PremiumPacksBrowserView: View {

    // MARK: - Environment

    @EnvironmentObject var storeKit: StoreKitService
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @StateObject private var viewModel = PremiumPacksBrowserViewModel()
    @State private var selectedPack: PremiumPack?
    @State private var searchText = ""

    // MARK: - Layout

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Featured packs section
                    if !viewModel.featuredPacks.isEmpty {
                        featuredPacksSection
                    }

                    // All packs grid
                    if !viewModel.filteredPacks.isEmpty {
                        allPacksSection
                    }

                    // Empty state
                    if viewModel.filteredPacks.isEmpty && !viewModel.isLoading {
                        emptyStateView
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .navigationTitle("Premium Packs")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search packs...")
            .onChange(of: searchText) { _, newValue in
                viewModel.filterPacks(searchText: newValue)
            }
            .refreshableWithHaptic {
                await viewModel.loadData()
            }
            .overlay {
                if viewModel.isLoading && viewModel.packs.isEmpty {
                    loadingView
                }
            }
            .sheet(item: $selectedPack) { pack in
                PremiumPackDetailSheet(
                    pack: pack,
                    isSubscribed: viewModel.isSubscribed(to: pack)
                )
                .environmentObject(storeKit)
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Featured Packs Section

    private var featuredPacksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Featured Packs")
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Text("\(viewModel.featuredPacks.count) packs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, Spacing.sm)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(viewModel.featuredPacks) { pack in
                        FeaturedPackCard(
                            pack: pack,
                            isSubscribed: viewModel.isSubscribed(to: pack)
                        ) {
                            HapticFeedback.light()
                            selectedPack = pack
                        }
                    }
                }
            }
        }
    }

    // MARK: - All Packs Section

    private var allPacksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("All Packs")
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                if !searchText.isEmpty {
                    Text("\(viewModel.filteredPacks.count) results")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(viewModel.filteredPacks) { pack in
                    PackGridCard(
                        pack: pack,
                        isSubscribed: viewModel.isSubscribed(to: pack)
                    ) {
                        HapticFeedback.light()
                        selectedPack = pack
                    }
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .accessibilityHidden(true)
            Text("Loading packs...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.9))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading premium packs, please wait")
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: searchText.isEmpty ? "square.stack.3d.up.fill" : "magnifyingglass")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text(searchText.isEmpty ? "No Packs Available" : "No Matching Packs")
                .font(.headline)

            Text(searchText.isEmpty
                 ? "Premium content packs will appear here when available."
                 : "No packs match your search. Try different keywords.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Label("Clear Search", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
}

// MARK: - Featured Pack Card

private struct FeaturedPackCard: View {
    let pack: PremiumPack
    let isSubscribed: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header with icon and badge
                HStack {
                    // Pack icon
                    Image(systemName: pack.icon)
                        .font(.title)
                        .foregroundColor(pack.themeColor)
                        .frame(width: 44, height: 44)
                        .background(pack.themeColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                        .accessibilityHidden(true)

                    Spacer()

                    // Subscribed badge
                    if isSubscribed {
                        SubscribedBadge()
                    }
                }

                // Pack name
                Text(pack.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Description
                Text(pack.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: Spacing.xs)

                // Price
                HStack {
                    Text(pack.formattedMonthlyPrice)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(pack.themeColor)

                    Text("/month")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .padding(Spacing.md)
            .frame(width: 220, height: 160)
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.lg)
            .adaptiveShadow(Shadow.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pack.name)\(isSubscribed ? ", subscribed" : ""), \(pack.formattedMonthlyPrice) per month")
        .accessibilityHint("Double tap to view pack details and programs")
    }
}

// MARK: - Pack Grid Card

private struct PackGridCard: View {
    let pack: PremiumPack
    let isSubscribed: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Header with icon and subscribed badge
                HStack {
                    Image(systemName: pack.icon)
                        .font(.title2)
                        .foregroundColor(pack.themeColor)
                        .frame(width: 40, height: 40)
                        .background(pack.themeColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xs))
                        .accessibilityHidden(true)

                    Spacer()

                    if isSubscribed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                            .accessibilityHidden(true)
                    }
                }

                // Pack name
                Text(pack.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Description
                Text(pack.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: Spacing.xxs)

                // Price row
                HStack(spacing: Spacing.xxs) {
                    Text(pack.formattedMonthlyPrice)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(pack.themeColor)

                    Text("/mo")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    if pack.isAddon {
                        Text("Add-on")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 2)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.xs)
                    }
                }
            }
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pack.name)\(isSubscribed ? ", subscribed" : "")\(pack.isAddon ? ", add-on pack" : ""), \(pack.formattedMonthlyPrice) per month")
        .accessibilityHint("Double tap to view pack details")
    }
}

// MARK: - Subscribed Badge

private struct SubscribedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .accessibilityHidden(true)
            Text("Subscribed")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.green)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(Color.green.opacity(0.15))
        .cornerRadius(CornerRadius.xs)
    }
}

// MARK: - View Model

@MainActor
class PremiumPacksBrowserViewModel: ObservableObject {
    @Published var packs: [PremiumPack] = []
    @Published var featuredPacks: [PremiumPack] = []
    @Published var filteredPacks: [PremiumPack] = []
    @Published var subscribedPackCodes: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = PremiumPackService.shared

    // MARK: - Load Data

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all packs and subscriptions in parallel
            async let packsFetch = service.fetchAllPacks()
            async let subscriptionsFetch = service.fetchUserSubscriptions()

            let fetchedPacks = try await packsFetch
            _ = try await subscriptionsFetch

            await MainActor.run {
                self.packs = fetchedPacks
                self.featuredPacks = fetchedPacks.filter { !$0.isAddon }.prefix(6).map { $0 }
                self.filteredPacks = fetchedPacks
                self.subscribedPackCodes = service.getSubscribedPackCodes()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Unable to load premium packs. Please try again."
                self.isLoading = false
            }
        }
    }

    // MARK: - Filter Packs

    func filterPacks(searchText: String) {
        if searchText.isEmpty {
            filteredPacks = packs
        } else {
            filteredPacks = packs.filter { pack in
                pack.name.localizedCaseInsensitiveContains(searchText) ||
                pack.description.localizedCaseInsensitiveContains(searchText) ||
                pack.code.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - Check Subscription

    func isSubscribed(to pack: PremiumPack) -> Bool {
        return subscribedPackCodes.contains(pack.code.uppercased())
    }
}

// MARK: - Preview

#if DEBUG
struct PremiumPacksBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumPacksBrowserView()
            .environmentObject(StoreKitService.shared)
    }
}
#endif
