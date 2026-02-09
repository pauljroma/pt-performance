//
//  SessionDataImportView.swift
//  PTPerformance
//
//  Component for importing session data into SOAP Note Objective section.
//  Shows recent sessions with exercise logs and allows selective import.
//

import SwiftUI

/// View for selecting session data to import into SOAP note Objective section
struct SessionDataImportView: View {
    let patientId: String
    let onImport: (String) -> Void

    @StateObject private var viewModel = SessionDataImportViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSessionId: String?
    @State private var selectedExerciseIds: Set<String> = []
    @State private var showPreview = false

    // Import options
    @State private var includePainScores = true
    @State private var includeRPE = true
    @State private var includeVolume = true
    @State private var includeNotes = true

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.sessions.isEmpty {
                    emptyStateView
                } else {
                    sessionListContent
                }
            }
            .navigationTitle("Import Session Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel import")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        importSelectedData()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canImport)
                    .accessibilityLabel("Import selected session data")
                    .accessibilityHint(canImport ? "Imports selected exercises into Objective section" : "Select exercises to enable import")
                }
            }
            .task {
                await viewModel.loadSessions(patientId: patientId)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var canImport: Bool {
        selectedSessionId != nil && !selectedExerciseIds.isEmpty
    }

    private var selectedSession: SessionWithLogs? {
        guard let id = selectedSessionId else { return nil }
        return viewModel.sessions.first { $0.id == id }
    }

    private var selectedExercises: [ExerciseLogDetail] {
        guard let session = selectedSession else { return [] }
        return session.exerciseLogs.filter { selectedExerciseIds.contains($0.id) }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading sessions...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading patient sessions")
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text("No Recent Sessions")
                .font(.headline)

            Text("This patient has no completed sessions with exercise data to import.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No recent sessions available for import")
    }

    // MARK: - Session List Content

    private var sessionListContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Import Options Section
                importOptionsSection

                // Sessions Section
                sessionsSection

                // Preview Section (when exercises selected)
                if !selectedExercises.isEmpty {
                    previewSection
                }
            }
            .padding()
        }
    }

    // MARK: - Import Options Section

    private var importOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.blue)
                Text("Import Options")
                    .font(.headline)
            }

            VStack(spacing: 8) {
                ImportOptionToggle(
                    title: "Pain Scores",
                    icon: "waveform.path.ecg",
                    isOn: $includePainScores
                )

                ImportOptionToggle(
                    title: "RPE Values",
                    icon: "gauge.medium",
                    isOn: $includeRPE
                )

                ImportOptionToggle(
                    title: "Volume Metrics",
                    icon: "chart.bar.fill",
                    isOn: $includeVolume
                )

                ImportOptionToggle(
                    title: "Exercise Notes",
                    icon: "note.text",
                    isOn: $includeNotes
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Sessions Section

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(.green)
                Text("Recent Sessions")
                    .font(.headline)
            }

            ForEach(viewModel.sessions, id: \.id) { session in
                SessionSelectionCard(
                    session: session,
                    isSelected: selectedSessionId == session.id,
                    selectedExerciseIds: selectedSessionId == session.id ? $selectedExerciseIds : .constant([]),
                    onSessionTap: {
                        selectSession(session)
                    },
                    onSelectAll: {
                        selectAllExercises(in: session)
                    },
                    onDeselectAll: {
                        selectedExerciseIds.removeAll()
                    }
                )
            }
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "eye")
                    .foregroundColor(.purple)
                Text("Preview")
                    .font(.headline)

                Spacer()

                Text("\(selectedExercises.count) exercises selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(generatePreviewText())
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preview of import text with \(selectedExercises.count) exercises")
    }

    // MARK: - Actions

    private func selectSession(_ session: SessionWithLogs) {
        HapticService.selection()

        if selectedSessionId == session.id {
            // Toggle off
            selectedSessionId = nil
            selectedExerciseIds.removeAll()
        } else {
            // Select new session and all its exercises
            selectedSessionId = session.id
            selectedExerciseIds = Set(session.exerciseLogs.map { $0.id })
        }
    }

    private func selectAllExercises(in session: SessionWithLogs) {
        HapticService.light()
        selectedExerciseIds = Set(session.exerciseLogs.map { $0.id })
    }

    private func generatePreviewText() -> String {
        guard let session = selectedSession else { return "" }

        let options = SessionToObjectiveFormatter.FormattingOptions(
            includeExercises: true,
            includePainScores: includePainScores,
            includeRPE: includeRPE,
            includeVolume: includeVolume,
            includeNotes: includeNotes,
            includeSummary: true
        )

        // Create a filtered session with only selected exercises
        let filteredLogs = session.exerciseLogs.filter { selectedExerciseIds.contains($0.id) }

        return SessionToObjectiveFormatter.formatSelectedExercises(filteredLogs, options: options)
    }

    private func importSelectedData() {
        HapticService.success()

        let formattedText = generatePreviewText()
        onImport(formattedText)
        dismiss()
    }
}

