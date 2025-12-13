//
//  ProgramBuilderViewModel.swift
//  PTPerformance
//

import Foundation
import SwiftUI

@MainActor
class ProgramBuilderViewModel: ObservableObject {
    @Published var programName: String = ""
    @Published var selectedProtocol: TherapyProtocol? {
        didSet {
            if let therapyProtocol = selectedProtocol {
                loadProtocolPhases(therapyProtocol)
            }
        }
    }
    @Published var phases: [ProgramPhase] = []
    @Published var availableProtocols: [TherapyProtocol] = []
    @Published var validationError: String?
    @Published var isCreating = false
    @Published var createError: String?

    private let supabase: PTSupabaseClient

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }
    
    var isValid: Bool {
        guard !programName.isEmpty else {
            validationError = "Program name is required"
            return false
        }
        
        guard !phases.isEmpty else {
            validationError = "At least one phase is required"
            return false
        }
        
        if let therapyProtocol = selectedProtocol {
            let constraints = therapyProtocol.constraints

            if phases.count < constraints.minPhases {
                validationError = "Protocol requires at least \(constraints.minPhases) phases"
                return false
            }

            if phases.count > constraints.maxPhases {
                validationError = "Protocol allows maximum \(constraints.maxPhases) phases"
                return false
            }
        }
        
        validationError = nil
        return true
    }
    
    var canAddPhase: Bool {
        guard let therapyProtocol = selectedProtocol else { return true }
        return phases.count < therapyProtocol.constraints.maxPhases
    }
    
    func loadProtocols() async {
        // For MVP, use sample protocols
        // In production, fetch from Supabase:
        // let response = try await supabase.from("protocol_templates").select().execute()
        
        availableProtocols = TherapyProtocol.sampleProtocols
    }
    
    func loadProtocolPhases(_ therapyProtocol: TherapyProtocol) {
        // Load phases from protocol
        phases = therapyProtocol.phases.map { protocolPhase in
            ProgramPhase(
                name: protocolPhase.name,
                durationWeeks: protocolPhase.durationWeeks,
                sessions: [],
                order: protocolPhase.order
            )
        }
    }
    
    func addPhase() {
        let newPhase = ProgramPhase(
            name: "Phase \(phases.count + 1)",
            durationWeeks: 2,
            sessions: [],
            order: phases.count + 1
        )
        phases.append(newPhase)
    }
    
    func deletePhase(at offsets: IndexSet) {
        // Only allow deletion if not using protocol with fixed phases
        guard selectedProtocol == nil || selectedProtocol?.constraints.canModifyDuration == true else {
            return
        }
        
        phases.remove(atOffsets: offsets)
        
        // Reorder remaining phases
        for (index, _) in phases.enumerated() {
            phases[index].order = index + 1
        }
    }
    
    func createProgram(patientId: String?, targetLevel: String = "Intermediate") async throws -> String {
        let logger = DebugLogger.shared
        isCreating = true
        createError = nil

        logger.log("📝 Creating program: \(programName)", level: .diagnostic)

        do {
            // Calculate total duration
            let totalWeeks = phases.reduce(0) { $0 + $1.durationWeeks }

            // Step 1: Create program record
            let programInput = CreateProgramInput(
                patientId: patientId,
                name: programName,
                targetLevel: targetLevel,
                durationWeeks: totalWeeks
            )

            logger.log("📝 Inserting program into programs table...", level: .diagnostic)

            let programResponse = try await supabase.client
                .from("programs")
                .insert(programInput)
                .select()
                .single()
                .execute()

            logger.log("✅ Program created successfully", level: .success)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let program = try decoder.decode(Program.self, from: programResponse.data)

            logger.log("✅ Program ID: \(program.id)", level: .success)

            // Step 2: Create phase records
            for (index, phase) in phases.enumerated() {
                let phaseInput = CreatePhaseInput(
                    programId: program.id,
                    phaseNumber: index + 1,
                    name: phase.name,
                    durationWeeks: phase.durationWeeks,
                    goals: nil
                )

                logger.log("📝 Creating phase \(index + 1): \(phase.name)", level: .diagnostic)

                try await supabase.client
                    .from("phases")
                    .insert(phaseInput)
                    .execute()

                logger.log("✅ Phase \(index + 1) created", level: .success)
            }

            logger.log("✅ Program creation complete!", level: .success)
            isCreating = false

            return program.id

        } catch {
            logger.log("❌ Error creating program: \(error)", level: .error)
            createError = error.localizedDescription
            isCreating = false
            throw error
        }
    }
}

// MARK: - Input Models for Supabase

struct CreateProgramInput: Codable {
    let patientId: String?
    let name: String
    let targetLevel: String
    let durationWeeks: Int

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case name
        case targetLevel = "target_level"
        case durationWeeks = "duration_weeks"
    }
}

struct CreatePhaseInput: Codable {
    let programId: String
    let phaseNumber: Int
    let name: String
    let durationWeeks: Int?
    let goals: String?

    enum CodingKeys: String, CodingKey {
        case programId = "program_id"
        case phaseNumber = "phase_number"
        case name
        case durationWeeks = "duration_weeks"
        case goals
    }
}
