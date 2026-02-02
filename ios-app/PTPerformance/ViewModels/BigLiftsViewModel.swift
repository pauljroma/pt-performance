import Foundation
import SwiftUI

/// ViewModel for the Big Lifts Scorecard
/// Handles data fetching, loading states, and refresh capability
@MainActor
class BigLiftsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var bigLifts: [BigLiftSummary] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?

    // MARK: - Computed Properties

    /// Whether the data is empty (no big lifts found)
    var isEmpty: Bool {
        bigLifts.isEmpty && !isLoading
    }

    /// Total PRs across all big lifts
    var totalPRCount: Int {
        bigLifts.reduce(0) { $0 + $1.prCount }
    }

    /// Number of lifts that have improved in the last 30 days
    var improvingCount: Int {
        bigLifts.filter { $0.isImproving }.count
    }

    /// Average improvement percentage across all lifts
    var averageImprovement: Double? {
        let improvements = bigLifts.compactMap { $0.improvementPct30d }
        guard !improvements.isEmpty else { return nil }
        return improvements.reduce(0, +) / Double(improvements.count)
    }

    /// Estimated total (sum of estimated 1RMs for core lifts: SBD)
    var estimatedTotal: Double {
        let coreNames = [
            BigLift.benchPress.rawValue,
            BigLift.squat.rawValue,
            BigLift.deadlift.rawValue
        ]
        return bigLifts
            .filter { coreNames.contains($0.exerciseName) }
            .reduce(0) { $0 + $1.estimated1rm }
    }

    // MARK: - Dependencies

    private let service: BigLiftsService
    private var cachedPatientId: UUID?

    // MARK: - Initialization

    init(service: BigLiftsService = .shared) {
        self.service = service
    }

    // MARK: - Data Fetching

    /// Fetch big lifts data for the given patient
    /// - Parameter patientId: The patient's UUID
    func fetchData(for patientId: UUID) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        cachedPatientId = patientId

        do {
            let summaries = try await service.fetchBigLiftsSummary(patientId: patientId)
            bigLifts = summaries
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            #if DEBUG
            print("BigLiftsViewModel: Error fetching data: \(error)")
            #endif
        }
    }

    /// Refresh the data (pull-to-refresh)
    /// - Parameter patientId: The patient's UUID
    func refresh(for patientId: UUID) async {
        guard !isRefreshing else { return }

        isRefreshing = true
        errorMessage = nil

        do {
            let summaries = try await service.fetchBigLiftsSummary(patientId: patientId)
            bigLifts = summaries
            isRefreshing = false
        } catch {
            errorMessage = error.localizedDescription
            isRefreshing = false
        }
    }

    /// Refresh using cached patient ID (for retry after error)
    func retryFetch() async {
        guard let patientId = cachedPatientId else { return }
        await fetchData(for: patientId)
    }

    // MARK: - Helpers

    /// Get the icon name for a lift
    func iconName(for exerciseName: String) -> String {
        if let lift = BigLift.allCases.first(where: { $0.rawValue == exerciseName }) {
            return lift.iconName
        }
        // Default icon for unrecognized exercises
        return "dumbbell.fill"
    }

    /// Check if an exercise is a core lift (SBD)
    func isCoreLift(_ exerciseName: String) -> Bool {
        let coreNames = [
            BigLift.benchPress.rawValue,
            BigLift.squat.rawValue,
            BigLift.deadlift.rawValue
        ]
        return coreNames.contains(exerciseName)
    }
}
