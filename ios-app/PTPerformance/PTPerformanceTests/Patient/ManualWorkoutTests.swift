//
//  ManualWorkoutTests.swift
//  PTPerformanceTests
//
//  Comprehensive tests for patient manual workout features.
//  Tests template selection, favorites management, custom workout creation,
//  and workout saving as template.
//

import XCTest
@testable import PTPerformance

// MARK: - Mock Services

class MockManualWorkoutCreationService {

    var shouldFailFetchTemplates = false
    var shouldFailFetchFavorites = false
    var shouldFailToggleFavorite = false
    var shouldFailCreateWorkout = false
    var shouldFailCreateTemplate = false
    var shouldFailAddExercise = false
    var shouldFailRemoveExercise = false

    var fetchTemplatesCallCount = 0
    var fetchFavoritesCallCount = 0
    var toggleFavoriteCallCount = 0
    var createWorkoutCallCount = 0
    var createTemplateCallCount = 0
    var addExerciseCallCount = 0
    var removeExerciseCallCount = 0

    var mockTemplates: [MockWorkoutTemplate] = []
    var mockFavoriteIds: Set<UUID> = []
    var mockExerciseLibrary: [MockExerciseTemplate] = []

    var lastCreatedWorkout: (
        name: String,
        patientId: UUID,
        exercises: [MockExerciseSelection]
    )?

    var lastCreatedTemplate: (
        name: String,
        category: String,
        exercises: [MockExerciseSelection]
    )?

    func fetchTemplates(category: String?) async throws -> [MockWorkoutTemplate] {
        fetchTemplatesCallCount += 1
        if shouldFailFetchTemplates {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fetch templates failed"])
        }
        if let category = category {
            return mockTemplates.filter { $0.category == category }
        }
        return mockTemplates
    }

    func fetchFavorites(patientId: UUID) async throws -> Set<UUID> {
        fetchFavoritesCallCount += 1
        if shouldFailFetchFavorites {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fetch favorites failed"])
        }
        return mockFavoriteIds
    }

    func toggleFavorite(patientId: UUID, templateId: UUID) async throws -> Bool {
        toggleFavoriteCallCount += 1
        if shouldFailToggleFavorite {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Toggle favorite failed"])
        }
        if mockFavoriteIds.contains(templateId) {
            mockFavoriteIds.remove(templateId)
            return false
        } else {
            mockFavoriteIds.insert(templateId)
            return true
        }
    }

    func createWorkout(
        patientId: UUID,
        name: String,
        exercises: [MockExerciseSelection]
    ) async throws -> MockManualSession {
        createWorkoutCallCount += 1
        if shouldFailCreateWorkout {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Create workout failed"])
        }
        lastCreatedWorkout = (name, patientId, exercises)
        return MockManualSession(
            id: UUID(),
            patientId: patientId,
            name: name,
            exerciseCount: exercises.count,
            startedAt: Date(),
            completed: false
        )
    }

    func createTemplate(
        creatorId: UUID,
        name: String,
        category: String,
        exercises: [MockExerciseSelection]
    ) async throws -> MockWorkoutTemplate {
        createTemplateCallCount += 1
        if shouldFailCreateTemplate {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Create template failed"])
        }
        lastCreatedTemplate = (name, category, exercises)
        return MockWorkoutTemplate(
            id: UUID(),
            name: name,
            category: category,
            exerciseCount: exercises.count,
            isPublic: false,
            createdBy: creatorId
        )
    }

    func fetchExerciseLibrary(searchQuery: String?) async throws -> [MockExerciseTemplate] {
        if let query = searchQuery, !query.isEmpty {
            return mockExerciseLibrary.filter { $0.name.lowercased().contains(query.lowercased()) }
        }
        return mockExerciseLibrary
    }

