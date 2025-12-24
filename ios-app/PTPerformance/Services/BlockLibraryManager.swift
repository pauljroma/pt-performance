import Foundation
import Supabase

/// Manages loading and caching of training block definitions
/// Supports Baseball and Return-to-Play (RTP) block libraries
class BlockLibraryManager: ObservableObject {

    // MARK: - Published Properties
    @Published var baseballBlocks: [TrainingBlock] = []
    @Published var rtpBlocks: [TrainingBlock] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let supabase = SupabaseManager.shared.client
    private var loadedFromCache = false

    // MARK: - Singleton
    static let shared = BlockLibraryManager()

    private init() {
        loadBlockLibraries()
    }

    // MARK: - Public Methods

    /// Load both baseball and RTP block libraries
    func loadBlockLibraries() {
        guard !loadedFromCache else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Load baseball blocks
                let baseballData = try loadJSONFile(named: "baseball_blocks")
                let baseballLibrary = try JSONDecoder().decode(BlockLibrary.self, from: baseballData)

                // Load RTP blocks
                let rtpData = try loadJSONFile(named: "rtp_blocks")
                let rtpLibrary = try JSONDecoder().decode(BlockLibrary.self, from: rtpData)

                await MainActor.run {
                    self.baseballBlocks = baseballLibrary.blocks
                    self.rtpBlocks = rtpLibrary.blocks
                    self.isLoading = false
                    self.loadedFromCache = true

                    print("✅ Block libraries loaded successfully")
                    print("📊 Baseball blocks: \(self.baseballBlocks.count)")
                    print("📊 RTP blocks: \(self.rtpBlocks.count)")
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load block libraries: \(error.localizedDescription)"
                    self.isLoading = false
                    print("❌ Error loading block libraries: \(error)")
                }
            }
        }
    }

    /// Reload block libraries from disk (force refresh)
    func reloadLibraries() {
        loadedFromCache = false
        loadBlockLibraries()
    }

    /// Get a baseball block by ID
    func getBaseballBlock(id: String) -> TrainingBlock? {
        return baseballBlocks.first { $0.id == id }
    }

    /// Get an RTP block by ID
    func getRTPBlock(id: String) -> TrainingBlock? {
        return rtpBlocks.first { $0.id == id }
    }

    /// Get RTP blocks filtered by category (knee, shoulder, elbow, trunk)
    func getRTPBlocks(category: String) -> [TrainingBlock] {
        return rtpBlocks.filter { $0.category == category }
    }

    /// Get RTP blocks filtered by tier (0-5)
    func getRTPBlocks(tier: Int) -> [TrainingBlock] {
        return rtpBlocks.filter { $0.tier == tier }
    }

    /// Get baseball blocks filtered by category
    func getBaseballBlocks(category: String) -> [TrainingBlock] {
        return baseballBlocks.filter { $0.category == category }
    }

    /// Search blocks by title or description
    func searchBlocks(query: String, inLibrary library: BlockType) -> [TrainingBlock] {
        let blocks = library == .baseball ? baseballBlocks : rtpBlocks
        let lowercaseQuery = query.lowercased()

        return blocks.filter {
            $0.title.lowercased().contains(lowercaseQuery) ||
            $0.description.lowercased().contains(lowercaseQuery)
        }
    }

    // MARK: - Private Methods

    private func loadJSONFile(named filename: String) throws -> Data {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Data") else {
            throw BlockLibraryError.fileNotFound(filename)
        }

        return try Data(contentsOf: url)
    }
}

// MARK: - Supporting Types

enum BlockType {
    case baseball
    case rtp
}

enum BlockLibraryError: LocalizedError {
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Block library file not found: \(filename).json"
        }
    }
}

/// Container for block library JSON structure
struct BlockLibrary: Codable {
    let version: String
    let lastUpdated: String
    let blocks: [TrainingBlock]

    enum CodingKeys: String, CodingKey {
        case version
        case lastUpdated = "last_updated"
        case blocks
    }
}

/// Represents a single training block with exercises, criteria, and evidence
struct TrainingBlock: Codable, Identifiable {
    let id: String
    let type: String // "baseball" or "rtp"
    let category: String // e.g., "power", "knee", "shoulder"
    let tier: Int? // For RTP blocks (0-5)
    let title: String
    let description: String
    let entryCriteria: [String]?
    let exitCriteria: [String]?
    let exercises: [BlockExercise]
    let evidence: [String]
    let precautions: [String]?
    let progressions: [String]
    let trackingMetrics: [String]?
    let maintenanceExercises: [String]?

    enum CodingKeys: String, CodingKey {
        case id, type, category, tier, title, description, exercises, evidence, precautions, progressions
        case entryCriteria = "entry_criteria"
        case exitCriteria = "exit_criteria"
        case trackingMetrics = "tracking_metrics"
        case maintenanceExercises = "maintenance_exercises"
    }
}

/// Represents an individual exercise within a block
struct BlockExercise: Codable, Identifiable {
    var id: String { name } // Use name as unique identifier

    let name: String
    let sets: String
    let reps: String
    let load: String
    let tempo: String
    let rest: String
    let notes: String
}

// MARK: - Extensions

extension TrainingBlock {
    /// Get a formatted display string for tier (RTP blocks only)
    var tierDisplay: String? {
        guard let tier = tier else { return nil }
        return "Tier \(tier)"
    }

    /// Check if this is an RTP block
    var isRTPBlock: Bool {
        return type == "rtp"
    }

    /// Check if this is a baseball block
    var isBaseballBlock: Bool {
        return type == "baseball"
    }

