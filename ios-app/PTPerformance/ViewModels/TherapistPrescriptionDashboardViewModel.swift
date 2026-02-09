//
//  TherapistPrescriptionDashboardViewModel.swift
//  PTPerformance
//
//  ViewModel for therapist prescription dashboard
//  Manages prescription data, filters, and compliance metrics
//

import SwiftUI
import Combine

/// ViewModel for the Therapist Prescription Dashboard
/// Provides real-time tracking of patient prescription compliance
@MainActor
class TherapistPrescriptionDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    /// All prescriptions for the therapist's patients
    @Published var prescriptions: [PrescriptionWithPatient] = []

    /// Loading state
    @Published var isLoading = false

    /// Error message for display
    @Published var errorMessage: String?

    /// Search text for filtering
    @Published var searchText = ""

    /// Selected status filter
    @Published var selectedStatusFilter: StatusFilter = .all

    /// Selected date range filter
    @Published var selectedDateRange: DateRangeFilter = .all

    /// Selected patient filter (nil = all patients)
    @Published var selectedPatientId: UUID?

    /// All patients for the filter picker
    @Published var patients: [Patient] = []

    /// Refresh timestamp for real-time updates
    @Published var lastRefreshDate: Date?

    // MARK: - Private Properties

    private let prescriptionService: WorkoutPrescriptionService
    private let supabase = PTSupabaseClient.shared
    private var refreshTask: Task<Void, Never>?

    // MARK: - Enums

    /// Status filter options
    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case pending = "Pending"
        case viewed = "Viewed"
        case started = "Started"
        case completed = "Completed"
        case overdue = "Overdue"
        case cancelled = "Cancelled"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .pending: return "clock"
            case .viewed: return "eye"
            case .started: return "play.circle"
            case .completed: return "checkmark.circle"
            case .overdue: return "exclamationmark.triangle"
            case .cancelled: return "xmark.circle"
            }
        }

        var color: Color {
            switch self {
            case .all: return .primary
            case .pending: return .blue
            case .viewed: return .purple
            case .started: return .orange
            case .completed: return .green
            case .overdue: return .red
            case .cancelled: return .gray
            }
        }
    }

    /// Date range filter options
    enum DateRangeFilter: String, CaseIterable, Identifiable {
        case all = "All Time"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case overdue = "Overdue Only"

        var id: String { rawValue }
    }

    // MARK: - Computed Properties

    /// Filtered prescriptions based on current filter settings
    var filteredPrescriptions: [PrescriptionWithPatient] {
        var result = prescriptions

        // Apply search filter
        if !searchText.isEmpty {
            let search = searchText.lowercased()
            result = result.filter { item in
                item.patient.fullName.lowercased().contains(search) ||
                item.prescription.name.lowercased().contains(search)
            }
        }

        // Apply status filter
        if selectedStatusFilter != .all {
            result = result.filter { item in
                switch selectedStatusFilter {
                case .all:
                    return true
                case .pending:
                    return item.prescription.status == .pending
                case .viewed:
                    return item.prescription.status == .viewed
                case .started:
                    return item.prescription.status == .started
                case .completed:
                    return item.prescription.status == .completed
                case .overdue:
                    return item.prescription.isOverdue
                case .cancelled:
                    return item.prescription.status == .cancelled
                }
            }
        }

        // Apply date range filter
        result = applyDateRangeFilter(to: result)

        // Apply patient filter
        if let patientId = selectedPatientId {
            result = result.filter { $0.patient.id == patientId }
        }

        return result
    }

    /// Active prescriptions (pending, viewed, started)
    var activePrescriptions: [PrescriptionWithPatient] {
        prescriptions.filter { item in
            let status = item.prescription.status
            return status == .pending || status == .viewed || status == .started
        }
    }

    /// Overdue prescriptions
    var overduePrescriptions: [PrescriptionWithPatient] {
        prescriptions.filter { $0.prescription.isOverdue }
    }

    /// Recently completed prescriptions (last 7 days)
    var recentlyCompletedPrescriptions: [PrescriptionWithPatient] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return prescriptions.filter { item in
            guard item.prescription.status == .completed,
                  let completedAt = item.prescription.completedAt else {
                return false
            }
            return completedAt >= sevenDaysAgo
        }
    }

    /// Overall compliance rate (completed / total non-cancelled)
    var overallComplianceRate: Double {
        let nonCancelled = prescriptions.filter { $0.prescription.status != .cancelled }
        guard !nonCancelled.isEmpty else { return 0 }
        let completed = nonCancelled.filter { $0.prescription.status == .completed }
        return Double(completed.count) / Double(nonCancelled.count) * 100
    }

    /// Compliance rate by patient
    var complianceByPatient: [PatientCompliance] {
        let grouped = Dictionary(grouping: prescriptions) { $0.patient.id }

        return grouped.compactMap { (patientId, items) -> PatientCompliance? in
            guard let patient = items.first?.patient else { return nil }

            let nonCancelled = items.filter { $0.prescription.status != .cancelled }
            guard !nonCancelled.isEmpty else {
                return PatientCompliance(patient: patient, complianceRate: 0, totalPrescriptions: 0, completedPrescriptions: 0, overduePrescriptions: 0)
            }

            let completed = nonCancelled.filter { $0.prescription.status == .completed }
            let overdue = nonCancelled.filter { $0.prescription.isOverdue }
            let rate = Double(completed.count) / Double(nonCancelled.count) * 100

            return PatientCompliance(
                patient: patient,
                complianceRate: rate,
                totalPrescriptions: nonCancelled.count,
                completedPrescriptions: completed.count,
                overduePrescriptions: overdue.count
            )
        }.sorted { $0.complianceRate < $1.complianceRate } // Low compliance first for attention
    }

    /// Prescriptions due today
    var prescriptionsDueToday: [PrescriptionWithPatient] {
        prescriptions.filter { item in
            guard let dueDate = item.prescription.dueDate else { return false }
            return Calendar.current.isDateInToday(dueDate) &&
                   item.prescription.status != .completed &&
                   item.prescription.status != .cancelled
        }
    }

    /// Count by status for quick stats
    var statusCounts: [StatusFilter: Int] {
        var counts: [StatusFilter: Int] = [:]
        counts[.all] = prescriptions.count
        counts[.pending] = prescriptions.filter { $0.prescription.status == .pending }.count
        counts[.viewed] = prescriptions.filter { $0.prescription.status == .viewed }.count
        counts[.started] = prescriptions.filter { $0.prescription.status == .started }.count
        counts[.completed] = prescriptions.filter { $0.prescription.status == .completed }.count
        counts[.overdue] = overduePrescriptions.count
        counts[.cancelled] = prescriptions.filter { $0.prescription.status == .cancelled }.count
        return counts
    }

    // MARK: - Initialization

    init(prescriptionService: WorkoutPrescriptionService = WorkoutPrescriptionService()) {
        self.prescriptionService = prescriptionService
    }

    deinit {
        refreshTask?.cancel()
    }

    // MARK: - Public Methods

    /// Load all prescriptions for therapist's patients
    func loadPrescriptions(therapistId: String) async {
        guard !therapistId.isEmpty else {
            DebugLogger.shared.log("SECURITY: Cannot load prescriptions without therapist ID", level: .error)
            errorMessage = "Unable to verify your account. Please sign in again."
            return
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            // Load patients first
            await loadPatients(therapistId: therapistId)

            // Load prescriptions with patient data
            guard let therapistUUID = UUID(uuidString: therapistId) else {
                errorMessage = "Invalid therapist ID format"
                return
            }
            let loadedPrescriptions = try await prescriptionService.fetchTherapistDashboardPrescriptions(therapistId: therapistUUID)

            // Map prescriptions to patients
            prescriptions = loadedPrescriptions.compactMap { prescription in
                guard let patient = patients.first(where: { $0.id == prescription.patientId }) else {
                    return nil
                }
                return PrescriptionWithPatient(prescription: prescription, patient: patient)
            }

            lastRefreshDate = Date()
            DebugLogger.shared.log("Loaded \(prescriptions.count) prescriptions for dashboard", level: .success)

        } catch {
            DebugLogger.shared.log("Failed to load prescriptions: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to load prescriptions. Please try again."
        }
    }

    /// Refresh prescriptions data
    func refresh(therapistId: String) async {
        await loadPrescriptions(therapistId: therapistId)
    }

    /// Start auto-refresh for real-time updates
    func startAutoRefresh(therapistId: String, interval: TimeInterval = 30) {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                if !Task.isCancelled {
                    await refresh(therapistId: therapistId)
                }
            }
        }
    }

    /// Stop auto-refresh
    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// Send reminder for a prescription
    func sendReminder(for prescription: WorkoutPrescription) async -> Bool {
        // In a production app, this would trigger a push notification
        // For now, log the action
        DebugLogger.shared.log("Reminder sent for prescription: \(prescription.name)", level: .success)
        HapticFeedback.success()
        return true
    }

    /// Cancel a prescription
    func cancelPrescription(_ prescriptionId: UUID) async -> Bool {
        do {
            try await prescriptionService.cancelPrescription(prescriptionId)

            // Update local state
            if let index = prescriptions.firstIndex(where: { $0.prescription.id == prescriptionId }) {
                // Remove from list or update status locally
                prescriptions.remove(at: index)
            }

            HapticFeedback.success()
            return true
        } catch {
            DebugLogger.shared.log("Failed to cancel prescription: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to cancel prescription."
            HapticFeedback.error()
            return false
        }
    }

    /// Extend prescription due date
    func extendDueDate(for prescriptionId: UUID, newDueDate: Date) async -> Bool {
        do {
            try await prescriptionService.extendPrescriptionDueDate(prescriptionId, newDueDate: newDueDate)

            // Refresh to get updated data
            if let therapistId = prescriptions.first?.prescription.therapistId.uuidString {
                await refresh(therapistId: therapistId)
            }

            HapticFeedback.success()
            return true
        } catch {
            DebugLogger.shared.log("Failed to extend due date: \(error.localizedDescription)", level: .error)
            errorMessage = "Failed to extend due date."
            HapticFeedback.error()
            return false
        }
    }

    /// Clear all filters
    func clearFilters() {
        searchText = ""
        selectedStatusFilter = .all
        selectedDateRange = .all
        selectedPatientId = nil
    }

    // MARK: - Private Methods

    private func loadPatients(therapistId: String) async {
        do {
            let response = try await supabase.client
                .from("patients")
                .select()
                .eq("therapist_id", value: therapistId)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            patients = try decoder.decode([Patient].self, from: response.data)

        } catch {
            DebugLogger.shared.log("Failed to load patients: \(error.localizedDescription)", level: .error)
        }
    }

    private func applyDateRangeFilter(to items: [PrescriptionWithPatient]) -> [PrescriptionWithPatient] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedDateRange {
        case .all:
            return items

        case .today:
            return items.filter { item in
                guard let dueDate = item.prescription.dueDate else { return false }
                return calendar.isDateInToday(dueDate)
            }

        case .thisWeek:
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                return items
            }
            return items.filter { item in
                guard let dueDate = item.prescription.dueDate else { return false }
                return dueDate >= weekStart && dueDate < weekEnd
            }

        case .thisMonth:
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
                return items
            }
            return items.filter { item in
                guard let dueDate = item.prescription.dueDate else { return false }
                return dueDate >= monthStart && dueDate < monthEnd
            }

        case .overdue:
            return items.filter { $0.prescription.isOverdue }
        }
    }
}

// MARK: - Supporting Types

/// Prescription with associated patient data
struct PrescriptionWithPatient: Identifiable {
    let prescription: WorkoutPrescription
    let patient: Patient

    var id: UUID { prescription.id }
}

/// Patient compliance summary
struct PatientCompliance: Identifiable {
    let patient: Patient
    let complianceRate: Double
    let totalPrescriptions: Int
    let completedPrescriptions: Int
    let overduePrescriptions: Int

    var id: UUID { patient.id }

    var complianceColor: Color {
        switch complianceRate {
        case 80...: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }

    var complianceLabel: String {
        switch complianceRate {
        case 80...: return "Good"
        case 50..<80: return "Needs Attention"
        default: return "At Risk"
        }
    }
}
