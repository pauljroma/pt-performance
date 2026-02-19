import Foundation
import Combine

// MARK: - ACP-466 / ACP-470: Wearable Readiness Integration
//
// Bridges unified WearableRecoveryData from any connected wearable into the
// existing readiness system. This is an *additive* layer that does NOT modify
// ReadinessService, ReadinessScoreService, or WorkoutAdaptationService.
//
// Architecture:
//   WearableProvider (WHOOP / Oura / Apple Watch / Garmin)
//        |
//        v
//   WearableRecoveryData  (normalized, from WearableProvider.swift)
//        |
//        v
//   WearableReadinessIntegration  <-- THIS FILE
//        |                    |
//        v                    v
//   WearableReadinessInput   WearableWorkoutAdjustment
//        |                    |
//        v                    v
//   ReadinessBand            Edge Function / UI
//
// Thread Safety: All public API is @MainActor isolated.

// MARK: - WearableReadinessInput

/// Readiness score derived from wearable device data.
///
/// This is distinct from the existing `ReadinessInput` model which holds
/// subjective check-in fields for database submission. `WearableReadinessInput`
/// captures the *objective* wearable-derived score and its provenance.
struct WearableReadinessInput: Sendable {
    /// Computed readiness score on the standard 0-100 scale.
    /// Maps to the same thresholds used by `ReadinessBand`:
    /// - 80-100: Green
    /// - 60-79:  Yellow
    /// - 40-59:  Orange
    /// - 0-39:   Red
    let score: Double

    /// The wearable device that produced this score
    let source: WearableType

    /// The readiness band derived from the score
    var band: ReadinessBand {
        ReadinessBand.from(score: score)
    }

    /// Timestamp when the underlying wearable data was recorded
    let recordedAt: Date

    /// How confident we are in this score (0-100).
    /// Higher confidence = more data sources available.
    let confidence: Double
}

// MARK: - WearableWorkoutAdjustment

/// Workout adjustment recommendation generated from wearable recovery data.
///
/// Provides multipliers for load and volume that can be applied to any
/// programmed workout. The multipliers are based on the `ReadinessBand`
/// thresholds defined in `DailyReadiness.swift`.
///
/// ## Multiplier Semantics
/// Multipliers are expressed as positive fractions of the prescribed load:
/// - 1.0 = no change (green band)
/// - 0.90 = 10% reduction (yellow band)
/// - 0.75 = 25% reduction (orange band, load)
/// - 0.70 = 30% reduction (orange band, volume)
/// - 0.50 = 50% reduction (red band)
///
/// These align with `ReadinessBand.loadAdjustment` and
/// `ReadinessBand.volumeAdjustment`, converted from negative percentages
/// to positive multipliers: `multiplier = 1.0 + band.xxxAdjustment`.
struct WearableWorkoutAdjustment: Sendable {
    /// The readiness band that drove this adjustment
    let band: ReadinessBand

    /// Multiplier for prescribed load/weight (0.50 - 1.0)
    /// Example: 0.75 means use 75% of prescribed weight
    let loadMultiplier: Double

    /// Multiplier for prescribed volume (sets x reps) (0.50 - 1.0)
    /// Example: 0.70 means use 70% of prescribed volume
    let volumeMultiplier: Double

    /// The wearable device that sourced the data
    let source: WearableType

    /// Confidence in this adjustment (0-100).
    /// Low confidence suggests the PT should verify subjectively.
    let confidence: Double

    /// Human-readable recommendations for the session
    let recommendations: [String]

    /// The underlying readiness score (0-100) that produced this adjustment
    let readinessScore: Double

    /// Timestamp of the source wearable data
    let dataRecordedAt: Date
}

// MARK: - ReadinessBand Extension

extension ReadinessBand {
    /// Derive a ReadinessBand from a 0-100 readiness score.
    ///
    /// Uses the same thresholds as `DailyReadiness.readinessBand` and
    /// `ReadinessThreshold` in `ReadinessService.swift`:
    /// - >= 80 -> green
    /// - >= 60 -> yellow
    /// - >= 40 -> orange
    /// - < 40  -> red
    static func from(score: Double) -> ReadinessBand {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .yellow
        } else if score >= 40 {
            return .orange
        } else {
            return .red
        }
    }

    /// Positive load multiplier derived from `loadAdjustment`.
    /// `loadAdjustment` is a negative percentage (e.g., -0.25 for orange).
    /// This returns `1.0 + loadAdjustment`, i.e., 0.75 for orange.
    var loadMultiplier: Double {
        1.0 + loadAdjustment
    }

    /// Positive volume multiplier derived from `volumeAdjustment`.
    /// `volumeAdjustment` is a negative percentage (e.g., -0.30 for orange).
    /// This returns `1.0 + volumeAdjustment`, i.e., 0.70 for orange.
    var volumeMultiplier: Double {
        1.0 + volumeAdjustment
    }
}

