//
//  RTSActivityItem.swift
//  PTPerformance
//
//  Model for activity feed items in the RTS dashboard
//

import Foundation
import SwiftUI

/// Model for activity feed items in the RTS dashboard
/// Note: Not Codable due to SwiftUI Color property - used for UI display only
struct RTSActivityItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let date: Date

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
