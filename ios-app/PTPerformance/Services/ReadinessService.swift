import Foundation
import Supabase

/// Service for managing daily readiness check-ins and workout modifications
/// Part of the Auto-Regulation System (Build 39 - Phase 3)
class ReadinessService: ObservableObject {
    private let supabase: PTSupabaseClient

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Daily Check-in

    /// Submit a daily readiness check-in
    /// Calculates readiness band based on multiple inputs and stores to database
    /// - Parameters:
    ///   - patientId: The patient ID
    ///   - input: Readiness input data
    /// - Returns: The created DailyReadiness record
    func submitDailyReadiness(
        patientId: String,
        input: ReadinessInput
    ) async throws -> DailyReadiness {
        let logger = DebugLogger.shared

        logger.log("📊 Submitting daily readiness check-in for patient \(patientId)", level: .diagnostic)

        // Calculate HRV delta from baseline if HRV value provided
        var hrvDelta: Double? = nil
        if let hrvValue = input.hrvValue {
            hrvDelta = try? await calculateHRVDelta(patientId: patientId, currentHRV: hrvValue)
            if let delta = hrvDelta {
                logger.log("  HRV delta from baseline: \(String(format: "%.1f%%", delta))", level: .diagnostic)
            }
        }

        // Calculate readiness band using weighted scoring algorithm
        let (band, score) = calculateReadinessBand(input: input, hrvDelta: hrvDelta)

        logger.log("  Calculated band: \(band.rawValue)", level: .diagnostic)
        logger.log("  Calculated score: \(score)", level: .diagnostic)

        let record: [String: Any?] = [
            "patient_id": patientId,
            "check_in_date": Calendar.current.startOfDay(for: Date()).ISO8601Format(),
            "sleep_hours": input.sleepHours,
            "sleep_quality": input.sleepQuality,
            "hrv_value": input.hrvValue,
            "hrv_delta_from_baseline": hrvDelta,
            "whoop_recovery_pct": input.whoopRecoveryPct,
            "subjective_readiness": input.subjectiveReadiness,
            "arm_soreness": input.armSoreness,
            "arm_soreness_severity": input.armSorenessSeverity,
            "shoulder_pain": input.jointPain.contains(.shoulder),
            "elbow_pain": input.jointPain.contains(.elbow),
            "hip_pain": input.jointPain.contains(.hip),
            "knee_pain": input.jointPain.contains(.knee),
            "back_pain": input.jointPain.contains(.back),
            "joint_pain_notes": input.jointPainNotes,
            "readiness_band": band.rawValue,
            "readiness_score": score,
            "band_calculation_method": "weighted_scoring"
        ]

        do {
            logger.log("📊 Upserting to daily_readiness table...", level: .diagnostic)

            let response = try await supabase.client
                .from("daily_readiness")
                .upsert(record, onConflict: "patient_id,check_in_date")
                .select()
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let readiness = try decoder.decode(DailyReadiness.self, from: response.data)

            logger.log("✅ Daily readiness check-in submitted successfully", level: .success)

            // Update HRV baseline if new HRV value provided
            if let hrvValue = input.hrvValue {
                try? await updateHRVBaseline(patientId: patientId, newHRVValue: hrvValue)
            }

            return readiness
        } catch {
            logger.log("❌ READINESS SUBMISSION ERROR: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // MARK: - Band Calculation

    /// Calculate readiness band from input data
    /// Uses weighted scoring system with automatic overrides for pain
    /// Algorithm weights:
    /// - Sleep: 30% (hours + quality)
    /// - HRV delta: 20%
    /// - WHOOP recovery: 20%
    /// - Subjective readiness: 15%
    /// - Pain: 15% (auto-red if joint pain present)
    /// - Parameters:
    ///   - input: Readiness input data
    ///   - hrvDelta: Calculated HRV delta from baseline (percentage)
    /// - Returns: Tuple of (band, score)
    func calculateReadinessBand(
        input: ReadinessInput,
        hrvDelta: Double? = nil
    ) -> (band: ReadinessBand, score: Double) {
        var score: Double = 100.0

        // Sleep scoring (30% weight)
        // Hours component: 15%
        if let sleepHours = input.sleepHours {
            if sleepHours < 6 {
                score -= 15  // Severe penalty
            } else if sleepHours < 7 {
                score -= 10  // Moderate penalty
            } else if sleepHours < 7.5 {
                score -= 5   // Minor penalty
            }
            // 7.5+ hours = no penalty
        }

        // Sleep quality component: 15%
        if let sleepQuality = input.sleepQuality {
            switch sleepQuality {
            case 1:
                score -= 15  // Very poor
            case 2:
                score -= 10  // Poor
            case 3:
                score -= 5   // Fair
            case 4:
                score -= 0   // Good
            case 5:
                score -= 0   // Excellent
            default:
                break
            }
        }

        // HRV delta from baseline (20% weight)
        if let delta = hrvDelta {
            if delta < -15 {
                score -= 20  // Significant decrease
            } else if delta < -10 {
                score -= 15  // Moderate decrease
            } else if delta < -5 {
                score -= 10  // Minor decrease
            } else if delta < 0 {
                score -= 5   // Slight decrease
            }
            // Positive delta = no penalty (good recovery)
        }

        // WHOOP Recovery (20% weight)
        if let recovery = input.whoopRecoveryPct {
            if recovery < 33 {
                score -= 20  // Red zone
            } else if recovery < 66 {
                score -= 10  // Yellow zone
            }
            // 66+ = Green zone, no penalty
        }

        // Subjective readiness (15% weight)
        if let subjective = input.subjectiveReadiness {
            switch subjective {
            case 1:
                score -= 15  // Very low
            case 2:
                score -= 10  // Low
            case 3:
                score -= 5   // Moderate
            case 4:
                score -= 0   // Good
            case 5:
                score -= 0   // Excellent
            default:
                break
            }
        }

        // Joint pain (15% weight - AUTO RED if present)
        if !input.jointPain.isEmpty {
            // Any joint pain triggers automatic red band
            return (.red, max(score - 15, 0))
        }

        // Arm soreness (can downgrade to orange)
        if input.armSoreness, let severity = input.armSorenessSeverity {
            if severity >= 3 {
                return (.red, max(score - 15, 0))
            } else if severity >= 2 {
                return (.orange, max(score - 10, 0))
            }
            // Mild soreness (severity 1) is tolerable, continue with score
        }

        // Determine band from final score
        let band: ReadinessBand
        if score >= 85 {
            band = .green     // Full prescription
        } else if score >= 70 {
            band = .yellow    // Reduce load 5-8%
        } else if score >= 50 {
            band = .orange    // Skip top set
        } else {
            band = .red       // Technique only
        }

        return (band, max(score, 0))
    }

    // MARK: - Apply Modifications

    /// Apply readiness-based modifications to a workout session
    /// Adjusts load and volume for all exercises based on readiness band
    /// - Parameters:
    ///   - patientId: The patient ID
    ///   - sessionId: The session ID
    ///   - readinessId: The daily readiness record ID
    ///   - band: The readiness band to apply
    func applyReadinessModifications(
        patientId: String,
        sessionId: String,
        readinessId: String,
        band: ReadinessBand
    ) async throws {
        let logger = DebugLogger.shared

        logger.log("🔧 Applying readiness modifications for session \(sessionId)", level: .diagnostic)
        logger.log("  Band: \(band.rawValue)", level: .diagnostic)
        logger.log("  Load adjustment: \(band.loadAdjustment * 100)%", level: .diagnostic)
        logger.log("  Volume adjustment: \(band.volumeAdjustment * 100)%", level: .diagnostic)

        do {
            // Fetch session exercises
            let exercisesResponse = try await supabase.client
                .from("session_exercises")
                .select("*")
                .eq("session_id", value: sessionId)
                .execute()

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let exercises = try decoder.decode([Exercise].self, from: exercisesResponse.data)

            logger.log("  Found \(exercises.count) exercises to modify", level: .diagnostic)

            // Modify each exercise based on band
            var modifiedExercises: [[String: Any]] = []

            for exercise in exercises {
                var modification: [String: Any] = [
                    "exercise_id": exercise.id,
                    "original_sets": exercise.prescribed_sets,
                    "original_reps": exercise.prescribed_reps as Any
                ]

                // Apply load adjustment if load is prescribed
                if let originalLoad = exercise.prescribed_load {
                    let loadAdjustment = band.loadAdjustment
                    let modifiedLoad = originalLoad * (1 + loadAdjustment)

                    modification["original_load"] = originalLoad
                    modification["modified_load"] = max(0, modifiedLoad)
                    modification["load_adjustment_pct"] = loadAdjustment
                }

                // Apply volume adjustment (modify sets)
                let volumeAdjustment = band.volumeAdjustment
                let modifiedSets = Int(Double(exercise.prescribed_sets) * (1 + volumeAdjustment))

                modification["modified_sets"] = max(1, modifiedSets)
                modification["volume_adjustment_pct"] = volumeAdjustment

                modifiedExercises.append(modification)
            }

            // Record modifications
            let record: [String: Any] = [
                "patient_id": patientId,
                "session_id": sessionId,
                "daily_readiness_id": readinessId,
                "readiness_band": band.rawValue,
                "load_adjustment_pct": band.loadAdjustment,
                "volume_adjustment_pct": band.volumeAdjustment,
                "skip_top_set": band == .orange || band == .red,
                "technique_only": band == .red,
                "modified_exercises": modifiedExercises
            ]

            try await supabase.client
                .from("readiness_modifications")
                .insert(record)
                .execute()

            logger.log("✅ Readiness modifications applied successfully", level: .success)
        } catch {
            logger.log("❌ READINESS MODIFICATION ERROR: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // MARK: - Fetch Methods

    /// Fetch today's readiness check-in for a patient
    /// - Parameter patientId: The patient ID
    /// - Returns: Today's readiness record, or nil if not found
    func fetchTodayReadiness(patientId: String) async throws -> DailyReadiness? {
        let today = ISO8601DateFormatter().string(from: Date())

        do {
            let response = try await supabase.client
                .from("daily_readiness")
                .select()
                .eq("patient_id", value: patientId)
                .eq("check_in_date", value: today)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(DailyReadiness.self, from: response.data)
        } catch {
            // Return nil if no record found (not an error condition)
            return nil
        }
    }

    /// Fetch readiness history for a patient
    /// - Parameters:
    ///   - patientId: The patient ID
    ///   - limit: Maximum number of records to return
    /// - Returns: Array of readiness records, ordered by date descending
    func fetchReadinessHistory(
        patientId: String,
        limit: Int = 30
    ) async throws -> [DailyReadiness] {
        let response = try await supabase.client
            .from("daily_readiness")
            .select()
            .eq("patient_id", value: patientId)
            .order("check_in_date", ascending: false)
            .limit(limit)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([DailyReadiness].self, from: response.data)
    }

    // MARK: - HRV Baseline Management

    /// Calculate HRV delta from 7-day rolling baseline
    /// - Parameters:
    ///   - patientId: The patient ID
    ///   - currentHRV: Current HRV value
    /// - Returns: Percentage delta from baseline
    private func calculateHRVDelta(patientId: String, currentHRV: Double) async throws -> Double {
        // Fetch most recent baseline
        let response = try await supabase.client
            .from("hrv_baseline")
            .select()
            .eq("patient_id", value: patientId)
            .order("calculated_date", ascending: false)
            .limit(1)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let baselines = try decoder.decode([HRVBaseline].self, from: response.data)

        guard let baseline = baselines.first else {
            // No baseline yet, return 0 (neutral)
            return 0
        }

        // Calculate percentage delta
        let delta = ((currentHRV - baseline.baselineValue) / baseline.baselineValue) * 100
        return delta
    }

    /// Update HRV baseline with new data point (7-day rolling average)
    /// - Parameters:
    ///   - patientId: The patient ID
    ///   - newHRVValue: New HRV value to incorporate
    private func updateHRVBaseline(patientId: String, newHRVValue: Double) async throws {
        let logger = DebugLogger.shared

        // Fetch last 7 days of HRV values
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

        let response = try await supabase.client
            .from("daily_readiness")
            .select("hrv_value")
            .eq("patient_id", value: patientId)
            .gte("check_in_date", value: sevenDaysAgo.ISO8601Format())
            .not("hrv_value", operator: "is", value: "null")
            .execute()

        struct HRVRecord: Codable {
            let hrvValue: Double?
            enum CodingKeys: String, CodingKey {
                case hrvValue = "hrv_value"
            }
        }

        let decoder = JSONDecoder()
        let records = try decoder.decode([HRVRecord].self, from: response.data)
        let hrvValues = records.compactMap { $0.hrvValue }

        // Add current value
        var allValues = hrvValues
        allValues.append(newHRVValue)

        // Calculate new baseline (7-day average)
        guard !allValues.isEmpty else { return }

        let baseline = allValues.reduce(0, +) / Double(allValues.count)

        let today = Calendar.current.startOfDay(for: Date())
        let windowStart = Calendar.current.date(byAdding: .day, value: -7, to: today)!

        let baselineRecord: [String: Any] = [
            "patient_id": patientId,
            "calculated_date": today.ISO8601Format(),
            "baseline_value": baseline,
            "calculation_window_days": 7,
            "data_points_used": allValues.count,
            "window_start": windowStart.ISO8601Format(),
            "window_end": today.ISO8601Format()
        ]

        do {
            try await supabase.client
                .from("hrv_baseline")
                .upsert(baselineRecord, onConflict: "patient_id,calculated_date")
                .execute()

            logger.log("✅ HRV baseline updated: \(String(format: "%.1f", baseline))", level: .diagnostic)
        } catch {
            logger.log("⚠️ Failed to update HRV baseline: \(error.localizedDescription)", level: .warning)
            // Non-fatal error, continue
        }
    }
}
