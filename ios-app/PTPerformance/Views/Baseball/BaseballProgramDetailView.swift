//
//  BaseballProgramDetailView.swift
//  PTPerformance
//
//  Detailed program view showing overview, phases, equipment, and expected outcomes.
//  Includes "Start Program" button for enrollment.
//

import SwiftUI

struct BaseballProgramDetailView: View {
    let program: BaseballProgram

    @Environment(\.dismiss) private var dismiss
    @State private var isEnrolling: Bool = false
    @State private var showEnrollmentSuccess: Bool = false
    @State private var errorMessage: String?
    @State private var realPhases: [BaseballProgramPhaseDetail] = []
    @State private var isLoadingPhases: Bool = true

    private let programLibraryService = ProgramLibraryService()

    // MARK: - Baseball Theme Colors

    private let baseballNavy = Color(red: 0.07, green: 0.14, blue: 0.28)
    private let baseballRed = Color(red: 0.80, green: 0.16, blue: 0.22)

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section
                    headerSection

                    // Quick Stats
                    quickStatsSection

                    // Program Overview
                    overviewSection

                    // Phase Breakdown
                    phaseBreakdownSection

                    // Equipment Needed
                    equipmentSection

                    // Expected Outcomes
                    outcomesSection

                    // Who This Is For
                    whoIsThisForSection
                }
                .padding()
            }
            .navigationTitle("Program Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                startProgramButton
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .alert("Program Started", isPresented: $showEnrollmentSuccess) {
                Button("Let's Go") {
                    dismiss()
                }
            } message: {
                Text("You've been enrolled in \(program.title). Head to your programs to get started!")
            }
            .task {
                await loadRealPhases()
            }
        }
    }

    // MARK: - Load Real Phases

    private func loadRealPhases() async {
        guard let programId = program.programId else {
            isLoadingPhases = false
            return
        }
        do {
            let phases = try await BaseballPackService.shared.fetchProgramPhases(programId: programId)
            await MainActor.run {
                self.realPhases = phases
                self.isLoadingPhases = false
            }
        } catch {
            DebugLogger.shared.error("BaseballProgramDetailView", "Failed to load phases: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoadingPhases = false
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Cover image
            ZStack {
                LinearGradient(
                    colors: [baseballNavy.opacity(0.9), baseballNavy],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack {
                    Image(systemName: program.categoryEnum.icon)
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.4))

                    Text(program.categoryEnum.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(height: 140)
            .cornerRadius(CornerRadius.lg)

            // Title and badges
            VStack(alignment: .leading, spacing: 12) {
                Text(program.title)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 8) {
                    // Category badge
                    HStack(spacing: 4) {
                        Image(systemName: program.categoryEnum.icon)
                            .font(.caption2)
                        Text(program.categoryEnum.rawValue)
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(program.categoryEnum.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(program.categoryEnum.color.opacity(0.15))
                    .cornerRadius(CornerRadius.sm)

                    // Position badge
                    if program.positionUIEnum != .all {
                        HStack(spacing: 4) {
                            Image(systemName: program.positionUIEnum.icon)
                                .font(.caption2)
                            Text(program.positionUIEnum.rawValue)
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(baseballNavy)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(baseballNavy.opacity(0.15))
                        .cornerRadius(CornerRadius.sm)
                    }

                    // Season badge
                    HStack(spacing: 4) {
                        Image(systemName: program.seasonUIEnum.icon)
                            .font(.caption2)
                        Text(program.seasonUIEnum.rawValue)
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(program.seasonUIEnum.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(program.seasonUIEnum.color.opacity(0.15))
                    .cornerRadius(CornerRadius.sm)
                }

                if program.featured {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text("Featured Program")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(baseballRed)
                }
            }
        }
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                value: program.formattedDuration,
                label: "Duration",
                icon: "calendar",
                color: .blue
            )

            StatCard(
                value: program.difficultyLevel.capitalized,
                label: "Difficulty",
                icon: "chart.bar.fill",
                color: program.difficultyColor
            )

            StatCard(
                value: "\(program.durationWeeks * 4)",
                label: "Sessions",
                icon: "figure.baseball",
                color: baseballNavy
            )
        }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Program Overview", icon: "doc.text.fill")

            Text(program.safeDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(extendedDescription(for: program))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Phase Breakdown Section

    private var phaseBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Phase Breakdown", icon: "list.number")

            if isLoadingPhases {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if !realPhases.isEmpty {
                // Show real phases from database
                VStack(spacing: 12) {
                    ForEach(realPhases) { phase in
                        RealPhaseRow(phase: phase)
                    }
                }
            } else {
                // Fallback to generated phases
                VStack(spacing: 12) {
                    ForEach(phases(for: program), id: \.name) { phase in
                        PhaseRow(phase: phase)
                    }
                }
            }
        }
    }

    // MARK: - Equipment Section

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Equipment Needed", icon: "wrench.and.screwdriver.fill")

            BaseballFlowLayout(spacing: 8) {
                ForEach(equipment(for: program), id: \.self) { item in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text(item)
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.sm)
                }
            }
        }
    }

    // MARK: - Outcomes Section

    private var outcomesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Expected Outcomes", icon: "target")

            VStack(alignment: .leading, spacing: 10) {
                ForEach(outcomes(for: program), id: \.self) { outcome in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(baseballRed)

                        Text(outcome)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    // MARK: - Who Is This For Section

    private var whoIsThisForSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Who Is This For?", icon: "person.fill.questionmark")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(targetAudience(for: program), id: \.self) { audience in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(baseballNavy)

                        Text(audience)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.bottom, 100) // Space for floating button
    }

    // MARK: - Start Program Button

    private var startProgramButton: some View {
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
                    } else {
                        Image(systemName: "play.circle.fill")
                        Text("Start Program")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [baseballNavy, baseballNavy.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.md)
            }
            .disabled(isEnrolling)
            .padding()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Actions

    private func enrollInProgram() async {
        isEnrolling = true

        guard let patientId = PTSupabaseClient.shared.userId else {
            await MainActor.run {
                errorMessage = "Please sign in to enroll in programs"
                isEnrolling = false
            }
            return
        }

        do {
            // Enroll using the program library service
            _ = try await programLibraryService.enrollInProgram(
                patientId: patientId,
                programLibraryId: program.id
            )

            await MainActor.run {
                showEnrollmentSuccess = true
                isEnrolling = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isEnrolling = false
            }
        }
    }

    // MARK: - Helper Data

    private func extendedDescription(for program: BaseballProgram) -> String {
        switch program.categoryEnum {
        case .velocity:
            return "This program uses progressive overload principles combined with targeted arm care to safely develop throwing velocity while minimizing injury risk."
        case .armCare:
            return "Built on evidence-based recovery protocols, this program keeps your arm healthy and ready to perform when it matters most."
        case .weightedBall:
            return "Weighted ball training is one of the most effective methods for developing arm strength and velocity when implemented correctly with proper progression."
        case .conditioning:
            return "Position-specific conditioning ensures you're ready for the demands of your role while building the athleticism needed for peak performance."
        case .recovery:
            return "Active recovery is essential for long-term arm health. This program balances rest with targeted movement to accelerate recovery."
        case .all:
            return "A comprehensive approach to baseball training that addresses all aspects of athletic development."
        }
    }

    private func phases(for program: BaseballProgram) -> [BaseballProgramPhase] {
        let weekCount = program.durationWeeks

        if weekCount <= 4 {
            return [
                BaseballProgramPhase(name: "Phase 1: Foundation", weeks: "Weeks 1-\(weekCount)", focus: "Building baseline strength and movement patterns")
            ]
        } else if weekCount <= 8 {
            let mid = weekCount / 2
            return [
                BaseballProgramPhase(name: "Phase 1: Foundation", weeks: "Weeks 1-\(mid)", focus: "Building baseline strength and movement patterns"),
                BaseballProgramPhase(name: "Phase 2: Development", weeks: "Weeks \(mid + 1)-\(weekCount)", focus: "Progressive loading and skill development")
            ]
        } else {
            let phase1End = weekCount / 3
            let phase2End = (weekCount * 2) / 3
            return [
                BaseballProgramPhase(name: "Phase 1: Foundation", weeks: "Weeks 1-\(phase1End)", focus: "Building baseline strength and movement patterns"),
                BaseballProgramPhase(name: "Phase 2: Development", weeks: "Weeks \(phase1End + 1)-\(phase2End)", focus: "Progressive loading and skill development"),
                BaseballProgramPhase(name: "Phase 3: Peak", weeks: "Weeks \(phase2End + 1)-\(weekCount)", focus: "Maximizing performance and maintaining gains")
            ]
        }
    }

    private func equipment(for program: BaseballProgram) -> [String] {
        var items: [String] = ["Baseballs"]

        switch program.categoryEnum {
        case .weightedBall:
            items.append(contentsOf: ["Weighted Balls (2-7 oz)", "Plyo Balls", "Throwing Target"])
        case .velocity:
            items.append(contentsOf: ["Weighted Balls (2-7 oz)", "Radar Gun (optional)", "Video Camera (optional)"])
        case .armCare:
            items.append(contentsOf: ["Resistance Bands", "Light Dumbbells (3-8 lbs)", "Foam Roller"])
        case .conditioning:
            items.append(contentsOf: ["Cones", "Agility Ladder", "Medicine Ball"])
        case .recovery:
            items.append(contentsOf: ["Foam Roller", "Lacrosse Ball", "Resistance Bands"])
        case .all:
            items.append(contentsOf: ["Resistance Bands", "Light Dumbbells"])
        }

        if program.positionUIEnum == .catcher {
            items.append("Catcher's Gear")
        }

        return items
    }

    private func outcomes(for program: BaseballProgram) -> [String] {
        switch program.categoryEnum {
        case .velocity:
            return [
                "Increased throwing velocity (2-5 mph typical)",
                "Improved arm speed and whip",
                "Better hip-to-shoulder separation",
                "Enhanced kinetic chain efficiency"
            ]
        case .armCare:
            return [
                "Reduced arm soreness and fatigue",
                "Improved recovery between throwing sessions",
                "Better arm health markers",
                "Decreased injury risk"
            ]
        case .weightedBall:
            return [
                "Increased arm strength",
                "Improved velocity potential",
                "Better connection in throwing motion",
                "Enhanced feel for different ball weights"
            ]
        case .conditioning:
            return [
                "Improved sport-specific conditioning",
                "Better endurance throughout games",
                "Enhanced explosiveness and power",
                "Position-specific athletic improvements"
            ]
        case .recovery:
            return [
                "Faster recovery between games",
                "Reduced muscle tension and soreness",
                "Improved mobility and flexibility",
                "Better preparation for next performance"
            ]
        case .all:
            return [
                "Improved overall athletic performance",
                "Better baseball-specific conditioning",
                "Enhanced throwing mechanics",
                "Reduced injury risk"
            ]
        }
    }

    private func targetAudience(for program: BaseballProgram) -> [String] {
        var audience: [String] = []

        switch program.difficultyLevel.lowercased() {
        case "beginner":
            audience.append("Athletes new to structured training programs")
            audience.append("Youth players (12+) with proper supervision")
        case "intermediate":
            audience.append("Athletes with at least 1 year of training experience")
            audience.append("High school and college-level players")
        case "advanced":
            audience.append("Experienced athletes with 2+ years of training")
            audience.append("College and professional-level players")
        default:
            break
        }

        if program.positionUIEnum != .all {
            audience.append("\(program.positionUIEnum.rawValue)s looking to improve position-specific skills")
        }

        audience.append("Athletes with no current arm injuries or pain")

        return audience
    }
}

// MARK: - Supporting Views

private struct SectionHeader: View {
    let title: String
    let icon: String

    private let baseballNavy = Color(red: 0.07, green: 0.14, blue: 0.28)

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(baseballNavy)

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

private struct BaseballProgramPhase: Hashable {
    let name: String
    let weeks: String
    let focus: String
}

private struct PhaseRow: View {
    let phase: BaseballProgramPhase

    private let baseballNavy = Color(red: 0.07, green: 0.14, blue: 0.28)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(phase.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(phase.weeks)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(phase.focus)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

/// Row for displaying real phases from database
private struct RealPhaseRow: View {
    let phase: BaseballProgramPhaseDetail

    private let baseballNavy = Color(red: 0.07, green: 0.14, blue: 0.28)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(phase.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                if let weeks = phase.durationWeeks, weeks > 0 {
                    Text("\(weeks) week\(weeks == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let goals = phase.goals, !goals.isEmpty {
                Text(goals)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            } else if let notes = phase.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Flow Layout

private struct BaseballFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: .unspecified
            )
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Preview
// Note: Preview requires a real BaseballProgram from the service
// #Preview {
//     BaseballProgramDetailView(program: <sample program>)
// }