// MARK: - WearableReadinessIntegration

/// Bridges WearableRecoveryData from any connected wearable into the existing
/// readiness system. Handles source-specific mapping algorithms for WHOOP,
/// Apple Watch (HealthKit), Oura Ring, and generic wearables.
///
/// ## Usage
/// ```swift
/// let integration = WearableReadinessIntegration.shared
///
/// // From raw wearable data:
/// let input = integration.mapToReadinessInput(recoveryData)
/// let band = input.band   // .green / .yellow / .orange / .red
///
/// // Full workout adjustment:
/// let adjustment = try await integration.generateWorkoutAdjustment(
///     for: recoveryData
/// )
/// let adjustedWeight = prescribedWeight * adjustment.loadMultiplier
/// ```
///
/// ## WHOOP Recovery Mapping (ACP-466)
///
/// WHOOP provides a single recovery percentage (0-100%) which maps to
/// readiness bands via a piecewise linear function:
///
/// | WHOOP Recovery | Readiness Score | Band   |
/// |---------------|-----------------|--------|
/// | 67-100%       | 80-100          | Green  |
/// | 34-66%        | 60-79           | Yellow |
/// | 0-33%         | 0-59            | Orange/Red |
///
/// Additional adjustments:
/// - **HRV baseline deviation**: HRV >20% above 7-day rolling mean boosts
///   the score by up to +10 points; >20% below depresses by up to -10.
/// - **Sleep debt**: <5 hours of sleep depresses by -15; 5-6 hours by -8;
///   >9 hours with good quality boosts by +5.
///
/// ## Apple Watch / HealthKit Mapping
///
/// Apple Watch does not provide a single recovery score. We build a composite
/// from four weighted signals:
/// - HRV percentile (35%): compared to population norms
/// - Sleep composite (35%): hours + quality score
/// - Resting HR (20%): lower is better, inverse scoring
/// - Activity strain (10%): high recent strain = lower recovery
///
/// ## Oura Ring Mapping
///
/// Oura provides its own readiness score (0-100) that maps nearly 1:1 to our
/// readiness scale. We apply minor normalization to align thresholds, plus
/// temperature deviation adjustments.
@MainActor
class WearableReadinessIntegration: ObservableObject {

    // MARK: - Singleton

    static let shared = WearableReadinessIntegration()

    // MARK: - Published State

    /// The most recently computed wearable readiness input, if any
    @Published private(set) var latestReadinessInput: WearableReadinessInput?

    /// The most recently generated workout adjustment, if any
    @Published private(set) var latestWorkoutAdjustment: WearableWorkoutAdjustment?

    /// Error from the most recent operation
    @Published private(set) var error: Error?

    // MARK: - HRV Baseline Cache

    /// Cached 7-day HRV values for baseline calculation.
    /// Key: ISO date string "yyyy-MM-dd", Value: HRV in milliseconds.
    /// This allows the integration to compute a rolling 7-day HRV mean
    /// without requiring a database round-trip on every call.
    private var hrvBaselineCache: [String: Double] = [:]

    /// When the HRV baseline cache was last refreshed
    private var hrvBaselineCacheDate: Date?

    /// Maximum age for the HRV baseline cache before refresh (6 hours)
    private let hrvBaselineCacheMaxAge: TimeInterval = 6 * 60 * 60

    // MARK: - Initialization

    private init() {}

    // MARK: - Primary API: Map Recovery Data to Readiness Input

    /// Map any `WearableRecoveryData` to a `WearableReadinessInput`.
    ///
    /// This is the central normalization layer. It dispatches to the
    /// appropriate source-specific mapping algorithm based on the
    /// wearable type, then clamps the result to the 0-100 range.
    ///
    /// - Parameter data: Normalized recovery data from any wearable.
    /// - Returns: A readiness input with score, band, and confidence.
    func mapToReadinessInput(_ data: WearableRecoveryData) -> WearableReadinessInput {
        let score: Double
        let confidence: Double

        switch data.source {
        case .whoop:
            let result = mapWHOOPToReadiness(data)
            score = result.score
            confidence = result.confidence
        case .appleWatch:
            let result = mapHealthKitToReadiness(data)
            score = result.score
            confidence = result.confidence
        case .oura:
            let result = mapOuraToReadiness(data)
            score = result.score
            confidence = result.confidence
        case .garmin:
            let result = mapGenericToReadiness(data)
            score = result.score
            confidence = result.confidence
        }

        let input = WearableReadinessInput(
            score: clamp(score, min: 0, max: 100),
            source: data.source,
            recordedAt: data.recordedAt,
            confidence: clamp(confidence, min: 0, max: 100)
        )

        latestReadinessInput = input
        return input
    }

    // MARK: - Primary API: Generate Workout Adjustment

