import SwiftUI
import Combine

/// ViewModel for the FastingTrackerView (ACP-1001)
/// Manages current fasting state, timer, protocol selection, and UI state
@MainActor
final class FastingTrackerViewModel: ObservableObject {
    // MARK: - Published Properties

    // Fasting state
    @Published var currentFast: FastingLog?
    @Published var fastingHistory: [FastingLog] = []
    @Published var stats: FastingStats?

    // Protocol selection
    @Published var selectedProtocol: FastingProtocolType = .sixteen8
    @Published var customFastingHours: Int = 16

    // Timer state
    @Published private(set) var elapsedSeconds: TimeInterval = 0
    @Published private(set) var targetSeconds: TimeInterval = 0

    // UI state
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Private Properties

    private let service = FastingTrackerService.shared
    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupTimerUpdates()
        setupServiceBindings()
    }

    private func setupTimerUpdates() {
        // Update every second when fasting is active
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimerState()
            }
    }

    private func setupServiceBindings() {
        // Observe service changes
        service.$currentFast
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentFast)

        service.$fastingHistory
            .receive(on: DispatchQueue.main)
            .assign(to: &$fastingHistory)

        service.$stats
            .receive(on: DispatchQueue.main)
            .assign(to: &$stats)

        service.$currentProtocol
            .receive(on: DispatchQueue.main)
            .assign(to: &$selectedProtocol)

        service.$customFastingHours
            .receive(on: DispatchQueue.main)
            .assign(to: &$customFastingHours)

        service.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
    }

    private func updateTimerState() {
        guard let fast = currentFast else {
            elapsedSeconds = 0
            targetSeconds = 0
            return
        }

        elapsedSeconds = Date().timeIntervalSince(fast.startedAt)
        targetSeconds = Double(fast.targetHours) * 3600
    }

    // MARK: - Public Methods

    func loadData() async {
        await service.fetchFastingData()
        updateTimerState()
    }

    func startFast() async {
        error = nil
        do {
            service.setProtocol(selectedProtocol, customHours: customFastingHours)
            try await service.startFast()
            updateTimerState()
        } catch {
            ErrorLogger.shared.logError(error, context: "FastingTrackerViewModel.startFast")
            self.error = "Unable to start your fast. Please try again."
        }
    }

    func endFast(energyLevel: Int, notes: String?, moodEnd: Int? = nil, hungerLevel: Int? = nil) async {
        error = nil
        do {
            try await service.endFast(
                energyLevel: energyLevel,
                notes: notes,
                moodEnd: moodEnd,
                hungerLevel: hungerLevel
            )
        } catch {
            ErrorLogger.shared.logError(error, context: "FastingTrackerViewModel.endFast")
            self.error = "Unable to end your fast. Please try again."
        }
    }

    func cancelFast() async {
        error = nil
        do {
            try await service.cancelFast()
        } catch {
            ErrorLogger.shared.logError(error, context: "FastingTrackerViewModel.cancelFast")
            self.error = "Unable to cancel your fast. Please try again."
        }
    }

    // MARK: - Computed Properties

    var isFasting: Bool {
        currentFast != nil
    }

    var fastStartTime: Date? {
        currentFast?.startedAt
    }

    var currentProtocol: FastingProtocolType? {
        guard currentFast != nil else { return selectedProtocol }
        return selectedProtocol
    }

    var currentPhase: FastingPhase {
        FastingPhase.fromHours(elapsedSeconds / 3600)
    }

    var remainingSeconds: TimeInterval {
        max(0, targetSeconds - elapsedSeconds)
    }

    var formattedElapsedTime: String {
        formatDuration(elapsedSeconds)
    }

    var formattedRemainingTime: String {
        if remainingSeconds <= 0 {
            return "Goal reached!"
        }
        return formatDuration(remainingSeconds)
    }

    var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        return min(elapsedSeconds / targetSeconds, 1.0)
    }

    // Streak properties
    var currentStreak: Int {
        service.currentStreak
    }

    var bestStreak: Int {
        service.bestStreak
    }

    // Weekly stats
    var weeklyCompletedFasts: Int {
        service.weeklyStats().completed
    }

    var weeklyAverageHours: Double {
        service.weeklyStats().average
    }

    var weeklyCompliance: Double {
        service.weeklyStats().compliance
    }

    // MARK: - Private Helpers

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, secs)
        } else {
            return String(format: "%ds", secs)
        }
    }
}
