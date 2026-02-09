import SwiftUI

/// ViewModel for supplement tracking, routine management, and compliance
@MainActor
final class SupplementViewModel: ObservableObject {

    // MARK: - Published State

    /// Supplement catalog (all available supplements)
    @Published var catalog: [CatalogSupplement] = []

    /// Pre-built supplement stacks
    @Published var stacks: [SupplementStack] = []

    /// User's active routines
    @Published var routines: [SupplementRoutine] = []

    /// Today's scheduled doses
    @Published var todayDoses: [TodaySupplementDose] = []

    /// Today's compliance data
    @Published var todayCompliance: SupplementCompliance?

    /// Weekly compliance data
    @Published var weeklyCompliance: WeeklySupplementCompliance?

    /// Overall analytics
    @Published var analytics: SupplementAnalytics?

    /// Legacy supplements support
    @Published var supplements: [Supplement] = []
    @Published var todaySchedule: [ScheduledSupplement] = []

    /// Loading states
    @Published var isLoading = false
    @Published var isLoadingCatalog = false
    @Published var error: String?

    /// Search and filter
    @Published var searchText: String = ""
    @Published var selectedCategory: SupplementCatalogCategory?
    @Published var selectedTiming: SupplementTiming?

    /// Sheet states
    @Published var showingAddSheet = false
    @Published var showingCatalogSheet = false
    @Published var showingStackSheet = false
    @Published var showingHistorySheet = false
    @Published var selectedSupplement: CatalogSupplement?
    @Published var selectedStack: SupplementStack?

    /// Add supplement form (legacy)
    @Published var newName: String = ""
    @Published var newBrand: String = ""
    @Published var newCategory: SupplementCategory = .vitamins
    @Published var newDosage: String = ""
    @Published var newFrequency: SupplementFrequency = .daily
    @Published var newTimeOfDay: Set<TimeOfDay> = [.morning]
    @Published var newWithFood: Bool = false
    @Published var newNotes: String = ""

    /// Add to routine form
    @Published var routineDosage: String = ""
    @Published var routineTiming: SupplementTiming = .morning
    @Published var routineFrequency: SupplementFrequency = .daily
    @Published var routineWithFood: Bool = false
    @Published var routineNotes: String = ""

    private let service = SupplementService.shared

    // MARK: - Initialization

    init() {
        // Subscribe to service updates
        observeService()
    }

    private func observeService() {
        // The service is @MainActor so we can safely observe it
        // In a real app, you might use Combine publishers here
    }

    // MARK: - Load Data

    /// Loads all supplement data
    func loadData() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        // Load routines (primary data)
        await service.fetchRoutines()

        // Sync state from service
        syncFromService()

        // Calculate today's compliance
        await service.calculateTodayCompliance()
        todayCompliance = service.todayCompliance

