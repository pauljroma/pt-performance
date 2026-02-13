//
//  ManualWorkoutCreatorView.swift
//  PTPerformance
//
//  View for creating a new manual workout by adding exercises organized into blocks.
//

import SwiftUI

// MARK: - ViewModel

@MainActor
class ManualWorkoutCreatorViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var workoutName: String = ""
    @Published var blocks: [WorkoutBlockType: [CreatorExercise]] = [:]
    @Published var expandedBlocks: Set<WorkoutBlockType> = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var isStartingWorkout = false
    @Published var errorMessage: String?
    @Published var showingSaveTemplateSheet = false
    @Published var showingExercisePicker = false
    @Published var selectedBlockType: WorkoutBlockType?
    @Published var createdSession: ManualSession?

    // Template save fields
    @Published var templateName: String = ""
    @Published var templateDescription: String = ""

    private let service: ManualWorkoutService
    private let patientId: UUID

    // MARK: - Initialization

    init(patientId: UUID, service: ManualWorkoutService = ManualWorkoutService()) {
        self.patientId = patientId
        self.service = service

        // Initialize empty blocks for all block types
        for blockType in WorkoutBlockType.allCases {
            blocks[blockType] = []
        }
    }

    // MARK: - Computed Properties

    var totalExerciseCount: Int {
        blocks.values.reduce(0) { $0 + $1.count }
    }

    var hasExercises: Bool {
        totalExerciseCount > 0
    }

    var canStartWorkout: Bool {
        hasExercises && !workoutName.isEmpty
    }

    var canSaveAsTemplate: Bool {
        hasExercises && !templateName.isEmpty
    }

    var blocksWithExercises: [WorkoutBlockType] {
        WorkoutBlockType.allCases.filter { !(blocks[$0]?.isEmpty ?? true) }
    }

    // MARK: - Block Management

    func toggleBlockExpansion(_ blockType: WorkoutBlockType) {
        if expandedBlocks.contains(blockType) {
            expandedBlocks.remove(blockType)
        } else {
            expandedBlocks.insert(blockType)
        }
    }

    func isBlockExpanded(_ blockType: WorkoutBlockType) -> Bool {
        expandedBlocks.contains(blockType)
    }

    func exerciseCount(for blockType: WorkoutBlockType) -> Int {
        blocks[blockType]?.count ?? 0
    }

    // MARK: - Exercise Management

    func addExercise(to blockType: WorkoutBlockType) {
        selectedBlockType = blockType
        showingExercisePicker = true
    }

    func addExercise(_ exercise: CreatorExercise, to blockType: WorkoutBlockType) {
        var exerciseWithSequence = exercise
        exerciseWithSequence.sequence = (blocks[blockType]?.count ?? 0) + 1
        blocks[blockType, default: []].append(exerciseWithSequence)

        // Auto-expand the block when adding exercise
        expandedBlocks.insert(blockType)
    }

    func removeExercise(at offsets: IndexSet, from blockType: WorkoutBlockType) {
        blocks[blockType]?.remove(atOffsets: offsets)
        resequenceExercises(in: blockType)
    }

    func moveExercise(from source: IndexSet, to destination: Int, in blockType: WorkoutBlockType) {
        blocks[blockType]?.move(fromOffsets: source, toOffset: destination)
        resequenceExercises(in: blockType)
    }

    private func resequenceExercises(in blockType: WorkoutBlockType) {
        guard var exercises = blocks[blockType] else { return }
        for index in exercises.indices {
            exercises[index].sequence = index + 1
        }
        blocks[blockType] = exercises
    }

    // MARK: - Convert to WorkoutBlocks

    func buildWorkoutBlocks() -> WorkoutBlocks {
        var result: WorkoutBlocks = []
        var sequence = 1

        for blockType in WorkoutBlockType.allCases {
            guard let exercises = blocks[blockType], !exercises.isEmpty else { continue }

            let blockExercises = exercises.enumerated().map { _, exercise in
                BlockExercise(
                    id: UUID(),
                    name: exercise.name,
                    sets: exercise.sets,
                    reps: exercise.reps,
                    duration: nil,
                    rpe: nil,
                    notes: exercise.notes
                )
            }

            let block = WorkoutBlock(
                id: UUID(),
                name: blockType.displayName,
                blockType: blockType,
                sequence: sequence,
                exercises: blockExercises
            )

            result.append(block)
            sequence += 1
        }

        return result
    }

    // MARK: - Actions

    func startWorkout() async {
        guard canStartWorkout else { return }

        isStartingWorkout = true
        errorMessage = nil

        do {
            let session = try await service.createManualSession(
                name: workoutName,
                patientId: patientId,
                sourceTemplateId: nil,
                sourceTemplateType: nil,
                sessionSource: .chosen
            )

            // Add exercises to the session
            for blockType in WorkoutBlockType.allCases {
                guard let exercises = blocks[blockType] else { continue }

                for (index, exercise) in exercises.enumerated() {
                    let input = AddManualSessionExerciseInput(
                        manualSessionId: session.id,
                        exerciseTemplateId: exercise.exerciseTemplateId,
                        exerciseName: exercise.name,
                        blockName: blockType.displayName,
                        sequence: index,
                        targetSets: exercise.sets,
                        targetReps: exercise.reps,
                        targetLoad: exercise.load,
                        loadUnit: exercise.loadUnit,
                        restPeriodSeconds: exercise.restSeconds,
                        notes: exercise.notes
                    )
                    _ = try await service.addExercise(to: session.id, exercise: input)
                }
            }

            // Start the workout
            let startedSession = try await service.startWorkout(session.id)
            createdSession = startedSession

            DebugLogger.shared.log("Workout started: \(startedSession.id)", level: .success)
        } catch {
            errorMessage = "Failed to start workout: \(error.localizedDescription)"
            DebugLogger.shared.log("Failed to start workout: \(error)", level: .error)
        }

        isStartingWorkout = false
    }

    func saveAsTemplate() async {
        guard canSaveAsTemplate else { return }

        isSaving = true
        errorMessage = nil

        do {
            let workoutBlocks = buildWorkoutBlocks()

            let template = try await service.saveAsTemplate(
                name: templateName,
                description: templateDescription.isEmpty ? nil : templateDescription,
                blocks: workoutBlocks,
                patientId: patientId
            )

            DebugLogger.shared.log("Template saved: \(template.id)", level: .success)
            showingSaveTemplateSheet = false
            templateName = ""
            templateDescription = ""
        } catch {
            errorMessage = "Failed to save template: \(error.localizedDescription)"
            DebugLogger.shared.log("Failed to save template: \(error)", level: .error)
        }

        isSaving = false
    }
}

