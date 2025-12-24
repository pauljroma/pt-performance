import Foundation
import SwiftUI

/// Represents a training block within a session (e.g., Warm-up, Main Work, Accessories)
struct Block: Codable, Identifiable, Hashable {
    let id: UUID
    let sessionId: UUID
    let blockType: BlockType
    let title: String
    let orderIndex: Int
    var items: [BlockItem]
    var isCompleted: Bool
    var completedAt: Date?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case blockType = "block_type"
        case title
        case orderIndex = "order_index"
        case items
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case notes
    }

    init(id: UUID = UUID(), sessionId: UUID, blockType: BlockType, title: String, orderIndex: Int, items: [BlockItem] = [], isCompleted: Bool = false, completedAt: Date? = nil, notes: String? = nil) {
        self.id = id
        self.sessionId = sessionId
        self.blockType = blockType
        self.title = title
        self.orderIndex = orderIndex
        self.items = items
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.notes = notes
    }

    /// Progress percentage (0.0 to 1.0)
    var progress: Double {
        guard !items.isEmpty else { return 0.0 }
        let completedItems = items.filter { $0.isCompleted }.count
        return Double(completedItems) / Double(items.count)
    }

    /// Total completed sets across all items
    var completedSets: Int {
        items.reduce(0) { $0 + $1.completedSets.count }
    }

    /// Total prescribed sets across all items
    var totalSets: Int {
        items.reduce(0) { $0 + $1.prescribedSets }
    }

    /// Estimated time in minutes
    var estimatedTimeMinutes: Int {
        items.reduce(0) { $0 + $1.estimatedTimeMinutes }
    }

    /// Check if any items have pain flags
    var hasPainFlags: Bool {
        items.contains { item in
            item.completedSets.contains { $0.painLevel != nil && $0.painLevel! > 0 }
        }
    }

    /// Complete all items as prescribed (1-tap completion)
    mutating func completeAsPrescribed() {
        for index in items.indices {
            items[index].completeAsPrescribed()
        }
        isCompleted = true
        completedAt = Date()
    }
}

// MARK: - Block Type

enum BlockType: String, Codable, CaseIterable, Identifiable {
    case warmup = "warmup"
    case mainWork = "main_work"
    case accessories = "accessories"
    case cooldown = "cooldown"
    case conditioning = "conditioning"
    case skillWork = "skill_work"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .warmup: return "Warm-up"
        case .mainWork: return "Main Work"
        case .accessories: return "Accessories"
        case .cooldown: return "Cool-down"
        case .conditioning: return "Conditioning"
        case .skillWork: return "Skill Work"
        }
    }

    var icon: String {
        switch self {
        case .warmup: return "flame.fill"
        case .mainWork: return "bolt.fill"
        case .accessories: return "dumbbell.fill"
        case .cooldown: return "wind"
        case .conditioning: return "heart.fill"
        case .skillWork: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .warmup: return .orange
        case .mainWork: return .blue
        case .accessories: return .purple
        case .cooldown: return .cyan
        case .conditioning: return .red
        case .skillWork: return .yellow
        }
    }

    var backgroundColor: Color {
        switch self {
        case .warmup: return Color.orange.opacity(0.1)
        case .mainWork: return Color.blue.opacity(0.1)
        case .accessories: return Color.purple.opacity(0.1)
        case .cooldown: return Color.cyan.opacity(0.1)
        case .conditioning: return Color.red.opacity(0.1)
        case .skillWork: return Color.yellow.opacity(0.1)
        }
    }
}