    /// Generate a complete workout adjustment from wearable recovery data.
    ///
    /// Computes the readiness score, derives the readiness band, calculates
    /// load and volume multipliers, and generates human-readable recommendations.
    ///
    /// - Parameter data: Normalized recovery data from any wearable.
    /// - Returns: A `WearableWorkoutAdjustment` ready for UI display or
    ///   submission to the `calculate-readiness-adjustment` Edge Function.
    func generateWorkoutAdjustment(
        for data: WearableRecoveryData
    ) -> WearableWorkoutAdjustment {
        let input = mapToReadinessInput(data)
        let band = input.band

        let adjustment = WearableWorkoutAdjustment(
            band: band,
            loadMultiplier: band.loadMultiplier,
            volumeMultiplier: band.volumeMultiplier,
            source: data.source,
            confidence: input.confidence,
            recommendations: generateRecommendations(band: band, data: data),
            readinessScore: input.score,
            dataRecordedAt: data.recordedAt
        )

        latestWorkoutAdjustment = adjustment
        return adjustment
    }

    // MARK: - HRV Baseline Management

    /// Update the rolling 7-day HRV baseline cache with a new value.
    ///
    /// Call this whenever new HRV data arrives from any wearable.
    /// The cache stores one value per calendar day (most recent wins).
    ///
    /// - Parameters:
    ///   - hrvMs: HRV value in milliseconds (RMSSD).
    ///   - date: The date this HRV was recorded.
    func updateHRVBaseline(hrvMs: Double, for date: Date) {
        guard hrvMs > 0 else { return }
        let key = Self.dateKey(for: date)
        hrvBaselineCache[key] = hrvMs

        // Prune entries older than 8 days to keep cache bounded
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -8, to: Date()) ?? Date()
        let cutoffKey = Self.dateKey(for: cutoff)
        hrvBaselineCache = hrvBaselineCache.filter { $0.key >= cutoffKey }
    }

    /// Retrieve the 7-day rolling HRV baseline mean.
    ///
    /// Returns `nil` if fewer than 3 days of data are cached, as the
    /// baseline would be unreliable.
    ///
    /// - Returns: Mean HRV in milliseconds, or nil if insufficient data.
    func getHRVBaseline() -> Double? {
        guard hrvBaselineCache.count >= 3 else { return nil }

        let values = Array(hrvBaselineCache.values)
        let sum = values.reduce(0, +)
        return sum / Double(values.count)
    }

    // MARK: - WHOOP Recovery Mapping (ACP-466)

    /// Map WHOOP recovery data to a readiness score.
    ///
    /// ## Algorithm
    ///
    /// 1. **Base score** from recovery percentage using piecewise linear mapping:
    ///    - WHOOP Green (67-100%) -> Readiness 80-100 (Green band)
    ///    - WHOOP Yellow (34-66%) -> Readiness 60-79 (Yellow band)
    ///    - WHOOP Red (0-33%) -> Readiness 0-59 (Orange/Red band)
    ///
    /// 2. **HRV adjustment** (up to +/- 10 points):
    ///    - Compare current HRV to 7-day rolling baseline
    ///    - >20% above baseline -> up to +10 points (boost toward next band)
    ///    - >20% below baseline -> up to -10 points (depress toward lower band)
    ///    - Linear interpolation within +/- 20% range
    ///
    /// 3. **Sleep debt adjustment** (up to +/- 15 points):
    ///    - <5 hours sleep -> -15 points
    ///    - 5-6 hours -> -8 points
    ///    - 6-7 hours -> -3 points
    ///    - 7-9 hours with quality >= 70 -> +5 points (optimal recovery)
    ///    - 7-9 hours without quality data -> +0 (no penalty)
    ///    - >9 hours -> +0 (possible oversleeping, no bonus)
    ///
    /// - Parameter data: WHOOP recovery data with `recoveryScore`, `hrvMilliseconds`,
    ///   `sleepHours`, and `sleepQuality` fields.
    /// - Returns: Tuple of (score: 0-100, confidence: 0-100).
    private func mapWHOOPToReadiness(_ data: WearableRecoveryData) -> (score: Double, confidence: Double) {
        // Step 1: Base score from WHOOP recovery percentage.
        // Default 50.0 places the athlete in the Yellow band when no recovery
        // score is available. Confidence is already reduced for this case (the
        // +30 for recoveryScore != nil is skipped), signaling that the PT should
        // verify subjectively.
        let recoveryPct = data.recoveryScore ?? 50.0
        var score = mapWHOOPRecoveryToScore(recoveryPct)

        // Step 2: HRV baseline adjustment
        if let hrv = data.hrvMilliseconds {
            score += hrvBaselineAdjustment(currentHRV: hrv)
            // Update baseline cache with this new HRV value
            updateHRVBaseline(hrvMs: hrv, for: data.recordedAt)
        }

        // Step 3: Sleep debt adjustment
        if let sleepHours = data.sleepHours {
            score += sleepDebtAdjustment(
                hours: sleepHours,
                quality: data.sleepQuality
            )
        }

        // Calculate confidence based on data availability
        var confidence: Double = 30.0 // Base confidence for having WHOOP connected
        if data.recoveryScore != nil { confidence += 30.0 }
        if data.hrvMilliseconds != nil { confidence += 15.0 }
        if data.sleepHours != nil { confidence += 15.0 }
        if data.restingHeartRate != nil { confidence += 5.0 }
        if data.sleepQuality != nil { confidence += 5.0 }

        return (score: score, confidence: confidence)
    }

    /// Piecewise linear mapping from WHOOP recovery percentage to readiness score.
    ///
    /// The mapping preserves WHOOP's three-band system while stretching it
    /// across our 0-100 readiness scale:
    ///
    /// ```
    /// WHOOP Recovery %   Readiness Score
    /// ================   ===============
    /// 100%            -> 100
    ///  67%            ->  80
    ///  66%            ->  79
    ///  34%            ->  60
    ///  33%            ->  59
    ///   0%            ->   0
    /// ```
    ///
    /// Within each segment the mapping is linear, ensuring smooth transitions.
    private func mapWHOOPRecoveryToScore(_ recoveryPct: Double) -> Double {
        let clamped = clamp(recoveryPct, min: 0, max: 100)

        if clamped >= 67 {
            // Green zone: 67-100% recovery -> 80-100 readiness score
            // Linear interpolation: score = 80 + (recovery - 67) / (100 - 67) * (100 - 80)
            return 80.0 + (clamped - 67.0) / 33.0 * 20.0
        } else if clamped >= 34 {
            // Yellow zone: 34-66% recovery -> 60-79 readiness score
            // Linear interpolation: score = 60 + (recovery - 34) / (66 - 34) * (79 - 60)
            return 60.0 + (clamped - 34.0) / 32.0 * 19.0
        } else {
            // Red zone: 0-33% recovery -> 0-59 readiness score
            // Linear interpolation: score = 0 + (recovery / 33) * 59
            return clamped / 33.0 * 59.0
        }
    }

    /// Calculate HRV adjustment by comparing current HRV to 7-day baseline.
    ///
    /// The adjustment is capped at +/- 10 points and uses linear interpolation:
    /// - At +20% above baseline: +10 points
    /// - At baseline: 0 points
    /// - At -20% below baseline: -10 points
    /// - Beyond +/- 20%: capped at +/- 10
    ///
    /// Returns 0 if no baseline is available (fewer than 3 days of data).
    private func hrvBaselineAdjustment(currentHRV: Double) -> Double {
        guard let baseline = getHRVBaseline(), baseline > 0 else {
            return 0.0
        }

        let deviationPct = (currentHRV - baseline) / baseline
        // Scale: +/- 20% deviation -> +/- 10 points
        let adjustment = deviationPct / 0.20 * 10.0
        return clamp(adjustment, min: -10, max: 10)
    }

    /// Calculate sleep debt adjustment.
    ///
    /// | Sleep Hours       | Quality       | Adjustment |
    /// |-------------------|---------------|------------|
    /// | < 5               | any           | -15        |
    /// | 5 to < 6          | any           | -8         |
    /// | 6 to < 7          | any           | -3         |
    /// | 7 to 9            | >= 70         | +5         |
    /// | 7 to 9            | < 70 or nil   | 0          |
    /// | > 9               | any           | 0          |
    private func sleepDebtAdjustment(hours: Double, quality: Double?) -> Double {
        if hours < 5 {
            return -15.0
        } else if hours < 6 {
            return -8.0
        } else if hours < 7 {
            return -3.0
        } else if hours <= 9 {
            // Optimal range: bonus only if sleep quality is good
            if let q = quality, q >= 70 {
                return 5.0
            }
            return 0.0
        } else {
            // Oversleeping: no bonus, no penalty
            return 0.0
        }
    }

    // MARK: - Apple Watch / HealthKit Mapping

    /// Map Apple Watch (HealthKit) data to a readiness score.
    ///
    /// Apple Watch does not provide a single recovery score, so we build
    /// a composite from four weighted signals:
    ///
    /// | Component      | Weight | Score Derivation                      |
    /// |---------------|--------|---------------------------------------|
    /// | HRV           | 35%    | Population percentile (see below)     |
    /// | Sleep         | 35%    | Hours + quality composite             |
    /// | Resting HR    | 20%    | Inverse scale (lower = better)        |
    /// | Activity      | 10%    | Strain / recovery inverse             |
    ///
    /// ### HRV Percentile Scoring
    /// Uses age-independent population norms:
    /// - > 100ms RMSSD -> score 95 (excellent)
    /// - 60-100ms -> 70-95 (good to excellent)
    /// - 40-60ms -> 50-70 (average)
    /// - 20-40ms -> 30-50 (below average)
    /// - < 20ms -> score 10-30 (poor)
    ///
    /// ### Sleep Composite
    /// Combines hours and quality (0-100):
    /// - Hours score: optimal at 7-9h (score 90-100), scales down outside
    /// - Quality score: direct 0-100 mapping, or 50 if unavailable
    /// - Composite: 60% hours + 40% quality
    ///
    /// ### Resting HR Scoring (inverse)
    /// - <= 50 BPM -> 95 (excellent)
    /// - 50-60 -> 75-95
    /// - 60-70 -> 55-75
    /// - 70-80 -> 35-55
    /// - > 80 -> 15-35
    ///
    /// ### Activity Strain Scoring (inverse for recovery)
    /// Higher strain yesterday means lower recovery today:
    /// - Strain 0-5 (low) -> score 85 (well-recovered)
    /// - Strain 5-10 -> 65-85
    /// - Strain 10-15 -> 45-65
    /// - Strain 15-21 -> 20-45
    private func mapHealthKitToReadiness(_ data: WearableRecoveryData) -> (score: Double, confidence: Double) {
        var totalWeight: Double = 0
        var weightedSum: Double = 0
        var confidence: Double = 20.0 // Base for being connected

        // HRV component (35% weight)
        if let hrv = data.hrvMilliseconds {
            let hrvScore = hrvPercentileScore(hrv)
            weightedSum += hrvScore * 0.35
            totalWeight += 0.35
            confidence += 25.0

            // Update baseline cache
            updateHRVBaseline(hrvMs: hrv, for: data.recordedAt)
        }

        // Sleep component (35% weight)
        if let sleepHours = data.sleepHours {
            let sleepHrsScore = sleepHoursScore(sleepHours)
            let qualityScore = data.sleepQuality ?? 50.0 // Default to average if unknown
            let compositeSlpScore = sleepHrsScore * 0.6 + qualityScore * 0.4
            weightedSum += compositeSlpScore * 0.35
            totalWeight += 0.35
            confidence += 25.0
            if data.sleepQuality != nil { confidence += 5.0 }
        }

        // Resting HR component (20% weight)
        if let rhr = data.restingHeartRate {
            let rhrScore = restingHeartRateScore(rhr)
            weightedSum += rhrScore * 0.20
            totalWeight += 0.20
            confidence += 15.0
        }

        // Activity strain component (10% weight, inverse for recovery)
        if let strain = data.strain {
            let strainScore = strainToRecoveryScore(strain)
            weightedSum += strainScore * 0.10
            totalWeight += 0.10
            confidence += 10.0
        }

        // Normalize: if we have partial data, scale up proportionally
        let score: Double
        if totalWeight > 0 {
            score = weightedSum / totalWeight
        } else {
            score = 50.0 // No data available, return baseline
        }

        return (score: score, confidence: confidence)
    }

    // MARK: - Oura Ring Mapping

    /// Map Oura Ring data to a readiness score.
    ///
    /// Oura provides its own readiness score (0-100) which aligns well
    /// with our scale. We apply minor normalization and temperature-based
    /// adjustments:
    ///
    /// 1. **Base**: Use Oura readiness score directly (it maps 1:1 to our bands)
    /// 2. **Temperature deviation**: If available in `rawData`, adjust:
    ///    - > +0.5 C above baseline -> -5 points (potential illness)
    ///    - > +1.0 C above baseline -> -10 points
    ///    - Normal range -> no adjustment
    /// 3. **HRV cross-validation**: If HRV is also available, use it as a
    ///    sanity check. Significant divergence triggers lower confidence.
    private func mapOuraToReadiness(_ data: WearableRecoveryData) -> (score: Double, confidence: Double) {
        // Oura provides a direct readiness/recovery score
        var score = data.recoveryScore ?? 50.0
        var confidence: Double = 25.0

        if data.recoveryScore != nil { confidence += 35.0 }

        // Temperature deviation adjustment (from rawData)
        if let rawData = data.rawData,
           case .double(let tempDeviation) = rawData["readiness_temperature_deviation"] {
            score += temperatureDeviationAdjustment(tempDeviation)
        }

        // HRV data improves confidence
        if let hrv = data.hrvMilliseconds {
            confidence += 15.0
            updateHRVBaseline(hrvMs: hrv, for: data.recordedAt)

            // Cross-validate: if HRV strongly disagrees with recovery score,
            // reduce confidence (don't change score, just flag uncertainty)
            if let recoveryScore = data.recoveryScore {
                let hrvImpliedScore = hrvPercentileScore(hrv)
                let divergence = abs(hrvImpliedScore - recoveryScore)
                if divergence > 25 {
                    confidence -= 10.0
                }
            }
        }

        // Sleep data improves confidence
        if data.sleepHours != nil { confidence += 10.0 }
        if data.sleepQuality != nil { confidence += 5.0 }
        if data.restingHeartRate != nil { confidence += 10.0 }

        return (score: score, confidence: confidence)
    }

    // MARK: - Generic / Garmin Mapping

    /// Map data from unsupported or generic wearable types.
    ///
    /// Falls back to a simple composite similar to Apple Watch mapping,
    /// using whatever data is available. Confidence is lower due to
    /// less-validated data pathways.
    private func mapGenericToReadiness(_ data: WearableRecoveryData) -> (score: Double, confidence: Double) {
        // If a direct recovery score is provided, use it
        if let recoveryScore = data.recoveryScore {
            var confidence: Double = 50.0
            if data.hrvMilliseconds != nil { confidence += 15.0 }
            if data.sleepHours != nil { confidence += 15.0 }
            if data.restingHeartRate != nil { confidence += 10.0 }
            return (score: recoveryScore, confidence: confidence)
        }

        // Otherwise, build a composite like Apple Watch
        let result = mapHealthKitToReadiness(data)
        // Reduce confidence for generic/less-validated devices
        return (score: result.score, confidence: max(0, result.confidence - 15.0))
    }

    // MARK: - Scoring Helper Functions

    /// Convert HRV (RMSSD, ms) to a percentile score (0-100).
    ///
    /// Based on general population norms. These are age-independent
    /// approximations; a future enhancement could use age-adjusted tables.
    ///
    /// | HRV (ms) | Score |
    /// |----------|-------|
    /// | >= 100   | 95    |
    /// | 80-100   | 82-95 |
    /// | 60-80    | 70-82 |
    /// | 40-60    | 50-70 |
    /// | 20-40    | 30-50 |
    /// | < 20     | 10-30 |
    private func hrvPercentileScore(_ hrv: Double) -> Double {
        let clamped = clamp(hrv, min: 0, max: 150)

        if clamped >= 100 {
            return 95.0
        } else if clamped >= 80 {
            return 82.0 + (clamped - 80.0) / 20.0 * 13.0
        } else if clamped >= 60 {
            return 70.0 + (clamped - 60.0) / 20.0 * 12.0
        } else if clamped >= 40 {
            return 50.0 + (clamped - 40.0) / 20.0 * 20.0
        } else if clamped >= 20 {
            return 30.0 + (clamped - 20.0) / 20.0 * 20.0
        } else {
            return 10.0 + clamped / 20.0 * 20.0
        }
    }

    /// Score sleep duration on a 0-100 scale.
    ///
    /// Optimal range is 7-9 hours. Scoring:
    /// - 7-9 hours: 90-100
    /// - 6-7 hours: 70-90
    /// - 5-6 hours: 50-70
    /// - 9-10 hours: 80-90 (slight oversleep)
    /// - < 5 hours: 20-50
    /// - > 10 hours: 70-80
    private func sleepHoursScore(_ hours: Double) -> Double {
        if hours >= 7 && hours <= 9 {
            // Optimal: 90-100, peaks at 8 hours
            let distanceFrom8 = abs(hours - 8.0)
            return 100.0 - distanceFrom8 * 10.0
        } else if hours >= 6 && hours < 7 {
            return 70.0 + (hours - 6.0) * 20.0
        } else if hours >= 5 && hours < 6 {
            return 50.0 + (hours - 5.0) * 20.0
        } else if hours > 9 && hours <= 10 {
            return 90.0 - (hours - 9.0) * 10.0
        } else if hours > 10 {
            return 70.0 // Excessive sleep, possibly compensatory
        } else if hours >= 3 {
            // 3-5 hours: 20-50
            return 20.0 + (hours - 3.0) / 2.0 * 30.0
        } else {
            return max(5.0, hours * 6.67) // Very little sleep
        }
    }

    /// Score resting heart rate (inverse: lower is better).
    ///
    /// | RHR (BPM) | Score |
    /// |-----------|-------|
    /// | <= 50     | 95    |
    /// | 50-60     | 75-95 |
    /// | 60-70     | 55-75 |
    /// | 70-80     | 35-55 |
    /// | > 80      | 15-35 |
    private func restingHeartRateScore(_ rhr: Double) -> Double {
        if rhr <= 50 {
            return 95.0
        } else if rhr <= 60 {
            return 95.0 - (rhr - 50.0) * 2.0
        } else if rhr <= 70 {
            return 75.0 - (rhr - 60.0) * 2.0
        } else if rhr <= 80 {
            return 55.0 - (rhr - 70.0) * 2.0
        } else {
            return max(10.0, 35.0 - (rhr - 80.0) * 1.0)
        }
    }

    /// Convert day strain (0-21, WHOOP scale) to a recovery score (inverse).
    ///
    /// Higher strain yesterday typically means lower recovery today.
    ///
    /// | Strain | Recovery Score |
    /// |--------|---------------|
    /// | 0-5    | 85-100        |
    /// | 5-10   | 65-85         |
    /// | 10-15  | 45-65         |
    /// | 15-21  | 20-45         |
    private func strainToRecoveryScore(_ strain: Double) -> Double {
        let clamped = clamp(strain, min: 0, max: 21)

        if clamped <= 5 {
            return 85.0 + (5.0 - clamped) / 5.0 * 15.0
        } else if clamped <= 10 {
            return 65.0 + (10.0 - clamped) / 5.0 * 20.0
        } else if clamped <= 15 {
            return 45.0 + (15.0 - clamped) / 5.0 * 20.0
        } else {
            return 20.0 + (21.0 - clamped) / 6.0 * 25.0
        }
    }

    /// Adjust score based on body temperature deviation (Oura-specific).
    ///
    /// An elevated temperature deviation can indicate illness or overtraining:
    /// - Normal range (-0.5 to +0.5 C): no adjustment
    /// - +0.5 to +1.0 C above baseline: -5 points
    /// - > +1.0 C above baseline: -10 points
    /// - Below baseline (negative): no penalty (normal variance)
    private func temperatureDeviationAdjustment(_ deviation: Double) -> Double {
        if deviation > 1.0 {
            return -10.0
        } else if deviation > 0.5 {
            // Linear from -5 to -10 between 0.5 and 1.0
            return -5.0 - (deviation - 0.5) / 0.5 * 5.0
        } else {
            return 0.0
        }
    }

    // MARK: - Recommendation Generation

    /// Generate human-readable recommendations based on readiness band and data.
    ///
    /// Provides 2-4 targeted recommendations that reference the athlete's
    /// specific data points (e.g., "Your HRV is 15% below baseline").
    private func generateRecommendations(band: ReadinessBand, data: WearableRecoveryData) -> [String] {
        var recommendations: [String] = []

        // Band-level training recommendation
        switch band {
        case .green:
            recommendations.append("Full intensity today. Your recovery data supports a challenging session.")
        case .yellow:
            recommendations.append(
                "Train at moderate intensity. Consider reducing load by ~10% from your programmed weights."
            )
        case .orange:
            recommendations.append(
                "Significant fatigue detected. Reduce load by ~25% and volume by ~30%. Focus on technique."
            )
        case .red:
            recommendations.append(
                "Recovery day recommended. If training, use only 50% of programmed weights with minimal volume."
            )
        }

        // Sleep-specific recommendation
        if let sleepHours = data.sleepHours {
            if sleepHours < 6 {
                recommendations.append(
                    String(format: "Sleep deficit detected (%.1f hrs). Prioritize an earlier bedtime tonight.", sleepHours)
                )
            } else if sleepHours < 7 {
                recommendations.append(
                    String(format: "Suboptimal sleep (%.1f hrs). Consider a 20-minute power nap before training.", sleepHours)
                )
            }
        }

        // HRV-specific recommendation
        if let hrv = data.hrvMilliseconds, let baseline = getHRVBaseline(), baseline > 0 {
            let deviationPct = (hrv - baseline) / baseline * 100
            if deviationPct < -20 {
                recommendations.append(
                    String(format: "HRV is %.0f%% below your 7-day baseline. Your nervous system is fatigued.", abs(deviationPct))
                )
            } else if deviationPct > 20 {
                recommendations.append(
                    String(format: "HRV is %.0f%% above baseline. Great recovery - consider pushing intensity.", deviationPct)
                )
            }
        }

        // Strain / recovery recommendation
        if let strain = data.strain, strain > 15 {
            recommendations.append(
                "High training strain detected from your previous session. Extra warm-up and recovery work recommended."
            )
        }

        return recommendations
    }

    // MARK: - Utility

    /// Clamp a value to a range.
    private func clamp(_ value: Double, min minVal: Double, max maxVal: Double) -> Double {
        return Swift.min(maxVal, Swift.max(minVal, value))
    }

    /// Cached date formatter for HRV baseline cache keys.
    /// Avoids allocating a new `DateFormatter` on every call to `dateKey(for:)`.
    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// Generate a date key string for the HRV baseline cache.
    private static func dateKey(for date: Date) -> String {
        return dateKeyFormatter.string(from: date)
    }
}

