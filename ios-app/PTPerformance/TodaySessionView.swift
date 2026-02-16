import SwiftUI

// MARK: - Sheet Type Enums

/// Represents all sheets presented from TodaySessionView using `.springSheet(item:)`.
/// Each case maps to a distinct modal presentation. Associated values carry data
/// needed to build the destination view.
enum TodaySessionSheet: Identifiable {
    case debugLogs
    case sessionSummary(Session)
    case readinessCheckIn
    case readinessDashboard
    case armCareAssessment
    case modificationSuggestion
    case recoveryProtocol
    case readinessInsights
    case rehabDashboard
    case strengthDashboard
    case performanceDashboard
    case templateLibrary
    case workoutCreator
    case addToTodayPicker

    var id: String {
        switch self {
        case .debugLogs: return "debugLogs"
        case .sessionSummary(let session): return "sessionSummary-\(session.id)"
        case .readinessCheckIn: return "readinessCheckIn"
        case .readinessDashboard: return "readinessDashboard"
        case .armCareAssessment: return "armCareAssessment"
        case .modificationSuggestion: return "modificationSuggestion"
        case .recoveryProtocol: return "recoveryProtocol"
        case .readinessInsights: return "readinessInsights"
        case .rehabDashboard: return "rehabDashboard"
        case .strengthDashboard: return "strengthDashboard"
        case .performanceDashboard: return "performanceDashboard"
        case .templateLibrary: return "templateLibrary"
        case .workoutCreator: return "workoutCreator"
        case .addToTodayPicker: return "addToTodayPicker"
        }
    }
}

/// Represents all full-screen covers presented from TodaySessionView.
/// Kept separate from `TodaySessionSheet` because SwiftUI requires distinct
/// `.sheet(item:)` and `.fullScreenCover(item:)` modifiers.
enum TodaySessionFullScreenCover: Identifiable {
    case manualWorkoutExecution(ManualSession)
    case unifiedWorkoutExecution

    var id: String {
        switch self {
        case .manualWorkoutExecution(let session): return "manualWorkout-\(session.id)"
        case .unifiedWorkoutExecution: return "unifiedWorkout"
        }
    }
}

// MARK: - TodaySessionViewState

/// Consolidates the remaining @State properties and data-loading / action methods
/// that were previously scattered across TodaySessionView.  Sheet-presentation
/// enums (`activeSheet`, `activeFullScreenCover`, `lastActiveSheet`) remain as
/// @State in the view because they drive SwiftUI sheet modifiers directly.
@MainActor
class TodaySessionViewState: ObservableObject {

    // MARK: - UI Interaction State

    @Published var selectedExercise: Exercise?
    @Published var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @Published var scrollOffset: CGFloat = 0

    // Exercise state management
    @Published var completedExercises: [UUID: Bool] = [:]
    @Published var expandedExercises: [UUID: Bool] = [:]

    // MARK: - Session Completion State

    @Published var isCompletingSession = false
    @Published var completionError: String?

    // MARK: - Readiness State

    @Published var todayReadiness: DailyReadiness?
    @Published var isLoadingReadiness = false

    // MARK: - ACP-522: Arm Care Assessment State

    @Published var todayArmCare: ArmCareAssessment?
    @Published var isLoadingArmCare = false

    // MARK: - Recovery Intelligence State

    @Published var workoutAdaptation: WorkoutAdaptation?
    @Published var isLoadingAdaptation = false

    // MARK: - Prescribed Workouts State

    @Published var pendingPrescriptions: [WorkoutPrescription] = []
    @Published var isLoadingPrescriptions = false
    @Published var selectedPrescription: WorkoutPrescription?

    // MARK: - Workout Execution State

    @Published var sessionStartTime: Date?
    @Published var isWorkoutStarted = false

    // MARK: - Manual Workout Navigation

    @Published var selectedWorkoutTemplate: AnyWorkoutTemplate?
    @Published var isCreatingManualSession = false

    // MARK: - Error Handling State

    @Published var errorMessage: String?
    @Published var showErrorAlert = false

    // MARK: - Service Instances

    /// Shared service instances to avoid re-instantiating on every call
    let readinessServiceInstance = ReadinessService()
    let armCareService = ArmCareAssessmentService()

