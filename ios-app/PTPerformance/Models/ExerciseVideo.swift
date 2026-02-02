//
//  ExerciseVideo.swift
//  PTPerformance
//
//  ACP-813: HD Video Exercise Demos - Multi-angle video support
//  Created for Build with exercise video demo capabilities
//

import Foundation

/// Exercise video model supporting multi-angle HD video demonstrations
struct ExerciseVideo: Identifiable, Codable, Hashable {
    let id: UUID
    let exerciseId: UUID
    let videoUrl: String
    let thumbnailUrl: String?
    let angle: VideoAngle
    let durationSeconds: Int?
    let fileSizeBytes: Int64?
    let resolution: VideoResolution
    let isPrimary: Bool
    let supportsSlowMotion: Bool
    let contentHash: String?

    // MARK: - Video Angle

    enum VideoAngle: String, Codable, CaseIterable, Hashable {
        case front
        case side
        case back
        case detail

        var displayName: String {
            switch self {
            case .front: return "Front View"
            case .side: return "Side View"
            case .back: return "Back View"
            case .detail: return "Detail View"
            }
        }

        var iconName: String {
            switch self {
            case .front: return "person.fill"
            case .side: return "person.fill.turn.right"
            case .back: return "person.fill.turn.left"
            case .detail: return "magnifyingglass"
            }
        }

        var sortOrder: Int {
            switch self {
            case .front: return 1
            case .side: return 2
            case .back: return 3
            case .detail: return 4
            }
        }
    }

    // MARK: - Video Resolution

    enum VideoResolution: String, Codable, Hashable {
        case hd720p = "720p"
        case hd1080p = "1080p"
        case uhd4k = "4k"

        var displayName: String {
            switch self {
            case .hd720p: return "720p HD"
            case .hd1080p: return "1080p Full HD"
            case .uhd4k: return "4K UHD"
            }
        }

        var estimatedBitrate: Int {
            switch self {
            case .hd720p: return 3_000_000   // 3 Mbps
            case .hd1080p: return 6_000_000  // 6 Mbps
            case .uhd4k: return 15_000_000   // 15 Mbps
            }
        }
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseId = "exercise_id"
        case videoUrl = "video_url"
        case thumbnailUrl = "thumbnail_url"
        case angle
        case durationSeconds = "duration_seconds"
        case fileSizeBytes = "file_size_bytes"
        case resolution
        case isPrimary = "is_primary"
        case supportsSlowMotion = "supports_slow_motion"
        case contentHash = "content_hash"
    }

    // MARK: - Alternative CodingKeys for JSON response

    /// Alternative coding keys for view response format
    enum AlternativeCodingKeys: String, CodingKey {
        case id
        case exerciseId = "exerciseId"
        case videoUrl = "url"
        case thumbnailUrl = "thumbnail"
        case angle
        case durationSeconds = "duration"
        case fileSizeBytes = "fileSize"
        case resolution
        case isPrimary = "isPrimary"
        case supportsSlowMotion = "supportsSlowMotion"
        case contentHash = "contentHash"
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        // Try standard keys first
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            id = try container.decode(UUID.self, forKey: .id)
            exerciseId = try container.decode(UUID.self, forKey: .exerciseId)
            videoUrl = try container.decode(String.self, forKey: .videoUrl)
            thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
            angle = try container.decode(VideoAngle.self, forKey: .angle)
            durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
            fileSizeBytes = try container.decodeIfPresent(Int64.self, forKey: .fileSizeBytes)
            resolution = try container.decodeIfPresent(VideoResolution.self, forKey: .resolution) ?? .hd1080p
            isPrimary = try container.decodeIfPresent(Bool.self, forKey: .isPrimary) ?? false
            supportsSlowMotion = try container.decodeIfPresent(Bool.self, forKey: .supportsSlowMotion) ?? true
            contentHash = try container.decodeIfPresent(String.self, forKey: .contentHash)
        } else {
            // Try alternative keys (from view response)
            let container = try decoder.container(keyedBy: AlternativeCodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            exerciseId = try container.decodeIfPresent(UUID.self, forKey: .exerciseId) ?? UUID()
            videoUrl = try container.decode(String.self, forKey: .videoUrl)
            thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
            angle = try container.decode(VideoAngle.self, forKey: .angle)
            durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
            fileSizeBytes = try container.decodeIfPresent(Int64.self, forKey: .fileSizeBytes)
            resolution = try container.decodeIfPresent(VideoResolution.self, forKey: .resolution) ?? .hd1080p
            isPrimary = try container.decodeIfPresent(Bool.self, forKey: .isPrimary) ?? false
            supportsSlowMotion = try container.decodeIfPresent(Bool.self, forKey: .supportsSlowMotion) ?? true
            contentHash = try container.decodeIfPresent(String.self, forKey: .contentHash)
        }
    }

    // MARK: - Initializer

    init(
        id: UUID,
        exerciseId: UUID,
        videoUrl: String,
        thumbnailUrl: String? = nil,
        angle: VideoAngle,
        durationSeconds: Int? = nil,
        fileSizeBytes: Int64? = nil,
        resolution: VideoResolution = .hd1080p,
        isPrimary: Bool = false,
        supportsSlowMotion: Bool = true,
        contentHash: String? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.videoUrl = videoUrl
        self.thumbnailUrl = thumbnailUrl
        self.angle = angle
        self.durationSeconds = durationSeconds
        self.fileSizeBytes = fileSizeBytes
        self.resolution = resolution
        self.isPrimary = isPrimary
        self.supportsSlowMotion = supportsSlowMotion
        self.contentHash = contentHash
    }

    // MARK: - Computed Properties

    /// Video URL as Foundation URL
    var url: URL? {
        URL(string: videoUrl)
    }

