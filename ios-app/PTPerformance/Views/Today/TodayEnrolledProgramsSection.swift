import SwiftUI

/// Section component displaying user's enrolled programs in a horizontal scrolling view
/// Used in the Today tab to show program progress at a glance
struct TodayEnrolledProgramsSection: View {
    let enrolledPrograms: [EnrollmentWithProgram]
    let activeEnrollmentCount: Int
    let isLoading: Bool
    let currentWeek: (EnrollmentWithProgram) -> Int
    let progressPercentage: (EnrollmentWithProgram) -> Int
    let daysRemainingDisplay: (EnrollmentWithProgram) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text("My Programs")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if activeEnrollmentCount > 0 {
                    Text("\(activeEnrollmentCount) active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Content
            if isLoading {
                loadingView
            } else {
                programCardsScrollView
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Loading View

    @ViewBuilder
    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading programs...")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 20)
    }

    // MARK: - Program Cards

    @ViewBuilder
    private var programCardsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(enrolledPrograms) { enrollment in
                    EnrolledProgramCardInline(
                        enrollment: enrollment,
                        currentWeek: currentWeek(enrollment),
                        progressPercentage: progressPercentage(enrollment),
                        daysRemainingDisplay: daysRemainingDisplay(enrollment)
                    )
                }
            }
        }
    }
}

// MARK: - Enrolled Program Card (Inline for Today tab)

/// Compact card for displaying enrolled programs in the Today tab horizontal scroll
struct EnrolledProgramCardInline: View {
    let enrollment: EnrollmentWithProgram
    let currentWeek: Int
    let progressPercentage: Int
    let daysRemainingDisplay: String

    @State private var showDetailSheet = false

    var body: some View {
        Button {
            HapticFeedback.light()
            showDetailSheet = true
        } label: {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(enrollment.program.title), Week \(currentWeek), \(progressPercentage) percent complete, \(daysRemainingDisplay)")
        .accessibilityHint("Tap to view program details")
        .contextMenu {
            contextMenuContent
        }
        .sheet(isPresented: $showDetailSheet) {
            ActiveProgramDetailView(enrollment: enrollment)
        }
    }

    // MARK: - Card Content

    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            progressBarSection
        }
        .padding(Spacing.sm)
        .frame(width: 160, height: 150)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Progress Bar

    @ViewBuilder
    private var progressBarSection: some View {
        VStack(alignment: .leading, spacing: 4) {
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

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuContent: some View {
        Button {
            HapticFeedback.light()
            showDetailSheet = true
        } label: {
            Label("View Details", systemImage: "info.circle")
        }

        Button {
            HapticFeedback.light()
            // Copy program summary
            let summary = "\(enrollment.program.title) - Week \(currentWeek) (\(progressPercentage)% complete)"
            UIPasteboard.general.string = summary
        } label: {
            Label("Copy Progress", systemImage: "doc.on.doc")
        }

        Divider()

        Button {
            HapticFeedback.light()
            // Share program progress
            let summary = "Working on \(enrollment.program.title) - Week \(currentWeek), \(progressPercentage)% complete!"
            UIPasteboard.general.string = summary
        } label: {
            Label("Share Progress", systemImage: "square.and.arrow.up")
        }
    }

    // MARK: - Helper

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

#if DEBUG
struct TodayEnrolledProgramsSection_Previews: PreviewProvider {
    static var previews: some View {
        TodayEnrolledProgramsSection(
            enrolledPrograms: [],
            activeEnrollmentCount: 2,
            isLoading: false,
            currentWeek: { _ in 3 },
            progressPercentage: { _ in 45 },
            daysRemainingDisplay: { _ in "12 days left" }
        )
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
