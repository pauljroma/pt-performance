//
//  ExerciseSnapshotTests.swift
//  PTPerformanceTests
//
//  Snapshot/Preview verification tests for Exercise views.
//  Tests ExerciseCompactRow, ExerciseLogView, ExerciseTechniqueView,
//  and StrengthTargetsCard across different states and configurations.
//

import XCTest
import SwiftUI
@testable import PTPerformance

final class ExerciseSnapshotTests: SnapshotTestCase {

    // MARK: - Sample Data Helpers

    private static var sampleExercise: Exercise {
        Exercise(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            session_id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            exercise_template_id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            sequence: 1,
            target_sets: 3,
            target_reps: 10,
            prescribed_sets: nil,
            prescribed_reps: "8-10",
            prescribed_load: 185,
            load_unit: "lbs",
            rest_period_seconds: 120,
            notes: nil,
            exercise_templates: Exercise.ExerciseTemplate(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                name: "Back Squat",
                category: "squat",
                body_region: "lower",
                videoUrl: nil,
                videoThumbnailUrl: nil,
                videoDuration: nil,
                formCues: nil,
                techniqueCues: Exercise.TechniqueCues(
                    setup: ["Feet shoulder-width apart", "Bar on upper traps", "Core braced"],
                    execution: ["Push knees out", "Hips back and down", "Drive through heels"],
                    breathing: ["Breathe in at top", "Hold during descent", "Exhale on drive up"]
                ),
                commonMistakes: "Knees caving in, excessive forward lean, not reaching proper depth",
                safetyNotes: "Keep spine neutral throughout movement. Stop if you feel pain in knees or lower back."
            )
        )
    }

    private static var bodyweightExercise: Exercise {
        Exercise(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            session_id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            exercise_template_id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            sequence: 2,
            target_sets: 3,
            target_reps: 15,
            prescribed_sets: nil,
            prescribed_reps: "15",
            prescribed_load: nil,
            load_unit: nil,
            rest_period_seconds: 60,
            notes: nil,
            exercise_templates: Exercise.ExerciseTemplate(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
                name: "Push-ups",
                category: "push",
                body_region: "upper",
                videoUrl: nil,
                videoThumbnailUrl: nil,
                videoDuration: nil,
                formCues: nil,
                techniqueCues: nil,
                commonMistakes: nil,
                safetyNotes: nil
            )
        )
    }

    private static var exerciseWithVideo: Exercise {
        Exercise(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            session_id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            exercise_template_id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
            sequence: 3,
            target_sets: 4,
            target_reps: 8,
            prescribed_sets: nil,
            prescribed_reps: "6-8",
            prescribed_load: 135,
            load_unit: "lbs",
            rest_period_seconds: 90,
            notes: "Focus on form",
            exercise_templates: Exercise.ExerciseTemplate(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
                name: "Romanian Deadlift",
                category: "hinge",
                body_region: "lower",
                videoUrl: "https://example.com/rdl.mp4",
                videoThumbnailUrl: "https://example.com/rdl-thumb.jpg",
                videoDuration: 90,
                formCues: nil,
                techniqueCues: Exercise.TechniqueCues(
                    setup: ["Feet hip-width apart", "Grip just outside legs"],
                    execution: ["Hinge at hips", "Keep bar close", "Feel hamstring stretch"],
                    breathing: ["Inhale on descent", "Exhale on return"]
                ),
                commonMistakes: "Rounding the back, locking knees fully",
                safetyNotes: "Maintain neutral spine throughout the movement"
            )
        )
    }

    // MARK: - ExerciseTechniqueView Tests

    func testExerciseTechniqueView_LightMode() {
        let view = ExerciseTechniqueView(exercise: Self.sampleExercise)
            .lightModeTest()

        verifyViewRenders(view, named: "ExerciseTechniqueView_Light")
    }

    func testExerciseTechniqueView_DarkMode() {
        let view = ExerciseTechniqueView(exercise: Self.sampleExercise)
            .darkModeTest()

        verifyViewRenders(view, named: "ExerciseTechniqueView_Dark")
    }

    func testExerciseTechniqueView_BothColorSchemes() {
        let view = ExerciseTechniqueView(exercise: Self.sampleExercise)

        verifyViewInBothColorSchemes(view, named: "ExerciseTechniqueView")
    }

    func testExerciseTechniqueView_WithVideo() {
        let view = ExerciseTechniqueView(exercise: Self.exerciseWithVideo)
            .lightModeTest()

        verifyViewRenders(view, named: "ExerciseTechniqueView_WithVideo")
    }

