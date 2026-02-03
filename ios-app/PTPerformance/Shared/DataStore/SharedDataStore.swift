import Foundation
import WidgetKit

/// Manages shared data storage between main app and widget extension using App Groups
public final class SharedDataStore {

    // MARK: - Singleton

    public static let shared = SharedDataStore()

    // MARK: - Constants

    private let suiteName = "group.com.ptperformance.shared"

    public enum Keys {
        public static let readiness = "widget_readiness"
        public static let workout = "widget_workout"
        public static let adherence = "widget_adherence"
        public static let streak = "widget_streak"
        public static let weekTrend = "widget_week_trend"
        public static let lastRefresh = "widget_last_refresh"
        public static let userId = "widget_user_id"
    }

    // MARK: - Properties

    private lazy var userDefaults: UserDefaults? = {
        UserDefaults(suiteName: suiteName)
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Init

    private init() {}

    // MARK: - Readiness

    public func saveReadiness(_ data: WidgetReadiness) {
        save(data, forKey: Keys.readiness)
        updateLastRefresh()
    }

    public func getReadiness() -> WidgetReadiness? {
        get(WidgetReadiness.self, forKey: Keys.readiness)
    }

    // MARK: - Workout

    public func saveWorkout(_ data: WidgetWorkout) {
        save(data, forKey: Keys.workout)
        updateLastRefresh()
    }

    public func getWorkout() -> WidgetWorkout? {
        get(WidgetWorkout.self, forKey: Keys.workout)
    }

    // MARK: - Adherence

    public func saveAdherence(_ data: WidgetAdherence) {
        save(data, forKey: Keys.adherence)
        updateLastRefresh()
    }

    public func getAdherence() -> WidgetAdherence? {
        get(WidgetAdherence.self, forKey: Keys.adherence)
    }

    // MARK: - Streak

    public func saveStreak(_ data: WidgetStreak) {
        save(data, forKey: Keys.streak)
        updateLastRefresh()
    }

    public func getStreak() -> WidgetStreak? {
        get(WidgetStreak.self, forKey: Keys.streak)
    }

    // MARK: - Week Trend (for Recovery Dashboard)

    public func saveWeekTrend(_ data: [WidgetReadiness]) {
        save(data, forKey: Keys.weekTrend)
    }

    public func getWeekTrend() -> [WidgetReadiness]? {
        get([WidgetReadiness].self, forKey: Keys.weekTrend)
    }

    // MARK: - User ID
    // TODO: SECURITY - Migrate userId to SecureStore (Keychain)
    // User IDs are sensitive PII that could identify a person and should not be stored in UserDefaults.
    // Use SecureStore.shared.set(userId, forKey: SecureStore.Keys.userIdentifier) instead.
    // This requires coordinating with widget extension which may have limited Keychain access.
    // See: Services/Security/SecureStore.swift

    public func saveUserId(_ userId: String) {
        userDefaults?.set(userId, forKey: Keys.userId)
    }

    public func getUserId() -> String? {
        userDefaults?.string(forKey: Keys.userId)
    }

    // MARK: - Last Refresh

    public func getLastRefresh() -> Date? {
        userDefaults?.object(forKey: Keys.lastRefresh) as? Date
    }

    private func updateLastRefresh() {
        userDefaults?.set(Date(), forKey: Keys.lastRefresh)
    }

    // MARK: - Bulk Update

    /// Update all widget data at once (call from main app after data sync)
    public func updateAllWidgetData(
        readiness: WidgetReadiness?,
        workout: WidgetWorkout?,
        adherence: WidgetAdherence?,
        streak: WidgetStreak?,
        weekTrend: [WidgetReadiness]?
    ) {
        if let readiness = readiness {
            save(readiness, forKey: Keys.readiness)
        }
        if let workout = workout {
            save(workout, forKey: Keys.workout)
        }
        if let adherence = adherence {
            save(adherence, forKey: Keys.adherence)
        }
        if let streak = streak {
            save(streak, forKey: Keys.streak)
        }
        if let weekTrend = weekTrend {
            save(weekTrend, forKey: Keys.weekTrend)
        }

        updateLastRefresh()
        reloadWidgets()
    }

    // MARK: - Widget Reload

    /// Trigger WidgetKit to reload all timelines
    public func reloadWidgets() {
        #if !WIDGET_EXTENSION
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    /// Reload specific widget timeline
    public func reloadWidget(kind: String) {
        #if !WIDGET_EXTENSION
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        #endif
    }

    // MARK: - Clear Data

    /// Clear all widget data (call on logout)
    public func clearAllData() {
        userDefaults?.removeObject(forKey: Keys.readiness)
        userDefaults?.removeObject(forKey: Keys.workout)
        userDefaults?.removeObject(forKey: Keys.adherence)
        userDefaults?.removeObject(forKey: Keys.streak)
        userDefaults?.removeObject(forKey: Keys.weekTrend)
        userDefaults?.removeObject(forKey: Keys.lastRefresh)
        userDefaults?.removeObject(forKey: Keys.userId)
        reloadWidgets()
    }

    // MARK: - Private Helpers

    private func save<T: Encodable>(_ data: T, forKey key: String) {
        guard let encoded = try? encoder.encode(data) else {
            print("[SharedDataStore] Failed to encode data for key: \(key)")
            return
        }
        userDefaults?.set(encoded, forKey: key)
    }

    private func get<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults?.data(forKey: key) else {
            return nil
        }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("[SharedDataStore] Failed to decode data for key: \(key), error: \(error)")
            return nil
        }
    }
}

// MARK: - Widget Kind Constants

public extension SharedDataStore {
    enum WidgetKind {
        public static let readiness = "ReadinessWidget"
        public static let todayWorkout = "TodayWorkoutWidget"
        public static let streak = "StreakWidget"
        public static let dailySummary = "DailySummaryWidget"
        public static let weekOverview = "WeekOverviewWidget"
        public static let recoveryDashboard = "RecoveryDashboardWidget"
    }
}
