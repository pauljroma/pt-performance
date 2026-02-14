//
//  PatientContextCard.swift
//  PTPerformance
//
//  Patient Context Card for displaying patient information in the program builder.
//  Shows patient avatar, name, injury type, previous programs (count + last completed),
//  active goals, and suggested program type.
//

import SwiftUI

// MARK: - Patient Context Card

/// A card that displays patient information in the program builder.
/// Shows patient avatar (initials if no photo), name, injury/condition,
/// previous programs count with last completed date, active goals,
/// and suggested program type.
struct PatientContextCard: View {
    @Binding var patient: Patient?
    let previousProgramsCount: Int
    let lastCompletedDate: Date?
    let patientGoals: [PatientGoalSummary]
    let onSelectPatient: () -> Void

    // Convenience initializer for backward compatibility
    init(
        patient: Binding<Patient?>,
        previousProgramsCount: Int,
        patientGoal: String?,
        onSelectPatient: @escaping () -> Void
    ) {
        self._patient = patient
        self.previousProgramsCount = previousProgramsCount
        self.lastCompletedDate = nil
        // Convert single goal string to array
        if let goal = patientGoal {
            self.patientGoals = [PatientGoalSummary(id: UUID(), title: goal, category: .custom, progress: 0)]
        } else {
            self.patientGoals = []
        }
        self.onSelectPatient = onSelectPatient
    }

    // Full initializer with all parameters
    init(
        patient: Binding<Patient?>,
        previousProgramsCount: Int,
        lastCompletedDate: Date?,
        patientGoals: [PatientGoalSummary],
        onSelectPatient: @escaping () -> Void
    ) {
        self._patient = patient
        self.previousProgramsCount = previousProgramsCount
        self.lastCompletedDate = lastCompletedDate
        self.patientGoals = patientGoals
        self.onSelectPatient = onSelectPatient
    }

    // MARK: - Body

    var body: some View {
        if let patient = patient {
            patientCard(patient: patient)
        } else {
            selectPatientButton
        }
    }

    // MARK: - Patient Card

    private func patientCard(patient: Patient) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Avatar + Name + Injury
            headerSection(patient: patient)

            // Divider
            Divider()

            // Info rows
            infoSection(patient: patient)

