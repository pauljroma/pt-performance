//
//  TrainingOutcomesDashboardViewModel.swift
//  PTPerformance
//
//  ViewModel for the Training Outcomes Dashboard
//  Loads aggregate program effectiveness and per-patient training outcomes
//

import Foundation

// MARK: - Training Outcomes Dashboard ViewModel

@MainActor
final class TrainingOutcomesDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var outcomes: TrainingOutcomeData?
    @Published var summary: TrainingOutcomeSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedPatientId: String?

    // MARK: - Private Properties

    private let service = EdgeFunctionAnalyticsService.shared

    // MARK: - Public Methods

    /// Load aggregate program effectiveness data (all patients)
    func loadAggregate() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await service.fetchProgramEffectiveness()
            outcomes = response.data
            summary = response.summary
        } catch {
            errorMessage = error.localizedDescription
            ErrorLogger.shared.logError(error, context: "TrainingOutcomesDashboardViewModel.loadAggregate")
        }

        isLoading = false
    }

    /// Load training outcomes for a specific patient
    /// - Parameter patientId: The patient UUID string
    func loadForPatient(_ patientId: String) async {
        isLoading = true
        errorMessage = nil
        selectedPatientId = patientId

        do {
            let response = try await service.fetchTrainingOutcomes(patientId: patientId)
            outcomes = response.data
            summary = response.summary
        } catch {
            errorMessage = error.localizedDescription
            ErrorLogger.shared.logError(error, context: "TrainingOutcomesDashboardViewModel.loadForPatient")
        }

        isLoading = false
    }

    // MARK: - Computed Helpers

    /// Strength gains sorted by percentage change (biggest gain first)
    var sortedStrengthGains: [StrengthGain] {
        (outcomes?.strengthGains ?? []).sorted { ($0.pctChange ?? 0) > ($1.pctChange ?? 0) }
    }

    /// Volume progression data for charting
    var volumeProgression: [WeeklyVolume] {
        outcomes?.volumeProgression ?? []
    }

    /// Pain trend data for charting
    var painTrend: [WeeklyPain] {
        outcomes?.painTrend ?? []
    }

    /// Adherence data for charting
    var adherenceData: [EFWeeklyAdherence] {
        outcomes?.adherence ?? []
    }
}
