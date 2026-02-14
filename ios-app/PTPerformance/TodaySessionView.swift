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

    // ACP-MODE: Mode-specific dashboard navigation
    @StateObject private var modeService = ModeService.shared
    @State private var showRehabDashboard = false
    @State private var showStrengthDashboard = false
    @State private var showPerformanceDashboard = false
    @StateObject private var modeStatusVM = ModeStatusCardViewModel()

    // Recovery Intelligence state
    @State private var workoutAdaptation: WorkoutAdaptation?
    @State private var isLoadingAdaptation = false
    @State private var showRecoveryProtocol = false
    @State private var showReadinessInsights = false

    // Adaptive Training: Workout Modifications
    @StateObject private var adaptiveWorkoutVM = AdaptiveWorkoutViewModel()
    @State private var showModificationSheet = false

    // Prescribed workouts state
    @State private var pendingPrescriptions: [WorkoutPrescription] = []
    @State private var isLoadingPrescriptions = false
    @State private var selectedPrescription: WorkoutPrescription?

    // Scroll animation state
    @State private var scrollOffset: CGFloat = 0

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme

    // Shared service instances to avoid re-instantiating on every call
    private let readinessServiceInstance = ReadinessService()
    private let armCareService = ArmCareAssessmentService()

    // Exercise state management
    @State private var completedExercises: [UUID: Bool] = [:]
    @State private var expandedExercises: [UUID: Bool] = [:]

    // Explicit workout session tracking
    @State private var sessionStartTime: Date?
    @State private var isWorkoutStarted = false

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

    // Error handling state
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    var shouldUseSplitView: Bool {
        DeviceHelper.shouldUseSplitView(horizontalSizeClass: horizontalSizeClass)
    }

    /// Safely convert a patient ID string to UUID, returning nil if invalid
    private func validPatientUUID(_ patientId: String) -> UUID? {
        UUID(uuidString: patientId)
    }

    var body: some View {
        Group {
            if shouldUseSplitView {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .springSheet(isPresented: $showDebugLogs) {
            DebugLogView()
        }
        // Use sheet(item:) pattern to prevent black screen when session is nil
        .springSheet(item: $completedSession) { session in
            SessionSummaryView(session: session)
                .environmentObject(appState)
        }
        .springSheet(isPresented: $showReadinessCheckIn, onDismiss: {
            // Reload readiness data after check-in submission
            Task {
                await loadTodayReadiness()
                // Adaptive Training: Check if modification should be generated
                await adaptiveWorkoutVM.checkForModificationAfterReadiness()
                if adaptiveWorkoutVM.todayModification != nil {
                    showModificationSheet = true
                }
            }
        }) {
            if let patientId = appState.userId, let uuid = validPatientUUID(patientId) {
                ReadinessCheckInView(patientId: uuid)
            }
        }
        .springSheet(isPresented: $showReadinessDashboard) {
            if let patientId = appState.userId, let uuid = validPatientUUID(patientId) {
                NavigationStack {
                    ReadinessDashboardView(patientId: uuid)
                }
            }
        }
        // ACP-522: Arm Care Assessment sheet
        .springSheet(isPresented: $showArmCareAssessment, onDismiss: {
            Task {
                await loadTodayArmCare()
            }
        }) {
            if let patientId = appState.userId, let uuid = validPatientUUID(patientId) {
                ArmCareAssessmentView(patientId: uuid)
            }
        }
        // Adaptive Training: Modification suggestion sheet
        .springSheet(isPresented: $showModificationSheet) {
            if let modification = adaptiveWorkoutVM.todayModification {
                NavigationStack {
                    ScrollView {
                        WorkoutModificationCard(
                            modification: modification,
                            onAccept: {
                                Task {
                                    await adaptiveWorkoutVM.acceptModification(modification)
                                }
                            },
                            onDecline: {
                                Task {
                                    await adaptiveWorkoutVM.declineModification(modification)
                                }
                            }
                        )
                        .padding()
                    }
                    .navigationTitle("Workout Adjustment")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Dismiss") {
                                showModificationSheet = false
                            }
                        }
                    }
                }
            }
        }
        // Recovery Intelligence sheets
        .springSheet(isPresented: $showRecoveryProtocol) {
            if let patientId = appState.userId, let uuid = validPatientUUID(patientId) {
                NavigationStack {
                    RecoveryProtocolView(patientId: uuid)
                }
            }
        }
        .springSheet(isPresented: $showReadinessInsights) {
            if let patientId = appState.userId, let uuid = validPatientUUID(patientId) {
                NavigationStack {
                    ReadinessInsightsView(patientId: uuid)
                }
            }
        }
        // ACP-MODE: Mode-specific dashboard sheets
        .springSheet(isPresented: $showRehabDashboard) {
            NavigationStack {
                RehabModeDashboardView()
                    .environmentObject(appState)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showRehabDashboard = false
                            }
                        }
                    }
            }
        }
        .springSheet(isPresented: $showStrengthDashboard) {
            if let patientId = appState.userId, let uuid = validPatientUUID(patientId) {
                NavigationStack {
                    StrengthModeDashboardView(patientId: uuid)
                        .environmentObject(appState)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showStrengthDashboard = false
                                }
                            }
                        }
                }
            }
        }
        .springSheet(isPresented: $showPerformanceDashboard) {
            if let patientId = appState.userId, let uuid = validPatientUUID(patientId) {
                NavigationStack {
                    PerformanceModeDashboardView(patientId: uuid)
                        .environmentObject(appState)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showPerformanceDashboard = false
                                }
                            }
                        }
                }
            }
        }
        // Manual Workout Sheets
        .springSheet(isPresented: $showTemplateLibrary) {
            if let patientId = appState.userId, let uuid = validPatientUUID(patientId) {
                NavigationStack {
                    WorkoutTemplateLibraryView(
                        patientId: uuid,
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
        .springSheet(isPresented: $showWorkoutCreator) {
            if let patientId = appState.userId, let uuid = validPatientUUID(patientId) {
                NavigationStack {
                    ManualWorkoutCreatorView(
                        patientId: uuid
                    )
                }
            }
        }
        // Add exercise to today's session picker
        .springSheet(isPresented: $showAddToTodayPicker) {
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
            if let patientId = appState.userId, let uuid = validPatientUUID(patientId) {
                ManualWorkoutExecutionView(
                    session: session,
                    patientId: uuid,
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
            if let session = viewModel.session, let patientId = appState.userId, let uuid = validPatientUUID(patientId) {
                ManualWorkoutExecutionView(
                    prescribedSession: session,
                    exercises: viewModel.exercises,
                    patientId: uuid,
                    onComplete: {
                        showUnifiedWorkoutExecution = false
                        isWorkoutStarted = false
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
            // Configure adaptive workout VM with patient ID
            if let userId = appState.userId,
               let patientId = validPatientUUID(userId) {
                adaptiveWorkoutVM.configure(patientId: patientId)
            }

            // Parallelize all independent data loads
            // Capture main-actor state before parallel dispatch
            let shouldLoadMode = appState.userId.flatMap { validPatientUUID($0) }
            let shouldFetchSession = viewModel.session == nil && !viewModel.isLoading

            async let a: () = {
                if let patientId = shouldLoadMode {
                    await modeStatusVM.loadData(for: patientId)
                }
            }()
            async let b: () = {
                if shouldFetchSession {
                    await viewModel.fetchTodaySession()
                }
            }()
            async let c: () = loadTodayReadiness()
            async let d: () = loadTodayArmCare()
            async let e: () = enrolledProgramsViewModel.loadEnrolledPrograms()
            async let f: () = loadPendingPrescriptions()
            async let g: () = loadWorkoutAdaptation()
            async let h: () = adaptiveWorkoutVM.loadPendingModifications()
            _ = await (a, b, c, d, e, f, g, h)

            // If readiness exists but no pending modification, check if one should be generated
            if todayReadiness != nil && !adaptiveWorkoutVM.hasTodayModification {
                await adaptiveWorkoutVM.checkForModificationAfterReadiness()
            }
        }
        .onDisappear {
            // Cleanup when view disappears
        }
        // Adaptive Training: Sync VM's showModificationSheet with local state
        .onChange(of: adaptiveWorkoutVM.showModificationSheet) { _, newValue in
            if newValue {
                showModificationSheet = true
                adaptiveWorkoutVM.showModificationSheet = false
            }
        }
        // Also sync success toast and dismiss sheet on accept/decline
        .onChange(of: adaptiveWorkoutVM.showSuccessToast) { _, newValue in
            if newValue {
                showModificationSheet = false
            }
        }
        // Adaptive Training: Success alert for modification acceptance
        .alert("Workout Updated", isPresented: $adaptiveWorkoutVM.showSuccessToast) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(adaptiveWorkoutVM.successMessage)
        }
        // Error alert for mode integration operations
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unexpected error occurred.")
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
                        .refreshableWithHaptic {
                            await viewModel.refresh()
                        }
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
    // Uses scroll-triggered micro-animations for enhanced visual feedback
    // Combines parallax hero section with staggered card entrance animations
    @ViewBuilder
    private var sessionContent: some View {
        ScrollTrackingContainer(scrollOffset: $scrollOffset) {
            VStack(alignment: .leading, spacing: 20) {
                // Daily Check-in Prompt Card - hero section with parallax depth effect
                CheckInPromptCard()
                    .parallax(scrollOffset: scrollOffset, intensity: 0.15)
                    .scaleOnScroll(scrollOffset: scrollOffset, minScale: 0.98)
                    .staggeredAnimation(index: 0)

                // ACP-MODE: Mode-specific status card with dashboard navigation
                modeStatusCard
                    .staggeredAnimation(index: 1)

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
                    .staggeredAnimation(index: 2)
                }

                // Today's completed workouts counter
                if viewModel.completedTodayCount > 0 {
                    CompletedWorkoutsSection(
                        completedCount: viewModel.completedTodayCount,
                        completedWorkouts: viewModel.todaysCompletedWorkouts
                    )
                    .staggeredAnimation(index: 3)
                }

                // Readiness Section
                ReadinessStatusCard(
                    todayReadiness: todayReadiness,
                    isLoading: isLoadingReadiness,
                    onCheckIn: { showReadinessCheckIn = true },
                    onShowDashboard: { showReadinessDashboard = true }
                )
                .staggeredAnimation(index: 4)

                // ACP-522: Arm Care Section (for baseball/throwing athletes)
                ArmCareStatusCard(
                    todayArmCare: todayArmCare,
                    isLoading: isLoadingArmCare,
                    onCheckIn: { showArmCareAssessment = true },
                    onShowDetails: { showArmCareAssessment = true }
                )
                .staggeredAnimation(index: 5)

                // Adaptive Training: Workout Modification Suggestion
                if adaptiveWorkoutVM.hasTodayModification, let modification = adaptiveWorkoutVM.todayModification {
                    WorkoutModificationCardCompact(
                        modification: modification,
                        onTap: {
                            HapticFeedback.light()
                            showModificationSheet = true
                        }
                    )
                    .staggeredAnimation(index: 6)
                } else if adaptiveWorkoutVM.isLoading {
                    // Loading placeholder for modification check
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Checking for workout adjustments...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .staggeredAnimation(index: 6)
                }

                // Recovery Intelligence: Readiness-Based Workout Recommendation
                if let adaptation = workoutAdaptation {
                    ReadinessWorkoutRecommendationCard(
                        adaptation: adaptation,
                        onViewRecoveryProtocol: { showRecoveryProtocol = true },
                        onViewInsights: { showReadinessInsights = true },
                        onStartAlternative: { alternative in
                            guard let patientId = appState.userId else { return }
                            Task {
                                await startAlternativeWorkout(alternative, patientId: patientId)
                            }
                        }
                    )
                    .staggeredAnimation(index: 7)
                } else if isLoadingAdaptation {
                    ReadinessWorkoutRecommendationCard.loadingPlaceholder
                        .staggeredAnimation(index: 7)
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
                    .staggeredAnimation(index: 8)
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
                        .staggeredAnimation(index: 9)
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
                        .staggeredAnimation(index: 9)
                    }
                }

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - ACP-MODE: Mode Status Card (extracted to TodayModeStatusCard.swift)

    /// Convenience wrapper that wires up the extracted `TodayModeStatusCard`
    /// with this view's state and action bindings.
    private var modeStatusCard: some View {
        TodayModeStatusCard(
            currentMode: modeService.currentMode,
            modeStatusVM: modeStatusVM,
            hasUserId: appState.userId != nil,
            onShowRehabDashboard: { showRehabDashboard = true },
            onShowStrengthDashboard: { showStrengthDashboard = true },
            onShowPerformanceDashboard: { showPerformanceDashboard = true },
            onShowReadinessCheckIn: { showReadinessCheckIn = true }
        )
    }

    // MARK: - Workout Timing Helpers

    private func startWorkout() {
        // Haptic feedback for starting workout
        HapticFeedback.medium()
        // Launch unified workout execution view
        showUnifiedWorkoutExecution = true
        DebugLogger.shared.log("Launching unified workout execution view")
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
        ScrollView {
            VStack(spacing: 20) {
                // Daily Check-in Prompt Card - always show for better discoverability
                CheckInPromptCard()
                    .padding(.horizontal)

                // ACP-MODE: Mode-specific status card with dashboard navigation
                modeStatusCard
                    .padding(.horizontal)

                // Show completed workouts even when no prescribed session
                if viewModel.completedTodayCount > 0 {
                    CompletedWorkoutsSection(
                        completedCount: viewModel.completedTodayCount,
                        completedWorkouts: viewModel.todaysCompletedWorkouts
                    )
                    .padding(.bottom, 8)
                }

                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 64))
                    .foregroundColor(.green)

                Text("No Prescribed Session Today")
                    .font(.headline)

                Text("Great job staying on track! You can rest today, or start a manual workout from the library if you're feeling motivated.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)

                Button {
                    HapticFeedback.light()
                    showTemplateLibrary = true
                } label: {
                    Label("Browse Workout Library", systemImage: "books.vertical")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.modusCyan)
                        .cornerRadius(CornerRadius.md)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .refreshableWithHaptic {
            await viewModel.refresh()
        }
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
            todayReadiness = try await readinessServiceInstance.fetchTodayReadiness(for: patientId)
            DebugLogger.shared.log("[READINESS] Loaded today's readiness: \(todayReadiness != nil ? "YES" : "NO")")
        } catch {
            // Silently fail - just means no check-in today
            DebugLogger.shared.log("[READINESS] No readiness check-in for today: \(error.localizedDescription)")
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
        guard let userId = appState.userId else {
            DebugLogger.shared.log("No user ID available for prescribed workout", level: .error)
            await MainActor.run {
                errorMessage = "Unable to start workout: You must be signed in."
                showErrorAlert = true
            }
            return
        }

        guard let patientUUID = UUID(uuidString: userId) else {
            DebugLogger.shared.log("Invalid patient ID format for prescribed workout: \(userId)", level: .error)
            await MainActor.run {
                errorMessage = "Unable to start workout: Invalid user ID format. Please sign out and sign back in."
                showErrorAlert = true
            }
            return
        }

        isCreatingManualSession = true
        defer { isCreatingManualSession = false }

        let service = ManualWorkoutService()
        let prescriptionService = WorkoutPrescriptionService()

        do {
            DebugLogger.shared.log("Creating session from prescription: \(prescription.name)", level: .diagnostic)

            // 1. Create manual session with prescribed source
            // Note: sourceTemplateType must only be set if sourceTemplateId is set (database constraint)
            let templateType: SourceTemplateType? = prescription.templateId != nil
                ? (prescription.templateType == "system" ? .system : .patient)
                : nil

            let session = try await service.createManualSession(
                name: prescription.name,
                patientId: patientUUID,
                sourceTemplateId: prescription.templateId,
                sourceTemplateType: templateType,
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

        do {
            // Fetch the template based on type
            if templateType == "system" {
                let templates = try await service.fetchSystemTemplates()
                guard let template = templates.first(where: { $0.id == templateId }) else {
                    logger.log("System template not found: \(templateId)", level: .warning)
                    await MainActor.run {
                        errorMessage = "Workout template not found. The workout may have been deleted."
                        showErrorAlert = true
                    }
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
                guard let patientId = appState.userId else {
                    logger.log("No patient ID available for loading template", level: .error)
                    await MainActor.run {
                        errorMessage = "Unable to load workout: You must be signed in."
                        showErrorAlert = true
                    }
                    return
                }

                guard let patientUUID = UUID(uuidString: patientId) else {
                    logger.log("Invalid patient ID format: \(patientId)", level: .error)
                    await MainActor.run {
                        errorMessage = "Unable to load workout: Invalid user ID format. Please sign out and sign back in."
                        showErrorAlert = true
                    }
                    return
                }

                let templates = try await service.fetchPatientTemplates(patientId: patientUUID)
                guard let template = templates.first(where: { $0.id == templateId }) else {
                    logger.log("Patient template not found: \(templateId)", level: .warning)
                    await MainActor.run {
                        errorMessage = "Workout template not found. The workout may have been deleted."
                        showErrorAlert = true
                    }
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
        } catch {
            logger.log("Failed to load exercises from template: \(error.localizedDescription)", level: .error)
            await MainActor.run {
                errorMessage = "Failed to load workout exercises: \(error.localizedDescription)"
                showErrorAlert = true
            }
            throw error
        }
    }

    // MARK: - Alternative Workout from Readiness Recommendation

    /// Start an alternative workout recommended based on readiness state
    /// These are dynamically generated recovery workouts (mobility, yoga, walking, etc.)
    private func startAlternativeWorkout(_ alternative: AlternativeWorkout, patientId: String) async {
        guard let patientUUID = UUID(uuidString: patientId) else {
            DebugLogger.shared.log("Invalid patient ID for alternative workout", level: .error)
            return
        }

        isCreatingManualSession = true
        defer { isCreatingManualSession = false }

        let service = ManualWorkoutService()

        do {
            DebugLogger.shared.log("Creating alternative workout session: \(alternative.name)", level: .diagnostic)

            // Create a manual session for this alternative workout
            // Uses .chosen source since user selected this from readiness recommendations
            let session = try await service.createManualSession(
                name: alternative.name,
                patientId: patientUUID,
                sourceTemplateId: nil,  // Alternative workouts are dynamically generated
                sourceTemplateType: nil,
                sessionSource: .chosen
            )

            DebugLogger.shared.log("Alternative workout session created: \(session.id)", level: .success)

            // Add a single exercise entry for the alternative workout
            // These are typically single-activity sessions (yoga, walking, mobility flow)
            let input = AddManualSessionExerciseInput(
                manualSessionId: session.id,
                exerciseTemplateId: nil,
                exerciseName: alternative.name,
                blockName: alternative.type.displayName,
                sequence: 0,
                targetSets: 1,
                targetReps: nil,
                targetLoad: nil,
                loadUnit: nil,
                restPeriodSeconds: nil,
                notes: "\(alternative.description)\n\nDuration: \(alternative.duration) minutes\nIntensity: \(alternative.intensity.displayName)"
            )
            _ = try await service.addExercise(to: session.id, exercise: input)

            // Start the workout
            let startedSession = try await service.startWorkout(session.id)

            DebugLogger.shared.log("Starting alternative workout execution: \(startedSession.id)", level: .success)
            await MainActor.run {
                createdManualSession = startedSession
            }

        } catch {
            DebugLogger.shared.log("Failed to create alternative workout: \(error)", level: .error)
            await MainActor.run {
                createdManualSession = nil
            }
        }
    }

    // MARK: - Manual Workout Creation from Template

    private func createManualSessionFromTemplate(_ template: AnyWorkoutTemplate, patientId: String) async {
        guard let patientUUID = UUID(uuidString: patientId) else {
            DebugLogger.shared.log("[TEMPLATE] Invalid patient ID for manual workout", level: .error)
            return
        }

        isCreatingManualSession = true
        defer { isCreatingManualSession = false }

        let service = ManualWorkoutService()

        do {
            DebugLogger.shared.log("[TEMPLATE] Creating manual session from template: \(template.name)", level: .diagnostic)

            // 1. Create the manual session (chosen = self-selected from library)
            let session = try await service.createManualSession(
                name: template.name,
                patientId: patientUUID,
                sourceTemplateId: template.id,
                sourceTemplateType: template.isSystemTemplate ? .system : .patient,
                sessionSource: .chosen
            )

            DebugLogger.shared.log("[SESSION] Manual session created: \(session.id)", level: .success)

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

            DebugLogger.shared.log("[TEMPLATE] Added \(sequence) exercises to session", level: .success)

            // 3. Start the workout
            let startedSession = try await service.startWorkout(session.id)

            // 4. Store the session - fullScreenCover(item:) will present automatically
            DebugLogger.shared.log("[SESSION] Setting createdManualSession to trigger fullScreenCover: \(startedSession.id)", level: .success)
            await MainActor.run {
                createdManualSession = startedSession
                DebugLogger.shared.log("[SESSION] createdManualSession set, fullScreenCover should present", level: .diagnostic)
            }

        } catch {
            DebugLogger.shared.log("[SESSION] Failed to create manual session: \(error)", level: .error)
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

