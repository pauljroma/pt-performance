//
//  HealthHubViewModel.swift
//  PTPerformance
//
//  ViewModel for the Health Hub - unified entry point for all health features
//  Aggregates data from Recovery, Fasting, Supplements, and Biomarker services
//

import SwiftUI
import Combine

/// ViewModel for the Health Hub dashboard
/// Aggregates health data from multiple services to provide a unified snapshot
@MainActor
final class HealthHubViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Today's recovery score (0-100 percentage)
    @Published private(set) var recoveryScore: Int = 0
    @Published private(set) var hasRecoveredToday: Bool = false
    @Published private(set) var recoveryStreak: Int = 0

    /// Current fasting status
    @Published private(set) var isFasting: Bool = false
    @Published private(set) var fastingElapsedTime: String = "--:--"
    @Published private(set) var fastingTargetTime: String = "16:00"
    @Published private(set) var fastingProgress: Double = 0

    /// Supplement compliance
    @Published private(set) var supplementsTaken: Int = 0
    @Published private(set) var supplementsTotal: Int = 0
    @Published private(set) var supplementComplianceRate: Double = 0

    /// Biomarker summary
    @Published private(set) var biomarkersNeedingAttention: Int = 0
    @Published private(set) var totalBiomarkers: Int = 0
    @Published private(set) var lastLabDate: Date?

    /// Whether user has uploaded lab results
    @Published private(set) var hasLabResults: Bool = false

    /// AI Insight
    @Published private(set) var dailyInsight: String = "Loading your personalized insight..."
    @Published private(set) var insightIcon: String = "sparkles"

    /// Loading states
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?

    // MARK: - Services (using shared instances to prevent duplication)

    private let recoveryService = RecoveryTrackingService.shared
    private let fastingService = FastingTrackerService.shared
    private let supplementService = SupplementService.shared

    // Lazy-loaded biomarker view model to prevent unnecessary initialization
    private lazy var biomarkerViewModel: BiomarkerDashboardViewModel = {
        BiomarkerDashboardViewModel()
    }()

    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?

    /// Flag to track if timer updates are paused (e.g., when view is not visible)
    private var isTimerPaused: Bool = false

    /// Flag to prevent redundant data fetching during tab switches
    private var hasLoadedInitialData: Bool = false

    // MARK: - Initialization

    init() {
        setupObservers()
    }

    // MARK: - Data Loading

    /// Load all health hub data
    /// Uses hasLoadedInitialData flag to prevent redundant fetching on tab switches
    func loadData() async {
        // Skip if we've already loaded and this isn't a forced refresh
        guard !hasLoadedInitialData || isLoading == false else {
            return
        }

        isLoading = true
        error = nil

        // Load data from all services in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadRecoveryData() }
            group.addTask { await self.loadFastingData() }
            group.addTask { await self.loadSupplementData() }
            group.addTask { await self.loadBiomarkerData() }
        }

        // Generate insight after all data is loaded
        await generateDailyInsight()

        hasLoadedInitialData = true
        isLoading = false
    }

    /// Refresh all data (forces reload regardless of cache)
    func refresh() async {
        hasLoadedInitialData = false
        await loadData()
    }

    // MARK: - Timer Control

    /// Pause timer updates when the view is not visible
    /// Prevents unnecessary CPU usage and battery drain
    func pauseTimerUpdates() {
        isTimerPaused = true
        stopFastingTimer()
    }

    /// Resume timer updates when the view becomes visible again
    func resumeTimerUpdates() {
        isTimerPaused = false
        if isFasting {
            startFastingTimer()
        }
    }

    // MARK: - Recovery Data

    private func loadRecoveryData() async {
        let streakInfo = await recoveryService.calculateStreakInfo()
        let weeklyStats = await recoveryService.calculateWeeklyStats()

        self.recoveryStreak = streakInfo.currentStreak
        self.hasRecoveredToday = streakInfo.hasRecoveredToday

        // Calculate recovery score based on weekly activity and streak
        // This is a composite score: streak contribution + weekly consistency
        let streakBonus = min(streakInfo.currentStreak * 5, 30) // Max 30 points from streak
        let weeklyContribution = min(weeklyStats.totalSessions * 10, 50) // Max 50 points from weekly sessions
        let consistencyBonus = weeklyStats.weekOverWeekChange > 0 ? 20 : 10 // 10-20 points for consistency

        self.recoveryScore = min(streakBonus + weeklyContribution + consistencyBonus, 100)
    }

    // MARK: - Fasting Data

    private func loadFastingData() async {
        await fastingService.fetchFastingData()

        if let currentFast = fastingService.currentFast {
            self.isFasting = true
            self.fastingTargetTime = formatDuration(hours: currentFast.targetHours)
            startFastingTimer()
        } else {
            self.isFasting = false
            self.fastingElapsedTime = "00:00"
            self.fastingProgress = 0
            stopFastingTimer()
        }
    }

    private func startFastingTimer() {
        // Don't start timer if paused (view not visible)
        guard !isTimerPaused else { return }

        stopFastingTimer()

        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateFastingTime()
            }

        // Update immediately
        updateFastingTime()
    }

    private func stopFastingTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func updateFastingTime() {
        guard let currentFast = fastingService.currentFast else { return }

        let elapsed = Date().timeIntervalSince(currentFast.startedAt)
        let target = Double(currentFast.targetHours) * 3600

        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60

        self.fastingElapsedTime = String(format: "%02d:%02d", hours, minutes)
        self.fastingProgress = min(elapsed / target, 1.0)
    }

    private func formatDuration(hours: Int) -> String {
        return String(format: "%02d:00", hours)
    }

    // MARK: - Supplement Data

    private func loadSupplementData() async {
        await supplementService.fetchRoutines()
        await supplementService.calculateTodayCompliance()

        let todayDoses = supplementService.todayDoses
        self.supplementsTotal = todayDoses.count
        self.supplementsTaken = todayDoses.filter { $0.isTaken }.count
        self.supplementComplianceRate = supplementsTotal > 0
            ? Double(supplementsTaken) / Double(supplementsTotal)
            : 0
    }

    // MARK: - Biomarker Data

    private func loadBiomarkerData() async {
        await biomarkerViewModel.loadDashboard()

        self.totalBiomarkers = biomarkerViewModel.biomarkerSummaries.count
        self.biomarkersNeedingAttention = biomarkerViewModel.concerningBiomarkers.count
        self.lastLabDate = biomarkerViewModel.lastLabDate
        self.hasLabResults = biomarkerViewModel.biomarkerSummaries.count > 0
    }

    // MARK: - AI Insight Generation

    private func generateDailyInsight() async {
        // Generate contextual insight based on current health data
        var insights: [(message: String, icon: String, priority: Int)] = []

        // Check recovery status
        if !hasRecoveredToday && recoveryStreak > 0 {
            insights.append((
                "Don't break your \(recoveryStreak)-day recovery streak! Consider a quick cold shower or sauna session today.",
                "flame.fill",
                3
            ))
        } else if hasRecoveredToday {
            insights.append((
                "Great job maintaining your recovery routine! Consistency is key to optimal performance.",
                "checkmark.circle.fill",
                1
            ))
        }

        // Check fasting status
        if isFasting && fastingProgress > 0.75 {
            insights.append((
                "You're in the home stretch of your fast! Keep going - autophagy benefits peak in the final hours.",
                "clock.fill",
                2
            ))
        } else if !isFasting && fastingService.currentStreak > 3 {
            insights.append((
                "Your \(fastingService.currentStreak)-day fasting streak shows great discipline. Ready for today's fast?",
                "trophy.fill",
                2
            ))
        }

        // Check supplement compliance
        if supplementsTotal > 0 && supplementComplianceRate < 0.5 {
            insights.append((
                "You have \(supplementsTotal - supplementsTaken) supplements left to take today. Stay on track for optimal results!",
                "pill.fill",
                2
            ))
        }

        // Check biomarkers
        if biomarkersNeedingAttention > 0 {
            insights.append((
                "\(biomarkersNeedingAttention) biomarker\(biomarkersNeedingAttention == 1 ? "" : "s") need attention. Review your lab results for actionable insights.",
                "exclamationmark.triangle.fill",
                3
            ))
        }

        // Select highest priority insight, or default message
        if let topInsight = insights.sorted(by: { $0.priority > $1.priority }).first {
            self.dailyInsight = topInsight.message
            self.insightIcon = topInsight.icon
        } else {
            self.dailyInsight = "You're doing great! Keep up with your health routines for optimal performance."
            self.insightIcon = "sparkles"
        }
    }

    // MARK: - Observers

    private func setupObservers() {
        // Observe fasting service changes
        fastingService.$currentFast
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentFast in
                self?.isFasting = currentFast != nil
                if currentFast != nil {
                    self?.startFastingTimer()
                } else {
                    self?.stopFastingTimer()
                }
            }
            .store(in: &cancellables)

        // Observe supplement changes
        supplementService.$todayDoses
            .receive(on: DispatchQueue.main)
            .sink { [weak self] doses in
                self?.supplementsTotal = doses.count
                self?.supplementsTaken = doses.filter { $0.isTaken }.count
                if let total = self?.supplementsTotal, total > 0 {
                    self?.supplementComplianceRate = Double(self?.supplementsTaken ?? 0) / Double(total)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Quick Actions

    /// Start a new fasting session
    func startFast() async {
        do {
            try await fastingService.startFast()
            HapticFeedback.success()
        } catch {
            self.error = error
            HapticFeedback.error()
        }
    }

    /// End current fasting session
    func endFast() async {
        do {
            try await fastingService.endFast()
            HapticFeedback.success()
        } catch {
            self.error = error
            HapticFeedback.error()
        }
    }

    // MARK: - Computed Properties

    /// Recovery status text for display
    var recoveryStatusText: String {
        if hasRecoveredToday {
            return "\(recoveryScore)%"
        } else if recoveryStreak > 0 {
            return "\(recoveryScore)%"
        } else {
            return "Not started"
        }
    }

    /// Recovery status color
    var recoveryStatusColor: Color {
        switch recoveryScore {
        case 80...100: return .green
        case 60..<80: return .modusTealAccent
        case 40..<60: return .orange
        default: return .red
        }
    }

    /// Fasting status text for display
    var fastingStatusText: String {
        if isFasting {
            return "\(fastingElapsedTime) of \(fastingTargetTime)"
        } else {
            return "Not fasting"
        }
    }

    /// Supplement status text for display
    var supplementStatusText: String {
        return "\(supplementsTaken)/\(supplementsTotal) logged"
    }

    /// Biomarker status text for display
    var biomarkerStatusText: String {
        if biomarkersNeedingAttention > 0 {
            return "\(biomarkersNeedingAttention) marker\(biomarkersNeedingAttention == 1 ? "" : "s") need attention"
        } else if totalBiomarkers > 0 {
            return "All markers in range"
        } else {
            return "No labs uploaded"
        }
    }

    /// Biomarker status color
    var biomarkerStatusColor: Color {
        if biomarkersNeedingAttention > 0 {
            return .orange
        } else if totalBiomarkers > 0 {
            return .green
        } else {
            return .secondary
        }
    }

    deinit {
        timerCancellable?.cancel()
        timerCancellable = nil
        cancellables.removeAll()
    }
}

// MARK: - Snapshot Item Model

/// Represents a single item in the Today's Snapshot section
struct HealthSnapshotItem: Identifiable {
    var id: String { "\(title)-\(value)" }
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    let status: SnapshotStatus

    enum SnapshotStatus {
        case good
        case warning
        case needsAttention
        case neutral

        var indicatorColor: Color {
            switch self {
            case .good: return .green
            case .warning: return .orange
            case .needsAttention: return .red
            case .neutral: return .secondary
            }
        }
    }
}

// MARK: - Quick Action Model

/// Represents a quick action button in the Health Hub
struct HealthQuickAction: Identifiable {
    var id: String { "\(title)-\(destination)" }
    let title: String
    let icon: String
    let iconColor: Color
    let gradientColors: [Color]
    let destination: HealthHubDestination
}

/// Navigation destinations from Health Hub
enum HealthHubDestination {
    case fastingTracker
    case supplements
    case recovery
    case biomarkers
    case labResults
    case nutrition
    case aiCoach
}
