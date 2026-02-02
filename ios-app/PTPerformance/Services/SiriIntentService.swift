import Foundation
import SwiftUI

/// Service to handle pending Siri intents when the app opens
/// Processes intent data stored in UserDefaults and triggers appropriate actions
@MainActor
final class SiriIntentService: ObservableObject {
    static let shared = SiriIntentService()

    @Published var pendingIntent: PendingIntent?
    @Published var showingIntentAlert = false
    @Published var alertMessage = ""

    private let userDefaults = UserDefaults.standard
    private let pendingIntentKey = "pendingSiriIntent"

    private init() {}

    // MARK: - Intent Types

    enum IntentType: String {
        case logExercise
        case quickLog
        case logReadiness
        case restTimer
        case startWorkout
        case viewProgress
    }

    struct PendingIntent {
        let type: IntentType
        let data: [String: Any]
        let timestamp: Date
    }

    // MARK: - Check for Pending Intents

    /// Called when app becomes active to check for pending Siri intents
    func checkForPendingIntents() {
        guard let data = userDefaults.data(forKey: pendingIntentKey),
              let intentData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let typeString = intentData["type"] as? String,
              let type = IntentType(rawValue: typeString),
              let timestamp = intentData["timestamp"] as? TimeInterval else {
            return
        }

        // Only process intents from the last 5 minutes
        let intentDate = Date(timeIntervalSince1970: timestamp)
        guard Date().timeIntervalSince(intentDate) < 300 else {
            clearPendingIntent()
            return
        }

        pendingIntent = PendingIntent(
            type: type,
            data: intentData,
            timestamp: intentDate
        )

        // Clear the stored intent
        clearPendingIntent()

        // Process the intent
        processIntent()
    }

    /// Clear stored pending intent
    private func clearPendingIntent() {
        userDefaults.removeObject(forKey: pendingIntentKey)
    }

    // MARK: - Process Intent

    private func processIntent() {
        guard let intent = pendingIntent else { return }

        switch intent.type {
        case .logExercise:
            processLogExerciseIntent(intent.data)

        case .quickLog:
            processQuickLogIntent(intent.data)

        case .logReadiness:
            processLogReadinessIntent(intent.data)

        case .restTimer:
            processRestTimerIntent(intent.data)

        case .startWorkout:
            processStartWorkoutIntent(intent.data)

        case .viewProgress:
            processViewProgressIntent(intent.data)
        }

        // Clear pending intent after processing
        self.pendingIntent = nil
    }

    // MARK: - Intent Processors

    private func processLogExerciseIntent(_ data: [String: Any]) {
        let sets = data["sets"] as? Int ?? 0
        let reps = data["reps"] as? Int ?? 0
        let exerciseName = data["exerciseName"] as? String ?? ""
        let weight = data["weight"] as? Double ?? 0

        DebugLogger.shared.info("SiriIntentService", "Processing log exercise: \(sets) sets of \(reps)")

        // Post notification for views to handle
        NotificationCenter.default.post(
            name: .siriLogExerciseIntent,
            object: nil,
            userInfo: [
                "sets": sets,
                "reps": reps,
                "exerciseName": exerciseName,
                "weight": weight
            ]
        )

        var message = "Logged \(sets) sets of \(reps) reps"
        if !exerciseName.isEmpty {
            message = "Logged \(sets) sets of \(reps) for \(exerciseName)"
        }
        showAlert(message: message)
    }

    private func processQuickLogIntent(_ data: [String: Any]) {
        let reps = data["reps"] as? Int ?? 0
        let weight = data["weight"] as? Double ?? 0

        DebugLogger.shared.info("SiriIntentService", "Processing quick log: \(reps) reps")

        NotificationCenter.default.post(
            name: .siriQuickLogIntent,
            object: nil,
            userInfo: [
                "reps": reps,
                "weight": weight
            ]
        )
    }

    private func processLogReadinessIntent(_ data: [String: Any]) {
        let sleepHours = data["sleepHours"] as? Int ?? 7
        let energyLevel = data["energyLevel"] as? Int ?? 5
        let sorenessLevel = data["sorenessLevel"] as? Int ?? 5
        let stressLevel = data["stressLevel"] as? Int ?? 5

        DebugLogger.shared.info("SiriIntentService", "Processing log readiness")

        NotificationCenter.default.post(
            name: .siriLogReadinessIntent,
            object: nil,
            userInfo: [
                "sleepHours": sleepHours,
                "energyLevel": energyLevel,
                "sorenessLevel": sorenessLevel,
                "stressLevel": stressLevel
            ]
        )
    }

    private func processRestTimerIntent(_ data: [String: Any]) {
        let seconds = data["seconds"] as? Int ?? 90

        DebugLogger.shared.info("SiriIntentService", "Processing rest timer: \(seconds) seconds")

        NotificationCenter.default.post(
            name: .siriRestTimerIntent,
            object: nil,
            userInfo: ["seconds": seconds]
        )
    }

    private func processStartWorkoutIntent(_ data: [String: Any]) {
        let workoutName = data["workoutName"] as? String

        DebugLogger.shared.info("SiriIntentService", "Processing start workout")

        NotificationCenter.default.post(
            name: .siriStartWorkoutIntent,
            object: nil,
            userInfo: workoutName != nil ? ["workoutName": workoutName!] : [:]
        )
    }

    private func processViewProgressIntent(_ data: [String: Any]) {
        DebugLogger.shared.info("SiriIntentService", "Processing view progress")

        NotificationCenter.default.post(
            name: .siriViewProgressIntent,
            object: nil,
            userInfo: [:]
        )
    }

    // MARK: - Alert Helper

    private func showAlert(message: String) {
        alertMessage = message
        showingIntentAlert = true
    }
}

// MARK: - Notification Names for Siri Intents

extension Notification.Name {
    static let siriLogExerciseIntent = Notification.Name("siriLogExerciseIntent")
    static let siriQuickLogIntent = Notification.Name("siriQuickLogIntent")
    static let siriLogReadinessIntent = Notification.Name("siriLogReadinessIntent")
    static let siriRestTimerIntent = Notification.Name("siriRestTimerIntent")
    static let siriStartWorkoutIntent = Notification.Name("siriStartWorkoutIntent")
    static let siriViewProgressIntent = Notification.Name("siriViewProgressIntent")
}

// MARK: - View Modifier for Siri Intent Handling

@available(iOS 16.0, *)
struct SiriIntentHandler: ViewModifier {
    @ObservedObject private var siriService = SiriIntentService.shared
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    siriService.checkForPendingIntents()
                }
            }
            .alert("Siri Action", isPresented: $siriService.showingIntentAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(siriService.alertMessage)
            }
    }
}

@available(iOS 16.0, *)
extension View {
    /// Add Siri intent handling to a view
    func handleSiriIntents() -> some View {
        modifier(SiriIntentHandler())
    }
}
