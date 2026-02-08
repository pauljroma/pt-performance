//
//  ExerciseTemplate.swift
//  PTPerformance
//
//  Build 88: Shared exercise template data model
//

import Foundation

/// Exercise template data model from Supabase
struct ExerciseTemplateData: Codable, Identifiable, Hashable, Equatable, Sendable {
    let id: UUID
    let name: String
    let category: String?
    let bodyRegion: String?
    let videoUrl: String?
    let videoThumbnailUrl: String?
    let videoDuration: Int?
    let formCues: [FormCueData]?

    enum CodingKeys: String, CodingKey {
        case id, name, category
        case bodyRegion = "body_region"
        case videoUrl = "video_url"
        case videoThumbnailUrl = "video_thumbnail_url"
        case videoDuration = "video_duration"
        case formCues = "form_cues"
    }

    struct FormCueData: Codable, Hashable, Equatable, Sendable {
        let cue: String
        let timestamp: Int?

        init(cue: String, timestamp: Int? = nil) {
            self.cue = cue
            self.timestamp = timestamp
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            cue = container.safeString(forKey: .cue, default: "")
            timestamp = container.safeOptionalInt(forKey: .timestamp)
        }

        enum CodingKeys: String, CodingKey {
            case cue, timestamp
        }
    }

    init(
        id: UUID,
        name: String,
        category: String? = nil,
        bodyRegion: String? = nil,
        videoUrl: String? = nil,
        videoThumbnailUrl: String? = nil,
        videoDuration: Int? = nil,
        formCues: [FormCueData]? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.bodyRegion = bodyRegion
        self.videoUrl = videoUrl
        self.videoThumbnailUrl = videoThumbnailUrl
        self.videoDuration = videoDuration
        self.formCues = formCues
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required field with fallback to new UUID
        id = container.safeUUID(forKey: .id)

        // Required string with fallback
        name = container.safeString(forKey: .name, default: "Unknown Exercise")

        // Optional fields
        category = container.safeOptionalString(forKey: .category)
        bodyRegion = container.safeOptionalString(forKey: .bodyRegion)
        videoUrl = container.safeOptionalString(forKey: .videoUrl)
        videoThumbnailUrl = container.safeOptionalString(forKey: .videoThumbnailUrl)
        videoDuration = container.safeOptionalInt(forKey: .videoDuration)

        // Array with fallback to nil (not empty array, to preserve original optional behavior)
        formCues = try? container.decodeIfPresent([FormCueData].self, forKey: .formCues)
    }
}