// MARK: - Creator Exercise Model

struct CreatorExercise: Identifiable, Hashable {
    let id: UUID
    let exerciseTemplateId: UUID
    let name: String
    var sets: Int
    var reps: String?
    var load: Double?
    var loadUnit: String?
    var restSeconds: Int?
    var notes: String?
    var sequence: Int

    // Optional metadata
    var category: String?
    var bodyRegion: String?
    var videoUrl: String?

    init(
        id: UUID = UUID(),
        exerciseTemplateId: UUID,
        name: String,
        sets: Int = 3,
        reps: String? = "10",
        load: Double? = nil,
        loadUnit: String? = "lbs",
        restSeconds: Int? = 90,
        notes: String? = nil,
        sequence: Int = 1,
        category: String? = nil,
        bodyRegion: String? = nil,
        videoUrl: String? = nil
    ) {
        self.id = id
        self.exerciseTemplateId = exerciseTemplateId
        self.name = name
        self.sets = sets
        self.reps = reps
        self.load = load
        self.loadUnit = loadUnit
        self.restSeconds = restSeconds
        self.notes = notes
        self.sequence = sequence
        self.category = category
        self.bodyRegion = bodyRegion
        self.videoUrl = videoUrl
    }

    var setsRepsDisplay: String {
        if let reps = reps {
            return "\(sets) x \(reps)"
        }
        return "\(sets) sets"
    }

    var loadDisplay: String {
        if let load = load, let unit = loadUnit {
            return "\(Int(load)) \(unit)"
        }
        return "Bodyweight"
    }
}

// MARK: - Main View

struct ManualWorkoutCreatorView: View {
    @StateObject private var viewModel: ManualWorkoutCreatorViewModel
    @Environment(\.dismiss) private var dismiss

