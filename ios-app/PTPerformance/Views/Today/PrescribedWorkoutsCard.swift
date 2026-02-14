//
//  PrescribedWorkoutsCard.swift
//  PTPerformance
//
//  Card component displaying pending workout prescriptions from therapist
//

import SwiftUI

/// Card component showing pending prescriptions assigned by therapist
/// Displays prescription details with priority badges and start workout action
struct PrescribedWorkoutsCard: View {
    let prescriptions: [WorkoutPrescription]
    let isLoading: Bool
    let onStartPrescription: (WorkoutPrescription) -> Void
    let onViewAll: () -> Void

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Label("From Your Therapist", systemImage: "person.badge.clock")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                if prescriptions.count > 1 {
                    Button("View All") {
                        onViewAll()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .accessibilityLabel("View all prescribed workouts")
                }
            }

            if isLoading {
                loadingView
            } else if prescriptions.isEmpty {
                noPrescriptionsView
            } else {
                // Show first prescription prominently, others as compact list
                if let firstPrescription = prescriptions.first {
                    prescriptionCard(firstPrescription, isFirst: true)
                }

                // Show remaining prescriptions as compact items
                if prescriptions.count > 1 {
                    ForEach(prescriptions.dropFirst().prefix(2)) { prescription in
                        prescriptionCard(prescription, isFirst: false)
                    }

                    if prescriptions.count > 3 {
                        Text("+ \(prescriptions.count - 3) more prescriptions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Loading View

    @ViewBuilder
    private var loadingView: some View {
        ProgressView("Loading prescriptions...")
            .frame(maxWidth: .infinity)
            .padding()
    }

    // MARK: - No Prescriptions View

    @ViewBuilder
    private var noPrescriptionsView: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.title2)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("All caught up!")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("No pending workouts from your therapist")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Prescription Card

    @ViewBuilder
    private func prescriptionCard(_ prescription: WorkoutPrescription, isFirst: Bool) -> some View {
        VStack(alignment: .leading, spacing: isFirst ? 12 : 8) {
            // Header with name and priority badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prescription.name)
                        .font(isFirst ? .headline : .subheadline)
                        .fontWeight(.semibold)

                    if let dueDate = prescription.dueDate {
                        dueDateLabel(dueDate, isOverdue: prescription.isOverdue)
                    }
                }

                Spacer()

                priorityBadge(prescription.priority)
            }

            // Therapist instructions (only for first prescription)
            if isFirst, let instructions = prescription.instructions, !instructions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Instructions", systemImage: "quote.bubble")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(instructions)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(CornerRadius.sm)
                }
            }

            // Start Workout Button (prominent for first, compact for others)
            if isFirst {
                Button(action: {
                    HapticFeedback.medium()
                    onStartPrescription(prescription)
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                        Text("Start Workout")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.md)
                }
                .accessibilityLabel("Start prescribed workout: \(prescription.name)")
                .accessibilityHint("Begins the workout prescribed by your therapist")
            } else {
                Button(action: {
                    HapticFeedback.light()
                    onStartPrescription(prescription)
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.caption)
                        Text("Start")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.15))
                    .foregroundColor(.purple)
                    .cornerRadius(CornerRadius.sm)
                }
                .accessibilityLabel("Start workout: \(prescription.name)")
            }
        }
        .padding(isFirst ? 16 : 12)
        .background(isFirst ? Color.purple.opacity(0.05) : Color(.systemGray6))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Priority Badge

    @ViewBuilder
    private func priorityBadge(_ priority: PrescriptionPriority) -> some View {
        let color: Color = {
            switch priority {
            case .low: return .green
            case .medium: return .blue
            case .high: return .orange
            case .urgent: return .red
            }
        }()

        HStack(spacing: 4) {
            if priority == .urgent {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
            }
            Text(priority.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Due Date Label

    private func dueDateLabel(_ date: Date, isOverdue: Bool) -> some View {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        let isTomorrow = calendar.isDateInTomorrow(date)

        let text: String
        let color: Color

        if isOverdue {
            text = "Overdue"
            color = .red
        } else if isToday {
            text = "Due today"
            color = .orange
        } else if isTomorrow {
            text = "Due tomorrow"
            color = .blue
        } else {
            text = "Due \(Self.shortDateFormatter.string(from: date))"
            color = .secondary
        }

        return HStack(spacing: 4) {
            Image(systemName: isOverdue ? "exclamationmark.circle" : "calendar")
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .foregroundColor(color)
    }
}

// MARK: - Previews

#if DEBUG
struct PrescribedWorkoutsCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Loading state
            PrescribedWorkoutsCard(
                prescriptions: [],
                isLoading: true,
                onStartPrescription: { _ in },
                onViewAll: {}
            )

            // No prescriptions state
            PrescribedWorkoutsCard(
                prescriptions: [],
                isLoading: false,
                onStartPrescription: { _ in },
                onViewAll: {}
            )

            // With prescriptions
            PrescribedWorkoutsCard(
                prescriptions: [
                    WorkoutPrescription(
                        id: UUID(),
                        patientId: UUID(),
                        therapistId: UUID(),
                        templateId: UUID(),
                        templateType: "system",
                        name: "Upper Body Recovery",
                        instructions: "Focus on proper form. Take extra rest between sets if needed.",
                        dueDate: Date(),
                        priority: .high,
                        status: .pending,
                        manualSessionId: nil,
                        prescribedAt: Date(),
                        viewedAt: nil,
                        startedAt: nil,
                        completedAt: nil,
                        createdAt: Date()
                    ),
                    WorkoutPrescription(
                        id: UUID(),
                        patientId: UUID(),
                        therapistId: UUID(),
                        templateId: UUID(),
                        templateType: "system",
                        name: "Core Stability",
                        instructions: nil,
                        dueDate: Date().addingTimeInterval(86400),
                        priority: .medium,
                        status: .pending,
                        manualSessionId: nil,
                        prescribedAt: Date(),
                        viewedAt: nil,
                        startedAt: nil,
                        completedAt: nil,
                        createdAt: Date()
                    )
                ],
                isLoading: false,
                onStartPrescription: { _ in },
                onViewAll: {}
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