    func reset() {
        shouldFailFetchTemplates = false
        shouldFailFetchFavorites = false
        shouldFailToggleFavorite = false
        shouldFailCreateWorkout = false
        shouldFailCreateTemplate = false
        shouldFailAddExercise = false
        shouldFailRemoveExercise = false
        fetchTemplatesCallCount = 0
        fetchFavoritesCallCount = 0
        toggleFavoriteCallCount = 0
        createWorkoutCallCount = 0
        createTemplateCallCount = 0
        addExerciseCallCount = 0
        removeExerciseCallCount = 0
        mockTemplates = []
        mockFavoriteIds = []
        mockExerciseLibrary = []
        lastCreatedWorkout = nil
        lastCreatedTemplate = nil
    }
}

// MARK: - Mock Models

struct MockWorkoutTemplate: Identifiable, Equatable {
    let id: UUID
    let name: String
    let category: String
    let exerciseCount: Int
    let isPublic: Bool
    let createdBy: UUID?
}

struct MockExerciseTemplate: Identifiable, Equatable {
    let id: UUID
    let name: String
    let category: String
    let bodyRegion: String
    let equipment: String?
}

struct MockExerciseSelection: Equatable {
    let exerciseId: UUID
    let name: String
    let sets: Int
    let reps: String
    let load: Double?
    let loadUnit: String
    let restSeconds: Int
    let sequence: Int
}

struct MockManualSession: Identifiable, Equatable {
    let id: UUID
    let patientId: UUID
    let name: String
    let exerciseCount: Int
    let startedAt: Date
    let completed: Bool
}

// MARK: - Manual Workout Tests

@MainActor
final class ManualWorkoutTests: XCTestCase {

