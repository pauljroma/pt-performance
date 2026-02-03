import SwiftUI
import Combine

@MainActor
final class FastingViewModel: ObservableObject {
    @Published var currentFast: FastingLog?
    @Published var history: [FastingLog] = []
    @Published var stats: FastingStats?
    @Published var recommendation: EatingWindowRecommendation?
    @Published var isLoading = false
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
    }

    func startFast() async {
        do {
            try await service.startFast(type: selectedFastType)
            currentFast = service.currentFast
            showingStartSheet = false
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
}
