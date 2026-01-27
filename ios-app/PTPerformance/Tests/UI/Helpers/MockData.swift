//
//  MockData.swift
//  PTPerformanceUITests
//
//  Mock data generators for UI testing
//  BUILD 95 - Agent 1: XCUITest Framework Setup
//

import Foundation

/// Mock data generators for consistent test data across UI tests
enum MockData {

    // MARK: - User Credentials

    /// Demo patient account credentials
    enum DemoPatient {
        static let email = "demo-athlete@ptperformance.app"
        static let password = "demo-patient-2025"
        static let name = "Demo Athlete"
    }

    /// Demo therapist account credentials
    enum DemoTherapist {
        static let email = "demo-therapist@ptperformance.app"
        static let password = "demo-therapist-2025"
        static let name = "Demo Therapist"
    }

    /// Test patient account (for destructive testing)
    enum TestPatient {
        static let email = "test-patient@ptperformance.app"
        static let password = "test-password-2025"
        static let name = "Test Patient"
    }

    /// Test therapist account (for destructive testing)
    enum TestTherapist {
        static let email = "test-therapist@ptperformance.app"
        static let password = "test-password-2025"
        static let name = "Test Therapist"
    }

    // MARK: - Exercise Data

    /// Sample exercise names commonly used in testing
    enum ExerciseNames {
        static let squat = "Back Squat"
        static let benchPress = "Bench Press"
        static let deadlift = "Deadlift"
        static let pullUp = "Pull-Up"
        static let shoulderPress = "Shoulder Press"
        static let row = "Barbell Row"
        static let lunge = "Walking Lunge"
        static let plank = "Plank"

        static let all = [
            squat,
            benchPress,
            deadlift,
            pullUp,
            shoulderPress,
            row,
            lunge,
            plank
        ]

        /// Get a random exercise name
        static var random: String {
            return all.randomElement() ?? squat
        }
    }

    /// Sample exercise sets/reps/load configurations
    struct ExerciseConfiguration {
        let sets: Int
        let reps: Int
        let load: Double
        let unit: String

        static let strength = ExerciseConfiguration(
            sets: 5,
            reps: 5,
            load: 185,
            unit: "lbs"
        )

        static let hypertrophy = ExerciseConfiguration(
            sets: 4,
            reps: 10,
            load: 135,
            unit: "lbs"
        )

        static let endurance = ExerciseConfiguration(
            sets: 3,
            reps: 15,
            load: 95,
            unit: "lbs"
        )

        static let bodyweight = ExerciseConfiguration(
            sets: 3,
            reps: 12,
            load: 0,
            unit: "lbs"
        )

        /// Get a random configuration
        static var random: ExerciseConfiguration {
            return [strength, hypertrophy, endurance, bodyweight].randomElement() ?? strength
        }
    }

    // MARK: - Program Data

    /// Sample program names
    enum ProgramNames {
        static let strength = "Strength Building Program"
        static let hypertrophy = "Muscle Building Program"
        static let conditioning = "Conditioning Program"
        static let rehabilitation = "Knee Rehab Program"
        static let baseball = "Baseball Off-Season"
        static let general = "General Fitness"

        static let all = [
            strength,
            hypertrophy,
            conditioning,
            rehabilitation,
            baseball,
            general
        ]

        /// Get a random program name
        static var random: String {
            return all.randomElement() ?? general
        }
    }

    // MARK: - Program Type Data (BUILD 294)

    /// Program type identifiers for filtering and creation
    enum ProgramTypes {
        static let rehab = "rehab"
        static let performance = "performance"
        static let lifestyle = "lifestyle"
        static let all = [rehab, performance, lifestyle]
    }

    /// Sample program names by type for testing program type workflows
    enum ProgramTypeNames {
        static let rehabKnee = "ACL Rehab Program"
        static let performancePower = "Explosive Power Training"
        static let lifestyleWellness = "Daily Wellness Routine"
    }

    /// Program phase names
    enum PhaseNames {
        static let foundation = "Foundation Phase"
        static let development = "Development Phase"
        static let peak = "Peak Phase"
        static let taper = "Taper Phase"
        static let maintenance = "Maintenance Phase"

        static let all = [
            foundation,
            development,
            peak,
            taper,
            maintenance
        ]

        /// Get a random phase name
        static var random: String {
            return all.randomElement() ?? foundation
        }
    }

    // MARK: - Session Data

    /// Sample session names
    enum SessionNames {
        static let upperBody = "Upper Body Strength"
        static let lowerBody = "Lower Body Strength"
        static let fullBody = "Full Body Workout"
        static let conditioning = "Conditioning Session"
        static let recovery = "Recovery Session"
        static let skills = "Skills & Technique"

        static let all = [
            upperBody,
            lowerBody,
            fullBody,
            conditioning,
            recovery,
            skills
        ]

        /// Get a random session name
        static var random: String {
            return all.randomElement() ?? fullBody
        }
    }

    // MARK: - Readiness Data

    /// Sample readiness scores (1-10 scale)
    struct ReadinessScore {
        let sleep: Int
        let soreness: Int
        let stress: Int
        let energy: Int

