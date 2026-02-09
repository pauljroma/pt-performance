//
//  SessionToObjectiveFormatter.swift
//  PTPerformance
//
//  Helper to format session data into clinical Objective text for SOAP notes.
//  Converts exercise logs, metrics, and session data into proper clinical documentation format.
//

import Foundation

/// Formats session data into clinical Objective documentation text
struct SessionToObjectiveFormatter {

    // MARK: - Main Formatting Function

    /// Formats a session with exercise logs into clinical Objective text
    /// - Parameters:
    ///   - session: The session with logs to format
    ///   - includeExercises: Whether to include exercise details
    ///   - includePainScores: Whether to include pain scores
    ///   - includeRPE: Whether to include RPE values
    ///   - includeVolume: Whether to include volume metrics
    ///   - includeNotes: Whether to include exercise notes
    /// - Returns: Formatted clinical text for the Objective section
    static func formatObjectiveText(
        from session: SessionWithLogs,
        includeExercises: Bool = true,
        includePainScores: Bool = true,
        includeRPE: Bool = true,
        includeVolume: Bool = true,
        includeNotes: Bool = true
    ) -> String {
        var sections: [String] = []

        // Session Summary Header
        sections.append(formatSessionHeader(session))

        // Vital Metrics Summary
        if let metricsSection = formatMetricsSummary(
            session,
            includePainScores: includePainScores,
            includeRPE: includeRPE,
            includeVolume: includeVolume
        ) {
            sections.append(metricsSection)
        }

        // Exercise Performance Details
        if includeExercises && !session.exerciseLogs.isEmpty {
            sections.append(formatExerciseDetails(
                session.exerciseLogs,
                includePainScores: includePainScores,
                includeRPE: includeRPE,
                includeNotes: includeNotes
            ))
        }

        // Patient-Reported Notes
        if includeNotes, let notes = session.notes, !notes.isEmpty {
            sections.append("Patient Notes: \(notes)")
        }

        return sections.joined(separator: "\n\n")
    }

    // MARK: - Section Formatters

    /// Formats the session header with date and duration
    private static func formatSessionHeader(_ session: SessionWithLogs) -> String {
        var header = "Session Date: \(formatDate(session.sessionDate))"

        if let sessionNumber = session.sessionNumber {
            header += " (Session #\(sessionNumber))"
        }

        if let duration = session.durationMinutes {
            header += "\nSession Duration: \(duration) minutes"
        }

        return header
    }

    /// Formats the metrics summary section
    private static func formatMetricsSummary(
        _ session: SessionWithLogs,
        includePainScores: Bool,
        includeRPE: Bool,
        includeVolume: Bool
    ) -> String? {
        var metrics: [String] = []

        if includeVolume, let volume = session.totalVolume, volume > 0 {
            metrics.append("Total Volume: \(formatVolume(volume))")
        }

        if includeRPE, let avgRpe = session.avgRpe {
            metrics.append("Average RPE: \(formatDecimal(avgRpe))/10")
        }

        if includePainScores, let avgPain = session.avgPainScore {
            let painDescription = describePainLevel(avgPain)
            metrics.append("Average Pain Score: \(formatDecimal(avgPain))/10 (\(painDescription))")
        }

        guard !metrics.isEmpty else { return nil }

        return "Objective Measures:\n" + metrics.map { "- \($0)" }.joined(separator: "\n")
    }

    /// Formats individual exercise details
    private static func formatExerciseDetails(
        _ logs: [ExerciseLogDetail],
        includePainScores: Bool,
        includeRPE: Bool,
        includeNotes: Bool
    ) -> String {
        var exerciseLines: [String] = ["Exercise Performance:"]

        for log in logs {
            var line = "- \(log.exerciseName): \(log.actualSets) sets x \(log.repsDisplay) reps"

            // Add load if available
            if log.actualLoad != nil {
                line += " @ \(log.loadDisplay)"
            }

            // Add RPE
            if includeRPE {
                line += ", RPE \(log.rpe)/10"
            }

            // Add pain score
            if includePainScores && log.painScore > 0 {
                let painDesc = describePainLevel(Double(log.painScore))
                line += ", Pain \(log.painScore)/10 (\(painDesc))"
            }

            exerciseLines.append(line)

            // Add exercise-specific notes on new line if present
            if includeNotes, let notes = log.notes, !notes.isEmpty {
                exerciseLines.append("  Note: \(notes)")
            }
        }

        return exerciseLines.joined(separator: "\n")
    }

    // MARK: - Formatting Helpers

