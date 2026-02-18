import AppIntents
import Foundation

/// Siri Intent to check today's readiness score
/// Phrase: "Hey Siri, check my readiness in Modus"
@available(iOS 16.0, *)
struct CheckReadinessIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Readiness"
    static var description = IntentDescription("Check your readiness score for today")

    /// Optionally open the app to show full readiness details
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        DebugLogger.shared.log("[CheckReadinessIntent] Checking readiness via Siri", level: .diagnostic)

        // Try to get cached readiness score from UserDefaults (set by WidgetBridgeService)
        let defaults = UserDefaults(suiteName: "group.com.getmodus.app") ?? UserDefaults.standard

        if let readinessData = defaults.data(forKey: "cachedReadinessScore"),
           let decoded = try? JSONDecoder().decode(CachedReadiness.self, from: readinessData) {

            let score = decoded.score
            let recommendation = getReadinessRecommendation(score: score)

            return .result(
                dialog: IntentDialog(stringLiteral: "Your readiness score is \(score). \(recommendation)")
            )
        }

        // No cached score available
        return .result(
            dialog: "I don't have your readiness score yet. Open Modus to complete your daily check-in."
        )
    }

    /// Get workout recommendation based on readiness score
    private func getReadinessRecommendation(score: Int) -> String {
        switch score {
        case 90...100:
            return "You're in peak condition! Perfect day for intense training."
        case 75..<90:
            return "You're ready to train! Go for your planned workout."
        case 60..<75:
            return "Moderate readiness. Consider a lighter session today."
        case 40..<60:
            return "Low readiness. Focus on recovery or light mobility work."
        default:
            return "Very low readiness. Rest and recovery recommended."
        }
    }
}

// MARK: - Log Readiness Intent

/// Siri Intent to log readiness check-in
/// Phrase: "Hey Siri, log my readiness in Modus"
@available(iOS 16.0, *)
struct LogReadinessIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Readiness"
    static var description = IntentDescription("Log your daily readiness check-in")

    @Parameter(title: "Sleep Hours", default: 7)
    var sleepHours: Int

    @Parameter(title: "Energy Level (1-10)", default: 7)
    var energyLevel: Int

    @Parameter(title: "Soreness Level (1-10)", default: 3)
    var sorenessLevel: Int

    @Parameter(title: "Stress Level (1-10)", default: 3)
    var stressLevel: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Log readiness with \(\.$sleepHours) hours sleep") {
            \.$energyLevel
            \.$sorenessLevel
            \.$stressLevel
        }
    }

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        DebugLogger.shared.log("[LogReadinessIntent] Logging readiness via Siri", level: .diagnostic)

        // Validate inputs
        guard sleepHours >= 0, sleepHours <= 24 else {
            return .result(dialog: "Please specify sleep hours between 0 and 24.")
        }

        guard energyLevel >= 1, energyLevel <= 10 else {
            return .result(dialog: "Please specify energy level between 1 and 10.")
        }

        guard sorenessLevel >= 1, sorenessLevel <= 10 else {
            return .result(dialog: "Please specify soreness level between 1 and 10.")
        }

        guard stressLevel >= 1, stressLevel <= 10 else {
            return .result(dialog: "Please specify stress level between 1 and 10.")
        }

        // Calculate approximate readiness score
        // This is a simplified version - the actual calculation happens in the database
        let sleepScore = Double(min(sleepHours, 8)) * 12.5 // Max 100 from 8 hours
        let energyScore = Double(energyLevel) * 10
        let sorenessScore = Double(11 - sorenessLevel) * 10 // Inverse scale
        let stressScore = Double(11 - stressLevel) * 10 // Inverse scale

        let approximateScore = Int((sleepScore + energyScore + sorenessScore + stressScore) / 4)

        // Store for app to process
        let intentData: [String: Any] = [
            "type": "logReadiness",
            "sleepHours": sleepHours,
            "energyLevel": energyLevel,
            "sorenessLevel": sorenessLevel,
            "stressLevel": stressLevel,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let encoded = try? JSONSerialization.data(withJSONObject: intentData) {
            UserDefaults.standard.set(encoded, forKey: "pendingSiriIntent")
        }

        let recommendation = getReadinessRecommendation(score: approximateScore)

        return .result(
            dialog: IntentDialog(stringLiteral: "Logged your readiness check-in. Estimated score: \(approximateScore). \(recommendation)")
        )
    }

    private func getReadinessRecommendation(score: Int) -> String {
        switch score {
        case 80...100:
            return "Great day to train hard!"
        case 60..<80:
            return "Ready for a normal workout."
        case 40..<60:
            return "Consider taking it easy today."
        default:
            return "Focus on rest and recovery."
        }
    }
}

// MARK: - Cached Readiness Model

struct CachedReadiness: Codable {
    let score: Int
    let date: Date
    let sleepHours: Double?
    let energyLevel: Int?
    let sorenessLevel: Int?
    let stressLevel: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.score = (try? container.decode(Int.self, forKey: .score)) ?? 0
        self.date = (try? container.decodeIfPresent(Double.self, forKey: .date))
            .map { Date(timeIntervalSinceReferenceDate: $0) } ?? Date()
        self.sleepHours = try? container.decodeIfPresent(Double.self, forKey: .sleepHours)
        self.energyLevel = try? container.decodeIfPresent(Int.self, forKey: .energyLevel)
        self.sorenessLevel = try? container.decodeIfPresent(Int.self, forKey: .sorenessLevel)
        self.stressLevel = try? container.decodeIfPresent(Int.self, forKey: .stressLevel)
    }

    init(score: Int, date: Date, sleepHours: Double?, energyLevel: Int?, sorenessLevel: Int?, stressLevel: Int?) {
        self.score = score
        self.date = date
        self.sleepHours = sleepHours
        self.energyLevel = energyLevel
        self.sorenessLevel = sorenessLevel
        self.stressLevel = stressLevel
    }
}
