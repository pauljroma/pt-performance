import Foundation
import SwiftUI

// Note: Requires Color+Modus extension for brand colors

// MARK: - Journal Entry Model

/// Represents a single audio health journal entry with transcription
struct JournalEntry: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let date: Date
    var audioURL: URL?
    var transcription: String
    var mood: Mood
    var tags: [Tag]
    var duration: TimeInterval // Duration of audio recording in seconds

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        audioURL: URL? = nil,
        transcription: String = "",
        mood: Mood = .neutral,
        tags: [Tag] = [],
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.date = date
        self.audioURL = audioURL
        self.transcription = transcription
        self.mood = mood
        self.tags = tags
        self.duration = duration
    }

    // MARK: - Mood

    enum Mood: String, Codable, CaseIterable {
        case great
        case good
        case neutral
        case tired
        case bad

        var emoji: String {
            switch self {
            case .great: return "😄"
            case .good: return "🙂"
            case .neutral: return "😐"
            case .tired: return "😴"
            case .bad: return "😔"
            }
        }

        var displayName: String {
            switch self {
            case .great: return "Great"
            case .good: return "Good"
            case .neutral: return "Neutral"
            case .tired: return "Tired"
            case .bad: return "Bad"
            }
        }

        var color: Color {
            switch self {
            case .great: return .green
            case .good: return .modusTealAccent
            case .neutral: return .gray
            case .tired: return .orange
            case .bad: return .red
            }
        }
    }

    // MARK: - Tag

    enum Tag: String, Codable, CaseIterable, Identifiable {
        case sleep
        case energy
        case pain
        case stress
        case nutrition
        case recovery
        case training
        case custom

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .sleep: return "Sleep"
            case .energy: return "Energy"
            case .pain: return "Pain"
            case .stress: return "Stress"
            case .nutrition: return "Nutrition"
            case .recovery: return "Recovery"
            case .training: return "Training"
            case .custom: return "Custom"
            }
        }

        var icon: String {
            switch self {
            case .sleep: return "bed.double.fill"
            case .energy: return "bolt.fill"
            case .pain: return "bandage.fill"
            case .stress: return "brain.head.profile"
            case .nutrition: return "fork.knife"
            case .recovery: return "heart.fill"
            case .training: return "figure.strengthtraining.traditional"
            case .custom: return "tag.fill"
            }
        }

        var color: Color {
            switch self {
            case .sleep: return .indigo
            case .energy: return .yellow
            case .pain: return .red
            case .stress: return .purple
            case .nutrition: return .green
            case .recovery: return .modusTealAccent
            case .training: return .modusCyan
            case .custom: return .gray
            }
        }
    }

    // MARK: - Computed Properties

    /// Preview text for list display (first 100 characters)
    var preview: String {
        let maxLength = 100
        if transcription.count <= maxLength {
            return transcription
        }
        let preview = String(transcription.prefix(maxLength))
        return preview + "..."
    }

    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Formatted duration string
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

// MARK: - Custom Tag Model

/// Custom tag with user-defined name
struct CustomTag: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
