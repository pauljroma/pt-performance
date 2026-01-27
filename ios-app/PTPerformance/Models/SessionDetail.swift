import Foundation

// MARK: - BUILD 296: Session Detail Models (ACP-588)

/// Session with its exercise logs — used by detail view and export
struct SessionWithLogs: Identifiable {
    let id: String
    let sessionNumber: Int?
    let sessionDate: Date
    let completed: Bool
    let notes: String?
    let totalVolume: Double?
    let avgRpe: Double?
    let avgPainScore: Double?
    let durationMinutes: Int?
    let exerciseLogs: [ExerciseLogDetail]
}

/// Individual exercise log with exercise name (fetched via join)
struct ExerciseLogDetail: Identifiable, Codable, Hashable {
    let id: String
    let exerciseName: String
    let actualSets: Int
    let actualReps: [Int]
    let actualLoad: Double?
    let loadUnit: String?
    let rpe: Int
    let painScore: Int
    let notes: String?
    let loggedAt: Date
    let exerciseTemplateId: String?
    let videoUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseName = "exercise_name"
        case actualSets = "actual_sets"
        case actualReps = "actual_reps"
        case actualLoad = "actual_load"
        case loadUnit = "load_unit"
        case rpe
        case painScore = "pain_score"
        case notes
        case loggedAt = "logged_at"
        case exerciseTemplateId = "exercise_template_id"
        case videoUrl = "video_url"
    }

    // MARK: - Display Helpers

    var repsDisplay: String {
        if actualReps.isEmpty { return "0" }
        let unique = Set(actualReps)
        if unique.count == 1 {
            return "\(actualReps[0])"
        }
        return actualReps.map { String($0) }.joined(separator: "/")
    }

    var loadDisplay: String {
        guard let load = actualLoad else { return "BW" }
        let unit = loadUnit ?? "lbs"
        if load == floor(load) {
            return "\(Int(load)) \(unit)"
        }
        return String(format: "%.1f %@", load, unit)
    }

    var hasVideo: Bool {
        videoUrl != nil
    }
}