        if let serviceError = service.error {
            ErrorLogger.shared.logError(serviceError, context: "SupplementViewModel.loadData")
            error = "Unable to load your supplement data. Please try again."
        }
    }

    /// Loads the supplement catalog
    func loadCatalog() async {
        isLoadingCatalog = true
        await service.fetchCatalog()
        catalog = service.catalog
        isLoadingCatalog = false
    }

    /// Loads supplement stacks
    func loadStacks() async {
        await service.fetchStacks()
        stacks = service.stacks
    }

    /// Loads weekly compliance data
    func loadWeeklyCompliance() async {
        await service.fetchWeeklyCompliance()
        weeklyCompliance = service.weeklyCompliance
    }

    /// Loads analytics
    func loadAnalytics() async {
        await service.fetchAnalytics()
        analytics = service.analytics
    }

    /// Refreshes all data
    func refresh() async {
        await loadData()
        await loadWeeklyCompliance()
    }

    /// Syncs state from service
    private func syncFromService() {
        routines = service.routines
        todayDoses = service.todayDoses
        supplements = service.supplements
        todaySchedule = service.todaySchedule

        if let serviceError = service.error {
            error = serviceError.localizedDescription
        }
    }

    // MARK: - Today's Progress

    /// Number of supplements taken today
    var takenCount: Int {
        todayDoses.filter { $0.isTaken }.count
    }

    /// Total planned supplements for today
    var plannedCount: Int {
        todayDoses.count
    }

    /// Today's completion percentage
    var todayProgress: Double {
        guard plannedCount > 0 else { return 0 }
        return Double(takenCount) / Double(plannedCount)
    }

    /// Formatted progress string
    var progressText: String {
        "\(takenCount)/\(plannedCount)"
    }

    /// Whether all supplements have been taken today
    var isComplete: Bool {
        plannedCount > 0 && takenCount >= plannedCount
    }

    /// Doses that are still pending
    var pendingDoses: [TodaySupplementDose] {
        todayDoses.filter { !$0.isTaken }
    }

    /// Doses that have been taken
    var completedDoses: [TodaySupplementDose] {
        todayDoses.filter { $0.isTaken }
    }

    /// Overdue doses
    var overdueDoses: [TodaySupplementDose] {
        todayDoses.filter { $0.isOverdue }
    }

    // MARK: - Grouped Routine by Timing

    /// Today's doses grouped by timing
    var dosesByTiming: [(SupplementTiming, [TodaySupplementDose])] {
        let grouped = Dictionary(grouping: todayDoses, by: { $0.timing })
        return grouped.sorted { $0.key.sortOrder < $1.key.sortOrder }
    }

    /// Routines grouped by timing
    var routinesByTiming: [(SupplementTiming, [SupplementRoutine])] {
        let grouped = Dictionary(grouping: routines.filter { $0.isActive }, by: { $0.timing })
        return grouped.sorted { $0.key.sortOrder < $1.key.sortOrder }
    }

    /// Next dose to take
    var nextDose: TodaySupplementDose? {
        pendingDoses.first { !$0.isOverdue }
    }

    // MARK: - Filtered Supplements

    /// Catalog filtered by search and category
    var filteredCatalog: [CatalogSupplement] {
        var results = catalog

        // Filter by search text
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(searchLower) ||
                ($0.brand?.lowercased().contains(searchLower) ?? false) ||
                $0.benefits.contains { $0.lowercased().contains(searchLower) }
            }
        }

        // Filter by category
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }

        return results
    }

    /// Catalog grouped by category
    var catalogByCategory: [(SupplementCatalogCategory, [CatalogSupplement])] {
        let grouped = Dictionary(grouping: filteredCatalog, by: { $0.category })
        return grouped.sorted { $0.key.displayName < $1.key.displayName }
    }

    /// Stacks filtered by search
    var filteredStacks: [SupplementStack] {
        guard !searchText.isEmpty else { return stacks }
        let searchLower = searchText.lowercased()
        return stacks.filter {
            $0.name.lowercased().contains(searchLower) ||
            $0.description.lowercased().contains(searchLower)
        }
    }

    // MARK: - Legacy Computed Properties

    var pendingToday: [ScheduledSupplement] {
        todaySchedule.filter { !$0.taken }
    }

    var takenToday: [ScheduledSupplement] {
        todaySchedule.filter { $0.taken }
    }

    var completionRate: Double {
        guard !todaySchedule.isEmpty else { return 0 }
        return Double(takenToday.count) / Double(todaySchedule.count)
    }

    var supplementsByCategory: [(SupplementCategory, [Supplement])] {
        let grouped = Dictionary(grouping: supplements, by: { $0.category })
        return grouped.sorted { $0.key.displayName < $1.key.displayName }
    }

    // MARK: - Actions: Log Supplement

    /// Marks a dose as taken
    func logSupplement(_ dose: TodaySupplementDose) async {
        error = nil
        do {
            try await service.logSupplement(dose: dose)
            syncFromService()
            todayCompliance = service.todayCompliance
        } catch {
            ErrorLogger.shared.logError(error, context: "SupplementViewModel.logSupplement")
            self.error = "Unable to log your supplement. Please try again."
        }
    }

    /// Marks a dose as taken with additional data
    func logSupplement(
        _ dose: TodaySupplementDose,
        perceivedEffect: PerceivedEffect?,
        sideEffects: [String]?,
        notes: String?
    ) async {
        error = nil
        do {
            try await service.logSupplement(
                dose: dose,
                perceivedEffect: perceivedEffect,
                sideEffects: sideEffects,
                notes: notes
            )
            syncFromService()
            todayCompliance = service.todayCompliance
        } catch {
            ErrorLogger.shared.logError(error, context: "SupplementViewModel.logSupplement(withDetails)")
            self.error = "Unable to log your supplement. Please try again."
        }
    }

    /// Skips a dose
    func skipSupplement(_ dose: TodaySupplementDose, reason: String? = nil) async {
        error = nil
        do {
            try await service.skipSupplement(dose: dose, reason: reason)
            syncFromService()
            todayCompliance = service.todayCompliance
        } catch {
            ErrorLogger.shared.logError(error, context: "SupplementViewModel.skipSupplement")
            self.error = "Unable to skip this supplement. Please try again."
        }
    }

    /// Undoes a log entry
    func undoLog(_ logId: UUID) async {
        error = nil
        do {
            try await service.undoLog(logId)
            syncFromService()
            todayCompliance = service.todayCompliance
        } catch {
            ErrorLogger.shared.logError(error, context: "SupplementViewModel.undoLog")
            self.error = "Unable to undo the log. Please try again."
        }
    }

    /// Marks a legacy scheduled supplement as taken
    func markTaken(_ scheduled: ScheduledSupplement) async {
        error = nil
        do {
            try await service.logSupplementTaken(scheduled.supplement)
            await loadData()
        } catch {
            ErrorLogger.shared.logError(error, context: "SupplementViewModel.markTaken")
            self.error = "Unable to mark this supplement as taken. Please try again."
        }
    }

    // MARK: - Actions: Routine Management

    /// Adds a supplement from catalog to routine
    func addToRoutine(_ supplement: CatalogSupplement) async {
        error = nil
        do {
            try await service.addToRoutine(
                supplementId: supplement.id,
                supplementName: supplement.name,
                brand: supplement.brand,
                category: supplement.category,
                dosage: routineDosage.isEmpty ? supplement.dosageRange : routineDosage,
                timing: routineTiming,
                frequency: routineFrequency,
                withFood: routineWithFood,
                notes: routineNotes.isEmpty ? nil : routineNotes
            )
            resetRoutineForm()
            showingCatalogSheet = false
            await loadData()
        } catch {
            ErrorLogger.shared.logError(error, context: "SupplementViewModel.addToRoutine")
            self.error = "Unable to add supplement to routine. Please try again."
        }
    }

    /// Adds a stack to routine
    func addStackToRoutine(_ stack: SupplementStack) async {
        error = nil
        do {
            try await service.addStackToRoutine(stack)
            showingStackSheet = false
            await loadData()
        } catch {
            ErrorLogger.shared.logError(error, context: "SupplementViewModel.addStackToRoutine")
            self.error = "Unable to add supplement stack. Please try again."
        }
    }

    /// Removes a routine item
    func removeFromRoutine(_ routineId: UUID) async {
        error = nil
        do {
            try await service.removeFromRoutine(routineId)
            await loadData()
        } catch {
            ErrorLogger.shared.logError(error, context: "SupplementViewModel.removeFromRoutine")
            self.error = "Unable to remove supplement from routine. Please try again."
        }
    }

    /// Updates a routine item
    func updateRoutine(
        _ routineId: UUID,
        dosage: String? = nil,
        timing: SupplementTiming? = nil,
        frequency: SupplementFrequency? = nil,
        withFood: Bool? = nil,
        notes: String? = nil
    ) async {
        error = nil
        do {
            try await service.updateRoutine(
                routineId,
                dosage: dosage,
                timing: timing,
                frequency: frequency,
                withFood: withFood,
                notes: notes
            )
            await loadData()
        } catch {
            ErrorLogger.shared.logError(error, context: "SupplementViewModel.updateRoutine")
            self.error = "Unable to update supplement routine. Please try again."
        }
    }

    // MARK: - Actions: Legacy Add Supplement

    /// Adds a supplement using the legacy model
    func addSupplement() async {
        guard !newName.isEmpty, !newDosage.isEmpty else {
            error = "Name and dosage are required"
            return
        }

        guard let patientId = await getPatientId() else {
            error = "Unable to get patient ID"
            return
        }

        let supplement = Supplement(
            id: UUID(),
            patientId: patientId,
            name: newName,
            brand: newBrand.isEmpty ? nil : newBrand,
            category: newCategory,
            dosage: newDosage,
            frequency: newFrequency,
            timeOfDay: Array(newTimeOfDay),
            withFood: newWithFood,
            notes: newNotes.isEmpty ? nil : newNotes,
            momentousProductId: nil,
            isActive: true,
            createdAt: Date()
        )

        do {
            try await service.addSupplement(supplement)
            resetForm()
            showingAddSheet = false
            await loadData()
        } catch {
            ErrorLogger.shared.logError(error, context: "SupplementViewModel.addSupplement")
            self.error = "Unable to add supplement. Please try again."
        }
    }

    /// Deletes a legacy supplement
    func deleteSupplement(_ supplement: Supplement) async {
        error = nil
        do {
            try await service.deleteSupplement(supplement.id)
            await loadData()
        } catch {
            ErrorLogger.shared.logError(error, context: "SupplementViewModel.deleteSupplement")
            self.error = "Unable to delete supplement. Please try again."
        }
    }

    // MARK: - Form Helpers

    private func resetForm() {
        newName = ""
        newBrand = ""
        newCategory = .vitamins
        newDosage = ""
        newFrequency = .daily
        newTimeOfDay = [.morning]
        newWithFood = false
        newNotes = ""
    }

    private func resetRoutineForm() {
        routineDosage = ""
        routineTiming = .morning
        routineFrequency = .daily
        routineWithFood = false
        routineNotes = ""
        selectedSupplement = nil
    }

    /// Clears search and filter
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedTiming = nil
    }

    /// Prepares to add a supplement from catalog
    func prepareAddFromCatalog(_ supplement: CatalogSupplement) {
        selectedSupplement = supplement
        routineDosage = supplement.dosageRange
        routineTiming = supplement.timing.first ?? .morning
        routineWithFood = supplement.timing.contains(.withMeal)
    }

    // MARK: - Patient ID Helper

    private func getPatientId() async -> UUID? {
        guard let userId = PTSupabaseClient.shared.client.auth.currentUser?.id else {
            // Return demo patient ID
            return UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        }

        struct PatientRow: Decodable {
            let id: UUID
        }

        do {
            let patients: [PatientRow] = try await PTSupabaseClient.shared.client
                .from("patients")
                .select("id")
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value
            return patients.first?.id ?? UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        } catch {
            return UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        }
    }

    // MARK: - Summary Stats

    /// Current streak days
    var currentStreak: Int {
        todayCompliance?.streakDays ?? analytics?.currentStreak ?? 0
    }

    /// Weekly compliance rate
    var weeklyComplianceRate: Double {
        weeklyCompliance?.averageComplianceRate ?? analytics?.weeklyComplianceRate ?? 0
    }

    /// Formatted weekly compliance
    var formattedWeeklyCompliance: String {
        "\(Int(weeklyComplianceRate * 100))%"
    }

    /// Total active supplements in routine
    var activeSupplementCount: Int {
        routines.filter { $0.isActive }.count
    }

    /// Categories in user's routine
    var routineCategories: [SupplementCatalogCategory] {
        let categories = routines.compactMap { $0.supplement?.category }
        return Array(Set(categories)).sorted { $0.displayName < $1.displayName }
    }

    // MARK: - Quick Actions

    /// Marks all pending doses as taken
    func markAllPendingAsTaken() async {
        for dose in pendingDoses {
            await logSupplement(dose)
        }
    }

    /// Gets dose for a specific routine
    func dose(for routineId: UUID) -> TodaySupplementDose? {
        todayDoses.first { $0.routineId == routineId }
    }

    /// Gets routine for a specific dose
    func routine(for dose: TodaySupplementDose) -> SupplementRoutine? {
        routines.first { $0.id == dose.routineId }
    }
}

