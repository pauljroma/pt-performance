//
//  ShoulderHealthDashboardViewModel.swift
//  PTPerformance
//
//  ACP-545: Shoulder Health Dashboard ViewModel
//  Manages state and data loading for the shoulder health dashboard
//

import Foundation
import SwiftUI

@MainActor
class ShoulderHealthDashboardViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?

    @Published var healthStatus: ShoulderHealthStatus?
    @Published var alerts: [ShoulderAlert] = []
    @Published var recentROMMeasurements: [ShoulderROMMeasurement] = []
    @Published var recentStrengthMeasurements: [ShoulderStrengthMeasurement] = []
    @Published var trendData: ShoulderTrendData = .empty

    @Published var asymmetryData: (romDifference: Double?, strengthDifference: Double?)?

    // MARK: - Private Properties

    private let service = ShoulderHealthService.shared
    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    // MARK: - Computed Properties

    var hasTrendData: Bool {
        !trendData.romTrends.isEmpty || !trendData.ratioTrends.isEmpty
    }

    var patientId: String? {
        supabase.userId
    }

    // MARK: - Public Methods

    /// Load all dashboard data for the specified side
    func loadDashboard(side: ShoulderSide) async {
        guard let patientId = patientId else {
            logger.error("SHOULDER DASHBOARD", "No patient ID available")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Load health status
            healthStatus = try await service.calculateHealthStatus(
                patientId: patientId,
                side: side
            )

            // Load alerts
            alerts = try await service.fetchAlerts(patientId: patientId)

            // Load recent measurements
            recentROMMeasurements = try await service.fetchROMMeasurements(
                patientId: patientId,
                side: side,
                limit: 5
            )

            recentStrengthMeasurements = try await service.fetchStrengthMeasurements(
                patientId: patientId,
                side: side,
                limit: 5
            )

            // Load trend data
            trendData = try await service.fetchTrendData(patientId: patientId)

            // Load asymmetry data
            asymmetryData = try await service.calculateAsymmetry(patientId: patientId)

            logger.success("SHOULDER DASHBOARD", "Loaded dashboard data successfully")
        } catch {
            logger.error("SHOULDER DASHBOARD", "Error loading dashboard: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// Refresh dashboard data
    func refresh(side: ShoulderSide) async {
        await loadDashboard(side: side)
    }

    /// Clear error state
    func clearError() {
        showError = false
        errorMessage = nil
    }
}