    init(patientId: UUID) {
        _viewModel = StateObject(wrappedValue: ManualWorkoutCreatorViewModel(patientId: patientId))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Workout Name Header
                    workoutNameHeader

                    // Block Sections
                    ForEach(WorkoutBlockType.allCases, id: \.self) { blockType in
                        BlockSection(
                            blockType: blockType,
                            exercises: viewModel.blocks[blockType] ?? [],
                            isExpanded: viewModel.isBlockExpanded(blockType),
                            onToggleExpansion: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.toggleBlockExpansion(blockType)
                                }
                            },
                            onAddExercise: {
                                viewModel.addExercise(to: blockType)
                            },
                            onDeleteExercise: { offsets in
                                viewModel.removeExercise(at: offsets, from: blockType)
                            },
                            onMoveExercise: { source, destination in
                                viewModel.moveExercise(from: source, to: destination, in: blockType)
                            }
                        )
                    }

                    // Error Message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    // Start Workout Button
                    startWorkoutButton
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                }
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Create Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Discards workout and returns to previous screen")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.templateName = viewModel.workoutName
                            viewModel.showingSaveTemplateSheet = true
                        } label: {
                            Label("Save as Template", systemImage: "square.and.arrow.down")
                        }
                        .disabled(!viewModel.hasExercises)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("More options")
                    .accessibilityHint("Shows additional workout options like save as template")
                }
            }
            .sheet(isPresented: $viewModel.showingSaveTemplateSheet) {
                SaveTemplateSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingExercisePicker) {
                if let blockType = viewModel.selectedBlockType {
                    ExercisePickerSheet(blockType: blockType) { exercise in
                        viewModel.addExercise(exercise, to: blockType)
                    }
                }
            }
            .onChange(of: viewModel.createdSession) { _, session in
                if session != nil {
                    // Dismiss and navigate to workout execution
                    dismiss()
                }
            }
        }
    }

    // MARK: - Subviews

    private var workoutNameHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workout Name")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            TextField("Enter workout name", text: $viewModel.workoutName)
                .font(.title3)
                .fontWeight(.semibold)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(CornerRadius.md)
                .accessibilityLabel("Workout name")
                .accessibilityHint("Enter a name for your workout")
        }
        .padding(.top, 8)
    }

    private var startWorkoutButton: some View {
        Button {
            Task {
                await viewModel.startWorkout()
            }
        } label: {
            HStack(spacing: 12) {
                if viewModel.isStartingWorkout {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "play.fill")
                }
                Text("Start Workout")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.canStartWorkout ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.md)
        }
        .disabled(!viewModel.canStartWorkout || viewModel.isStartingWorkout)
        .accessibilityLabel("Start Workout")
        .accessibilityHint(viewModel.canStartWorkout ? "Begins your workout session with \(viewModel.totalExerciseCount) exercises" : "Add exercises and a workout name to start")
    }
}

// MARK: - Block Section

