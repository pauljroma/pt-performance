//
//  ComplicationController.swift
//  PTPerformanceWatch
//
//  Watch face complications for workout status
//  ACP-824: Apple Watch Standalone App
//

import ClockKit
import SwiftUI

/// Provides data for Watch face complications
class ComplicationController: NSObject, CLKComplicationDataSource {

    // MARK: - Complication Configuration

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "workout-status",
                displayName: "Workout Status",
                supportedFamilies: CLKComplicationFamily.allCases
            ),
            CLKComplicationDescriptor(
                identifier: "next-workout",
                displayName: "Next Workout",
                supportedFamilies: [.modularLarge, .graphicRectangular, .graphicExtraLarge]
            ),
            CLKComplicationDescriptor(
                identifier: "streak",
                displayName: "Workout Streak",
                supportedFamilies: [.circularSmall, .modularSmall, .graphicCircular, .graphicCorner]
            )
        ]

        handler(descriptors)
    }

    // MARK: - Timeline Configuration

    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Provide data for the next 24 hours
        handler(Date().addingTimeInterval(24 * 60 * 60))
    }

    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Show workout data on locked screen
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population

    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let entry = createTimelineEntry(for: complication, date: Date())
        handler(entry)
    }

    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        var entries: [CLKComplicationTimelineEntry] = []

        // Create entries for the next few hours
        let calendar = Calendar.current
        var currentDate = date

        for _ in 0..<min(limit, 8) {
            currentDate = calendar.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
            if let entry = createTimelineEntry(for: complication, date: currentDate) {
                entries.append(entry)
            }
        }

        handler(entries)
    }

    // MARK: - Template Creation

    private func createTimelineEntry(for complication: CLKComplication, date: Date) -> CLKComplicationTimelineEntry? {
        guard let template = createTemplate(for: complication, date: date) else {
            return nil
        }

        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }

    private func createTemplate(for complication: CLKComplication, date: Date) -> CLKComplicationTemplate? {
        switch complication.identifier {
        case "workout-status":
            return createWorkoutStatusTemplate(for: complication.family)
        case "next-workout":
            return createNextWorkoutTemplate(for: complication.family)
        case "streak":
            return createStreakTemplate(for: complication.family)
        default:
            return createWorkoutStatusTemplate(for: complication.family)
        }
    }

    // MARK: - Workout Status Templates

    private func createWorkoutStatusTemplate(for family: CLKComplicationFamily) -> CLKComplicationTemplate? {
        let workoutData = getWorkoutData()

        switch family {
        case .modularSmall:
            return CLKComplicationTemplateModularSmallSimpleText(
                textProvider: CLKSimpleTextProvider(text: workoutData.shortStatus)
            )

        case .modularLarge:
            return CLKComplicationTemplateModularLargeStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "PT Performance"),
                body1TextProvider: CLKSimpleTextProvider(text: workoutData.nextWorkout),
                body2TextProvider: CLKSimpleTextProvider(text: workoutData.status)
            )

        case .utilitarianSmall, .utilitarianSmallFlat:
            return CLKComplicationTemplateUtilitarianSmallFlat(
                textProvider: CLKSimpleTextProvider(text: workoutData.shortStatus)
            )

        case .utilitarianLarge:
            return CLKComplicationTemplateUtilitarianLargeFlat(
                textProvider: CLKSimpleTextProvider(text: workoutData.status)
            )

        case .circularSmall:
            return CLKComplicationTemplateCircularSmallSimpleText(
                textProvider: CLKSimpleTextProvider(text: workoutData.emoji)
            )

        case .extraLarge:
            return CLKComplicationTemplateExtraLargeSimpleText(
                textProvider: CLKSimpleTextProvider(text: workoutData.shortStatus)
            )

        case .graphicCorner:
            return CLKComplicationTemplateGraphicCornerTextImage(
                textProvider: CLKSimpleTextProvider(text: workoutData.status),
                imageProvider: CLKFullColorImageProvider(fullColorImage: createWorkoutIcon())
            )

        case .graphicBezel:
            let circularTemplate = CLKComplicationTemplateGraphicCircularImage(
                imageProvider: CLKFullColorImageProvider(fullColorImage: createWorkoutIcon())
            )
            return CLKComplicationTemplateGraphicBezelCircularText(
                circularTemplate: circularTemplate,
                textProvider: CLKSimpleTextProvider(text: workoutData.status)
            )

        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularStackText(
                line1TextProvider: CLKSimpleTextProvider(text: workoutData.emoji),
                line2TextProvider: CLKSimpleTextProvider(text: workoutData.shortStatus)
            )

        case .graphicRectangular:
            return CLKComplicationTemplateGraphicRectangularStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "Next Workout"),
                body1TextProvider: CLKSimpleTextProvider(text: workoutData.nextWorkout),
                body2TextProvider: CLKSimpleTextProvider(text: workoutData.time)
            )

        case .graphicExtraLarge:
            return CLKComplicationTemplateGraphicExtraLargeCircularStackText(
                line1TextProvider: CLKSimpleTextProvider(text: workoutData.nextWorkout),
                line2TextProvider: CLKSimpleTextProvider(text: workoutData.time)
            )

        @unknown default:
            return nil
        }
    }

    // MARK: - Streak Templates

    private func createStreakTemplate(for family: CLKComplicationFamily) -> CLKComplicationTemplate? {
        let streakCount = getStreakCount()

        switch family {
        case .circularSmall:
            return CLKComplicationTemplateCircularSmallStackText(
                line1TextProvider: CLKSimpleTextProvider(text: "\(streakCount)"),
                line2TextProvider: CLKSimpleTextProvider(text: "days")
            )

        case .modularSmall:
            return CLKComplicationTemplateModularSmallStackText(
                line1TextProvider: CLKSimpleTextProvider(text: "\(streakCount)"),
                line2TextProvider: CLKSimpleTextProvider(text: "streak")
            )

        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularStackText(
                line1TextProvider: CLKSimpleTextProvider(text: "\(streakCount)"),
                line2TextProvider: CLKSimpleTextProvider(text: "days")
            )

        case .graphicCorner:
            return CLKComplicationTemplateGraphicCornerStackText(
                innerTextProvider: CLKSimpleTextProvider(text: "\(streakCount)"),
                outerTextProvider: CLKSimpleTextProvider(text: "day streak")
            )

        default:
            return nil
        }
    }

    // MARK: - Next Workout Templates

    private func createNextWorkoutTemplate(for family: CLKComplicationFamily) -> CLKComplicationTemplate? {
        let workoutData = getWorkoutData()

        switch family {
        case .modularLarge:
            return CLKComplicationTemplateModularLargeColumns(
                row1Column1TextProvider: CLKSimpleTextProvider(text: "Next"),
                row1Column2TextProvider: CLKSimpleTextProvider(text: workoutData.time),
                row2Column1TextProvider: CLKSimpleTextProvider(text: workoutData.nextWorkout),
                row2Column2TextProvider: CLKSimpleTextProvider(text: workoutData.exerciseCount)
            )

        case .graphicRectangular:
            return CLKComplicationTemplateGraphicRectangularFullView(
                WorkoutComplicationView(
                    workoutName: workoutData.nextWorkout,
                    time: workoutData.time,
                    exerciseCount: workoutData.exerciseCount
                )
            )

        case .graphicExtraLarge:
            return CLKComplicationTemplateGraphicExtraLargeCircularStackText(
                line1TextProvider: CLKSimpleTextProvider(text: workoutData.nextWorkout),
                line2TextProvider: CLKSimpleTextProvider(text: workoutData.time)
            )

        default:
            return nil
        }
    }

    // MARK: - Data Helpers

    private struct WorkoutData {
        let status: String
        let shortStatus: String
        let nextWorkout: String
        let time: String
        let exerciseCount: String
        let emoji: String
    }

    private func getWorkoutData() -> WorkoutData {
        // In production, this would read from shared storage
        // For now, return sample data
        let sessions = WatchWorkoutStorage.shared.loadTodaysSessions()

        if let nextSession = sessions.first(where: { $0.status == .scheduled }) {
            return WorkoutData(
                status: "Workout at \(nextSession.formattedTime)",
                shortStatus: nextSession.formattedTime,
                nextWorkout: nextSession.name,
                time: nextSession.formattedTime,
                exerciseCount: "\(nextSession.exercises.count) ex",
                emoji: "..."
            )
        } else if let completedSession = sessions.first(where: { $0.status == .completed }) {
            return WorkoutData(
                status: "Workout Complete",
                shortStatus: "Done",
                nextWorkout: completedSession.name,
                time: "Completed",
                exerciseCount: "\(completedSession.completedExercises)/\(completedSession.totalExercises)",
                emoji: "Checkmark"
            )
        } else {
            return WorkoutData(
                status: "Rest Day",
                shortStatus: "Rest",
                nextWorkout: "No workout today",
                time: "--",
                exerciseCount: "--",
                emoji: "Zzz"
            )
        }
    }

    private func getStreakCount() -> Int {
        // In production, read from shared storage or sync from iPhone
        return UserDefaults.standard.integer(forKey: "PTPerformance.StreakCount")
    }

    private func createWorkoutIcon() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20))
        return renderer.image { ctx in
            UIColor.systemBlue.setFill()
            let path = UIBezierPath(ovalIn: CGRect(x: 2, y: 2, width: 16, height: 16))
            path.fill()
        }
    }

    // MARK: - Placeholder Template

    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let template = createTemplate(for: complication, date: Date())
        handler(template)
    }
}

// MARK: - SwiftUI Complication View

struct WorkoutComplicationView: View {
    let workoutName: String
    let time: String
    let exerciseCount: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.blue)
                Text("Next Workout")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(workoutName)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)

            HStack {
                Text(time)
                    .font(.caption2)
                Spacer()
                Text(exerciseCount)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(4)
    }
}
