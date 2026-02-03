//
//  TemplatesTests.swift
//  PTPerformanceTests
//
//  Created by Build 46 Swarm Agent 2
//  Integration tests for workout templates
//

import XCTest
@testable import PTPerformance

final class TemplatesTests: IntegrationTestBase {

    var templatesService: TemplatesService!
    var testTherapistId: String!

    override func setUp() async throws {
        try await super.setUp()
        templatesService = TemplatesService.shared

        // Login as therapist
        let session = try await loginAsTherapist()
        testTherapistId = session.user.id.uuidString
    }

    // MARK: - Create Template Tests

    func testCreateTemplate_Success() async throws {
        let template = try await templatesService.createTemplate(
            name: "Test Strength Program",
            description: "Progressive strength building program",
            category: .strength,
            difficultyLevel: .intermediate,
            durationWeeks: 8,
            createdBy: testTherapistId,
            isPublic: false,
            tags: ["Strength", "Progressive Overload"]
        )

        // Verify created template
        XCTAssertNotNil(template.id)
        XCTAssertEqual(template.name, "Test Strength Program")
        XCTAssertEqual(template.category, .strength)
        XCTAssertEqual(template.difficultyLevel, .intermediate)
        XCTAssertEqual(template.durationWeeks, 8)
        XCTAssertEqual(template.createdBy, testTherapistId)
        XCTAssertFalse(template.isPublic)
        XCTAssertEqual(template.tags.count, 2)
        XCTAssertEqual(template.usageCount, 0)

        // Cleanup
        try await templatesService.deleteTemplate(templateId: template.id)
    }

    func testCreateTemplate_AllCategories() async throws {
        let categories = WorkoutTemplate.TemplateCategory.allCases
        var createdTemplates: [WorkoutTemplate] = []

        for category in categories {
            let template = try await templatesService.createTemplate(
                name: "Test \(category.displayName) Template",
                description: nil,
                category: category,
                difficultyLevel: .beginner,
                durationWeeks: 4,
                createdBy: testTherapistId,
                isPublic: false,
                tags: []
            )

            XCTAssertEqual(template.category, category)
            createdTemplates.append(template)
        }

        // Cleanup
        for template in createdTemplates {
            try await templatesService.deleteTemplate(templateId: template.id)
        }
    }

    // MARK: - Fetch Templates Tests

    func testFetchTemplates_ReturnsPublicAndOwnTemplates() async throws {
        // Create public template
        let publicTemplate = try await createTestTemplate(
            name: "Public Template",
            isPublic: true
        )

        // Create private template
        let privateTemplate = try await createTestTemplate(
            name: "Private Template",
            isPublic: false
        )

        // Fetch templates
        let templates = try await templatesService.fetchTemplates(for: testTherapistId)

        // Verify both templates are returned
        let templateIds = templates.map { $0.id }
        XCTAssertTrue(templateIds.contains(publicTemplate.id))
        XCTAssertTrue(templateIds.contains(privateTemplate.id))

        // Cleanup
        try await templatesService.deleteTemplate(templateId: publicTemplate.id)
        try await templatesService.deleteTemplate(templateId: privateTemplate.id)
    }

    func testFetchPopularTemplates_OrdersByUsageCount() async throws {
        // Note: This test assumes we can manually set usage_count
        // In production, usage_count is incremented when templates are used
        let templates = try await templatesService.fetchPopularTemplates(limit: 5)

        // Verify templates are ordered by usage count
        for i in 0..<templates.count - 1 {
            XCTAssertGreaterThanOrEqual(
                templates[i].usageCount,
                templates[i + 1].usageCount,
                "Templates should be ordered by usage count descending"
            )
        }
    }

    // MARK: - Template Details Tests

    func testFetchTemplateDetails_IncludesPhasesAndSessions() async throws {
        // Create template with phases and sessions
        let template = try await createTestTemplate(name: "Detailed Template", isPublic: false)

        let phase1 = try await templatesService.addPhase(
            to: template.id,
            name: "Phase 1",
            description: "Foundation phase",
            sequence: 1,
            durationWeeks: 4
        )

        let phase2 = try await templatesService.addPhase(
            to: template.id,
            name: "Phase 2",
            description: "Build phase",
            sequence: 2,
            durationWeeks: 4
        )

        let session1 = try await templatesService.addSession(
            to: phase1.id,
            name: "Session 1A",
            description: nil,
            sequence: 1,
            exercises: [createTestExercise(sequence: 1)],
            notes: nil
        )

        // Fetch details
        let details = try await templatesService.fetchTemplateDetails(templateId: template.id)

        // Verify structure
        XCTAssertEqual(details.template.id, template.id)
        XCTAssertEqual(details.phases.count, 2)
        XCTAssertEqual(details.phases[0].phase.id, phase1.id)
        XCTAssertEqual(details.phases[1].phase.id, phase2.id)
        XCTAssertEqual(details.phases[0].sessions.count, 1)
        XCTAssertEqual(details.phases[0].sessions[0].id, session1.id)

        // Cleanup
        try await templatesService.deleteTemplate(templateId: template.id)
    }