struct BlockSection: View {
    let blockType: WorkoutBlockType
    let exercises: [CreatorExercise]
    let isExpanded: Bool
    let onToggleExpansion: () -> Void
    let onAddExercise: () -> Void
    let onDeleteExercise: (IndexSet) -> Void
    let onMoveExercise: (IndexSet, Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggleExpansion) {
                HStack(spacing: 12) {
                    // Block Icon
                    Image(systemName: blockType.icon)
                        .font(.title3)
                        .foregroundColor(blockType.color)
                        .frame(width: 32, height: 32)
                        .background(blockType.color.opacity(0.15))
                        .cornerRadius(CornerRadius.sm)

                    // Block Name
                    VStack(alignment: .leading, spacing: 2) {
                        Text(blockType.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if !exercises.isEmpty {
                            Text("\(exercises.count) exercise\(exercises.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Expand/Collapse Chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .accessibilityHidden(true)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(blockType.displayName) block, \(exercises.count) exercise\(exercises.count == 1 ? "" : "s")")
            .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand")

            // Expanded Content
            if isExpanded {
                VStack(spacing: 0) {
                    // Exercise List
                    if !exercises.isEmpty {
                        ForEach(exercises) { exercise in
                            CreatorExerciseRow(exercise: exercise)
                                .padding(.horizontal)
                                .padding(.vertical, 8)

                            if exercise.id != exercises.last?.id {
                                Divider()
                                    .padding(.leading)
                            }
                        }
                    }

                    // Add Exercise Button
                    Button(action: onAddExercise) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(blockType.color)
                            Text("Add Exercise")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(blockType.color)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .background(blockType.color.opacity(0.08))
                    .accessibilityLabel("Add exercise to \(blockType.displayName)")
                    .accessibilityHint("Opens exercise picker to add to this block")
                }
                .background(Color(.systemBackground))
            }
        }
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Creator Exercise Row

private struct CreatorExerciseRow: View {
    let exercise: CreatorExercise

    var body: some View {
        HStack(spacing: 12) {
            // Drag Handle
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            // Exercise Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    // Sets x Reps
                    Label(exercise.setsRepsDisplay, systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Load
                    if exercise.load != nil {
                        Text("-")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)

                        Label(exercise.loadDisplay, systemImage: "scalemass")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Video indicator
            if exercise.videoUrl != nil {
                Image(systemName: "play.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .accessibilityLabel("Has video demonstration")
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), \(exercise.setsRepsDisplay), \(exercise.loadDisplay)")
    }
}

// MARK: - Save Template Sheet

struct SaveTemplateSheet: View {
    @ObservedObject var viewModel: ManualWorkoutCreatorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Template Name", text: $viewModel.templateName)
                        .textInputAutocapitalization(.words)

                    TextField("Description (optional)", text: $viewModel.templateDescription, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Template Details")
                }

                Section {
                    HStack {
                        Text("Total Exercises")
                        Spacer()
                        Text("\(viewModel.totalExerciseCount)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Blocks Used")
                        Spacer()
                        Text("\(viewModel.blocksWithExercises.count)")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Summary")
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Save as Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Discards template and returns to workout creator")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.saveAsTemplate()
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .accessibilityLabel("Saving template")
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!viewModel.canSaveAsTemplate || viewModel.isSaving)
                    .accessibilityLabel("Save template")
                    .accessibilityHint(viewModel.canSaveAsTemplate ? "Saves this workout as a reusable template" : "Enter a template name to save")
                }
            }
        }
    }
}

// MARK: - Exercise Picker Sheet

struct ExercisePickerSheet: View {
    let blockType: WorkoutBlockType
    let onExerciseSelected: (CreatorExercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var exercises: [Exercise.ExerciseTemplate] = []
    @State private var favoriteExerciseIds: Set<UUID> = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showAllExercises = false

    // Filtered exercises based on block type
    private var suggestedExercises: [Exercise.ExerciseTemplate] {
        exercises.filter { exercise in
            blockType.matchesExercise(category: exercise.category, bodyRegion: exercise.body_region)
        }
    }

    // Favorite exercises
    private var favoriteExercises: [Exercise.ExerciseTemplate] {
        exercises.filter { favoriteExerciseIds.contains($0.id) }
    }

    // Search-filtered exercises
    private var filteredExercises: [Exercise.ExerciseTemplate] {
        let baseExercises = showAllExercises ? exercises : suggestedExercises

        if searchText.isEmpty {
            return baseExercises
        }
        return baseExercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(searchText) ||
            (exercise.category?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (exercise.body_region?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading exercises...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let error = error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                await loadExercises()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        // Favorites section (if any and not searching)
                        if !favoriteExercises.isEmpty && searchText.isEmpty {
                            Section {
                                ForEach(favoriteExercises) { exercise in
                                    Button {
                                        selectExercise(exercise)
                                    } label: {
                                        ExercisePickerRowView(
                                            exercise: exercise,
                                            blockType: blockType,
                                            isFavorite: true,
                                            onToggleFavorite: {
                                                toggleFavorite(exercise)
                                            }
                                        )
                                    }
                                }
                            } header: {
                                Label("Favorites", systemImage: "star.fill")
                            }
                        }

                        // Filter toggle section
                        if searchText.isEmpty {
                            Section {
                                Toggle(isOn: $showAllExercises) {
                                    HStack {
                                        Image(systemName: showAllExercises ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                                            .foregroundColor(blockType.color)
                                        VStack(alignment: .leading) {
                                            Text(showAllExercises ? "Showing All Exercises" : "Showing Suggested")
                                                .font(.subheadline)
                                            Text(showAllExercises ? "\(exercises.count) exercises" : "\(suggestedExercises.count) for \(blockType.displayName)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }

                        // Main exercise list
                        Section {
                            if filteredExercises.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text(searchText.isEmpty ? "No suggested exercises" : "No exercises found")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    if !showAllExercises && searchText.isEmpty {
                                        Button("Show All Exercises") {
                                            showAllExercises = true
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                ForEach(filteredExercises) { exercise in
                                    Button {
                                        selectExercise(exercise)
                                    } label: {
                                        ExercisePickerRowView(
                                            exercise: exercise,
                                            blockType: blockType,
                                            isFavorite: favoriteExerciseIds.contains(exercise.id),
                                            onToggleFavorite: {
                                                toggleFavorite(exercise)
                                            }
                                        )
                                    }
                                }
                            }
                        } header: {
                            if !filteredExercises.isEmpty {
                                Text(showAllExercises ? "All Exercises" : "Suggested for \(blockType.displayName)")
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add to \(blockType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Closes exercise picker without adding")
                }
            }
            .task {
                await loadExercises()
                await loadFavorites()
            }
        }
    }

    private func loadExercises() async {
        isLoading = true
        error = nil

        do {
            let response = try await PTSupabaseClient.shared.client
                .from("exercise_templates")
                .select("id, name, category, body_region, video_url")
                .order("name", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            exercises = try decoder.decode([Exercise.ExerciseTemplate].self, from: response.data)

            DebugLogger.shared.log("Loaded \(exercises.count) exercises for picker", level: .success)
        } catch {
            self.error = "Failed to load exercises: \(error.localizedDescription)"
            DebugLogger.shared.log("Failed to load exercises: \(error)", level: .error)
        }

        isLoading = false
    }

    private func loadFavorites() async {
        guard let userId = appState.userId, let patientId = UUID(uuidString: userId) else { return }

        do {
            let response = try await PTSupabaseClient.shared.client
                .from("patient_favorite_exercises")
                .select("exercise_template_id")
                .eq("patient_id", value: patientId.uuidString)
                .execute()

            struct FavoriteRow: Codable {
                let exerciseTemplateId: UUID

                enum CodingKeys: String, CodingKey {
                    case exerciseTemplateId = "exercise_template_id"
                }
            }

            let decoder = JSONDecoder()
            let rows = try decoder.decode([FavoriteRow].self, from: response.data)
            favoriteExerciseIds = Set(rows.map { $0.exerciseTemplateId })

            DebugLogger.shared.log("Loaded \(favoriteExerciseIds.count) favorite exercises", level: .success)
        } catch {
            // Table might not exist yet, that's OK
            DebugLogger.shared.log("Favorites not loaded (table may not exist): \(error.localizedDescription)", level: .warning)
        }
    }

    private func toggleFavorite(_ exercise: Exercise.ExerciseTemplate) {
        guard let userId = appState.userId, let patientId = UUID(uuidString: userId) else { return }

        Task {
            do {
                if favoriteExerciseIds.contains(exercise.id) {
                    // Remove from favorites
                    try await PTSupabaseClient.shared.client
                        .from("patient_favorite_exercises")
                        .delete()
                        .eq("patient_id", value: patientId.uuidString)
                        .eq("exercise_template_id", value: exercise.id.uuidString)
                        .execute()

                    await MainActor.run {
                        favoriteExerciseIds.remove(exercise.id)
                        HapticFeedback.light()
                    }
                } else {
                    // Add to favorites
                    struct InsertFavorite: Codable {
                        let patientId: UUID
                        let exerciseTemplateId: UUID

                        enum CodingKeys: String, CodingKey {
                            case patientId = "patient_id"
                            case exerciseTemplateId = "exercise_template_id"
                        }
                    }

                    try await PTSupabaseClient.shared.client
                        .from("patient_favorite_exercises")
                        .insert(InsertFavorite(patientId: patientId, exerciseTemplateId: exercise.id))
                        .execute()

                    await MainActor.run {
                        favoriteExerciseIds.insert(exercise.id)
                        HapticFeedback.success()
                    }
                }
            } catch {
                DebugLogger.shared.log("Failed to toggle favorite: \(error.localizedDescription)", level: .error)
            }
        }
    }

    private func selectExercise(_ exercise: Exercise.ExerciseTemplate) {
        let creatorExercise = CreatorExercise(
            exerciseTemplateId: exercise.id,
            name: exercise.name,
            sets: 3,
            reps: "10",
            load: nil,
            loadUnit: "lbs",
            restSeconds: 90,
            notes: nil,
            sequence: 1,
            category: exercise.category,
            bodyRegion: exercise.body_region,
            videoUrl: exercise.videoUrl
        )
        onExerciseSelected(creatorExercise)
        dismiss()
    }
}

// MARK: - Exercise Picker Row View

struct ExercisePickerRowView: View {
    let exercise: Exercise.ExerciseTemplate
    let blockType: WorkoutBlockType
    var isFavorite: Bool = false
    var onToggleFavorite: (() -> Void)?

    var body: some View {
        HStack {
            // Favorite star button
            Button {
                onToggleFavorite?()
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.subheadline)
                    .foregroundColor(isFavorite ? .yellow : .secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            .accessibilityHint(isFavorite ? "Removes \(exercise.name) from your favorite exercises" : "Adds \(exercise.name) to your favorite exercises")

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    if let category = exercise.category {
                        Text(category.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let bodyRegion = exercise.body_region {
                        if exercise.category != nil {
                            Text("-")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(bodyRegion.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if exercise.hasVideo {
                Image(systemName: "play.circle")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.trailing, 4)
            }

            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundColor(blockType.color)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), \(exercise.category?.capitalized ?? ""), \(exercise.body_region?.capitalized ?? "")")
        .accessibilityHint("Double tap to add to \(blockType.displayName)")
    }
}

// MARK: - Preview

#Preview {
    ManualWorkoutCreatorView(patientId: UUID())
}
