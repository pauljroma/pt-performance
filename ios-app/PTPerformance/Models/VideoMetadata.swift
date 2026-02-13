//
//  VideoMetadata.swift
//  PTPerformance
//
//  Created by Content & Polish Sprint Agent 3
//  Model for exercise video metadata with multi-quality support
//

import Foundation

/// Metadata for exercise videos including multiple quality options
/// Maps to the exercise_video_metadata database table
struct VideoMetadata: Codable, Identifiable, Equatable {

    // MARK: - Properties

    let id: UUID
    let exerciseTemplateId: UUID
    let videoUrlSd: String?
    let videoUrlHd: String?
    let videoUrlFhd: String?
    let thumbnailUrl: String?
    let durationSeconds: Int?
    let fileSizeBytes: Int64?
    let aspectRatio: String
    let hasAudio: Bool
    let hasCaptions: Bool
    let captionUrl: String?
    let viewCount: Int
    let createdAt: Date?
    let updatedAt: Date?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseTemplateId = "exercise_template_id"
        case videoUrlSd = "video_url_sd"
        case videoUrlHd = "video_url_hd"
        case videoUrlFhd = "video_url_fhd"
        case thumbnailUrl = "thumbnail_url"
        case durationSeconds = "duration_seconds"
        case fileSizeBytes = "file_size_bytes"
        case aspectRatio = "aspect_ratio"
        case hasAudio = "has_audio"
        case hasCaptions = "has_captions"
        case captionUrl = "caption_url"
        case viewCount = "view_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Video URL Selection

    /// Get the best available video URL based on quality preference
    /// Falls back to lower quality if preferred quality is unavailable
    /// - Parameter quality: The preferred video quality
    /// - Returns: The best available video URL, or nil if no videos are available
    func getVideoUrl(for quality: VideoQuality) -> String? {
        switch quality {
        case .fhd:
            return videoUrlFhd ?? videoUrlHd ?? videoUrlSd
        case .hd:
            return videoUrlHd ?? videoUrlFhd ?? videoUrlSd
        case .sd:
            return videoUrlSd ?? videoUrlHd ?? videoUrlFhd
        case .auto:
            // Auto prefers HD as a balance of quality and bandwidth
            return videoUrlHd ?? videoUrlSd ?? videoUrlFhd
        }
    }

    /// Get the actual quality that will be used for a preference
    /// Useful for displaying what quality is actually playing
    /// - Parameter preferredQuality: The preferred video quality
    /// - Returns: The actual quality that will be used
    func getActualQuality(for preferredQuality: VideoQuality) -> VideoQuality? {
        switch preferredQuality {
        case .fhd:
            if videoUrlFhd != nil { return .fhd }
            if videoUrlHd != nil { return .hd }
            if videoUrlSd != nil { return .sd }
            return nil
        case .hd:
            if videoUrlHd != nil { return .hd }
            if videoUrlFhd != nil { return .fhd }
            if videoUrlSd != nil { return .sd }
            return nil
        case .sd:
            if videoUrlSd != nil { return .sd }
            if videoUrlHd != nil { return .hd }
            if videoUrlFhd != nil { return .fhd }
            return nil
        case .auto:
            if videoUrlHd != nil { return .hd }
            if videoUrlSd != nil { return .sd }
            if videoUrlFhd != nil { return .fhd }
            return nil
        }
    }

    /// Check if any video is available
    var hasVideo: Bool {
        videoUrlSd != nil || videoUrlHd != nil || videoUrlFhd != nil
    }

    /// Get all available quality options
    var availableQualities: [VideoQuality] {
        var qualities: [VideoQuality] = []
        if videoUrlSd != nil { qualities.append(.sd) }
        if videoUrlHd != nil { qualities.append(.hd) }
        if videoUrlFhd != nil { qualities.append(.fhd) }
        return qualities
    }

    // MARK: - Duration Formatting

    /// Formatted duration string (e.g., "2:30" or "1:05:30")
    var formattedDuration: String {
        guard let seconds = durationSeconds else { return "--:--" }

        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    /// Duration in minutes (rounded)
    var durationMinutes: Int {
        guard let seconds = durationSeconds else { return 0 }
        return (seconds + 30) / 60  // Round to nearest minute
    }

    // MARK: - File Size Formatting

    /// Formatted file size (e.g., "15.2 MB")
    var formattedFileSize: String {
        guard let bytes = fileSizeBytes else { return "Unknown" }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    /// Estimated file size for a specific quality
    /// - Parameter quality: The video quality
    /// - Returns: Estimated size string
    func estimatedSize(for quality: VideoQuality) -> String {
        guard let baseBytes = fileSizeBytes else { return "Unknown" }

        // Estimate based on quality multipliers
        let multiplier: Double
        switch quality {
        case .sd: multiplier = 0.5
        case .hd: multiplier = 1.0
        case .fhd: multiplier = 2.0
        case .auto: multiplier = 1.0
        }

        let estimatedBytes = Int64(Double(baseBytes) * multiplier)
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: estimatedBytes)
    }

    // MARK: - Aspect Ratio

    /// Parsed aspect ratio as a tuple (width, height)
    var aspectRatioComponents: (width: Int, height: Int)? {
        let parts = aspectRatio.split(separator: ":")
        guard let widthStr = parts.first,
              let heightStr = parts.dropFirst().first,
              let width = Int(widthStr),
              let height = Int(heightStr) else {
            return nil
        }
        return (width, height)
    }

    /// Aspect ratio as a decimal (e.g., 1.78 for 16:9)
    var aspectRatioDecimal: Double {
        guard let components = aspectRatioComponents else {
            return 16.0 / 9.0  // Default to 16:9
        }
        return Double(components.width) / Double(components.height)
    }

    /// Whether the video is in portrait orientation
    var isPortrait: Bool {
        aspectRatioDecimal < 1.0
    }

    /// Whether the video is in landscape orientation
    var isLandscape: Bool {
        aspectRatioDecimal >= 1.0
    }
}

// MARK: - Video Metadata Extensions

extension VideoMetadata {
    /// Create a sample video metadata for previews
    static var sample: VideoMetadata {
        VideoMetadata(
            id: UUID(),
            exerciseTemplateId: UUID(),
            videoUrlSd: "https://example.com/video_480p.mp4",
            videoUrlHd: "https://example.com/video_720p.mp4",
            videoUrlFhd: "https://example.com/video_1080p.mp4",
            thumbnailUrl: "https://example.com/thumbnail.jpg",
            durationSeconds: 150,
            fileSizeBytes: 15_000_000,
            aspectRatio: "16:9",
            hasAudio: true,
            hasCaptions: true,
            captionUrl: "https://example.com/captions.vtt",
            viewCount: 1250,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// Create video metadata with minimal data (no URLs)
    static var empty: VideoMetadata {
        VideoMetadata(
            id: UUID(),
            exerciseTemplateId: UUID(),
            videoUrlSd: nil,
            videoUrlHd: nil,
            videoUrlFhd: nil,
            thumbnailUrl: nil,
            durationSeconds: nil,
            fileSizeBytes: nil,
            aspectRatio: "16:9",
            hasAudio: false,
            hasCaptions: false,
            captionUrl: nil,
            viewCount: 0,
            createdAt: nil,
            updatedAt: nil
        )
    }
}

// MARK: - Hashable

extension VideoMetadata: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: VideoMetadata, rhs: VideoMetadata) -> Bool {
        lhs.id == rhs.id
    }
}
