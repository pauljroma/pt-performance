import Foundation

/// One-Rep Max (1RM) Calculator
/// Implements standard 1RM estimation formulas for strength training
struct RMCalculator {

    // MARK: - 1RM Formulas

    /// Epley formula: 1RM = weight × (1 + reps / 30)
    /// Most commonly used, accurate for reps 1-10
    static func epley(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        return weight * (1 + Double(reps) / 30.0)
    }

    /// Brzycki formula: 1RM = weight × (36 / (37 - reps))
    /// Accurate for higher rep ranges (1-12 reps)
    static func brzycki(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0, reps < 37 else { return 0 }
        return weight * (36.0 / (37.0 - Double(reps)))
    }

    /// Lombardi formula: 1RM = weight × reps^0.1
    /// Conservative estimate, works well for lower reps
    static func lombardi(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        return weight * pow(Double(reps), 0.1)
    }

    /// Mayhew formula: 1RM = (100 × weight) / (52.2 + (41.9 × e^(-0.055 × reps)))
    /// More accurate for higher rep ranges
    static func mayhew(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        let denominator = 52.2 + (41.9 * exp(-0.055 * Double(reps)))
        return (100 * weight) / denominator
    }

    /// O'Conner formula: 1RM = weight × (1 + reps / 40)
    /// Similar to Epley but more conservative
    static func oconner(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        return weight * (1 + Double(reps) / 40.0)
    }

    /// Wathan formula: 1RM = (100 × weight) / (48.8 + (53.8 × e^(-0.075 × reps)))
    /// Good for general population
    static func wathan(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        let denominator = 48.8 + (53.8 * exp(-0.075 * Double(reps)))
        return (100 * weight) / denominator
    }

    // MARK: - Combined Methods

    /// Average of Epley, Brzycki, and Lombardi (most commonly used)
    /// Provides a balanced estimate across different rep ranges
    static func average(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }

        let e = epley(weight: weight, reps: reps)
        let b = brzycki(weight: weight, reps: reps)
        let l = lombardi(weight: weight, reps: reps)