    // MARK: - Helpers

    /// Safely convert a patient ID string to UUID, returning nil if invalid
    func validPatientUUID(_ patientId: String) -> UUID? {
        UUID(uuidString: patientId)
    }

    // MARK: - Session Completion

    func handleCompleteSession(
        sessionVM: TodaySessionViewModel,
        onSuccess: @escaping (Session) -> Void
    ) async {
        isCompletingSession = true
        completionError = nil

        // Pass session start time to completion
        let startTime = sessionStartTime ?? Date() // Fallback to current time if not captured
        let result = await sessionVM.completeSession(startedAt: startTime)

        switch result {
        case .success(let session):
            onSuccess(session)
            isCompletingSession = false
        case .failure(let error):
            isCompletingSession = false
            completionError = UserFriendlyError.logAndMessage(for: error, context: "Session completion")
        }
    }

    // MARK: - Readiness Data Loading

    func loadTodayReadiness(userId: String?) async {
        guard let userId = userId,
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

    func loadTodayArmCare(userId: String?) async {
        guard let userId = userId,
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

    func loadWorkoutAdaptation(userId: String?) async {
        guard let userId = userId,
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

    func loadPendingPrescriptions(userId: String?) async {
        guard let userId = userId,
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

    func startPrescribedWorkout(
        _ prescription: WorkoutPrescription,
        userId: String?,
        onPresent: @escaping (TodaySessionFullScreenCover) -> Void,
        onDismiss: @escaping () -> Void
    ) async {
        guard let userId = userId else {
            DebugLogger.shared.log("No user ID available for prescribed workout", level: .error)
            errorMessage = "Unable to start workout: You must be signed in."
            showErrorAlert = true
            return
        }

        guard let patientUUID = UUID(uuidString: userId) else {
            DebugLogger.shared.log("Invalid patient ID format for prescribed workout: \(userId)", level: .error)
            errorMessage = "Unable to start workout: Invalid user ID format. Please sign out and sign back in."
            showErrorAlert = true
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
                    service: service,
                    userId: userId
                )
            }

            // 3. Mark prescription as started and link the session
            try await prescriptionService.markAsStarted(prescription.id, sessionId: session.id)

            // 4. Start the workout
            let startedSession = try await service.startWorkout(session.id)

            // 5. Store prescription for completion tracking and trigger workout execution
            selectedPrescription = prescription
            onPresent(.manualWorkoutExecution(startedSession))
            DebugLogger.shared.log("Prescribed workout ready, launching execution view", level: .success)

        } catch {
            DebugLogger.shared.log("Failed to start prescribed workout: \(error)", level: .error)
            selectedPrescription = nil
            onDismiss()
        }
    }

    /// Load exercises from a template and add them to the session
    func loadExercisesFromTemplate(
        templateId: UUID,
        templateType: String?,
        sessionId: UUID,
        service: ManualWorkoutService,
        userId: String?
    ) async throws {
        let logger = DebugLogger.shared

        do {
            // Fetch the template based on type
            if templateType == "system" {
                let templates = try await service.fetchSystemTemplates()
                guard let template = templates.first(where: { $0.id == templateId }) else {
                    logger.log("System template not found: \(templateId)", level: .warning)
                    errorMessage = "Workout template not found. The workout may have been deleted."
                    showErrorAlert = true
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
                guard let patientId = userId else {
                    logger.log("No patient ID available for loading template", level: .error)
                    errorMessage = "Unable to load workout: You must be signed in."
                    showErrorAlert = true
                    return
                }

                guard let patientUUID = UUID(uuidString: patientId) else {
                    logger.log("Invalid patient ID format: \(patientId)", level: .error)
                    errorMessage = "Unable to load workout: Invalid user ID format. Please sign out and sign back in."
                    showErrorAlert = true
                    return
                }

                let templates = try await service.fetchPatientTemplates(patientId: patientUUID)
                guard let template = templates.first(where: { $0.id == templateId }) else {
                    logger.log("Patient template not found: \(templateId)", level: .warning)
                    errorMessage = "Workout template not found. The workout may have been deleted."
                    showErrorAlert = true
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
            errorMessage = "Failed to load workout exercises: \(error.localizedDescription)"
            showErrorAlert = true
            throw error
        }
    }

    // MARK: - Alternative Workout from Readiness Recommendation

    /// Start an alternative workout recommended based on readiness state
    /// These are dynamically generated recovery workouts (mobility, yoga, walking, etc.)
    func startAlternativeWorkout(
        _ alternative: AlternativeWorkout,
        patientId: String,
        onPresent: @escaping (TodaySessionFullScreenCover) -> Void,
        onDismiss: @escaping () -> Void
    ) async {
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
            onPresent(.manualWorkoutExecution(startedSession))

        } catch {
            DebugLogger.shared.log("Failed to create alternative workout: \(error)", level: .error)
            onDismiss()
        }
    }

    // MARK: - Manual Workout Creation from Template

    func createManualSessionFromTemplate(
        _ template: AnyWorkoutTemplate,
        patientId: String,
        onPresent: @escaping (TodaySessionFullScreenCover) -> Void,
        onDismiss: @escaping () -> Void
    ) async {
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
            DebugLogger.shared.log("[SESSION] Setting activeFullScreenCover to trigger fullScreenCover: \(startedSession.id)", level: .success)
            onPresent(.manualWorkoutExecution(startedSession))
            DebugLogger.shared.log("[SESSION] activeFullScreenCover set, fullScreenCover should present", level: .diagnostic)

        } catch {
            DebugLogger.shared.log("[SESSION] Failed to create manual session: \(error)", level: .error)
            // Ensure cover is nil so fullScreenCover doesn't present
            onDismiss()
        }
    }
}

// MARK: - TodaySessionView

struct TodaySessionView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var supabase: PTSupabaseClient
    @StateObject private var viewModel = TodaySessionViewModel()
    @StateObject private var viewState = TodaySessionViewState()
    @StateObject private var enrolledProgramsViewModel = EnrolledProgramsViewModel()

    // Consolidated sheet state (replaces individual showXxx booleans)
    @State private var activeSheet: TodaySessionSheet?
    @State private var activeFullScreenCover: TodaySessionFullScreenCover?

    // ACP-MODE: Mode-specific dashboard navigation
    @EnvironmentObject private var modeService: ModeService
    @StateObject private var modeStatusVM = ModeStatusCardViewModel()

    // Adaptive Training: Workout Modifications
    @StateObject private var adaptiveWorkoutVM = AdaptiveWorkoutViewModel()

    // Tracks the last non-nil activeSheet so onDismiss can perform case-specific cleanup
    @State private var lastActiveSheet: TodaySessionSheet?

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme

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
        // MARK: - Consolidated Sheet Presentation
        .springSheet(item: $activeSheet, onDismiss: handleSheetDismiss) { sheet in
            sheetContent(for: sheet)
        }
        // MARK: - Consolidated Full Screen Cover Presentation
        .fullScreenCover(item: $activeFullScreenCover) { cover in
            fullScreenCoverContent(for: cover)
        }
        .task {
            // Configure adaptive workout VM with patient ID
            if let userId = appState.userId,
               let patientId = viewState.validPatientUUID(userId) {
                adaptiveWorkoutVM.configure(patientId: patientId)
            }

            // Parallelize all independent data loads
            // Capture main-actor state before parallel dispatch
            let shouldLoadMode = appState.userId.flatMap { viewState.validPatientUUID($0) }
            let shouldFetchSession = viewModel.session == nil && !viewModel.isLoading
            let userId = appState.userId

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
            async let c: () = viewState.loadTodayReadiness(userId: userId)
            async let d: () = viewState.loadTodayArmCare(userId: userId)
            async let e: () = enrolledProgramsViewModel.loadEnrolledPrograms()
            async let f: () = viewState.loadPendingPrescriptions(userId: userId)
            async let g: () = viewState.loadWorkoutAdaptation(userId: userId)
            async let h: () = adaptiveWorkoutVM.loadPendingModifications()
            _ = await (a, b, c, d, e, f, g, h)

            // If readiness exists but no pending modification, check if one should be generated
            if viewState.todayReadiness != nil && !adaptiveWorkoutVM.hasTodayModification {
                await adaptiveWorkoutVM.checkForModificationAfterReadiness()
                if adaptiveWorkoutVM.todayModification != nil {
                    activeSheet = .modificationSuggestion
                }
            }
        }
        .onDisappear {
            // Cleanup when view disappears
        }
        // Track the last active sheet so onDismiss can perform case-specific cleanup
        .onChange(of: activeSheet?.id) { oldValue, newValue in
            if let sheet = activeSheet {
                lastActiveSheet = sheet
            }
        }
        // Adaptive Training: Sync VM's showModificationSheet with local state
        .onChange(of: adaptiveWorkoutVM.showModificationSheet) { _, newValue in
            if newValue {
                activeSheet = .modificationSuggestion
                adaptiveWorkoutVM.showModificationSheet = false
            }
        }
        // Also sync success toast and dismiss sheet on accept/decline
        .onChange(of: adaptiveWorkoutVM.showSuccessToast) { _, newValue in
            if newValue {
                // Dismiss modification sheet if it is the active sheet
                if case .modificationSuggestion = activeSheet {
                    activeSheet = nil
                }
            }
        }
        // Adaptive Training: Success alert for modification acceptance
        .alert("Workout Updated", isPresented: $adaptiveWorkoutVM.showSuccessToast) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(adaptiveWorkoutVM.successMessage)
        }
        // Error alert for mode integration operations
        .alert("Error", isPresented: $viewState.showErrorAlert) {
            Button("OK", role: .cancel) {
                viewState.errorMessage = nil
            }
        } message: {
            Text(viewState.errorMessage ?? "An unexpected error occurred.")
        }
    }

