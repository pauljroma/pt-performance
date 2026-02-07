//
//  WorkoutSnapshotTests.swift
//  PTPerformanceTests
//
//  Snapshot/Preview verification tests for Workout views.
//  Tests OptimisticWorkoutExecutionView, OptimisticSetRow, RestTimerOverlay,
//  and set logging components across different states and configurations.
//

import XCTest
import SwiftUI
@testable import PTPerformance

final class WorkoutSnapshotTests: SnapshotTestCase {

    // MARK: - OptimisticSetRow Tests

    func testOptimisticSetRow_Incomplete_LightMode() {
        let view = StatefulTestWrapper(false) { isCompleted in
            OptimisticSetRow(
                setNumber: 1,
                reps: .constant(10),
                weight: .constant(135),
                isCompleted: isCompleted,
                loadUnit: "lbs",
                targetReps: 10,
                targetWeight: 135,
                onComplete: {}
            )
        }
        .lightModeTest()
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "OptimisticSetRow_Incomplete_Light")
    }

    func testOptimisticSetRow_Incomplete_DarkMode() {
        let view = StatefulTestWrapper(false) { isCompleted in
            OptimisticSetRow(
                setNumber: 1,
                reps: .constant(10),
                weight: .constant(135),
                isCompleted: isCompleted,
                loadUnit: "lbs",
                targetReps: 10,
                targetWeight: 135,
                onComplete: {}
            )
        }
        .darkModeTest()
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "OptimisticSetRow_Incomplete_Dark")
    }

    func testOptimisticSetRow_Completed_LightMode() {
        let view = OptimisticSetRow(
            setNumber: 2,
            reps: .constant(10),
            weight: .constant(135),
            isCompleted: .constant(true),
            loadUnit: "lbs",
            targetReps: 10,
            targetWeight: 135,
            onComplete: {}
        )
        .lightModeTest()
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "OptimisticSetRow_Completed_Light")
    }

    func testOptimisticSetRow_Completed_DarkMode() {
        let view = OptimisticSetRow(
            setNumber: 2,
            reps: .constant(10),
            weight: .constant(135),
            isCompleted: .constant(true),
            loadUnit: "lbs",
            targetReps: 10,
            targetWeight: 135,
            onComplete: {}
        )
        .darkModeTest()
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "OptimisticSetRow_Completed_Dark")
    }

    func testOptimisticSetRow_Bodyweight() {
        let view = OptimisticSetRow(
            setNumber: 3,
            reps: .constant(15),
            weight: .constant(0),
            isCompleted: .constant(false),
            loadUnit: "lbs",
            targetReps: 15,
            targetWeight: 0,
            onComplete: {}
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "OptimisticSetRow_Bodyweight")
    }

    func testOptimisticSetRow_KgUnits() {
        let view = OptimisticSetRow(
            setNumber: 1,
            reps: .constant(8),
            weight: .constant(60),
            isCompleted: .constant(false),
            loadUnit: "kg",
            targetReps: 8,
            targetWeight: 60,
            onComplete: {}
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "OptimisticSetRow_Kg")
    }

    func testOptimisticSetRow_BothColorSchemes() {
        let view = OptimisticSetRow(
            setNumber: 1,
            reps: .constant(10),
            weight: .constant(135),
            isCompleted: .constant(false),
            loadUnit: "lbs",
            targetReps: 10,
            targetWeight: 135,
            onComplete: {}
        )
        .frame(width: 350)
        .padding()

        verifyViewInBothColorSchemes(view, named: "OptimisticSetRow")
    }

    func testOptimisticSetRow_AccessibilityTextSizes() {
        let view = OptimisticSetRow(
            setNumber: 1,
            reps: .constant(10),
            weight: .constant(135),
            isCompleted: .constant(false),
            loadUnit: "lbs",
            targetReps: 10,
            targetWeight: 135,
            onComplete: {}
        )
        .frame(width: 350)
        .padding()

        verifyViewAcrossDynamicTypeSizes(view, named: "OptimisticSetRow")
    }

    // MARK: - RestTimerOverlay Tests

    func testRestTimerOverlay_FullTime_LightMode() {
        let view = RestTimerOverlay(
            timeRemaining: 90,
            totalTime: 90,
            onSkip: {}
        )
        .lightModeTest()

        verifyViewRenders(view, named: "RestTimerOverlay_Full_Light")
    }

    func testRestTimerOverlay_FullTime_DarkMode() {
        let view = RestTimerOverlay(
            timeRemaining: 90,
            totalTime: 90,
            onSkip: {}
        )
        .darkModeTest()

        verifyViewRenders(view, named: "RestTimerOverlay_Full_Dark")
    }

    func testRestTimerOverlay_HalfTime() {
        let view = RestTimerOverlay(
            timeRemaining: 45,
            totalTime: 90,
            onSkip: {}
        )

        verifyViewRenders(view, named: "RestTimerOverlay_Half")
    }

    func testRestTimerOverlay_NearlyComplete() {
        let view = RestTimerOverlay(
            timeRemaining: 5,
            totalTime: 90,
            onSkip: {}
        )

        verifyViewRenders(view, named: "RestTimerOverlay_NearlyComplete")
    }

    func testRestTimerOverlay_ShortRest() {
        let view = RestTimerOverlay(
            timeRemaining: 30,
            totalTime: 30,
            onSkip: {}
        )

        verifyViewRenders(view, named: "RestTimerOverlay_Short")
    }

    func testRestTimerOverlay_LongRest() {
        let view = RestTimerOverlay(
            timeRemaining: 180,
            totalTime: 180,
            onSkip: {}
        )

        verifyViewRenders(view, named: "RestTimerOverlay_Long")
    }

    func testRestTimerOverlay_BothColorSchemes() {
        let view = RestTimerOverlay(
            timeRemaining: 45,
            totalTime: 90,
            onSkip: {}
        )

        verifyViewInBothColorSchemes(view, named: "RestTimerOverlay")
    }

    func testRestTimerOverlay_AccessibilityTextSizes() {
        let view = RestTimerOverlay(
            timeRemaining: 45,
            totalTime: 90,
            onSkip: {}
        )

        verifyViewAcrossDynamicTypeSizes(view, named: "RestTimerOverlay")
    }

    // MARK: - TappableRepCounter Tests

    func testTappableRepCounter_AtTarget() {
        let view = StatefulTestWrapper(10) { reps in
            TappableRepCounter(reps: reps, prescribedReps: 10)
        }
        .frame(width: 100)
        .padding()

        verifyViewRenders(view, named: "TappableRepCounter_AtTarget")
    }

    func testTappableRepCounter_BelowTarget() {
        let view = StatefulTestWrapper(8) { reps in
            TappableRepCounter(reps: reps, prescribedReps: 10)
        }
        .frame(width: 100)
        .padding()

        verifyViewRenders(view, named: "TappableRepCounter_BelowTarget")
    }

    func testTappableRepCounter_AboveTarget() {
        let view = StatefulTestWrapper(12) { reps in
            TappableRepCounter(reps: reps, prescribedReps: 10)
        }
        .frame(width: 100)
        .padding()

        verifyViewRenders(view, named: "TappableRepCounter_AboveTarget")
    }

    func testTappableRepCounter_BothColorSchemes() {
        let view = StatefulTestWrapper(10) { reps in
            TappableRepCounter(reps: reps, prescribedReps: 10)
        }
        .frame(width: 100)
        .padding()

        verifyViewInBothColorSchemes(view, named: "TappableRepCounter")
    }

    // MARK: - SwipeableWeightControl Tests

    func testSwipeableWeightControl_Standard() {
        let view = StatefulTestWrapper(135.0) { weight in
            SwipeableWeightControl(weight: weight, increment: 5.0)
        }
        .frame(width: 100)
        .padding()

        verifyViewRenders(view, named: "SwipeableWeightControl_Standard")
    }

    func testSwipeableWeightControl_KgIncrement() {
        let view = StatefulTestWrapper(60.0) { weight in
            SwipeableWeightControl(weight: weight, increment: 2.5)
        }
        .frame(width: 100)
        .padding()

        verifyViewRenders(view, named: "SwipeableWeightControl_Kg")
    }

    func testSwipeableWeightControl_ZeroWeight() {
        let view = StatefulTestWrapper(0.0) { weight in
            SwipeableWeightControl(weight: weight, increment: 5.0)
        }
        .frame(width: 100)
        .padding()

        verifyViewRenders(view, named: "SwipeableWeightControl_Zero")
    }

    func testSwipeableWeightControl_HeavyWeight() {
        let view = StatefulTestWrapper(315.0) { weight in
            SwipeableWeightControl(weight: weight, increment: 5.0)
        }
        .frame(width: 100)
        .padding()

        verifyViewRenders(view, named: "SwipeableWeightControl_Heavy")
    }

    func testSwipeableWeightControl_BothColorSchemes() {
        let view = StatefulTestWrapper(135.0) { weight in
            SwipeableWeightControl(weight: weight, increment: 5.0)
        }
        .frame(width: 100)
        .padding()

        verifyViewInBothColorSchemes(view, named: "SwipeableWeightControl")
    }

    // MARK: - RepsEditorSheet Tests

    func testRepsEditorSheet_Standard() {
        let view = StatefulTestWrapper(10) { reps in
            RepsEditorSheet(
                reps: reps,
                targetReps: 10,
                onDismiss: {}
            )
        }

        verifyViewRenders(view, named: "RepsEditorSheet_Standard")
    }

    func testRepsEditorSheet_BothColorSchemes() {
        let view = StatefulTestWrapper(10) { reps in
            RepsEditorSheet(
                reps: reps,
                targetReps: 10,
                onDismiss: {}
            )
        }

        verifyViewInBothColorSchemes(view, named: "RepsEditorSheet")
    }

    // MARK: - WeightEditorSheet Tests

    func testWeightEditorSheet_Lbs() {
        let view = StatefulTestWrapper(135.0) { weight in
            WeightEditorSheet(
                weight: weight,
                loadUnit: "lbs",
                targetWeight: 135,
                onDismiss: {}
            )
        }

        verifyViewRenders(view, named: "WeightEditorSheet_Lbs")
    }

    func testWeightEditorSheet_Kg() {
        let view = StatefulTestWrapper(60.0) { weight in
            WeightEditorSheet(
                weight: weight,
                loadUnit: "kg",
                targetWeight: 60,
                onDismiss: {}
            )
        }

        verifyViewRenders(view, named: "WeightEditorSheet_Kg")
    }

    func testWeightEditorSheet_BothColorSchemes() {
        let view = StatefulTestWrapper(135.0) { weight in
            WeightEditorSheet(
                weight: weight,
                loadUnit: "lbs",
                targetWeight: 135,
                onDismiss: {}
            )
        }

        verifyViewInBothColorSchemes(view, named: "WeightEditorSheet")
    }

    // MARK: - WorkoutCompletionSummary Tests

    func testWorkoutCompletionSummary_LightMode() {
        let viewModel = MockOptimisticWorkoutViewModel()
        let view = WorkoutCompletionSummary(
            viewModel: viewModel,
            onDismiss: {}
        )
        .lightModeTest()

        verifyViewRenders(view, named: "WorkoutCompletionSummary_Light")
    }

    func testWorkoutCompletionSummary_DarkMode() {
        let viewModel = MockOptimisticWorkoutViewModel()
        let view = WorkoutCompletionSummary(
            viewModel: viewModel,
            onDismiss: {}
        )
        .darkModeTest()

        verifyViewRenders(view, named: "WorkoutCompletionSummary_Dark")
    }

    func testWorkoutCompletionSummary_BothColorSchemes() {
        let viewModel = MockOptimisticWorkoutViewModel()
        let view = WorkoutCompletionSummary(
            viewModel: viewModel,
            onDismiss: {}
        )

        verifyViewInBothColorSchemes(view, named: "WorkoutCompletionSummary")
    }

    // MARK: - Set Row Variations

    func testSetRowList_MultipleStates() {
        let view = VStack(spacing: 8) {
            // Completed set
            OptimisticSetRow(
                setNumber: 1,
                reps: .constant(10),
                weight: .constant(135),
                isCompleted: .constant(true),
                loadUnit: "lbs",
                targetReps: 10,
                targetWeight: 135,
                onComplete: {}
            )

            // Current set (incomplete)
            OptimisticSetRow(
                setNumber: 2,
                reps: .constant(10),
                weight: .constant(135),
                isCompleted: .constant(false),
                loadUnit: "lbs",
                targetReps: 10,
                targetWeight: 135,
                onComplete: {}
            )

            // Upcoming set (incomplete)
            OptimisticSetRow(
                setNumber: 3,
                reps: .constant(10),
                weight: .constant(135),
                isCompleted: .constant(false),
                loadUnit: "lbs",
                targetReps: 10,
                targetWeight: 135,
                onComplete: {}
            )
        }
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "SetRowList_MultipleStates")
    }

    // MARK: - TodayWorkoutCard Tests

    func testTodayWorkoutCard_WithExercises_LightMode() {
        let session = Session(
            id: UUID(),
            phase_id: UUID(),
            name: "Upper Body Strength",
            sequence: 1,
            weekday: 1,
            notes: nil,
            created_at: Date(),
            completed: false,
            started_at: nil,
            completed_at: nil,
            total_volume: nil,
            avg_rpe: nil,
            avg_pain: nil,
            duration_minutes: nil
        )

        let view = TodayWorkoutCard(
            session: session,
            exercises: Exercise.sampleExercises,
            onStartWorkout: {},
            onRefresh: {},
            onExerciseSelected: { _ in }
        )
        .frame(width: 350)
        .lightModeTest()
        .padding()

        verifyViewRenders(view, named: "TodayWorkoutCard_WithExercises_Light")
    }

    func testTodayWorkoutCard_WithExercises_DarkMode() {
        let session = Session(
            id: UUID(),
            phase_id: UUID(),
            name: "Lower Body Power",
            sequence: 2,
            weekday: 3,
            notes: nil,
            created_at: Date(),
            completed: false,
            started_at: nil,
            completed_at: nil,
            total_volume: nil,
            avg_rpe: nil,
            avg_pain: nil,
            duration_minutes: nil
        )

        let view = TodayWorkoutCard(
            session: session,
            exercises: Exercise.sampleExercises,
            onStartWorkout: {},
            onRefresh: {},
            onExerciseSelected: { _ in }
        )
        .frame(width: 350)
        .darkModeTest()
        .padding()

        verifyViewRenders(view, named: "TodayWorkoutCard_WithExercises_Dark")
    }

    func testTodayWorkoutCard_EmptyExercises() {
        let session = Session(
            id: UUID(),
            phase_id: UUID(),
            name: "Recovery Day",
            sequence: 3,
            weekday: 5,
            notes: nil,
            created_at: Date(),
            completed: false,
            started_at: nil,
            completed_at: nil,
            total_volume: nil,
            avg_rpe: nil,
            avg_pain: nil,
            duration_minutes: nil
        )

        let view = TodayWorkoutCard(
            session: session,
            exercises: [],
            onStartWorkout: {},
            onRefresh: {},
            onExerciseSelected: { _ in }
        )
        .frame(width: 350)
        .padding()

        verifyViewRenders(view, named: "TodayWorkoutCard_EmptyExercises")
    }

    func testTodayWorkoutCard_BothColorSchemes() {
        let session = Session(
            id: UUID(),
            phase_id: UUID(),
            name: "Full Body Workout",
            sequence: 1,
            weekday: 1,
            notes: nil,
            created_at: Date(),
            completed: false,
            started_at: nil,
            completed_at: nil,
            total_volume: nil,
            avg_rpe: nil,
            avg_pain: nil,
            duration_minutes: nil
        )

        let view = TodayWorkoutCard(
            session: session,
            exercises: Exercise.sampleExercises,
            onStartWorkout: {},
            onRefresh: {},
            onExerciseSelected: { _ in }
        )
        .frame(width: 350)
        .padding()

        verifyViewInBothColorSchemes(view, named: "TodayWorkoutCard")
    }

    func testTodayWorkoutCard_iPhoneAndIPad() {
        let session = Session(
            id: UUID(),
            phase_id: UUID(),
            name: "Upper Body Strength",
            sequence: 1,
            weekday: 1,
            notes: nil,
            created_at: Date(),
            completed: false,
            started_at: nil,
            completed_at: nil,
            total_volume: nil,
            avg_rpe: nil,
            avg_pain: nil,
            duration_minutes: nil
        )

        let view = TodayWorkoutCard(
            session: session,
            exercises: Exercise.sampleExercises,
            onStartWorkout: {},
            onRefresh: {},
            onExerciseSelected: { _ in }
        )
        .padding()

        verifyViewAcrossDevices(
            view,
            named: "TodayWorkoutCard",
            devices: [.iPhone15Pro, .iPadPro]
        )
    }

    // MARK: - SessionSummaryView Tests

    func testSessionSummaryView_Complete_LightMode() {
        let session = Session(
            id: UUID(),
            phase_id: UUID(),
            name: "Upper Body Strength",
            sequence: 1,
            weekday: 1,
            notes: nil,
            created_at: Date(),
            completed: true,
            started_at: Date().addingTimeInterval(-2700),
            completed_at: Date(),
            total_volume: 12500.50,
            avg_rpe: 7.5,
            avg_pain: 3.2,
            duration_minutes: 45
        )

        let view = SessionSummaryView(session: session)
            .lightModeTest()

        verifyViewRenders(view, named: "SessionSummaryView_Complete_Light")
    }

    func testSessionSummaryView_Complete_DarkMode() {
        let session = Session(
            id: UUID(),
            phase_id: UUID(),
            name: "Lower Body Power",
            sequence: 2,
            weekday: 3,
            notes: nil,
            created_at: Date(),
            completed: true,
            started_at: Date().addingTimeInterval(-3600),
            completed_at: Date(),
            total_volume: 18750.0,
            avg_rpe: 8.5,
            avg_pain: 2.0,
            duration_minutes: 60
        )

        let view = SessionSummaryView(session: session)
            .darkModeTest()

        verifyViewRenders(view, named: "SessionSummaryView_Complete_Dark")
    }

    func testSessionSummaryView_HighVolume() {
        let session = Session(
            id: UUID(),
            phase_id: UUID(),
            name: "Heavy Deadlift Day",
            sequence: 1,
            weekday: 2,
            notes: nil,
            created_at: Date(),
            completed: true,
            started_at: Date().addingTimeInterval(-5400),
            completed_at: Date(),
            total_volume: 35000.0,
            avg_rpe: 9.0,
            avg_pain: 4.5,
            duration_minutes: 90
        )

        let view = SessionSummaryView(session: session)

        verifyViewRenders(view, named: "SessionSummaryView_HighVolume")
    }

    func testSessionSummaryView_MinimalMetrics() {
        let session = Session(
            id: UUID(),
            phase_id: UUID(),
            name: "Quick Session",
            sequence: 1,
            weekday: 4,
            notes: nil,
            created_at: Date(),
            completed: true,
            started_at: Date().addingTimeInterval(-900),
            completed_at: Date(),
            total_volume: 2500.0,
            avg_rpe: nil,
            avg_pain: nil,
            duration_minutes: 15
        )

        let view = SessionSummaryView(session: session)

        verifyViewRenders(view, named: "SessionSummaryView_MinimalMetrics")
    }

    func testSessionSummaryView_BothColorSchemes() {
        let session = Session(
            id: UUID(),
            phase_id: UUID(),
            name: "Full Body Workout",
            sequence: 1,
            weekday: 1,
            notes: nil,
            created_at: Date(),
            completed: true,
            started_at: Date().addingTimeInterval(-2700),
            completed_at: Date(),
            total_volume: 15000.0,
            avg_rpe: 7.0,
            avg_pain: 2.5,
            duration_minutes: 45
        )

        let view = SessionSummaryView(session: session)

        verifyViewInBothColorSchemes(view, named: "SessionSummaryView")
    }

    // MARK: - WorkoutGridView Component Tests

    func testWorkoutGridHeader_LightMode() {
        // Test the grid header portion which can be tested in isolation
        let view = HStack(spacing: 0) {
            Text("Exercise")
                .frame(width: 200, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Sets")
                .frame(width: 60, alignment: .center)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Reps")
                .frame(width: 80, alignment: .center)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Weight")
                .frame(width: 80, alignment: .center)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Notes")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .lightModeTest()

        verifyViewRenders(view, named: "WorkoutGridHeader_Light")
    }

    func testWorkoutGridHeader_DarkMode() {
        let view = HStack(spacing: 0) {
            Text("Exercise")
                .frame(width: 200, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Sets")
                .frame(width: 60, alignment: .center)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Reps")
                .frame(width: 80, alignment: .center)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Weight")
                .frame(width: 80, alignment: .center)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Notes")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .darkModeTest()

        verifyViewRenders(view, named: "WorkoutGridHeader_Dark")
    }

    // MARK: - Workout Components Gallery

    func testWorkoutComponentsGallery_LightMode() {
        let view = ScrollView {
            VStack(spacing: 16) {
                // Set rows in various states
                OptimisticSetRow(
                    setNumber: 1,
                    reps: .constant(10),
                    weight: .constant(135),
                    isCompleted: .constant(true),
                    loadUnit: "lbs",
                    targetReps: 10,
                    targetWeight: 135,
                    onComplete: {}
                )

                OptimisticSetRow(
                    setNumber: 2,
                    reps: .constant(10),
                    weight: .constant(135),
                    isCompleted: .constant(false),
                    loadUnit: "lbs",
                    targetReps: 10,
                    targetWeight: 135,
                    onComplete: {}
                )
            }
            .frame(width: 350)
            .padding()
        }
        .lightModeTest()

        verifyViewRenders(view, named: "WorkoutComponentsGallery_Light")
    }

    func testWorkoutComponentsGallery_DarkMode() {
        let view = ScrollView {
            VStack(spacing: 16) {
                OptimisticSetRow(
                    setNumber: 1,
                    reps: .constant(10),
                    weight: .constant(135),
                    isCompleted: .constant(true),
                    loadUnit: "lbs",
                    targetReps: 10,
                    targetWeight: 135,
                    onComplete: {}
                )

                OptimisticSetRow(
                    setNumber: 2,
                    reps: .constant(10),
                    weight: .constant(135),
                    isCompleted: .constant(false),
                    loadUnit: "lbs",
                    targetReps: 10,
                    targetWeight: 135,
                    onComplete: {}
                )
            }
            .frame(width: 350)
            .padding()
        }
        .darkModeTest()

        verifyViewRenders(view, named: "WorkoutComponentsGallery_Dark")
    }
}

// MARK: - Mock ViewModels for Testing

/// Mock ViewModel for WorkoutCompletionSummary
class MockOptimisticWorkoutViewModel: OptimisticWorkoutViewModel {
    override init(sessionId: UUID, patientId: UUID, exercises: [Exercise]) {
        super.init(sessionId: sessionId, patientId: patientId, exercises: [])
    }

    convenience init() {
        self.init(sessionId: UUID(), patientId: UUID(), exercises: [])
    }

    override var totalVolume: Double {
        return 12500.0
    }

    override var averageRPE: Double? {
        return 7.5
    }

    override var averagePain: Double? {
        return 2.0
    }
}
