//
//  ReferralView.swift
//  PTPerformance
//
//  ACP-994: Referral Program
//  Dashboard for managing referral codes, tracking referrals, and viewing rewards
//

import SwiftUI

// MARK: - Referral View

/// Referral program dashboard showing code, stats, rewards, and referred friends
struct ReferralView: View {

    // MARK: - Properties

    @StateObject private var service = ReferralService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showRedeemSheet = false
    @State private var redeemCode = ""
    @State private var redeemError: String?
    @State private var isRedeeming = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Referral code section
                    referralCodeSection

                    // Share button
                    shareButton

                    // Progress to next reward
                    progressSection

                    // Rewards tiers
                    rewardsTiersSection

                    // Referred friends
                    referredFriendsSection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.lg)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Referral Program")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticFeedback.light()
                        dismiss()
                    }
                }
            }
            .refreshableWithHaptic {
                await service.fetchReferralStats()
            }
            .sheet(isPresented: $showRedeemSheet) {
                redeemCodeSheet
            }
            .overlay {
                if service.isLoading && service.referralCode.isEmpty {
                    ProgressView("Loading referral data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGroupedBackground))
                }
            }
        }
    }

    // MARK: - Referral Code Section

    private var referralCodeSection: some View {
        VStack(spacing: Spacing.md) {
            Text("Your Referral Code")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Big, copyable code
            Button {
                service.copyReferralCode()
            } label: {
                HStack(spacing: Spacing.sm) {
                    Text(service.referralCode.isEmpty ? "------" : service.referralCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.modusCyan)
                        .tracking(4)

                    Image(systemName: service.codeCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.title3)
                        .foregroundColor(service.codeCopied ? .green : .modusCyan)
                        .animation(.easeInOut(duration: AnimationDuration.standard), value: service.codeCopied)
                }
                .padding(.vertical, Spacing.md)
                .padding(.horizontal, Spacing.lg)
                .background(Color.modusLightTeal)
                .cornerRadius(CornerRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.modusCyan.opacity(0.3), lineWidth: 1.5)
                )
            }
            .accessibilityLabel("Referral code: \(service.referralCode). Tap to copy.")
            .accessibilityHint("Double tap to copy code to clipboard")

            if service.codeCopied {
                Text("Copied to clipboard!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Spacing.lg)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button {
            service.shareReferralLink()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "square.and.arrow.up")
                    .font(.headline)
                Text("Share Referral Link")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.modusCyan)
            .cornerRadius(CornerRadius.md)
        }
        .accessibilityLabel("Share your referral link")
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Referral Progress")
                        .font(.headline)

                    if let nextTier = service.nextTier {
                        Text("\(service.referralsToNextTier) more to unlock \(nextTier.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("All tiers unlocked!")
                            .font(.caption)
                            .foregroundColor(.modusCyan)
                    }
                }

                Spacer()

                // Referral count badge
                VStack(spacing: Spacing.xxs) {
                    Text("\(service.referralCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.modusCyan)
                    Text("Referrals")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(Color.modusCyan)
                        .frame(width: geometry.size.width * service.progressToNextTier, height: 8)
                        .animation(.easeInOut(duration: AnimationDuration.standard), value: service.progressToNextTier)
                }
            }
            .frame(height: 8)

            // Tier markers
            HStack {
                ForEach(ReferralTier.allCases, id: \.self) { tier in
                    VStack(spacing: Spacing.xxs) {
                        Image(systemName: tier.iconName)
                            .font(.caption)
                            .foregroundColor(
                                service.referralCount >= tier.requiredReferrals ? tier.color : .secondary
                            )
                        Text("\(tier.requiredReferrals)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    if tier != ReferralTier.allCases.last {
                        Spacer()
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Rewards Tiers Section

    private var rewardsTiersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Rewards")
                .font(.headline)
                .padding(.horizontal, Spacing.xxs)

            ForEach(service.referralRewards) { reward in
                rewardTierRow(reward: reward)
            }

            // Empty state fallback if no rewards loaded yet
            if service.referralRewards.isEmpty && !service.isLoading {
                ForEach(ReferralTier.allCases, id: \.self) { tier in
                    rewardTierRow(reward: ReferralReward(
                        id: UUID(),
                        tier: tier,
                        title: tier.displayName,
                        description: tier.rewardDescription,
                        isUnlocked: false,
                        unlockedAt: nil
                    ))
                }
            }
        }
    }

    private func rewardTierRow(reward: ReferralReward) -> some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(reward.isUnlocked ? reward.tier.color.opacity(0.15) : Color(.tertiarySystemFill))
                    .frame(width: 44, height: 44)

                Image(systemName: reward.tier.iconName)
                    .font(.body)
                    .foregroundColor(reward.isUnlocked ? reward.tier.color : .secondary)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack {
                    Text(reward.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if reward.isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                Text(reward.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(reward.tier.requiredReferrals) referral\(reward.tier.requiredReferrals == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(CornerRadius.xs)
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(
                    reward.isUnlocked ? reward.tier.color.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .opacity(reward.isUnlocked ? 1.0 : 0.7)
    }

    // MARK: - Referred Friends Section

    private var referredFriendsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Referred Friends")
                    .font(.headline)

                Spacer()

                Button {
                    HapticFeedback.light()
                    showRedeemSheet = true
                } label: {
                    Text("Redeem Code")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }
            .padding(.horizontal, Spacing.xxs)

            if service.referredFriends.isEmpty {
                // Empty state
                VStack(spacing: Spacing.md) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("No referrals yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Share your code with friends to start earning rewards!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xl)
                .background(Color(.systemBackground))
                .cornerRadius(CornerRadius.md)
            } else {
                ForEach(service.referredFriends) { friend in
                    HStack(spacing: Spacing.md) {
                        // Avatar placeholder
                        Circle()
                            .fill(Color.modusCyan.opacity(0.15))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(String(friend.displayName.prefix(1)))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.modusCyan)
                            )

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(friend.displayName)
                                .font(.subheadline)

                            Text("Joined \(formattedDate(friend.joinedAt))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Active status
                        Circle()
                            .fill(friend.isActive ? Color.green : Color.secondary)
                            .frame(width: 8, height: 8)
                    }
                    .padding(Spacing.sm)
                    .background(Color(.systemBackground))
                    .cornerRadius(CornerRadius.sm)
                }
            }
        }
    }

    // MARK: - Redeem Code Sheet

    private var redeemCodeSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Text("Enter a referral code from a friend")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.md)

                TextField("Referral Code", text: $redeemCode)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(Spacing.md)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.md)
                    .padding(.horizontal, Spacing.lg)

                if let error = redeemError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                LoadingButton(
                    title: "Redeem Code",
                    icon: "gift.fill",
                    isLoading: isRedeeming,
                    action: {
                        Task {
                            await redeemCode()
                        }
                    },
                    isDisabled: redeemCode.isEmpty
                )
                .padding(.horizontal, Spacing.lg)

                Spacer()
            }
            .padding(.vertical, Spacing.md)
            .navigationTitle("Redeem Referral")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showRedeemSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func redeemCode() async {
        isRedeeming = true
        redeemError = nil

        do {
            try await service.redeemReferralCode(redeemCode)
            showRedeemSheet = false
            redeemCode = ""
        } catch {
            redeemError = error.localizedDescription
        }

        isRedeeming = false
    }

    // MARK: - Helpers

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#if DEBUG
struct ReferralView_Previews: PreviewProvider {
    static var previews: some View {
        ReferralView()
    }
}
#endif
