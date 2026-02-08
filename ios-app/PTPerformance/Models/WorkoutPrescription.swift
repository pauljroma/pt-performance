//
//  WorkoutPrescription.swift
//  PTPerformance
//
//  Workout prescribed by therapist to patient
//

import Foundation

/// Priority level for prescribed workouts
enum PrescriptionPriority: String, Codable, CaseIterable {
    case low
    case medium
    case high
    case urgent

    var displayName: String {
        rawValue.capitalized
    }

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
}

/// Status of a workout prescription
enum PrescriptionStatus: String, Codable, CaseIterable {
    case pending
    case viewed
    case started
    case completed
    case expired
    case cancelled

    var displayName: String {
        rawValue.capitalized
    }
}

/// A workout prescribed by a therapist to a patient
struct WorkoutPrescription: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let therapistId: UUID
    let templateId: UUID?
    let templateType: String?
    let name: String
    let instructions: String?
    let dueDate: Date?
    let priority: PrescriptionPriority
    let status: PrescriptionStatus
    let manualSessionId: UUID?
    let prescribedAt: Date
    let viewedAt: Date?
    let startedAt: Date?
    let completedAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case templateId = "template_id"
        case templateType = "template_type"
        case name
        case instructions
        case dueDate = "due_date"
        case priority
        case status
        case manualSessionId = "manual_session_id"
        case prescribedAt = "prescribed_at"
        case viewedAt = "viewed_at"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case createdAt = "created_at"
    }

    // Memberwise initializer for creating instances programmatically
    init(
        id: UUID,
        patientId: UUID,
        therapistId: UUID,
        templateId: UUID?,
        templateType: String?,
        name: String,
        instructions: String?,
        dueDate: Date?,
        priority: PrescriptionPriority,
        status: PrescriptionStatus,
        manualSessionId: UUID?,
        prescribedAt: Date,
        viewedAt: Date?,
        startedAt: Date?,
        completedAt: Date?,
        createdAt: Date
    ) {
        self.id = id
        self.patientId = patientId
        self.therapistId = therapistId
        self.templateId = templateId
        self.templateType = templateType
        self.name = name
        self.instructions = instructions
        self.dueDate = dueDate
        self.priority = priority
        self.status = status
        self.manualSessionId = manualSessionId
        self.prescribedAt = prescribedAt
        self.viewedAt = viewedAt
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.createdAt = createdAt
    }

    // Custom decoder to handle database nulls and format variations
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields with robust decoding
        id = try container.decode(UUID.self, forKey: .id)
        patientId = try container.decode(UUID.self, forKey: .patientId)
        therapistId = try container.decode(UUID.self, forKey: .therapistId)

        // Optional UUIDs
        templateId = try? container.decodeIfPresent(UUID.self, forKey: .templateId)
        templateType = try? container.decodeIfPresent(String.self, forKey: .templateType)
        manualSessionId = try? container.decodeIfPresent(UUID.self, forKey: .manualSessionId)

        // Strings with defaults
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? "Unnamed Prescription"
        instructions = try? container.decodeIfPresent(String.self, forKey: .instructions)

        // Priority with fallback
        if let priorityString = try? container.decodeIfPresent(String.self, forKey: .priority),
           let decodedPriority = PrescriptionPriority(rawValue: priorityString) {
            priority = decodedPriority
        } else {
            priority = .medium
        }

        // Status with fallback
        if let statusString = try? container.decodeIfPresent(String.self, forKey: .status),
           let decodedStatus = PrescriptionStatus(rawValue: statusString) {
            status = decodedStatus
        } else {
            status = .pending
        }

        // Date fields - handle both ISO8601 and other formats
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let altDateFormatter = ISO8601DateFormatter()
        altDateFormatter.formatOptions = [.withInternetDateTime]

        func parseDate(_ key: CodingKeys) -> Date? {
            if let date = try? container.decodeIfPresent(Date.self, forKey: key) {
                return date
            }
            if let dateString = try? container.decodeIfPresent(String.self, forKey: key) {
                return dateFormatter.date(from: dateString) ?? altDateFormatter.date(from: dateString)
            }
            return nil
        }

        dueDate = parseDate(.dueDate)
        viewedAt = parseDate(.viewedAt)
        startedAt = parseDate(.startedAt)
        completedAt = parseDate(.completedAt)

        // Required dates with fallback to current date
        prescribedAt = parseDate(.prescribedAt) ?? Date()
        createdAt = parseDate(.createdAt) ?? Date()
    }

    /// Check if prescription is overdue
    var isOverdue: Bool {
        guard let due = dueDate else { return false }
        return due < Date() && status != .completed && status != .cancelled
    }

    /// Days until due (negative if overdue)
    var daysUntilDue: Int? {
        guard let due = dueDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: due).day
    }
}

/// DTO for creating a prescription
struct CreatePrescriptionDTO: Codable {
    let patientId: UUID
    let therapistId: UUID
    let templateId: UUID?
    let templateType: String?
    let name: String
    let instructions: String?
    let dueDate: Date?
    let priority: String

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case templateId = "template_id"
        case templateType = "template_type"
        case name
        case instructions
        case dueDate = "due_date"
        case priority
    }
}
