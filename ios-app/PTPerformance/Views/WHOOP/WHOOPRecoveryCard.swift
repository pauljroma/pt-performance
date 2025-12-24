//
//  WHOOPRecoveryCard.swift
//  PTPerformance
//
//  Build 76 - WHOOP Integration
//

import SwiftUI

struct WHOOPRecoveryCard: View {
    let recovery: WHOOPRecovery

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)

                Text("WHOOP Recovery")
                    .font(.headline)

                Spacer()

                Text(recovery.readinessBandEnum.emoji)
                    .font(.title2)
            }

            // Recovery Score
            VStack(alignment: .leading, spacing: 4) {
                Text("Recovery Score")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(alignment: .bottom) {
                    Text("\(Int(recovery.recoveryScore))%")
                        .font(.system(size: 36, weight: .bold))

                    Text(recovery.recoveryLevel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
            }

            // Progress Bar
            ProgressView(value: recovery.recoveryScore, total: 100)
                .tint(recovery.readinessBandEnum.color)
                .scaleEffect(x: 1, y: 2, anchor: .center)

            // Details Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let hrv = recovery.hrvRmssd {
                    MetricCell(title: "HRV", value: "\(Int(hrv)) ms")
                }

                if let rhr = recovery.restingHr {
                    MetricCell(title: "Resting HR", value: "\(rhr) bpm")
                }

                if let sleep = recovery.sleepPerformance {
                    MetricCell(title: "Sleep", value: "\(Int(sleep))%")
                }
            }

            // Sync timestamp
            Text("Synced \(timeAgoDisplay(recovery.syncedAt))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func timeAgoDisplay(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct MetricCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// Preview
struct WHOOPRecoveryCard_Previews: PreviewProvider {
    static var previews: some View {
        WHOOPRecoveryCard(recovery: WHOOPRecovery(
            id: UUID(),
            athleteId: UUID(),
            date: Date(),
            recoveryScore: 75,
            hrvRmssd: 65.5,
            restingHr: 52,
            hrvBaseline: 60.0,
            sleepPerformance: 85,
            readinessBand: "green",
            syncedAt: Date()
        ))
        .padding()
    }
}