    var mockService: MockManualWorkoutCreationService!
    let testPatientId = UUID()

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockManualWorkoutCreationService()
    }

    override func tearDown() async throws {
        mockService = nil
        try await super.tearDown()
    }

    // MARK: - Template Selection Tests

    func testFetchTemplates_AllCategories() async throws {
        mockService.mockTemplates = [
            MockWorkoutTemplate(id: UUID(), name: "Upper Body", category: "strength", exerciseCount: 6, isPublic: true, createdBy: nil),
            MockWorkoutTemplate(id: UUID(), name: "Lower Body", category: "strength", exerciseCount: 5, isPublic: true, createdBy: nil),
            MockWorkoutTemplate(id: UUID(), name: "Full Body HIIT", category: "cardio", exerciseCount: 8, isPublic: true, createdBy: nil)
        ]

        let templates = try await mockService.fetchTemplates(category: nil)

        XCTAssertEqual(templates.count, 3)
        XCTAssertEqual(mockService.fetchTemplatesCallCount, 1)
    }

    func testFetchTemplates_FilterByCategory() async throws {
        mockService.mockTemplates = [
            MockWorkoutTemplate(id: UUID(), name: "Upper Body", category: "strength", exerciseCount: 6, isPublic: true, createdBy: nil),
            MockWorkoutTemplate(id: UUID(), name: "Lower Body", category: "strength", exerciseCount: 5, isPublic: true, createdBy: nil),
            MockWorkoutTemplate(id: UUID(), name: "Full Body HIIT", category: "cardio", exerciseCount: 8, isPublic: true, createdBy: nil)
        ]

        let strengthTemplates = try await mockService.fetchTemplates(category: "strength")

        XCTAssertEqual(strengthTemplates.count, 2)
        XCTAssertTrue(strengthTemplates.allSatisfy { $0.category == "strength" })
    }

    func testFetchTemplates_Empty() async throws {
        mockService.mockTemplates = []

        let templates = try await mockService.fetchTemplates(category: nil)

        XCTAssertTrue(templates.isEmpty)
    }

    func testFetchTemplates_Failure() async {
        mockService.shouldFailFetchTemplates = true

        do {
            _ = try await mockService.fetchTemplates(category: nil)
            XCTFail("Should throw error when fetch fails")
        } catch {
            XCTAssertEqual(mockService.fetchTemplatesCallCount, 1)
        }
    }

    func testFetchTemplates_WithExerciseCounts() async throws {
        mockService.mockTemplates = [
            MockWorkoutTemplate(id: UUID(), name: "Quick Core", category: "strength", exerciseCount: 3, isPublic: true, createdBy: nil),
            MockWorkoutTemplate(id: UUID(), name: "Full Workout", category: "strength", exerciseCount: 12, isPublic: true, createdBy: nil)
        ]

        let templates = try await mockService.fetchTemplates(category: nil)

        XCTAssertEqual(templates[0].exerciseCount, 3)
        XCTAssertEqual(templates[1].exerciseCount, 12)
    }

    // MARK: - Favorites Management Tests

    func testFetchFavorites_Success() async throws {
        let favoriteId1 = UUID()
        let favoriteId2 = UUID()
        mockService.mockFavoriteIds = [favoriteId1, favoriteId2]

        let favorites = try await mockService.fetchFavorites(patientId: testPatientId)

        XCTAssertEqual(favorites.count, 2)
        XCTAssertTrue(favorites.contains(favoriteId1))
        XCTAssertTrue(favorites.contains(favoriteId2))
    }

    func testFetchFavorites_Empty() async throws {
        mockService.mockFavoriteIds = []

        let favorites = try await mockService.fetchFavorites(patientId: testPatientId)

        XCTAssertTrue(favorites.isEmpty)
    }

    func testFetchFavorites_Failure() async {
        mockService.shouldFailFetchFavorites = true

        do {
            _ = try await mockService.fetchFavorites(patientId: testPatientId)
            XCTFail("Should throw error when fetch fails")
        } catch {
            XCTAssertEqual(mockService.fetchFavoritesCallCount, 1)
        }
    }

    func testToggleFavorite_Add() async throws {
        mockService.mockFavoriteIds = []
        let templateId = UUID()

        let isFavorite = try await mockService.toggleFavorite(patientId: testPatientId, templateId: templateId)

        XCTAssertTrue(isFavorite)
        XCTAssertTrue(mockService.mockFavoriteIds.contains(templateId))
    }

    func testToggleFavorite_Remove() async throws {
        let templateId = UUID()
        mockService.mockFavoriteIds = [templateId]

        let isFavorite = try await mockService.toggleFavorite(patientId: testPatientId, templateId: templateId)

        XCTAssertFalse(isFavorite)
        XCTAssertFalse(mockService.mockFavoriteIds.contains(templateId))
    }

    func testToggleFavorite_MultipleTemplates() async throws {
        let template1 = UUID()
        let template2 = UUID()
        let template3 = UUID()
        mockService.mockFavoriteIds = [template1]

        // Add template2
        _ = try await mockService.toggleFavorite(patientId: testPatientId, templateId: template2)
        XCTAssertEqual(mockService.mockFavoriteIds.count, 2)

        // Add template3
        _ = try await mockService.toggleFavorite(patientId: testPatientId, templateId: template3)
        XCTAssertEqual(mockService.mockFavoriteIds.count, 3)

        // Remove template1
        _ = try await mockService.toggleFavorite(patientId: testPatientId, templateId: template1)
        XCTAssertEqual(mockService.mockFavoriteIds.count, 2)
        XCTAssertFalse(mockService.mockFavoriteIds.contains(template1))
    }

    func testToggleFavorite_Failure() async {
        mockService.shouldFailToggleFavorite = true

        do {
            _ = try await mockService.toggleFavorite(patientId: testPatientId, templateId: UUID())
            XCTFail("Should throw error when toggle fails")
        } catch {
            XCTAssertEqual(mockService.toggleFavoriteCallCount, 1)
        }
    }

    // MARK: - Custom Workout Creation Tests

    func testCreateWorkout_Basic() async throws {
        let exercises = [
            MockExerciseSelection(exerciseId: UUID(), name: "Squat", sets: 3, reps: "10", load: 135, loadUnit: "lbs", restSeconds: 90, sequence: 0),
            MockExerciseSelection(exerciseId: UUID(), name: "Bench Press", sets: 3, reps: "10", load: 135, loadUnit: "lbs", restSeconds: 90, sequence: 1)
        ]

        let session = try await mockService.createWorkout(
            patientId: testPatientId,
            name: "Morning Workout",
            exercises: exercises
        )

        XCTAssertNotNil(session)
        XCTAssertEqual(session.name, "Morning Workout")
        XCTAssertEqual(session.exerciseCount, 2)
        XCTAssertEqual(mockService.lastCreatedWorkout?.name, "Morning Workout")
    }

    func testCreateWorkout_SingleExercise() async throws {
        let exercises = [
            MockExerciseSelection(exerciseId: UUID(), name: "Deadlift", sets: 5, reps: "5", load: 225, loadUnit: "lbs", restSeconds: 180, sequence: 0)
        ]

        let session = try await mockService.createWorkout(
            patientId: testPatientId,
            name: "Deadlift Day",
            exercises: exercises
        )

        XCTAssertNotNil(session)
        XCTAssertEqual(session.exerciseCount, 1)
    }

    func testCreateWorkout_ManyExercises() async throws {
        let exercises = (0..<10).map { index in
            MockExerciseSelection(
                exerciseId: UUID(),
                name: "Exercise \(index + 1)",
                sets: 3,
                reps: "10",
                load: Double(100 + index * 10),
                loadUnit: "lbs",
                restSeconds: 60,
                sequence: index
            )
        }

        let session = try await mockService.createWorkout(
            patientId: testPatientId,
            name: "Full Body Workout",
            exercises: exercises
        )

        XCTAssertNotNil(session)
        XCTAssertEqual(session.exerciseCount, 10)
    }

    func testCreateWorkout_Failure() async {
        mockService.shouldFailCreateWorkout = true

        let exercises = [
            MockExerciseSelection(exerciseId: UUID(), name: "Squat", sets: 3, reps: "10", load: 135, loadUnit: "lbs", restSeconds: 90, sequence: 0)
        ]

        do {
            _ = try await mockService.createWorkout(
                patientId: testPatientId,
                name: "Test",
                exercises: exercises
            )
            XCTFail("Should throw error when create fails")
        } catch {
            XCTAssertEqual(mockService.createWorkoutCallCount, 1)
        }
    }

    func testCreateWorkout_BodyweightExercises() async throws {
        let exercises = [
            MockExerciseSelection(exerciseId: UUID(), name: "Push-ups", sets: 3, reps: "15", load: nil, loadUnit: "bw", restSeconds: 60, sequence: 0),
            MockExerciseSelection(exerciseId: UUID(), name: "Pull-ups", sets: 3, reps: "8", load: nil, loadUnit: "bw", restSeconds: 90, sequence: 1),
            MockExerciseSelection(exerciseId: UUID(), name: "Air Squats", sets: 3, reps: "20", load: nil, loadUnit: "bw", restSeconds: 60, sequence: 2)
        ]

        let session = try await mockService.createWorkout(
            patientId: testPatientId,
            name: "Bodyweight Circuit",
            exercises: exercises
        )

        XCTAssertNotNil(session)
        XCTAssertTrue(mockService.lastCreatedWorkout?.exercises.allSatisfy { $0.load == nil } ?? false)
    }

    func testCreateWorkout_RepsAsRange() async throws {
        let exercises = [
            MockExerciseSelection(exerciseId: UUID(), name: "Bicep Curls", sets: 3, reps: "8-12", load: 25, loadUnit: "lbs", restSeconds: 60, sequence: 0)
        ]

        let session = try await mockService.createWorkout(
            patientId: testPatientId,
            name: "Arms",
            exercises: exercises
        )

        XCTAssertNotNil(session)
        XCTAssertEqual(mockService.lastCreatedWorkout?.exercises[0].reps, "8-12")
    }

    // MARK: - Save as Template Tests

    func testCreateTemplate_Success() async throws {
        let exercises = [
            MockExerciseSelection(exerciseId: UUID(), name: "Squat", sets: 4, reps: "8", load: nil, loadUnit: "lbs", restSeconds: 120, sequence: 0),
            MockExerciseSelection(exerciseId: UUID(), name: "Leg Press", sets: 3, reps: "12", load: nil, loadUnit: "lbs", restSeconds: 90, sequence: 1),
            MockExerciseSelection(exerciseId: UUID(), name: "Leg Curl", sets: 3, reps: "15", load: nil, loadUnit: "lbs", restSeconds: 60, sequence: 2)
        ]

        let template = try await mockService.createTemplate(
            creatorId: testPatientId,
            name: "Leg Day Template",
            category: "strength",
            exercises: exercises
        )

        XCTAssertNotNil(template)
        XCTAssertEqual(template.name, "Leg Day Template")
        XCTAssertEqual(template.category, "strength")
        XCTAssertEqual(template.exerciseCount, 3)
        XCTAssertFalse(template.isPublic)
    }

    func testCreateTemplate_DifferentCategories() async throws {
        let strengthExercises = [
            MockExerciseSelection(exerciseId: UUID(), name: "Bench Press", sets: 3, reps: "8", load: nil, loadUnit: "lbs", restSeconds: 90, sequence: 0)
        ]

        let cardioExercises = [
            MockExerciseSelection(exerciseId: UUID(), name: "Burpees", sets: 5, reps: "10", load: nil, loadUnit: "bw", restSeconds: 30, sequence: 0)
        ]

        let strengthTemplate = try await mockService.createTemplate(
            creatorId: testPatientId,
            name: "Strength Template",
            category: "strength",
            exercises: strengthExercises
        )

        let cardioTemplate = try await mockService.createTemplate(
            creatorId: testPatientId,
            name: "Cardio Template",
            category: "cardio",
            exercises: cardioExercises
        )

        XCTAssertEqual(strengthTemplate.category, "strength")
        XCTAssertEqual(cardioTemplate.category, "cardio")
    }

    func testCreateTemplate_Failure() async {
        mockService.shouldFailCreateTemplate = true

        let exercises = [
            MockExerciseSelection(exerciseId: UUID(), name: "Test", sets: 3, reps: "10", load: nil, loadUnit: "lbs", restSeconds: 60, sequence: 0)
        ]

        do {
            _ = try await mockService.createTemplate(
                creatorId: testPatientId,
                name: "Test Template",
                category: "strength",
                exercises: exercises
            )
            XCTFail("Should throw error when create fails")
        } catch {
            XCTAssertEqual(mockService.createTemplateCallCount, 1)
        }
    }

    func testCreateTemplate_Private() async throws {
        let exercises = [
            MockExerciseSelection(exerciseId: UUID(), name: "Squat", sets: 3, reps: "10", load: nil, loadUnit: "lbs", restSeconds: 90, sequence: 0)
        ]

        let template = try await mockService.createTemplate(
            creatorId: testPatientId,
            name: "My Private Template",
            category: "strength",
            exercises: exercises
        )

        XCTAssertFalse(template.isPublic)
        XCTAssertEqual(template.createdBy, testPatientId)
    }

    // MARK: - Exercise Library Tests

    func testFetchExerciseLibrary_All() async throws {
        mockService.mockExerciseLibrary = [
            MockExerciseTemplate(id: UUID(), name: "Squat", category: "Compound", bodyRegion: "Lower", equipment: "Barbell"),
            MockExerciseTemplate(id: UUID(), name: "Bench Press", category: "Compound", bodyRegion: "Upper", equipment: "Barbell"),
            MockExerciseTemplate(id: UUID(), name: "Deadlift", category: "Compound", bodyRegion: "Full", equipment: "Barbell")
        ]

        let exercises = try await mockService.fetchExerciseLibrary(searchQuery: nil)

        XCTAssertEqual(exercises.count, 3)
    }

    func testFetchExerciseLibrary_Search() async throws {
        mockService.mockExerciseLibrary = [
            MockExerciseTemplate(id: UUID(), name: "Squat", category: "Compound", bodyRegion: "Lower", equipment: "Barbell"),
            MockExerciseTemplate(id: UUID(), name: "Front Squat", category: "Compound", bodyRegion: "Lower", equipment: "Barbell"),
            MockExerciseTemplate(id: UUID(), name: "Bench Press", category: "Compound", bodyRegion: "Upper", equipment: "Barbell")
        ]

        let exercises = try await mockService.fetchExerciseLibrary(searchQuery: "squat")

        XCTAssertEqual(exercises.count, 2)
        XCTAssertTrue(exercises.allSatisfy { $0.name.lowercased().contains("squat") })
    }

    func testFetchExerciseLibrary_NoResults() async throws {
        mockService.mockExerciseLibrary = [
            MockExerciseTemplate(id: UUID(), name: "Squat", category: "Compound", bodyRegion: "Lower", equipment: "Barbell")
        ]

        let exercises = try await mockService.fetchExerciseLibrary(searchQuery: "swimming")

        XCTAssertTrue(exercises.isEmpty)
    }

    func testFetchExerciseLibrary_CaseInsensitive() async throws {
        mockService.mockExerciseLibrary = [
            MockExerciseTemplate(id: UUID(), name: "Dumbbell Row", category: "Pull", bodyRegion: "Upper", equipment: "Dumbbell")
        ]

        let exercises = try await mockService.fetchExerciseLibrary(searchQuery: "DUMBBELL")

        XCTAssertEqual(exercises.count, 1)
    }
}

