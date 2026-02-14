//
//  ProgramReviewQueueView.swift
//  PTPerformance
//
//  ACP-395: Review and Approval Workflow
//  Main queue for therapists to review AI-generated rehabilitation programs
//

import SwiftUI

// MARK: - Review Queue View

/// Main review queue showing AI-generated programs pending therapist review.
///
/// Displays a filterable list of programs organized by review status.
/// Each row shows program ID, AI confidence badge, status, and submission time.
/// Supports pull-to-refresh, filter tabs, and navigation to the detail review view.
struct ProgramReviewQueueView: View {

    // MARK: - State

    @StateObject private var viewModel = ProgramReviewQueueViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFilter: ReviewFilterTab = .all

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.reviewQueue.isEmpty {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else if filteredReviews.isEmpty {
                    emptyStateView
                } else {
                    reviewList
                }
            }
            .navigationTitle("Program Reviews")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if pendingCount > 0 {
                        pendingBadge
                    }
                }
            }
            .refreshableWithHaptic {
                await viewModel.fetchReviewQueue()
            }
            .task {
                await viewModel.fetchReviewQueue()
            }
        }
    }

    // MARK: - Computed Properties

    private var tabCounts: (all: Int, pending: Int, inReview: Int, completed: Int) {
        var pending = 0
        var inReview = 0
        var completed = 0
        for review in viewModel.reviewQueue {
            switch review.status {
            case .pendingReview:
                pending += 1
            case .inReview:
                inReview += 1
            case .approved, .rejected, .revisionRequested:
                completed += 1
            }
        }
        return (viewModel.reviewQueue.count, pending, inReview, completed)
    }

    private var pendingCount: Int {
        tabCounts.pending
    }

    private var filteredReviews: [ProgramReview] {
        switch selectedFilter {
        case .all:
            return viewModel.reviewQueue
        case .pending:
            return viewModel.reviewQueue.filter { $0.status == .pendingReview }
        case .inReview:
            return viewModel.reviewQueue.filter { $0.status == .inReview }
        case .completed:
            return viewModel.reviewQueue.filter {
                $0.status == .approved || $0.status == .rejected || $0.status == .revisionRequested
            }
        }
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        let counts = tabCounts
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(ReviewFilterTab.allCases, id: \.self) { tab in
                    ReviewFilterTabButton(
                        tab: tab,
                        isSelected: selectedFilter == tab,
                        count: {
                            switch tab {
                            case .all: return counts.all
                            case .pending: return counts.pending
                            case .inReview: return counts.inReview
                            case .completed: return counts.completed
                            }
                        }()
                    ) {
                        HapticFeedback.selectionChanged()
                        withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                            selectedFilter = tab
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
        }
    }

    // MARK: - Review List

    private var reviewList: some View {
        VStack(spacing: 0) {
            filterTabs

            List {
                ForEach(filteredReviews) { review in
                    NavigationLink {
                        ProgramReviewDetailView(review: review)
                    } label: {
                        ReviewQueueRowView(review: review)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
            Text("Loading review queue...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task {
                    await viewModel.fetchReviewQueue()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 0) {
            filterTabs

            EmptyStateView(
                title: emptyStateTitle,
                message: emptyStateMessage,
                icon: "checkmark.seal",
                iconColor: DesignTokens.statusSuccess
            )
        }
    }

    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all:
            return "No Reviews"
        case .pending:
            return "No Pending Reviews"
        case .inReview:
            return "None In Review"
        case .completed:
            return "No Completed Reviews"
        }
    }

    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return "AI-generated programs will appear here for your review and approval."
        case .pending:
            return "All pending reviews have been addressed. Great work!"
        case .inReview:
            return "No programs are currently being reviewed."
        case .completed:
            return "Completed reviews will appear here after you approve or reject programs."
        }
    }

    // MARK: - Pending Badge

    private var pendingBadge: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.caption)
            Text("\(pendingCount)")
                .font(.caption)
                .fontWeight(.bold)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(ReviewStatus.pendingReview.uiColor.opacity(0.15))
        .foregroundColor(ReviewStatus.pendingReview.uiColor)
        .cornerRadius(CornerRadius.sm)
        .accessibilityLabel("\(pendingCount) pending \(pendingCount == 1 ? "review" : "reviews")")
    }

}

// MARK: - Filter Tab Enum

enum ReviewFilterTab: String, CaseIterable {
    case all = "All"
    case pending = "Pending"
    case inReview = "In Review"
    case completed = "Completed"
}

// MARK: - Filter Tab Button