            // Active Goals Section (if any)
            if !patientGoals.isEmpty {
                Divider()
                activeGoalsSection
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Header Section

    private func headerSection(patient: Patient) -> some View {
        HStack(spacing: 12) {
            // Avatar
            patientAvatar(patient: patient)

            // Name and condition
            VStack(alignment: .leading, spacing: 2) {
                Text(patient.fullName)
                    .font(.headline)
                    .foregroundColor(.primary)

                if let injuryType = patient.injuryType {
                    HStack(spacing: 4) {
                        Image(systemName: "bandage.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(injuryType)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if let sport = patient.sport {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.run")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text(sport)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Change button
            Button {
                HapticService.selection()
                onSelectPatient()
            } label: {
                Text("Change")
                    .font(.subheadline)
                    .foregroundColor(.modusCyan)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Patient Avatar

    private func patientAvatar(patient: Patient) -> some View {
        Group {
            if let profileImageUrl = patient.profileImageUrl,
               let url = URL(string: profileImageUrl) {
                // Photo avatar
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        initialsCircle(patient: patient)
                    @unknown default:
                        initialsCircle(patient: patient)
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
            } else {
                // Initials circle
                initialsCircle(patient: patient)
            }
        }
        .accessibilityHidden(true)
    }

    private func initialsCircle(patient: Patient) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.modusCyan, .modusCyan.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)

            Text(patient.initials)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }

    // MARK: - Info Section

    private func infoSection(patient: Patient) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Previous Programs with last completed date
            previousProgramsRow

            // Suggested program type
            let suggestedType = suggestProgramType(for: patient)
            suggestedProgramRow(type: suggestedType)
        }
    }

    private var previousProgramsRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text.fill")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(previousProgramsCount) Previous Program\(previousProgramsCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                if let lastCompleted = lastCompletedDate {
                    Text("Last completed \(lastCompleted.relativeDateString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if previousProgramsCount == 0 {
                    Text("First program for this patient")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Program history indicator
            if previousProgramsCount > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<min(previousProgramsCount, 3), id: \.self) { _ in
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                    if previousProgramsCount > 3 {
                        Text("+\(previousProgramsCount - 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func suggestedProgramRow(type: ProgramType) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.yellow)
                .frame(width: 16)

            Text("Suggested: ")
                .font(.subheadline)
                .foregroundColor(.primary)
            +
            Text("\(type.displayName) Program")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(type.color)

            Spacer()

            // Type icon
            Image(systemName: type.icon)
                .font(.caption)
                .foregroundColor(type.color)
                .padding(6)
                .background(type.color.opacity(0.15))
                .clipShape(Circle())
        }
    }

    // MARK: - Active Goals Section

    private var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "target")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Active Goals")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(patientGoals.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.modusCyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.modusCyan.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)
            }

            // Show up to 3 goals
            ForEach(patientGoals.prefix(3)) { goal in
                GoalRow(goal: goal)
            }

            // Show more indicator
            if patientGoals.count > 3 {
                Text("+\(patientGoals.count - 3) more goals")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 24)
            }
        }
    }

    // MARK: - Select Patient Button

    private var selectPatientButton: some View {
        Button {
            HapticService.selection()
            onSelectPatient()
        } label: {
            HStack(spacing: 12) {
                // Placeholder avatar
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 56, height: 56)

                    Image(systemName: "person.fill.badge.plus")
                        .font(.title3)
                        .foregroundColor(.modusCyan)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Select Patient")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Choose a patient for personalized program suggestions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select Patient")
        .accessibilityHint("Opens patient picker to choose a patient for the program")
    }

    // MARK: - Program Type Suggestion

    /// Suggests an appropriate program type based on patient injury and characteristics
    private func suggestProgramType(for patient: Patient) -> ProgramType {
        guard let injuryType = patient.injuryType else {
            // No injury - check for sport/performance context
            if patient.sport != nil || patient.targetLevel != nil {
                return .performance
            }
            return .lifestyle
        }

        let lowercased = injuryType.lowercased()

        // Post-surgical conditions -> Rehab
        let surgicalKeywords = [
            "surgery", "reconstruction", "repair", "replacement",
            "acl", "mcl", "pcl", "lcl", "tommy john", "ucl",
            "meniscus", "labrum", "rotator cuff", "achilles"
        ]
        for keyword in surgicalKeywords {
            if lowercased.contains(keyword) {
                return .rehab
            }
        }

        // Acute injuries -> Rehab
        let acuteKeywords = [
            "tear", "rupture", "fracture", "dislocation",
            "sprain", "strain", "tendinitis", "tendonitis",
            "bursitis", "impingement"
        ]
        for keyword in acuteKeywords {
            if lowercased.contains(keyword) {
                return .rehab
            }
        }

        // Chronic/overuse -> Could be rehab or performance
        let chronicKeywords = [
            "chronic", "overuse", "repetitive", "wear"
        ]
        for keyword in chronicKeywords {
            if lowercased.contains(keyword) {
                return .rehab
            }
        }

        // Pain conditions -> Rehab
        let painKeywords = [
            "pain", "ache", "soreness", "discomfort"
        ]
        for keyword in painKeywords {
            if lowercased.contains(keyword) {
                return .rehab
            }
        }

        // Recovery mentions -> Rehab
        if lowercased.contains("recovery") || lowercased.contains("rehab") {
            return .rehab
        }

        // If patient has sports context, lean toward performance
        if patient.sport != nil || patient.targetLevel != nil {
            return .performance
        }

        // Default to rehab for any unclassified injury
        return .rehab
    }
}

