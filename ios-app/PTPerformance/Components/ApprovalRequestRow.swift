//
//  ApprovalRequestRow.swift
//  PTPerformance
//
//  Compact row component for the Therapist Approval Queue list.
//  Shows request type, title, severity, time remaining, and AI confidence.
//

import SwiftUI

// MARK: - Approval Request Row

/// Compact list row displaying an approval request summary.
/// Used in ApprovalQueueView to show each request at a glance.
struct ApprovalRequestRow: View {
    let request: ApprovalRequest

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Request type icon
            requestTypeIcon

            // Title and subtitle
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(request.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: Spacing.xs) {
                    // Request type label
                    Text(request.requestType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Time remaining
                    if let timeText = request.timeRemainingText {
                        Text(timeText)
                            .font(.caption)
                            .foregroundColor(timeTextColor)
                    }
                }
            }

            Spacer()

            // Right side: severity badge, confidence, chevron
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                severityBadge

                if let confidenceText = request.confidenceText {
                    Text(confidenceText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view details")
        .accessibilityIdentifier("approval_request_row_\(request.id.uuidString)")
    }

    // MARK: - Subviews

    private var requestTypeIcon: some View {
        ZStack {
            Circle()
                .fill(Color.modusCyan.opacity(0.15))
                .frame(width: 40, height: 40)

            Image(systemName: request.requestType.icon)
                .font(.system(size: 18))
                .foregroundColor(.modusCyan)
        }
    }

    private var severityBadge: some View {
        Text(request.severity.displayName)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(severityColor)
            .cornerRadius(CornerRadius.xs)
    }

    // MARK: - Computed Properties

    private var severityColor: Color {
        switch request.severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }

    private var timeTextColor: Color {
        guard let expiresAt = request.expiresAt else { return .secondary }
        let hoursRemaining = expiresAt.timeIntervalSince(Date()) / 3600
        if hoursRemaining <= 0 { return .red }
        if hoursRemaining < 12 { return .orange }
        return .secondary
    }

    private var accessibilityLabel: String {
        var label = "\(request.requestType.displayName): \(request.title), severity \(request.severity.displayName)"
        if let time = request.timeRemainingText {
            label += ", \(time)"
        }
        if let confidence = request.confidenceText {
            label += ", \(confidence)"
        }
        return label
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Approval Request Rows") {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(ApprovalRequest.mockPendingRequests) { request in
                ApprovalRequestRow(request: request)
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
#endif