// MARK: - Preview Support

extension SupplementViewModel {
    static var preview: SupplementViewModel {
        let viewModel = SupplementViewModel()
        viewModel.catalog = CatalogSupplement.demoSupplements
        viewModel.stacks = SupplementStack.demoStacks
        viewModel.routines = SupplementRoutine.demoRoutines

        // Generate demo today doses
        let calendar = Calendar.current
        let today = Date()
        viewModel.todayDoses = [
            TodaySupplementDose(
                id: UUID(),
                routineId: UUID(),
                supplementId: UUID(),
                supplementName: "Creatine Monohydrate",
                brand: "Momentous",
                category: .performance,
                dosage: "5g",
                timing: .postWorkout,
                scheduledTime: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today) ?? today,
                withFood: false,
                isTaken: true,
                takenAt: Date(),
                logId: UUID()
            ),
            TodaySupplementDose(
                id: UUID(),
                routineId: UUID(),
                supplementId: UUID(),
                supplementName: "Vitamin D3",
                brand: nil,
                category: .vitamin,
                dosage: "5000 IU",
                timing: .morning,
                scheduledTime: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: today) ?? today,
                withFood: true,
                isTaken: true,
                takenAt: Date(),
                logId: UUID()
            ),
            TodaySupplementDose(
                id: UUID(),
                routineId: UUID(),
                supplementId: UUID(),
                supplementName: "Omega-3 Fish Oil",
                brand: "Momentous",
                category: .health,
                dosage: "3g",
                timing: .withMeal,
                scheduledTime: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today) ?? today,
                withFood: true,
                isTaken: false,
                takenAt: nil,
                logId: nil
            ),
            TodaySupplementDose(
                id: UUID(),
                routineId: UUID(),
                supplementId: UUID(),
                supplementName: "Magnesium Glycinate",
                brand: nil,
                category: .mineral,
                dosage: "300mg",
                timing: .beforeBed,
                scheduledTime: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: today) ?? today,
                withFood: false,
                isTaken: false,
                takenAt: nil,
                logId: nil
            )
        ]

        viewModel.todayCompliance = SupplementCompliance(
            id: UUID(),
            patientId: UUID(),
            date: Date(),
            plannedCount: 4,
            takenCount: 2,
            skippedCount: 0,
            complianceRate: 0.5,
            streakDays: 5
        )

        return viewModel
    }
}
