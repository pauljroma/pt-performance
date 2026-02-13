import Foundation

// MARK: - Database-Matching Models with Safe Decoding
// These models exactly match the Supabase database schema and use safe decoding

// MARK: - Supplement Catalog (supplements table)

/// Matches the supplements table exactly - use for database operations
struct DBSupplement: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let brand: String?
    let category: String
    let description: String?
    let evidenceRating: Int
    let dosageInfo: String?
    let timingRecommendation: String?
    let interactions: [String]?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, brand, category, description
        case evidenceRating = "evidence_rating"
        case dosageInfo = "dosage_info"
        case timingRecommendation = "timing_recommendation"
        case interactions
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.safeUUID(forKey: .id)
        name = container.safeString(forKey: .name, default: "Unknown Supplement")
        brand = container.safeOptionalString(forKey: .brand)
        category = container.safeString(forKey: .category, default: "other")
        description = container.safeOptionalString(forKey: .description)
        evidenceRating = container.safeInt(forKey: .evidenceRating, default: 3)
        dosageInfo = container.safeOptionalString(forKey: .dosageInfo)
        timingRecommendation = container.safeOptionalString(forKey: .timingRecommendation)
        interactions = try? container.decodeIfPresent([String].self, forKey: .interactions)
        createdAt = container.safeOptionalDate(forKey: .createdAt)
        updatedAt = container.safeOptionalDate(forKey: .updatedAt)
    }

    /// Convert to app's CatalogSupplement model
    func toCatalogSupplement() -> CatalogSupplement {
        CatalogSupplement(
            id: id,
            name: name,
            brand: brand,
            category: SupplementCatalogCategory(rawValue: category) ?? .other,
            benefits: [],
            evidenceRating: evidenceRating >= 4 ? .strong : evidenceRating >= 3 ? .moderate : evidenceRating >= 2 ? .emerging : .limited,
            dosageRange: dosageInfo ?? "As directed",
            timing: parseTimings(timingRecommendation),
            contraindications: [],
            interactions: interactions ?? [],
            description: description,
            imageUrl: nil,
            purchaseUrl: nil,
            averageCost: nil,
            servingsPerContainer: nil,
            isVerified: true,
            createdAt: createdAt ?? Date()
        )
    }

    private func parseTimings(_ recommendation: String?) -> [SupplementTiming] {
        guard let rec = recommendation?.lowercased() else { return [.morning] }
        var timings: [SupplementTiming] = []
        if rec.contains("morning") { timings.append(.morning) }
        if rec.contains("pre") && rec.contains("workout") { timings.append(.preWorkout) }
        if rec.contains("post") && rec.contains("workout") { timings.append(.postWorkout) }
        if rec.contains("evening") { timings.append(.evening) }
        if rec.contains("bed") { timings.append(.beforeBed) }
        if rec.contains("meal") || rec.contains("food") { timings.append(.withMeal) }
        return timings.isEmpty ? [.morning] : timings
    }
}

// MARK: - Supplement Stack (patient_supplement_stacks table)

