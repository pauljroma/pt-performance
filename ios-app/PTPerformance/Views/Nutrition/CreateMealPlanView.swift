//
//  CreateMealPlanView.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Create meal plan view
//

import SwiftUI

/// View for creating a new meal plan
struct CreateMealPlanView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var planType: MealPlanType = .daily
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date().addingTimeInterval(86400 * 7) // 1 week
    @State private var isSaving = false
    @State private var error: String?
    @State private var showError = false

    private let mealPlanService = MealPlanService.shared
    private let supabase = PTSupabaseClient.shared

    let onCreated: (MealPlan) -> Void

    var body: some View {
        Form {
            // Basic Info
            Section("Plan Details") {
                TextField("Plan Name", text: $name)

                TextField("Description (optional)", text: $description, axis: .vertical)
                    .lineLimit(3...6)
            }

            // Plan Type
            Section("Plan Type") {
                Picker("Type", selection: $planType) {
                    ForEach(MealPlanType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                Text(planTypeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Date Range
            Section("Schedule") {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)

                Toggle("Set End Date", isOn: $hasEndDate)

                if hasEndDate {
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
            }

            // Preview
            Section("Preview") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your plan will include:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if planType == .daily {
                        Text("• Same meals every day")
                        Text("• Easy to follow")
                        Text("• Best for consistent schedules")
                    } else {
                        Text("• Different meals for each day")
                        Text("• More variety")
                        Text("• 7 days of unique meals")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Create Meal Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task {
                        await createPlan()
                    }
                }
                .disabled(!isValid || isSaving)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(error ?? "An error occurred")
        }
    }

    private var planTypeDescription: String {
        switch planType {
        case .daily:
            return "A daily plan repeats the same meals every day. Great for consistency."
        case .weekly:
            return "A weekly plan lets you set different meals for each day of the week."
        }
    }

    private var isValid: Bool {
        !name.isEmpty
    }

    private let logger = DebugLogger.shared

    private func createPlan() async {
        guard let patientId = supabase.userId else {
            logger.error("CREATE MEAL PLAN", "Not logged in - no userId")
            error = "Not logged in"
            showError = true
            return
        }

        logger.info("CREATE MEAL PLAN", "Starting create for patient: \(patientId)")
        isSaving = true

        do {
            let dto = CreateMealPlanDTO(
                patientId: patientId,
                name: name,
                description: description.isEmpty ? nil : description,
                planType: planType.rawValue,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil
            )

            logger.info("CREATE MEAL PLAN", "DTO: name=\(name), type=\(planType.rawValue)")
            let newPlan = try await mealPlanService.createMealPlan(dto)

            logger.success("CREATE MEAL PLAN", "Created: \(newPlan.id)")
            isSaving = false
            onCreated(newPlan)
            dismiss()
        } catch {
            logger.error("CREATE MEAL PLAN", "FAILED: \(error)")
            logger.error("CREATE MEAL PLAN", "Error type: \(type(of: error)), details: \(String(describing: error))")
            self.error = "Failed to create plan: \(error.localizedDescription)"
            self.showError = true
            isSaving = false
        }
    }
}

#Preview {
    NavigationStack {
        CreateMealPlanView { plan in
            print("Created: \(plan.name)")
        }
    }
}