// MARK: - AR60 Bridge (Disabled)
// Disabled: AR60ReadinessScore.swift target membership issue prevents compilation.
// This bridge can be re-enabled once the target membership is resolved.

#if false
extension WearableReadinessIntegration {

    /// Create an `AR60ReadinessScore`-compatible contributor from wearable data.
    ///
    /// This allows wearable-derived readiness to be injected into the
    /// `ReadinessScoreService` AR60 scoring system as an additional contributor.
    ///
    /// The contributor uses the `.recovery` domain with wearable-specific evidence.
    ///
    /// - Parameter data: Normalized wearable recovery data.
    /// - Returns: A `ReadinessContributor` suitable for AR60 composite scoring.
    func toAR60Contributor(_ data: WearableRecoveryData) -> ReadinessContributor {
        let input = mapToReadinessInput(data)

        let impact: ReadinessContributor.ContributorImpact
        switch input.band {
        case .green: impact = .positive
        case .yellow: impact = .neutral
        case .orange: impact = .negative
        case .red: impact = .critical
        }

        var evidenceRefs: [EvidenceSourceRef] = []

        // Recovery score evidence
        if let recovery = data.recoveryScore {
            evidenceRefs.append(EvidenceSourceRef(
                sourceType: .wearableMetric,
                sourceId: "\(data.source.rawValue)_recovery",
                timestamp: data.recordedAt,
                snippet: String(format: "%@ recovery: %.0f%%", data.source.displayName, recovery)
            ))
        }

        // HRV evidence
        if let hrv = data.hrvMilliseconds {
            evidenceRefs.append(EvidenceSourceRef(
                sourceType: .wearableMetric,
                sourceId: "\(data.source.rawValue)_hrv",
                timestamp: data.recordedAt,
                snippet: String(format: "HRV: %.0f ms", hrv)
            ))
        }

        // Sleep evidence
        if let sleepHours = data.sleepHours {
            evidenceRefs.append(EvidenceSourceRef(
                sourceType: .wearableMetric,
                sourceId: "\(data.source.rawValue)_sleep",
                timestamp: data.recordedAt,
                snippet: String(format: "Sleep: %.1f hrs", sleepHours)
            ))
        }

        return ReadinessContributor(
            domain: .recovery,
            value: input.score,
            weight: 0.25, // Wearable data contributes 25% to AR60 composite
            impact: impact,
            sourceRefs: evidenceRefs
        )
    }
}
#endif