        /// Calculate overall readiness (average)
        var overall: Double {
            return Double(sleep + soreness + stress + energy) / 4.0
        }

        static let high = ReadinessScore(
            sleep: 9,
            soreness: 8,
            stress: 8,
            energy: 9
        )

        static let medium = ReadinessScore(
            sleep: 6,
            soreness: 6,
            stress: 6,
            energy: 7
        )

        static let low = ReadinessScore(
            sleep: 4,
            soreness: 3,
            stress: 4,
            energy: 4
        )

        /// Get a random readiness score
        static var random: ReadinessScore {
            return [high, medium, low].randomElement() ?? medium
        }
    }

    // MARK: - Date Helpers

    /// Common date generators for testing
    enum Dates {
        /// Today's date
        static var today: Date {
            return Date()
        }

        /// Yesterday's date
        static var yesterday: Date {
            return Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        }

        /// Tomorrow's date
        static var tomorrow: Date {
            return Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        }

        /// Date one week ago
        static var lastWeek: Date {
            return Calendar.current.date(byAdding: .day, value: -7, to: today) ?? today
        }

        /// Date one week from now
        static var nextWeek: Date {
            return Calendar.current.date(byAdding: .day, value: 7, to: today) ?? today
        }

        /// Random date within the next 30 days
        static var randomFuture: Date {
            let days = Int.random(in: 1...30)
            return Calendar.current.date(byAdding: .day, value: days, to: today) ?? today
        }

        /// Random date within the past 30 days
        static var randomPast: Date {
            let days = Int.random(in: 1...30)
            return Calendar.current.date(byAdding: .day, value: -days, to: today) ?? today
        }
    }

    // MARK: - Text Generators

    /// Generate random text for testing
    enum TextGenerators {
        /// Short text (1-3 words)
        static func shortText() -> String {
            let words = ["Quick", "Test", "Session", "Program", "Phase", "Exercise"]
            let count = Int.random(in: 1...3)
            return (0..<count).map { _ in words.randomElement() ?? "Test" }.joined(separator: " ")
        }

        /// Medium text (1-2 sentences)
        static func mediumText() -> String {
            return "This is a test session designed to evaluate the functionality of the PTPerformance app."
        }

        /// Long text (paragraph)
        static func longText() -> String {
            return """
            This is a comprehensive test program that includes multiple phases and sessions. \
            Each session is carefully designed to progress the athlete through various training \
            adaptations while monitoring their readiness and recovery. The program uses evidence-based \
            principles to optimize training outcomes.
            """
        }

        /// Random notes text
        static func randomNotes() -> String {
            let templates = [
                "Athlete felt strong today",
                "Minor knee discomfort during squats",
                "Excellent technique throughout",
                "May need to reduce volume next week",
                "Ready to progress to next phase"
            ]
            return templates.randomElement() ?? "Notes from session"
        }
    }

    // MARK: - Error Scenarios

    /// Common error messages for negative testing
    enum ErrorMessages {
        static let invalidCredentials = "Invalid email or password"
        static let networkError = "Network request failed"
        static let dataNotFound = "The data couldn't be read because it doesn't exist"
        static let permissionDenied = "Permission denied"
        static let sessionExpired = "Your session has expired"
        static let invalidInput = "Please enter valid information"

        static let all = [
            invalidCredentials,
            networkError,
            dataNotFound,
            permissionDenied,
            sessionExpired,
            invalidInput
        ]
    }

    // MARK: - Validation Helpers

    /// Email validation test cases
    enum EmailTestCases {
        static let valid = [
            "user@example.com",
            "test.user@domain.com",
            "athlete123@ptperformance.app"
        ]

        static let invalid = [
            "notanemail",
            "@example.com",
            "user@",
            "user @example.com",
            ""
        ]
    }

    /// Password validation test cases
    enum PasswordTestCases {
        static let valid = [
            "SecurePassword123!",
            "TestPass2025",
            "demo-patient-2025"
        ]

        static let invalid = [
            "short",
            "",
            "   ",
            "123" // too short
        ]
    }

    // MARK: - Performance Metrics

    /// Expected performance benchmarks
    enum PerformanceBenchmarks {
        /// Maximum acceptable app launch time (seconds)
        static let maxLaunchTime: TimeInterval = 3.0

        /// Maximum acceptable login time (seconds)
        static let maxLoginTime: TimeInterval = 5.0

        /// Maximum acceptable data load time (seconds)
        static let maxDataLoadTime: TimeInterval = 10.0

        /// Maximum acceptable navigation time (seconds)
        static let maxNavigationTime: TimeInterval = 1.0

        /// Maximum acceptable form submission time (seconds)
        static let maxFormSubmissionTime: TimeInterval = 5.0
    }

    // MARK: - Test Data Cleanup

    /// Test data that should be cleaned up after tests
    struct CleanupData {
        var createdProgramIds: [String] = []
        var createdSessionIds: [String] = []
        var createdExerciseLogIds: [String] = []

        mutating func reset() {
            createdProgramIds.removeAll()
            createdSessionIds.removeAll()
            createdExerciseLogIds.removeAll()
        }
    }
}
