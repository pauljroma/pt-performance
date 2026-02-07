import Foundation

/// Weekly adherence data for widget display
public struct WidgetAdherence: Codable {
    public let adherencePercent: Double    // 0-100
    public let completedSessions: Int
    public let totalSessions: Int
    public let weekDays: [DayStatus]       // 7 days, Mon-Sun
    public let lastUpdated: Date

    public struct DayStatus: Codable {
        public let date: Date
        public let status: Status

        public enum Status: String, Codable {
            case completed      // ✓
            case scheduled      // ○
            case skipped        // ✗
            case restDay        // -
            case future         // ·
        }

        public init(date: Date, status: Status) {
            self.date = date
            self.status = status
        }
    }

    public init(adherencePercent: Double, completedSessions: Int, totalSessions: Int, weekDays: [DayStatus], lastUpdated: Date = Date()) {
        self.adherencePercent = adherencePercent
        self.completedSessions = completedSessions
        self.totalSessions = totalSessions
        self.weekDays = weekDays
        self.lastUpdated = lastUpdated
    }

    /// Placeholder for widget previews
    public static var placeholder: WidgetAdherence {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today

        let days: [DayStatus] = (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else {
                return nil
            }
            let status: DayStatus.Status
            if offset < 3 {
                status = .completed
            } else if offset < 5 {
                status = .scheduled
            } else {
                status = .restDay
            }
            return DayStatus(date: date, status: status)
        }

        return WidgetAdherence(adherencePercent: 85, completedSessions: 3, totalSessions: 5, weekDays: days)
    }
}
