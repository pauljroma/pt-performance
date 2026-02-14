// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  ContraindicationWarningView.swift
//  PTPerformance
//
//  ACP-395: PT Review Workflow - Contraindication Warning View
//  Displays safety warnings and contraindications for an AI-generated program.
//
//  Features:
//  - Warnings sorted by severity: Critical > Warning > Info
//  - Color-coded severity bands with appropriate SF Symbol icons
//  - Acknowledgement tracking for critical warnings
//  - Summary banner reflecting overall safety status
//  - Affected exercise links for each contraindication
//

import SwiftUI

// MARK: - Contraindication Warning View

/// Displays safety warnings for an AI-generated program during PT review.
///
/// Warnings are sorted by severity (critical first) and each must be
/// acknowledged by the PT before they can approve the program. The view
/// tracks acknowledgement state via a binding and provides a summary
/// banner reflecting the overall safety status.
struct ContraindicationWarningView: View {

    // MARK: - Properties

    let contraindications: [ReviewContraindication]
    @Binding var acknowledgedIds: Set<String>
    var onExerciseTapped: ((String) -> Void)?

    // MARK: - Body

    var body: some View {
        Group {
            if contraindications.isEmpty {
                safeStatusView
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        summaryBanner

                        ForEach(sortedReviewContraindications) { contraindication in
                            contraindicationCard(contraindication)
                        }
                    }
                    .padding(Spacing.md)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Computed Properties

    private var sortedReviewContraindications: [ReviewContraindication] {
        contraindications.sorted { $0.severity.sortOrder < $1.severity.sortOrder }
    }

    private var criticalCount: Int {
        contraindications.filter { $0.severity == .critical }.count
    }

    private var warningCount: Int {
        contraindications.filter { $0.severity == .warning }.count
    }

    private var infoCount: Int {
        contraindications.filter { $0.severity == .info }.count
    }

    private var criticalReviewContraindications: [ReviewContraindication] {
        contraindications.filter { $0.severity == .critical }
    }

    private var unacknowledgedCriticalCount: Int {
        criticalReviewContraindications.filter { !acknowledgedIds.contains($0.stableId) }.count
    }

    var allCriticalAcknowledged: Bool {
        criticalReviewContraindications.allSatisfy { acknowledgedIds.contains($0.stableId) }
    }

    // MARK: - Summary Banner

    private var summaryBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: bannerIcon)
                .font(.title3)
                .foregroundColor(.white)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(bannerTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                if criticalCount > 0 || warningCount > 0 {
                    Text(bannerSubtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }
            }

            Spacer()

            // Severity breakdown pills
            HStack(spacing: Spacing.xs) {
                if criticalCount > 0 {
                    severityCountPill(count: criticalCount, severity: .critical)
                }
                if warningCount > 0 {
                    severityCountPill(count: warningCount, severity: .warning)
                }
                if infoCount > 0 {
                    severityCountPill(count: infoCount, severity: .info)
                }
            }
        }
        .padding(Spacing.md)
        .background(bannerColor)
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(bannerAccessibilityLabel)
    }

    private var bannerIcon: String {
        if criticalCount > 0 {
            return "exclamationmark.triangle.fill"
        } else if warningCount > 0 {
            return "exclamationmark.circle.fill"
        } else {
            return "info.circle.fill"
        }
    }

    private var bannerColor: Color {
        if criticalCount > 0 {
            return DesignTokens.statusError
        } else if warningCount > 0 {
            return DesignTokens.statusWarning
        } else {
            return DesignTokens.statusInfo
        }
    }

    private var bannerTitle: String {
        if criticalCount > 0 {
            return "\(unacknowledgedCriticalCount) critical warning\(unacknowledgedCriticalCount == 1 ? "" : "s") require\(unacknowledgedCriticalCount == 1 ? "s" : "") acknowledgment"
        } else if warningCount > 0 {
            return "\(warningCount) warning\(warningCount == 1 ? "" : "s") to review"
        } else {
            return "\(infoCount) informational note\(infoCount == 1 ? "" : "s")"
        }
    }

    private var bannerSubtitle: String {
        let total = contraindications.count
        return "\(total) total contraindication\(total == 1 ? "" : "s") identified"
    }

