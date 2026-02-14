//
//  String+LiftName.swift
//  PTPerformance
//
//  Shared helper for abbreviating exercise names in compact UI displays.
//  Centralized here to avoid duplication across strength views.
//

import Foundation

extension String {
    /// Returns a shortened version of common lift names for compact display.
    /// Falls back to the first 8 characters for unrecognized names.
    var shortLiftName: String {
        switch self {
        case "Bench Press": return "Bench"
        case "Back Squat", "Squat": return "Squat"
        case "Deadlift": return "Deadlift"
        case "Overhead Press": return "OHP"
        case "Barbell Row": return "Row"
        default: return String(self.prefix(8))
        }
    }
}
