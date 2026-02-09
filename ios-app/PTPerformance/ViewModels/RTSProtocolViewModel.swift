//
//  RTSProtocolViewModel.swift
//  PTPerformance
//
//  Main ViewModel for managing Return-to-Sport protocols.
//  Handles protocol lifecycle, phase management, clearances, and readiness tracking.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for the Return-to-Sport Protocol management
/// Provides comprehensive state management for RTS protocol workflows
@MainActor
class RTSProtocolViewModel: ObservableObject {

    // MARK: - Static Formatters
    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    // MARK: - Published Properties - Protocol Data

    /// All protocols for the current therapist or patient
    @Published var protocols: [RTSProtocol] = []

    /// Currently selected/active protocol
    @Published var currentProtocol: RTSProtocol?

    /// Phases for the current protocol
    @Published var phases: [RTSPhase] = []

    /// Currently active phase
    @Published var currentPhase: RTSPhase?

    /// Available sports for protocol creation
    @Published var sports: [RTSSport] = []

    /// Clearance documents for the current protocol
    @Published var clearances: [RTSClearance] = []

    /// Readiness scores for the current protocol
    @Published var readinessScores: [RTSReadinessScore] = []

    /// Most recent readiness score
    @Published var latestReadiness: RTSReadinessScore?

    /// Recent activity items for dashboard display
    @Published var recentActivity: [RTSActivityItem] = []

    // MARK: - Compatibility Aliases

    /// Alias for latestReadiness (used by some views)
    var latestReadinessScore: RTSReadinessScore? { latestReadiness }

    // MARK: - Published Properties - UI State

    /// Whether data is currently loading
    @Published var isLoading = false

    /// Whether a save operation is in progress
    @Published var isSaving = false

    /// Error message for display
    @Published var errorMessage: String?

    /// Success message for display
    @Published var successMessage: String?

    // MARK: - Published Properties - Protocol Creation Form

    /// Selected sport for new protocol
    @Published var selectedSport: RTSSport?

    /// Injury type description
    @Published var injuryType: String = ""

    /// Surgery date (optional)
    @Published var surgeryDate: Date?

    /// Date of injury
    @Published var injuryDate: Date = Date()

    /// Target return to sport date
    @Published var targetReturnDate: Date = Date()

    /// Additional notes for the protocol
    @Published var notes: String = ""

    // MARK: - Private Properties

    private let service = RTSService.shared
    private var cancellables = Set<AnyCancellable>()
    private var messageClearTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// Active phases (started but not completed)
    var activePhases: [RTSPhase] {
        phases.filter { $0.isActive }
    }

    /// Completed phases
    var completedPhases: [RTSPhase] {
        phases.filter { $0.isCompleted }
    }

    /// Pending phases (not yet started)
    var pendingPhases: [RTSPhase] {
        phases.filter { $0.isPending }
    }

    /// Overall protocol progress based on completed phases
    var overallProgress: Double {
        guard !phases.isEmpty else { return 0 }
        return Double(completedPhases.count) / Double(phases.count)
    }

    /// Current traffic light status based on latest readiness score
    var currentTrafficLight: RTSTrafficLight {
        latestReadiness?.trafficLight ?? .red
    }

    /// Whether the athlete can advance to the next phase
    /// Requires active phase and readiness score >= 80
    var canAdvancePhase: Bool {
        guard let current = currentPhase else { return false }
        return current.isActive && (latestReadiness?.overallScore ?? 0) >= 80
    }

    /// Whether the protocol creation form is valid
    var isFormValid: Bool {
        selectedSport != nil &&
        !injuryType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        targetReturnDate > injuryDate
    }

    /// Days until target return date for current protocol
    var daysUntilTarget: Int? {
        currentProtocol?.daysUntilTarget
    }

    /// Active protocols (not completed or discontinued)
    var activeProtocols: [RTSProtocol] {
        protocols.filter { $0.status == .active }
    }