    func testExerciseTechniqueView_NoVideo() {
        let view = ExerciseTechniqueView(exercise: Self.bodyweightExercise)
            .lightModeTest()

        verifyViewRenders(view, named: "ExerciseTechniqueView_NoVideo")
    }

    func testExerciseTechniqueView_AccessibilityTextSizes() {
        let view = ExerciseTechniqueView(exercise: Self.sampleExercise)

        verifyViewAcrossDynamicTypeSizes(view, named: "ExerciseTechniqueView")
    }

    func testExerciseTechniqueView_iPhoneAndIPad() {
        let view = ExerciseTechniqueView(exercise: Self.sampleExercise)

        verifyViewAcrossDevices(
            view,
            named: "ExerciseTechniqueView",
            devices: [.iPhone15Pro, .iPadPro]
        )
    }

    // MARK: - StrengthTargetsCard Tests

    func testStrengthTargetsCard_With1RM_LightMode() {
        let view = StrengthTargetsCard(
            exercise: Self.sampleExercise,
            oneRepMax: 225
        )
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "StrengthTargetsCard_With1RM_Light")
    }

    func testStrengthTargetsCard_With1RM_DarkMode() {
        let view = StrengthTargetsCard(
            exercise: Self.sampleExercise,
            oneRepMax: 225
        )
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "StrengthTargetsCard_With1RM_Dark")
    }

    func testStrengthTargetsCard_Without1RM_LightMode() {
        let view = StrengthTargetsCard(
            exercise: Self.sampleExercise,
            oneRepMax: nil
        )
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "StrengthTargetsCard_Without1RM_Light")
    }

    func testStrengthTargetsCard_Without1RM_DarkMode() {
        let view = StrengthTargetsCard(
            exercise: Self.sampleExercise,
            oneRepMax: nil
        )
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "StrengthTargetsCard_Without1RM_Dark")
    }

    func testStrengthTargetsCard_BothColorSchemes() {
        let view = StrengthTargetsCard(
            exercise: Self.sampleExercise,
            oneRepMax: 315
        )
        .frame(width: 350)
        .padding()

        verifyViewInBothColorSchemes(view, named: "StrengthTargetsCard")
    }

    func testStrengthTargetsCard_AccessibilityTextSizes() {
        let view = StrengthTargetsCard(
            exercise: Self.sampleExercise,
            oneRepMax: 275
        )
        .frame(width: 350)
        .padding()

        verifyViewAcrossDynamicTypeSizes(view, named: "StrengthTargetsCard")
    }

    func testStrengthTargetsCard_Heavy1RM() {
        let view = StrengthTargetsCard(
            exercise: Self.sampleExercise,
            oneRepMax: 500
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "StrengthTargetsCard_Heavy1RM")
    }

    func testStrengthTargetsCard_Light1RM() {
        let view = StrengthTargetsCard(
            exercise: Self.sampleExercise,
            oneRepMax: 95
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "StrengthTargetsCard_Light1RM")
    }

    // MARK: - VideoPlaceholderView Tests

    func testVideoPlaceholderView_LightMode() {
        let view = VideoPlaceholderView(exerciseName: "Romanian Deadlift")
            .frame(height: 250)
            .cornerRadius(12)
            .padding()
            .lightModeTest()

        verifyViewRenders(view, named: "VideoPlaceholderView_Light")
    }

    func testVideoPlaceholderView_DarkMode() {
        let view = VideoPlaceholderView(exerciseName: "Romanian Deadlift")
            .frame(height: 250)
            .cornerRadius(12)
            .padding()
            .darkModeTest()

        verifyViewRenders(view, named: "VideoPlaceholderView_Dark")
    }

    func testVideoPlaceholderView_BothColorSchemes() {
        let view = VideoPlaceholderView(exerciseName: "Back Squat")
            .frame(height: 250)
            .cornerRadius(12)
            .padding()

        verifyViewInBothColorSchemes(view, named: "VideoPlaceholderView")
    }

    // MARK: - CommonMistakesCard Tests

    func testCommonMistakesCard_LightMode() {
        let view = CommonMistakesCard(
            mistakes: "Knees caving in, excessive forward lean, not reaching proper depth"
        )
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "CommonMistakesCard_Light")
    }

    func testCommonMistakesCard_DarkMode() {
        let view = CommonMistakesCard(
            mistakes: "Rounding the lower back, using momentum instead of controlled movement"
        )
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "CommonMistakesCard_Dark")
    }

    func testCommonMistakesCard_BothColorSchemes() {
        let view = CommonMistakesCard(
            mistakes: "Allowing knees to pass too far over toes, bouncing at the bottom"
        )
        .frame(width: 350)
        .padding()

        verifyViewInBothColorSchemes(view, named: "CommonMistakesCard")
    }

    // MARK: - SafetyNotesCard Tests

    func testSafetyNotesCard_LightMode() {
        let view = SafetyNotesCard(
            notes: "Keep spine neutral throughout movement. Stop if you feel pain in knees or lower back."
        )
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "SafetyNotesCard_Light")
    }

    func testSafetyNotesCard_DarkMode() {
        let view = SafetyNotesCard(
            notes: "Ensure proper warm-up before heavy lifting. Use a spotter when working near maximal loads."
        )
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "SafetyNotesCard_Dark")
    }

    func testSafetyNotesCard_BothColorSchemes() {
        let view = SafetyNotesCard(
            notes: "Progress gradually. Listen to your body."
        )
        .frame(width: 350)
        .padding()

        verifyViewInBothColorSchemes(view, named: "SafetyNotesCard")
    }

    // MARK: - PrescriptionInfoCard Tests

    func testPrescriptionInfoCard_WithLoad_LightMode() {
        let view = PrescriptionInfoCard(exercise: Self.sampleExercise)
            .frame(width: 350)
            .lightModeTest()
            .padding()

        verifyViewRenders(view, named: "PrescriptionInfoCard_WithLoad_Light")
    }

    func testPrescriptionInfoCard_WithLoad_DarkMode() {
        let view = PrescriptionInfoCard(exercise: Self.sampleExercise)
            .frame(width: 350)
            .darkModeTest()
            .padding()

        verifyViewRenders(view, named: "PrescriptionInfoCard_WithLoad_Dark")
    }

    func testPrescriptionInfoCard_Bodyweight() {
        let view = PrescriptionInfoCard(exercise: Self.bodyweightExercise)
            .frame(width: 350)
            .padding()

        verifyViewRenders(view, named: "PrescriptionInfoCard_Bodyweight")
    }

    func testPrescriptionInfoCard_BothColorSchemes() {
        let view = PrescriptionInfoCard(exercise: Self.sampleExercise)
            .frame(width: 350)
            .padding()

        verifyViewInBothColorSchemes(view, named: "PrescriptionInfoCard")
    }

    // MARK: - TargetRow Tests

    func testTargetRow_Strength() {
        let view = TargetRow(
            goal: "Strength",
            percentage: 0.85,
            oneRM: 225,
            color: .red,
            icon: "bolt.fill"
        )
        .frame(width: 300)
        .padding()

        verifyViewRenders(view, named: "TargetRow_Strength")
    }

    func testTargetRow_Hypertrophy() {
        let view = TargetRow(
            goal: "Hypertrophy",
            percentage: 0.70,
            oneRM: 225,
            color: .orange,
            icon: "figure.arms.open"
        )
        .frame(width: 300)
        .padding()

        verifyViewRenders(view, named: "TargetRow_Hypertrophy")
    }

    func testTargetRow_Endurance() {
        let view = TargetRow(
            goal: "Endurance",
            percentage: 0.50,
            oneRM: 225,
            color: .green,
            icon: "arrow.clockwise"
        )
        .frame(width: 300)
        .padding()

        verifyViewRenders(view, named: "TargetRow_Endurance")
    }

    func testTargetRow_BothColorSchemes() {
        let view = TargetRow(
            goal: "Strength",
            percentage: 0.85,
            oneRM: 315,
            color: .red,
            icon: "bolt.fill"
        )
        .frame(width: 300)
        .padding()

        verifyViewInBothColorSchemes(view, named: "TargetRow")
    }

    // MARK: - Comprehensive Gallery Tests

    func testExerciseComponentsGallery_LightMode() {
        let view = ScrollView {
            VStack(spacing: 16) {
                StrengthTargetsCard(exercise: Self.sampleExercise, oneRepMax: 225)
                CommonMistakesCard(mistakes: "Sample mistakes text")
                SafetyNotesCard(notes: "Sample safety notes")
                PrescriptionInfoCard(exercise: Self.sampleExercise)
            }
            .frame(width: 350)
            .padding()
        }
        .lightModeTest()

        verifyViewRenders(view, named: "ExerciseComponentsGallery_Light")
    }

    func testExerciseComponentsGallery_DarkMode() {
        let view = ScrollView {
            VStack(spacing: 16) {
                StrengthTargetsCard(exercise: Self.sampleExercise, oneRepMax: 225)
                CommonMistakesCard(mistakes: "Sample mistakes text")
                SafetyNotesCard(notes: "Sample safety notes")
                PrescriptionInfoCard(exercise: Self.sampleExercise)
            }
            .frame(width: 350)
            .padding()
        }
        .darkModeTest()

        verifyViewRenders(view, named: "ExerciseComponentsGallery_Dark")
    }
}