// MARK: - WearableReadinessIntegration + Edge Function Bridge

extension WearableReadinessIntegration {

    /// Build the request payload for the `calculate-readiness-adjustment` Edge Function.
    ///
    /// This produces the JSON body expected by the Edge Function, which takes a
    /// `readiness_band` string ("green", "yellow", "orange", "red") along with
    /// patient and session identifiers.
    ///
    /// - Parameters:
    ///   - patientId: The patient's UUID.
    ///   - sessionId: The training session's UUID.
    ///   - data: Wearable recovery data to compute the band from.
    ///   - forceRecalculate: Whether to override an existing adjustment.
    /// - Returns: Dictionary suitable for JSON encoding as the Edge Function request body.
    func buildEdgeFunctionPayload(
        patientId: UUID,
        sessionId: UUID,
        data: WearableRecoveryData,
        forceRecalculate: Bool = false
    ) -> [String: Any] {
        let input = mapToReadinessInput(data)
        return [
            "patient_id": patientId.uuidString,
            "session_id": sessionId.uuidString,
            "readiness_band": input.band.rawValue,
            "force_recalculate": forceRecalculate
        ]
    }
}

// MARK: - Preview Support

#if DEBUG
extension WearableReadinessInput {
    /// Sample green-band input from WHOOP
    static var sampleGreenWHOOP: WearableReadinessInput {
        WearableReadinessInput(
            score: 88,
            source: .whoop,
            recordedAt: Date(),
            confidence: 95
        )
    }

