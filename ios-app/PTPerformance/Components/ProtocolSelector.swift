//
//  ProtocolSelector.swift
//  PTPerformance
//

import SwiftUI

struct ProtocolSelector: View {
    @Binding var selectedProtocol: TherapyProtocol?
    let protocols: [TherapyProtocol]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Protocol")
                .font(.headline)
            
            Picker("Protocol", selection: $selectedProtocol) {
                Text("None (Custom Program)").tag(nil as TherapyProtocol?)
                
                ForEach(protocols) { protocol in
                    Text(protocol.name).tag(protocol as TherapyProtocol?)
                }
            }
            .pickerStyle(.menu)
            
            if let protocol = selectedProtocol {
                ProtocolInfoCard(protocol: protocol)
            }
        }
    }
}

struct ProtocolInfoCard: View {
    let protocol: TherapyProtocol
    
    var totalWeeks: Int {
        protocol.phases.map(\.durationWeeks).reduce(0, +)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(protocol.description)
                .font(.callout)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                Label("\(protocol.phases.count) phases", systemImage: "list.number")
                Label("\(totalWeeks) weeks", systemImage: "calendar")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            if !protocol.constraints.requiredExerciseTypes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Required:")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(protocol.constraints.requiredExerciseTypes.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