    /// Get total number of exercises in this block
    var exerciseCount: Int {
        return exercises.count
    }

    /// Get formatted evidence citations
    var evidenceSummary: String {
        guard !evidence.isEmpty else { return "No evidence available" }
        return evidence.joined(separator: "\n\n")
    }

    /// Get formatted entry criteria list
    var entryCriteriaSummary: String? {
        guard let criteria = entryCriteria, !criteria.isEmpty else { return nil }
        return criteria.map { "• \($0)" }.joined(separator: "\n")
    }

    /// Get formatted exit criteria list
    var exitCriteriaSummary: String? {
        guard let criteria = exitCriteria, !criteria.isEmpty else { return nil }
        return criteria.map { "• \($0)" }.joined(separator: "\n")
    }

    /// Get formatted precautions list
    var precautionsSummary: String? {
        guard let precautions = precautions, !precautions.isEmpty else { return nil }
        return precautions.map { "⚠️ \($0)" }.joined(separator: "\n")
    }

    /// Get formatted progressions list
    var progressionsSummary: String {
        guard !progressions.isEmpty else { return "No progressions defined" }
        return progressions.map { "→ \($0)" }.joined(separator: "\n")
    }
}

extension BlockExercise {
    /// Get a formatted display string for the exercise prescription
    var prescription: String {
        var parts: [String] = []

        if sets != "N/A" && !sets.isEmpty {
            parts.append("\(sets) sets")
        }

        if reps != "N/A" && !reps.isEmpty {
            parts.append("\(reps) reps")
        }

        if load != "N/A" && load != "Bodyweight" && !load.isEmpty {
            parts.append("@ \(load)")
        }

        return parts.joined(separator: " × ")
    }

    /// Get formatted tempo display
    var tempoDisplay: String {
        guard tempo != "N/A" && !tempo.isEmpty else { return "" }
        return "Tempo: \(tempo)"
    }

    /// Get formatted rest display
    var restDisplay: String {
        guard rest != "N/A" && !rest.isEmpty else { return "" }
        return "Rest: \(rest)"
    }
}

// MARK: - Mock Data for Previews

extension TrainingBlock {
    static var mockBaseballBlock: TrainingBlock {
        TrainingBlock(
            id: "baseball_rotation_power",
            type: "baseball",
            category: "power",
            tier: nil,
            title: "Rotation Power",
            description: "Develop rotational power through medicine ball throws and explosive rotational movements.",
            entryCriteria: [
                "Pain-free trunk rotation",
                "Adequate hip mobility (>45° internal rotation)",
                "Stable base strength established"
            ],
            exitCriteria: [
                "Rotational power output >85% baseline",
                "Symmetrical power production L/R",
                "Pain-free execution at max effort"
            ],
            exercises: [
                BlockExercise(
                    name: "Med Ball Scoop Toss",
                    sets: "3-4",
                    reps: "6-8",
                    load: "6-10 lb",
                    tempo: "Explosive",
                    rest: "90-120s",
                    notes: "Focus on hip-driven rotation"
                ),
                BlockExercise(
                    name: "Med Ball Rotational Throw",
                    sets: "3-4",
                    reps: "6-8 each side",
                    load: "8-12 lb",
                    tempo: "Explosive",
                    rest: "90-120s",
                    notes: "Maintain stable base"
                )
            ],
            evidence: [
                "Szymanski DJ, et al. Effect of torso rotational strength on angular hip, angular shoulder, and linear bat velocities of high school baseball players. J Strength Cond Res. 2009;23(6):1681-1687."
            ],
            precautions: nil,
            progressions: [
                "Increase load 2-3 lb when maintaining velocity",
                "Increase volume by 1 set per week"
            ],
            trackingMetrics: nil,
            maintenanceExercises: nil
        )
    }

    static var mockRTPBlock: TrainingBlock {
        TrainingBlock(
            id: "rtp_knee_tier2",
            type: "rtp",
            category: "knee",
            tier: 2,
            title: "Knee RTP - Tier 2: Strength & Neuromuscular Control",
            description: "Develop strength >80% of uninvolved limb, introduce controlled dynamic movements.",
            entryCriteria: [
                "Tier 1 criteria met",
                "Full ROM (0-135°)",
                "Quad strength >60% uninvolved"
            ],
            exitCriteria: [
                "Quad strength >80% uninvolved",
                "Single-leg squat depth >60° with good form",
                "Y-Balance Test >90% composite"
            ],
            exercises: [
                BlockExercise(
                    name: "Bulgarian Split Squat",
                    sets: "3",
                    reps: "8-12 each leg",
                    load: "Bodyweight to light DBs",
                    tempo: "3010",
                    rest: "90s",
                    notes: "Address strength asymmetries"
                ),
                BlockExercise(
                    name: "Single-Leg Leg Press",
                    sets: "3",
                    reps: "10-12 each leg",
                    load: "Moderate",
                    tempo: "3010",
                    rest: "90s",
                    notes: "Build unilateral strength"
                )
            ],
            evidence: [
                "Hewett TE, et al. Biomechanical measures of neuromuscular control and valgus loading of the knee predict anterior cruciate ligament injury risk. Am J Sports Med. 2005;33(4):492-501."
            ],
            precautions: [
                "Monitor for knee valgus during single-leg tasks",
                "Avoid ballistic movements or jumping",
                "Control swelling - ice as needed"
            ],
            progressions: [
                "Increase external load by 5-10% weekly",
                "Progress to unstable surface variations"
            ],
            trackingMetrics: nil,
            maintenanceExercises: nil
        )
    }
}
