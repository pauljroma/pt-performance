import Foundation
import SwiftUI

@MainActor
final class RecoveryViewModel: ObservableObject {
    @Published var sessions: [RecoverySession] = []
    @Published var recommendations: [RecoveryRecommendation] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showingLogSheet = false
    @Published var selectedProtocol: RecoveryProtocolType = .sauna

    // Log session form
    @Published var logDuration: Int = 15
    @Published var logTemperature: Double?
    @Published var logHeartRate: Int?
    @Published var logEffort: Int = 5
    @Published var logNotes: String = ""

    private let service = RecoveryService.shared

    func loadData() async {
        isLoading = true
        error = nil
        await service.fetchSessions()
        await service.generateRecommendations()
        sessions = service.sessions
        recommendations = service.recommendations
        if let serviceError = service.error {
            error = serviceError.localizedDescription
        }
        isLoading = false
    }

    func logSession() async {
        do {
            try await service.logSession(
                protocolType: selectedProtocol,
                duration: logDuration * 60, // Convert to seconds
                temperature: logTemperature,
                heartRateAvg: logHeartRate,
                perceivedEffort: logEffort,
                notes: logNotes.isEmpty ? nil : logNotes
            )
            resetForm()
            showingLogSheet = false
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func resetForm() {
        logDuration = 15
        logTemperature = nil
        logHeartRate = nil
        logEffort = 5
        logNotes = ""
    }

    // MARK: - Computed Properties

    var weeklyStats: (sessions: Int, minutes: Int, favorite: RecoveryProtocolType?) {
        let stats = service.weeklyStats()
        return (sessions: stats.totalSessions, minutes: stats.totalMinutes, favorite: stats.favoriteProtocol)
    }

    var todaySessions: [RecoverySession] {
        sessions.filter { Calendar.current.isDateInToday($0.startTime) }
    }

    var thisWeekSessions: [RecoverySession] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.startTime >= weekAgo }
    }

    func sessionsForProtocol(_ type: RecoveryProtocolType) -> [RecoverySession] {
        sessions.filter { $0.protocolType == type }
    }
}
