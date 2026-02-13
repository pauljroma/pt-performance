//
//  WorkloadFlagBanner.swift
//  PTPerformance
//
//  Display workload alerts and flags
//

import SwiftUI

struct WorkloadFlagBanner: View {
    let flag: WorkloadFlag
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: flag.icon)
                    .font(.title2)
                    .foregroundColor(flag.color)
                    .frame(width: 32)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(flag.flagType.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(flag.color)

                    Text(flag.message)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        Text(String(format: "%.1f", flag.value))
                            .fontWeight(.semibold)
                        Text("/ \(String(format: "%.1f", flag.threshold))")
                        Text("threshold")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(flag.color.opacity(0.1))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .strokeBorder(flag.color, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Workload flag: \(flag.message)")
    }
}

struct WorkloadFlagsList: View {
    let flags: [WorkloadFlag]
    let onFlagTap: (WorkloadFlag) -> Void

    var criticalFlags: [WorkloadFlag] {
        flags.filter { $0.severity == .critical }
    }

    var warningFlags: [WorkloadFlag] {
        flags.filter { $0.severity == .warning }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !criticalFlags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Critical Alerts", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundColor(.red)

                    ForEach(criticalFlags) { flag in
                        WorkloadFlagBanner(flag: flag) {
                            onFlagTap(flag)
                        }
                    }
                }
            }

            if !warningFlags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Warnings", systemImage: "exclamationmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.orange)

                    ForEach(warningFlags) { flag in
                        WorkloadFlagBanner(flag: flag) {
                            onFlagTap(flag)
                        }
                    }
                }
            }
        }
    }
}

// Preview
#if DEBUG
struct WorkloadFlagBanner_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                WorkloadFlagsList(flags: WorkloadFlag.sampleFlags) { flag in
                    print("Tapped: \(flag.message)")
                }
            }
            .padding()
        }
    }
}
#endif
