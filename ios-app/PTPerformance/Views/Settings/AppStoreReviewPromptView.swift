//
//  AppStoreReviewPromptView.swift
//  PTPerformance
//
//  ACP-998: App Store Optimization — Inline review prompt
//
//  Appears after positive moments (workout complete, achievement unlock).
//  Routes 4-5 star ratings to SKStoreReviewController and 1-3 star ratings
//  to an in-app feedback form.
//

import SwiftUI

// MARK: - Review Prompt View

/// Inline review prompt that appears after positive user moments.
///
/// Flow:
/// 1. "Enjoying Modus?" with star rating selector
/// 2. If 4-5 stars → triggers SKStoreReviewController system dialog
/// 3. If 1-3 stars → shows in-app feedback form
/// 4. "Not now" dismisses with cooldown, "Don't ask again" permanently dismisses
struct AppStoreReviewPromptView: View {
    @StateObject private var asoService = ASOService.shared
    @State private var selectedRating: Int = 0
    @State private var showFeedbackForm = false
    @State private var feedbackText = ""
    @State private var feedbackSubmitted = false
    @State private var animateStars = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.lg) {
            if feedbackSubmitted {
                thankYouView
            } else if showFeedbackForm {
                feedbackFormView
            } else {
                ratingView
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, Spacing.md)
        .onAppear {
            asoService.recordInlinePromptShown()
            withAnimation(.easeOut(duration: AnimationDuration.standard).delay(0.2)) {
                animateStars = true
            }
        }
    }

    // MARK: - Rating View

    private var ratingView: some View {
        VStack(spacing: Spacing.md) {
            // App icon placeholder
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.modusCyan)
                .accessibilityHidden(true)

            Text("Enjoying Modus?")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Text("Your feedback helps us improve the app for everyone.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.sm)

            // Star rating selector
            starRatingSelector
                .padding(.vertical, Spacing.xs)

            // Action buttons
            if selectedRating > 0 {
                submitButton
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            dismissButtons
        }
        .animation(.easeInOut(duration: AnimationDuration.standard), value: selectedRating)
    }

    // MARK: - Star Rating Selector

    private var starRatingSelector: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        selectedRating = star
                    }
                    HapticFeedback.light()
                } label: {
                    Image(systemName: star <= selectedRating ? "star.fill" : "star")
                        .font(.system(size: 36))
                        .foregroundStyle(star <= selectedRating ? .yellow : Color(.tertiaryLabel))
                        .scaleEffect(animateStars ? 1.0 : 0.5)
                        .opacity(animateStars ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.5)
                                .delay(Double(star) * 0.06),
                            value: animateStars
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                .accessibilityAddTraits(star == selectedRating ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Rate Modus from 1 to 5 stars")
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            handleRatingSubmission()
        } label: {
            Text(selectedRating >= 4 ? "Rate on App Store" : "Submit Feedback")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color.modusCyan)
                )
        }
        .accessibilityHint(selectedRating >= 4
            ? "Opens the App Store rating dialog"
            : "Shows a text feedback form")
    }

    // MARK: - Dismiss Buttons

    private var dismissButtons: some View {
        HStack(spacing: Spacing.lg) {
            Button("Not now") {
                asoService.dismissPrompt()
                dismiss()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button("Don't ask again") {
                asoService.permanentlyDismissPrompt()
                dismiss()
            }
            .font(.subheadline)
            .foregroundStyle(.tertiary)
        }
        .padding(.top, Spacing.xxs)
    }

    // MARK: - Feedback Form View

    private var feedbackFormView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.modusCyan)
                .accessibilityHidden(true)

            Text("How can we improve?")
                .font(.title3)
                .fontWeight(.semibold)

            Text("We'd love to hear what would make Modus better for you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextEditor(text: $feedbackText)
                .frame(minHeight: 100, maxHeight: 160)
                .padding(Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .accessibilityLabel("Feedback text field")
                .accessibilityHint("Enter your feedback about the app")

            HStack(spacing: Spacing.md) {
                Button("Cancel") {
                    asoService.dismissPrompt()
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Button {
                    submitFeedback()
                } label: {
                    Text("Send Feedback")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                      ? Color.gray
                                      : Color.modusCyan)
                        )
                }
                .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityHint("Send your feedback to the Modus team")
            }
        }
    }

    // MARK: - Thank You View

    private var thankYouView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.statusSuccess)
                .accessibilityHidden(true)

            Text("Thank you!")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Your feedback helps us build a better app.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Done") {
                dismiss()
            }
            .font(.headline)
            .foregroundStyle(Color.modusCyan)
            .padding(.top, Spacing.xs)
        }
        .onAppear {
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                dismiss()
            }
        }
    }

    // MARK: - Actions

    private func handleRatingSubmission() {
        asoService.recordStarRating(selectedRating)

        if selectedRating >= 4 {
            // High rating — system review dialog was triggered by recordStarRating
            // Show thank you then dismiss
            withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                feedbackSubmitted = true
            }
        } else {
            // Low rating — show feedback form
            withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                showFeedbackForm = true
            }
        }

        HapticFeedback.medium()
    }

    private func submitFeedback() {
        let trimmedFeedback = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFeedback.isEmpty else { return }

        // Log feedback for analytics
        ErrorLogger.shared.logUserAction(
            action: "app_feedback_submitted",
            properties: [
                "rating": String(selectedRating),
                "feedback_length": String(trimmedFeedback.count)
            ]
        )

        // Sync feedback to Supabase
        Task {
            await syncFeedbackToSupabase(rating: selectedRating, feedback: trimmedFeedback)
        }

        withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
            feedbackSubmitted = true
        }

        HapticFeedback.success()
        DebugLogger.shared.success("AppStoreReviewPrompt", "Feedback submitted — \(selectedRating) stars, \(trimmedFeedback.count) chars")
    }

    private func syncFeedbackToSupabase(rating: Int, feedback: String) async {
        do {
            let payload: [String: String] = [
                "user_id": PTSupabaseClient.shared.userId ?? "anonymous",
                "rating": String(rating),
                "feedback": feedback,
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "build_number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]

            try await PTSupabaseClient.shared.client
                .from("app_feedback")
                .insert(payload)
                .execute()

            DebugLogger.shared.success("AppStoreReviewPrompt", "Feedback synced to Supabase")
        } catch {
            DebugLogger.shared.warning("AppStoreReviewPrompt", "Failed to sync feedback: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Review Prompt") {
    VStack {
        Spacer()
        AppStoreReviewPromptView()
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}
#endif
