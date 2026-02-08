import SwiftUI
import Combine

// MARK: - Fasting Zone

/// Enhanced fasting zones for timeline visualization
enum FastingZone: String, CaseIterable {
    case fed = "fed"
    case burningSugar = "burning_sugar"
    case fatBurning = "fat_burning"
    case ketosis = "ketosis"
    case deepKetosis = "deep_ketosis"
    case autophagy = "autophagy"

    var displayName: String {
        switch self {
        case .fed: return "Fed"
        case .burningSugar: return "Burning Sugar"
        case .fatBurning: return "Fat Burning"
        case .ketosis: return "Ketosis"
        case .deepKetosis: return "Deep Ketosis"
        case .autophagy: return "Autophagy"
        }
    }

    var shortName: String {
        switch self {
        case .fed: return "Fed"
        case .burningSugar: return "Sugar"
        case .fatBurning: return "Fat"
        case .ketosis: return "Ketosis"
        case .deepKetosis: return "Deep"
        case .autophagy: return "Autophagy"
        }
    }

    var description: String {
        switch self {
        case .fed: return "Digesting recent meal"
        case .burningSugar: return "Using glucose for energy"
        case .fatBurning: return "Switching to fat for fuel"
        case .ketosis: return "Producing ketones"
        case .deepKetosis: return "Enhanced ketone production"
        case .autophagy: return "Cellular cleanup active"
        }
    }

    var icon: String {
        switch self {
        case .fed: return "fork.knife"
        case .burningSugar: return "bolt.fill"
        case .fatBurning: return "flame.fill"
        case .ketosis: return "brain.head.profile"
        case .deepKetosis: return "sparkles"
        case .autophagy: return "arrow.triangle.2.circlepath"
        }
    }

    var color: Color {
        switch self {
        case .fed: return .orange
        case .burningSugar: return .yellow
        case .fatBurning: return .orange
        case .ketosis: return .purple
        case .deepKetosis: return .blue
        case .autophagy: return .purple
        }
    }

    /// Start hour for this zone
    var startHour: Double {
        switch self {
        case .fed: return 0
        case .burningSugar: return 0
        case .fatBurning: return 4
        case .ketosis: return 12
        case .deepKetosis: return 18
        case .autophagy: return 48
        }
    }

    /// Hour marker for timeline display
    var hourMarker: Int {
        switch self {
        case .fed: return 0
        case .burningSugar: return 4
        case .fatBurning: return 12
        case .ketosis: return 18
        case .deepKetosis: return 24
        case .autophagy: return 48
        }
    }

    /// Determine zone from hours fasted
    static func fromHours(_ hours: Double) -> FastingZone {
        switch hours {
        case ..<4: return .burningSugar
        case 4..<12: return .fatBurning
        case 12..<18: return .ketosis
        case 18..<48: return .deepKetosis
        default: return .autophagy
        }
    }

    /// Zones for timeline display (excludes fed state)
    static var timelineZones: [FastingZone] {
        [.burningSugar, .fatBurning, .ketosis, .deepKetosis, .autophagy]
    }
}

// MARK: - Training Sync Model

/// Represents an upcoming workout for training sync
struct UpcomingWorkout {
    let id: UUID
    let name: String
    let scheduledTime: Date
    let workoutType: String

    /// Hours until this workout starts
    var hoursUntil: Double {
        scheduledTime.timeIntervalSince(Date()) / 3600
    }

    /// Whether fasted training is recommended for this workout type
    var fastedTrainingOK: Bool {
        // Fasted training is generally OK for:
        // - Light cardio, mobility, recovery work
        // - Moderate strength (if adapted)
        // NOT recommended for:
        // - High intensity, heavy lifting, long endurance
        let lowIntensityTypes = ["mobility", "recovery", "stretching", "yoga", "light_cardio", "warmup"]
        return lowIntensityTypes.contains(workoutType.lowercased()) || hoursUntil > 2
    }

    /// Formatted time until workout
    var formattedTimeUntil: String {
        let hours = Int(hoursUntil)
        let minutes = Int((hoursUntil - Double(hours)) * 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

/// Eating window recommendation based on training schedule
struct TrainingSyncRecommendation {
    let workout: UpcomingWorkout
    let suggestedEatingStart: Date
    let suggestedEatingEnd: Date
    let protocol_: FastingProtocolType
    let reason: String

    /// Formatted eating window string
    var formattedWindow: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: suggestedEatingStart)) - \(formatter.string(from: suggestedEatingEnd))"
    }

    /// Protocol display string
    var protocolDisplay: String {
        "\(protocol_.fastingHours):\(protocol_.eatingHours) protocol"
    }
}

// MARK: - ViewModel