    /// Formats a date for clinical documentation
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Formats volume for display (with appropriate units)
    private static func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK lbs", volume / 1000)
        }
        return String(format: "%.0f lbs", volume)
    }

    /// Formats decimal values consistently
    private static func formatDecimal(_ value: Double) -> String {
        if value == floor(value) {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    /// Provides clinical description for pain level
    private static func describePainLevel(_ pain: Double) -> String {
        switch pain {
        case 0:
            return "no pain"
        case 1...3:
            return "mild"
        case 4...6:
            return "moderate"
        case 7...8:
            return "severe"
        case 9...10:
            return "very severe"
        default:
            return "unspecified"
        }
    }

    // MARK: - Selected Exercises Formatter

    /// Formats selected exercise logs into clinical text
    /// - Parameters:
    ///   - logs: Array of selected exercise log details
    ///   - options: Formatting options
    /// - Returns: Formatted clinical text
    static func formatSelectedExercises(
        _ logs: [ExerciseLogDetail],
        options: FormattingOptions = .default
    ) -> String {
        guard !logs.isEmpty else { return "" }

        var sections: [String] = []

        // Calculate aggregates for selected exercises
        let totalSets = logs.reduce(0) { $0 + $1.actualSets }
        let avgRPE = logs.reduce(0.0) { $0 + Double($1.rpe) } / Double(logs.count)
        let avgPain = logs.reduce(0.0) { $0 + Double($1.painScore) } / Double(logs.count)
        let maxPain = logs.map { $0.painScore }.max() ?? 0

        // Summary metrics
        if options.includeSummary {
            var summaryLines: [String] = []
            summaryLines.append("Exercises Completed: \(logs.count)")
            summaryLines.append("Total Sets: \(totalSets)")

            if options.includeRPE {
                summaryLines.append("Average RPE: \(formatDecimal(avgRPE))/10")
            }

            if options.includePainScores && maxPain > 0 {
                summaryLines.append("Average Pain: \(formatDecimal(avgPain))/10, Peak: \(maxPain)/10")
            }

            sections.append(summaryLines.joined(separator: "\n"))
        }

        // Individual exercise details
        sections.append(formatExerciseDetails(
            logs,
            includePainScores: options.includePainScores,
            includeRPE: options.includeRPE,
            includeNotes: options.includeNotes
        ))

        return sections.joined(separator: "\n\n")
    }

    // MARK: - Formatting Options

    /// Options for controlling what gets included in formatted output
    struct FormattingOptions {
        var includeExercises: Bool = true
        var includePainScores: Bool = true
        var includeRPE: Bool = true
        var includeVolume: Bool = true
        var includeNotes: Bool = true
        var includeSummary: Bool = true

        static let `default` = FormattingOptions()

        static let minimal = FormattingOptions(
            includeExercises: true,
            includePainScores: false,
            includeRPE: false,
            includeVolume: false,
            includeNotes: false,
            includeSummary: false
        )

        static let comprehensive = FormattingOptions(
            includeExercises: true,
            includePainScores: true,
            includeRPE: true,
            includeVolume: true,
            includeNotes: true,
            includeSummary: true
        )
    }
}

// MARK: - Preview Helper Extension

extension SessionWithLogs {
    /// Sample session for previews and testing
    static var sample: SessionWithLogs {
        SessionWithLogs(
            id: "sample-session-1",
            sessionNumber: 5,
            sessionDate: Date(),
            completed: true,
            notes: "Patient reported feeling stronger today.",
            totalVolume: 12500,
            avgRpe: 6.5,
            avgPainScore: 2.0,
            durationMinutes: 45,
            exerciseLogs: [
                ExerciseLogDetail(
                    id: "log-1",
                    exerciseName: "Bench Press",
                    actualSets: 3,
                    actualReps: [10, 10, 8],
                    actualLoad: 135,
                    loadUnit: "lbs",
                    rpe: 7,
                    painScore: 0,
                    notes: nil,
                    loggedAt: Date(),
                    exerciseTemplateId: nil,
                    videoUrl: nil
                ),
                ExerciseLogDetail(
                    id: "log-2",
                    exerciseName: "Shoulder External Rotation",
                    actualSets: 3,
                    actualReps: [15, 15, 15],
                    actualLoad: 8,
                    loadUnit: "lbs",
                    rpe: 5,
                    painScore: 2,
                    notes: "Mild discomfort at end range",
                    loggedAt: Date(),
                    exerciseTemplateId: nil,
                    videoUrl: nil
                ),
                ExerciseLogDetail(
                    id: "log-3",
                    exerciseName: "Lat Pulldown",
                    actualSets: 3,
                    actualReps: [12, 12, 10],
                    actualLoad: 100,
                    loadUnit: "lbs",
                    rpe: 6,
                    painScore: 0,
                    notes: nil,
                    loggedAt: Date(),
                    exerciseTemplateId: nil,
                    videoUrl: nil
                )
            ]
        )
    }
}
