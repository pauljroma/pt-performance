//
//  QuickBuildOptionsView.swift
//  PTPerformance
//
//  Quick Build templates feature for the enhanced program builder.
//  Provides pre-built program template cards for rapid program creation.
//

import SwiftUI

// MARK: - Data Structures

/// Represents a phase within a program template
struct PhaseTemplate {
    let name: String
    let weekStart: Int
    let weekEnd: Int
    let goal: String
}

/// Represents a pre-built program template for quick creation
struct QuickBuildTemplate: Identifiable {
    let id = UUID()
    let name: String
    let type: String // "rehab", "performance", "lifestyle"
    let durationWeeks: Int
    let phases: [PhaseTemplate]
    let icon: String
    let description: String
}

// MARK: - Template Data

extension QuickBuildTemplate {
    /// All available program templates
    static let templates: [QuickBuildTemplate] = [
        // 4-Week Post-Op Recovery - Rehab type, 4 weeks, 3 phases
        QuickBuildTemplate(
            name: "4-Week Post-Op Recovery",
            type: "rehab",
            durationWeeks: 4,
            phases: [
                PhaseTemplate(
                    name: "Protection Phase",
                    weekStart: 1,
                    weekEnd: 1,
                    goal: "Manage pain and swelling, protect surgical site, begin gentle ROM exercises"
                ),
                PhaseTemplate(
                    name: "Early Mobility",
                    weekStart: 2,
                    weekEnd: 3,
                    goal: "Restore range of motion, reduce inflammation, begin gentle strengthening"
                ),
                PhaseTemplate(
                    name: "Progressive Loading",
                    weekStart: 4,
                    weekEnd: 4,
                    goal: "Build foundational strength, improve functional movement patterns"
                )
            ],
            icon: "cross.case.fill",
            description: "Structured recovery protocol for post-surgical rehabilitation with progressive loading"
        ),

        // 8-Week Return to Sport - Performance type, 8 weeks, 4 phases
        QuickBuildTemplate(
            name: "8-Week Return to Sport",
            type: "performance",
            durationWeeks: 8,
            phases: [
                PhaseTemplate(
                    name: "Foundation",
                    weekStart: 1,
                    weekEnd: 2,
                    goal: "Establish movement quality and baseline aerobic conditioning"
                ),
                PhaseTemplate(
                    name: "Strength Development",
                    weekStart: 3,
                    weekEnd: 4,
                    goal: "Build sport-specific strength and increase training volume"
                ),
                PhaseTemplate(
                    name: "Power & Agility",
                    weekStart: 5,
                    weekEnd: 6,
                    goal: "Develop explosive power, agility, and change of direction skills"
                ),
                PhaseTemplate(
                    name: "Sport Integration",
                    weekStart: 7,
                    weekEnd: 8,
                    goal: "Full sport-specific training and competition preparation"
                )
            ],
            icon: "figure.run",
            description: "Progressive return to athletic performance with sport-specific conditioning phases"
        ),

        // 12-Week Strength Foundation - Lifestyle type, 12 weeks, 3 phases
        QuickBuildTemplate(
            name: "12-Week Strength Foundation",
            type: "lifestyle",
            durationWeeks: 12,
            phases: [
                PhaseTemplate(
                    name: "Movement Mastery",
                    weekStart: 1,
                    weekEnd: 4,
                    goal: "Learn fundamental movement patterns, build exercise consistency"
                ),
                PhaseTemplate(
                    name: "Strength Building",
                    weekStart: 5,
                    weekEnd: 8,
                    goal: "Progressive overload training, develop muscular strength"
                ),
                PhaseTemplate(
                    name: "Performance Peak",
                    weekStart: 9,
                    weekEnd: 12,
                    goal: "Maximize strength gains, establish sustainable training habits"
                )
            ],
            icon: "dumbbell.fill",
            description: "Comprehensive strength program for building a solid fitness foundation"
        ),

        // 6-Week ACL Protocol - Rehab type, 6 weeks
        QuickBuildTemplate(
            name: "6-Week ACL Protocol",
            type: "rehab",
            durationWeeks: 6,
            phases: [
                PhaseTemplate(
                    name: "Initial Recovery",
                    weekStart: 1,
                    weekEnd: 2,
                    goal: "Control inflammation, restore knee extension, quad activation"
                ),
                PhaseTemplate(
                    name: "Strength & Stability",
                    weekStart: 3,
                    weekEnd: 4,
                    goal: "Progressive strengthening, proprioceptive training, gait normalization"
                ),
                PhaseTemplate(
                    name: "Functional Progression",
                    weekStart: 5,
                    weekEnd: 6,
                    goal: "Dynamic stability, early plyometrics, return to running protocol"
                )
            ],
            icon: "figure.walk",
            description: "Evidence-based ACL rehabilitation with neuromuscular training focus"
        ),

        // Custom Program - Blank slate
        QuickBuildTemplate(
            name: "Custom Program",
            type: "custom",
            durationWeeks: 0,
            phases: [],
            icon: "plus.rectangle.on.folder.fill",
            description: "Start from scratch and build your own fully customized program"
        )
    ]
}