    private var bannerAccessibilityLabel: String {
        if criticalCount > 0 {
            return "Safety alert: \(unacknowledgedCriticalCount) critical warnings require acknowledgment out of \(contraindications.count) total contraindications"
        } else if warningCount > 0 {
            return "\(warningCount) warnings to review out of \(contraindications.count) total contraindications"
        } else {
            return "\(infoCount) informational notes, no safety concerns"
        }
    }

    // MARK: - Severity Count Pill

    private func severityCountPill(count: Int, severity: ContraindicationSeverity) -> some View {
        Text("\(count)")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(severity.pillTextColor)
            .frame(minWidth: 20, minHeight: 20)
            .background(Circle().fill(.white.opacity(0.25)))
    }

    // MARK: - ReviewContraindication Card

    private func contraindicationCard(_ contraindication: ReviewContraindication) -> some View {
        let isAcknowledged = acknowledgedIds.contains(contraindication.stableId)

        return VStack(alignment: .leading, spacing: 0) {
            // Severity color band with icon
            HStack(spacing: Spacing.sm) {
                Image(systemName: contraindication.severity.iconName)
                    .font(.subheadline.weight(.semibold))
                    .accessibilityHidden(true)

                Text(contraindication.severity.displayName.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(0.5)

                Spacer()

                if isAcknowledged {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Acknowledged")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(contraindication.severity.color)

            // Card content
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Warning type
                Text(contraindication.type)
                    .font(.headline)
                    .foregroundColor(.primary)

                // Description
                Text(contraindication.description)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                // Affected exercises
                if !contraindication.affectedExercises.isEmpty {
                    affectedExercisesSection(contraindication.affectedExercises)
                }

                // Acknowledge toggle for critical warnings
                if contraindication.severity == .critical {
                    acknowledgeToggle(contraindication, isAcknowledged: isAcknowledged)
                }
            }
            .padding(Spacing.md)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(
                    contraindication.severity.color.opacity(
                        isAcknowledged ? 0.2 : 0.5
                    ),
                    lineWidth: isAcknowledged ? 1 : 2
                )
        )
        .opacity(isAcknowledged ? 0.85 : 1.0)
        .animation(.easeInOut(duration: AnimationDuration.standard), value: isAcknowledged)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(cardAccessibilityLabel(contraindication, isAcknowledged: isAcknowledged))
    }

    // MARK: - Affected Exercises Section

    private func affectedExercisesSection(_ exerciseIds: [UUID]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Affected Exercises")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .accessibilityAddTraits(.isHeader)

            FlowLayout(spacing: Spacing.xs) {
                ForEach(exerciseIds, id: \.self) { exerciseId in
                    let shortId = String(exerciseId.uuidString.prefix(8))
                    Button {
                        HapticFeedback.light()
                        onExerciseTapped?(exerciseId.uuidString)
                    } label: {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.caption2)
                                .accessibilityHidden(true)

                            Text("Exercise \(shortId)...")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.modusCyan)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.modusCyan.opacity(0.12))
                        .cornerRadius(CornerRadius.xs)
                    }
                    .accessibilityLabel("Exercise \(shortId). Tap to view exercise.")
                    .accessibilityAddTraits(.isLink)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Acknowledge Toggle

    private func acknowledgeToggle(
        _ contraindication: ReviewContraindication,
        isAcknowledged: Bool
    ) -> some View {
        Button {
            HapticFeedback.medium()
            withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                if isAcknowledged {
                    acknowledgedIds.remove(contraindication.stableId)
                } else {
                    acknowledgedIds.insert(contraindication.stableId)
                }
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: isAcknowledged ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isAcknowledged ? DesignTokens.statusSuccess : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isAcknowledged ? "Warning Acknowledged" : "Acknowledge Warning")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isAcknowledged ? DesignTokens.statusSuccess : .primary)

                    Text("Required before program approval")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(Spacing.sm)
            .background(
                isAcknowledged
                    ? DesignTokens.statusSuccess.opacity(0.08)
                    : Color(.tertiarySystemGroupedBackground)
            )
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(
                        isAcknowledged ? DesignTokens.statusSuccess.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isAcknowledged ? "Warning acknowledged" : "Acknowledge warning, required before program approval")
        .accessibilityHint("Double tap to \(isAcknowledged ? "remove acknowledgment" : "acknowledge this warning")")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Safe Status View (No ReviewContraindications)

    private var safeStatusView: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(DesignTokens.statusSuccess.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 36))
                    .foregroundColor(DesignTokens.statusSuccess)
            }
            .accessibilityHidden(true)

