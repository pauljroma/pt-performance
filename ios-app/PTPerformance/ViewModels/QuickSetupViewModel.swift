//
//  QuickSetupViewModel.swift
//  PTPerformance
//
//  Quick Setup flow for new users - configures mode, goals, and initial data
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

    // Readiness check-in
    @Published var sleepHours: Double = 7.0
    @Published var sorenessLevel: Int = 3
    @Published var energyLevel: Int = 7
    @Published var stressLevel: Int = 4

    // Therapist linking
    @Published var therapistCode: String = ""
    @Published var hasTherapist = false

    // MARK: - Services

    private let supabase = PTSupabaseClient.shared
    private let modeService = ModeService.shared
    private let readinessService = ReadinessService()
    private let streakService = StreakTrackingService.shared

    // Cached patient ID (fetched from user_id)
    private var cachedPatientId: UUID?

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

        guard let userId = supabase.userId else {
            throw NSError(domain: "QuickSetup", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])
        }

        // First try to fetch existing patient
        let response = try await supabase.client
            .from("patients")
            .select("id")
            .eq("user_id", value: userId)
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
        let patientId = try await createPatientRecord(userId: userId)
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

        #if DEBUG
        print("✅ Created patient record: \(patientId)")
        #endif

        return patientId
    }

    // MARK: - Setup Steps

    enum SetupStep: Int, CaseIterable {
        case welcome = 0
        case modeSelection = 1
        case goalSelection = 2
        case readinessCheckIn = 3
        case therapistLink = 4
        case complete = 5

        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .modeSelection: return "Choose Your Mode"
            case .goalSelection: return "Set Your Goals"
            case .readinessCheckIn: return "How Are You Feeling?"
            case .therapistLink: return "Connect with Therapist"
            case .complete: return "You're All Set!"
            }
        }

        var subtitle: String {
            switch self {
            case .welcome: return "Let's get you set up in 2 minutes"
            case .modeSelection: return "This helps us personalize your experience"
            case .goalSelection: return "What do you want to achieve?"
            case .readinessCheckIn: return "Your daily baseline for training"
            case .therapistLink: return "Optional: Connect for personalized programs"
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
        case .readinessCheckIn:
            return true  // Has defaults
        case .therapistLink:
            return true  // Optional step
        case .complete:
            return true
        }
    }

    var continueButtonText: String {
        switch currentStep {
        case .welcome:
            return "Get Started"
        case .therapistLink:
            return hasTherapist || !therapistCode.isEmpty ? "Link & Finish" : "Skip & Finish"
        case .complete:
            return "Go to Dashboard"
        default:
            return "Continue"
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

    /// Handle continue button tap - saves data and advances
    func handleContinue() async {
        error = nil

        switch currentStep {
        case .welcome:
            goToNextStep()

        case .modeSelection:
            await saveMode()

        case .goalSelection:
            await saveGoals()

        case .readinessCheckIn:
            await saveReadiness()

        case .therapistLink:
            if !therapistCode.isEmpty {
                await linkTherapist()
            } else {
                await finalizeSetup()
            }

        case .complete:
            isComplete = true
        }
    }

    // MARK: - Save Functions

    private func saveMode() async {
        isLoading = true
        defer { isLoading = false }

        guard let userId = supabase.userId else {
            error = "Not logged in"
            return
        }

        do {
            // Update patient mode using user_id (not id)
            try await supabase.client
                .from("patients")
                .update(["mode": selectedMode.rawValue])
                .eq("user_id", value: userId)
                .execute()

            // Reload mode in service
            await modeService.loadPatientMode()

            goToNextStep()
        } catch {
            self.error = "Failed to save mode: \(error.localizedDescription)"
        }
    }

    private func saveGoals() async {
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

            // Insert all goals using the Encodable struct directly
            for goal in goalsToInsert {
                try await supabase.client
                    .from("patient_goals")
                    .insert(goal)
                    .execute()
            }

            goToNextStep()
        } catch {
            self.error = "Failed to save goals: \(error.localizedDescription)"
        }
    }

    private func saveReadiness() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch the actual patient ID from user_id
            let patientId = try await getPatientId()

            // Submit readiness check-in
            _ = try await readinessService.submitReadiness(
                patientId: patientId,
                date: Date(),
                sleepHours: sleepHours,
                sorenessLevel: sorenessLevel,
                energyLevel: energyLevel,
                stressLevel: stressLevel,
                notes: "Initial check-in from Quick Setup"
            )

            // Initialize streak records
            await initializeStreaks(patientId: patientId)

            goToNextStep()
        } catch {
            self.error = "Failed to save readiness: \(error.localizedDescription)"
        }
    }

    /// Encodable struct for streak record initialization
    private struct StreakRecordInsert: Encodable {
        let patientId: String
        let streakType: String
        let currentStreak: Int
        let longestStreak: Int
        let lastActivityDate: String?
        let streakStartDate: String?

        enum CodingKeys: String, CodingKey {
            case patientId = "patient_id"
            case streakType = "streak_type"
            case currentStreak = "current_streak"
            case longestStreak = "longest_streak"
            case lastActivityDate = "last_activity_date"
            case streakStartDate = "streak_start_date"
        }
    }

    private func initializeStreaks(patientId: UUID) async {
        // Create initial streak records if they don't exist
        let streakTypes = ["workout", "arm_care", "combined"]

        for streakType in streakTypes {
            do {
                let streakInsert = StreakRecordInsert(
                    patientId: patientId.uuidString,
                    streakType: streakType,
                    currentStreak: 0,
                    longestStreak: 0,
                    lastActivityDate: nil,
                    streakStartDate: nil
                )

                try await supabase.client
                    .from("streak_records")
                    .upsert(streakInsert, onConflict: "patient_id,streak_type")
                    .execute()
            } catch {
                // Non-fatal - streaks will be created on first activity
                #if DEBUG
                print("⚠️ Could not initialize \(streakType) streak: \(error)")
                #endif
            }
        }
    }

    private func linkTherapist() async {
        isLoading = true
        defer { isLoading = false }

        guard !therapistCode.isEmpty else {
            await finalizeSetup()
            return
        }

        do {
            // Call link-therapist edge function
            _ = try await supabase.client.functions.invoke(
                "link-therapist",
                options: .init(body: ["code": therapistCode.uppercased()])
            )

            hasTherapist = true
            await finalizeSetup()
        } catch {
            self.error = "Invalid code or already used. You can link later from Settings."
            // Still proceed to complete
            await finalizeSetup()
        }
    }

    private func finalizeSetup() async {
        // Mark setup as complete in user defaults
        UserDefaults.standard.set(true, forKey: "hasCompletedQuickSetup")

        goToNextStep()
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
