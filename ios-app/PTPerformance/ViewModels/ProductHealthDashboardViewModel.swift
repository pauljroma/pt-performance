//
//  ProductHealthDashboardViewModel.swift
//  PTPerformance
//
//  ViewModel for the Product Health Dashboard
//  Loads DAU/WAU/MAU, feature adoption, satisfaction, safety, and subscription health
//

import Foundation

// MARK: - Product Health Dashboard ViewModel

@MainActor
final class ProductHealthDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var health: ProductHealthResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedPeriod: Int = 30

    // MARK: - Private Properties

    private let service = EdgeFunctionAnalyticsService.shared

    // MARK: - Public Methods

    /// Load product health data for the selected period
    func loadHealth() async {
        isLoading = true
        errorMessage = nil

        do {
            health = try await service.fetchProductHealth(periodDays: selectedPeriod)
        } catch {
            errorMessage = error.localizedDescription
            ErrorLogger.shared.logError(error, context: "ProductHealthDashboardViewModel.loadHealth")
        }

        isLoading = false
    }

    // MARK: - Computed Helpers

    /// Feature adoption entries sorted by adoption percentage descending
    var sortedFeatureAdoption: [(key: String, value: FeatureAdoptionMetric)] {
        (health?.featureAdoption ?? [:])
            .sorted { ($0.value.adoptionPct ?? 0) > ($1.value.adoptionPct ?? 0) }
    }

    /// Total rating count from the distribution
    var totalRatings: Int {
        guard let dist = health?.satisfaction?.ratingDistribution else { return 0 }
        return (dist.oneStar ?? 0) + (dist.twoStar ?? 0) + (dist.threeStar ?? 0)
             + (dist.fourStar ?? 0) + (dist.fiveStar ?? 0)
    }

    /// Rating distribution as an array of (stars, count) for charting
    var ratingDistributionData: [(stars: Int, count: Int)] {
        guard let dist = health?.satisfaction?.ratingDistribution else { return [] }
        return [
            (1, dist.oneStar ?? 0),
            (2, dist.twoStar ?? 0),
            (3, dist.threeStar ?? 0),
            (4, dist.fourStar ?? 0),
            (5, dist.fiveStar ?? 0)
        ]
    }

    /// Period display label
    var periodLabel: String {
        switch selectedPeriod {
        case 7: return "7 Days"
        case 30: return "30 Days"
        case 90: return "90 Days"
        default: return "\(selectedPeriod) Days"
        }
    }
}