            Text("No Safety Concerns Identified")
                .font(.headline)
                .foregroundColor(.primary)

            Text("The AI system did not flag any contraindications or safety warnings for this program.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No safety concerns identified. No contraindications or safety warnings for this program.")
    }

    // MARK: - Helpers

    private func cardAccessibilityLabel(
        _ contraindication: ReviewContraindication,
        isAcknowledged: Bool
    ) -> String {
        var label = "\(contraindication.severity.displayName) contraindication: \(contraindication.type)"
        label += ". \(contraindication.description)"
        if !contraindication.affectedExercises.isEmpty {
            label += ". Affects \(contraindication.affectedExercises.count) exercise\(contraindication.affectedExercises.count == 1 ? "" : "s")"
        }
        if isAcknowledged {
            label += ". Acknowledged."
        }
        return label
    }
}

// MARK: - ContraindicationSeverity View Helpers

/// View-layer extensions for ContraindicationSeverity.
/// The core enum (with iconName, displayName) lives in ProgramReview.swift.
/// These add view-specific display properties that don't belong on the model.
extension ContraindicationSeverity {
    var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .warning: return 1
        case .info: return 2
        }
    }

    var color: Color {
        switch self {
        case .critical: return DesignTokens.statusError
        case .warning: return DesignTokens.statusWarning
        case .info: return DesignTokens.statusInfo
        }
    }

    var pillTextColor: Color {
        switch self {
        case .critical: return .white
        case .warning: return .white
        case .info: return .white
        }
    }
}

// MARK: - ReviewContraindication Stable ID

extension ReviewContraindication {
    /// Stable identifier derived from the contraindication's content, used for acknowledgement tracking.
    var stableId: String {
        "\(type)-\(severity)-\(description.prefix(32))"
    }
}

// MARK: - Preview

#if DEBUG

private extension ReviewContraindication {
    static let sampleReviewContraindications: [ReviewContraindication] = [
        ReviewContraindication(
            type: "Post-Surgical Precaution",
            description: "Patient is 8 weeks post-ACL reconstruction. Avoid open kinetic chain knee extension exercises beyond 60 degrees of flexion per surgical protocol.",
            severity: .critical,
            affectedExercises: [UUID(), UUID()]
        ),
        ReviewContraindication(
            type: "Range of Motion Restriction",
            description: "Patient has documented limited shoulder flexion (120 degrees). Overhead pressing movements may exacerbate impingement symptoms.",
            severity: .critical,
            affectedExercises: [UUID(), UUID(), UUID()]
        ),
        ReviewContraindication(
            type: "Load Progression Rate",
            description: "Recommended load increase exceeds 10% weekly progression guideline. Consider more gradual loading to reduce injury risk.",
            severity: .warning,
            affectedExercises: [UUID(), UUID()]
        ),
        ReviewContraindication(
            type: "Medication Interaction",
            description: "Patient is currently on blood thinners. High-intensity plyometric exercises carry elevated bruising risk.",
            severity: .warning,
            affectedExercises: [UUID(), UUID()]
        ),
        ReviewContraindication(
            type: "Age-Appropriate Modification",
            description: "Patient is 16 years old. Consider age-appropriate loading parameters for developing musculoskeletal system.",
            severity: .info,
            affectedExercises: [UUID()]
        )
    ]
}

#Preview("ReviewContraindications - Mixed Severity") {
    NavigationStack {
        ContraindicationWarningView(
            contraindications: ReviewContraindication.sampleReviewContraindications,
            acknowledgedIds: .constant(Set(["Post-Surgical Precaution-critical-Patient is 8 weeks post-ACL re"])),
            onExerciseTapped: { exercise in
                print("Tapped exercise: \(exercise)")
            }
        )
        .navigationTitle("Safety Warnings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("ReviewContraindications - All Clear") {
    NavigationStack {
        ContraindicationWarningView(
            contraindications: [],
            acknowledgedIds: .constant([])
        )
        .navigationTitle("Safety Warnings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("ReviewContraindications - Info Only") {
    NavigationStack {
        ContraindicationWarningView(
            contraindications: [
                ReviewContraindication(
                    type: "Training History Note",
                    description: "Patient has no prior resistance training experience. Start with bodyweight progressions.",
                    severity: .info,
                    affectedExercises: [UUID()]
                )
            ],
            acknowledgedIds: .constant([])
        )
        .navigationTitle("Safety Warnings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