// MARK: - Exercise Selection Tests

final class ExerciseSelectionTests: XCTestCase {

    func testExerciseSelection_DefaultValues() {
        let selection = MockExerciseSelection(
            exerciseId: UUID(),
            name: "Squat",
            sets: 3,
            reps: "10",
            load: nil,
            loadUnit: "lbs",
            restSeconds: 90,
            sequence: 0
        )

        XCTAssertEqual(selection.sets, 3)
        XCTAssertEqual(selection.reps, "10")
        XCTAssertNil(selection.load)
        XCTAssertEqual(selection.loadUnit, "lbs")
        XCTAssertEqual(selection.restSeconds, 90)
    }

    func testExerciseSelection_WithLoad() {
        let selection = MockExerciseSelection(
            exerciseId: UUID(),
            name: "Bench Press",
            sets: 4,
            reps: "8",
            load: 185.0,
            loadUnit: "lbs",
            restSeconds: 120,
            sequence: 0
        )

        XCTAssertEqual(selection.load, 185.0)
    }

    func testExerciseSelection_DifferentUnits() {
        let lbsSelection = MockExerciseSelection(
            exerciseId: UUID(),
            name: "Squat",
            sets: 3,
            reps: "10",
            load: 225,
            loadUnit: "lbs",
            restSeconds: 90,
            sequence: 0
        )

        let kgSelection = MockExerciseSelection(
            exerciseId: UUID(),
            name: "Squat",
            sets: 3,
            reps: "10",
            load: 100,
            loadUnit: "kg",
            restSeconds: 90,
            sequence: 0
        )

        XCTAssertEqual(lbsSelection.loadUnit, "lbs")
        XCTAssertEqual(kgSelection.loadUnit, "kg")
    }