// MARK: - Quick Build Options View

struct QuickBuildOptionsView: View {
    let onTemplateSelected: (QuickBuildTemplate) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(QuickBuildTemplate.templates) { template in
                        QuickBuildTemplateCard(template: template)
                            .onTapGesture {
                                onTemplateSelected(template)
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Build")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Choose a template to get started quickly")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

// MARK: - Template Card View

struct QuickBuildTemplateCard: View {
    let template: QuickBuildTemplate

    @State private var isPressed = false

    private var typeColor: Color {
        switch template.type {
        case "rehab":
            return .blue
        case "performance":
            return .orange
        case "lifestyle":
            return .green
        case "custom":
            return .purple
        default:
            return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and duration badge
            HStack {
                ZStack {
                    Circle()
                        .fill(typeColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: template.icon)
                        .font(.system(size: 20))
                        .foregroundColor(typeColor)
                }

                Spacer()

                if template.durationWeeks > 0 {
                    DurationBadge(weeks: template.durationWeeks)
                }
            }

            // Title
            Text(template.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Description
            Text(template.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            // Phase count indicator or custom label
            phaseIndicator
        }
        .padding(16)
        .frame(minHeight: 180)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(typeColor.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(template.name), \(template.durationWeeks > 0 ? "\(template.durationWeeks) weeks" : "custom duration")")
        .accessibilityHint("Double tap to start building with this template")
    }

    @ViewBuilder
    private var phaseIndicator: some View {
        if !template.phases.isEmpty {
            HStack(spacing: 4) {
                Image(systemName: "list.bullet")
                    .font(.caption2)
                Text("\(template.phases.count) phases")
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
        } else if template.type == "custom" {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                Text("Blank slate")
                    .font(.caption2)
            }
            .foregroundColor(.purple)
        }
    }
}

// MARK: - Duration Badge

struct DurationBadge: View {
    let weeks: Int

    var body: some View {
        Text("\(weeks)W")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.accentBlue)
            )
    }
}

// MARK: - Color Extension

private extension Color {
    static let accentBlue = Color(red: 0.2, green: 0.5, blue: 0.9)
}

// MARK: - Legacy Support

/// Backward-compatible type alias for existing code using QuickBuildOption
// Legacy alias removed - use QuickBuildTemplate directly

extension QuickBuildTemplate {
    /// Legacy accessor for backward compatibility
    static var allOptions: [QuickBuildTemplate] { templates }

    /// Computed properties for backward compatibility
    var title: String { name }
    var subtitle: String { durationWeeks > 0 ? "\(durationWeeks) weeks" : "Build from scratch" }
    var color: Color {
        switch type {
        case "rehab": return .blue
        case "performance": return .orange
        case "lifestyle": return .green
        case "custom": return .purple
        default: return .gray
        }
    }
    var isCustom: Bool { type == "custom" }
    var totalDurationWeeks: Int { durationWeeks }
}

// MARK: - Preview

#if DEBUG
struct QuickBuildOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        QuickBuildOptionsView { template in
            print("Selected: \(template.name)")
        }
    }
}
#endif
