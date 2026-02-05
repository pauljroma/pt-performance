//
//  EnrolledProgramsSection.swift
//  PTPerformance
//
//  Horizontal scrolling section showing enrolled programs on the Today tab
//

import SwiftUI

// MARK: - Enrolled Programs Section

struct EnrolledProgramsSection: View {
    @StateObject private var viewModel = EnrolledProgramsViewModel()
    @State private var selectedEnrollment: EnrollmentWithProgram?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text(LocalizedStrings.SectionHeaders.myPrograms)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if viewModel.activeEnrollmentCount > 0 {
                    Text("\(viewModel.activeEnrollmentCount) \(LocalizedStrings.Programs.active)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            // Content
            if viewModel.isLoading {
                loadingView
            } else if viewModel.enrolledPrograms.isEmpty {
                // Don't show anything if no programs - this section hides itself
                EmptyView()
            } else {
                programsScrollView
            }
        }
        .sheet(item: $selectedEnrollment) { enrollment in
            EnrolledProgramDetailSheet(enrollment: enrollment, viewModel: viewModel)
        }
        .task {
            await viewModel.loadEnrolledPrograms()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Text(LocalizedStrings.LoadingStates.loadingPrograms)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 20)
    }

    // MARK: - Programs Scroll View

    private var programsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.enrolledPrograms) { enrollment in
                    EnrolledProgramCard(
                        enrollment: enrollment,
                        currentWeek: viewModel.currentWeek(for: enrollment),
                        progressPercentage: viewModel.progressPercentage(for: enrollment),
                        daysRemainingDisplay: viewModel.daysRemainingDisplay(for: enrollment)
                    )
                    .id(enrollment.id)
                    .onTapGesture {
                        HapticFeedback.light()
                        selectedEnrollment = enrollment
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Enrolled Program Card

struct EnrolledProgramCard: View {
    let enrollment: EnrollmentWithProgram
    let currentWeek: Int
    let progressPercentage: Int
    let daysRemainingDisplay: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Category Badge
            HStack {
                ProgramCategoryBadge(category: enrollment.program.category)
                Spacer()
            }

            // Program Title
            Text(enrollment.program.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .foregroundColor(.primary)

            // Current Week
            Text("Week \(currentWeek)")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer(minLength: 4)

            // Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.tertiarySystemGroupedBackground))
                            .frame(height: 8)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressColor)
                            .frame(width: geometry.size.width * CGFloat(progressPercentage) / 100, height: 8)
                    }
                }
                .frame(height: 8)

                // Progress label
                HStack {
                    Text("\(progressPercentage)%")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(progressColor)

                    Spacer()

                    Text(daysRemainingDisplay)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .frame(width: 160, height: 150)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .adaptiveShadow(Shadow.subtle)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(enrollment.program.title), Week \(currentWeek), \(progressPercentage) percent complete, \(daysRemainingDisplay)")
        .accessibilityHint("Tap to view program details")
    }

    private var progressColor: Color {
        if progressPercentage >= 75 {
            return .green
        } else if progressPercentage >= 50 {
            return .blue
        } else if progressPercentage >= 25 {
            return .orange
        } else {
            return .purple
        }
    }
}

// MARK: - Enrolled Program Detail Sheet

struct EnrolledProgramDetailSheet: View {
    let enrollment: EnrollmentWithProgram
    @ObservedObject var viewModel: EnrolledProgramsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showLeaveConfirmation = false
    @State private var isProcessing = false

    /// Convenience initializer for contexts without a shared viewModel
    init(enrollment: EnrollmentWithProgram) {
        self.enrollment = enrollment
        self._viewModel = ObservedObject(wrappedValue: EnrolledProgramsViewModel())
    }

