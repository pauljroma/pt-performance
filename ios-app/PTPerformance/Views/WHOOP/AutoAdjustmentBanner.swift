//
//  AutoAdjustmentBanner.swift
//  PTPerformance
//
//  Build 76 - WHOOP Integration
//

import SwiftUI

struct AutoAdjustmentBanner: View {
    let recovery: WHOOPRecovery
    let adjustment: SessionAdjustment
    @Binding var isAccepted: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.blue)

                Text("WHOOP Auto-Adjustment")
                    .font(.headline)

                Spacer()
            }

            // Description
            Text(adjustment.notes)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Metrics
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Volume")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(adjustment.volumeMultiplier * 100))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Divider()

                VStack(alignment: .leading) {
                    Text("Intensity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(adjustment.intensity.rawValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            .frame(height: 50)

            // Action Buttons
            if isAccepted == nil {
                HStack {
                    Button("Decline") {
                        isAccepted = false
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Apply Adjustment") {
                        isAccepted = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if isAccepted == true {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Adjustment Applied")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.green)
            } else {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                    Text("Adjustment Declined")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// Preview
struct AutoAdjustmentBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AutoAdjustmentBanner(
                recovery: WHOOPRecovery(
                    id: UUID(),
                    athleteId: UUID(),
                    date: Date(),
                    recoveryScore: 45,
                    hrvRmssd: 55.0,
                    restingHr: 58,
                    hrvBaseline: 60.0,
                    sleepPerformance: 70,
                    readinessBand: "yellow",
                    syncedAt: Date()
                ),
                adjustment: SessionAdjustment(
                    volumeMultiplier: 0.85,
                    intensity: .moderate,
                    notes: "Moderate recovery - reduce volume to 85%"
                ),
                isAccepted: .constant(nil)
            )

            AutoAdjustmentBanner(
                recovery: WHOOPRecovery(
                    id: UUID(),
                    athleteId: UUID(),
                    date: Date(),
                    recoveryScore: 45,
                    hrvRmssd: 55.0,
                    restingHr: 58,
                    hrvBaseline: 60.0,
                    sleepPerformance: 70,
                    readinessBand: "yellow",
                    syncedAt: Date()
                ),
                adjustment: SessionAdjustment(
                    volumeMultiplier: 0.85,
                    intensity: .moderate,
                    notes: "Moderate recovery - reduce volume to 85%"
                ),
                isAccepted: .constant(true)
            )
        }
        .padding()
    }
}
