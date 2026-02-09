//
//  PatientContextCard.swift
//  PTPerformance
//
//  Patient Context Card for displaying patient information in the program builder.
//  Shows patient avatar, name, injury type, previous programs, goal, and suggested program type.
//

import SwiftUI

// MARK: - Patient Context Card

/// A card that displays patient information in the program builder.
/// Shows patient avatar (initials if no photo), name, injury/condition,
/// previous programs count, goal, and suggested program type.
struct PatientContextCard: View {
    @Binding var patient: Patient?
    let previousProgramsCount: Int
    let patientGoal: String?
    let onSelectPatient: () -> Void

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
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
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
                    Text(injuryType)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                    .foregroundColor(.accentColor)
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
                .frame(width: 48, height: 48)
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
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 48, height: 48)

            Text(patient.initials)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
        }
    }

    // MARK: - Info Section

    private func infoSection(patient: Patient) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Previous Programs
            infoRow(
                icon: "doc.text.fill",
                text: "\(previousProgramsCount) Previous Program\(previousProgramsCount == 1 ? "" : "s")"
            )

            // Goal
            if let goal = patientGoal {
                infoRow(
                    icon: "target",
                    text: "Goal: \(goal)"
                )
            }

            // Suggested program type
            let suggestedType = suggestProgramType(for: patient)
            infoRow(
                icon: "lightbulb.fill",
                text: "Suggested: \(suggestedType.displayName) Program",
                iconColor: .yellow
            )
        }
    }

    private func infoRow(icon: String, text: String, iconColor: Color = .secondary) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(iconColor)
                .frame(width: 16)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
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
                        .frame(width: 48, height: 48)

                    Image(systemName: "person.fill.badge.plus")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Select Patient")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Choose a patient for this program")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
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

// MARK: - Preview Provider

#if DEBUG
struct PatientContextCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // With patient selected
            PatientContextCard(
                patient: .constant(Patient.samplePatients[0]),
                previousProgramsCount: 3,
                patientGoal: "Return to basketball",
                onSelectPatient: {}
            )
            .padding()
            .previewDisplayName("With Patient")

            // No patient selected
            PatientContextCard(
                patient: .constant(nil),
                previousProgramsCount: 0,
                patientGoal: nil,
                onSelectPatient: {}
            )
            .padding()
            .previewDisplayName("No Patient")

            // Patient without injury
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
                previousProgramsCount: 1,
                patientGoal: "Improve serve speed",
                onSelectPatient: {}
            )
            .padding()
            .previewDisplayName("No Injury (Performance)")
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