    /// Sample yellow-band input from Apple Watch
    static var sampleYellowAppleWatch: WearableReadinessInput {
        WearableReadinessInput(
            score: 68,
            source: .appleWatch,
            recordedAt: Date(),
            confidence: 72
        )
    }

    /// Sample red-band input from Oura
    static var sampleRedOura: WearableReadinessInput {
        WearableReadinessInput(
            score: 32,
            source: .oura,
            recordedAt: Date(),
            confidence: 85
        )
    }
}

extension WearableWorkoutAdjustment {
    /// Sample green-band adjustment
    static var sampleGreen: WearableWorkoutAdjustment {
        WearableWorkoutAdjustment(
            band: .green,
            loadMultiplier: 1.0,
            volumeMultiplier: 1.0,
            source: .whoop,
            confidence: 95,
            recommendations: [
                "Full intensity today. Your recovery data supports a challenging session."
            ],
            readinessScore: 88,
            dataRecordedAt: Date()
        )
    }

    /// Sample orange-band adjustment
    static var sampleOrange: WearableWorkoutAdjustment {
        WearableWorkoutAdjustment(
            band: .orange,
            loadMultiplier: 0.75,
            volumeMultiplier: 0.70,
            source: .appleWatch,
            confidence: 60,
            recommendations: [
                "Significant fatigue detected. Reduce load by ~25% and volume by ~30%. Focus on technique.",
                "Sleep deficit detected (5.2 hrs). Prioritize an earlier bedtime tonight.",
                "HRV is 28% below your 7-day baseline. Your nervous system is fatigued."
            ],
            readinessScore: 48,
            dataRecordedAt: Date()
        )
    }
}
#endif
