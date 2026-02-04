//
//  NutritionProfileSetupView.swift
//  PTPerformance
//
//  Modus Nutrition Module - Setup/edit nutrition profile
//  Allows users to input stats for personalized nutrition calculations
//

import SwiftUI

/// View for setting up or editing the user's nutrition profile
struct NutritionProfileSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = NutritionProfileSetupViewModel()

    // Called when profile is saved
    var onSave: (() -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                // Personal Info Section
                personalInfoSection

                // Body Measurements Section
                measurementsSection

                // Activity Level Section
                activityLevelSection

                // Nutrition Goal Section
                goalSection

                // Athlete Type Section
                athleteTypeSection

                // Calculated Results Preview
                if viewModel.showCalculatedResults {
                    calculatedResultsSection
                }
            }
            .navigationTitle("Nutrition Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.saveProfile()
                            if viewModel.saveSuccessful {
                                onSave?()
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isSaving || !viewModel.isValid)
                }
            }
            .task {
                await viewModel.loadProfile()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.error ?? "An error occurred")
            }
        }
    }

    // MARK: - Personal Info Section

    private var personalInfoSection: some View {
        Section {
            // Age Input
            HStack {
                Text("Age")
                Spacer()
                TextField("30", text: $viewModel.ageText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("years")
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Age, \(viewModel.ageText) years")

            // Gender Picker
            Picker("Biological Gender", selection: $viewModel.gender) {
                ForEach(BiologicalGender.allCases) { gender in
                    Text(gender.displayName).tag(gender)
                }
            }
            .accessibilityLabel("Biological gender for metabolic calculations")
        } header: {
            Text("Personal Information")
        } footer: {
            Text("Used for BMR calculation (Mifflin-St Jeor formula)")
        }
    }

    // MARK: - Measurements Section

    private var measurementsSection: some View {
        Section {
            // Weight Input
            HStack {
                Text("Weight")
                Spacer()
                TextField("180", text: $viewModel.weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("lbs")
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Weight, \(viewModel.weightText) pounds")

            // Height Input
            HStack {
                Text("Height")
                Spacer()

                // Feet
                TextField("5", text: $viewModel.heightFeetText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 40)
                Text("ft")
                    .foregroundColor(.secondary)

                // Inches
                TextField("10", text: $viewModel.heightInchesText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 40)
                Text("in")
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Height, \(viewModel.heightFeetText) feet \(viewModel.heightInchesText) inches")
        } header: {
            Text("Body Measurements")
        }
    }

    // MARK: - Activity Level Section

    private var activityLevelSection: some View {
        Section {
            ForEach(ActivityLevel.allCases) { level in
                Button {
                    viewModel.activityLevel = level
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: level.icon)
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text(level.displayName)
                                    .foregroundColor(.primary)
                            }
                            Text(level.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if viewModel.activityLevel == level {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(level.displayName), \(level.description)")
                .accessibilityValue(viewModel.activityLevel == level ? "Selected" : "Not selected")
                .accessibilityAddTraits(viewModel.activityLevel == level ? .isSelected : [])
            }
        } header: {
            Text("Activity Level")
        } footer: {
            Text("Multiplier: \(String(format: "%.2f", viewModel.activityLevel.multiplier))x BMR")
        }
    }

    // MARK: - Goal Section

    private var goalSection: some View {
        Section {
            ForEach(NutritionGoalType.allCases) { goalType in
                Button {
                    viewModel.goal = goalType
                } label: {
                    HStack {
                        Image(systemName: goalType.icon)
                            .foregroundColor(goalType.color)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(goalType.displayName)
                                .foregroundColor(.primary)
                            Text(goalType.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if viewModel.goal == goalType {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(goalType.displayName), \(goalType.description)")
                .accessibilityValue(viewModel.goal == goalType ? "Selected" : "Not selected")
                .accessibilityAddTraits(viewModel.goal == goalType ? .isSelected : [])
            }
        } header: {
            Text("Primary Goal")
        }
    }

    // MARK: - Athlete Type Section

    private var athleteTypeSection: some View {
        Section {
            Picker("Athlete Type", selection: $viewModel.athleteType) {
                ForEach(NutritionGuidelinesData.athleteTypes) { type in
                    Text(type.athleteType).tag(type.athleteType)
                }
            }
            .pickerStyle(.navigationLink)

            if let guidelines = NutritionGuidelinesData.getAthleteTypeNutrition(code: viewModel.athleteType) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Protein:")
                            .foregroundColor(.secondary)
                        Text(guidelines.proteinRangeString)
                    }
                    .font(.caption)

                    HStack {
                        Text("Carb Focus:")
                            .foregroundColor(.secondary)
                        Text(guidelines.carbFocus.displayName)
                    }
                    .font(.caption)

                    HStack {
                        Text("Key Nutrients:")
                            .foregroundColor(.secondary)
                        Text(guidelines.keyNutrients.joined(separator: ", "))
                            .lineLimit(2)
                    }
                    .font(.caption)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Athlete Type")
        } footer: {
            Text("This determines sport-specific nutrition recommendations")
        }
    }

    // MARK: - Calculated Results Section

    private var calculatedResultsSection: some View {
        Section {
            // BMR
            HStack {
                VStack(alignment: .leading) {
                    Text("BMR")
                        .font(.subheadline)
                    Text("Basal Metabolic Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(viewModel.calculatedBMR) cal")
                    .fontWeight(.medium)
            }

            // TDEE
            HStack {
                VStack(alignment: .leading) {
                    Text("TDEE")
                        .font(.subheadline)
                    Text("Maintenance Calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(viewModel.calculatedTDEE) cal")
                    .fontWeight(.medium)
            }

            // Target Calories
            HStack {
                VStack(alignment: .leading) {
                    Text("Target Calories")
                        .font(.subheadline)
                    Text("Based on \(viewModel.goal.displayName) goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(viewModel.calculatedTargetCalories) cal")
                    .fontWeight(.semibold)
                    .foregroundColor(viewModel.goal.color)
            }

            // Macro Targets
            VStack(alignment: .leading, spacing: 8) {
                Text("Macro Targets")
                    .font(.subheadline)

                HStack(spacing: 16) {
                    MacroPreviewPill(
                        name: "Protein",
                        grams: viewModel.calculatedProtein,
                        color: .red
                    )
                    MacroPreviewPill(
                        name: "Carbs",
                        grams: viewModel.calculatedCarbs,
                        color: .blue
                    )
                    MacroPreviewPill(
                        name: "Fat",
                        grams: viewModel.calculatedFat,
                        color: .yellow
                    )
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Calculated Targets")
        } footer: {
            Text("These values update automatically based on your inputs")
        }
    }
}

// MARK: - Macro Preview Pill

private struct MacroPreviewPill: View {
    let name: String
    let grams: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(grams)g")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}

// MARK: - View Model

@MainActor
class NutritionProfileSetupViewModel: ObservableObject {
    // Input fields
    @Published var ageText = "30"
    @Published var weightText = "180"
    @Published var heightFeetText = "5"
    @Published var heightInchesText = "10"
    @Published var gender: BiologicalGender = .male
    @Published var activityLevel: ActivityLevel = .moderate
    @Published var goal: NutritionGoalType = .maintain
    @Published var athleteType = "BASE"

    // State
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    @Published var showError = false
    @Published var saveSuccessful = false

    private let profileService = NutritionProfileService.shared
    private let logger = DebugLogger.shared

    // MARK: - Computed Properties

    var age: Int {
        Int(ageText) ?? 30
    }

    var weightLbs: Double {
        Double(weightText) ?? 180
    }

    var heightInches: Double {
        let feet = Double(heightFeetText) ?? 5
        let inches = Double(heightInchesText) ?? 10
        return feet * 12 + inches
    }

    var isValid: Bool {
        age >= 12 && age <= 120 &&
        weightLbs >= 50 && weightLbs <= 500 &&
        heightInches >= 36 && heightInches <= 96
    }

    var showCalculatedResults: Bool {
        isValid
    }

    var calculatedBMR: Int {
        Int(profileService.calculateBMR(
            weightLbs: weightLbs,
            heightInches: heightInches,
            age: age,
            gender: gender
        ))
    }

    var calculatedTDEE: Int {
        let bmr = profileService.calculateBMR(
            weightLbs: weightLbs,
            heightInches: heightInches,
            age: age,
            gender: gender
        )
        return Int(profileService.calculateTDEE(bmr: bmr, activityLevel: activityLevel))
    }

    var calculatedTargetCalories: Int {
        Int(Double(calculatedTDEE) * goal.calorieMultiplier)
    }

    var calculatedMacros: MacroTargets {
        // Create a temporary profile for calculation
        let profile = NutritionProfile(
            id: UUID(),
            userId: UUID(),
            athleteType: athleteType,
            age: age,
            weightLbs: weightLbs,
            heightInches: heightInches,
            gender: gender,
            activityLevel: activityLevel,
            goal: goal,
            createdAt: nil,
            updatedAt: nil
        )
        return profileService.calculateMacros(profile: profile)
    }

    var calculatedProtein: Int {
        calculatedMacros.proteinGrams
    }

    var calculatedCarbs: Int {
        calculatedMacros.carbsGrams
    }

    var calculatedFat: Int {
        calculatedMacros.fatGrams
    }

    // MARK: - Load Profile

    func loadProfile() async {
        isLoading = true

        do {
            if let profile = try await profileService.fetchProfile() {
                // Populate fields from existing profile
                ageText = "\(profile.age)"
                weightText = String(format: "%.0f", profile.weightLbs)

                let totalInches = Int(profile.heightInches)
                heightFeetText = "\(totalInches / 12)"
                heightInchesText = "\(totalInches % 12)"

                gender = profile.gender
                activityLevel = profile.activityLevel
                goal = profile.goal
                athleteType = profile.athleteType

                logger.info("NutritionProfileSetup", "Loaded existing profile")
            } else {
                // Detect athlete type from subscriptions
                athleteType = await profileService.detectAthleteTypeFromSubscriptions()
                logger.info("NutritionProfileSetup", "No existing profile, detected athlete type: \(athleteType)")
            }
        } catch {
            logger.error("NutritionProfileSetup", "Error loading profile: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Save Profile

    func saveProfile() async {
        guard isValid else {
            error = "Please enter valid values"
            showError = true
            return
        }

        isSaving = true
        saveSuccessful = false

        do {
            _ = try await profileService.saveProfile(
                athleteType: athleteType,
                age: age,
                weightLbs: weightLbs,
                heightInches: heightInches,
                gender: gender,
                activityLevel: activityLevel,
                goal: goal
            )
            saveSuccessful = true
            logger.success("NutritionProfileSetup", "Profile saved successfully")
        } catch {
            self.error = error.localizedDescription
            showError = true
            logger.error("NutritionProfileSetup", "Error saving profile: \(error.localizedDescription)")
        }

        isSaving = false
    }
}

// MARK: - Preview

#Preview {
    NutritionProfileSetupView()
}
