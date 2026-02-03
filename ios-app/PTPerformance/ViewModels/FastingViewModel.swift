import SwiftUI
import Combine

@MainActor
final class FastingViewModel: ObservableObject {
    @Published var currentFast: FastingLog?
    @Published var history: [FastingLog] = []
    @Published var stats: FastingStats?
    @Published var recommendation: EatingWindowRecommendation?
    @Published var workoutRecommendation: FastingWorkoutRecommendation?
    @Published var isLoading = false
    @Published var isLoadingWorkoutRec = false
    @Published var error: String?

    // Start fast form
    @Published var selectedFastType: FastingType = .intermittent16_8
    @Published var showingStartSheet = false

    // End fast form
    @Published var showingEndSheet = false
    @Published var breakfastFood: String = ""
    @Published var energyLevel: Int = 5
    @Published var endNotes: String = ""

    private let service = FastingService.shared
    private var timerCancellable: AnyCancellable?
    private var fastingStateObserver: AnyCancellable?

    init() {
        // Update current fast progress every minute
        timerCancellable = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }

    func loadData() async {
        isLoading = true
        error = nil
        await service.fetchFastingData()
        currentFast = service.currentFast
        history = service.fastingHistory
        stats = service.stats
        recommendation = service.eatingWindowRecommendation
        if let serviceError = service.error {
            error = serviceError.localizedDescription
        }
        isLoading = false

        // Automatically fetch workout recommendation when fasting state is loaded
        await fetchWorkoutRecommendation()
    }

    /// Fetch workout recommendation based on current fasting state
    func fetchWorkoutRecommendation() async {
        isLoadingWorkoutRec = true
        await service.generateLocalWorkoutRecommendation()
        workoutRecommendation = service.workoutRecommendation
        isLoadingWorkoutRec = false
    }

    /// Fetch workout recommendation for a specific workout (calls edge function)
    func fetchWorkoutRecommendation(for workoutId: UUID) async {
        isLoadingWorkoutRec = true
        await service.getWorkoutRecommendation(workoutId: workoutId)
        workoutRecommendation = service.workoutRecommendation
        isLoadingWorkoutRec = false
    }

    func startFast() async {
        do {
            try await service.startFast(type: selectedFastType)
            currentFast = service.currentFast
            showingStartSheet = false
            // Refresh workout recommendation when fast starts
            await fetchWorkoutRecommendation()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func endFast() async {
        do {
            try await service.endFast(
                breakfastFood: breakfastFood.isEmpty ? nil : breakfastFood,
                energyLevel: energyLevel,
                notes: endNotes.isEmpty ? nil : endNotes
            )
            currentFast = nil
            showingEndSheet = false
            await loadData()
            resetEndForm()
            // Refresh workout recommendation when fast ends
            await fetchWorkoutRecommendation()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func generateRecommendation(trainingTime: Date?) async {
        await service.generateEatingWindowRecommendation(trainingTime: trainingTime)
        recommendation = service.eatingWindowRecommendation
    }

    private func resetEndForm() {
        breakfastFood = ""
        energyLevel = 5
        endNotes = ""
    }

    // MARK: - Computed Properties

    var isFasting: Bool {
        currentFast != nil
    }

    var currentProgress: Double {
        currentFast?.progressPercent ?? 0
    }

    var elapsedHours: Double {
        guard let fast = currentFast else { return 0 }
        return Date().timeIntervalSince(fast.startTime) / 3600
    }

    var remainingHours: Double {
        guard let fast = currentFast else { return 0 }
        return max(0, Double(fast.targetHours) - elapsedHours)
    }

    var completedFasts: [FastingLog] {
        history.filter { $0.endTime != nil }
    }

    var completionRate: Double {
        guard !history.isEmpty else { return 0 }
        let completed = history.filter { $0.endTime != nil && ($0.actualHours ?? 0) >= Double($0.targetHours) * 0.9 }
        return Double(completed.count) / Double(history.count)
    }

    // MARK: - Workout Recommendation Computed Properties

    /// Whether the current fast is extended (16+ hours)
    var isExtendedFast: Bool {
        workoutRecommendation?.isExtendedFast ?? false
    }

    /// Current intensity modifier as percentage
    var intensityPercentage: Int {
        workoutRecommendation?.intensityPercentage ?? 100
    }

    /// Whether workout is recommended in current fasting state
    var isWorkoutRecommended: Bool {
        workoutRecommendation?.workoutRecommended ?? true
    }

    /// Safety warnings count
    var warningsCount: Int {
        workoutRecommendation?.safetyWarnings.count ?? 0
    }
}
