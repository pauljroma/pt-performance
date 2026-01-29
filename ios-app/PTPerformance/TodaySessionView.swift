import SwiftUI

struct TodaySessionView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var supabase: PTSupabaseClient  // BUILD 264: For ManualWorkoutExecutionView
    @StateObject private var viewModel = TodaySessionViewModel()
    @State private var selectedExercise: Exercise?
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var showDebugLogs = false
    // BUILD 307: Removed showSessionSummary bool - use sheet(item:) pattern instead
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
    // showManualWorkoutExecution removed - using fullScreenCover(item:) pattern instead
    @State private var selectedWorkoutTemplate: AnyWorkoutTemplate?
    @State private var createdManualSession: ManualSession?
    @State private var isCreatingManualSession = false

    // BUILD 258: Unified workout execution
    @State private var showUnifiedWorkoutExecution = false

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
        // BUILD 307: Use sheet(item:) pattern to prevent black screen when session is nil
        .sheet(item: $completedSession) { session in
            SessionSummaryView(session: session)
                .environmentObject(appState)
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
        // BUILD 220: Add exercise to today's session picker
        .sheet(isPresented: $showAddToTodayPicker) {
            NavigationStack {
                AddExerciseToTodaySheet(
                    onExerciseAdded: {
                        showAddToTodayPicker = false
                        Task { await viewModel.fetchTodaySession() }
                    }
                )
            }
        }
        // Use item: pattern to avoid SwiftUI state race condition
        .fullScreenCover(item: $createdManualSession) { (session: ManualSession) in
            if let patientId = appState.userId {
                ManualWorkoutExecutionView(
                    session: session,
                    patientId: UUID(uuidString: patientId) ?? UUID(),
                    onComplete: {
                        createdManualSession = nil
                        selectedWorkoutTemplate = nil
                        // BUILD 275: Refresh completed workouts FIRST, then fetch next session
                        Task {
                            await viewModel.fetchTodaysCompletedWorkouts()
                            await viewModel.fetchTodaySession()
                        }
                    }
                )
                .environmentObject(supabase)  // BUILD 264: Pass supabase to workout execution
            }
        }
        // BUILD 258: Unified workout execution for prescribed sessions
        .fullScreenCover(isPresented: $showUnifiedWorkoutExecution) {
            if let session = viewModel.session, let patientId = appState.userId {
                ManualWorkoutExecutionView(
                    prescribedSession: session,
                    exercises: viewModel.exercises,
                    patientId: UUID(uuidString: patientId) ?? UUID(),
                    onComplete: {
                        showUnifiedWorkoutExecution = false
                        isWorkoutStarted = false
                        timer?.invalidate()
                        timer = nil
                        // BUILD 275: Refresh completed workouts FIRST, then fetch next session
                        Task {
                            await viewModel.fetchTodaysCompletedWorkouts()
                            await viewModel.fetchTodaySession()
                        }
                    }
                )
                .environmentObject(supabase)  // BUILD 264: Pass supabase to workout execution
            }
        }
        .task {
            // Only fetch on initial load; onComplete callbacks handle refresh after workouts
            if viewModel.session == nil && !viewModel.isLoading {
                await viewModel.fetchTodaySession()
            }
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

    // MARK: - Loading View

    @ViewBuilder
    private var loadingView: some View {
        TodaySessionLoadingView()
    }

    @ViewBuilder
    private var exerciseListContent: some View {
        ZStack {
            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorStateView(errorMessage)
            } else if viewModel.session == nil {
                noSessionView
            } else {
                sessionContent
            }

            // BUILD 286: Re-enabled Add to Today FAB option (ACP-591)
            FloatingActionButton(
                onAddToToday: { showAddToTodayPicker = true },
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

    // BUILD 259: Simplified session content - just cards and Start Workout button
    @ViewBuilder
    private var sessionContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // BUILD 269: Today's completed workouts counter
                if viewModel.completedTodayCount > 0 {
                    completedTodaySection
                }

                // Readiness Section
                readinessSection

                // Session Card with Start Workout
                if let session = viewModel.session {
                    if session.isCompleted {
                        sessionCompletedView
                    } else {
                        todaySessionCard(session)
                    }
                }

                Spacer()
            }
            .padding()
        }
    }

    // BUILD 269: Section showing today's completed workouts
    @ViewBuilder
    private var completedTodaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.completedTodayCount) workout\(viewModel.completedTodayCount == 1 ? "" : "s") completed today")
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let lastWorkout = viewModel.todaysCompletedWorkouts.first {
                        Text("Last: \(lastWorkout.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )

            // List of completed workouts today
            if viewModel.todaysCompletedWorkouts.count > 0 {
                ForEach(viewModel.todaysCompletedWorkouts) { workout in
                    HStack(spacing: 12) {
                        Image(systemName: workout.isPrescribed ? "clipboard.fill" : "dumbbell.fill")
                            .foregroundColor(workout.isPrescribed ? .blue : .orange)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(workout.name)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack(spacing: 8) {
                                if let duration = workout.durationMinutes {
                                    Text("\(duration) min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                if let volume = workout.totalVolume, volume > 0 {
                                    Text(volume >= 1000 ? String(format: "%.1fk lbs", volume / 1000) : "\(Int(volume)) lbs")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Text(workout.completedAt, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
        }
    }

    // BUILD 259: Clean session card with exercise preview and Start button
    @ViewBuilder
    private func todaySessionCard(_ session: Session) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Session Info Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY'S WORKOUT")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Text(session.name)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                // Exercise count badge
                VStack {
                    Text("\(viewModel.exercises.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Exercise preview (first 3)
            if !viewModel.exercises.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.exercises.prefix(3)) { exercise in
                        HStack(spacing: 12) {
                            Image(systemName: "circle")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(exercise.exercise_name ?? "Exercise")
                                .font(.subheadline)

                            Spacer()

                            Text("\(exercise.prescribed_sets) × \(exercise.repsDisplay)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if viewModel.exercises.count > 3 {
                        Text("+ \(viewModel.exercises.count - 3) more exercises")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 24)
                    }
                }
                .padding(.vertical, 8)
            }

            Divider()

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
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
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
        // BUILD 258: Launch unified workout execution view
        showUnifiedWorkoutExecution = true
        DebugLogger.shared.log("🏋️ Launching unified workout execution view")
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

    // MARK: - Session Completed View (BUILD 215)

    @ViewBuilder
    private var sessionCompletedView: some View {
        VStack(spacing: 24) {
            // Success icon and message
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.green)

                Text("Session Complete!")
                    .font(.title)
                    .bold()

                if let session = viewModel.session {
                    Text(session.name)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                // Show metrics if available
                if let session = viewModel.session {
                    HStack(spacing: 24) {
                        if let volume = session.total_volume, volume > 0 {
                            VStack {
                                Text(volume >= 1000 ? String(format: "%.1fk", volume / 1000) : "\(Int(volume))")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("lbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let duration = session.duration_minutes {
                            VStack {
                                Text("\(duration)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("min")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let rpe = session.avg_rpe {
                            VStack {
                                Text(String(format: "%.1f", rpe))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("RPE")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }

            Divider()
                .padding(.vertical, 8)

            // Options for next steps
            VStack(spacing: 12) {
                Text("Want to do more?")
                    .font(.headline)
                    .foregroundColor(.secondary)

                // Start another workout from library
                Button(action: {
                    showTemplateLibrary = true
                }) {
                    HStack {
                        Image(systemName: "books.vertical.fill")
                        Text("Browse Workout Library")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                // Create custom workout
                Button(action: {
                    showWorkoutCreator = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Custom Workout")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green, lineWidth: 1)
                    )
                }

                // View summary - BUILD 307: sheet(item:) shows when completedSession is set
                Button(action: {
                    completedSession = viewModel.session
                }) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("View Session Summary")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.top, 8)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
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
            // BUILD 307: sheet(item:) shows automatically when completedSession is set
            completedSession = session
            isCompletingSession = false
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

            // 4. Store the session - fullScreenCover(item:) will present automatically
            DebugLogger.shared.log("🎯 Setting createdManualSession to trigger fullScreenCover: \(startedSession.id)", level: .success)
            await MainActor.run {
                createdManualSession = startedSession
                DebugLogger.shared.log("🎯 createdManualSession set, fullScreenCover should present", level: .diagnostic)
            }

        } catch {
            DebugLogger.shared.log("❌ Failed to create manual session: \(error)", level: .error)
            // Ensure session is nil so fullScreenCover doesn't present
            await MainActor.run {
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
