//
//  ApprovalRequestDetailView.swift
//  PTPerformance
//
//  Detail view for a single approval request in the Therapist Approval Gate system.
//  Shows full request details, AI rationale, suggested changes, and action buttons.
//

import SwiftUI

// MARK: - Approval Request Detail View

struct ApprovalRequestDetailView: View {
    let request: ApprovalRequest

    @StateObject private var viewModel = ApprovalRequestViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var therapistNotes: String = ""
    @State private var showRejectConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header: patient, type, severity
                headerSection

                Divider()

                // Title and description
                detailSection

                // AI Rationale
                if request.aiRationale != nil || request.aiConfidence != nil {
                    aiRationaleSection
                }

                // Suggested Change Details
                suggestedChangeSection

                // Time Remaining
                if request.status.isPending {
                    timeRemainingSection
                }

                // Status badge for non-pending requests
                if !request.status.isPending {
                    statusSection
                }

                Divider()

                // Therapist notes input
                if request.status.isPending {
                    therapistNotesSection
                } else if let notes = request.therapistNotes, !notes.isEmpty {
                    existingNotesSection(notes: notes)
                }

                // Action buttons (only for pending requests)
                if request.isActionable {
                    actionButtonsSection
                }
            }
            .padding(Spacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Request Detail")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reject Modification", isPresented: $showRejectConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reject", role: .destructive) {
                Task { await rejectRequest() }
            }
        } message: {
            Text("Are you sure you want to reject this modification? The AI-suggested change will not be applied.")
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .overlay {
            if viewModel.isProcessing {
                processingOverlay
            }
        }
        // Success dismissal
        .onChange(of: viewModel.successMessage) { _, newValue in
            if newValue != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Patient ID (placeholder - show patientId for now)
            HStack(spacing: Spacing.xs) {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.modusCyan)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Patient")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(request.patientId.uuidString.prefix(8) + "...")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Severity badge (large)
                severityBadge
            }

            // Request type
            HStack(spacing: Spacing.xs) {
                Image(systemName: request.requestType.icon)
                    .font(.body)
                    .foregroundColor(.modusCyan)

                Text(request.requestType.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityIdentifier("approval_detail_header")
    }

    private var severityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(severityColor)
                .frame(width: 8, height: 8)

            Text(request.severity.displayName)
                .font(.caption)
                .fontWeight(.bold)
        }
        .foregroundColor(severityColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(severityColor.opacity(0.15))
        .cornerRadius(CornerRadius.sm)
        .accessibilityIdentifier("approval_detail_severity_badge")
    }

    // MARK: - Detail Section

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(request.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(request.description)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityIdentifier("approval_detail_description")
    }

    // MARK: - AI Rationale Section

    private var aiRationaleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.modusCyan)
                Text("AI Rationale")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()

                if let confidenceText = request.confidenceText {
                    confidenceBadge(confidenceText)
                }
            }

            if let rationale = request.aiRationale {
                Text(rationale)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Confidence bar
            if let confidence = request.aiConfidence {
                confidenceBar(confidence: confidence)
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityIdentifier("approval_detail_ai_rationale")
    }

    private func confidenceBadge(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.modusCyan)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.modusCyan.opacity(0.12))
            .cornerRadius(CornerRadius.xs)
    }

    private func confidenceBar(confidence: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(confidenceColor(confidence))
                        .frame(width: geometry.size.width * confidence, height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("Low")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("High")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityLabel("AI confidence \(Int(confidence * 100)) percent")
        .accessibilityIdentifier("approval_detail_confidence_bar")
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .orange }
        return .red
    }

    // MARK: - Suggested Change Section

    private var suggestedChangeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "doc.badge.gearshape")
                    .foregroundColor(.modusCyan)
                Text("Suggested Changes")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            // Display available change data
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let modType = request.suggestedChange.modificationType {
                    changeDetailRow(label: "Type", value: modType.replacingOccurrences(of: "_", with: " ").capitalized)
                }

                if let pct = request.suggestedChange.changePercentage {
                    let sign = pct > 0 ? "+" : ""
                    changeDetailRow(label: "Change", value: "\(sign)\(Int(pct))%")
                }

                if let sameGroup = request.suggestedChange.sameMusclGroup {
                    changeDetailRow(label: "Same Muscle Group", value: sameGroup ? "Yes" : "No")
                }

                if let painRelated = request.suggestedChange.painRelated {
                    changeDetailRow(label: "Pain Related", value: painRelated ? "Yes" : "No")
                }

                // Show raw keys if there are additional fields
                let knownKeys: Set<String> = ["modification_type", "increase_percentage", "reduction_percentage", "same_muscle_group", "pain_related"]
                let extraKeys = request.suggestedChange.rawData.keys.filter { !knownKeys.contains($0) }
                ForEach(Array(extraKeys.sorted()), id: \.self) { key in
                    if let value = request.suggestedChange.rawData[key]?.value {
                        changeDetailRow(
                            label: key.replacingOccurrences(of: "_", with: " ").capitalized,
                            value: "\(value)"
                        )
                    }
                }

                if request.suggestedChange.rawData.isEmpty {
                    Text("No detailed change data available.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .accessibilityIdentifier("approval_detail_suggested_changes")
    }

    private func changeDetailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Time Remaining Section

    private var timeRemainingSection: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "clock")
                .foregroundColor(timeColor)

            if let timeText = request.timeRemainingText {
                Text(timeText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(timeColor)
            } else {
                Text("No expiration set")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let expiresAt = request.expiresAt {
                Text(expiresAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.md)
        .background(timeColor.opacity(0.08))
        .cornerRadius(CornerRadius.md)
        .accessibilityIdentifier("approval_detail_time_remaining")
    }

    private var timeColor: Color {
        guard let expiresAt = request.expiresAt else { return .secondary }
        let hoursRemaining = expiresAt.timeIntervalSince(Date()) / 3600
        if hoursRemaining <= 0 { return .red }
        if hoursRemaining < 12 { return .orange }
        if hoursRemaining < 24 { return .yellow }
        return .modusCyan
    }

    // MARK: - Status Section (for non-pending)

    private var statusSection: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: request.status.icon)
                .foregroundColor(statusColor)

            Text(request.status.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)

            Spacer()

            if let reviewedAt = request.reviewedAt {
                Text(reviewedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                + Text(" ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.md)
        .background(statusColor.opacity(0.08))
        .cornerRadius(CornerRadius.md)
        .accessibilityIdentifier("approval_detail_status")
    }

    private var statusColor: Color {
        switch request.status {
        case .approved, .autoApproved: return .green
        case .rejected: return .red
        case .expired: return .orange
        case .pending: return .modusCyan
        }
    }

    // MARK: - Therapist Notes Section

    private var therapistNotesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Therapist Notes")
                .font(.headline)
                .fontWeight(.semibold)

            Text("Add optional notes explaining your decision.")
                .font(.caption)
                .foregroundColor(.secondary)

            TextEditor(text: $therapistNotes)
                .frame(minHeight: 80)
                .padding(Spacing.xs)
                .background(Color(.systemBackground))
                .cornerRadius(CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .accessibilityIdentifier("approval_detail_notes_input")
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func existingNotesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Therapist Notes")
                .font(.headline)
                .fontWeight(.semibold)

            Text(notes)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Action Buttons

    private var actionButtonsSection: some View {
        HStack(spacing: Spacing.md) {
            // Reject button
            Button {
                HapticFeedback.medium()
                showRejectConfirmation = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Reject")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.md)
            }
            .disabled(viewModel.isProcessing)
            .accessibilityIdentifier("approval_detail_reject_button")

            // Approve button
            Button {
                HapticFeedback.medium()
                Task { await approveRequest() }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Approve")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.md)
            }
            .disabled(viewModel.isProcessing)
            .accessibilityIdentifier("approval_detail_approve_button")
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: - Processing Overlay

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Submitting review...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(Spacing.lg)
            .background(.ultraThinMaterial)
            .cornerRadius(CornerRadius.lg)
        }
        .accessibilityIdentifier("approval_detail_processing_overlay")
    }

    // MARK: - Actions

    private func approveRequest() async {
        guard let therapistUserId = appState.userId else { return }
        let notes = therapistNotes.isEmpty ? nil : therapistNotes
        let success = await viewModel.approveRequest(
            requestId: request.id,
            therapistUserId: therapistUserId,
            notes: notes
        )
        if success {
            HapticFeedback.success()
        }
    }

    private func rejectRequest() async {
        guard let therapistUserId = appState.userId else { return }
        let notes = therapistNotes.isEmpty ? "Rejected by therapist" : therapistNotes
        let success = await viewModel.rejectRequest(
            requestId: request.id,
            therapistUserId: therapistUserId,
            notes: notes
        )
        if success {
            HapticFeedback.success()
        }
    }

    // MARK: - Severity Color

    private var severityColor: Color {
        switch request.severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Approval Detail - Pending") {
    NavigationStack {
        ApprovalRequestDetailView(
            request: ApprovalRequest.mockPendingRequests[0]
        )
        .environmentObject(AppState())
    }
}

#Preview("Approval Detail - Critical") {
    NavigationStack {
        ApprovalRequestDetailView(
            request: ApprovalRequest.mockPendingRequests[2]
        )
        .environmentObject(AppState())
    }
}
#endif