/// Matches the patient_supplement_stacks table exactly
struct DBSupplementStack: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    let patientId: UUID
    let supplementId: UUID
    let dosage: Double
    let dosageUnit: String
    let frequency: String
    let timing: String
    let isActive: Bool
    let startedAt: Date?
    let endedAt: Date?
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?

    // Joined data
    let supplement: DBSupplement?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case supplementId = "supplement_id"
        case dosage
        case dosageUnit = "dosage_unit"
        case frequency, timing
        case isActive = "is_active"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case supplement
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.safeUUID(forKey: .id)
        patientId = container.safeUUID(forKey: .patientId)
        supplementId = container.safeUUID(forKey: .supplementId)
        dosage = container.safeDouble(forKey: .dosage, default: 0)
        dosageUnit = container.safeString(forKey: .dosageUnit, default: "mg")
        frequency = container.safeString(forKey: .frequency, default: "daily")
        timing = container.safeString(forKey: .timing, default: "morning")
        isActive = container.safeBool(forKey: .isActive, default: true)
        startedAt = container.safeOptionalDate(forKey: .startedAt)
        endedAt = container.safeOptionalDate(forKey: .endedAt)
        notes = container.safeOptionalString(forKey: .notes)
        createdAt = container.safeOptionalDate(forKey: .createdAt)
        updatedAt = container.safeOptionalDate(forKey: .updatedAt)
        supplement = try? container.decodeIfPresent(DBSupplement.self, forKey: .supplement)
    }

    static func == (lhs: DBSupplementStack, rhs: DBSupplementStack) -> Bool {
        lhs.id == rhs.id &&
        lhs.patientId == rhs.patientId &&
        lhs.supplementId == rhs.supplementId &&
        lhs.dosage == rhs.dosage &&
        lhs.dosageUnit == rhs.dosageUnit &&
        lhs.frequency == rhs.frequency &&
        lhs.timing == rhs.timing &&
        lhs.isActive == rhs.isActive &&
        lhs.startedAt == rhs.startedAt &&
        lhs.endedAt == rhs.endedAt &&
        lhs.notes == rhs.notes &&
        lhs.createdAt == rhs.createdAt &&
        lhs.updatedAt == rhs.updatedAt &&
        lhs.supplement == rhs.supplement
    }

    /// Convert to app's SupplementRoutine model
    func toRoutine() -> SupplementRoutine {
        let supplementTiming = SupplementTiming(rawValue: timing) ?? .morning
        let supplementFreq = parseFrequency(frequency)
        let routineSupplement = supplement.map { supp in
            RoutineSupplement(
                id: supp.id,
                name: supp.name,
                brand: supp.brand,
                category: SupplementCatalogCategory(rawValue: supp.category) ?? .other
            )
        }

        return SupplementRoutine(
            id: id,
            patientId: patientId,
            supplementId: supplementId,
            supplement: routineSupplement,
            dosage: "\(Int(dosage))\(dosageUnit)",
            timing: supplementTiming,
            frequency: supplementFreq,
            withFood: timing.contains("meal"),
            notes: notes,
            isActive: isActive,
            startDate: startedAt ?? Date(),
            endDate: endedAt,
            createdAt: createdAt ?? Date()
        )
    }

    private func parseFrequency(_ freq: String) -> SupplementFrequency {
        switch freq.lowercased() {
        case "daily": return .daily
        case "twice_daily", "twice daily": return .twiceDaily
        case "three_times_daily", "three times daily": return .threeTimesDaily
        case "weekly": return .weekly
        case "training_days", "training days only": return .trainingDaysOnly
        case "as_needed", "as needed": return .asNeeded
        default: return .daily
        }
    }
}

// MARK: - Supplement Log (supplement_logs table)

/// Matches the supplement_logs table exactly
struct DBSupplementLog: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    let patientId: UUID
    let supplementId: UUID
    let routineId: UUID?
    let dosage: Double
    let dosageUnit: String
    let timing: String
    let loggedAt: Date
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case supplementId = "supplement_id"
        case routineId = "routine_id"
        case dosage
        case dosageUnit = "dosage_unit"
        case timing
        case loggedAt = "logged_at"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.safeUUID(forKey: .id)
        patientId = container.safeUUID(forKey: .patientId)
        supplementId = container.safeUUID(forKey: .supplementId)
        routineId = container.safeOptionalUUID(forKey: .routineId)
        dosage = container.safeDouble(forKey: .dosage, default: 0)
        dosageUnit = container.safeString(forKey: .dosageUnit, default: "mg")
        timing = container.safeString(forKey: .timing, default: "morning")
        loggedAt = container.safeDate(forKey: .loggedAt)
        notes = container.safeOptionalString(forKey: .notes)
        createdAt = container.safeOptionalDate(forKey: .createdAt)
        updatedAt = container.safeOptionalDate(forKey: .updatedAt)
    }

    /// Convert to app's SupplementLogEntry model
    func toLogEntry(supplementName: String = "Unknown") -> SupplementLogEntry {
        let supplementTiming = SupplementTiming(rawValue: timing) ?? .morning
        let isSkipped = dosage == 0 || (notes?.contains("[SKIPPED]") ?? false)

        return SupplementLogEntry(
            id: id,
            patientId: patientId,
            supplementId: supplementId,
            routineId: routineId,
            supplementName: supplementName,
            dosage: "\(Int(dosage))\(dosageUnit)",
            timing: supplementTiming,
            takenAt: loggedAt,
            skipped: isSkipped,
            skipReason: isSkipped ? notes?.replacingOccurrences(of: "[SKIPPED]", with: "").trimmingCharacters(in: .whitespaces) : nil,
            perceivedEffect: nil,
            sideEffects: nil,
            notes: isSkipped ? nil : notes,
            createdAt: createdAt ?? loggedAt,
            supplement: nil
        )
    }

    static func == (lhs: DBSupplementLog, rhs: DBSupplementLog) -> Bool {
        lhs.id == rhs.id &&
        lhs.patientId == rhs.patientId &&
        lhs.supplementId == rhs.supplementId &&
        lhs.routineId == rhs.routineId &&
        lhs.dosage == rhs.dosage &&
        lhs.dosageUnit == rhs.dosageUnit &&
        lhs.timing == rhs.timing &&
        lhs.loggedAt == rhs.loggedAt &&
        lhs.notes == rhs.notes &&
        lhs.createdAt == rhs.createdAt &&
        lhs.updatedAt == rhs.updatedAt
    }
}