    /// Draft protocols awaiting activation
    var draftProtocols: [RTSProtocol] {
        protocols.filter { $0.status == .draft }
    }

    /// Completed protocols
    var completedProtocols: [RTSProtocol] {
        protocols.filter { $0.status == .completed }
    }

    // MARK: - Initialization

    init() {
        #if DEBUG
        print("[RTSProtocolVM] Initialized")
        #endif
    }

    deinit {
        messageClearTask?.cancel()
    }

    // MARK: - Data Loading

    /// Load all available sports for protocol creation
    func loadSports() async {
        isLoading = true
        errorMessage = nil

        do {
            sports = try await service.fetchSports()

            #if DEBUG
            print("[RTSProtocolVM] Loaded \(sports.count) sports")
            #endif
        } catch {
            handleError(error, context: "loading sports")
        }

        isLoading = false
    }

    /// Load protocols for a specific therapist
    /// - Parameter therapistId: The therapist's UUID
    func loadProtocols(therapistId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            protocols = try await service.fetchProtocols(therapistId: therapistId)

            #if DEBUG
            print("[RTSProtocolVM] Loaded \(protocols.count) protocols for therapist")
            #endif
        } catch {
            handleError(error, context: "loading protocols")
        }

        isLoading = false
    }

    /// Load protocols for a specific patient
    /// - Parameter patientId: The patient's UUID
    func loadProtocolsForPatient(patientId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            protocols = try await service.fetchProtocolsForPatient(patientId: patientId)

            #if DEBUG
            print("[RTSProtocolVM] Loaded \(protocols.count) protocols for patient")
            #endif
        } catch {
            handleError(error, context: "loading patient protocols")
        }

        isLoading = false
    }

    /// Convenience method to load all data for a patient dashboard
    /// - Parameter patientId: The patient's UUID
    func loadData(patientId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch protocols for patient
            let fetchedProtocols = try await service.fetchProtocolsForPatient(patientId: patientId)
            protocols = fetchedProtocols

            // Get active protocol (first active one, or most recent)
            let activeProtocol = fetchedProtocols.first { $0.status == .active } ?? fetchedProtocols.first
            currentProtocol = activeProtocol

            guard let rtsProtocol = activeProtocol else {
                isLoading = false
                return
            }

            // Fetch phases
            phases = try await service.fetchPhases(protocolId: rtsProtocol.id)

            // Find current phase
            if let currentPhaseId = rtsProtocol.currentPhaseId {
                currentPhase = phases.first { $0.id == currentPhaseId }
            } else {
                currentPhase = phases.first { $0.isActive }
            }

            // Fetch latest readiness score
            latestReadiness = try await service.fetchLatestReadinessScore(protocolId: rtsProtocol.id)

            // Build recent activity
            await loadRecentActivity(protocolId: rtsProtocol.id)

            #if DEBUG
            print("[RTSProtocolVM] Loaded dashboard data for patient: \(patientId)")
            #endif
        } catch {
            handleError(error, context: "loading dashboard data")
        }

        isLoading = false
    }

    /// Load recent activity for the protocol
    private func loadRecentActivity(protocolId: UUID) async {
        var activities: [RTSActivityItem] = []

        // Add test results as activities
        if let testResults = try? await service.fetchTestResults(protocolId: protocolId) {
            for result in testResults.prefix(10) {
                activities.append(RTSActivityItem(
                    id: result.id,
                    title: result.passed ? "Test Passed" : "Test Recorded",
                    subtitle: "\(result.value) \(result.unit)",
                    icon: result.passed ? "checkmark.circle.fill" : "circle",
                    color: result.passed ? .green : .orange,
                    date: result.recordedAt
                ))
            }
        }

        // Add phase completions
        for phase in phases where phase.isCompleted {
            if let completedAt = phase.completedAt {
                activities.append(RTSActivityItem(
                    id: phase.id,
                    title: "Phase Completed",
                    subtitle: phase.phaseName,
                    icon: "flag.fill",
                    color: .green,
                    date: completedAt
                ))
            }
        }

        // Sort by date and take most recent
        recentActivity = activities.sorted { $0.date > $1.date }
    }

    /// Load full details for a specific protocol including phases, clearances, and readiness
    /// - Parameter protocolId: The protocol's UUID
    func loadProtocolDetails(protocolId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            currentProtocol = try await service.fetchProtocol(id: protocolId)

            // Load related data concurrently
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadPhases(protocolId: protocolId) }
                group.addTask { await self.loadClearances(protocolId: protocolId) }
                group.addTask { await self.loadReadinessScores(protocolId: protocolId) }
            }

            // Update current phase based on protocol's currentPhaseId
            if let phaseId = currentProtocol?.currentPhaseId {
                currentPhase = phases.first { $0.id == phaseId }
            } else {
                currentPhase = activePhases.first
            }

            #if DEBUG
            print("[RTSProtocolVM] Loaded protocol details: \(protocolId)")
            #endif
        } catch {
            handleError(error, context: "loading protocol details")
        }

        isLoading = false
    }

    /// Load phases for a protocol
    /// - Parameter protocolId: The protocol's UUID
    func loadPhases(protocolId: UUID) async {
        do {
            phases = try await service.fetchPhases(protocolId: protocolId)

            // Update current phase
            if let phaseId = currentProtocol?.currentPhaseId {
                currentPhase = phases.first { $0.id == phaseId }
            }

            #if DEBUG
            print("[RTSProtocolVM] Loaded \(phases.count) phases")
            #endif
        } catch {
            DebugLogger.shared.error("RTSProtocolViewModel", "Failed to load phases: \(error.localizedDescription)")
        }
    }

    /// Load clearances for a protocol
    /// - Parameter protocolId: The protocol's UUID
    func loadClearances(protocolId: UUID) async {
        do {
            clearances = try await service.fetchClearances(protocolId: protocolId)

            #if DEBUG
            print("[RTSProtocolVM] Loaded \(clearances.count) clearances")
            #endif
        } catch {
            DebugLogger.shared.error("RTSProtocolViewModel", "Failed to load clearances: \(error.localizedDescription)")
        }
    }

    /// Load readiness scores for a protocol
    /// - Parameter protocolId: The protocol's UUID
    func loadReadinessScores(protocolId: UUID) async {
        do {
            readinessScores = try await service.fetchReadinessScores(protocolId: protocolId)
            latestReadiness = readinessScores.first

            #if DEBUG
            print("[RTSProtocolVM] Loaded \(readinessScores.count) readiness scores")
            #endif
        } catch {
            DebugLogger.shared.error("RTSProtocolViewModel", "Failed to load readiness scores: \(error.localizedDescription)")
        }
    }

    // MARK: - Protocol Management

    /// Create a new RTS protocol
    /// - Parameters:
    ///   - patientId: The patient's UUID
    ///   - therapistId: The therapist's UUID
    /// - Returns: True if creation was successful
    func createProtocol(patientId: UUID, therapistId: UUID) async -> Bool {
        guard let sport = selectedSport else {
            errorMessage = "Please select a sport"
            return false
        }

        guard !injuryType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter an injury type"
            return false
        }

        guard targetReturnDate > injuryDate else {
            errorMessage = "Target return date must be after injury date"
            return false
        }

        isSaving = true
        errorMessage = nil

        do {
            let input = RTSProtocolInput(
                patientId: patientId.uuidString,
                therapistId: therapistId.uuidString,
                sportId: sport.id.uuidString,
                injuryType: injuryType.trimmingCharacters(in: .whitespacesAndNewlines),
                surgeryDate: surgeryDate.map { formatDate($0) },
                injuryDate: formatDate(injuryDate),
                targetReturnDate: formatDate(targetReturnDate),
                status: RTSProtocolStatus.draft.rawValue,
                notes: notes.isEmpty ? nil : notes
            )

            let newProtocol = try await service.createProtocol(input: input)

            // Create phases from sport template
            if !sport.defaultPhases.isEmpty {
                try await service.createPhasesFromTemplate(
                    protocolId: newProtocol.id,
                    templates: sport.defaultPhases
                )
            }

            // Add to local list and set as current
            protocols.insert(newProtocol, at: 0)
            currentProtocol = newProtocol

            // Load the created phases
            await loadPhases(protocolId: newProtocol.id)

            showSuccessMessage("Protocol created successfully")

            #if DEBUG
            print("[RTSProtocolVM] Created protocol: \(newProtocol.id)")
            #endif

            isSaving = false
            return true
        } catch {
            handleError(error, context: "creating protocol")
            isSaving = false
            return false
        }
    }

    /// Activate a draft protocol
    /// - Parameter protocolId: The protocol's UUID
    func activateProtocol(_ protocolId: UUID) async {
        isSaving = true
        errorMessage = nil

        do {
            try await service.updateProtocolStatus(id: protocolId, status: .active)

            // Update local state
            if let index = protocols.firstIndex(where: { $0.id == protocolId }) {
                protocols[index].status = .active
            }
            if currentProtocol?.id == protocolId {
                currentProtocol?.status = .active
            }

            // Start the first phase if not already started
            if let firstPhase = phases.first, firstPhase.isPending {
                await startPhase(firstPhase.id)
            }

            showSuccessMessage("Protocol activated")

            #if DEBUG
            print("[RTSProtocolVM] Activated protocol: \(protocolId)")
            #endif
        } catch {
            handleError(error, context: "activating protocol")
        }

        isSaving = false
    }

    /// Complete a protocol with the actual return date
    /// - Parameters:
    ///   - protocolId: The protocol's UUID
    ///   - returnDate: The actual date the athlete returned to sport
    func completeProtocol(_ protocolId: UUID, returnDate: Date) async {
        isSaving = true
        errorMessage = nil

        do {
            try await service.completeProtocol(id: protocolId, returnDate: returnDate)

            // Update local state
            if let index = protocols.firstIndex(where: { $0.id == protocolId }) {
                protocols[index].status = .completed
                protocols[index].actualReturnDate = returnDate
            }
            if currentProtocol?.id == protocolId {
                currentProtocol?.status = .completed
                currentProtocol?.actualReturnDate = returnDate
            }

            showSuccessMessage("Protocol completed - Athlete cleared for return to sport!")

            #if DEBUG
            print("[RTSProtocolVM] Completed protocol: \(protocolId)")
            #endif
        } catch {
            handleError(error, context: "completing protocol")
        }

        isSaving = false
    }

    /// Discontinue a protocol
    /// - Parameter protocolId: The protocol's UUID
    func discontinueProtocol(_ protocolId: UUID) async {
        isSaving = true
        errorMessage = nil

        do {
            try await service.updateProtocolStatus(id: protocolId, status: .discontinued)

            // Update local state
            if let index = protocols.firstIndex(where: { $0.id == protocolId }) {
                protocols[index].status = .discontinued
            }
            if currentProtocol?.id == protocolId {
                currentProtocol?.status = .discontinued
            }

            showSuccessMessage("Protocol discontinued")

            #if DEBUG
            print("[RTSProtocolVM] Discontinued protocol: \(protocolId)")
            #endif
        } catch {
            handleError(error, context: "discontinuing protocol")
        }

        isSaving = false
    }

    // MARK: - Phase Management

    /// Start a phase
    /// - Parameter phaseId: The phase's UUID
    func startPhase(_ phaseId: UUID) async {
        isSaving = true

        do {
            let updatedPhase = try await service.startPhase(id: phaseId)

            // Update local state
            if let index = phases.firstIndex(where: { $0.id == phaseId }) {
                phases[index] = updatedPhase
            }
            if currentPhase?.id == phaseId {
                currentPhase = updatedPhase
            }

            showSuccessMessage("Phase started: \(updatedPhase.phaseName)")

            #if DEBUG
            print("[RTSProtocolVM] Started phase: \(phaseId)")
            #endif
        } catch {
            handleError(error, context: "starting phase")
        }

        isSaving = false
    }

    /// Complete a phase
    /// - Parameter phaseId: The phase's UUID
    func completePhase(_ phaseId: UUID) async {
        isSaving = true

        do {
            let updatedPhase = try await service.completePhase(id: phaseId)

            // Update local state
            if let index = phases.firstIndex(where: { $0.id == phaseId }) {
                phases[index] = updatedPhase
            }
            if currentPhase?.id == phaseId {
                currentPhase = updatedPhase
            }

            showSuccessMessage("Phase completed: \(updatedPhase.phaseName)")

            #if DEBUG
            print("[RTSProtocolVM] Completed phase: \(phaseId)")
            #endif
        } catch {
            handleError(error, context: "completing phase")
        }

        isSaving = false
    }

    /// Advance to the next phase in the protocol
    /// - Parameters:
    ///   - reason: Reason for advancement decision
    ///   - criteriaSummary: Summary of criteria status at advancement
    func advanceToNextPhase(reason: String, criteriaSummary: RTSCriteriaSummary) async {
        guard let currentProtocol = currentProtocol,
              let currentPhase = currentPhase else {
            errorMessage = "No active protocol or phase"
            return
        }

        // Find the next phase
        let sortedPhases = phases.sorted { $0.phaseNumber < $1.phaseNumber }
        guard let currentIndex = sortedPhases.firstIndex(where: { $0.id == currentPhase.id }),
              currentIndex + 1 < sortedPhases.count else {
            errorMessage = "No next phase available"
            return
        }

        let nextPhase = sortedPhases[currentIndex + 1]

        isSaving = true
        errorMessage = nil

        do {
            // Record the advancement decision
            _ = try await service.recordAdvancement(
                protocolId: currentProtocol.id,
                fromPhaseId: currentPhase.id,
                toPhaseId: nextPhase.id,
                decision: .advance,
                reason: reason,
                criteriaSummary: criteriaSummary,
                decidedBy: currentProtocol.therapistId
            )

            // Complete current phase
            await completePhase(currentPhase.id)

            // Start next phase
            await startPhase(nextPhase.id)

            // Update current phase reference
            self.currentPhase = phases.first { $0.id == nextPhase.id }

            showSuccessMessage("Advanced to \(nextPhase.phaseName)")

            #if DEBUG
            print("[RTSProtocolVM] Advanced from phase \(currentPhase.phaseNumber) to \(nextPhase.phaseNumber)")
            #endif
        } catch {
            handleError(error, context: "advancing phase")
        }

        isSaving = false
    }

    // MARK: - Clearance Management

    /// Create a phase clearance document
    /// - Returns: The created clearance or nil if failed
    func createPhaseClearance() async -> RTSClearance? {
        guard let protocol_ = currentProtocol,
              let phase = currentPhase else {
            errorMessage = "No active protocol or phase"
            return nil
        }

        isSaving = true
        errorMessage = nil

        do {
            let input = RTSClearanceInput(
                protocolId: protocol_.id.uuidString,
                clearanceType: RTSClearanceType.phaseClearance.rawValue,
                clearanceLevel: currentTrafficLight.rawValue,
                status: RTSClearanceStatus.draft.rawValue,
                assessmentSummary: "Phase \(phase.phaseNumber) (\(phase.phaseName)) clearance assessment.",
                recommendations: "Continue with prescribed rehabilitation protocol.",
                requiresPhysicianSignature: false
            )

            let clearance = try await service.createClearance(input: input)
            clearances.insert(clearance, at: 0)

            showSuccessMessage("Phase clearance created")

            #if DEBUG
            print("[RTSProtocolVM] Created phase clearance: \(clearance.id)")
            #endif

            isSaving = false
            return clearance
        } catch {
            handleError(error, context: "creating phase clearance")
            isSaving = false
            return nil
        }
    }

    /// Create a final return-to-sport clearance document
    /// - Returns: The created clearance or nil if failed
    func createFinalClearance() async -> RTSClearance? {
        guard let protocol_ = currentProtocol else {
            errorMessage = "No active protocol"
            return nil
        }

        guard currentTrafficLight == .green else {
            errorMessage = "Readiness score must be in green zone for final clearance"
            return nil
        }

        isSaving = true
        errorMessage = nil

        do {
            let input = RTSClearanceInput(
                protocolId: protocol_.id.uuidString,
                clearanceType: RTSClearanceType.finalClearance.rawValue,
                clearanceLevel: RTSTrafficLight.green.rawValue,
                status: RTSClearanceStatus.draft.rawValue,
                assessmentSummary: "Final return-to-sport clearance assessment. All criteria met.",
                recommendations: "Full return to sport activities. Continue home exercise program for maintenance.",
                requiresPhysicianSignature: true
            )

            let clearance = try await service.createClearance(input: input)
            clearances.insert(clearance, at: 0)

            showSuccessMessage("Final clearance created - requires signatures")

            #if DEBUG
            print("[RTSProtocolVM] Created final clearance: \(clearance.id)")
            #endif

            isSaving = false
            return clearance
        } catch {
            handleError(error, context: "creating final clearance")
            isSaving = false
            return nil
        }
    }

    // MARK: - Helpers

    /// Reset the ViewModel to initial state
    func reset() {
        protocols = []
        currentProtocol = nil
        phases = []
        currentPhase = nil
        sports = []
        clearances = []
        readinessScores = []
        latestReadiness = nil
        resetForm()
        clearMessages()

        #if DEBUG
        print("[RTSProtocolVM] Reset complete")
        #endif
    }

    /// Reset the protocol creation form
    func resetForm() {
        selectedSport = nil
        injuryType = ""
        surgeryDate = nil
        injuryDate = Date()
        targetReturnDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
        notes = ""
    }

    /// Clear error and success messages
    func clearMessages() {
        messageClearTask?.cancel()
        errorMessage = nil
        successMessage = nil
    }

    // MARK: - Private Helpers

    /// Handle an error by logging and setting error message
    private func handleError(_ error: Error, context: String) {
        DebugLogger.shared.error("RTSProtocolViewModel", "\(context): \(error.localizedDescription)")
        errorMessage = error.localizedDescription
    }

    /// Show a success message that auto-clears after 3 seconds
    private func showSuccessMessage(_ message: String) {
        successMessage = message

        // Auto-clear after 3 seconds
        messageClearTask?.cancel()
        messageClearTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !Task.isCancelled {
                successMessage = nil
            }
        }
    }

    /// Format a date for API submission
    private func formatDate(_ date: Date) -> String {
        Self.apiDateFormatter.string(from: date)
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension RTSProtocolViewModel {
    /// Preview instance with sample data
    static var preview: RTSProtocolViewModel {
        let viewModel = RTSProtocolViewModel()
        viewModel.currentProtocol = RTSProtocol.sample
        viewModel.phases = [
            RTSPhase.completedSample,
            RTSPhase.activeSample,
            RTSPhase.pendingSample
        ]
        viewModel.currentPhase = RTSPhase.activeSample
        viewModel.sports = [RTSSport.baseballSample, RTSSport.soccerSample]
        viewModel.clearances = [RTSClearance.draftSample]
        viewModel.readinessScores = [RTSReadinessScore.yellowSample, RTSReadinessScore.greenSample]
        viewModel.latestReadiness = RTSReadinessScore.yellowSample
        return viewModel
    }

    /// Preview instance in loading state
    static var loadingPreview: RTSProtocolViewModel {
        let viewModel = RTSProtocolViewModel()
        viewModel.isLoading = true
        return viewModel
    }

    /// Preview instance with error state
    static var errorPreview: RTSProtocolViewModel {
        let viewModel = RTSProtocolViewModel()
        viewModel.errorMessage = "Failed to load protocol data. Please try again."
        return viewModel
    }
}
#endif
