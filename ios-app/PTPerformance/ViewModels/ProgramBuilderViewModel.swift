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
    
    func loadProtocolPhases(_ protocol: TherapyProtocol) {
        // Load phases from protocol
        phases = protocol.phases.map { protocolPhase in
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
    
    func createProgram(patientId: UUID?) async {
        // In production, save to Supabase:
        // 1. Create program record
        // 2. Create phase records
        // 3. If patientId provided, assign to patient
        
        print("Creating program: \(programName)")
        print("Protocol: \(selectedProtocol?.name ?? "Custom")")
        print("Phases: \(phases.count)")
        
        // TODO: Implement Supabase save
        /*
        do {
            let programData: [String: Any] = [
                "name": programName,
                "protocol_id": selectedProtocol?.id.uuidString,
                "patient_id": patientId?.uuidString,
                "created_at": Date().ISO8601Format()
            ]
            
            let response = try await supabase
                .from("programs")
                .insert(programData)
                .execute()
            
            // Save phases...
        } catch {
            print("Error creating program: \(error)")
        }
        */
    }
}