    func testExerciseSelection_Sequence() {
        let exercises = [
            MockExerciseSelection(exerciseId: UUID(), name: "Squat", sets: 3, reps: "10", load: nil, loadUnit: "lbs", restSeconds: 90, sequence: 0),
            MockExerciseSelection(exerciseId: UUID(), name: "Leg Press", sets: 3, reps: "12", load: nil, loadUnit: "lbs", restSeconds: 90, sequence: 1),
            MockExerciseSelection(exerciseId: UUID(), name: "Lunges", sets: 3, reps: "10", load: nil, loadUnit: "lbs", restSeconds: 60, sequence: 2)
        ]

        for (index, exercise) in exercises.enumerated() {
            XCTAssertEqual(exercise.sequence, index)
        }
    }
}

// MARK: - Template Category Tests

final class TemplateCategoryTests: XCTestCase {

    func testTemplateCategory_AllCategories() {
        let categories = ["strength", "cardio", "hiit", "mobility", "recovery", "sport_specific"]

        XCTAssertEqual(categories.count, 6)
    }

    func testTemplateCategory_DisplayNames() {
        let categoryNames: [String: String] = [
            "strength": "Strength",
            "cardio": "Cardio",
            "hiit": "HIIT",
            "mobility": "Mobility",
            "recovery": "Recovery",
            "sport_specific": "Sport Specific"
        ]

        for (rawValue, displayName) in categoryNames {
            XCTAssertEqual(getDisplayName(for: rawValue), displayName)
        }
    }

