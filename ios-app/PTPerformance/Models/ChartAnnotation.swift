//
//  ChartAnnotation.swift
//  PTPerformance
//
//  ACP-1026: Progress Charts Interactivity
//  Model for user-created life event annotations on charts
//

import Foundation
import SwiftUI

// MARK: - Chart Annotation

/// A user-created annotation marking a life event on a progress chart.
/// Events like vacations, injuries, and deloads provide context for
/// understanding training data trends.
struct ChartAnnotation: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let title: String
    let note: String?
    let category: AnnotationCategory
    let createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        title: String,
        note: String? = nil,
        category: AnnotationCategory,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.note = note
        self.category = category
        self.createdAt = createdAt
    }
}

// MARK: - Annotation Category

/// Categories for chart annotations with associated visual styling
enum AnnotationCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case vacation = "vacation"
    case injury = "injury"
    case deload = "deload"
    case illness = "illness"
    case competition = "competition"
    case milestone = "milestone"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vacation: return "Vacation"
        case .injury: return "Injury"
        case .deload: return "Deload"
        case .illness: return "Illness"
        case .competition: return "Competition"
        case .milestone: return "Milestone"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .vacation: return "airplane"
        case .injury: return "cross.case.fill"
        case .deload: return "arrow.down.right.circle"
        case .illness: return "pills.fill"
        case .competition: return "trophy.fill"
        case .milestone: return "star.fill"
        case .other: return "flag.fill"
        }
    }

    var color: Color {
        switch self {
        case .vacation: return .orange
        case .injury: return .red
        case .deload: return .purple
        case .illness: return .yellow
        case .competition: return .modusCyan
        case .milestone: return .modusTealAccent
        case .other: return .gray
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension ChartAnnotation {
    static var sampleVacation: ChartAnnotation {
        ChartAnnotation(
            date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
            title: "Beach Vacation",
            note: "7-day trip, limited gym access",
            category: .vacation
        )
    }

    static var sampleInjury: ChartAnnotation {
        ChartAnnotation(
            date: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            title: "Lower Back Strain",
            note: "Modified training for 2 weeks",
            category: .injury
        )
    }

    static var sampleDeload: ChartAnnotation {
        ChartAnnotation(
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            title: "Planned Deload",
            note: "50% volume reduction",
            category: .deload
        )
    }
}
#endif
