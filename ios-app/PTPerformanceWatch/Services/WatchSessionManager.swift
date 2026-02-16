//
//  WatchSessionManager.swift
//  PTPerformanceWatch
//
//  WatchConnectivity manager for syncing with iPhone
//  ACP-824: Apple Watch Standalone App
//

import Foundation
import WatchConnectivity
import Combine

/// Manages Watch-iPhone connectivity and data synchronization
@MainActor
class WatchSessionManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = WatchSessionManager()

    // MARK: - Published Properties

    @Published var isReachable = false
    @Published var isPaired = false
    @Published var isWatchAppInstalled = false
    @Published var lastSyncDate: Date?
    @Published var pendingSyncCount = 0

    // MARK: - Private Properties

    private let session: WCSession
    private var pendingMessages: [WatchSyncMessage] = []
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // Storage for offline queue
    private let offlineQueueKey = "PTPerformance.WatchOfflineQueue"

    // MARK: - Callbacks

    var onWorkoutDataReceived: ((WatchWorkoutSession) -> Void)?
    var onSyncCompleted: (() -> Void)?

    // MARK: - Initialization

    override init() {
        session = WCSession.default
        super.init()
        loadPendingMessages()
    }

    // MARK: - Session Activation

    func activateSession() {
        guard WCSession.isSupported() else {
            #if DEBUG
            print("WatchConnectivity is not supported")
            #endif
            return
        }

        session.delegate = self
        session.activate()
    }

    // MARK: - Sending Messages

    /// Send a message to the iPhone app (requires reachability)
    func sendMessage(_ message: WatchSyncMessage, replyHandler: (([String: Any]) -> Void)? = nil) {
        guard session.isReachable else {
            // Queue for later if not reachable
            queueMessage(message)
            return
        }

        do {
            let data = try encoder.encode(message)
            let messageDict: [String: Any] = [
                "type": message.type.rawValue,
                "payload": data,
                "timestamp": message.timestamp.timeIntervalSince1970
            ]

            session.sendMessage(messageDict, replyHandler: replyHandler) { [weak self] error in
                #if DEBUG
                print("Failed to send message: \(error.localizedDescription)")
                #endif
                // Queue for retry
                Task { @MainActor in
                    self?.queueMessage(message)
                }
            }
        } catch {
            #if DEBUG
            print("Failed to encode message: \(error.localizedDescription)")
            #endif
        }
    }

    /// Send logged set to iPhone for sync
    func sendLoggedSet(_ set: WatchCompletedSet, exerciseId: UUID, sessionId: UUID) {
        let payload = SetLogPayload(set: set, exerciseId: exerciseId, sessionId: sessionId)

        do {
            let payloadData = try encoder.encode(payload)
            let message = WatchSyncMessage(type: .setLogged, payload: payloadData)
            sendMessage(message)
        } catch {
            #if DEBUG
            print("Failed to encode set log: \(error.localizedDescription)")
            #endif
        }
    }

    /// Send workout completion to iPhone
    func sendWorkoutCompleted(_ sessionId: UUID) {
        let payload = WorkoutCompletedPayload(sessionId: sessionId, completedAt: Date())

        do {
            let payloadData = try encoder.encode(payload)
            let message = WatchSyncMessage(type: .workoutCompleted, payload: payloadData)
            sendMessage(message)
        } catch {
            #if DEBUG
            print("Failed to encode workout completion: \(error.localizedDescription)")
            #endif
        }
    }

    /// Request workout data sync from iPhone
    func requestSync() {
        let message = WatchSyncMessage(
            type: .requestSync,
            payload: Data()
        )

        sendMessage(message) { [weak self] reply in
            Task { @MainActor in
                self?.handleSyncReply(reply)
            }
        }
    }

    // MARK: - Offline Queue Management

    private func queueMessage(_ message: WatchSyncMessage) {
        pendingMessages.append(message)
        pendingSyncCount = pendingMessages.count
        savePendingMessages()
    }

    private func savePendingMessages() {
        do {
            let data = try encoder.encode(pendingMessages)
            UserDefaults.standard.set(data, forKey: offlineQueueKey)
        } catch {
            #if DEBUG
            print("Failed to save pending messages: \(error.localizedDescription)")
            #endif
        }
    }

    private func loadPendingMessages() {
        guard let data = UserDefaults.standard.data(forKey: offlineQueueKey) else { return }

        do {
            pendingMessages = try decoder.decode([WatchSyncMessage].self, from: data)
            pendingSyncCount = pendingMessages.count
        } catch {
            #if DEBUG
            print("Failed to load pending messages: \(error.localizedDescription)")
            #endif
        }
    }

    /// Flush pending messages when connection becomes available
    func flushPendingMessages() {
        guard session.isReachable else { return }

        let messagesToSend = pendingMessages
        pendingMessages = []
        pendingSyncCount = 0
        savePendingMessages()

        for message in messagesToSend {
            sendMessage(message)
        }
    }

    // MARK: - Reply Handling

    private func handleSyncReply(_ reply: [String: Any]) {
        guard let typeString = reply["type"] as? String,
              let type = WatchSyncMessageType(rawValue: typeString) else {
            return
        }

        switch type {
        case .workoutData:
            if let data = reply["payload"] as? Data {
                do {
                    let session = try decoder.decode(WatchWorkoutSession.self, from: data)
                    onWorkoutDataReceived?(session)
                } catch {
                    #if DEBUG
                    print("Failed to decode workout data: \(error.localizedDescription)")
                    #endif
                }
            }

        case .syncAcknowledged:
            lastSyncDate = Date()
            onSyncCompleted?()

        default:
            break
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                #if DEBUG
                print("WCSession activation failed: \(error.localizedDescription)")
                #endif
                return
            }

            self.isReachable = session.isReachable

            #if os(iOS)
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            #endif

            // Flush any pending messages
            if session.isReachable {
                self.flushPendingMessages()
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable

            if session.isReachable {
                self.flushPendingMessages()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.handleReceivedMessage(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            self.handleReceivedMessage(message)
            replyHandler(["status": "received"])
        }
    }

    @MainActor
    private func handleReceivedMessage(_ message: [String: Any]) {
        guard let typeString = message["type"] as? String,
              let type = WatchSyncMessageType(rawValue: typeString),
              let payloadData = message["payload"] as? Data else {
            return
        }

        switch type {
        case .workoutData:
            do {
                let session = try decoder.decode(WatchWorkoutSession.self, from: payloadData)
                onWorkoutDataReceived?(session)
            } catch {
                #if DEBUG
                print("Failed to decode workout data: \(error.localizedDescription)")
                #endif
            }

        case .syncAcknowledged:
            lastSyncDate = Date()
            onSyncCompleted?()

        default:
            break
        }
    }

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session on iOS
        session.activate()
    }
    #endif
}

// MARK: - Payload Types

struct SetLogPayload: Codable {
    let set: WatchCompletedSet
    let exerciseId: UUID
    let sessionId: UUID
}

struct WorkoutCompletedPayload: Codable {
    let sessionId: UUID
    let completedAt: Date
}