    func testTemplateCategory_Icons() {
        let categoryIcons: [String: String] = [
            "strength": "dumbbell.fill",
            "cardio": "heart.fill",
            "hiit": "flame.fill",
            "mobility": "figure.flexibility",
            "recovery": "leaf.fill",
            "sport_specific": "sportscourt.fill"
        ]

        for (rawValue, iconName) in categoryIcons {
            XCTAssertEqual(getIcon(for: rawValue), iconName)
        }
    }

    private func getDisplayName(for category: String) -> String {
        switch category {
        case "strength": return "Strength"
        case "cardio": return "Cardio"
        case "hiit": return "HIIT"
        case "mobility": return "Mobility"
        case "recovery": return "Recovery"
        case "sport_specific": return "Sport Specific"
        default: return category.capitalized
        }
    }

    private func getIcon(for category: String) -> String {
        switch category {
        case "strength": return "dumbbell.fill"
        case "cardio": return "heart.fill"
        case "hiit": return "flame.fill"
        case "mobility": return "figure.flexibility"
        case "recovery": return "leaf.fill"
        case "sport_specific": return "sportscourt.fill"
        default: return "questionmark"
        }
    }
}

// MARK: - Body Region Tests

final class BodyRegionTests: XCTestCase {

    func testBodyRegion_AllRegions() {
        let regions = ["upper", "lower", "core", "full"]

        XCTAssertEqual(regions.count, 4)
    }

