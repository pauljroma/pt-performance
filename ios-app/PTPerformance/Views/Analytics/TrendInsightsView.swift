//
//  TrendInsightsView.swift
//  PTPerformance
//
//  Created for M8 - Historical Trend Analysis Feature
//  AI-generated insights and pattern recognition view
//

import SwiftUI

/// View displaying AI-generated insights based on trend analysis
struct TrendInsightsView: View {

    // MARK: - Properties

    let patientId: UUID

    // MARK: - State

    @StateObject private var viewModel: TrendInsightsViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
        self._viewModel = StateObject(wrappedValue: TrendInsightsViewModel(patientId: patientId))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.insights.isEmpty {
                        emptyStateView
                    } else {
                        // Insights by severity
                        if !viewModel.criticalInsights.isEmpty {
                            insightSection(
                                title: "Needs Attention",
                                icon: "exclamationmark.octagon.fill",
                                color: .red,
                                insights: viewModel.criticalInsights
                            )
                        }

                        if !viewModel.warningInsights.isEmpty {
                            insightSection(
                                title: "Areas to Watch",
                                icon: "exclamationmark.triangle.fill",
                                color: .orange,
                                insights: viewModel.warningInsights
                            )
                        }

                        if !viewModel.positiveInsights.isEmpty {
                            insightSection(
                                title: "Wins & Achievements",
                                icon: "star.fill",
                                color: .green,
                                insights: viewModel.positiveInsights
                            )
                        }

                        if !viewModel.neutralInsights.isEmpty {
                            insightSection(
                                title: "Observations",
                                icon: "info.circle.fill",
                                color: .blue,
                                insights: viewModel.neutralInsights
                            )
                        }

                        // Recommendations section
                        if !viewModel.recommendations.isEmpty {
                            recommendationsSection
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .refreshable {
                await viewModel.loadInsights()
            }
            .task {
                await viewModel.loadInsights()
            }
        }
    }

    // MARK: - Insight Section