    // MARK: - Update Template Tests

    func testUpdateTemplate_Success() async throws {
        let template = try await createTestTemplate(name: "Original Name", isPublic: false)

        // Update template
        let updated = try await templatesService.updateTemplate(
            templateId: template.id,
            updates: [
                "name": "Updated Name",
                "description": "Updated description",
                "is_public": true
            ]
        )

        // Verify updates
        XCTAssertEqual(updated.name, "Updated Name")
        XCTAssertEqual(updated.description, "Updated description")
        XCTAssertTrue(updated.isPublic)

        // Cleanup
        try await templatesService.deleteTemplate(templateId: template.id)
    }

    // MARK: - Delete Template Tests

    func testDeleteTemplate_CascadesDeletes() async throws {
        // Create template with phases and sessions
        let template = try await createTestTemplate(name: "To Delete", isPublic: false)
        let phase = try await templatesService.addPhase(
            to: template.id,
            name: "Phase 1",
            description: nil,
            sequence: 1,
            durationWeeks: nil
        )
        _ = try await templatesService.addSession(
            to: phase.id,
            name: "Session 1",
            description: nil,
            sequence: 1,
            exercises: [],
            notes: nil
        )

        // Delete template
        try await templatesService.deleteTemplate(templateId: template.id)

        // Verify template is deleted
        do {
            _ = try await templatesService.fetchTemplateDetails(templateId: template.id)
            XCTFail("Template should be deleted")
        } catch {
            // Expected to fail
        }
    }

    // MARK: - Phase Operations Tests

    func testAddPhase_Success() async throws {
        let template = try await createTestTemplate(name: "Template with Phases", isPublic: false)

        let phase = try await templatesService.addPhase(
            to: template.id,
            name: "Foundation Phase",
            description: "Build strength base",
            sequence: 1,
            durationWeeks: 4
        )

        // Verify phase
        XCTAssertNotNil(phase.id)
        XCTAssertEqual(phase.templateId, template.id)
        XCTAssertEqual(phase.name, "Foundation Phase")
        XCTAssertEqual(phase.sequence, 1)
        XCTAssertEqual(phase.durationWeeks, 4)

        // Cleanup
        try await templatesService.deleteTemplate(templateId: template.id)
    }

    func testDeletePhase_Success() async throws {
        let template = try await createTestTemplate(name: "Template", isPublic: false)
        let phase = try await templatesService.addPhase(
            to: template.id,
            name: "Phase",
            description: nil,
            sequence: 1,
            durationWeeks: nil
        )

        // Delete phase
        try await templatesService.deletePhase(phaseId: phase.id)

        // Verify phase is deleted
        let details = try await templatesService.fetchTemplateDetails(templateId: template.id)
        XCTAssertEqual(details.phases.count, 0)

        // Cleanup
        try await templatesService.deleteTemplate(templateId: template.id)
    }

    // MARK: - Session Operations Tests

    func testAddSession_WithExercises() async throws {
        let template = try await createTestTemplate(name: "Template", isPublic: false)
        let phase = try await templatesService.addPhase(
            to: template.id,
            name: "Phase",
            description: nil,
            sequence: 1,
            durationWeeks: nil
        )

        let exercises = [
            createTestExercise(sequence: 1, sets: 3, reps: 10),
            createTestExercise(sequence: 2, sets: 3, reps: 12),
            createTestExercise(sequence: 3, sets: 4, reps: 8)
        ]

        let session = try await templatesService.addSession(
            to: phase.id,
            name: "Upper Body Strength",
            description: "Focus on compound movements",
            sequence: 1,
            exercises: exercises,
            notes: "Warm up thoroughly"
        )

        // Verify session
        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.phaseId, phase.id)
        XCTAssertEqual(session.exercises.count, 3)
        XCTAssertEqual(session.exercises[0].sets, 3)
        XCTAssertEqual(session.exercises[0].reps, 10)

