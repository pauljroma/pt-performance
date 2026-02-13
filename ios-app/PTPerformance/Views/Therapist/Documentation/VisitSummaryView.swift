//
//  VisitSummaryView.swift
//  PTPerformance
//
//  Visit summary view displaying session details and clinical metrics
//

import SwiftUI

/// Displays a comprehensive summary of a patient visit/session
struct VisitSummaryView: View {
    let sessionId: UUID
    let patientId: String

    @StateObject private var viewModel = VisitSummaryViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showExportSheet = false
    @State private var showShareSheet = false
    @State private var exportedPDFURL: URL?

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading visit summary...")
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await viewModel.loadVisitSummary(sessionId: sessionId, patientId: patientId)
                    }
                }
            } else {
                summaryContent
            }
        }
        .navigationTitle("Visit Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        Task {
                            await exportToPDF()
                        }
                    } label: {
                        Label("Export PDF", systemImage: "arrow.down.doc")
                    }

                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedPDFURL {
                VSShareSheet(items: [url])
            }
        }
        .task {
            await viewModel.loadVisitSummary(sessionId: sessionId, patientId: patientId)
        }
    }

    // MARK: - Summary Content

    private var summaryContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                visitHeader

                // Metrics Overview
                metricsOverview

                // Exercises Performed
                exercisesSection

                // Pain & RPE Metrics
                painRPESection

                // Clinical Notes
                clinicalNotesSection

                // Export Button
                exportButton
            }
            .padding()
        }
    }

    // MARK: - Visit Header

    private var visitHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.patientName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(viewModel.visitDate.formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Session status
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isCompleted ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isCompleted ? "Completed" : "In Progress")
                        .font(.caption)
                        .foregroundColor(viewModel.isCompleted ? .green : .orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(viewModel.isCompleted ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                .cornerRadius(CornerRadius.md)
            }

            // Session type
            if let sessionType = viewModel.sessionType {
                HStack(spacing: 6) {
                    Image(systemName: sessionType.icon)
                        .foregroundColor(.blue)
                    Text(sessionType.displayName)
                        .font(.subheadline)
                }
            }

            // Duration
            HStack(spacing: 16) {
                Label("\(viewModel.durationMinutes) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if viewModel.exercisesCompleted > 0 {
                    Label("\(viewModel.exercisesCompleted) exercises", systemImage: "figure.strengthtraining.traditional")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Metrics Overview

    private var metricsOverview: some View {
        HStack(spacing: 0) {
            MetricBox(
                value: "\(viewModel.exercisesCompleted)",
                label: "Exercises",
                icon: "figure.strengthtraining.traditional",
                color: .blue
            )

            Divider()

            MetricBox(
                value: "\(viewModel.totalSets)",
                label: "Sets",
                icon: "repeat",
                color: .green
            )

            Divider()

            MetricBox(
                value: "\(viewModel.totalReps)",
                label: "Reps",
                icon: "arrow.triangle.2.circlepath",
                color: .orange
            )

            Divider()

            MetricBox(
                value: String(format: "%.0f", viewModel.averageRPE),
                label: "Avg RPE",
                icon: "gauge.with.dots.needle.33percent",
                color: .purple
            )
        }
        .frame(height: 90)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Exercises Section

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Exercises Performed", systemImage: "list.bullet.clipboard")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.exercises.count) total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.exercises.isEmpty {
                Text("No exercises recorded")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.exercises) { exercise in
                    ExerciseSummaryRow(exercise: exercise)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Pain & RPE Section

    private var painRPESection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Pain & Effort Metrics", systemImage: "waveform.path.ecg")
                .font(.headline)

            // Pain Level
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pain Level")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Text(String(format: "%.1f", viewModel.painLevel))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(painColor)
                        Text("/ 10")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                PainIndicator(level: viewModel.painLevel)
            }

            Divider()

            // RPE Distribution
            VStack(alignment: .leading, spacing: 8) {
                Text("RPE Distribution")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    ForEach(viewModel.rpeDistribution, id: \.rpe) { item in
                        VStack(spacing: 4) {
                            Text("\(item.count)")
                                .font(.headline)
                            Text("RPE \(item.rpe)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(rpeColor(item.rpe).opacity(0.2))
                        .cornerRadius(CornerRadius.sm)
                    }
                }
            }

            // Pain notes
            if let painNotes = viewModel.painNotes, !painNotes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Pain Notes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(painNotes)
                        .font(.subheadline)
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(CornerRadius.sm)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    private var painColor: Color {
        switch viewModel.painLevel {
        case 0..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        default: return .red
        }
    }

    private func rpeColor(_ rpe: Int) -> Color {
        switch rpe {
        case 1...4: return .green
        case 5...6: return .yellow
        case 7...8: return .orange
        default: return .red
        }
    }

    // MARK: - Clinical Notes Section

    private var clinicalNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Clinical Notes", systemImage: "note.text")
                .font(.headline)

            if viewModel.clinicalNotes.isEmpty {
                Text("No clinical notes for this visit")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.clinicalNotes) { note in
                    ClinicalNoteRow(note: note)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Export Button

    private var exportButton: some View {
        Button {
            Task {
                await exportToPDF()
            }
        } label: {
            HStack {
                Image(systemName: "arrow.down.doc.fill")
                Text("Export to PDF")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(CornerRadius.md)
        }
        .disabled(viewModel.isExporting)
        .overlay {
            if viewModel.isExporting {
                ProgressView()
                    .tint(.white)
            }
        }
    }

    // MARK: - Export Action

    private func exportToPDF() async {
        viewModel.isExporting = true

        do {
            let pdfURL = try await viewModel.generatePDF()
            exportedPDFURL = pdfURL
            showShareSheet = true
        } catch {
            viewModel.errorMessage = "Failed to export PDF: \(error.localizedDescription)"
        }

        viewModel.isExporting = false
    }
}

// MARK: - Metric Box

struct MetricBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Exercise Summary Row

struct ExerciseSummaryRow: View {
    let exercise: ExerciseSummary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Text("\(exercise.setsCompleted) sets")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(exercise.repsCompleted) reps")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let weight = exercise.weightUsed {
                        Text("\(Int(weight)) lbs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if let rpe = exercise.rpe {
                VStack(spacing: 2) {
                    Text("RPE")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(rpe)")
                        .font(.headline)
                        .foregroundColor(rpe <= 6 ? .green : rpe <= 8 ? .orange : .red)
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Pain Indicator

struct PainIndicator: View {
    let level: Double

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<10, id: \.self) { index in
                Rectangle()
                    .fill(index < Int(level) ? painColor(for: index) : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 20)
                    .cornerRadius(CornerRadius.xs)
            }
        }
    }

    private func painColor(for index: Int) -> Color {
        switch index {
        case 0..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        default: return .red
        }
    }
}

// MARK: - Clinical Note Row

struct ClinicalNoteRow: View {
    let note: ClinicalNote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: note.typeIcon)
                    .foregroundColor(note.typeColor)

                Text(note.type.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(note.typeColor)

                Spacer()

                Text(note.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(note.content)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Share Sheet

private struct VSShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Visit Summary ViewModel

@MainActor
class VisitSummaryViewModel: ObservableObject {
    @Published var patientName: String = ""
    @Published var visitDate: Date = Date()
    @Published var isCompleted: Bool = false
    @Published var sessionType: SessionType?
    @Published var durationMinutes: Int = 0
    @Published var exercisesCompleted: Int = 0
    @Published var totalSets: Int = 0
    @Published var totalReps: Int = 0
    @Published var averageRPE: Double = 0
    @Published var painLevel: Double = 0
    @Published var painNotes: String?
    @Published var exercises: [ExerciseSummary] = []
    @Published var rpeDistribution: [RPEDistributionItem] = []
    @Published var clinicalNotes: [ClinicalNote] = []

    @Published var isLoading: Bool = false
    @Published var isExporting: Bool = false
    @Published var errorMessage: String?

    private var sessionId: UUID?
    private var patientId: String?

    func loadVisitSummary(sessionId: UUID, patientId: String) async {
        self.sessionId = sessionId
        self.patientId = patientId
        isLoading = true
        errorMessage = nil

        do {
            // Fetch session details
            let session: SessionDetail = try await PTSupabaseClient.shared.client
                .from("sessions")
                .select("*, patients(*)")
                .eq("id", value: sessionId.uuidString)
                .single()
                .execute()
                .value

            patientName = session.patient?.fullName ?? "Unknown Patient"
            visitDate = session.scheduledDate ?? Date()
            isCompleted = session.status == "completed"
            sessionType = SessionType(rawValue: session.sessionType ?? "")
            durationMinutes = session.durationMinutes ?? 0

            // Fetch exercise logs
            let logs: [VSExerciseLog] = try await PTSupabaseClient.shared.client
                .from("exercise_logs")
                .select("*, exercises(*)")
                .eq("session_id", value: sessionId.uuidString)
                .execute()
                .value

            exercises = logs.map { log in
                ExerciseSummary(
                    id: log.id,
                    name: log.exercise?.name ?? "Unknown Exercise",
                    setsCompleted: log.setsCompleted ?? 0,
                    repsCompleted: log.repsCompleted ?? 0,
                    weightUsed: log.weightUsed,
                    rpe: log.rpe
                )
            }

            exercisesCompleted = exercises.count
            totalSets = exercises.reduce(0) { $0 + $1.setsCompleted }
            totalReps = exercises.reduce(0) { $0 + $1.repsCompleted }

            // Calculate RPE stats
            let rpeValues = exercises.compactMap { $0.rpe }
            if !rpeValues.isEmpty {
                averageRPE = Double(rpeValues.reduce(0, +)) / Double(rpeValues.count)
                calculateRPEDistribution(rpeValues)
            }

            // Fetch pain data
            if let painData = session.painLevel {
                painLevel = painData
            }
            painNotes = session.painNotes

            // Fetch clinical notes
            let notes: [SessionNote] = try await PTSupabaseClient.shared.client
                .from("session_notes")
                .select("*")
                .eq("session_id", value: sessionId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            clinicalNotes = notes.map { note in
                ClinicalNote(
                    id: note.id,
                    type: note.noteType,
                    content: note.noteText,
                    createdAt: note.createdAt
                )
            }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func calculateRPEDistribution(_ rpeValues: [Int]) {
        var distribution: [Int: Int] = [:]
        for rpe in rpeValues {
            distribution[rpe, default: 0] += 1
        }

        rpeDistribution = distribution.map { RPEDistributionItem(rpe: $0.key, count: $0.value) }
            .sorted { $0.rpe < $1.rpe }
    }

    func generatePDF() async throws -> URL {
        // Create PDF document
        let pdfMetaData = [
            kCGPDFContextCreator: "Modus",
            kCGPDFContextAuthor: "Modus App",
            kCGPDFContextTitle: "Visit Summary - \(patientName)"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            // Title
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
            let title = "Visit Summary"
            title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)

            // Patient info
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let bodyAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont]

            var yPosition: CGFloat = 90

            "Patient: \(patientName)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20

            "Date: \(visitDate.formatted(date: .long, time: .shortened))".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20

            "Duration: \(durationMinutes) minutes".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 40

            // Metrics
            let headerFont = UIFont.boldSystemFont(ofSize: 14)
            let headerAttributes: [NSAttributedString.Key: Any] = [.font: headerFont]

            "Summary Metrics".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: headerAttributes)
            yPosition += 25

            "Exercises Completed: \(exercisesCompleted)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20

            "Total Sets: \(totalSets)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20

            "Total Reps: \(totalReps)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20

            "Average RPE: \(String(format: "%.1f", averageRPE))".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20

            "Pain Level: \(String(format: "%.1f", painLevel))/10".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 40

            // Exercises
            "Exercises Performed".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: headerAttributes)
            yPosition += 25

            for exercise in exercises {
                let exerciseText = "\(exercise.name) - \(exercise.setsCompleted) sets x \(exercise.repsCompleted) reps"
                exerciseText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
                yPosition += 18

                if yPosition > 700 {
                    context.beginPage()
                    yPosition = 50
                }
            }
        }

        // Save to temp file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("VisitSummary_\(patientName)_\(Date().formatted(date: .numeric, time: .omitted)).pdf")

        try data.write(to: tempURL)
        return tempURL
    }
}

// MARK: - Supporting Models

struct ExerciseSummary: Identifiable {
    let id: UUID
    let name: String
    let setsCompleted: Int
    let repsCompleted: Int
    let weightUsed: Double?
    let rpe: Int?
}

struct RPEDistributionItem {
    let rpe: Int
    let count: Int
}

struct ClinicalNote: Identifiable {
    let id: UUID
    let type: String
    let content: String
    let createdAt: Date

    var typeIcon: String {
        switch type {
        case "assessment": return "stethoscope"
        case "progress": return "chart.line.uptrend.xyaxis"
        case "clinical": return "cross.case.fill"
        default: return "note.text"
        }
    }

    var typeColor: Color {
        switch type {
        case "assessment": return .blue
        case "progress": return .green
        case "clinical": return .red
        default: return .gray
        }
    }
}

struct SessionDetail: Codable {
    let id: UUID
    let scheduledDate: Date?
    let status: String?
    let sessionType: String?
    let durationMinutes: Int?
    let painLevel: Double?
    let painNotes: String?
    let patient: Patient?

    enum CodingKeys: String, CodingKey {
        case id
        case scheduledDate = "scheduled_date"
        case status
        case sessionType = "session_type"
        case durationMinutes = "duration_minutes"
        case painLevel = "pain_level"
        case painNotes = "pain_notes"
        case patient = "patients"
    }
}

private struct VSExerciseLog: Codable, Identifiable {
    let id: UUID
    let setsCompleted: Int?
    let repsCompleted: Int?
    let weightUsed: Double?
    let rpe: Int?
    let exercise: ExerciseInfo?

    enum CodingKeys: String, CodingKey {
        case id
        case setsCompleted = "sets_completed"
        case repsCompleted = "reps_completed"
        case weightUsed = "weight_used"
        case rpe
        case exercise = "exercises"
    }
}

struct ExerciseInfo: Codable {
    let id: UUID
    let name: String
}

enum SessionType: String {
    case evaluation = "evaluation"
    case treatment = "treatment"
    case followUp = "follow_up"
    case discharge = "discharge"

    var displayName: String {
        switch self {
        case .evaluation: return "Evaluation"
        case .treatment: return "Treatment"
        case .followUp: return "Follow-Up"
        case .discharge: return "Discharge"
        }
    }

    var icon: String {
        switch self {
        case .evaluation: return "clipboard"
        case .treatment: return "figure.strengthtraining.traditional"
        case .followUp: return "arrow.triangle.2.circlepath"
        case .discharge: return "checkmark.circle"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct VisitSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            VisitSummaryView(sessionId: UUID(), patientId: "patient-1")
        }
        .preferredColorScheme(.light)

        NavigationStack {
            VisitSummaryView(sessionId: UUID(), patientId: "patient-1")
        }
        .preferredColorScheme(.dark)
    }
}
#endif