    /// Initializer with shared viewModel for proper refresh after unenroll
    init(enrollment: EnrollmentWithProgram, viewModel: EnrolledProgramsViewModel) {
        self.enrollment = enrollment
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection

                    // Workout Schedule (NEW - Primary action)
                    workoutScheduleSection

                    // Progress Section
                    progressSection

                    // Program Details
                    detailsSection

                    // Equipment Section
                    if !enrollment.program.equipment.isEmpty {
                        equipmentSection
                    }

                    // Leave Program Section
                    leaveProgramSection
                }
                .padding()
            }
            .navigationTitle(LocalizedStrings.Programs.programDetails)
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
            .confirmationDialog(
                "Leave Program",
                isPresented: $showLeaveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Leave Program", role: .destructive) {
                    Task {
                        isProcessing = true
                        let success = await viewModel.disenrollFromProgram(enrollment)
                        isProcessing = false
                        if success {
                            HapticFeedback.success()
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to leave \"\(enrollment.program.title)\"? Your progress will be saved and you can re-enroll later.")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(enrollment.program.title)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 8) {
                ProgramCategoryBadge(category: enrollment.program.category)
                ProgramDifficultyBadge(difficulty: enrollment.program.difficultyLevel)

                // Enrollment status badge
                HStack(spacing: 4) {
                    Image(systemName: enrollment.enrollment.enrollmentStatus.icon)
                        .font(.caption2)
                    Text(enrollment.enrollment.enrollmentStatus.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(enrollment.enrollment.enrollmentStatus.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(enrollment.enrollment.enrollmentStatus.color.opacity(0.15))
                .cornerRadius(6)
            }

            if let author = enrollment.program.author {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                    Text("by \(author)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStrings.SectionHeaders.yourProgress)
                .font(.headline)

            // Progress card
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Week \(viewModel.currentWeek(for: enrollment))")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("of \(enrollment.program.durationWeeks)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Circular progress
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 8)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.progressPercentage(for: enrollment)) / 100)
                            .stroke(progressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text("\(viewModel.progressPercentage(for: enrollment))%")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("done")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Time remaining
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text(viewModel.daysRemainingDisplay(for: enrollment))
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("Enrolled \(enrollment.enrollment.enrolledAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    // MARK: - Workout Schedule Section

    private var workoutScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStrings.SectionHeaders.workoutSchedule)
                .font(.headline)

            NavigationLink {
                ProgramWorkoutScheduleView(enrollment: enrollment)
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStrings.Programs.viewWeeklyWorkouts)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Text(LocalizedStrings.Programs.seeYourScheduleByWeek)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStrings.SectionHeaders.aboutThisProgram)
                .font(.headline)

            if let description = enrollment.program.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Stats row
            HStack(spacing: 16) {
                statItem(icon: "calendar", value: enrollment.program.formattedDuration, label: "Duration")
                statItem(icon: "chart.bar.fill", value: enrollment.program.difficultyLevel.capitalized, label: "Difficulty")
                statItem(icon: enrollment.program.categoryIcon, value: enrollment.program.category.capitalized, label: "Category")
            }
        }
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }

    // MARK: - Equipment Section

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStrings.SectionHeaders.equipmentRequired)
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(enrollment.program.equipment, id: \.self) { equipment in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)

                        Text(equipment)
                            .font(.caption)
                            .lineLimit(1)

                        Spacer()
                    }
                    .padding(8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(6)
                    .id(equipment)
                }
            }
        }
    }

    private var progressColor: Color {
        let progress = viewModel.progressPercentage(for: enrollment)
        if progress >= 75 {
            return .green
        } else if progress >= 50 {
            return .blue
        } else if progress >= 25 {
            return .orange
        } else {
            return .purple
        }
    }

    // MARK: - Leave Program Section

    private var leaveProgramSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Program Options")
                .font(.headline)

            Button {
                HapticFeedback.warning()
                showLeaveConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "door.left.hand.open")
                        .font(.title3)
                        .foregroundColor(.red)
                        .frame(width: 44, height: 44)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Leave Program")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)

                        Text("Stop participating in this program")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            .disabled(isProcessing)
            .accessibilityLabel("Leave program")
            .accessibilityHint("Double tap to stop participating in this program")
        }
        .padding(.top, Spacing.md)
    }

}

// MARK: - Extension for EnrollmentWithProgram Identifiable conformance

extension EnrollmentWithProgram: Equatable {
    static func == (lhs: EnrollmentWithProgram, rhs: EnrollmentWithProgram) -> Bool {
        lhs.id == rhs.id
    }
}

extension EnrollmentWithProgram: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview

#if DEBUG
struct EnrolledProgramsSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            EnrolledProgramsSection()
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
