/**
 * One-Rep Max (1RM) Calculator
 * Implements standard 1RM estimation formulas for strength training
 */

/**
 * Epley formula: 1RM = weight × (1 + reps / 30)
 * Most commonly used, accurate for reps 1-10
 */
function epley(weight, reps) {
    if (weight <= 0 || reps <= 0) return 0;
    return weight * (1 + reps / 30);
}

/**
 * Brzycki formula: 1RM = weight × (36 / (37 - reps))
 * Accurate for higher rep ranges (1-12 reps)
 */
function brzycki(weight, reps) {
    if (weight <= 0 || reps <= 0 || reps >= 37) return 0;
    return weight * (36 / (37 - reps));
}

/**
 * Lombardi formula: 1RM = weight × reps^0.1
 * Conservative estimate, works well for lower reps
 */
function lombardi(weight, reps) {
    if (weight <= 0 || reps <= 0) return 0;
    return weight * Math.pow(reps, 0.1);
}

/**
 * Mayhew formula: 1RM = (100 × weight) / (52.2 + (41.9 × e^(-0.055 × reps)))
 * More accurate for higher rep ranges
 */
function mayhew(weight, reps) {
    if (weight <= 0 || reps <= 0) return 0;
    const denominator = 52.2 + (41.9 * Math.exp(-0.055 * reps));
    return (100 * weight) / denominator;
}

/**
 * O'Conner formula: 1RM = weight × (1 + reps / 40)
 * Similar to Epley but more conservative
 */
function oconner(weight, reps) {
    if (weight <= 0 || reps <= 0) return 0;
    return weight * (1 + reps / 40);
}

/**
 * Wathan formula: 1RM = (100 × weight) / (48.8 + (53.8 × e^(-0.075 × reps)))
 * Good for general population
 */
function wathan(weight, reps) {
    if (weight <= 0 || reps <= 0) return 0;
    const denominator = 48.8 + (53.8 * Math.exp(-0.075 * reps));
    return (100 * weight) / denominator;
}

/**
 * Average of Epley, Brzycki, and Lombardi
 * Provides a balanced estimate across different rep ranges
 */
function average(weight, reps) {
    if (weight <= 0 || reps <= 0) return 0;

    const e = epley(weight, reps);
    const b = brzycki(weight, reps);
    const l = lombardi(weight, reps);

    return (e + b + l) / 3;
}

/**
 * Average of all six formulas for maximum accuracy
 */
function averageAll(weight, reps) {
    if (weight <= 0 || reps <= 0) return 0;

    const formulas = [
        epley(weight, reps),
        brzycki(weight, reps),
        lombardi(weight, reps),
        mayhew(weight, reps),
        oconner(weight, reps),
        wathan(weight, reps)
    ];

    return formulas.reduce((sum, val) => sum + val, 0) / formulas.length;
}

/**
 * Calculate strength targets based on 1RM and program phase
 */
function strengthTargets(oneRM, week, programType = 'strength') {
    const intensity = progressiveIntensity(week, programType);
    const targetLoad = oneRM * intensity;
    const targetReps = getTargetReps(intensity, programType);
    const targetSets = getTargetSets(programType);

    return {
        targetLoad: Math.round(targetLoad * 2) / 2,  // Round to nearest 0.5
        targetReps,
        targetSets,
        intensity,
        percentage1RM: Math.round(intensity * 100)
    };
}

/**
 * Progressive intensity by week for 8-week program
 */
function progressiveIntensity(week, programType) {
    const intensityMap = {
        strength: [0.60, 0.60, 0.70, 0.70, 0.80, 0.80, 0.85, 0.85],
        hypertrophy: [0.60, 0.60, 0.65, 0.65, 0.70, 0.70, 0.75, 0.75],
        power: [0.50, 0.50, 0.55, 0.55, 0.60, 0.60, 0.65, 0.65],
        endurance: [0.40, 0.40, 0.45, 0.45, 0.50, 0.50, 0.55, 0.55]
    };

    const weekIndex = Math.min(Math.max(week - 1, 0), 7);
    return intensityMap[programType] ? intensityMap[programType][weekIndex] : 0.70;
}

/**
 * Target reps based on intensity and program type
 */
function getTargetReps(intensity, programType) {
    if (programType === 'hypertrophy') return 12;
    if (programType === 'power') return 5;
    if (programType === 'endurance') return 15;

    // Strength program
    if (intensity < 0.65) return 12;
    if (intensity < 0.75) return 10;
    if (intensity < 0.85) return 8;
    return 5;
}

/**
 * Target sets based on program type
 */
function getTargetSets(programType) {
    const setsMap = {
        strength: 3,
        hypertrophy: 4,
        power: 5,
        endurance: 3
    };

    return setsMap[programType] || 3;
}

module.exports = {
    epley,
    brzycki,
    lombardi,
    mayhew,
    oconner,
    wathan,
    average,
    averageAll,
    strengthTargets,
    progressiveIntensity,
    getTargetReps,
    getTargetSets
};