    /// Thumbnail URL as Foundation URL
    var thumbnail: URL? {
        thumbnailUrl.flatMap { URL(string: $0) }
    }

    /// Formatted duration string (e.g., "1:30")
    var durationDisplay: String? {
        guard let duration = durationSeconds else { return nil }
        let minutes = duration / 60
        let seconds = duration % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }

    /// Formatted file size string (e.g., "25 MB")
    var fileSizeDisplay: String? {
        guard let bytes = fileSizeBytes else { return nil }
        let megabytes = Double(bytes) / 1_000_000
        if megabytes >= 1000 {
            return String(format: "%.1f GB", megabytes / 1000)
        } else if megabytes >= 1 {
            return String(format: "%.0f MB", megabytes)
        } else {
            return String(format: "%.0f KB", Double(bytes) / 1000)
        }
    }

    /// Estimated download time at 5 Mbps
    var estimatedDownloadTime: String? {
        guard let bytes = fileSizeBytes else { return nil }
        let seconds = Double(bytes * 8) / 5_000_000 // 5 Mbps
        if seconds < 60 {
            return String(format: "~%.0f sec", max(1, seconds))
        } else {
            return String(format: "~%.0f min", seconds / 60)
        }
    }

    // MARK: - Sample Data

    static let sample = ExerciseVideo(
        id: UUID(),
        exerciseId: UUID(),
        videoUrl: "https://storage.ptperformance.com/videos/squat-front-1080p.mp4",
        thumbnailUrl: "https://storage.ptperformance.com/thumbnails/squat-front.jpg",
        angle: .front,
        durationSeconds: 45,
        fileSizeBytes: 25_000_000,
        resolution: .hd1080p,
        isPrimary: true,
        supportsSlowMotion: true,
        contentHash: "abc123"
    )

    static let sampleVideos: [ExerciseVideo] = [
        ExerciseVideo(
            id: UUID(),
            exerciseId: UUID(),
            videoUrl: "https://storage.ptperformance.com/videos/squat-front-1080p.mp4",
            thumbnailUrl: "https://storage.ptperformance.com/thumbnails/squat-front.jpg",
            angle: .front,
            durationSeconds: 45,
            fileSizeBytes: 25_000_000,
            resolution: .hd1080p,
            isPrimary: true
        ),
        ExerciseVideo(
            id: UUID(),
            exerciseId: UUID(),
            videoUrl: "https://storage.ptperformance.com/videos/squat-side-1080p.mp4",
            thumbnailUrl: "https://storage.ptperformance.com/thumbnails/squat-side.jpg",
            angle: .side,
            durationSeconds: 45,
            fileSizeBytes: 24_500_000,
            resolution: .hd1080p,
            isPrimary: false
        ),
        ExerciseVideo(
            id: UUID(),
            exerciseId: UUID(),
            videoUrl: "https://storage.ptperformance.com/videos/squat-back-1080p.mp4",
            thumbnailUrl: "https://storage.ptperformance.com/thumbnails/squat-back.jpg",
            angle: .back,
            durationSeconds: 45,
            fileSizeBytes: 23_000_000,
            resolution: .hd1080p,
            isPrimary: false
        )
    ]
}

// MARK: - Exercise Videos Collection

/// Container for exercise videos grouped by angle
struct ExerciseVideoCollection: Codable {
    let exerciseId: UUID
    let exerciseName: String
    let videos: [ExerciseVideo]
    let primaryVideo: ExerciseVideo?

    /// Videos grouped by angle
    var videosByAngle: [ExerciseVideo.VideoAngle: ExerciseVideo] {
        Dictionary(uniqueKeysWithValues: videos.map { ($0.angle, $0) })
    }

    /// Available angles
    var availableAngles: [ExerciseVideo.VideoAngle] {
        videos.map(\.angle).sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Total file size of all videos
    var totalFileSize: Int64 {
        videos.compactMap(\.fileSizeBytes).reduce(0, +)
    }

    /// Total file size display string
    var totalFileSizeDisplay: String {
        let megabytes = Double(totalFileSize) / 1_000_000
        if megabytes >= 1000 {
            return String(format: "%.1f GB", megabytes / 1000)
        } else {
            return String(format: "%.0f MB", megabytes)
        }
    }
}

// MARK: - Video Cache Info

/// Information about a cached video
struct VideoCacheInfo: Codable {
    let videoId: UUID
    let videoUrl: String
    let cachedAt: Date
    let cacheSizeBytes: Int64
    let contentHash: String?
    let localPath: String

    var isStale: Bool {
        // Consider cache stale after 7 days
        let staleDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return cachedAt < staleDate
    }
}

// MARK: - Playback Speed

/// Playback speed options for slow-motion review
enum PlaybackSpeed: Float, CaseIterable, Identifiable {
    case quarter = 0.25
    case half = 0.5
    case threeQuarter = 0.75
    case normal = 1.0
    case oneAndQuarter = 1.25
    case oneAndHalf = 1.5
    case double = 2.0

    var id: Float { rawValue }

    var displayName: String {
        switch self {
        case .quarter: return "0.25x"
        case .half: return "0.5x"
        case .threeQuarter: return "0.75x"
        case .normal: return "1x"
        case .oneAndQuarter: return "1.25x"
        case .oneAndHalf: return "1.5x"
        case .double: return "2x"
        }
    }

    var isSlowMotion: Bool {
        rawValue < 1.0
    }

    /// Speeds commonly used for form review
    static var formReviewSpeeds: [PlaybackSpeed] {
        [.quarter, .half, .threeQuarter, .normal]
    }

    /// All available speeds
    static var allSpeeds: [PlaybackSpeed] {
        allCases
    }
}
