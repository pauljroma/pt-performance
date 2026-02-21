//
//  EdgeFunctionAnalyticsService.swift
//  PTPerformance
//
//  Centralized service for calling analytics edge functions.
//  Each method invokes a Supabase edge function via POST and
//  returns a typed Codable response. Includes 60-second caching.
//

import Foundation
import Supabase

@MainActor
final class EdgeFunctionAnalyticsService: ObservableObject {

    static let shared = EdgeFunctionAnalyticsService()

    private let supabase = PTSupabaseClient.shared

    // MARK: - Cache (60-second TTL per function)

    private struct CacheEntry {
        let data: Any
        let timestamp: Date
    }

    private var cache: [String: CacheEntry] = [:]
    private let cacheTTL: TimeInterval = 60

    private func cached<T>(_ key: String) -> T? {
        guard let entry = cache[key],
              Date().timeIntervalSince(entry.timestamp) < cacheTTL,
              let value = entry.data as? T else {
            return nil
        }
        return value
    }

    private func store<T>(_ value: T, forKey key: String) {
        cache[key] = CacheEntry(data: value, timestamp: Date())
    }

    /// Clear all cached data
    func clearCache() {
        cache.removeAll()
    }

    // MARK: - Revenue Analytics

    /// Fetch revenue analytics (MRR, ARR, churn, cohorts, LTV, forecasting)
    /// - Parameters:
    ///   - periodDays: Lookback period in days (default 30, max 365)
    ///   - sections: Sections to include (metrics, cohorts, ltv, forecasting). Nil = all.
    func fetchRevenueAnalytics(
        periodDays: Int = 30,
        sections: [String]? = nil
    ) async throws -> RevenueAnalyticsResponse {
        let cacheKey = "revenue-\(periodDays)-\(sections?.joined(separator: ",") ?? "all")"
        if let cached: RevenueAnalyticsResponse = cached(cacheKey) { return cached }

        var body: [String: Any] = ["period": periodDays]
        if let sections {
            body["sections"] = sections.joined(separator: ",")
        }

        let result: RevenueAnalyticsResponse = try await invokeFunction("revenue-analytics", body: body)
        store(result, forKey: cacheKey)
        return result
    }

    // MARK: - Retention Analytics

    /// Fetch retention cohort analysis (D1/D7/D30/D90, drivers, resurrected users)
    /// - Parameters:
    ///   - months: Number of months to analyze (default 6)
    ///   - type: Optional filter: "cohorts", "drivers", or "resurrected"
    func fetchRetentionAnalytics(
        months: Int = 6,
        type: String? = nil
    ) async throws -> RetentionAnalyticsResponse {
        let cacheKey = "retention-\(months)-\(type ?? "all")"
        if let cached: RetentionAnalyticsResponse = cached(cacheKey) { return cached }

        var body: [String: Any] = ["months": months]
        if let type { body["type"] = type }

        let result: RetentionAnalyticsResponse = try await invokeFunction("retention-analytics", body: body)
        store(result, forKey: cacheKey)
        return result
    }

    // MARK: - Engagement Scoring

    /// Fetch engagement scores for patients
    /// - Parameters:
    ///   - patientId: Optional specific patient UUID
    ///   - atRisk: If true, fetch only at-risk patients
    ///   - threshold: Score threshold for at-risk (default 30)
    func fetchEngagementScores(
        patientId: String? = nil,
        atRisk: Bool = false,
        threshold: Int = 30
    ) async throws -> EngagementScoresResponse {
        let cacheKey = "engagement-\(patientId ?? "all")-\(atRisk)-\(threshold)"
        if let cached: EngagementScoresResponse = cached(cacheKey) { return cached }

        var body: [String: Any] = [:]
        if let patientId { body["patient_id"] = patientId }
        if atRisk {
            body["at_risk"] = true
            body["threshold"] = threshold
        }

        let result: EngagementScoresResponse = try await invokeFunction("engagement-scoring", body: body)
        store(result, forKey: cacheKey)
        return result
    }

    /// Trigger batch recalculation of engagement scores
    /// - Parameter patientId: Optional single patient to recalculate
    func recalculateEngagementScores(patientId: String? = nil) async throws -> EngagementScoresResponse {
        var body: [String: Any] = ["recalculate": true]
        if let patientId { body["patient_id"] = patientId }

        // Clear cache since we're recalculating
        cache = cache.filter { !$0.key.hasPrefix("engagement-") }

        return try await invokeFunction("engagement-scoring", body: body)
    }

    // MARK: - Training Outcomes

    /// Fetch training outcomes for a patient
    /// - Parameters:
    ///   - patientId: Patient UUID
    ///   - periodDays: Lookback period (default 90)
    func fetchTrainingOutcomes(
        patientId: String,
        periodDays: Int = 90
    ) async throws -> TrainingOutcomesResponse {
        let cacheKey = "training-\(patientId)-\(periodDays)"
        if let cached: TrainingOutcomesResponse = cached(cacheKey) { return cached }

        let body: [String: Any] = [
            "patient_id": patientId,
            "period": periodDays
        ]

        let result: TrainingOutcomesResponse = try await invokeFunction("training-outcomes", body: body)
        store(result, forKey: cacheKey)
        return result
    }

    /// Fetch aggregate program effectiveness (all patients)
    func fetchProgramEffectiveness() async throws -> TrainingOutcomesResponse {
        let cacheKey = "training-aggregate"
        if let cached: TrainingOutcomesResponse = cached(cacheKey) { return cached }

        let body: [String: Any] = ["aggregate": true]

        let result: TrainingOutcomesResponse = try await invokeFunction("training-outcomes", body: body)
        store(result, forKey: cacheKey)
        return result
    }

    // MARK: - Executive Dashboard

    /// Fetch the executive KPI dashboard
    /// - Parameter format: "digest" for email-friendly format, nil for full dashboard
    func fetchExecutiveDashboard(format: String? = nil) async throws -> ExecutiveDashboardResponse {
        let cacheKey = "executive-\(format ?? "full")"
        if let cached: ExecutiveDashboardResponse = cached(cacheKey) { return cached }

        var body: [String: Any] = [:]
        if let format { body["format"] = format }

        let result: ExecutiveDashboardResponse = try await invokeFunction("executive-dashboard", body: body)
        store(result, forKey: cacheKey)
        return result
    }

    // MARK: - Product Health

    /// Fetch product health metrics (DAU/WAU/MAU, feature adoption, satisfaction, safety)
    /// - Parameter periodDays: Lookback period (default 30, max 365)
    func fetchProductHealth(periodDays: Int = 30) async throws -> ProductHealthResponse {
        let cacheKey = "product-health-\(periodDays)"
        if let cached: ProductHealthResponse = cached(cacheKey) { return cached }

        let body: [String: Any] = ["period": periodDays]

        let result: ProductHealthResponse = try await invokeFunction("product-health", body: body)
        store(result, forKey: cacheKey)
        return result
    }

    // MARK: - Private Helpers

    /// Invoke a Supabase edge function and decode the response
    private func invokeFunction<T: Decodable>(
        _ functionName: String,
        body: [String: Any]
    ) async throws -> T {
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        let responseData: Data = try await supabase.client.functions.invoke(
            functionName,
            options: FunctionInvokeOptions(body: bodyData)
        ) { data, _ in
            data
        }

        return try PTSupabaseClient.flexibleDecoder.decode(T.self, from: responseData)
    }
}