// MARK: - Session Selection Card

private struct SessionSelectionCard: View {
    let session: SessionWithLogs
    let isSelected: Bool
    @Binding var selectedExerciseIds: Set<String>
    let onSessionTap: () -> Void
    let onSelectAll: () -> Void
    let onDeselectAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Session Header
            Button(action: onSessionTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            if let sessionNumber = session.sessionNumber {
                                Text("Session #\(sessionNumber)")
                                    .font(.headline)
                            }

                            if session.completed {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }

                        Text(session.sessionDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Metrics badges
                    HStack(spacing: 8) {
                        if let duration = session.durationMinutes {
                            MetricBadge(value: "\(duration)m", icon: "clock")
                        }

                        if let pain = session.avgPainScore {
                            MetricBadge(
                                value: String(format: "%.1f", pain),
                                icon: "waveform.path.ecg",
                                color: painColor(pain)
                            )
                        }
                    }

                    Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Session \(session.sessionNumber ?? 0) on \(session.sessionDate.formatted(date: .abbreviated, time: .omitted))")
            .accessibilityHint(isSelected ? "Tap to collapse" : "Tap to expand and select exercises")

            // Exercise list (when expanded)
            if isSelected {
                Divider()

                // Select/Deselect all buttons
                HStack {
                    Button("Select All") {
                        onSelectAll()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)

                    Text("|")
                        .foregroundColor(.secondary)

                    Button("Deselect All") {
                        onDeselectAll()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)

                    Spacer()

                    Text("\(selectedExerciseIds.count)/\(session.exerciseLogs.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ForEach(session.exerciseLogs, id: \.id) { log in
                    ExerciseSelectionRow(
                        log: log,
                        isSelected: selectedExerciseIds.contains(log.id),
                        onToggle: {
                            toggleExercise(log.id)
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }

    private func toggleExercise(_ id: String) {
        HapticService.selection()
        if selectedExerciseIds.contains(id) {
            selectedExerciseIds.remove(id)
        } else {
            selectedExerciseIds.insert(id)
        }
    }

    private func painColor(_ pain: Double) -> Color {
        switch pain {
        case 0...3: return .green
        case 4...6: return .orange
        default: return .red
        }
    }
}

// MARK: - Exercise Selection Row

private struct ExerciseSelectionRow: View {
    let log: ExerciseLogDetail
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(log.exerciseName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text("\(log.actualSets)x\(log.repsDisplay)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if log.actualLoad != nil {
                            Text("@ \(log.loadDisplay)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("RPE \(log.rpe)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if log.painScore > 0 {
                            Text("Pain \(log.painScore)")
                                .font(.caption)
                                .foregroundColor(log.painScore > 5 ? .orange : .secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(log.exerciseName), \(log.actualSets) sets, RPE \(log.rpe)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Metric Badge

private struct MetricBadge: View {
    let value: String
    let icon: String
    var color: Color = .secondary

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption)
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
}

// MARK: - Import Option Toggle

private struct ImportOptionToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: .blue))
        .accessibilityLabel("\(title) toggle")
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

// MARK: - ViewModel

@MainActor
class SessionDataImportViewModel: ObservableObject {
    @Published var sessions: [SessionWithLogs] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadSessions(patientId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch recent completed sessions for this patient
            let response: [SessionResponse] = try await PTSupabaseClient.shared.client
                .from("sessions")
                .select("""
                    id,
                    sequence,
                    completed,
                    completed_at,
                    notes,
                    total_volume,
                    avg_rpe,
                    avg_pain,
                    duration_minutes,
                    phases!inner(
                        programs!inner(
                            patient_id
                        )
                    )
                """)
                .eq("phases.programs.patient_id", value: patientId)
                .eq("completed", value: true)
                .order("completed_at", ascending: false)
                .limit(10)
                .execute()
                .value

            // For each session, fetch exercise logs
            var sessionsWithLogs: [SessionWithLogs] = []

            for sessionResp in response {
                let exerciseLogs: [ExerciseLogDetail] = try await fetchExerciseLogs(sessionId: sessionResp.id)

                let session = SessionWithLogs(
                    id: sessionResp.id,
                    sessionNumber: sessionResp.sequence,
                    sessionDate: sessionResp.completedAt ?? Date(),
                    completed: sessionResp.completed,
                    notes: sessionResp.notes,
                    totalVolume: sessionResp.totalVolume,
                    avgRpe: sessionResp.avgRpe,
                    avgPainScore: sessionResp.avgPain,
                    durationMinutes: sessionResp.durationMinutes,
                    exerciseLogs: exerciseLogs
                )

                if !exerciseLogs.isEmpty {
                    sessionsWithLogs.append(session)
                }
            }

            sessions = sessionsWithLogs
        } catch {
            errorMessage = "Failed to load sessions: \(error.localizedDescription)"
            // Load sample data for development/preview
            sessions = [SessionWithLogs.sample]
        }

        isLoading = false
    }

    private func fetchExerciseLogs(sessionId: String) async throws -> [ExerciseLogDetail] {
        let response: [SessionImportExerciseLogResponse] = try await PTSupabaseClient.shared.client
            .from("exercise_logs")
            .select("""
                id,
                actual_sets,
                actual_reps,
                actual_load,
                load_unit,
                rpe,
                pain_score,
                notes,
                logged_at,
                exercise_template_id,
                video_url,
                session_exercises!inner(
                    session_id,
                    exercise_templates(
                        name
                    )
                )
            """)
            .eq("session_exercises.session_id", value: sessionId)
            .order("logged_at", ascending: true)
            .execute()
            .value

        return response.map { resp in
            ExerciseLogDetail(
                id: resp.id,
                exerciseName: resp.sessionExercises?.exerciseTemplates?.name ?? "Unknown Exercise",
                actualSets: resp.actualSets,
                actualReps: resp.actualReps,
                actualLoad: resp.actualLoad,
                loadUnit: resp.loadUnit,
                rpe: resp.rpe,
                painScore: resp.painScore,
                notes: resp.notes,
                loggedAt: resp.loggedAt,
                exerciseTemplateId: resp.exerciseTemplateId,
                videoUrl: resp.videoUrl
            )
        }
    }
}

// MARK: - Response Models

private struct SessionResponse: Codable {
    let id: String
    let sequence: Int?
    let completed: Bool
    let completedAt: Date?
    let notes: String?
    let totalVolume: Double?
    let avgRpe: Double?
    let avgPain: Double?
    let durationMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case id, sequence, completed, notes
        case completedAt = "completed_at"
        case totalVolume = "total_volume"
        case avgRpe = "avg_rpe"
        case avgPain = "avg_pain"
        case durationMinutes = "duration_minutes"
    }
}

private struct SessionImportExerciseLogResponse: Codable {
    let id: String
    let actualSets: Int
    let actualReps: [Int]
    let actualLoad: Double?
    let loadUnit: String?
    let rpe: Int
    let painScore: Int
    let notes: String?
    let loggedAt: Date
    let exerciseTemplateId: String?
    let videoUrl: String?
    let sessionExercises: SessionExerciseJoin?

    enum CodingKeys: String, CodingKey {
        case id
        case actualSets = "actual_sets"
        case actualReps = "actual_reps"
        case actualLoad = "actual_load"
        case loadUnit = "load_unit"
        case rpe
        case painScore = "pain_score"
        case notes
        case loggedAt = "logged_at"
        case exerciseTemplateId = "exercise_template_id"
        case videoUrl = "video_url"
        case sessionExercises = "session_exercises"
    }
}

private struct SessionExerciseJoin: Codable {
    let sessionId: String?
    let exerciseTemplates: ExerciseTemplateJoin?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case exerciseTemplates = "exercise_templates"
    }
}

private struct ExerciseTemplateJoin: Codable {
    let name: String
}

// MARK: - Preview

#if DEBUG
struct SessionDataImportView_Previews: PreviewProvider {
    static var previews: some View {
        SessionDataImportView(patientId: "preview-patient") { text in
            print("Imported: \(text)")
        }
        .preferredColorScheme(.light)

        SessionDataImportView(patientId: "preview-patient") { text in
            print("Imported: \(text)")
        }
        .preferredColorScheme(.dark)
    }
}
#endif
