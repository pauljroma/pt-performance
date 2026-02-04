import SwiftUI

/// Stat for top supplement tracking
struct SupplementStat: Identifiable {
    let id = UUID()
    let supplement: RoutineSupplement
    let count: Int
}

/// ViewModel for Supplement History View
@MainActor
final class SupplementHistoryViewModel: ObservableObject {
    @Published var dayData: [Date: SupplementDayData] = [:]
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var totalCompleteDays: Int = 0
    @Published var recentLogs: [SupplementLogEntry] = []
    @Published var isLoading = false
    @Published var error: String?

    private let service = SupplementService.shared

    // MARK: - Computed Properties

    /// Calendar day data dictionary for the grid
    var calendarDayData: [Date: SupplementDayData] {
        dayData
    }

    var monthlyCompliance: Double {
        let thisMonth = dayData.values.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }
        guard !thisMonth.isEmpty else { return 0 }
        return thisMonth.reduce(0) { $0 + $1.complianceRate } / Double(thisMonth.count)
    }

    var monthlyLogsCount: Int {
        let thisMonth = dayData.values.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }
        return thisMonth.reduce(0) { $0 + $1.totalTaken }
    }

    var monthlyMissedCount: Int {
        let thisMonth = dayData.values.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }
        return thisMonth.reduce(0) { $0 + max(0, $1.totalPlanned - $1.totalTaken) }
    }

    var topSupplements: [SupplementStat] {
        var counts: [String: (supplement: RoutineSupplement, count: Int)] = [:]
        for log in recentLogs where !log.skipped {
            if let supplement = log.supplement {
                if let existing = counts[log.supplementName] {
                    counts[log.supplementName] = (existing.supplement, existing.count + 1)
                } else {
                    counts[log.supplementName] = (supplement, 1)
                }
            }
        }
        return counts.values
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { SupplementStat(supplement: $0.supplement, count: $0.count) }
    }

    // MARK: - Data Access

    func data(for date: Date) -> SupplementDayData? {
        dayData[Calendar.current.startOfDay(for: date)]
    }

    // MARK: - Data Loading

    func loadHistory(for month: Date = Date()) async {
        isLoading = true
        error = nil

        do {
            let calendar = Calendar.current
            guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
                  let range = calendar.range(of: .day, in: .month, for: month) else {
                isLoading = false
                return
            }

            // Fetch logs for the month
            let logs = try await service.fetchLogHistory(days: 60)
            recentLogs = logs

            // Group by day
            var newDayData: [Date: SupplementDayData] = [:]
            for day in 1...range.count {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                    let dayLogs = logs.filter { calendar.isDate($0.takenAt, inSameDayAs: date) }
                    let taken = dayLogs.filter { !$0.skipped }.count
                    let planned = max(taken, 5) // Estimate planned
                    let rate = planned > 0 ? Double(taken) / Double(planned) : 0

                    newDayData[date] = SupplementDayData(
                        date: date,
                        logs: dayLogs,
                        complianceRate: rate,
                        totalPlanned: planned,
                        totalTaken: taken
                    )
                }
            }
            dayData = newDayData

            // Calculate streaks
            calculateStreaks()

        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func calculateStreaks() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get sorted dates with > 80% compliance
        let completeDates = dayData.values
            .filter { $0.complianceRate >= 0.8 }
            .map { calendar.startOfDay(for: $0.date) }
            .sorted()

        totalCompleteDays = completeDates.count

        // Current streak (count back from today)
        var current = 0
        var checkDate = today
        while completeDates.contains(checkDate) {
            current += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        currentStreak = current

        // Best streak
        var best = 0
        var tempStreak = 0
        var lastDate: Date?
        for date in completeDates {
            if let last = lastDate,
               let dayAfter = calendar.date(byAdding: .day, value: 1, to: last),
               calendar.isDate(date, inSameDayAs: dayAfter) {
                tempStreak += 1
            } else {
                tempStreak = 1
            }
            best = max(best, tempStreak)
            lastDate = date
        }
        bestStreak = best
    }
}
