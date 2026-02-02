//
//  ExerciseTemplate.swift
//  PTPerformance
//
//  Build 88: Shared exercise template data model
//

import Foundation

/// Exercise template data model from Supabase
struct ExerciseTemplateData: Codable, Identifiable, Hashable, Equatable {
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

    struct FormCueData: Codable, Hashable, Equatable {
        let cue: String
        let timestamp: Int?
    }
}
