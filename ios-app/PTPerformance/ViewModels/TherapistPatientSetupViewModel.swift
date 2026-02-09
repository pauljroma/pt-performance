//
//  TherapistPatientSetupViewModel.swift
//  PTPerformance
//
//  Patient setup flow for therapists - configure new patients with mode, goals, and context
//

import SwiftUI
import Combine

/// View model managing the therapist patient setup flow
@MainActor
class TherapistPatientSetupViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentStep: SetupStep = .basicInfo
    @Published var isLoading = false
    @Published var error: String?
    @Published var isComplete = false
    @Published var createdPatientId: UUID?
    @Published var linkingCode: String?

    // Basic info
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var sport: String = ""
    @Published var position: String = ""
    @Published var injuryType: String = ""
    @Published var targetLevel: String = "Recreational"

    // Mode selection
    @Published var selectedMode: Mode = .rehab

    // Goals
    @Published var selectedGoals: Set<PatientGoalTemplate> = []
    @Published var customGoalTitle: String = ""
    @Published var customGoalDescription: String = ""

    // Training context
    @Published var trainingNotes: String = ""
    @Published var weeklyFrequency: Int = 3
    @Published var sessionDuration: Int = 45
    @Published var restrictions: String = ""
    @Published var precautions: String = ""

    // MARK: - Services

    private let supabase = PTSupabaseClient.shared

    // MARK: - Setup Steps

    enum SetupStep: Int, CaseIterable {
        case basicInfo = 0
        case modeSelection = 1
        case goalSelection = 2
        case trainingContext = 3
        case review = 4
        case complete = 5

        var title: String {
            switch self {
            case .basicInfo: return "Patient Information"
            case .modeSelection: return "Training Mode"
            case .goalSelection: return "Set Goals"
            case .trainingContext: return "Training Plan"
            case .review: return "Review & Create"
            case .complete: return "Patient Created"
            }
        }

        var subtitle: String {
            switch self {
            case .basicInfo: return "Enter the patient's details"
            case .modeSelection: return "Choose their training focus"
            case .goalSelection: return "Define what they're working toward"
            case .trainingContext: return "Set expectations and restrictions"
            case .review: return "Confirm patient setup"
            case .complete: return "Share the linking code with your patient"
            }
        }
    }

    // MARK: - Goal Templates

    struct PatientGoalTemplate: Hashable, Identifiable {
        let id = UUID()
        let title: String
        let category: GoalCategory
        let description: String
        let defaultTarget: Double
        let unit: String
        let modes: Set<Mode>

        var icon: String { category.icon }
        var color: Color { category.color }
    }

    /// Goal templates organized by mode
    let goalTemplates: [PatientGoalTemplate] = [
        // Rehab goals
        PatientGoalTemplate(
            title: "Pain-Free Movement",
            category: .painReduction,
            description: "Achieve pain-free range of motion",
            defaultTarget: 0,
            unit: "pain scale",
            modes: [.rehab]
        ),
        PatientGoalTemplate(
            title: "Restore ROM",
            category: .mobility,
            description: "Return to full range of motion",
            defaultTarget: 100,
            unit: "percent of normal",
            modes: [.rehab]
        ),
        PatientGoalTemplate(
            title: "Return to Activity",
            category: .rehabilitation,
            description: "Safe return to sport/activity",
            defaultTarget: 100,
            unit: "percent",
            modes: [.rehab]
        ),
        PatientGoalTemplate(
            title: "Rebuild Strength",
            category: .strength,
            description: "Restore pre-injury strength levels",
            defaultTarget: 100,
            unit: "percent",
            modes: [.rehab]
        ),
        PatientGoalTemplate(
            title: "Improve Function",
            category: .rehabilitation,
            description: "Return to daily activities without limitation",
            defaultTarget: 100,
            unit: "percent",
            modes: [.rehab]
        ),

        // Strength goals
        PatientGoalTemplate(
            title: "Build Muscle",
            category: .strength,
            description: "Increase muscle mass and definition",
            defaultTarget: 100,
            unit: "percent",
            modes: [.strength]
        ),
        PatientGoalTemplate(
            title: "Increase Strength",
            category: .strength,
            description: "Improve overall strength capacity",
            defaultTarget: 100,
            unit: "percent",
            modes: [.strength]
        ),
        PatientGoalTemplate(
            title: "Improve Conditioning",
            category: .endurance,
            description: "Build cardiovascular and muscular endurance",
            defaultTarget: 100,
            unit: "percent",
            modes: [.strength]
        ),
        PatientGoalTemplate(
            title: "Body Recomposition",
            category: .bodyComposition,
            description: "Reduce body fat and increase lean mass",
            defaultTarget: 100,
            unit: "percent",
            modes: [.strength]
        ),
        PatientGoalTemplate(
            title: "Improve Mobility",
            category: .mobility,
            description: "Increase flexibility and joint range",
            defaultTarget: 100,
            unit: "percent",
            modes: [.strength]
        ),

        // Performance goals
        PatientGoalTemplate(
            title: "Peak Performance",
            category: .strength,
            description: "Optimize sport-specific performance",
            defaultTarget: 100,
            unit: "percent",
            modes: [.performance]
        ),
        PatientGoalTemplate(
            title: "Speed & Power",
            category: .strength,
            description: "Develop explosive athletic qualities",
            defaultTarget: 100,
            unit: "percent",
            modes: [.performance]
        ),
        PatientGoalTemplate(
            title: "Sport-Specific Skills",
            category: .custom,
            description: "Improve sport-specific movement patterns",
            defaultTarget: 100,
            unit: "percent",
            modes: [.performance]
        ),
        PatientGoalTemplate(
            title: "Injury Prevention",
            category: .rehabilitation,
            description: "Reduce injury risk through prehab",
            defaultTarget: 100,
            unit: "percent",
            modes: [.performance]
        ),
        PatientGoalTemplate(
            title: "Recovery Optimization",
            category: .rehabilitation,
            description: "Maximize recovery between sessions",
            defaultTarget: 100,
            unit: "percent",
            modes: [.performance]
        )
    ]

    /// Goals filtered for the selected mode
    var availableGoals: [PatientGoalTemplate] {
        goalTemplates.filter { $0.modes.contains(selectedMode) }
    }

    // MARK: - Target Level Options

    let targetLevelOptions = [
        "Recreational",
        "High School",
        "College",
        "Semi-Pro",
        "Professional",
        "Elite/Olympic"
    ]

    // MARK: - Common Sports

    let commonSports = [
        "Baseball",
        "Basketball",
        "CrossFit",
        "Football",
        "Golf",
        "Hockey",
        "Lacrosse",
        "Running",
        "Soccer",
        "Softball",
        "Swimming",
        "Tennis",
        "Track & Field",
        "Volleyball",
        "Weightlifting",
        "Wrestling",
        "General Fitness",
        "Other"
    ]

    // MARK: - Validation

    var isBasicInfoValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        (email.isEmpty || email.contains("@"))
    }

    var canContinue: Bool {
        switch currentStep {
        case .basicInfo:
            return isBasicInfoValid
        case .modeSelection:
            return true
        case .goalSelection:
            return !selectedGoals.isEmpty
        case .trainingContext:
            return true
        case .review:
            return true
        case .complete:
            return true
        }
    }

    var canGoBack: Bool {
        currentStep.rawValue > SetupStep.basicInfo.rawValue && currentStep != .complete
    }

    var continueButtonText: String {
        switch currentStep {
        case .review:
            return "Create Patient"
        case .complete:
            return "Done"
        default:
            return "Continue"
        }
    }

    // MARK: - Navigation

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

    func handleContinue() async {
        error = nil

        switch currentStep {
        case .basicInfo, .modeSelection, .goalSelection, .trainingContext:
            goToNextStep()

        case .review:
            await createPatient()

        case .complete:
            isComplete = true
        }
    }

    // MARK: - Create Patient

    private func createPatient() async {
        isLoading = true
        defer { isLoading = false }

        guard let therapistId = supabase.userId else {
            error = "Not logged in"
            return
        }

        do {
            // 1. Create patient record
            let patientInsert = PatientInsert(
                therapistId: therapistId,
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces),
                email: email.isEmpty ? nil : email.lowercased().trimmingCharacters(in: .whitespaces),
                sport: sport.isEmpty ? nil : sport,
                position: position.isEmpty ? nil : position,
                injuryType: injuryType.isEmpty ? nil : injuryType,
                targetLevel: targetLevel,
                mode: selectedMode.rawValue
            )

            let patientResponse = try await supabase.client
                .from("patients")
                .insert(patientInsert)
                .select("id")
                .single()
                .execute()

            let decoder = JSONDecoder()
            let createdPatient = try decoder.decode(PatientIdResponse.self, from: patientResponse.data)
            guard let patientId = UUID(uuidString: createdPatient.id) else {
                self.error = "Invalid patient ID format returned from server"
                return
            }
            self.createdPatientId = patientId

            // 2. Create goals
            await createGoals(for: patientId)

            // 3. Create training notes if provided
            if !trainingNotes.isEmpty || !restrictions.isEmpty || !precautions.isEmpty {
                await createTherapistNotes(for: patientId)
            }

            // 4. Generate linking code
            await generateLinkingCode(for: patientId)

            goToNextStep()
        } catch {
            self.error = "Failed to create patient: \(error.localizedDescription)"
        }
    }

    private func createGoals(for patientId: UUID) async {
        let targetDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())

        for template in selectedGoals {
            let goalInsert = PatientGoalInsert(
                patientId: patientId,
                title: template.title,
                description: template.description,
                category: template.category,
                targetValue: template.defaultTarget,
                currentValue: 0,
                unit: template.unit,
                targetDate: targetDate,
                status: .active
            )

            do {
                try await supabase.client
                    .from("patient_goals")
                    .insert(goalInsert)
                    .execute()
            } catch {
                #if DEBUG
                print("⚠️ Failed to create goal: \(error)")
                #endif
            }
        }

        // Add custom goal if provided
        if !customGoalTitle.isEmpty {
            let customGoal = PatientGoalInsert(
                patientId: patientId,
                title: customGoalTitle,
                description: customGoalDescription.isEmpty ? nil : customGoalDescription,
                category: .custom,
                targetValue: 100,
                currentValue: 0,
                unit: "percent",
                targetDate: targetDate,
                status: .active
            )

            do {
                try await supabase.client
                    .from("patient_goals")
                    .insert(customGoal)
                    .execute()
            } catch {
                #if DEBUG
                print("⚠️ Failed to create custom goal: \(error)")
                #endif
            }
        }
    }

    private func createTherapistNotes(for patientId: UUID) async {
        guard let therapistId = supabase.userId else { return }

        // Build notes content
        var notesContent = ""

        if !trainingNotes.isEmpty {
            notesContent += "**Training Plan:**\n\(trainingNotes)\n\n"
        }

        notesContent += "**Frequency:** \(weeklyFrequency)x per week\n"
        notesContent += "**Session Duration:** \(sessionDuration) minutes\n\n"

        if !restrictions.isEmpty {
            notesContent += "**Restrictions:**\n\(restrictions)\n\n"
        }

        if !precautions.isEmpty {
            notesContent += "**Precautions:**\n\(precautions)\n\n"
        }

        let noteInsert = TherapistNoteInsert(
            patientId: patientId.uuidString,
            therapistId: therapistId,
            noteType: "initial_setup",
            content: notesContent,
            isPinned: true
        )

        do {
            try await supabase.client
                .from("therapist_notes")
                .insert(noteInsert)
                .execute()
        } catch {
            #if DEBUG
            print("⚠️ Failed to create therapist notes: \(error)")
            #endif
        }
    }

    private func generateLinkingCode(for patientId: UUID) async {
        // Generate a secure 8-character code
        let code = generateSecureCode()

        guard let expirationDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) else {
            #if DEBUG
            print("Failed to calculate expiration date for linking code")
            #endif
            return
        }

        let codeInsert = LinkingCodeInsert(
            patientId: patientId.uuidString,
            code: code,
            expiresAt: expirationDate
        )

        do {
            try await supabase.client
                .from("linking_codes")
                .insert(codeInsert)
                .execute()

            self.linkingCode = code
        } catch {
            #if DEBUG
            print("⚠️ Failed to generate linking code: \(error)")
            #endif
            // Still show success, code can be generated later
        }
    }

    private func generateSecureCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        var code = ""
        var randomBytes = [UInt8](repeating: 0, count: 8)
        _ = SecRandomCopyBytes(kSecRandomDefault, 8, &randomBytes)

        for byte in randomBytes {
            let index = Int(byte) % chars.count
            code.append(chars[chars.index(chars.startIndex, offsetBy: index)])
        }

        return code
    }

    // MARK: - Copy Linking Code

    func copyLinkingCode() {
        guard let code = linkingCode else { return }
        UIPasteboard.general.string = code
    }

    // MARK: - Summary Text

    var summaryText: String {
        var lines: [String] = []

        lines.append("**Patient:** \(firstName) \(lastName)")
        if !email.isEmpty { lines.append("**Email:** \(email)") }
        if !sport.isEmpty { lines.append("**Sport:** \(sport)") }
        if !position.isEmpty { lines.append("**Position:** \(position)") }
        if !injuryType.isEmpty { lines.append("**Injury:** \(injuryType)") }
        lines.append("**Level:** \(targetLevel)")
        lines.append("")
        lines.append("**Mode:** \(selectedMode.displayName)")
        lines.append("")
        lines.append("**Goals:**")
        for goal in selectedGoals {
            lines.append("• \(goal.title)")
        }
        if !customGoalTitle.isEmpty {
            lines.append("• \(customGoalTitle) (custom)")
        }
        lines.append("")
        lines.append("**Training:** \(weeklyFrequency)x/week, \(sessionDuration) min sessions")

        return lines.joined(separator: "\n")
    }
}

// MARK: - Encodable Structs

private struct PatientInsert: Encodable {
    let therapistId: String
    let firstName: String
    let lastName: String
    let email: String?
    let sport: String?
    let position: String?
    let injuryType: String?
    let targetLevel: String
    let mode: String

    enum CodingKeys: String, CodingKey {
        case therapistId = "therapist_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case sport
        case position
        case injuryType = "injury_type"
        case targetLevel = "target_level"
        case mode
    }
}

private struct PatientIdResponse: Decodable {
    let id: String
}

private struct TherapistNoteInsert: Encodable {
    let patientId: String
    let therapistId: String
    let noteType: String
    let content: String
    let isPinned: Bool

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case noteType = "note_type"
        case content
        case isPinned = "is_pinned"
    }
}

private struct LinkingCodeInsert: Encodable {
    let patientId: String
    let code: String
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case code
        case expiresAt = "expires_at"
    }
}
