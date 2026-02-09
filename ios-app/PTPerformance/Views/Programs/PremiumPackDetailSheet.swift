//
//  PremiumPackDetailSheet.swift
//  PTPerformance
//
//  Detail view for a premium pack showing programs and subscription options
//

import SwiftUI

struct PremiumPackDetailSheet: View {

    // MARK: - Properties

    let pack: PremiumPack
    let isSubscribed: Bool

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var storeKit: StoreKitService

    // MARK: - State

    @State private var programs: [ProgramLibrary] = []
    @State private var isLoadingPrograms = false
    @State private var programsError: String?
    @State private var showSubscribeConfirmation = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Pack header
                    packHeader

                    Divider()
                        .padding(.horizontal, Spacing.md)

                    // Price section
                    priceSection
                        .padding(.horizontal, Spacing.md)

                    Divider()
                        .padding(.horizontal, Spacing.md)

                    // Programs section
                    programsSection
                        .padding(.horizontal, Spacing.md)

                    // Bottom spacing for button
                    Spacer(minLength: 100)
                }
                .padding(.vertical, Spacing.md)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .safeAreaInset(edge: .bottom) {
                subscribeButton
            }
            .task {
                await loadPrograms()
            }
            .alert("Subscribe to \(pack.name)?", isPresented: $showSubscribeConfirmation) {
                Button("Subscribe", role: .none) {
                    // Placeholder for subscription action
                    HapticFeedback.success()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You'll be charged \(pack.formattedMonthlyPrice) per month. You can cancel anytime.")
            }
        }
    }

    // MARK: - Pack Header

    private var packHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Icon and badge row
            HStack(alignment: .top) {
                // Large pack icon
                Image(systemName: pack.icon)
                    .font(.system(size: 48))
                    .foregroundColor(pack.themeColor)
                    .frame(width: 80, height: 80)
                    .background(pack.themeColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .accessibilityHidden(true)

                Spacer()

                // Subscription status badge
                if isSubscribed {
                    SubscriptionStatusBadge(status: .subscribed)
                } else if pack.isAddon {
                    PackTypeBadge(type: .addon)
                } else {
                    PackTypeBadge(type: .core)
                }
            }

            // Pack name
            Text(pack.name)
                .font(.title)
                .fontWeight(.bold)

            // Pack description
            Text(pack.description)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Price Section

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Pricing")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            // Monthly price card
            PriceOptionCard(
                title: "Monthly",
                price: pack.formattedMonthlyPrice,
                period: "per month",
                isSelected: true,
                themeColor: pack.themeColor
            )

            // Bundle price card (if available)
            if let bundlePrice = pack.formattedBundlePrice {
                PriceOptionCard(
                    title: "Bundle",
                    price: bundlePrice,
                    period: "per month with annual",
                    savings: pack.bundleSavings.map { "Save \(formatCurrency($0))" },
                    isSelected: false,
                    themeColor: pack.themeColor
                )
            }
        }
    }

    // MARK: - Programs Section

    private var programsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Included Programs")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                if !programs.isEmpty {
                    Text("\(programs.count) programs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if isLoadingPrograms {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, Spacing.lg)
                    Spacer()
                }
            } else if let error = programsError {
                ProgramsErrorView(message: error) {
                    Task { await loadPrograms() }
                }
            } else if programs.isEmpty {
                ProgramsEmptyView()
            } else {
                programsList
            }
        }
    }

    // MARK: - Programs List

    private var programsList: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(programs) { program in
                PackProgramCard(
                    program: program,
                    hasAccess: isSubscribed
                )
            }
        }
    }

    // MARK: - Subscribe Button

    private var subscribeButton: some View {
        VStack(spacing: 0) {
            Divider()

            VStack(spacing: Spacing.sm) {
                if isSubscribed {
                    // Already subscribed state
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .accessibilityHidden(true)
                        Text("You're subscribed to this pack")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(CornerRadius.md)
                } else {
                    // Subscribe button
                    Button {
                        HapticFeedback.medium()
                        showSubscribeConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .accessibilityHidden(true)
                            Text("Subscribe for \(pack.formattedMonthlyPrice)/mo")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [pack.themeColor, pack.themeColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(CornerRadius.md)
                    }
                    .accessibilityLabel("Subscribe to \(pack.name) for \(pack.formattedMonthlyPrice) per month")
                    .accessibilityHint("Opens subscription confirmation")

                    // Restore purchases link
                    Button {
                        HapticFeedback.light()
                        Task {
                            await storeKit.restorePurchases()
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(Spacing.md)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Load Programs

    private func loadPrograms() async {
        isLoadingPrograms = true
        programsError = nil

        do {
            let service = PremiumPackService.shared
            let fetchedPrograms = try await service.fetchProgramsForPack(packCode: pack.code)

            await MainActor.run {
                programs = fetchedPrograms
                isLoadingPrograms = false
            }
        } catch {
            await MainActor.run {
                programsError = "Unable to load programs"
                isLoadingPrograms = false
            }
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$\(value)"
    }
}

// MARK: - Supporting Views

private struct SubscriptionStatusBadge: View {
    enum Status {
        case subscribed
        case expired
        case trial
    }

    let status: Status

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .accessibilityHidden(true)
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(color)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(color.opacity(0.15))
        .cornerRadius(CornerRadius.sm)
    }

    private var icon: String {
        switch status {
        case .subscribed: return "checkmark.circle.fill"
        case .expired: return "clock.badge.exclamationmark.fill"
        case .trial: return "gift.fill"
        }
    }

    private var text: String {
        switch status {
        case .subscribed: return "Subscribed"
        case .expired: return "Expired"
        case .trial: return "Trial"
        }
    }

    private var color: Color {
        switch status {
        case .subscribed: return .green
        case .expired: return .red
        case .trial: return .purple
        }
    }
}

private struct PackTypeBadge: View {
    enum PackType {
        case core
        case addon
    }

    let type: PackType

    var body: some View {
        Text(type == .core ? "Core Pack" : "Add-on")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(type == .core ? .blue : .secondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background((type == .core ? Color.blue : Color.gray).opacity(0.15))
            .cornerRadius(CornerRadius.sm)
    }
}

private struct PriceOptionCard: View {
    let title: String
    let price: String
    let period: String
    var savings: String? = nil
    let isSelected: Bool
    let themeColor: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(price)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeColor)

                    Text(period)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let savings = savings {
                Text(savings)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(CornerRadius.sm)
            }

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(themeColor)
                    .font(.title3)
                    .accessibilityHidden(true)
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .strokeBorder(isSelected ? themeColor : Color.clear, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) pricing: \(price) \(period)\(savings.map { ", \($0)" } ?? "")")
    }
}

private struct PackProgramCard: View {
    let program: ProgramLibrary
    let hasAccess: Bool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Program icon
            Image(systemName: program.categoryIcon)
                .font(.title3)
                .foregroundColor(categoryColor)
                .frame(width: 40, height: 40)
                .background(categoryColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                .accessibilityHidden(true)

            // Program info
            VStack(alignment: .leading, spacing: 4) {
                Text(program.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: Spacing.xs) {
                    // Duration
                    Label(program.formattedDuration, systemImage: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    // Difficulty
                    Text(program.difficultyLevel.capitalized)
                        .font(.caption2)
                        .foregroundColor(program.difficultyColor)
                }
            }

            Spacer()

            // Access badge
            if hasAccess {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                    .accessibilityLabel("Access granted")
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .accessibilityLabel("Requires subscription")
            }
        }
        .padding(Spacing.sm)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(program.title), \(program.formattedDuration), \(program.difficultyLevel) difficulty\(hasAccess ? ", access granted" : ", requires subscription")")
    }

    private var categoryColor: Color {
        switch program.category.lowercased() {
        case "baseball": return .orange
        case "strength": return .blue
        case "mobility": return .green
        case "cardio", "conditioning": return .red
        case "recovery": return .teal
        default: return .gray
        }
    }
}

private struct ProgramsErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
                .accessibilityHidden(true)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Try Again", action: retryAction)
                .font(.subheadline)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

private struct ProgramsEmptyView: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.title2)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text("No programs available yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Programs will be added to this pack soon.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Preview

#if DEBUG
struct PremiumPackDetailSheet_Previews: PreviewProvider {
    static var previews: some View {
        PremiumPackDetailSheet(
            pack: PremiumPack.preview,
            isSubscribed: false
        )
        .environmentObject(StoreKitService.shared)
    }
}
#endif