    private func insightSection(
        title: String,
        icon: String,
        color: Color,
        insights: [TrendInsight]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 8) {
                ForEach(insights) { insight in
                    InsightDetailCard(insight: insight)
                }
            }
        }
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Recommendations")
                    .font(.headline)
            }
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 8) {
                ForEach(viewModel.recommendations, id: \.self) { recommendation in
                    TrendRecommendationCard(recommendation: recommendation)
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Analyzing your performance...")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Looking for patterns and insights")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Insights Yet", systemImage: "sparkles")
        } description: {
            Text("Complete more sessions to receive personalized insights about your performance trends")
        } actions: {
            Button {
                dismiss()
            } label: {
                Label("Continue Training", systemImage: "figure.run")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Insight Detail Card

struct InsightDetailCard: View {
    let insight: TrendInsight

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                Image(systemName: insight.severity.icon)
                    .foregroundColor(insight.severity.color)
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)

                    if let metricType = insight.metricType {
                        HStack(spacing: 4) {
                            Image(systemName: metricType.icon)
                                .font(.caption2)
                            Text(metricType.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if insight.actionable {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }

            // Message
            Text(insight.message)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Recommendation (expandable)
            if insight.actionable, let recommendation = insight.recommendation {
                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)

                            Text(recommendation)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // Related date
            if let relatedDate = insight.relatedDate {
                Text(relatedDate, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding()
        .background(insight.severity.color.opacity(0.08))
        .cornerRadius(CornerRadius.md)
        .onTapGesture {
            if insight.actionable {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.severity.color == .green ? "Positive" : insight.severity.color == .orange ? "Warning" : "Info") insight: \(insight.title). \(insight.message)")
        .accessibilityHint(insight.actionable ? "Double tap to expand for recommendations" : "")
    }
}

// MARK: - Trend Recommendation Card

private struct TrendRecommendationCard: View {
    let recommendation: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 18))

            Text(recommendation)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.08))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Insights Summary Card (for dashboard)

struct InsightsSummaryCard: View {
    let patientId: UUID
    let onViewAll: () -> Void

    @StateObject private var viewModel = InsightsSummaryViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Insights", systemImage: "sparkles")
                    .font(.headline)

                Spacer()

                Button("View All", action: onViewAll)
                    .font(.caption)
            }

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else if viewModel.topInsights.isEmpty {
                Text("Complete more sessions to get insights")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.topInsights.prefix(3)) { insight in
                        TrendCompactInsightRow(insight: insight)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
        .task {
            await viewModel.loadInsights(for: patientId)
        }
    }
}

private struct TrendCompactInsightRow: View {
    let insight: TrendInsight

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: insight.severity.icon)
                .foregroundColor(insight.severity.color)
                .font(.system(size: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(insight.message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Insights Summary ViewModel

@MainActor
class InsightsSummaryViewModel: ObservableObject {
    @Published var topInsights: [TrendInsight] = []
    @Published var isLoading = false

    private let service = TrendAnalysisService.shared

    func loadInsights(for patientId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let allInsights = try await service.generatePatientInsights(patientId: patientId)
            topInsights = Array(allInsights.prefix(5))
        } catch {
            topInsights = []
        }
    }
}

// MARK: - ViewModel

@MainActor
class TrendInsightsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var insights: [TrendInsight] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Properties

    let patientId: UUID
    private let service = TrendAnalysisService.shared

    // MARK: - Computed Properties

    var criticalInsights: [TrendInsight] {
        insights.filter { $0.severity == .critical }
    }

    var warningInsights: [TrendInsight] {
        insights.filter { $0.severity == .warning }
    }

    var positiveInsights: [TrendInsight] {
        insights.filter { $0.severity == .positive }
    }

    var neutralInsights: [TrendInsight] {
        insights.filter { $0.severity == .neutral }
    }

    var recommendations: [String] {
        insights.compactMap { $0.recommendation }
    }

    // MARK: - Initialization

    init(patientId: UUID) {
        self.patientId = patientId
    }

    // MARK: - Methods

    func loadInsights() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            insights = try await service.generatePatientInsights(patientId: patientId)
        } catch {
            self.error = error
        }
    }
}

// MARK: - Pattern Recognition Card

/// Card displaying detected patterns in user behavior
struct PatternRecognitionCard: View {
    let pattern: DetectedPattern

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: pattern.icon)
                    .foregroundColor(pattern.color)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pattern.title)
                        .font(.subheadline.bold())

                    Text(pattern.frequency)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if pattern.isPositive {
                    Image(systemName: "hand.thumbsup.fill")
                        .foregroundColor(.green)
                }
            }

            Text(pattern.description)
                .font(.caption)
                .foregroundColor(.secondary)

            if let impact = pattern.impact {
                HStack {
                    Text("Impact:")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(impact)
                        .font(.caption2.bold())
                        .foregroundColor(pattern.isPositive ? .green : .orange)
                }
            }
        }
        .padding()
        .background(pattern.color.opacity(0.08))
        .cornerRadius(CornerRadius.md)
    }
}

/// Detected behavioral pattern
struct DetectedPattern: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let frequency: String
    let icon: String
    let color: Color
    let isPositive: Bool
    let impact: String?
}

// MARK: - Preview

#Preview {
    TrendInsightsView(patientId: UUID())
}

#Preview("Insight Card") {
    InsightDetailCard(insight: TrendInsight(
        id: UUID(),
        type: .warning,
        title: "Pain Level Trending Up",
        message: "Your average pain level has increased by 15% over the past 2 weeks",
        severity: .warning,
        metricType: .painLevel,
        relatedDate: Date(),
        actionable: true,
        recommendation: "Consider reducing workout intensity or consulting with your therapist about modifying exercises"
    ))
    .padding()
}

#Preview("Pattern Card") {
    PatternRecognitionCard(pattern: DetectedPattern(
        title: "Weekend Warrior",
        description: "You tend to have higher intensity workouts on weekends",
        frequency: "Detected in 8 of last 10 weeks",
        icon: "calendar.badge.clock",
        color: .purple,
        isPositive: false,
        impact: "+30% injury risk"
    ))
    .padding()
}
