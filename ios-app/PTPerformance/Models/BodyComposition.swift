//
//  BodyComposition.swift
//  PTPerformance
//
//  Body Composition tracking model (ACP-510)
//

import Foundation

/// Represents a body composition measurement from the body_compositions table
struct BodyComposition: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let patientId: UUID
    let recordedAt: Date
    let weightLb: Double?
    let bodyFatPercent: Double?
    let muscleMassLb: Double?
    let bmi: Double?
    let waistIn: Double?
    let chestIn: Double?
    let armIn: Double?
    let legIn: Double?
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case recordedAt = "recorded_at"
        case weightLb = "weight_lb"
        case bodyFatPercent = "body_fat_percent"
        case muscleMassLb = "muscle_mass_lb"
        case bmi
        case waistIn = "waist_in"
        case chestIn = "chest_in"
        case armIn = "arm_in"
        case legIn = "leg_in"
        case notes
        case createdAt = "created_at"
    }
}

// MARK: - Display Extensions

extension BodyComposition {
    /// Formatted date string for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: recordedAt)
    }

    /// Short formatted date (e.g., "Jan 27")
    var shortFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: recordedAt)
    }

    /// Formatted weight string
    var weightText: String {
        guard let weight = weightLb else { return "--" }
        return String(format: "%.1f lbs", weight)
    }

    /// Formatted body fat string
    var bodyFatText: String {
        guard let bf = bodyFatPercent else { return "--" }
        return String(format: "%.1f%%", bf)
    }

    /// Formatted muscle mass string
    var muscleMassText: String {
        guard let mm = muscleMassLb else { return "--" }
        return String(format: "%.1f lbs", mm)
    }
}

// MARK: - Insert DTO

/// Data transfer object for creating new body composition records
struct BodyCompositionInsert: Codable {
    let patientId: UUID
    let recordedAt: Date
    let weightLb: Double?
    let bodyFatPercent: Double?
    let muscleMassLb: Double?
    let bmi: Double?
    let waistIn: Double?
    let chestIn: Double?
    let armIn: Double?
    let legIn: Double?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case recordedAt = "recorded_at"
        case weightLb = "weight_lb"
        case bodyFatPercent = "body_fat_percent"
        case muscleMassLb = "muscle_mass_lb"
        case bmi
        case waistIn = "waist_in"
        case chestIn = "chest_in"
        case armIn = "arm_in"
        case legIn = "leg_in"
        case notes
    }
}