        // Cleanup
        try await templatesService.deleteTemplate(templateId: template.id)
    }

    // MARK: - Create Program from Template Tests

    func testCreateProgramFromTemplate_Success() async throws {
        // Create a complete template
        let template = try await createCompleteTestTemplate()

        // Get a patient ID
        let patientId = try await getFirstPatientId()

        // Create program from template
        let programId = try await templatesService.createProgramFromTemplate(
            templateId: template.id,
            patientId: patientId,
            programName: "Patient's Custom Program",
            startDate: Date()
        )

        // Verify program was created
        XCTAssertNotNil(programId)

        // Verify program has phases and sessions copied from template
        let programBuilderService = ProgramBuilderService()
        let createdProgram = try await programBuilderService.getProgram(id: UUID(uuidString: programId)!)

        // Verify program structure matches template
        XCTAssertEqual(createdProgram.name, "Patient's Custom Program")
        XCTAssertGreaterThan(createdProgram.phases.count, 0, "Program should have phases copied from template")

        // Verify template usage count was incremented
        let details = try await templatesService.fetchTemplateDetails(templateId: template.id)
        XCTAssertEqual(details.template.usageCount, 1)

        // Cleanup
        try await templatesService.deleteTemplate(templateId: template.id)
        try await programBuilderService.deleteProgram(id: UUID(uuidString: programId)!)
    }

    // MARK: - Search Tests

    func testSearchTemplates_FindsByName() async throws {
        let template = try await createTestTemplate(
            name: "Unique Search Test Template",
            isPublic: true
        )

        let results = try await templatesService.searchTemplates(
            searchText: "Unique Search Test",
            userId: testTherapistId
        )

        XCTAssertTrue(results.contains { $0.id == template.id })

        // Cleanup
        try await templatesService.deleteTemplate(templateId: template.id)
    }

    // MARK: - RLS Policy Tests

    func testPatientCannotCreateTemplate() async throws {
        // Login as patient
        try await loginAsPatient()

        // Try to create template
        do {
            _ = try await templatesService.createTemplate(
                name: "Unauthorized Template",
                description: nil,
                category: .strength,
                difficultyLevel: .beginner,
                durationWeeks: nil,
                createdBy: "patient-id",
                isPublic: false,
                tags: []
            )
            XCTFail("Patients should not be able to create templates")
        } catch {
            // Expected to fail
        }
    }

    func testTherapistCannotModifyOthersTemplate() async throws {
        // Create template as current therapist
        let template = try await createTestTemplate(name: "My Template", isPublic: false)

        // Login as different therapist
        try await loginAsTherapist(email: "therapist2@test.com") // Assume different therapist exists

        // Try to update the template
        do {
            _ = try await templatesService.updateTemplate(
                templateId: template.id,
                updates: ["name": "Stolen Template"]
            )
            XCTFail("Therapist should not be able to modify another therapist's template")
        } catch {
            // Expected to fail
        }

        // Cleanup (switch back to original therapist)
        try await loginAsTherapist()
        try await templatesService.deleteTemplate(templateId: template.id)
    }

    // MARK: - Performance Tests

    func testFetchTemplates_Performance() async throws {
        measure {
            let expectation = self.expectation(description: "Fetch templates")

            Task {
                do {
                    _ = try await templatesService.fetchTemplates(for: testTherapistId)
                    expectation.fulfill()
                } catch {
                    XCTFail("Fetch failed: \(error)")
                    expectation.fulfill()
                }
            }

            waitForExpectations(timeout: 5.0)
        }
    }

    // MARK: - Helper Methods

    private func createTestTemplate(name: String, isPublic: Bool) async throws -> WorkoutTemplate {
        try await templatesService.createTemplate(
            name: name,
            description: "Test description",
            category: .strength,
            difficultyLevel: .intermediate,
            durationWeeks: 8,
            createdBy: testTherapistId,
            isPublic: isPublic,
            tags: ["Test"]
        )
    }

    private func createTestExercise(
        sequence: Int,
        sets: Int = 3,
        reps: Int = 10
    ) -> TemplateExercise {
        TemplateExercise(
            exerciseId: UUID().uuidString,
            sequence: sequence,
            sets: sets,
            reps: reps,
            duration: nil,
            rest: 60,
            notes: nil,
            weight: nil,
            intensity: nil
        )
    }

    private func createCompleteTestTemplate() async throws -> WorkoutTemplate {
        let template = try await createTestTemplate(
            name: "Complete Test Template",
            isPublic: true
        )

        let phase = try await templatesService.addPhase(
            to: template.id,
            name: "Phase 1",
            description: nil,
            sequence: 1,
            durationWeeks: 4
        )

        _ = try await templatesService.addSession(
            to: phase.id,
            name: "Session 1",
            description: nil,
            sequence: 1,
            exercises: [createTestExercise(sequence: 1)],
            notes: nil
        )

        return template
    }

    private func getFirstPatientId() async throws -> String {
        let patients: [Patient] = try await supabase.client
            .from("patients")
            .select()
            .limit(1)
            .execute()
            .value

        guard let firstPatient = patients.first else {
            throw NSError(
                domain: "TestError",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "No patients found"]
            )
        }

        return firstPatient.id
    }
}
