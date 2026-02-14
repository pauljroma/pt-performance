//
//  ACWRDetailsSheet.swift
//  PTPerformance
//
//  Detail sheet for ACWR (Acute:Chronic Workload Ratio) information
//  Extracted from PerformanceModeDashboardView.swift
//

import SwiftUI

// MARK: - ACWR Details Sheet

struct ACWRDetailsSheet: View {
    let acwr: Double
    let status: ACWRStatus
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // ACWR gauge
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                            .frame(width: 150, height: 150)

                        Circle()
                            .trim(from: 0, to: min(1.0, acwr / 2.0))
                            .stroke(statusColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 4) {
                            Text(String(format: "%.2f", acwr))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(statusColor)

                            Text("ACWR")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()

                    // Status
                    VStack(spacing: Spacing.sm) {
                        Text(status.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(statusColor)

                        Text(status.recommendation)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                    // Zone descriptions
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("ACWR Zones")
                            .font(.headline)
                            .foregroundColor(.modusDeepTeal)

                        zoneRow(color: .blue, range: "< 0.8", label: "Undertraining", description: "Training load may be too low")
                        zoneRow(color: .green, range: "0.8 - 1.3", label: "Optimal", description: "Sweet spot for adaptation")
                        zoneRow(color: .yellow, range: "1.3 - 1.5", label: "Caution", description: "Increased injury risk")
                        zoneRow(color: .red, range: "> 1.5", label: "Danger", description: "High injury risk, reduce load")
                    }
                    .padding()
                }
            }
            .navigationTitle("ACWR Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var statusColor: Color {
        status.color
    }

    private func zoneRow(color: Color, range: String, label: String, description: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(range)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text("-")
                        .foregroundColor(.secondary)

                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(Spacing.sm)
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
    }
}
