//
//  ProductHealthDashboardView.swift
//  PTPerformance
//
//  Product health dashboard showing DAU/WAU/MAU, feature adoption,
//  satisfaction, safety incidents, and subscription health metrics.
//

import SwiftUI
import Charts

// MARK: - Product Health Dashboard View

struct ProductHealthDashboardView: View {
    @StateObject private var viewModel = ProductHealthDashboardViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.health == nil {
                    ProgressView("Loading product health...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let error = viewModel.errorMessage, viewModel.health == nil {
                    errorView(error)
                } else {
                    mainContent
                }
            }
            .navigationTitle("Product Health")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .refreshable {
                await viewModel.loadHealth()
            }
            .task {
                await viewModel.loadHealth()
            }
            .onChange(of: viewModel.selectedPeriod) { _, _ in
                Task { await viewModel.loadHealth() }
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Period picker
                periodPicker

                // Engagement section
                if let engagement = viewModel.health?.engagement {
                    engagementSection(engagement)
                }

                // Feature adoption section
                if !viewModel.sortedFeatureAdoption.isEmpty {
                    featureAdoptionSection
                }

                // Satisfaction section
                if let satisfaction = viewModel.health?.satisfaction {
                    satisfactionSection(satisfaction)
                }

                // Safety section
                if let safety = viewModel.health?.safety {
                    safetySection(safety)
                }

                // Subscription health section
                if let subHealth = viewModel.health?.subscriptionHealth {
                    subscriptionSection(subHealth)
                }
            }
            .padding()
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            Text("7d").tag(7)
            Text("30d").tag(30)
            Text("90d").tag(90)
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Time period selector")
    }

    // MARK: - Engagement Section

    private func engagementSection(_ engagement: ProductEngagement) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Engagement", systemImage: "person.3.fill")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm)
            ], spacing: Spacing.sm) {
                engagementCard(
                    title: "DAU",
                    value: engagement.dau ?? 0,
                    trend: engagement.dauTrend
                )
                engagementCard(
                    title: "WAU",
                    value: engagement.wau ?? 0,
                    trend: engagement.wauTrend
                )
                engagementCard(
                    title: "MAU",
                    value: engagement.mau ?? 0,
                    trend: engagement.mauTrend
                )
            }

            // Ratios
            HStack(spacing: Spacing.md) {
                if let dauWau = engagement.dauWauRatio {
                    ratioIndicator(label: "DAU/WAU", value: dauWau)
                }
                if let wauMau = engagement.wauMauRatio {
                    ratioIndicator(label: "WAU/MAU", value: wauMau)
                }
                if let total = engagement.totalPatients {
                    HStack(spacing: 4) {
                        Text("Total:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(total)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func engagementCard(title: String, value: Int, trend: Double?) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)

            if let trend = trend {
                HStack(spacing: 2) {
                    Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text(String(format: "%.1f%%", trend))
                        .font(.caption2)
                }
                .foregroundColor(trend >= 0 ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityLabel("\(title): \(value)\(trend != nil ? ", trend \(String(format: "%.1f%%", trend!))" : "")")
    }

    private func ratioIndicator(label: String, value: Double) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.0f%%", value * 100))
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Feature Adoption Section

    private var featureAdoptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Feature Adoption", systemImage: "square.grid.2x2.fill")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: Spacing.xs) {
                ForEach(viewModel.sortedFeatureAdoption, id: \.key) { feature in
                    featureAdoptionBar(
                        name: featureDisplayName(feature.key),
                        adoptionPct: feature.value.adoptionPct ?? 0,
                        users: feature.value.users ?? 0
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func featureAdoptionBar(name: String, adoptionPct: Double, users: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.0f%%", adoptionPct))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                Text("(\(users))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    Capsule()
                        .fill(adoptionBarColor(adoptionPct))
                        .frame(width: max(0, geometry.size.width * min(adoptionPct / 100.0, 1.0)), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityLabel("\(name): \(String(format: "%.0f%%", adoptionPct)) adoption, \(users) users")
    }

    private func featureDisplayName(_ key: String) -> String {
        let map: [String: String] = [
            "sessions": "Sessions",
            "manual_workouts": "Manual Workouts",
            "readiness": "Readiness Check-in",
            "streaks": "Streaks",
            "ai_chat": "AI Coach Chat"
        ]
        return map[key] ?? key.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func adoptionBarColor(_ pct: Double) -> LinearGradient {
        let color: Color = pct >= 60 ? .green : (pct >= 30 ? .blue : .orange)
        return LinearGradient(colors: [color.opacity(0.7), color], startPoint: .leading, endPoint: .trailing)
    }

    // MARK: - Satisfaction Section

    private func satisfactionSection(_ satisfaction: ProductSatisfaction) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Satisfaction", systemImage: "star.fill")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: Spacing.lg) {
                // Avg rating with stars
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", satisfaction.avgRating ?? 0))
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    starsView(rating: satisfaction.avgRating ?? 0)

                    Text("\(satisfaction.totalReviews ?? 0) reviews")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                // NPS proxy
                VStack(spacing: 4) {
                    Text("NPS Proxy")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let nps = satisfaction.npsProxy {
                        Text(String(format: "%+.0f", nps))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(nps >= 0 ? .green : .red)
                    } else {
                        Text("--")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Rating distribution chart
            if !viewModel.ratingDistributionData.isEmpty {
                ratingDistributionChart
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func starsView(rating: Double) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: starImageName(for: star, rating: rating))
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
    }

    private func starImageName(for star: Int, rating: Double) -> String {
        let starDouble = Double(star)
        if rating >= starDouble {
            return "star.fill"
        } else if rating >= starDouble - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }

    private var ratingDistributionChart: some View {
        Chart(viewModel.ratingDistributionData, id: \.stars) { entry in
            BarMark(
                x: .value("Stars", "\(entry.stars)"),
                y: .value("Count", entry.count)
            )
            .foregroundStyle(ratingBarColor(stars: entry.stars))
            .cornerRadius(CornerRadius.xs)
        }
        .chartXAxisLabel("Stars")
        .chartYAxisLabel("Count")
        .frame(height: 140)
    }

    private func ratingBarColor(stars: Int) -> Color {
        switch stars {
        case 5: return .green
        case 4: return .blue
        case 3: return .yellow
        case 2: return .orange
        default: return .red
        }
    }

    // MARK: - Safety Section

    private func safetySection(_ safety: ProductSafety) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Safety", systemImage: "shield.fill")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if let incidents = safety.openIncidents {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.sm) {
                    safetyCountCard(label: "Critical", count: incidents.critical ?? 0, color: .red)
                    safetyCountCard(label: "High", count: incidents.high ?? 0, color: .orange)
                    safetyCountCard(label: "Medium", count: incidents.medium ?? 0, color: .yellow)
                    safetyCountCard(label: "Low", count: incidents.low ?? 0, color: .gray)
                }
            }

            HStack(spacing: Spacing.md) {
                if let totalOpen = safety.totalOpen {
                    safetyMetric(label: "Open", value: "\(totalOpen)")
                }
                if let inPeriod = safety.incidentsInPeriod {
                    safetyMetric(label: "In Period", value: "\(inPeriod)")
                }
                if let resolved = safety.resolvedInPeriod {
                    safetyMetric(label: "Resolved", value: "\(resolved)")
                }
                if let avgHours = safety.avgResolutionHours {
                    safetyMetric(label: "Avg Resolve", value: String(format: "%.0fh", avgHours))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func safetyCountCard(label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(count > 0 ? color : .secondary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(count > 0 ? color.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .accessibilityLabel("\(label): \(count) incidents")
    }

    private func safetyMetric(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Subscription Health Section

    private func subscriptionSection(_ subHealth: ProductSubscriptionHealth) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Subscription Health", systemImage: "creditcard.fill")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm)
            ], spacing: Spacing.sm) {
                subscriptionCard(
                    title: "Trials",
                    value: "\(subHealth.newTrials ?? 0)",
                    color: .blue
                )
                subscriptionCard(
                    title: "Conversions",
                    value: "\(subHealth.conversions ?? 0)",
                    color: .green
                )
                subscriptionCard(
                    title: "Cancellations",
                    value: "\(subHealth.cancellations ?? 0)",
                    color: .red
                )
            }

            HStack(spacing: Spacing.md) {
                if let active = subHealth.activeSubscriptions {
                    HStack(spacing: 4) {
                        Text("Active:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(active)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                Spacer()
                if let convRate = subHealth.trialConversionRate {
                    HStack(spacing: 4) {
                        Text("Conv Rate:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f%%", convRate))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
                Spacer()
                if let churn = subHealth.churnRate {
                    HStack(spacing: 4) {
                        Text("Churn:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f%%", churn))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private func subscriptionCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(color.opacity(0.08))
        .cornerRadius(CornerRadius.sm)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text("Error Loading Product Health")
                .font(.headline)

            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task { await viewModel.loadHealth() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Preview

#if DEBUG
struct ProductHealthDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ProductHealthDashboardView()
    }
}
#endif
