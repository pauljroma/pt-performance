import SwiftUI

struct TodaySessionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = TodaySessionViewModel()
    @State private var selectedExercise: Exercise?
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var showDebugLogs = false
    @State private var showSessionSummary = false
    @State private var isCompletingSession = false
    @State private var completionError: String?
    @State private var showReadinessCheckIn = false
    @State private var showReadinessDashboard = false
    @State private var todayReadiness: DailyReadiness?
    @State private var isLoadingReadiness = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // BUILD 120: Exercise state management
    @State private var completedExercises: [UUID: Bool] = [:]
    @State private var expandedExercises: [UUID: Bool] = [:]

    // BUILD 124: Explicit workout session tracking
    @State private var sessionStartTime: Date?
    @State private var isWorkoutStarted = false
    @State private var currentTime = Date() // For running clock
    @State private var timer: Timer?

    // BUILD 174: Store completed session with correct started_at/completed_at
    @State private var completedSession: Session?

    // Manual Workout Navigation
    @State private var showTemplateLibrary = false
    @State private var showWorkoutCreator = false
    @State private var showAddToTodayPicker = false
    @State private var showManualWorkoutExecution = false
    @State private var selectedWorkoutTemplate: AnyWorkoutTemplate?
    @State private var createdManualSession: ManualSession?
    @State private var isCreatingManualSession = false

    var shouldUseSplitView: Bool {
        DeviceHelper.shouldUseSplitView(horizontalSizeClass: horizontalSizeClass)
    }

    var body: some View {
        Group {
            if shouldUseSplitView {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .sheet(isPresented: $showDebugLogs) {
            DebugLogView()
        }
        .sheet(isPresented: $showSessionSummary) {
            // BUILD 174: Use completedSession which has correct started_at/completed_at
            // Previously used viewModel.session which could be wrong session after fetchTodaySession()
            if let session = completedSession {
                SessionSummaryView(session: session)
            }
        }
        .sheet(isPresented: $showReadinessCheckIn, onDismiss: {
            // BUILD 127: Reload readiness data after check-in submission
            Task {
                await loadTodayReadiness()
            }
        }) {
            if let patientId = appState.userId {
                ReadinessCheckInView(patientId: UUID(uuidString: patientId) ?? UUID())
            }
        }
        .sheet(isPresented: $showReadinessDashboard) {
            if let patientId = appState.userId {
                NavigationStack {
                    ReadinessDashboardView(patientId: UUID(uuidString: patientId) ?? UUID())
                }
            }
        }
        // Manual Workout Sheets
        .sheet(isPresented: $showTemplateLibrary) {
            if let patientId = appState.userId {
                NavigationStack {
                    WorkoutTemplateLibraryView(
                        patientId: UUID(uuidString: patientId) ?? UUID(),
                        onStartWorkout: { template in
                            // Store template and trigger session creation
                            selectedWorkoutTemplate = template
                            showTemplateLibrary = false
                            Task {
                                await createManualSessionFromTemplate(template, patientId: patientId)
                            }
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showWorkoutCreator) {
            if let patientId = appState.userId {
                NavigationStack {
                    ManualWorkoutCreatorView(
                        patientId: UUID(uuidString: patientId) ?? UUID()
                    )
                }
            }
        }
        .fullScreenCover(isPresented: $showManualWorkoutExecution) {
            if let session = createdManualSession, let patientId = appState.userId {
                ManualWorkoutExecutionView(
                    session: session,
                    patientId: UUID(uuidString: patientId) ?? UUID(),
                    onComplete: {
                        showManualWorkoutExecution = false
                        createdManualSession = nil
                        selectedWorkoutTemplate = nil
                        // Refresh today's session to show any updates
                        Task { await viewModel.fetchTodaySession() }
                    }
                )
            } else {
                // Debug: Show what's missing
                VStack(spacing: 20) {
                    Text("Error Loading Workout")
                        .font(.title)
                    Text("Session: \(createdManualSession?.id.uuidString ?? "NIL")")
                    Text("Patient ID: \(appState.userId ?? "NIL")")
                    Button("Dismiss") {
                        showManualWorkoutExecution = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .task {
            await viewModel.fetchTodaySession()
            await loadTodayReadiness()
        }
        .onDisappear {
            // BUILD 124: Stop timer when view disappears
            timer?.invalidate()
            timer = nil
        }
    }

    // MARK: - iPad Split View Layout

    private var iPadLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            exerciseListContent
                .navigationTitle("Today's Session")
                .navigationSplitViewColumnWidth(
                    min: DeviceHelper.sidebarWidth.min,
                    ideal: DeviceHelper.sidebarWidth.ideal,
                    max: DeviceHelper.sidebarWidth.max
                )
        } detail: {
            if let exercise = selectedExercise {
                ExerciseDetailView(exercise: exercise)
            } else {
                placeholderDetailView
            }
        }
    }

    // MARK: - iPhone Stack Layout

    private var iPhoneLayout: some View {
        NavigationStack {
            exerciseListContent
                .navigationTitle("Today's Session")
        }
    }

    // MARK: - Shared Content

    @ViewBuilder
    private var exerciseListContent: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading today's session...")
            } else if let errorMessage = viewModel.errorMessage {
                errorStateView(errorMessage)
            } else if viewModel.session == nil {
                noSessionView
            } else {
                sessionContent
            }

            // Manual Workout FAB
            FloatingActionButton(
                onAddToToday: {
                    showAddToTodayPicker = true
                },
                onNewWorkout: {
                    showWorkoutCreator = true
                },
                onFromLibrary: {
                    showTemplateLibrary = true
                }
            )
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showDebugLogs = true }) {
                    Image(systemName: "ant.circle")
                        .foregroundColor(.orange)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    ContextualHelpButton(articleId: nil)

                    Button(action: {
                        Task {
                            await viewModel.refresh()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }

    @ViewBuilder
    private var sessionContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // BUILD 116 - Readiness Section (Agent 18)
                readinessSection

                // BUILD 124: Start Workout Button with Running Clock
                if let session = viewModel.session, !session.isCompleted {
                    startWorkoutSection
                }

                // Session Header
                if let session = viewModel.session {
                    sessionHeaderView(session)
                }

                // Exercise List
                if viewModel.exercises.isEmpty {
                    Text("No exercises in this session")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.exercises) { exercise in
                            // BUILD 120: Use ExerciseCompactRow for inline editing
                            ExerciseCompactRow(
                                exercise: exercise,
                                isCompleted: Binding(
                                    get: { completedExercises[exercise.id] ?? false },
                                    set: { completedExercises[exercise.id] = $0 }
                                ),
                                isExpanded: Binding(
                                    get: { expandedExercises[exercise.id] ?? false },
                                    set: { expandedExercises[exercise.id] = $0 }
                                )
                            )
                            .environmentObject(viewModel)
                        }
                    }
                }

                // Build 33: Complete Session Button
                if let session = viewModel.session, !session.isCompleted {
                    VStack(spacing: 16) {
                        Divider()
                            .padding(.vertical, 8)

                        Button(action: {
                            Task {
                                await handleCompleteSession()
                            }
                        }) {
                            HStack {
                                if isCompletingSession {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Complete Session")
                                }
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isCompletingSession ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isCompletingSession || viewModel.exercises.isEmpty)

                        if let error = completionError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationDestination(for: Exercise.self) { exercise in
            if !shouldUseSplitView {
                ExerciseDetailView(exercise: exercise)
            }
        }
    }

    // MARK: - BUILD 116: Readiness Section (Agent 18)

    @ViewBuilder
    private var readinessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title
            Text("Daily Readiness")
                .font(.headline)
                .foregroundColor(.secondary)

            if isLoadingReadiness {
                // Loading state
                ProgressView("Loading readiness...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let readiness = todayReadiness,
                      let score = readiness.readinessScore,
                      let category = readiness.category {
                // Checked in today - show score card
                readinessScoreCard(score: score, category: category)
            } else {
                // Not checked in - show prompt
                readinessCheckInPrompt
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
    }

    @ViewBuilder
    private func readinessScoreCard(score: Double, category: ReadinessCategory) -> some View {
        Button(action: {
            showReadinessDashboard = true
        }) {
            HStack(spacing: 16) {
                // Score circle
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.2))
                        .frame(width: 64, height: 64)

                    VStack(spacing: 2) {
                        Text(String(format: "%.0f", score))
                            .font(.title2)
                            .bold()
                            .foregroundColor(category.color)

                        Text("/ 100")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Category and recommendation
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.displayName)
                        .font(.headline)
                        .foregroundColor(category.color)

                    Text(category.recommendation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var readinessCheckInPrompt: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square")
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("How are you feeling today?")
                        .font(.headline)

                    Text("Complete your daily check-in")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Button(action: {
                showReadinessCheckIn = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Check In Now")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }

    // MARK: - BUILD 124: Start Workout Section with Running Clock

    @ViewBuilder
    private var startWorkoutSection: some View {
        VStack(spacing: 16) {
            if !isWorkoutStarted {
                // Start Workout Button
                Button(action: startWorkout) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                        Text("Start Workout")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            } else {
                // Running Clock
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        // Pulsing indicator
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .opacity(currentTime.timeIntervalSince1970.truncatingRemainder(dividingBy: 1.0) < 0.5 ? 1.0 : 0.3)

                        Text("Workout in Progress")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()
                    }

                    HStack {
                        Image(systemName: "timer")
                            .font(.title)
                            .foregroundColor(.green)

                        Text(elapsedTimeFormatted)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)

                        Spacer()
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - BUILD 124: Workout Timing Helpers

    private var elapsedTimeFormatted: String {
        guard let startTime = sessionStartTime else { return "00:00:00" }
        let elapsed = currentTime.timeIntervalSince(startTime)
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func startWorkout() {
        sessionStartTime = Date()
        isWorkoutStarted = true

        // Start timer to update clock every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }

        DebugLogger.shared.log("⏱️ Workout session started at: \(sessionStartTime!)")
    }

    @ViewBuilder
    private func sessionHeaderView(_ session: Session) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.dateDisplay)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(session.name)
                .font(.title)
                .bold()

            HStack {
                Image(systemName: "circle")
                Text(session.completionStatus)
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func errorStateView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task {
                    await viewModel.refresh()
                }
            }
        }
        .padding()
    }

    private var noSessionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("No Session Today")
                .font(.title2)
                .bold()

            Text("Great job! You're all caught up. Enjoy your rest day!")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var placeholderDetailView: some View {
        ContentUnavailableView(
            "Select an Exercise",
            systemImage: "figure.strengthtraining.traditional",
            description: Text("Choose an exercise to view details and log your performance")
        )
    }

    private func handleExerciseSelection(_ exercise: Exercise) {
        selectedExercise = exercise

        // On iPad, ensure detail is visible
        if shouldUseSplitView {
            columnVisibility = .doubleColumn
        }
    }

    // MARK: - Build 33: Session Completion

    private func handleCompleteSession() async {
        isCompletingSession = true
        completionError = nil

        // BUILD 123: Pass session start time to completion
        let startTime = sessionStartTime ?? Date() // Fallback to current time if not captured
        let result = await viewModel.completeSession(startedAt: startTime)

        switch result {
        case .success(let session):
            // BUILD 174: Store the completed session with correct started_at/completed_at
            completedSession = session
            isCompletingSession = false
            showSessionSummary = true
        case .failure(let error):
            isCompletingSession = false
            completionError = "Failed to complete session: \(error.localizedDescription)"
        }
    }

    // MARK: - BUILD 124: Readiness Data Loading (Fixed)

    private func loadTodayReadiness() async {
        guard let userId = appState.userId,
              let patientId = UUID(uuidString: userId) else {
            return
        }

        isLoadingReadiness = true
        defer { isLoadingReadiness = false }

        do {
            let readinessService = ReadinessService()
            todayReadiness = try await readinessService.fetchTodayReadiness(for: patientId)
            DebugLogger.shared.log("✅ Loaded today's readiness: \(todayReadiness != nil ? "YES" : "NO")")
        } catch {
            // Silently fail - just means no check-in today
            DebugLogger.shared.log("ℹ️ No readiness check-in for today: \(error.localizedDescription)")
            todayReadiness = nil
        }
    }

    // MARK: - Manual Workout Creation from Template

    private func createManualSessionFromTemplate(_ template: AnyWorkoutTemplate, patientId: String) async {
        guard let patientUUID = UUID(uuidString: patientId) else {
            DebugLogger.shared.log("❌ Invalid patient ID for manual workout", level: .error)
            return
        }

        isCreatingManualSession = true
        defer { isCreatingManualSession = false }

        let service = ManualWorkoutService()

        do {
            DebugLogger.shared.log("📝 Creating manual session from template: \(template.name)", level: .diagnostic)

            // 1. Create the manual session
            let session = try await service.createManualSession(
                name: template.name,
                patientId: patientUUID,
                sourceTemplateId: template.id,
                sourceTemplateType: template.isSystemTemplate ? .system : .patient
            )

            DebugLogger.shared.log("✅ Manual session created: \(session.id)", level: .success)

            // 2. Add exercises from the template
            // Note: Pass nil for exerciseTemplateId - imported templates don't have valid FK references
            var sequence = 0
            for block in template.blocks {
                for exercise in block.exercises {
                    let input = AddManualSessionExerciseInput(
                        manualSessionId: session.id,
                        exerciseTemplateId: nil,  // Templates don't have valid exercise_template_id references
                        exerciseName: exercise.name,
                        blockName: block.name,
                        sequence: sequence,
                        targetSets: exercise.prescribedSets,
                        targetReps: exercise.prescribedReps,
                        targetLoad: exercise.prescribedLoad,
                        loadUnit: exercise.loadUnit,
                        restPeriodSeconds: exercise.restPeriodSeconds,
                        notes: exercise.notes
                    )
                    _ = try await service.addExercise(to: session.id, exercise: input)
                    sequence += 1
                }
            }

            DebugLogger.shared.log("✅ Added \(sequence) exercises to session", level: .success)

            // 3. Start the workout
            let startedSession = try await service.startWorkout(session.id)

            // 4. Store the session and navigate to execution view
            DebugLogger.shared.log("🎯 Navigating to execution view with session: \(startedSession.id)", level: .success)
            await MainActor.run {
                createdManualSession = startedSession
                showManualWorkoutExecution = true
                DebugLogger.shared.log("🎯 showManualWorkoutExecution = true", level: .diagnostic)
            }

        } catch {
            DebugLogger.shared.log("❌ Failed to create manual session: \(error)", level: .error)
            // Don't show execution view if creation failed
            await MainActor.run {
                showManualWorkoutExecution = false
                createdManualSession = nil
            }
        }
    }
}

// MARK: - BUILD 116: ReadinessService Extension (Agent 18)

extension ReadinessService {
    /// Fetch today's readiness check-in for a patient (UUID version)
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Today's readiness record, or nil if not found
    func fetchTodayReadiness(for patientId: UUID) async throws -> DailyReadiness? {
        return try await getTodayReadiness(for: patientId)
    }
}

/// Exercise row component
struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 16) {
            // Exercise order badge
            Text("\(exercise.exercise_order)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.blue)
                .clipShape(Circle())

            // Exercise details
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exercise_name ?? "Exercise \(exercise.exercise_order)")
                    .font(.headline)

                HStack(spacing: 12) {
                    Label(exercise.setsDisplay, systemImage: "repeat")
                    Label(exercise.repsDisplay + " reps", systemImage: "number")
                    Label(exercise.loadDisplay, systemImage: "scalemass")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                if let notes = exercise.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
    }
}

/// Exercise detail view placeholder
struct ExerciseDetailView: View {
    let exercise: Exercise
    @EnvironmentObject var appState: AppState
    @State private var showTechniqueGuide = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(exercise.exercise_name ?? "Exercise")
                    .font(.largeTitle)
                    .bold()

                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Sets", value: exercise.setsDisplay)
                    DetailRow(label: "Reps", value: exercise.repsDisplay)
                    DetailRow(label: "Load", value: exercise.loadDisplay)

                    if let rest = exercise.rest_seconds {
                        DetailRow(label: "Rest", value: "\(rest) seconds")
                    }

                    if let notes = exercise.notes {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            Text(notes)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // View Technique Guide button
                Button(action: {
                    showTechniqueGuide = true
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("View Technique Guide")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                Spacer()

                // Log exercise button - navigates to exercise logging form
                if let patientId = appState.userId {
                    NavigationLink(destination: ExerciseLogView(
                        exercise: exercise,
                        sessionExerciseId: exercise.id.uuidString,
                        patientId: patientId
                    )) {
                        Text("Log This Exercise")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                } else {
                    Text("Log This Exercise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .overlay(
                            Text("Sign in to log exercises")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
            }
            .padding()
        }
        .navigationTitle("Exercise Detail")
        .sheet(isPresented: $showTechniqueGuide) {
            ExerciseTechniqueView(exercise: exercise)
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
}
