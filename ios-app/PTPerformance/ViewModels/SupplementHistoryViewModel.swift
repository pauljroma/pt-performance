import SwiftUI

/// Stat for top supplement tracking
struct SupplementStat: Identifiable {
    var id: String { "\(supplement.id)-\(count)" }
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
    @Published var hasNoHistory = false

    private let service = SupplementService.shared

    /// Compliance threshold for considering a day "complete" (80%)
    private let complianceThreshold = 0.8

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
        hasNoHistory = false

        do {
            let calendar = Calendar.current
            guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
                  let range = calendar.range(of: .day, in: .month, for: month) else {
                isLoading = false
                return
            }

            // Fetch routines to determine planned supplements per day
            await service.fetchRoutines()
            let routines = service.routines.filter { $0.isActive }

            // Fetch logs for the month
            let logs = try await service.fetchLogHistory(days: 60)
            recentLogs = logs

            // Check if there's any history at all
            hasNoHistory = logs.isEmpty && routines.isEmpty

            // Group by day
            var newDayData: [Date: SupplementDayData] = [:]
            let today = calendar.startOfDay(for: Date())

            for day in 1...range.count {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                    let dayStart = calendar.startOfDay(for: date)

                    // Don't create data for future dates
                    if dayStart > today {
                        continue
                    }

                    let dayLogs = logs.filter { calendar.isDate($0.takenAt, inSameDayAs: date) }
                    let taken = dayLogs.filter { !$0.skipped }.count

                    // Calculate planned count based on active routines for this day
                    let planned = calculatePlannedCount(for: date, routines: routines, calendar: calendar)

                    // Calculate compliance rate
                    let rate: Double
                    if planned > 0 {
                        rate = min(Double(taken) / Double(planned), 1.0) // Cap at 100%
                    } else if taken > 0 {
                        // User logged supplements but has no routines - count as complete
                        rate = 1.0
                    } else {
                        rate = 0.0
                    }

                    // Only add day data if there were logs or planned supplements
                    if !dayLogs.isEmpty || planned > 0 {
                        newDayData[dayStart] = SupplementDayData(
                            date: dayStart,
                            logs: dayLogs,
                            complianceRate: rate,
                            totalPlanned: planned,
                            totalTaken: taken
                        )
                    }
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

    /// Calculates the number of planned supplements for a given date based on routines
    private func calculatePlannedCount(for date: Date, routines: [SupplementRoutine], calendar: Calendar) -> Int {
        let weekday = calendar.component(.weekday, from: date) - 1 // Convert to 0-indexed (Sunday = 0)

        var count = 0

        for routine in routines {
            // Skip routines that started after this date
            if routine.startDate > date {
                continue
            }

            // Skip routines that ended before this date
            if let endDate = routine.endDate, endDate < date {
                continue
            }

            // Check if this routine is scheduled for this day based on frequency
            let isScheduled: Bool
            switch routine.frequency {
            case .daily:
                isScheduled = true
            case .twiceDaily:
                isScheduled = true
                count += 1 // Add extra dose for twice daily
            case .threeTimesDaily:
                isScheduled = true
                count += 2 // Add extra doses for three times daily
            case .weekly:
                // Assume weekly means once per week, on the first day
                isScheduled = weekday == 0
            case .trainingDaysOnly:
                // For training days, assume weekdays (Mon-Fri) are training days
                isScheduled = weekday >= 1 && weekday <= 5
            case .asNeeded:
                // As needed supplements don't count toward planned
                isScheduled = false
            }

            if isScheduled {
                count += 1
            }
        }

        return count
    }

    private func calculateStreaks() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get sorted dates with compliance >= threshold (80%)
        // Only consider days that had planned supplements
        let completeDates = dayData.values
            .filter { $0.complianceRate >= complianceThreshold && $0.totalPlanned > 0 }
            .map { calendar.startOfDay(for: $0.date) }
            .sorted()

        totalCompleteDays = completeDates.count

        // Guard against empty data
        guard !completeDates.isEmpty else {
            currentStreak = 0
            bestStreak = 0
            return
        }

        // Current streak (count back from today or yesterday)
        // Allow for the current day to not be complete yet
        var current = 0
        var checkDate = today

        // If today doesn't have data yet or isn't complete, start from yesterday
        if !completeDates.contains(checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
                currentStreak = 0
                bestStreak = calculateBestStreak(from: completeDates, calendar: calendar)
                return
            }
            checkDate = yesterday
        }

        // Count consecutive days backward
        while completeDates.contains(checkDate) {
            current += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previousDay
        }
        currentStreak = current

        // Calculate best streak
        bestStreak = calculateBestStreak(from: completeDates, calendar: calendar)
    }

    /// Calculates the longest streak from a sorted array of dates
    private func calculateBestStreak(from dates: [Date], calendar: Calendar) -> Int {
        guard !dates.isEmpty else { return 0 }

        var best = 1
        var tempStreak = 1
        var lastDate = dates[0]

        for date in dates.dropFirst() {
            if let expectedNextDay = calendar.date(byAdding: .day, value: 1, to: lastDate),
               calendar.isDate(date, inSameDayAs: expectedNextDay) {
                tempStreak += 1
                best = max(best, tempStreak)
            } else {
                tempStreak = 1
            }
            lastDate = date
        }

        return best
    }
}
