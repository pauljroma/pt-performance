//
//  TabBarBadgeManager.swift
//  PTPerformance
//
//  Centralized badge management for tab bar notifications
//

import SwiftUI
import Combine

/// Manages badge counts for tab bar items
/// Provides a centralized way to update badges from anywhere in the app
@MainActor
final class TabBarBadgeManager: ObservableObject {
    // MARK: - Singleton

    static let shared = TabBarBadgeManager()

    // MARK: - Published Properties

    /// Badge count for Today tab (index 0)
    /// Shows number of incomplete readiness check-ins or pending workouts
    @Published var todayBadge: Int = 0

    /// Badge count for Programs tab (index 1)
    /// Shows number of new programs assigned by therapist
    @Published var programsBadge: Int = 0

    /// Badge count for Profile tab (index 2)
    /// Shows unread notifications or subscription updates
    @Published var profileBadge: Int = 0

    // MARK: - Therapist Tab Badges

    /// Badge count for Patients tab
    @Published var patientsBadge: Int = 0

    /// Badge count for Intelligence tab (at-risk patients)
    @Published var intelligenceBadge: Int = 0

    /// Badge count for Prescriptions tab (overdue prescriptions)
    @Published var prescriptionsBadge: Int = 0

    /// Badge count for Reports tab
    @Published var reportsBadge: Int = 0

    /// Badge count for Schedule tab
    @Published var scheduleBadge: Int = 0

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        // Subscribe to notification changes if needed
        setupNotificationObservers()
    }

    // MARK: - Public Methods

    /// Sets the badge count for a specific tab
    /// - Parameters:
    ///   - count: The badge count to display (0 hides the badge)
    ///   - tabIndex: The tab index to update
    func setBadge(_ count: Int, for tabIndex: Int) {
        switch tabIndex {
        case 0:
            todayBadge = count
        case 1:
            programsBadge = count
        case 2:
            profileBadge = count
        case 3:
            // Therapist: Patients or Schedule depending on role
            patientsBadge = count
        case 4:
            reportsBadge = count
        default:
            break
        }
    }

    /// Clears the badge for a specific tab
    /// - Parameter tabIndex: The tab index to clear
    func clearBadge(for tabIndex: Int) {
        setBadge(0, for: tabIndex)
    }

    /// Clears all badges
    func clearAllBadges() {
        todayBadge = 0
        programsBadge = 0
        profileBadge = 0
        patientsBadge = 0
        intelligenceBadge = 0
        prescriptionsBadge = 0
        reportsBadge = 0
        scheduleBadge = 0
    }

    /// Increments the badge count for a specific tab
    /// - Parameter tabIndex: The tab index to increment
    func incrementBadge(for tabIndex: Int) {
        switch tabIndex {
        case 0:
            todayBadge += 1
        case 1:
            programsBadge += 1
        case 2:
            profileBadge += 1
        case 3:
            patientsBadge += 1
        case 4:
            reportsBadge += 1
        default:
            break
        }
    }

    // MARK: - Convenience Methods for Patient Tabs

    /// Sets badge for new program assignments
    func setNewProgramsBadge(_ count: Int) {
        programsBadge = count
    }

    /// Sets badge for profile notifications (unread messages, subscription updates)
    func setProfileNotificationsBadge(_ count: Int) {
        profileBadge = count
    }

    /// Sets badge for pending readiness check-in
    func setReadinessCheckInPending(_ pending: Bool) {
        todayBadge = pending ? 1 : 0
    }

    // MARK: - Convenience Methods for Therapist Tabs

    /// Sets badge for patients requiring attention
    func setPatientsNeedingAttention(_ count: Int) {
        patientsBadge = count
    }

    /// Sets badge for pending reports
    func setPendingReports(_ count: Int) {
        reportsBadge = count
    }

    /// Sets badge for upcoming schedule items needing review
    func setScheduleItemsNeedingReview(_ count: Int) {
        scheduleBadge = count
    }

    /// Sets badge for overdue prescriptions
    func setOverduePrescriptions(_ count: Int) {
        prescriptionsBadge = count
    }

    /// Sets badge for at-risk patients in Intelligence tab
    func setIntelligenceBadge(_ count: Int) {
        intelligenceBadge = count
    }

    /// Sets badge for coaching alerts (combines with intelligence badge)
    func setCoachingAlertsBadge(_ count: Int) {
        // Coaching alerts are shown on the Intelligence tab
        intelligenceBadge = count
    }

    /// Sets badge for risk escalations (combines with intelligence badge)
    func setRiskEscalationsBadge(_ count: Int) {
        // Risk escalations are shown on the Intelligence tab
        intelligenceBadge = count
    }

    // MARK: - Private Methods

    private func setupNotificationObservers() {
        // Listen for program assignment notifications
        NotificationCenter.default.publisher(for: .newProgramAssigned)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let count = notification.userInfo?["count"] as? Int {
                    self?.programsBadge = count
                } else {
                    self?.programsBadge += 1
                }
            }
            .store(in: &cancellables)

        // Listen for readiness check-in reminders
        NotificationCenter.default.publisher(for: .readinessCheckInReminder)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.todayBadge = 1
            }
            .store(in: &cancellables)

        // Listen for profile notifications
        NotificationCenter.default.publisher(for: .profileNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let count = notification.userInfo?["count"] as? Int {
                    self?.profileBadge = count
                } else {
                    self?.profileBadge += 1
                }
            }
            .store(in: &cancellables)

        // Listen for new risk escalations
        NotificationCenter.default.publisher(for: .newRiskEscalation)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let count = notification.userInfo?["count"] as? Int {
                    self?.intelligenceBadge = count
                } else {
                    self?.intelligenceBadge += 1
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a new program is assigned to the patient
    static let newProgramAssigned = Notification.Name("newProgramAssigned")

    /// Posted when a readiness check-in reminder is due
    static let readinessCheckInReminder = Notification.Name("readinessCheckInReminder")

    /// Posted when there's a new profile notification
    static let profileNotification = Notification.Name("profileNotification")

    /// Posted when a new risk escalation is created
    static let newRiskEscalation = Notification.Name("newRiskEscalation")
}
