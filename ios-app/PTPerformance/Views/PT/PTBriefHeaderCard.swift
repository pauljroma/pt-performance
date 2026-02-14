//
//  PTBriefHeaderCard.swift
//  PTPerformance
//
//  PT Brief Header Card - Large readiness score with trend and confidence
//  Part of the 60-Second Athlete Brief workflow
//
//  Features:
//  - Large readiness score with color coding
//  - Trend indicator (improving/stable/declining)
//  - Confidence bar showing data quality
//  - Last update timestamp
//  - Tap to see score breakdown
//

import SwiftUI

struct PTBriefHeaderCard: View {
    let readiness: PTBriefReadiness?
    let isLoading: Bool
    let onTapBreakdown: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTapBreakdown()
        }) {
            VStack(spacing: Spacing.md) {
                if isLoading {
                    loadingState
                } else if let readiness = readiness {
                    readinessContent(readiness)
                } else {
                    noDataState
                }
            }
            .padding(Spacing.lg)
            .background(cardBackground)
            .cornerRadius(CornerRadius.lg)
            .shadow(
                color: Shadow.medium.color(for: colorScheme),
                radius: Shadow.medium.radius,
                x: Shadow.medium.x,
                y: Shadow.medium.y
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Tap to view score breakdown")
    }

    // MARK: - Readiness Content

    @ViewBuilder
    private func readinessContent(_ readiness: PTBriefReadiness) -> some View {
        HStack(spacing: Spacing.lg) {
            // Score Circle
            scoreCircle(readiness)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Trend Indicator
                trendIndicator(readiness)

                // Confidence Bar
                confidenceBar(readiness)

                // Last Updated
                lastUpdatedLabel(readiness)
            }

            Spacer()

            // Drill-down chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }

        // Citation count badge
        HStack {
            Spacer()
            citationBadge(count: readiness.citationCount)
        }
    }

    // MARK: - Score Circle

    private func scoreCircle(_ readiness: PTBriefReadiness) -> some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 100, height: 100)

            // Progress circle
            Circle()
                .trim(from: 0, to: readiness.score / 100)
                .stroke(
                    readiness.scoreColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: AnimationDuration.standard), value: readiness.score)

            // Score Value
            VStack(spacing: 2) {
                Text("\(Int(readiness.score))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(readiness.scoreColor)

                Text(readiness.scoreLabel)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Trend Indicator

    private func trendIndicator(_ readiness: PTBriefReadiness) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: readiness.trend.icon)
                .font(.caption)
                .foregroundColor(readiness.trend.color)

            Text(readiness.trend.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Spacer()
        }
    }

    // MARK: - Confidence Bar

    private func confidenceBar(_ readiness: PTBriefReadiness) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Confidence")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(readiness.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))

                    // Fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(confidenceColor(readiness.confidence))
                        .frame(width: geometry.size.width * readiness.confidence)
                        .animation(.easeInOut(duration: AnimationDuration.standard), value: readiness.confidence)
                }
            }
            .frame(height: 6)

            // Confidence reason (uncertainty explicit)
            if readiness.confidence < 0.8 {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption2)

                    Text(readiness.confidenceReason)
                        .font(.caption2)
                }
                .foregroundColor(.orange)
            }
        }
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.8...: return .green
        case 0.6..<0.8: return .yellow
        default: return .orange
        }
    }

    // MARK: - Last Updated

    private func lastUpdatedLabel(_ readiness: PTBriefReadiness) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text("Updated \(formattedTime(readiness.lastUpdated))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Citation Badge

    private func citationBadge(count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.text.fill")
                .font(.caption2)

            Text("\(count) sources")
                .font(.caption2)
        }
        .foregroundColor(.modusCyan)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(Color.modusCyan.opacity(0.1))
        .cornerRadius(CornerRadius.xs)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        HStack(spacing: Spacing.lg) {
            // Placeholder circle
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(ProgressView())

            VStack(alignment: .leading, spacing: Spacing.sm) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 16)
                    .frame(maxWidth: 120)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                    .frame(maxWidth: 100)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 6)
            }

            Spacer()
        }
        .pulse()
    }

    // MARK: - No Data State

    private var noDataState: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("No Readiness Data")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Check-in not yet completed today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Helpers

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.secondarySystemGroupedBackground).opacity(0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var accessibilityLabel: String {
        guard let readiness = readiness else {
            return "Readiness score unavailable"
        }
        return "Readiness score \(Int(readiness.score)), \(readiness.trend.displayName), \(Int(readiness.confidence * 100))% confidence, based on \(readiness.citationCount) sources"
    }
}

// MARK: - Preview

#if DEBUG
struct PTBriefHeaderCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // With data
            PTBriefHeaderCard(
                readiness: PTBriefReadiness(
                    score: 78,
                    trend: .improving,
                    confidence: 0.85,
                    confidenceReason: "5 data sources, high consistency",
                    lastUpdated: Date().addingTimeInterval(-3600),
                    citationCount: 6
                ),
                isLoading: false,
                onTapBreakdown: {}
            )
            .padding()
            .previewDisplayName("With Data")

            // Low confidence
            PTBriefHeaderCard(
                readiness: PTBriefReadiness(
                    score: 65,
                    trend: .declining,
                    confidence: 0.55,
                    confidenceReason: "Limited data from past 24h",
                    lastUpdated: Date().addingTimeInterval(-7200),
                    citationCount: 2
                ),
                isLoading: false,
                onTapBreakdown: {}
            )
            .padding()
            .previewDisplayName("Low Confidence")

            // Loading
            PTBriefHeaderCard(
                readiness: nil,
                isLoading: true,
                onTapBreakdown: {}
            )
            .padding()
            .previewDisplayName("Loading")

            // No data
            PTBriefHeaderCard(
                readiness: nil,
                isLoading: false,
                onTapBreakdown: {}
            )
            .padding()
            .previewDisplayName("No Data")

            // Dark mode
            PTBriefHeaderCard(
                readiness: PTBriefReadiness(
                    score: 82,
                    trend: .stable,
                    confidence: 0.92,
                    confidenceReason: "All sources aligned",
                    lastUpdated: Date(),
                    citationCount: 8
                ),
                isLoading: false,
                onTapBreakdown: {}
            )
            .padding()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