    func testBodyRegion_DisplayNames() {
        let regionNames: [String: String] = [
            "upper": "Upper Body",
            "lower": "Lower Body",
            "core": "Core",
            "full": "Full Body"
        ]

        for (rawValue, displayName) in regionNames {
            XCTAssertEqual(getDisplayName(for: rawValue), displayName)
        }
    }

    private func getDisplayName(for region: String) -> String {
        switch region {
        case "upper": return "Upper Body"
        case "lower": return "Lower Body"
        case "core": return "Core"
        case "full": return "Full Body"
        default: return region.capitalized
        }
    }
}

// MARK: - Rest Period Tests

final class RestPeriodTests: XCTestCase {

    func testRestPeriod_ShortRest() {
        let restSeconds = 30
        XCTAssertEqual(formatRestPeriod(seconds: restSeconds), "30s")
    }

    func testRestPeriod_MediumRest() {
        let restSeconds = 60
        XCTAssertEqual(formatRestPeriod(seconds: restSeconds), "1:00")
    }

    func testRestPeriod_LongRest() {
        let restSeconds = 180
        XCTAssertEqual(formatRestPeriod(seconds: restSeconds), "3:00")
    }

    func testRestPeriod_OddSeconds() {
        let restSeconds = 90
        XCTAssertEqual(formatRestPeriod(seconds: restSeconds), "1:30")
    }