    // MARK: - iPad Split View Layout

    private var iPadLayout: some View {
        NavigationSplitView(columnVisibility: $viewState.columnVisibility) {
            exerciseListContent
                .navigationTitle("Today's Session")
                .navigationSplitViewColumnWidth(
                    min: DeviceHelper.sidebarWidth.min,
                    ideal: DeviceHelper.sidebarWidth.ideal,
                    max: DeviceHelper.sidebarWidth.max
                )
        } detail: {
            if let exercise = viewState.selectedExercise {
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
                    onAddToToday: { activeSheet = .addToTodayPicker },
                    onNewWorkout: {
                        activeSheet = .workoutCreator
                    },
                    onFromLibrary: {
                        activeSheet = .templateLibrary
                    }
                )
            }
            // One-Tap Start: Floating start button always visible when session available
            .overlay(alignment: .bottom) {
                if let session = viewModel.session, !session.isCompleted && !viewState.isWorkoutStarted {
                    OneTapStartButton(action: startWorkout)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { activeSheet = .debugLogs }) {
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
        ScrollTrackingContainer(scrollOffset: $viewState.scrollOffset) {
            VStack(alignment: .leading, spacing: 20) {
                // Daily Check-in Prompt Card - hero section with parallax depth effect
                CheckInPromptCard()
                    .parallax(scrollOffset: viewState.scrollOffset, intensity: 0.15)
                    .scaleOnScroll(scrollOffset: viewState.scrollOffset, minScale: 0.98)
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
                    todayReadiness: viewState.todayReadiness,
                    isLoading: viewState.isLoadingReadiness,
                    onCheckIn: { activeSheet = .readinessCheckIn },
                    onShowDashboard: { activeSheet = .readinessDashboard }
                )
                .staggeredAnimation(index: 4)

                // ACP-522: Arm Care Section (for baseball/throwing athletes)
                ArmCareStatusCard(
                    todayArmCare: viewState.todayArmCare,
                    isLoading: viewState.isLoadingArmCare,
                    onCheckIn: { activeSheet = .armCareAssessment },
                    onShowDetails: { activeSheet = .armCareAssessment }
                )
                .staggeredAnimation(index: 5)

                // Adaptive Training: Workout Modification Suggestion
                if adaptiveWorkoutVM.hasTodayModification, let modification = adaptiveWorkoutVM.todayModification {
                    WorkoutModificationCardCompact(
                        modification: modification,
                        onTap: {
                            HapticFeedback.light()
                            activeSheet = .modificationSuggestion
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
                if let adaptation = viewState.workoutAdaptation {
                    ReadinessWorkoutRecommendationCard(
                        adaptation: adaptation,
                        onViewRecoveryProtocol: { activeSheet = .recoveryProtocol },
                        onViewInsights: { activeSheet = .readinessInsights },
                        onStartAlternative: { alternative in
                            guard let patientId = appState.userId else { return }
                            Task {
                                await viewState.startAlternativeWorkout(
                                    alternative,
                                    patientId: patientId,
                                    onPresent: { cover in activeFullScreenCover = cover },
                                    onDismiss: { activeFullScreenCover = nil }
                                )
                            }
                        }
                    )
                    .staggeredAnimation(index: 7)
                } else if viewState.isLoadingAdaptation {
                    ReadinessWorkoutRecommendationCard.loadingPlaceholder
                        .staggeredAnimation(index: 7)
                }

                // Prescribed Workouts from Therapist
                if viewState.isLoadingPrescriptions || !viewState.pendingPrescriptions.isEmpty {
                    PrescribedWorkoutsCard(
                        prescriptions: viewState.pendingPrescriptions,
                        isLoading: viewState.isLoadingPrescriptions,
                        onStartPrescription: { prescription in
                            Task {
                                await viewState.startPrescribedWorkout(
                                    prescription,
                                    userId: appState.userId,
                                    onPresent: { cover in activeFullScreenCover = cover },
                                    onDismiss: { activeFullScreenCover = nil }
                                )
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
                            onBrowseLibrary: { activeSheet = .templateLibrary },
                            onCreateCustomWorkout: { activeSheet = .workoutCreator },
                            onViewSummary: {
                                if let s = viewModel.session {
                                    activeSheet = .sessionSummary(s)
                                }
                            }
                        )
                        .staggeredAnimation(index: 9)
                    } else {
                        TodayWorkoutCard(
                            session: session,
                            exercises: viewModel.exercises,
                            onStartWorkout: startWorkout,
                            onRefresh: { await viewModel.refresh() },
                            onExerciseSelected: { exercise in
                                viewState.selectedExercise = exercise
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
            onShowRehabDashboard: { activeSheet = .rehabDashboard },
            onShowStrengthDashboard: { activeSheet = .strengthDashboard },
            onShowPerformanceDashboard: { activeSheet = .performanceDashboard },
            onShowReadinessCheckIn: { activeSheet = .readinessCheckIn }
        )
    }

    // MARK: - Sheet Content Builders

    /// Builds the view content for each sheet type.
    @ViewBuilder
    private func sheetContent(for sheet: TodaySessionSheet) -> some View {
        switch sheet {
        case .debugLogs:
            DebugLogView()

        case .sessionSummary(let session):
            SessionSummaryView(session: session)
                .environmentObject(appState)

        case .readinessCheckIn:
            if let patientId = appState.userId, let uuid = viewState.validPatientUUID(patientId) {
                ReadinessCheckInView(patientId: uuid)
            }

        case .readinessDashboard:
            if let patientId = appState.userId, let uuid = viewState.validPatientUUID(patientId) {
                NavigationStack {
                    ReadinessDashboardView(patientId: uuid)
                }
            }

        case .armCareAssessment:
            if let patientId = appState.userId, let uuid = viewState.validPatientUUID(patientId) {
                ArmCareAssessmentView(patientId: uuid)
            }

        case .modificationSuggestion:
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
                                activeSheet = nil
                            }
                        }
                    }
                }
            }

        case .recoveryProtocol:
            if let patientId = appState.userId, let uuid = viewState.validPatientUUID(patientId) {
                NavigationStack {
                    RecoveryProtocolView(patientId: uuid)
                }
            }

        case .readinessInsights:
            if let patientId = appState.userId, let uuid = viewState.validPatientUUID(patientId) {
                NavigationStack {
                    ReadinessInsightsView(patientId: uuid)
                }
            }

        case .rehabDashboard:
            NavigationStack {
                RehabModeDashboardView()
                    .environmentObject(appState)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                activeSheet = nil
                            }
                        }
                    }
            }

        case .strengthDashboard:
            if let patientId = appState.userId, let uuid = viewState.validPatientUUID(patientId) {
                NavigationStack {
                    StrengthModeDashboardView(patientId: uuid)
                        .environmentObject(appState)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    activeSheet = nil
                                }
                            }
                        }
                }
            }

        case .performanceDashboard:
            if let patientId = appState.userId, let uuid = viewState.validPatientUUID(patientId) {
                NavigationStack {
                    PerformanceModeDashboardView(patientId: uuid)
                        .environmentObject(appState)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    activeSheet = nil
                                }
                            }
                        }
                }
            }

        case .templateLibrary:
            if let patientId = appState.userId, let uuid = viewState.validPatientUUID(patientId) {
                NavigationStack {
                    WorkoutTemplateLibraryView(
                        patientId: uuid,
                        onStartWorkout: { template in
                            // Store template and trigger session creation
                            viewState.selectedWorkoutTemplate = template
                            activeSheet = nil
                            Task {
                                await viewState.createManualSessionFromTemplate(
                                    template,
                                    patientId: patientId,
                                    onPresent: { cover in activeFullScreenCover = cover },
                                    onDismiss: { activeFullScreenCover = nil }
                                )
                            }
                        }
                    )
                }
            }

        case .workoutCreator:
            if let patientId = appState.userId, let uuid = viewState.validPatientUUID(patientId) {
                NavigationStack {
                    ManualWorkoutCreatorView(
                        patientId: uuid
                    )
                }
            }

        case .addToTodayPicker:
            NavigationStack {
                AddExerciseToTodaySheet(
                    onExerciseAdded: {
                        activeSheet = nil
                        Task { await viewModel.fetchTodaySession() }
                    }
                )
            }
        }
    }

    /// Builds the view content for each full screen cover type.
    @ViewBuilder
    private func fullScreenCoverContent(for cover: TodaySessionFullScreenCover) -> some View {
        switch cover {
        case .manualWorkoutExecution(let session):
            if let patientId = appState.userId, let uuid = viewState.validPatientUUID(patientId) {
                ManualWorkoutExecutionView(
                    session: session,
                    patientId: uuid,
                    onComplete: {
                        // If this was a prescribed workout, mark the prescription as completed
                        if let prescription = viewState.selectedPrescription {
                            Task {
                                let prescriptionService = WorkoutPrescriptionService()
                                try? await prescriptionService.markAsCompleted(prescription.id)
                                await viewState.loadPendingPrescriptions(userId: appState.userId)
                            }
                        }

                        activeFullScreenCover = nil
                        viewState.selectedWorkoutTemplate = nil
                        viewState.selectedPrescription = nil
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

        case .unifiedWorkoutExecution:
            if let session = viewModel.session, let patientId = appState.userId, let uuid = viewState.validPatientUUID(patientId) {
                ManualWorkoutExecutionView(
                    prescribedSession: session,
                    exercises: viewModel.exercises,
                    patientId: uuid,
                    onComplete: {
                        activeFullScreenCover = nil
                        viewState.isWorkoutStarted = false
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
    }

    /// Handles onDismiss for the consolidated sheet, performing case-specific
    /// cleanup based on which sheet was just dismissed.
    private func handleSheetDismiss() {
        guard let dismissed = lastActiveSheet else { return }
        switch dismissed {
        case .readinessCheckIn:
            // Reload readiness data after check-in submission
            Task {
                await viewState.loadTodayReadiness(userId: appState.userId)
                // Adaptive Training: Check if modification should be generated
                await adaptiveWorkoutVM.checkForModificationAfterReadiness()
                if adaptiveWorkoutVM.todayModification != nil {
                    activeSheet = .modificationSuggestion
                }
            }
        case .armCareAssessment:
            Task {
                await viewState.loadTodayArmCare(userId: appState.userId)
            }
        default:
            break
        }
        lastActiveSheet = nil
    }

    // MARK: - Workout Timing Helpers

    private func startWorkout() {
        // Haptic feedback for starting workout
        HapticFeedback.medium()
        // Launch unified workout execution view
        activeFullScreenCover = .unifiedWorkoutExecution
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
                    activeSheet = .templateLibrary
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
        viewState.selectedExercise = exercise

        // On iPad, ensure detail is visible
        if shouldUseSplitView {
            viewState.columnVisibility = .doubleColumn
        }
    }

    // MARK: - Build 33: Session Completion

    private func handleCompleteSession() async {
        await viewState.handleCompleteSession(
            sessionVM: viewModel,
            onSuccess: { session in
                activeSheet = .sessionSummary(session)
            }
        )
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