// MARK: - Patient Goal Summary

/// Simplified goal model for display in context card
struct PatientGoalSummary: Identifiable {
    let id: UUID
    let title: String
    let category: GoalCategory
    let progress: Double // 0.0 to 1.0

    init(id: UUID = UUID(), title: String, category: GoalCategory, progress: Double) {
        self.id = id
        self.title = title
        self.category = category
        self.progress = min(max(progress, 0), 1)
    }
}

// MARK: - Goal Row

private struct GoalRow: View {
    let goal: PatientGoalSummary

    var body: some View {
        HStack(spacing: 8) {
            // Category indicator
            Circle()
                .fill(goal.category.color)
                .frame(width: 8, height: 8)

            // Goal title
            Text(goal.title)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            // Progress indicator
            if goal.progress > 0 {
                HStack(spacing: 4) {
                    ProgressView(value: goal.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: goal.category.color))
                        .frame(width: 40)

                    Text("\(Int(goal.progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 30, alignment: .trailing)
                }
            } else {
                Text("Not started")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.leading, 24)
    }
}

// MARK: - Date Extension

private extension Date {
    var relativeDateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Preview Provider

#if DEBUG
struct PatientContextCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                // With patient selected - full info
                PatientContextCard(
                    patient: .constant(Patient.samplePatients[0]),
                    previousProgramsCount: 3,
                    lastCompletedDate: Calendar.current.date(byAdding: .day, value: -14, to: Date()),
                    patientGoals: [
                        PatientGoalSummary(
                            title: "Return to full throwing",
                            category: .rehabilitation,
                            progress: 0.65
                        ),
                        PatientGoalSummary(
                            title: "Pain-free overhead movement",
                            category: .painReduction,
                            progress: 0.8
                        ),
                        PatientGoalSummary(
                            title: "Increase ROM to 180 degrees",
                            category: .mobility,
                            progress: 0.45
                        ),
                        PatientGoalSummary(
                            title: "Build rotator cuff strength",
                            category: .strength,
                            progress: 0.3
                        )
                    ],
                    onSelectPatient: {}
                )
                .previewDisplayName("Full Patient Context")

                // With patient - no goals
                PatientContextCard(
                    patient: .constant(Patient.samplePatients[1]),
                    previousProgramsCount: 1,
                    lastCompletedDate: nil,
                    patientGoals: [],
                    onSelectPatient: {}
                )
                .previewDisplayName("Patient - No Goals")

                // No patient selected
                PatientContextCard(
                    patient: .constant(nil),
                    previousProgramsCount: 0,
                    patientGoal: nil,
                    onSelectPatient: {}
                )
                .previewDisplayName("No Patient")

                // Patient without injury (Performance suggestion)
                PatientContextCard(
                    patient: .constant(Patient(
                        id: UUID(),
                        therapistId: UUID(),
                        firstName: "Alex",
                        lastName: "Rivera",
                        email: "alex@example.com",
                        sport: "Tennis",
                        injuryType: nil,
                        targetLevel: "Recreational"
                    )),
                    previousProgramsCount: 0,
                    lastCompletedDate: nil,
                    patientGoals: [
                        PatientGoalSummary(
                            title: "Improve serve speed",
                            category: .endurance,
                            progress: 0.2
                        )
                    ],
                    onSelectPatient: {}
                )
                .previewDisplayName("Performance Patient")

                // First-time patient
                PatientContextCard(
                    patient: .constant(Patient(
                        id: UUID(),
                        therapistId: UUID(),
                        firstName: "New",
                        lastName: "Patient",
                        email: "new@example.com",
                        injuryType: "Post ACL Surgery"
                    )),
                    previousProgramsCount: 0,
                    lastCompletedDate: nil,
                    patientGoals: [],
                    onSelectPatient: {}
                )
                .previewDisplayName("First-Time Patient")
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
