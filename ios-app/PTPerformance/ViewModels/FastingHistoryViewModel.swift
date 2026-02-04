import SwiftUI
import Combine

/// ViewModel for FastingHistoryView (ACP-1004)
/// Manages history fetching, calendar data, and statistics
@MainActor
final class FastingHistoryViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var fastingLogs: [FastingLog] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    // Streak data
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var bestStreak: Int = 0
    @Published private(set) var monthlyStreak: Int = 0

    // MARK: - Private Properties

    private let service = FastingTrackerService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupBindings()
    }

    private func setupBindings() {
        service.$fastingHistory
            .receive(on: DispatchQueue.main)
            .assign(to: &$fastingLogs)

        service.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        service.$currentStreak
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentStreak)

        service.$bestStreak
            .receive(on: DispatchQueue.main)
            .assign(to: &$bestStreak)
    }

    // MARK: - Public Methods

    func loadHistory() async {
        await service.fetchFastingData()
        calculateMonthlyStreak()
    }

    func deleteFast(_ fast: FastingLog) async {
        do {
            try await service.deleteFast(fast)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Calendar Data

    func fastingLog(for date: Date) -> FastingLog? {
        let calendar = Calendar.current
        return fastingLogs.first { log in
            calendar.isDate(log.startedAt, inSameDayAs: date)
        }
    }

    // MARK: - Statistics

    func completedFasts(for period: HistoryPeriod) -> Int {
        let fasts = fastsForPeriod(period)
        return fasts.filter { fast in
            guard let actual = fast.actualHours else { return false }
            return actual >= Double(fast.targetHours) * 0.9
        }.count
    }

    func plannedFasts(for period: HistoryPeriod) -> Int {
        switch period {
        case .week: return 7
        case .month: return 30
        }
    }

    func averageDuration(for period: HistoryPeriod) -> Double {
        let fasts = fastsForPeriod(period).filter { $0.endedAt != nil }
        guard !fasts.isEmpty else { return 0 }
        let total = fasts.compactMap { $0.actualHours }.reduce(0, +)
        return total / Double(fasts.count)
    }

    func compliance(for period: HistoryPeriod) -> Double {
        let completed = completedFasts(for: period)
        let planned = plannedFasts(for: period)
        guard planned > 0 else { return 0 }
        return Double(completed) / Double(planned)
    }

    func longestFast(for period: HistoryPeriod) -> Double {
        let fasts = fastsForPeriod(period)
        return fasts.compactMap { $0.actualHours }.max() ?? 0
    }

    var recentFasts: [FastingLog] {
        Array(fastingLogs.prefix(10))
    }

    // MARK: - Private Helpers

    private func fastsForPeriod(_ period: HistoryPeriod) -> [FastingLog] {
        let calendar = Calendar.current
        let startDate: Date

        switch period {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        }

        return fastingLogs.filter { $0.startedAt >= startDate }
    }

    private func calculateMonthlyStreak() {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else {
            monthlyStreak = 0
            return
        }

        let monthlyFasts = fastingLogs.filter { $0.startedAt >= monthStart }
            .sorted { $0.startedAt > $1.startedAt }

        var streak = 0
        var currentDate = Date()

        while currentDate >= monthStart {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayFasts = monthlyFasts.filter { calendar.isDate($0.startedAt, inSameDayAs: dayStart) }

            let successfulFast = dayFasts.first { fast in
                guard let actual = fast.actualHours else { return false }
                return actual >= Double(fast.targetHours) * 0.9
            }

            if successfulFast != nil {
                streak += 1
            } else if !calendar.isDateInToday(currentDate) {
                break
            }

            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? monthStart
        }

        monthlyStreak = streak
    }
}
