//
//  VideoQuality.swift
//  PTPerformance
//
//  Video quality options for streaming
//

import Foundation

/// Available video quality options for streaming
enum VideoQuality: String, Codable, CaseIterable, Identifiable {
    case auto = "auto"
    case sd = "sd"
    case hd = "hd"
    case fhd = "fhd"

    var id: String { rawValue }

    /// Display name for the quality option
    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .sd: return "480p"
        case .hd: return "720p HD"
        case .fhd: return "1080p Full HD"
        }
    }

    /// Short display name
    var shortName: String {
        switch self {
        case .auto: return "Auto"
        case .sd: return "SD"
        case .hd: return "HD"
        case .fhd: return "FHD"
        }
    }

    /// Estimated bitrate in kbps
    var estimatedBitrate: Int {
        switch self {
        case .auto: return 2500  // Adaptive
        case .sd: return 1000   // 480p
        case .hd: return 2500   // 720p
        case .fhd: return 5000  // 1080p
        }
    }

    /// Description of the quality setting
    var description: String {
        switch self {
        case .auto: return "Adjusts quality based on your connection"
        case .sd: return "Lower quality, uses less data"
        case .hd: return "Good quality for most connections"
        case .fhd: return "Best quality, requires fast connection"
        }
    }
}