        return (e + b + l) / 3.0
    }

    /// Average of all six formulas for maximum accuracy
    static func averageAll(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }

        let formulas = [
            epley(weight: weight, reps: reps),
            brzycki(weight: weight, reps: reps),
            lombardi(weight: weight, reps: reps),
            mayhew(weight: weight, reps: reps),
            oconner(weight: weight, reps: reps),
            wathan(weight: weight, reps: reps)
        ]

        return formulas.reduce(0, +) / Double(formulas.count)
    }

    // MARK: - Strength Targets

    /// Calculate strength targets based on 1RM and program phase
    /// - Parameters:
    ///   - oneRM: Estimated or tested 1RM
    ///   - week: Week number in program (1-8 for 8-week program)
    ///   - programType: Type of program (strength, hypertrophy, power)
    /// - Returns: StrengthTarget with load, reps, sets, and intensity
    static func strengthTargets(
        oneRM: Double,
        week: Int,
        programType: TrainingFocus = .strength
    ) -> StrengthTarget {
        let intensity = progressiveIntensity(week: week, programType: programType)
        let targetLoad = oneRM * intensity
        let targetReps = targetReps(for: intensity, programType: programType)
        let targetSets = targetSets(for: programType)

        return StrengthTarget(
            targetLoad: targetLoad,
            targetReps: targetReps,
            targetSets: targetSets,
            intensity: intensity,
            percentage1RM: Int(intensity * 100)
        )
    }

    // MARK: - Private Helpers

    /// Progressive intensity by week for 8-week program
    private static func progressiveIntensity(week: Int, programType: TrainingFocus) -> Double {
        switch programType {
        case .strength:
            // Progressive overload: 60% → 85%
            switch week {
            case 1...2: return 0.60  // Weeks 1-2: Base building
            case 3...4: return 0.70  // Weeks 3-4: Strength phase
            case 5...6: return 0.80  // Weeks 5-6: Peak phase
            case 7...8: return 0.85  // Weeks 7-8: Competition prep
            default: return 0.70
            }

        case .hypertrophy:
            // Moderate intensity for volume
            switch week {
            case 1...2: return 0.60
            case 3...4: return 0.65
            case 5...6: return 0.70
            case 7...8: return 0.75
            default: return 0.65
            }

        case .power:
            // Lower intensity, focus on speed
            switch week {
            case 1...2: return 0.50
            case 3...4: return 0.55
            case 5...6: return 0.60
            case 7...8: return 0.65
            default: return 0.55
            }

        case .endurance:
            // Low intensity, high volume
            switch week {
            case 1...2: return 0.40
            case 3...4: return 0.45
            case 5...6: return 0.50
            case 7...8: return 0.55
            default: return 0.45
            }
        }
    }

    /// Target reps based on intensity and program type
    private static func targetReps(for intensity: Double, programType: TrainingFocus) -> Int {
        switch programType {
        case .strength:
            switch intensity {
            case ..<0.65: return 12  // Light: 12 reps
            case 0.65..<0.75: return 10  // Moderate: 10 reps
            case 0.75..<0.85: return 8   // Heavy: 8 reps
            default: return 5            // Max: 5 reps
            }

        case .hypertrophy:
            return 12  // Always 8-12 reps for hypertrophy

        case .power:
            return 5   // Always 3-5 reps for power

        case .endurance:
            return 15  // Always 15+ reps for endurance
        }
    }

    /// Target sets based on program type
    private static func targetSets(for programType: TrainingFocus) -> Int {
        switch programType {
        case .strength: return 3     // 3-5 sets for strength
        case .hypertrophy: return 4  // 3-4 sets for hypertrophy
        case .power: return 5        // 5-8 sets for power
        case .endurance: return 3    // 2-3 sets for endurance
        }
    }
}

// MARK: - Supporting Types

/// Strength target prescription
struct StrengthTarget {
    let targetLoad: Double        // Weight to lift (in lbs or kg)
    let targetReps: Int            // Number of reps
    let targetSets: Int            // Number of sets
    let intensity: Double          // Decimal (0.0-1.0)
    let percentage1RM: Int         // Integer percentage (0-100)

    /// Formatted load with rounding
    var formattedLoad: Double {
        (targetLoad * 2).rounded() / 2  // Round to nearest 0.5
    }

    /// Description for display
    var description: String {
        "\(targetSets) sets × \(targetReps) reps @ \(percentage1RM)% 1RM (\(Int(formattedLoad)) lbs)"
    }
}

/// Program type
enum TrainingFocus {
    case strength      // Focus: max strength (high intensity, low reps)
    case hypertrophy   // Focus: muscle growth (moderate intensity, moderate reps)
    case power         // Focus: explosive power (low-moderate intensity, low reps)
    case endurance     // Focus: muscular endurance (low intensity, high reps)
}

// MARK: - Example Usage

/*
 Example 1: Calculate 1RM from exercise log

 let weight = 185.0  // lbs
 let reps = 8
 let estimated1RM = RMCalculator.average(weight: weight, reps: reps)
 // Result: ~230 lbs

 Example 2: Generate strength targets for Week 5 of program

 let oneRM = 250.0  // lbs (tested or estimated)
 let week = 5
 let targets = RMCalculator.strengthTargets(oneRM: oneRM, week: week)
 // Result: 3 sets × 8 reps @ 80% 1RM (200 lbs)

 Example 3: Compare all formulas

 let weight = 225.0
 let reps = 5
 print("Epley: \(RMCalculator.epley(weight: weight, reps: reps))")
 print("Brzycki: \(RMCalculator.brzycki(weight: weight, reps: reps))")
 print("Lombardi: \(RMCalculator.lombardi(weight: weight, reps: reps))")
 print("Average: \(RMCalculator.average(weight: weight, reps: reps))")
 */
