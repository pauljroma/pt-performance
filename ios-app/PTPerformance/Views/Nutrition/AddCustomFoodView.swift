//
//  AddCustomFoodView.swift
//  PTPerformance
//
//  BUILD 222: Nutrition Module - Add custom food view
//

import SwiftUI

/// View for creating a custom food item
struct AddCustomFoodView: View {
    @Environment(\.dismiss) private var dismiss

    // Basic Info
    @State private var name = ""
    @State private var brand = ""
    @State private var servingSize = "1 serving"
    @State private var servingGrams: Double?

    // Macros
    @State private var calories: Int = 0
    @State private var protein: Double = 0
    @State private var carbs: Double = 0
    @State private var fat: Double = 0
    @State private var fiber: Double = 0
    @State private var sugar: Double = 0
    @State private var sodium: Double = 0

    // Category
    @State private var selectedCategory: FoodCategory?
    @State private var barcode = ""

    // Validation
    @State private var showError = false
    @State private var errorMessage = ""

    let onSave: (CreateFoodItemDTO) -> Void

    var body: some View {
        Form {
            // Basic Info Section
            Section("Basic Information") {
                TextField("Food Name *", text: $name)
                TextField("Brand (optional)", text: $brand)
                TextField("Serving Size *", text: $servingSize)

                HStack {
                    Text("Serving Weight")
                    Spacer()
                    TextField("grams", value: $servingGrams, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                    Text("g")
                        .foregroundColor(.secondary)
                }
            }

            // Nutrition Section
            Section("Nutrition Facts (per serving)") {
                HStack {
                    Text("Calories *")
                    Spacer()
                    TextField("0", value: $calories, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                    Text("kcal")
                        .foregroundColor(.secondary)
                }

                macroRow("Protein *", value: $protein, unit: "g", color: .red)
                macroRow("Carbs *", value: $carbs, unit: "g", color: .modusCyan)
                macroRow("Fat *", value: $fat, unit: "g", color: .yellow)
            }

            // Additional Nutrition
            Section("Additional (optional)") {
                macroRow("Fiber", value: $fiber, unit: "g", color: .green)
                macroRow("Sugar", value: $sugar, unit: "g", color: .orange)
                macroRow("Sodium", value: $sodium, unit: "mg", color: .gray)
            }

            // Category Section
            Section("Category") {
                Picker("Category", selection: $selectedCategory) {
                    Text("None").tag(nil as FoodCategory?)
                    ForEach(FoodCategory.allCases, id: \.self) { category in
                        Label(category.displayName, systemImage: category.icon)
                            .tag(category as FoodCategory?)
                    }
                }
            }

            // Barcode Section
            Section("Barcode (optional)") {
                TextField("UPC/Barcode", text: $barcode)
                    .keyboardType(.numberPad)
            }

            // Calculated Info
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calculated from macros:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    let calculatedCals = Int(protein * 4 + carbs * 4 + fat * 9)
                    HStack {
                        Text("Macro calories:")
                        Spacer()
                        Text("\(calculatedCals) kcal")
                            .foregroundColor(abs(calculatedCals - calories) > 50 ? .orange : .green)
                    }
                    .font(.subheadline)

                    if abs(calculatedCals - calories) > 50 {
                        Text("Note: Entered calories differ from macro calculation")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .navigationTitle("Add Custom Food")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveFood()
                }
                .disabled(!isValid)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Macro Row Helper

    private func macroRow(_ title: String, value: Binding<Double>, unit: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
            Spacer()
            TextField("0", value: value, format: .number.precision(.fractionLength(0...1)))
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
            Text(unit)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        !name.isEmpty &&
        !servingSize.isEmpty &&
        calories > 0
    }

    // MARK: - Save

    private func saveFood() {
        guard isValid else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return
        }

        let dto = CreateFoodItemDTO(
            name: name,
            brand: brand.isEmpty ? nil : brand,
            servingSize: servingSize,
            servingGrams: servingGrams,
            calories: calories,
            proteinG: protein,
            carbsG: carbs,
            fatG: fat,
            fiberG: fiber > 0 ? fiber : nil,
            sugarG: sugar > 0 ? sugar : nil,
            sodiumMg: sodium > 0 ? sodium : nil,
            category: selectedCategory?.rawValue,
            barcode: barcode.isEmpty ? nil : barcode
        )

        onSave(dto)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        AddCustomFoodView { food in
            print("Created: \(food.name)")
        }
    }
}
