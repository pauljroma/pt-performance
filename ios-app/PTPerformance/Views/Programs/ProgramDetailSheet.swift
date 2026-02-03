//
//  ProgramDetailSheet.swift
//  PTPerformance
//
//  Sheet showing full program details when a user taps a program card
//

import SwiftUI

struct ProgramDetailSheet: View {
    let program: ProgramLibrary
    @Environment(\.dismiss) private var dismiss
    @State private var isEnrolling = false
    @State private var showEnrollSuccess = false
    @State private var enrollmentError: String?

    // Phase preview state
    @State private var phases: [ProgramPhasePreview] = []
    @State private var isLoadingPhases = false
    @State private var phasesError: String?

    // Access current user for enrollment
    @ObservedObject private var supabase = PTSupabaseClient.shared

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: - Cover Image
                    ProgramCoverImage(
                        url: program.coverImageUrl,
                        size: CGSize(width: CGFloat.infinity, height: 200),
                        cornerRadius: 0
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .accessibilityHidden(true)

                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(program.title)
                            .font(.title)
                            .fontWeight(.bold)

                        if let author = program.author {
                            HStack(spacing: 4) {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.secondary)
                                Text("by \(author)")
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Info Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Duration
                            InfoPill(
                                icon: "calendar",
                                text: program.formattedDuration,
                                color: .blue
                            )

                            // Difficulty
                            InfoPill(
                                icon: "chart.bar.fill",
                                text: program.difficultyLevel.capitalized,
                                color: program.difficultyColor
                            )

                            // Equipment count
                            InfoPill(
                                icon: "dumbbell.fill",
                                text: "\(program.equipmentRequired.count) equipment",
                                color: .purple
                            )

                            // Category
                            InfoPill(
                                icon: program.categoryIcon,
                                text: program.category.capitalized,
                                color: .orange
                            )
                        }
                        .padding(.horizontal)
                    }

                    Divider()
                        .padding(.horizontal)

                    // MARK: - Description
                    if let description = program.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About This Program")
                                .font(.headline)

                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }

                    // MARK: - Equipment List
                    if !program.equipmentRequired.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Equipment Required")
                                .font(.headline)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 10) {
                                ForEach(program.equipmentRequired, id: \.self) { equipment in
                                    EquipmentItem(name: equipment)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // MARK: - Program Phases Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Program Phases")
                            .font(.headline)

                        if isLoadingPhases {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        } else if let error = phasesError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        } else if phases.isEmpty {
                            Text("Phase information will be available once you start the program.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(phases) { phase in
                                    PhasePreviewCard(phase: phase)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Tags
                    if !program.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.headline)

                            DetailFlowLayout(spacing: 8) {
                                ForEach(program.tags, id: \.self) { tag in
                                    ProgramTagChip(text: tag)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Bottom spacing for button
                    Spacer(minLength: 80)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // MARK: - Start Program Button
                VStack(spacing: 0) {
                    Divider()

                    Button {
                        Task {
                            await enrollInProgram()
                        }
                    } label: {
                        HStack {
                            if isEnrolling {
                                ProgressView()
                                    .tint(.white)
                                    .accessibilityHidden(true)
                            } else {
                                Image(systemName: "play.circle.fill")
                                    .accessibilityHidden(true)
                                Text("Start This Program")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(isEnrolling)
                    .accessibilityLabel(isEnrolling ? "Enrolling in program" : "Start \(program.title)")
                    .accessibilityHint(isEnrolling ? "Please wait" : "Enrolls you in this program and adds workouts to your schedule")
                    .padding()
                    .background(.ultraThinMaterial)
                }
            }
            .alert("Enrolled!", isPresented: $showEnrollSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("You have successfully enrolled in \(program.title). Check your Today tab to get started!")
            }
            .alert("Enrollment Error", isPresented: Binding(
                get: { enrollmentError != nil },
                set: { if !$0 { enrollmentError = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = enrollmentError {
                    Text(error)
                }
            }
            .task {
                await loadPhases()
            }
        }
    }

    // MARK: - Load Phases

    private func loadPhases() async {
        isLoadingPhases = true
        phasesError = nil

        do {
            let service = ProgramLibraryService()
            let fetchedPhases = try await service.fetchPhasePreview(programId: program.programId)

            await MainActor.run {
                phases = fetchedPhases
                isLoadingPhases = false
            }
        } catch {
            await MainActor.run {
                phasesError = "Unable to load phase information"
                isLoadingPhases = false
            }
        }
    }

    // MARK: - Enrollment Action

    private func enrollInProgram() async {
        guard let patientId = supabase.userId else {
            enrollmentError = "Unable to enroll: User not found"
            return
        }

        isEnrolling = true

        do {
            let service = ProgramLibraryService()
            _ = try await service.enrollInProgram(patientId: patientId, programLibraryId: program.id)

            await MainActor.run {
                isEnrolling = false
                showEnrollSuccess = true
            }
        } catch {
            await MainActor.run {
                isEnrolling = false
                enrollmentError = "Failed to enroll: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Supporting Views

private struct InfoPill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .accessibilityHidden(true)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

private struct EquipmentItem: View {
    let name: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
                .accessibilityHidden(true)

            Text(name)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), required equipment")
    }
}

private struct ProgramTagChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray5))
            .cornerRadius(16)
    }
}

private struct PhasePreviewCard: View {
    let phase: ProgramPhasePreview

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Phase number badge
                Text("\(phase.phaseNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(phaseColor)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(phase.phaseName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(phase.formattedWeekRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Workout count
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(phase.workoutCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    Text(phase.workoutCount == 1 ? "workout" : "workouts")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Phase description if available
            if let description = phase.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Phase \(phase.phaseNumber): \(phase.phaseName), \(phase.formattedWeekRange), \(phase.workoutCount) \(phase.workoutCount == 1 ? "workout" : "workouts")")
    }

    /// Color based on phase number for visual variety
    private var phaseColor: Color {
        let colors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal]
        return colors[(phase.phaseNumber - 1) % colors.count]
    }
}

// MARK: - Flow Layout for Tags

private struct DetailFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        let maxAllowedWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxAllowedWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))

            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX - spacing)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

// MARK: - Preview

#if DEBUG
struct ProgramDetailSheet_Previews: PreviewProvider {
    static var previews: some View {
        ProgramDetailSheet(program: ProgramLibrary(
            id: UUID(),
            title: "12-Week Strength Builder",
            description: "A comprehensive strength training program designed to build muscle and increase overall strength. Perfect for intermediate lifters looking to take their training to the next level.",
            category: "strength",
            durationWeeks: 12,
            difficultyLevel: "intermediate",
            equipmentRequired: ["Barbell", "Dumbbells", "Pull-up Bar", "Bench"],
            coverImageUrl: nil,
            programId: UUID(),
            isFeatured: true,
            tags: ["Strength", "Muscle Building", "Intermediate", "Full Body"],
            author: "Coach Mike",
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
#endif
