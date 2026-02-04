import SwiftUI

struct TodaySessionView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var supabase: PTSupabaseClient
    @StateObject private var viewModel = TodaySessionViewModel()
    @StateObject private var enrolledProgramsViewModel = EnrolledProgramsViewModel()
    @State private var selectedExercise: Exercise?
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var showDebugLogs = false
    // Use sheet(item:) pattern for session summary instead of boolean
    @State private var isCompletingSession = false
    @State private var completionError: String?
    @State private var showReadinessCheckIn = false
    @State private var showReadinessDashboard = false
    @State private var todayReadiness: DailyReadiness?
    @State private var isLoadingReadiness = false
    // ACP-522: Arm Care Assessment state
    @State private var showArmCareAssessment = false
    @State private var todayArmCare: ArmCareAssessment?
    @State private var isLoadingArmCare = false

    // Recovery Intelligence state
    @State private var workoutAdaptation: WorkoutAdaptation?
    @State private var isLoadingAdaptation = false
    @State private var showRecoveryProtocol = false
    @State private var showReadinessInsights = false

    // Prescribed workouts state
    @State private var pendingPrescriptions: [WorkoutPrescription] = []
    @State private var isLoadingPrescriptions = false
    @State private var selectedPrescription: WorkoutPrescription?

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme

    // Exercise state management
    @State private var completedExercises: [UUID: Bool] = [:]
    @State private var expandedExercises: [UUID: Bool] = [:]

    // Explicit workout session tracking
    @State private var sessionStartTime: Date?
    @State private var isWorkoutStarted = false
    @State private var currentTime = Date() // For running clock
    @State private var timer: Timer?

    // Store completed session with correct started_at/completed_at
    @State private var completedSession: Session?

    // Manual Workout Navigation
    @State private var showTemplateLibrary = false
    @State private var showWorkoutCreator = false
    @State private var showAddToTodayPicker = false
    // showManualWorkoutExecution removed - using fullScreenCover(item:) pattern instead
    @State private var selectedWorkoutTemplate: AnyWorkoutTemplate?
    @State private var createdManualSession: ManualSession?
    @State private var isCreatingManualSession = false

    // Unified workout execution
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
        // Use sheet(item:) pattern to prevent black screen when session is nil
        .sheet(item: $completedSession) { session in
            SessionSummaryView(session: session)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showReadinessCheckIn, onDismiss: {
            // Reload readiness data after check-in submission
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
        // ACP-522: Arm Care Assessment sheet
        .sheet(isPresented: $showArmCareAssessment, onDismiss: {
            Task {
                await loadTodayArmCare()
            }
        }) {
            if let patientId = appState.userId {
                ArmCareAssessmentView(patientId: UUID(uuidString: patientId) ?? UUID())
            }
        }
        // Recovery Intelligence sheets
        .sheet(isPresented: $showRecoveryProtocol) {
            if let patientId = appState.userId {
                NavigationStack {
                    RecoveryProtocolView(patientId: UUID(uuidString: patientId) ?? UUID())
                }
            }
        }
        .sheet(isPresented: $showReadinessInsights) {
            if let patientId = appState.userId {
                NavigationStack {
                    ReadinessInsightsView(patientId: UUID(uuidString: patientId) ?? UUID())
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
        // Add exercise to today's session picker
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
                        // If this was a prescribed workout, mark the prescription as completed
                        if let prescription = selectedPrescription {
                            Task {
                                let prescriptionService = WorkoutPrescriptionService()
                                try? await prescriptionService.markAsCompleted(prescription.id)
                                await loadPendingPrescriptions()
                            }
                        }

                        createdManualSession = nil
                        selectedWorkoutTemplate = nil
                        selectedPrescription = nil
                        // Refresh completed workouts and fetch next session in parallel
                        Task {
                            async let completedTask: () = viewModel.fetchTodaysCompletedWorkouts()
                            async let sessionTask: () = viewModel.fetchTodaySession()
                            _ = await (completedTask, sessionTask)
                        }
                    }
                )
                .environmentObject(supabase)
            }
        }
        // Unified workout execution for prescribed sessions
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
                        // Refresh completed workouts and fetch next session in parallel
                        Task {
                            async let completedTask: () = viewModel.fetchTodaysCompletedWorkouts()
                            async let sessionTask: () = viewModel.fetchTodaySession()
                            _ = await (completedTask, sessionTask)
                        }
                    }
                )
                .environmentObject(supabase)
            }
        }
        .task {
            // Only fetch on initial load; onComplete callbacks handle refresh after workouts
            if viewModel.session == nil && !viewModel.isLoading {
                await viewModel.fetchTodaySession()
            }
            await loadTodayReadiness()
            await loadTodayArmCare()  // ACP-522: Load arm care assessment
            // Load enrolled programs for the My Programs section
            await enrolledProgramsViewModel.loadEnrolledPrograms()
            // Load pending prescriptions from therapist
            await loadPendingPrescriptions()
            // Recovery Intelligence: Load workout adaptation based on readiness
            await loadWorkoutAdaptation()
        }
        .onDisappear {
            // Stop timer when view disappears
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
        VStack(spacing: 0) {
            // Offline banner at the top - shows when offline or has pending sync items
            OfflineBanner()

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

                // Add to Today FAB option (ACP-591)
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
            // One-Tap Start: Floating start button always visible when session available
            .overlay(alignment: .bottom) {
                if let session = viewModel.session, !session.isCompleted && !isWorkoutStarted {
                    OneTapStartButton(action: startWorkout)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showDebugLogs = true }) {
                    Image(systemName: "ant.circle")
                        .foregroundColor(.orange)
                }
                .accessibilityLabel("Debug logs")
                .accessibilityHint("Opens debug log viewer")
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
                    .accessibilityLabel("Refresh")
                    .accessibilityHint("Refreshes today's session data")
                }
            }
        }
    }

    // Simplified session content - just cards and Start Workout button
    @ViewBuilder
    private var sessionContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Enrolled Programs Section (only shows if user has enrolled programs)
                if enrolledProgramsViewModel.hasEnrolledPrograms {
                    TodayEnrolledProgramsSection(
                        enrolledPrograms: enrolledProgramsViewModel.enrolledPrograms,
                        activeEnrollmentCount: enrolledProgramsViewModel.activeEnrollmentCount,
                        isLoading: enrolledProgramsViewModel.isLoading,
                        currentWeek: { enrolledProgramsViewModel.currentWeek(for: $0) },
                        progressPercentage: { enrolledProgramsViewModel.progressPercentage(for: $0) },
                        daysRemainingDisplay: { enrolledProgramsViewModel.daysRemainingDisplay(for: $0) }
                    )
                }

                // Today's completed workouts counter
                if viewModel.completedTodayCount > 0 {
                    CompletedWorkoutsSection(
                        completedCount: viewModel.completedTodayCount,
                        completedWorkouts: viewModel.todaysCompletedWorkouts
                    )
                }

                // Readiness Section
                ReadinessStatusCard(
                    todayReadiness: todayReadiness,
                    isLoading: isLoadingReadiness,
                    onCheckIn: { showReadinessCheckIn = true },
                    onShowDashboard: { showReadinessDashboard = true }
                )

                // ACP-522: Arm Care Section (for baseball/throwing athletes)
                ArmCareStatusCard(
                    todayArmCare: todayArmCare,
                    isLoading: isLoadingArmCare,
                    onCheckIn: { showArmCareAssessment = true },
                    onShowDetails: { showArmCareAssessment = true }
                )

                // Recovery Intelligence: Readiness-Based Workout Recommendation
                if let adaptation = workoutAdaptation {
                    ReadinessWorkoutRecommendationCard(
                        adaptation: adaptation,
                        onViewRecoveryProtocol: { showRecoveryProtocol = true },
                        onViewInsights: { showReadinessInsights = true },
                        onStartAlternative: { alternative in
                            // TODO: Start alternative workout from template
                            DebugLogger.shared.log("Starting alternative workout: \(alternative.name)")
                        }
                    )
                } else if isLoadingAdaptation {
                    ReadinessWorkoutRecommendationCard.loadingPlaceholder
                }

                // Prescribed Workouts from Therapist
                if isLoadingPrescriptions || !pendingPrescriptions.isEmpty {
                    PrescribedWorkoutsCard(
                        prescriptions: pendingPrescriptions,
                        isLoading: isLoadingPrescriptions,
                        onStartPrescription: { prescription in
                            Task {
                                await startPrescribedWorkout(prescription)
                            }
                        },
                        onViewAll: {
                            // Could navigate to a full prescription list view if needed
                        }
                    )
                }

                // Session Card with Start Workout
                if let session = viewModel.session {
                    if session.isCompleted {
                        SessionCompletedView(
                            session: session,
                            onBrowseLibrary: { showTemplateLibrary = true },
                            onCreateCustomWorkout: { showWorkoutCreator = true },
                            onViewSummary: { completedSession = viewModel.session }
                        )
                    } else {
                        TodayWorkoutCard(
                            session: session,
                            exercises: viewModel.exercises,
                            onStartWorkout: startWorkout,
                            onRefresh: { await viewModel.refresh() },
                            onExerciseSelected: { exercise in
                                selectedExercise = exercise
                            }
                        )
                    }
                }

                Spacer()
            }
            .padding()
        }
    }



    // MARK: - Start Workout Section with Running Clock

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
                    .cornerRadius(DesignTokens.cornerRadiusMedium)
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
                .cornerRadius(DesignTokens.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Workout Timing Helpers

    private var elapsedTimeFormatted: String {
        guard let startTime = sessionStartTime else { return "00:00:00" }
        let elapsed = currentTime.timeIntervalSince(startTime)
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func startWorkout() {
        // Haptic feedback for starting workout
        HapticFeedback.medium()
        // Launch unified workout execution view
        showUnifiedWorkoutExecution = true
        DebugLogger.shared.log("Launching unified workout execution view")
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
        .cornerRadius(DesignTokens.cornerRadiusMedium)
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

    @ViewBuilder
    private var noSessionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("No Prescribed Session Today")
                .font(.headline)

            Text("Great job staying on track! You can rest today, or start a manual workout from the library if you're feeling motivated.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.spacingXLarge)

            Button {
                HapticFeedback.light()
                showTemplateLibrary = true
            } label: {
                Label("Browse Workout Library", systemImage: "books.vertical")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignTokens.spacingXLarge)
                    .padding(.vertical, DesignTokens.spacingMedium)
                    .background(Color.blue)
                    .cornerRadius(DesignTokens.cornerRadiusMedium)
            }
            .padding(.top, 8)
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

        // Pass session start time to completion
        let startTime = sessionStartTime ?? Date() // Fallback to current time if not captured
        let result = await viewModel.completeSession(startedAt: startTime)

        switch result {
        case .success(let session):
            // sheet(item:) shows automatically when completedSession is set
            completedSession = session
            isCompletingSession = false
        case .failure(let error):
            isCompletingSession = false
            completionError = UserFriendlyError.logAndMessage(for: error, context: "Session completion")
        }
    }

    // MARK: - Readiness Data Loading

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

    // MARK: - ACP-522: Arm Care Data Loading

    private func loadTodayArmCare() async {
        guard let userId = appState.userId,
              let patientId = UUID(uuidString: userId) else {
            return
        }

        isLoadingArmCare = true
        defer { isLoadingArmCare = false }

        do {
            let armCareService = ArmCareAssessmentService()
            todayArmCare = try await armCareService.getTodayAssessment(for: patientId)
            DebugLogger.shared.log("Loaded today's arm care: \(todayArmCare != nil ? "YES" : "NO")")
        } catch {
            // Silently fail - just means no assessment today
            DebugLogger.shared.log("No arm care assessment for today: \(error.localizedDescription)")
            todayArmCare = nil
        }
    }

    // MARK: - Recovery Intelligence: Workout Adaptation Loading

    private func loadWorkoutAdaptation() async {
        guard let userId = appState.userId,
              let patientId = UUID(uuidString: userId) else {
            return
        }

        isLoadingAdaptation = true
        defer { isLoadingAdaptation = false }

        do {
            let adaptationService = WorkoutAdaptationService.shared
            workoutAdaptation = try await adaptationService.getWorkoutAdaptation(for: patientId)
            DebugLogger.shared.log("Loaded workout adaptation: \(workoutAdaptation?.recommendationType.displayName ?? "none")")
        } catch {
            DebugLogger.shared.log("Failed to load workout adaptation: \(error.localizedDescription)", level: .warning)
            workoutAdaptation = nil
        }
    }

    // MARK: - Prescription Loading

    private func loadPendingPrescriptions() async {
        guard let userId = appState.userId,
              let patientId = UUID(uuidString: userId) else {
            return
        }

        isLoadingPrescriptions = true
        defer { isLoadingPrescriptions = false }

        do {
            let prescriptionService = WorkoutPrescriptionService()
            pendingPrescriptions = try await prescriptionService.fetchMyPrescriptions(patientId: patientId)
            DebugLogger.shared.log("Loaded \(pendingPrescriptions.count) pending prescriptions")

            // Mark prescriptions as viewed if any are pending
            for prescription in pendingPrescriptions where prescription.status == .pending {
                try? await prescriptionService.markAsViewed(prescription.id)
            }
        } catch {
            DebugLogger.shared.log("Failed to load prescriptions: \(error.localizedDescription)", level: .warning)
            pendingPrescriptions = []
        }
    }

    // MARK: - Starting Prescribed Workouts

    private func startPrescribedWorkout(_ prescription: WorkoutPrescription) async {
        guard let userId = appState.userId,
              let patientUUID = UUID(uuidString: userId) else {
            DebugLogger.shared.log("Invalid patient ID for prescribed workout", level: .error)
            return
        }

        isCreatingManualSession = true
        defer { isCreatingManualSession = false }

        let service = ManualWorkoutService()
        let prescriptionService = WorkoutPrescriptionService()

        do {
            DebugLogger.shared.log("Creating session from prescription: \(prescription.name)", level: .diagnostic)

            // 1. Create manual session with prescribed source
            let session = try await service.createManualSession(
                name: prescription.name,
                patientId: patientUUID,
                sourceTemplateId: prescription.templateId,
                sourceTemplateType: prescription.templateType == "system" ? .system : .patient,
                assignedByUserId: prescription.therapistId,
                sessionSource: .prescribed
            )

            DebugLogger.shared.log("Prescribed session created: \(session.id)", level: .success)

            // 2. If there's a template, load exercises from it
            if let templateId = prescription.templateId {
                try await loadExercisesFromTemplate(
                    templateId: templateId,
                    templateType: prescription.templateType,
                    sessionId: session.id,
                    service: service
                )
            }

            // 3. Mark prescription as started and link the session
            try await prescriptionService.markAsStarted(prescription.id, sessionId: session.id)

            // 4. Start the workout
            let startedSession = try await service.startWorkout(session.id)

            // 5. Store prescription for completion tracking and trigger workout execution
            await MainActor.run {
                selectedPrescription = prescription
                createdManualSession = startedSession
                DebugLogger.shared.log("Prescribed workout ready, launching execution view", level: .success)
            }

        } catch {
            DebugLogger.shared.log("Failed to start prescribed workout: \(error)", level: .error)
            await MainActor.run {
                selectedPrescription = nil
                createdManualSession = nil
            }
        }
    }

    /// Load exercises from a template and add them to the session
    private func loadExercisesFromTemplate(
        templateId: UUID,
        templateType: String?,
        sessionId: UUID,
        service: ManualWorkoutService
    ) async throws {
        let logger = DebugLogger.shared

        // Fetch the template based on type
        if templateType == "system" {
            let templates = try await service.fetchSystemTemplates()
            guard let template = templates.first(where: { $0.id == templateId }) else {
                logger.log("System template not found: \(templateId)", level: .warning)
                return
            }

            // Add exercises from template blocks
            var sequence = 0
            for block in template.blocks {
                for exercise in block.exercises {
                    let input = AddManualSessionExerciseInput(
                        manualSessionId: sessionId,
                        exerciseTemplateId: nil,
                        exerciseName: exercise.name,
                        blockName: block.name,
                        sequence: sequence,
                        targetSets: exercise.sets,
                        targetReps: exercise.reps,
                        targetLoad: nil,
                        loadUnit: nil,
                        restPeriodSeconds: nil,
                        notes: exercise.notes
                    )
                    _ = try await service.addExercise(to: sessionId, exercise: input)
                    sequence += 1
                }
            }
            logger.log("Added \(sequence) exercises from system template", level: .success)
        } else {
            // Patient template
            guard let patientId = appState.userId,
                  let patientUUID = UUID(uuidString: patientId) else { return }

            let templates = try await service.fetchPatientTemplates(patientId: patientUUID)
            guard let template = templates.first(where: { $0.id == templateId }) else {
                logger.log("Patient template not found: \(templateId)", level: .warning)
                return
            }

            // Add exercises from template blocks
            var sequence = 0
            for block in template.blocks {
                for exercise in block.exercises {
                    let input = AddManualSessionExerciseInput(
                        manualSessionId: sessionId,
                        exerciseTemplateId: nil,
                        exerciseName: exercise.name,
                        blockName: block.name,
                        sequence: sequence,
                        targetSets: exercise.sets,
                        targetReps: exercise.reps,
                        targetLoad: nil,
                        loadUnit: nil,
                        restPeriodSeconds: nil,
                        notes: exercise.notes
                    )
                    _ = try await service.addExercise(to: sessionId, exercise: input)
                    sequence += 1
                }
            }
            logger.log("Added \(sequence) exercises from patient template", level: .success)
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

            // 1. Create the manual session (chosen = self-selected from library)
            let session = try await service.createManualSession(
                name: template.name,
                patientId: patientUUID,
                sourceTemplateId: template.id,
                sourceTemplateType: template.isSystemTemplate ? .system : .patient,
                sessionSource: .chosen
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

// MARK: - ReadinessService Extension

extension ReadinessService {
    /// Fetch today's readiness check-in for a patient (UUID version)
    /// - Parameter patientId: The patient's UUID
    /// - Returns: Today's readiness record, or nil if not found
    func fetchTodayReadiness(for patientId: UUID) async throws -> DailyReadiness? {
        return try await getTodayReadiness(for: patientId)
    }
}

