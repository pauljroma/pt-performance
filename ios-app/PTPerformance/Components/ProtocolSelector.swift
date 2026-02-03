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
                
                ForEach(protocols) { therapyProtocol in
                    Text(therapyProtocol.name).tag(therapyProtocol as TherapyProtocol?)
                }
            }
            .pickerStyle(.menu)
            
            if let therapyProtocol = selectedProtocol {
                ProtocolInfoCard(therapyProtocol: therapyProtocol)
            }
        }
    }
}

struct ProtocolInfoCard: View {
    let therapyProtocol: TherapyProtocol

    var totalWeeks: Int {
        therapyProtocol.phases.map(\.durationWeeks).reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(therapyProtocol.description)
                .font(.callout)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Label("\(therapyProtocol.phases.count) phases", systemImage: "list.number")
                Label("\(totalWeeks) weeks", systemImage: "calendar")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            if !therapyProtocol.constraints.requiredExerciseTypes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Required:")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Text(therapyProtocol.constraints.requiredExerciseTypes.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
