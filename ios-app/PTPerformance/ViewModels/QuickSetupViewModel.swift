//
//  QuickSetupViewModel.swift
//  PTPerformance
//
//  ACP-1035: Streamlined Quick Setup — Progressive Disclosure
//  Reduced from 6 steps to 4: Welcome -> Mode -> Goals -> Complete
//  Readiness check-in and therapist linking are deferred to later in-app
//

import SwiftUI
import Combine

/// View model managing the Quick Setup onboarding flow
@MainActor
class QuickSetupViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentStep: SetupStep = .welcome
    @Published var isLoading = false
    @Published var error: String?
    @Published var isComplete = false

    // Mode selection
    @Published var selectedMode: Mode = .strength

    // Goals
    @Published var selectedGoals: Set<QuickGoalTemplate> = []

    // MARK: - Services

    private let supabase = PTSupabaseClient.shared
    private let modeService = ModeService.shared
    private let onboardingCoordinator = OnboardingCoordinator.shared

    // Cached patient ID (fetched from user_id)
    private var cachedPatientId: UUID?

    /// Whether the user arrived via quick-start (skipped onboarding)
    var quickStarted: Bool {
        onboardingCoordinator.quickStarted
    }

    // MARK: - Patient ID Helper

    /// Response struct for patient ID query
    private struct PatientIdResponse: Decodable {
        let id: String
    }

    /// Struct for creating a new patient record
    private struct PatientInsert: Encodable {
        let userId: String
        let email: String
        let firstName: String
        let lastName: String
        let sport: String
        let mode: String

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case email
            case firstName = "first_name"
            case lastName = "last_name"
            case sport
            case mode
        }
    }

    /// Fetch the patient's database ID from the user's auth ID, creating a record if needed
    private func getPatientId() async throws -> UUID {
        if let cached = cachedPatientId {
            return cached
        }

        guard let authUserId = supabase.authUserId else {
            throw NSError(domain: "QuickSetup", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])
        }

        // First try to fetch existing patient
        let response = try await supabase.client
            .from("patients")
            .select("id")
            .eq("user_id", value: authUserId)
            .execute()

        let decoder = JSONDecoder()

        // Check if we got results
        if let patients = try? decoder.decode([PatientIdResponse].self, from: response.data),
           let firstPatient = patients.first,
           let patientId = UUID(uuidString: firstPatient.id) {
            cachedPatientId = patientId
            return patientId
        }

        // No patient record exists - create one
        let patientId = try await createPatientRecord(userId: authUserId)
        cachedPatientId = patientId
        return patientId
    }

    /// Create a new patient record for the user
    private func createPatientRecord(userId: String) async throws -> UUID {
        // Get user email from auth
        let userEmail = supabase.client.auth.currentUser?.email ?? "unknown@example.com"

        // Parse name from email or use defaults
        let emailName = userEmail.components(separatedBy: "@").first ?? "User"
        let nameParts = emailName.components(separatedBy: ".")
        let firstName = nameParts.first?.capitalized ?? "New"
        let lastName = nameParts.count > 1 ? nameParts.last?.capitalized ?? "User" : "User"

        let patientInsert = PatientInsert(
            userId: userId,
            email: userEmail.lowercased(),
            firstName: firstName,
            lastName: lastName,
            sport: "General Fitness",
            mode: selectedMode.rawValue
        )

        let response = try await supabase.client
            .from("patients")
            .insert(patientInsert)
            .select("id")
            .single()
            .execute()

        let decoder = JSONDecoder()
        let patient = try decoder.decode(PatientIdResponse.self, from: response.data)

        guard let patientId = UUID(uuidString: patient.id) else {
            throw NSError(domain: "QuickSetup", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid patient ID"])
        }

        DebugLogger.shared.log("[QuickSetup] Created patient record: \(patientId)", level: .success)

        return patientId
    }

    // MARK: - Setup Steps (ACP-1035: Reduced)

    enum SetupStep: Int, CaseIterable {
        case welcome = 0
        case modeSelection = 1
        case goalSelection = 2
        case complete = 3

        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .modeSelection: return "Choose Your Mode"
            case .goalSelection: return "Set Your Goals"
            case .complete: return "You're All Set!"
            }
        }

        var subtitle: String {
            switch self {
            case .welcome: return "Two quick choices and you're in"
            case .modeSelection: return "This helps us personalize your experience"
            case .goalSelection: return "What do you want to achieve?"
            case .complete: return "Your personalized dashboard is ready"
            }
        }
    }

    // MARK: - Goal Templates

    struct QuickGoalTemplate: Hashable, Identifiable {
        let id = UUID()
        let title: String
        let category: GoalCategory
        let description: String
        let targetValue: Double
        let unit: String
        let modes: Set<Mode>  // Which modes this goal is relevant for

        var icon: String { category.icon }
        var color: Color { category.color }
    }

    /// Predefined goal templates based on mode
    let goalTemplates: [QuickGoalTemplate] = [
        // Rehab goals
        QuickGoalTemplate(
            title: "Reduce Pain",
            category: .painReduction,
            description: "Decrease pain levels during daily activities",
            targetValue: 2,
            unit: "pain scale",
            modes: [.rehab]
        ),
        QuickGoalTemplate(
            title: "Improve Mobility",
            category: .mobility,
            description: "Increase range of motion and flexibility",
            targetValue: 100,
            unit: "percent",
            modes: [.rehab, .performance]
        ),
        QuickGoalTemplate(
            title: "Return to Activity",
            category: .rehabilitation,
            description: "Safely return to full activity",
            targetValue: 100,
            unit: "percent",
            modes: [.rehab]
        ),

        // Strength goals
        QuickGoalTemplate(
            title: "Build Strength",
            category: .strength,
            description: "Increase overall strength and muscle",
            targetValue: 100,
            unit: "percent",
            modes: [.strength, .performance]
        ),
        QuickGoalTemplate(
            title: "Improve Endurance",
            category: .endurance,
            description: "Build cardiovascular fitness and stamina",
            targetValue: 100,
            unit: "percent",
            modes: [.strength]
        ),
        QuickGoalTemplate(
            title: "Body Recomposition",
            category: .bodyComposition,
            description: "Improve body composition and fitness",
            targetValue: 100,
            unit: "percent",
            modes: [.strength]
        ),

        // Performance goals
        QuickGoalTemplate(
            title: "Peak Performance",
            category: .strength,
            description: "Optimize athletic performance",
            targetValue: 100,
            unit: "percent",
            modes: [.performance]
        ),
        QuickGoalTemplate(
            title: "Recovery Optimization",
            category: .rehabilitation,
            description: "Maximize recovery between sessions",
            targetValue: 100,
            unit: "percent",
            modes: [.performance]
        ),
        QuickGoalTemplate(
            title: "Sport-Specific",
            category: .custom,
            description: "Excel in your sport",
            targetValue: 100,
            unit: "percent",
            modes: [.performance]
        )
    ]

    /// Goals filtered for the selected mode
    var availableGoals: [QuickGoalTemplate] {
        goalTemplates.filter { $0.modes.contains(selectedMode) }
    }

    // MARK: - Navigation

    var canGoBack: Bool {
        currentStep.rawValue > SetupStep.welcome.rawValue && currentStep != .complete
    }

    var canContinue: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .modeSelection:
            return true  // Mode has a default
        case .goalSelection:
            return !selectedGoals.isEmpty
        case .complete:
            return true
        }
    }

    var continueButtonText: String {
        switch currentStep {
        case .welcome:
            return "Get Started"
        case .modeSelection:
            return "Continue"
        case .goalSelection:
            return "Finish Setup"
        case .complete:
            return "Go to Dashboard"
        }
    }

    func goToNextStep() {
        guard let nextIndex = SetupStep.allCases.firstIndex(where: { $0.rawValue == currentStep.rawValue + 1 }) else {
            return
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = SetupStep.allCases[nextIndex]
        }
    }

    func goToPreviousStep() {
        guard currentStep.rawValue > 0,
              let prevIndex = SetupStep.allCases.firstIndex(where: { $0.rawValue == currentStep.rawValue - 1 }) else {
            return
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = SetupStep.allCases[prevIndex]
        }
    }

    // MARK: - Actions

    /// Handle continue button tap — saves data and advances
    func handleContinue() async {
        error = nil

        switch currentStep {
        case .welcome:
            goToNextStep()

        case .modeSelection:
            await saveMode()

        case .goalSelection:
            await saveGoalsAndFinalize()

        case .complete:
            isComplete = true
        }
    }

    /// ACP-1035: Handle "Skip for Now" — save what we have, skip remaining
    func handleSkipForNow() async {
        error = nil

        // If we have a mode selected and we're past mode selection, save it
        if currentStep.rawValue >= SetupStep.modeSelection.rawValue {
            // Try to save mode silently
            await saveModeQuietly()
        }

        // Mark as complete with deferred flag
        await finalizeSetup()

        // Jump to complete
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .complete
        }

        ErrorLogger.shared.logUserAction(
            action: "quick_setup_skipped",
            properties: ["skipped_at_step": currentStep.rawValue]
        )
    }

    // MARK: - Save Functions

    private func saveMode() async {
        isLoading = true
        defer { isLoading = false }

        guard let authUserId = supabase.authUserId else {
            error = "Not logged in"
            return
        }

        do {
            // Update patient mode using auth user_id
            try await supabase.client
                .from("patients")
                .update(["mode": selectedMode.rawValue])
                .eq("user_id", value: authUserId)
                .execute()

            // Reload mode in service
            await modeService.loadPatientMode()

            goToNextStep()
        } catch {
            self.error = "Failed to save mode: \(error.localizedDescription)"
        }
    }

    /// Save mode without blocking or showing errors (for skip scenarios)
    private func saveModeQuietly() async {
        guard let authUserId = supabase.authUserId else { return }

        do {
            try await supabase.client
                .from("patients")
                .update(["mode": selectedMode.rawValue])
                .eq("user_id", value: authUserId)
                .execute()

            await modeService.loadPatientMode()
        } catch {
            DebugLogger.shared.log("[QuickSetup] Silent mode save failed: \(error.localizedDescription)", level: .warning)
        }
    }

    /// ACP-1035: Combined save goals + finalize (no more readiness/therapist steps)
    private func saveGoalsAndFinalize() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch the actual patient ID from user_id
            let patientId = try await getPatientId()

            // Create goals from selected templates
            let goalsToInsert = selectedGoals.map { template in
                PatientGoalInsert(
                    patientId: patientId,
                    title: template.title,
                    description: template.description,
                    category: template.category,
                    targetValue: template.targetValue,
                    currentValue: 0,
                    unit: template.unit,
                    targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
                    status: .active
                )
            }

            // Insert all goals
            for goal in goalsToInsert {
                try await supabase.client
                    .from("patient_goals")
                    .insert(goal)
                    .execute()
            }

            await finalizeSetup()
            goToNextStep()
        } catch {
            self.error = "Failed to save goals: \(error.localizedDescription)"
        }
    }

    private func finalizeSetup() async {
        // Mark setup as complete in user defaults
        UserDefaults.standard.set(true, forKey: "hasCompletedQuickSetup")

        // ACP-1035: Mark deferred setup as pending (readiness, therapist link)
        onboardingCoordinator.deferredSetupPending = true
    }

    // MARK: - Check if Setup Needed

    /// Check if the user needs to complete Quick Setup
    static func needsQuickSetup() -> Bool {
        // Check if already completed
        if UserDefaults.standard.bool(forKey: "hasCompletedQuickSetup") {
            return false
        }

        // Check if user is logged in
        guard PTSupabaseClient.shared.userId != nil else {
            return false
        }

        return true
    }

    /// Reset quick setup (for testing)
    static func resetQuickSetup() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedQuickSetup")
    }
}
