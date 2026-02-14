//
//  EditSessionView.swift
//  PTPerformance
//
//  Build 60: Edit session details and manage exercises (ACP-114)
//

import SwiftUI

struct EditSessionView: View {
    @ObservedObject var viewModel: ProgramEditorViewModel
    let session: Session
    let phaseName: String

    // Mutable state for editing (initialized from session)
    @State private var sessionName: String
    @State private var weekday: Int?
    @State private var sessionNotes: String

    @State private var exercises: [Exercise] = []
    @State private var isLoadingExercises = false
    @State private var exercisesError: String?
    @State private var isSaving = false
    @State private var showAddExercise = false
    @State private var availableExercises: [Exercise] = []

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProgramEditorViewModel, session: Session, phaseName: String) {
        self.viewModel = viewModel
        self.session = session
        self.phaseName = phaseName
        _sessionName = State(initialValue: session.name)
        _weekday = State(initialValue: session.weekday)
        _sessionNotes = State(initialValue: session.notes ?? "")
    }

    var body: some View {
        Form {
            Section("Session Details") {
                TextField("Session Name", text: $sessionName)
                    .textInputAutocapitalization(.words)

                Picker("Day of Week", selection: Binding(
                    get: { weekday ?? 0 },
                    set: { weekday = $0 > 0 ? $0 : nil }
                )) {
                    Text("Not Set").tag(0)
                    Text("Monday").tag(1)
                    Text("Tuesday").tag(2)
                    Text("Wednesday").tag(3)
                    Text("Thursday").tag(4)
                    Text("Friday").tag(5)
                    Text("Saturday").tag(6)
                    Text("Sunday").tag(7)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $sessionNotes)
                        .frame(minHeight: 80)
                }
            }

            Section("Phase") {
                LabeledContent("Phase", value: phaseName)
            }

            Section {
                if isLoadingExercises {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading exercises...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, Spacing.sm)
                        Spacer()
                    }
                } else if let error = exercisesError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                await loadExercises()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, Spacing.sm)
                } else if exercises.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "dumbbell")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No exercises in this session")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Tap 'Add Exercise' to get started")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, Spacing.lg)
                        Spacer()
                    }
                } else {
                    ForEach(exercises.sorted(by: { ($0.sequence ?? 0) < ($1.sequence ?? 0) })) { exercise in
                        NavigationLink {
                            ExerciseEditorView(
                                viewModel: viewModel,
                                exercise: exercise,
                                sessionId: session.id.uuidString
                            )
                        } label: {
                            ExerciseRowDetailView(exercise: exercise)
                        }
                    }
                    .onDelete(perform: deleteExercise)
                }

                Button {
                    showAddExercise = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Exercises (\(exercises.count))")
            }
        }
        .navigationTitle("Edit Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await saveSession()
                    }
                }
                .disabled(isSaving || sessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .task {
            await loadExercises()
            await loadAvailableExercises()
        }
        .sheet(isPresented: $showAddExercise) {
            ExercisePickerView(
                sessionId: session.id.uuidString,
                availableExercises: availableExercises,
                onExerciseAdded: {
                    Task {
                        await loadExercises()
                    }
                }
            )
        }
    }

    private func loadExercises() async {
        let logger = DebugLogger.shared
        isLoadingExercises = true
        exercisesError = nil
        defer { isLoadingExercises = false }

        do {
            logger.log("💪 Loading exercises for session: \(session.name)")

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let result = try await PTSupabaseClient.shared.client
                .from("session_exercises")
                .select("""
                    *,
                    exercise_templates (
                        id,
                        name,
                        category,
                        body_region,
                        video_url,
                        video_thumbnail_url,
                        video_duration,
                        form_cues
                    )
                """)
                .eq("session_id", value: session.id)
                .order("sequence")
                .execute()

            if result.data.isEmpty || String(data: result.data, encoding: .utf8) == "[]" {
                exercises = []
                logger.log("   No exercises found for this session")
            } else {
                exercises = try decoder.decode([Exercise].self, from: result.data)
                logger.log("✅ Loaded \(exercises.count) exercises", level: .success)
            }
        } catch {
            exercisesError = "Failed to load exercises: \(error.localizedDescription)"
            logger.log("❌ Failed to load exercises: \(error)", level: .error)
        }
    }

    private func loadAvailableExercises() async {
        let logger = DebugLogger.shared

        do {
            logger.log("📥 Loading available exercise templates")

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let result = try await PTSupabaseClient.shared.client
                .from("exercise_templates")
                .select()
                .order("name")
                .execute()

            let templates = try decoder.decode([ExerciseTemplateData].self, from: result.data)

            // Convert to Exercise format for picker
            availableExercises = templates.map { template in
                Exercise(
                    id: template.id,
                    session_id: UUID(),  // Placeholder for templates
                    exercise_template_id: template.id,
                    sequence: nil,
                    target_sets: 3,
                    target_reps: 10,
                    prescribed_sets: nil,
                    prescribed_reps: "10",
                    prescribed_load: nil,
                    load_unit: "lbs",
                    rest_period_seconds: 90,
                    notes: nil,
                    exercise_templates: Exercise.ExerciseTemplate(
                        id: template.id,
                        name: template.name,
                        category: template.category,
                        body_region: template.bodyRegion,
                        videoUrl: template.videoUrl,
                        videoThumbnailUrl: template.videoThumbnailUrl,
                        videoDuration: template.videoDuration,
                        formCues: template.formCues?.map { cue in
                            Exercise.ExerciseTemplate.FormCue(cue: cue.cue, timestamp: cue.timestamp)
                        },
                        techniqueCues: nil,
                        commonMistakes: nil,
                        safetyNotes: nil
                    )
                )
            }

            logger.log("✅ Loaded \(availableExercises.count) exercise templates", level: .success)
        } catch {
            logger.log("❌ Failed to load exercise templates: \(error)", level: .error)
        }
    }

    private func saveSession() async {
        let logger = DebugLogger.shared
        isSaving = true
        defer { isSaving = false }

        do {
            logger.log("💾 Saving session: \(sessionName)")

            let updateInput = UpdateSessionInput(
                name: sessionName.trimmingCharacters(in: .whitespacesAndNewlines),
                weekday: weekday,
                notes: sessionNotes.isEmpty ? nil : sessionNotes
            )

            try await PTSupabaseClient.shared.client
                .from("sessions")
                .update(updateInput)
                .eq("id", value: session.id)
                .execute()

            logger.log("✅ Session saved successfully", level: .success)
            dismiss()
        } catch {
            logger.log("❌ Failed to save session: \(error)", level: .error)
            exercisesError = "Failed to save session: \(error.localizedDescription)"
        }
    }

    private func deleteExercise(at offsets: IndexSet) {
        let logger = DebugLogger.shared

        for index in offsets {
            let exercise = exercises[index]
            logger.log("🗑️ Deleting exercise: \(exercise.exercise_name ?? "Unknown")")

            Task {
                do {
                    try await PTSupabaseClient.shared.client
                        .from("session_exercises")
                        .delete()
                        .eq("id", value: exercise.id)
                        .execute()

                    logger.log("✅ Exercise deleted successfully", level: .success)

                    _ = await MainActor.run {
                        exercises.remove(at: index)
                    }
                } catch {
                    logger.log("❌ Failed to delete exercise: \(error)", level: .error)
                    await MainActor.run {
                        exercisesError = "Failed to delete exercise: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

struct ExerciseRowDetailView: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(exercise.exercise_name ?? "Unknown Exercise")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if exercise.exercise_templates?.hasVideo == true {
                    Image(systemName: "play.circle.fill")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }

            HStack(spacing: 12) {
                Label("\(exercise.sets) sets", systemImage: "repeat")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let reps = exercise.prescribed_reps {
                    Text("•").font(.caption).foregroundColor(.secondary)
                    Label("\(reps) reps", systemImage: "number")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let load = exercise.prescribed_load, let unit = exercise.load_unit {
                    Text("•").font(.caption).foregroundColor(.secondary)
                    Label("\(Int(load)) \(unit)", systemImage: "scalemass")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

struct UpdateSessionInput: Codable {
    let name: String
    let weekday: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case name
        case weekday
        case notes
    }
}

#Preview {
    NavigationStack {
        EditSessionView(
            viewModel: ProgramEditorViewModel(
                patientId: UUID(),
                exerciseId: nil
            ),
            session: Session(
                id: UUID(),
                phase_id: UUID(),
                name: "Day 1: Upper Body",
                sequence: 1,
                weekday: 1,
                notes: "Focus on controlled tempo",
                created_at: Date(),
                completed: false,
                started_at: nil, // BUILD 123
                completed_at: nil,
                total_volume: nil,
                avg_rpe: nil,
                avg_pain: nil,
                duration_minutes: nil
            ),
            phaseName: "Foundation Phase"
        )
    }
}
