//
//  ApprovalQueueView.swift
//  PTPerformance
//
//  Main approval queue view for the Therapist Approval Gate system.
//  Displays pending, approved, rejected, and all approval requests
//  with segmented filtering, pull-to-refresh, and empty/loading states.
//

import SwiftUI

// MARK: - Filter Segment

/// Segments for filtering approval requests by status
enum ApprovalFilterSegment: String, CaseIterable, Identifiable {
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"
    case all = "All"

    var id: String { rawValue }

    var statusFilter: ApprovalStatus? {
        switch self {
        case .pending: return .pending
        case .approved: return .approved
        case .rejected: return .rejected
        case .all: return nil
        }
    }
}

// MARK: - Approval Queue View

struct ApprovalQueueView: View {
    @StateObject private var viewModel = ApprovalRequestViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSegment: ApprovalFilterSegment = .pending

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Pending count header
                pendingCountHeader

                // Segmented picker
                segmentedPicker

                // Content
                contentView
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Approval Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("approval_queue_done_button")
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Pending Count Header

    private var pendingCountHeader: some View {
        HStack(spacing: Spacing.sm) {
            if viewModel.pendingCount > 0 {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.title3)
                        .foregroundColor(.orange)

                    Text("\(viewModel.pendingCount) pending")
                        .font(.headline)
                        .fontWeight(.semibold)

                    if viewModel.hasCriticalPending {
                        Text("\(viewModel.criticalPendingCount) critical")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(CornerRadius.xs)
                    }
                }
            } else if !viewModel.isLoading {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.modusTealAccent)

                    Text("All caught up")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color(.systemBackground))
        .accessibilityIdentifier("approval_queue_pending_header")
    }

    // MARK: - Segmented Picker

    private var segmentedPicker: some View {
        Picker("Filter", selection: $selectedSegment) {
            ForEach(ApprovalFilterSegment.allCases) { segment in
                Text(segment.rawValue).tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(Color(.systemBackground))
        .onChange(of: selectedSegment) { _, _ in
            Task {
                await loadData()
            }
        }
        .accessibilityIdentifier("approval_queue_segment_picker")
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingView
        } else if filteredRequests.isEmpty {
            emptyStateView
        } else {
            requestListView
        }
    }

    // MARK: - Request List

    private var requestListView: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(filteredRequests) { request in
                    NavigationLink {
                        ApprovalRequestDetailView(request: request)
                            .environmentObject(appState)
                    } label: {
                        ApprovalRequestRow(request: request)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .refreshableWithHaptic {
            await loadData()
        }
        .accessibilityIdentifier("approval_queue_list")
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading approvals...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("approval_queue_loading")
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Spacer()

            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text(emptyStateTitle)
                .font(.title3)
                .fontWeight(.semibold)

            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("approval_queue_empty_state")
    }

    // MARK: - Helpers

    private var filteredRequests: [ApprovalRequest] {
        switch selectedSegment {
        case .pending:
            return viewModel.approvalRequests.filter { $0.status == .pending }
        case .approved:
            return viewModel.approvalRequests.filter { $0.status == .approved || $0.status == .autoApproved }
        case .rejected:
            return viewModel.approvalRequests.filter { $0.status == .rejected }
        case .all:
            return viewModel.approvalRequests
        }
    }

    private var emptyStateIcon: String {
        switch selectedSegment {
        case .pending: return "checkmark.seal"
        case .approved: return "checkmark.circle"
        case .rejected: return "xmark.circle"
        case .all: return "tray"
        }
    }

    private var emptyStateTitle: String {
        switch selectedSegment {
        case .pending: return "No Pending Requests"
        case .approved: return "No Approved Requests"
        case .rejected: return "No Rejected Requests"
        case .all: return "No Requests"
        }
    }

    private var emptyStateMessage: String {
        switch selectedSegment {
        case .pending: return "All AI-generated modifications have been reviewed. New requests will appear here when the AI suggests changes to patient programs."
        case .approved: return "Approved modification requests will appear here."
        case .rejected: return "Rejected modification requests will appear here."
        case .all: return "No approval requests found. Requests are created when the AI suggests modifications to patient programs."
        }
    }

    private func loadData() async {
        guard let therapistId = appState.userId else { return }
        // Fetch all to enable client-side filtering across segments
        await viewModel.fetchApprovals(therapistId: therapistId, statusFilter: nil)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Approval Queue - With Data") {
    ApprovalQueueView()
        .environmentObject(AppState())
}

#Preview("Approval Queue - Empty") {
    ApprovalQueueView()
        .environmentObject(AppState())
}
#endif