// MARK: - Lab Result (lab_results table)

/// Matches the lab_results table exactly
struct DBLabResult: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let testDate: Date?
    let provider: String?
    let pdfUrl: String?
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case testDate = "test_date"
        case provider
        case pdfUrl = "pdf_url"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.safeUUID(forKey: .id)
        patientId = container.safeUUID(forKey: .patientId)
        testDate = container.safeOptionalDate(forKey: .testDate)
        provider = container.safeOptionalString(forKey: .provider)
        pdfUrl = container.safeOptionalString(forKey: .pdfUrl)
        notes = container.safeOptionalString(forKey: .notes)
        createdAt = container.safeOptionalDate(forKey: .createdAt)
        updatedAt = container.safeOptionalDate(forKey: .updatedAt)
    }

    /// Convert to app's LabResult model
    func toLabResult() -> LabResult {
        LabResult(
            id: id,
            patientId: patientId,
            testDate: testDate,
            testType: nil,
            results: nil,
            pdfUrl: pdfUrl,
            aiAnalysis: nil,
            createdAt: createdAt,
            updatedAt: updatedAt,
            provider: provider,
            notes: notes,
            parsedData: nil
        )
    }
}

// MARK: - Fasting Log (fasting_logs table)

/// Matches the fasting_logs table exactly - for database decoding
struct DBFastingLog: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let startedAt: Date
    let endedAt: Date?
    let plannedHours: Int
    let actualHours: Double?
    let protocolType: String?
    let notes: String?
    let completed: Bool
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case plannedHours = "planned_hours"
        case actualHours = "actual_hours"
        case protocolType = "protocol_type"
        case notes
        case completed
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.safeUUID(forKey: .id)
        patientId = container.safeUUID(forKey: .patientId)
        startedAt = container.safeDate(forKey: .startedAt)
        endedAt = container.safeOptionalDate(forKey: .endedAt)
        plannedHours = container.safeInt(forKey: .plannedHours, default: 16)
        actualHours = container.safeOptionalDouble(forKey: .actualHours)
        protocolType = container.safeOptionalString(forKey: .protocolType)
        notes = container.safeOptionalString(forKey: .notes)
        completed = container.safeBool(forKey: .completed, default: false)
        createdAt = container.safeOptionalDate(forKey: .createdAt)
        updatedAt = container.safeOptionalDate(forKey: .updatedAt)
    }

    /// Convert to app's FastingLog model
    func toFastingLog() -> FastingLog {
        FastingLog(
            id: id,
            patientId: patientId,
            protocolType: protocolType,
            startedAt: startedAt,
            endedAt: endedAt,
            plannedHours: plannedHours,
            actualHours: actualHours,
            completed: completed,
            notes: notes,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt
        )
    }
}

// MARK: - Recovery Session (recovery_sessions table)

/// Matches the recovery_sessions table exactly - for database decoding
struct DBRecoverySession: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let sessionType: String
    let durationMinutes: Int
    let temperatureF: Double?
    let notes: String?
    let loggedAt: Date
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case sessionType = "session_type"
        case durationMinutes = "duration_minutes"
        case temperatureF = "temperature_f"
        case notes
        case loggedAt = "logged_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.safeUUID(forKey: .id)
        patientId = container.safeUUID(forKey: .patientId)
        sessionType = container.safeString(forKey: .sessionType, default: "sauna_traditional")
        durationMinutes = container.safeInt(forKey: .durationMinutes, default: 15)
        temperatureF = container.safeOptionalDouble(forKey: .temperatureF)
        notes = container.safeOptionalString(forKey: .notes)
        loggedAt = container.safeDate(forKey: .loggedAt)
        createdAt = container.safeOptionalDate(forKey: .createdAt)
        updatedAt = container.safeOptionalDate(forKey: .updatedAt)
    }

    /// Convert to app's RecoverySession model
    func toRecoverySession() -> RecoverySession {
        let protocolType = RecoveryProtocolType(rawValue: sessionType) ?? .saunaTraditional
        return RecoverySession(
            id: id,
            patientId: patientId,
            protocolType: protocolType,
            loggedAt: loggedAt,
            durationSeconds: durationMinutes * 60,
            temperature: temperatureF,
            heartRateAvg: nil,
            heartRateMax: nil,
            perceivedEffort: nil,
            rating: nil,
            notes: notes,
            createdAt: createdAt ?? Date()
        )
    }
}

// Note: Safe decoder extensions are defined in SafeDecoder.swift