    private func formatRestPeriod(seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Workout Name Validation Tests

final class WorkoutNameValidationTests: XCTestCase {

    func testWorkoutName_Valid() {
        XCTAssertTrue(isValidWorkoutName("Upper Body"))
        XCTAssertTrue(isValidWorkoutName("Leg Day 1"))
        XCTAssertTrue(isValidWorkoutName("Morning Strength Session"))
    }

    func testWorkoutName_TooShort() {
        XCTAssertFalse(isValidWorkoutName(""))
        XCTAssertFalse(isValidWorkoutName("A"))
        XCTAssertFalse(isValidWorkoutName("AB"))
    }

    func testWorkoutName_TooLong() {
        let longName = String(repeating: "a", count: 101)
        XCTAssertFalse(isValidWorkoutName(longName))
    }

    func testWorkoutName_ValidLength() {
        let validName = String(repeating: "a", count: 50)
        XCTAssertTrue(isValidWorkoutName(validName))
    }

    private func isValidWorkoutName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 3 && trimmed.count <= 100
    }
}

// MARK: - Load Unit Tests

final class LoadUnitTests: XCTestCase {

    func testLoadUnit_AllUnits() {
        let units = ["lbs", "kg", "bw"]

        XCTAssertEqual(units.count, 3)
    }

    func testLoadUnit_DisplayNames() {
        XCTAssertEqual(getDisplayName(for: "lbs"), "Pounds")
        XCTAssertEqual(getDisplayName(for: "kg"), "Kilograms")
        XCTAssertEqual(getDisplayName(for: "bw"), "Bodyweight")
    }

    func testLoadUnit_Abbreviations() {
        XCTAssertEqual(getAbbreviation(for: "lbs"), "lbs")
        XCTAssertEqual(getAbbreviation(for: "kg"), "kg")
        XCTAssertEqual(getAbbreviation(for: "bw"), "BW")
    }

    private func getDisplayName(for unit: String) -> String {
        switch unit {
        case "lbs": return "Pounds"
        case "kg": return "Kilograms"
        case "bw": return "Bodyweight"
        default: return unit
        }
    }

    private func getAbbreviation(for unit: String) -> String {
        switch unit {
        case "lbs": return "lbs"
        case "kg": return "kg"
        case "bw": return "BW"
        default: return unit
        }
    }
}

// MARK: - Template Sorting Tests

final class TemplateSortingTests: XCTestCase {

    func testSortTemplates_ByName() {
        let templates = [
            MockWorkoutTemplate(id: UUID(), name: "Zzz Workout", category: "strength", exerciseCount: 3, isPublic: true, createdBy: nil),
            MockWorkoutTemplate(id: UUID(), name: "Aaa Workout", category: "strength", exerciseCount: 3, isPublic: true, createdBy: nil),
            MockWorkoutTemplate(id: UUID(), name: "Mmm Workout", category: "strength", exerciseCount: 3, isPublic: true, createdBy: nil)
        ]

        let sorted = templates.sorted { $0.name < $1.name }

        XCTAssertEqual(sorted[0].name, "Aaa Workout")
        XCTAssertEqual(sorted[1].name, "Mmm Workout")
        XCTAssertEqual(sorted[2].name, "Zzz Workout")
    }

    func testSortTemplates_ByExerciseCount() {
        let templates = [
            MockWorkoutTemplate(id: UUID(), name: "Small", category: "strength", exerciseCount: 3, isPublic: true, createdBy: nil),
            MockWorkoutTemplate(id: UUID(), name: "Large", category: "strength", exerciseCount: 10, isPublic: true, createdBy: nil),
            MockWorkoutTemplate(id: UUID(), name: "Medium", category: "strength", exerciseCount: 6, isPublic: true, createdBy: nil)
        ]

        let sorted = templates.sorted { $0.exerciseCount < $1.exerciseCount }

        XCTAssertEqual(sorted[0].exerciseCount, 3)
        XCTAssertEqual(sorted[1].exerciseCount, 6)
        XCTAssertEqual(sorted[2].exerciseCount, 10)
    }
}