struct ReviewFilterTabButton: View {
    let tab: ReviewFilterTab
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                Text(tab.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(isSelected ? Color.white.opacity(0.3) : Color(.tertiarySystemFill))
                        .cornerRadius(CornerRadius.xs)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(CornerRadius.md)
        }
        .accessibilityLabel("\(tab.rawValue), \(count) \(count == 1 ? "item" : "items")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Review Queue Row

struct ReviewQueueRowView: View {
    let review: ProgramReview

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Top row: Program ID + status badge
            HStack {
                Text("Program Review")
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                ReviewStatusBadge(status: review.status)
            }

            // AI info row
            HStack(spacing: Spacing.xs) {
                if review.aiGenerated {
                    Image(systemName: "cpu")
                        .font(.caption)
                        .foregroundColor(DesignTokens.statusInfo)
                        .accessibilityHidden(true)

                    if let model = review.aiModel {
                        Text(model)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("AI Generated")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            // Bottom row: AI confidence + time submitted
            HStack {
                // AI confidence badge
                if let confidence = review.aiConfidenceScore {
                    AIConfidenceBadge(score: confidence)
                }

                if review.hasCriticalContraindications {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text("Critical")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(DesignTokens.statusError)
                }

                Spacer()

                // Time submitted
                Text(review.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                + Text(" ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, Spacing.xxs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to review this program")
    }

    private var accessibilityDescription: String {
        var parts: [String] = ["Program Review"]
        parts.append("Status: \(review.status.displayName)")
        if review.aiGenerated, let model = review.aiModel {
            parts.append("AI model: \(model)")
        }
        if let confidence = review.aiConfidenceScore {
            parts.append("AI confidence: \(Int(confidence)) percent")
        }
        if review.hasCriticalContraindications {
            parts.append("Critical contraindication flagged")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Review Status Badge

struct ReviewStatusBadge: View {
    let status: ReviewStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(status.uiColor.opacity(0.15))
            .foregroundColor(status.uiColor)
            .cornerRadius(CornerRadius.xs)
            .accessibilityLabel("Status: \(status.displayName)")
    }
}

// MARK: - AI Confidence Badge

/// Displays AI confidence score as a colored badge.
/// Score is on a 0-100 scale (matching ProgramReview.aiConfidenceScore).
struct AIConfidenceBadge: View {
    let score: Double

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: "cpu")
                .font(.caption2)
                .accessibilityHidden(true)

            Text("\(Int(score))%")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 2)
        .background(confidenceColor.opacity(0.12))
        .foregroundColor(confidenceColor)
        .cornerRadius(CornerRadius.xs)
        .accessibilityLabel("AI confidence \(Int(score)) percent")
    }

    private var confidenceColor: Color {
        switch score {
        case 80...:
            return DesignTokens.statusSuccess
        case 60..<80:
            return DesignTokens.statusWarning
        default:
            return DesignTokens.statusError
        }
    }
}

// MARK: - ReviewStatus UI Extensions

extension ReviewStatus {
    /// Color for UI display of review status
    var uiColor: Color {
        switch self {
        case .pendingReview:
            return DesignTokens.statusWarning
        case .inReview:
            return DesignTokens.statusInfo
        case .approved:
            return DesignTokens.statusSuccess
        case .rejected:
            return DesignTokens.statusError
        case .revisionRequested:
            return .orange
        }
    }
}

// MARK: - View Model

@MainActor
final class ProgramReviewQueueViewModel: ObservableObject {
    @Published var reviewQueue: [ProgramReview] = []
    @Published var isLoading = false
    @Published var error: String?

    private let reviewService = ProgramReviewService()

    func fetchReviewQueue() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        guard let userIdString = PTSupabaseClient.shared.userId,
              let therapistId = UUID(uuidString: userIdString) else {
            self.error = "Not authenticated. Please sign in again."
            return
        }

        do {
            let reviews = try await reviewService.fetchReviewQueue(
                therapistId: therapistId
            )
            reviewQueue = reviews
        } catch {
            self.error = "Failed to load review queue: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Review Queue") {
    ProgramReviewQueueView()
}

#Preview("Queue Row - Pending") {
    List {
        ReviewQueueRowView(review: ProgramReview.samplePending)
        ReviewQueueRowView(review: ProgramReview.sampleApproved)
        ReviewQueueRowView(review: ProgramReview.sampleRejected)
    }
    .listStyle(.insetGrouped)
}

#Preview("Filter Tabs") {
    HStack {
        ReviewFilterTabButton(tab: .all, isSelected: true, count: 12) {}
        ReviewFilterTabButton(tab: .pending, isSelected: false, count: 5) {}
        ReviewFilterTabButton(tab: .inReview, isSelected: false, count: 3) {}
        ReviewFilterTabButton(tab: .completed, isSelected: false, count: 4) {}
    }
    .padding()
}

#Preview("Status Badges") {
    VStack(spacing: Spacing.sm) {
        ReviewStatusBadge(status: .pendingReview)
        ReviewStatusBadge(status: .inReview)
        ReviewStatusBadge(status: .approved)
        ReviewStatusBadge(status: .rejected)
        ReviewStatusBadge(status: .revisionRequested)
    }
    .padding()
}

#Preview("AI Confidence Badges") {
    VStack(spacing: Spacing.sm) {
        AIConfidenceBadge(score: 95.0)
        AIConfidenceBadge(score: 72.0)
        AIConfidenceBadge(score: 45.0)
    }
    .padding()
}
#endif