/// ViewModel for the FastingTrackerView (ACP-1001)
/// Manages current fasting state, timer, protocol selection, training sync, and UI state
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

    // Zone tracking
    @Published private(set) var currentZone: FastingZone = .burningSugar
    @Published private(set) var nextZone: FastingZone? = .fatBurning
    @Published private(set) var timeToNextZone: TimeInterval = 0

    // Training sync
    @Published private(set) var upcomingWorkout: UpcomingWorkout?
    @Published private(set) var trainingSyncRecommendation: TrainingSyncRecommendation?

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
            currentZone = .burningSugar
            nextZone = .fatBurning
            timeToNextZone = 0
            return
        }

        elapsedSeconds = Date().timeIntervalSince(fast.startedAt)
        targetSeconds = Double(fast.targetHours) * 3600

        // Update zone tracking
        let hours = elapsedSeconds / 3600
        currentZone = FastingZone.fromHours(hours)
        updateNextZone(currentHours: hours)
    }

    private func updateNextZone(currentHours: Double) {
        // Find the next zone based on current hours
        let zones = FastingZone.timelineZones
        guard let currentIndex = zones.firstIndex(of: currentZone) else {
            nextZone = nil
            timeToNextZone = 0
            return
        }

        let nextIndex = currentIndex + 1
        if nextIndex < zones.count {
            let next = zones[nextIndex]
            nextZone = next
            let hoursToNext = next.startHour - currentHours
            timeToNextZone = max(0, hoursToNext * 3600)
        } else {
            nextZone = nil
            timeToNextZone = 0
        }
    }

    // MARK: - Public Methods

    func loadData() async {
        await service.fetchFastingData()
        updateTimerState()
        await loadUpcomingWorkouts()
    }

    func startFast() async {
        error = nil
        do {
            service.setProtocol(selectedProtocol, customHours: customFastingHours)
            try await service.startFast()
            updateTimerState()
            HapticFeedback.success()
        } catch {
            ErrorLogger.shared.logError(error, context: "FastingTrackerViewModel.startFast")
            self.error = "Unable to start your fast. Please try again."
            HapticFeedback.error()
        }
    }

    func startFastWithProtocol(_ protocol_: FastingProtocolType) async {
        selectedProtocol = protocol_
        await startFast()
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
            HapticFeedback.success()
        } catch {
            ErrorLogger.shared.logError(error, context: "FastingTrackerViewModel.endFast")
            self.error = "Unable to end your fast. Please try again."
            HapticFeedback.error()
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

    func extendFast(byHours hours: Int) async {
        // Extend the target by adding hours to current target
        guard currentFast != nil else { return }
        let newTargetHours = Int(targetSeconds / 3600) + hours
        customFastingHours = newTargetHours
        // Note: In a full implementation, this would update the database record
        targetSeconds = Double(newTargetHours) * 3600
        HapticFeedback.medium()
    }

    // MARK: - Training Sync

    private func loadUpcomingWorkouts() async {
        // In a full implementation, this would fetch from WorkoutPrescriptionService
        // For now, we'll check for mock upcoming workouts
        // This simulates having upcoming training data

        // Check if there's a prescribed workout coming up
        // This would integrate with WorkoutPrescriptionService in production

        // Generate recommendation if we have an upcoming workout
        if let workout = upcomingWorkout {
            generateTrainingSyncRecommendation(for: workout)
        }
    }

    private func generateTrainingSyncRecommendation(for workout: UpcomingWorkout) {
        // Calculate optimal eating window based on workout time
        let workoutTime = workout.scheduledTime
        let calendar = Calendar.current

        // For strength training, eat 2-3 hours before
        // For cardio, can train more fasted
        let hoursBeforeWorkout = workout.fastedTrainingOK ? 0 : 2

        // Calculate eating window end (2 hours before workout for strength)
        let eatingEnd = calendar.date(byAdding: .hour, value: -hoursBeforeWorkout, to: workoutTime) ?? workoutTime

        // Default to 16:8 protocol
        let protocol_ = FastingProtocolType.sixteen8
        let eatingWindowHours = protocol_.eatingHours

        // Calculate eating start
        let eatingStart = calendar.date(byAdding: .hour, value: -eatingWindowHours, to: eatingEnd) ?? eatingEnd

        let reason = workout.fastedTrainingOK
            ? "Light session - fasted training is fine"
            : "Fuel up before your \(workout.name) session"

        trainingSyncRecommendation = TrainingSyncRecommendation(
            workout: workout,
            suggestedEatingStart: eatingStart,
            suggestedEatingEnd: eatingEnd,
            protocol_: protocol_,
            reason: reason
        )
    }

    func applyTrainingSyncSchedule() {
        guard let recommendation = trainingSyncRecommendation else { return }
        selectedProtocol = recommendation.protocol_
        HapticFeedback.success()
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

    var elapsedHours: Double {
        elapsedSeconds / 3600
    }

    var targetHours: Int {
        Int(targetSeconds / 3600)
    }

    var formattedElapsedTime: String {
        formatDuration(elapsedSeconds)
    }

    var formattedElapsedTimeShort: String {
        formatDurationShort(elapsedSeconds)
    }

    var formattedRemainingTime: String {
        if remainingSeconds <= 0 {
            return "Goal reached!"
        }
        return formatDuration(remainingSeconds)
    }

    var formattedTargetTime: String {
        formatDurationShort(targetSeconds)
    }

    var formattedTimeToNextZone: String {
        if timeToNextZone <= 0 {
            return "Now"
        }
        return formatDuration(timeToNextZone)
    }

    var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        return min(elapsedSeconds / targetSeconds, 1.0)
    }

    var goalReached: Bool {
        remainingSeconds <= 0 && isFasting
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

    // Zone status helpers
    var isFatBurningActive: Bool {
        elapsedHours >= 4
    }

    var isKetosisActive: Bool {
        elapsedHours >= 12
    }

    var isKetosisSoon: Bool {
        elapsedHours >= 10 && elapsedHours < 12
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

    private func formatDurationShort(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }
}
