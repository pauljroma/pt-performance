//
//  AISafetyAlert.swift
//  PTPerformance
//
//  Build 77 - AI Helper MVP
//

import SwiftUI

struct AISafetyAlert: View {
    let warningLevel: String  // "info", "caution", "warning", "danger"
    let reason: String
    let risks: [String]
    let recommendations: [String]
    @Binding var isDismissed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                Text(warningLevel.capitalized)
                    .font(.headline)
                    .foregroundColor(iconColor)
                Spacer()
                Button {
                    isDismissed = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            // Reason
            Text(reason)
                .font(.subheadline)
                .foregroundColor(.primary)

            // Risks
            if !risks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Risks:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    ForEach(risks, id: \.self) { risk in
                        HStack(alignment: .top, spacing: 4) {
                            Text("•")
                            Text(risk)
                                .font(.caption)
                        }
                    }
                }
            }

            // Recommendations
            if !recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendations:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    ForEach(recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 4) {
                            Text("✓")
                                .foregroundColor(.green)
                            Text(recommendation)
                                .font(.caption)
                        }
                    }
                }
            }

            // Actions
            HStack {
                Button("Contact PT") {
                    // Open messaging
                }
                .buttonStyle(.bordered)

                Spacer()

                if warningLevel != "danger" {
                    Button("Continue Anyway") {
                        isDismissed = true
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(iconColor, lineWidth: 2)
        )
    }

    private var iconName: String {
        switch warningLevel {
        case "info": return "info.circle"
        case "caution": return "exclamationmark.triangle"
        case "warning": return "exclamationmark.triangle.fill"
        case "danger": return "octagon.fill"
        default: return "info.circle"
        }
    }

    private var iconColor: Color {
        switch warningLevel {
        case "info": return .blue
        case "caution": return .yellow
        case "warning": return .orange
        case "danger": return .red
        default: return .blue
        }
    }

    private var backgroundColor: Color {
        iconColor.opacity(0.1)
    }
}

// Preview
struct AISafetyAlert_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AISafetyAlert(
                warningLevel: "warning",
                reason: "Overhead press may aggravate shoulder injury",
                risks: ["Shoulder impingement risk", "Pain during movement"],
                recommendations: ["Use neutral grip dumbbell press", "Reduce weight by 50%"],
                isDismissed: .constant(false)
            )

            AISafetyAlert(
                warningLevel: "danger",
                reason: "Critical contraindication detected",
                risks: ["High injury risk with current condition"],
                recommendations: ["Consult PT immediately", "Do not perform this exercise"],
                isDismissed: .constant(false)
            )
        }
        .padding()
    }
}
