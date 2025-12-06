//
//  ProgramEditorView.swift
//  PTPerformance
//
//  Edit exercise parameters with strength targets
//

import SwiftUI

struct ProgramEditorView: View {
    @StateObject private var viewModel: ProgramEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(patientId: UUID, exerciseId: UUID? = nil) {
        _viewModel = StateObject(wrappedValue: ProgramEditorViewModel(
            patientId: patientId,
            exerciseId: exerciseId
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Exercise Selector
                    ExercisePickerSection(
                        selectedExercise: $viewModel.selectedExercise,
                        exercises: viewModel.availableExercises
                    )
                    
                    // Show strength targets if exercise selected
                    if let exercise = viewModel.selectedExercise {
                        StrengthTargetsCard(
                            exercise: exercise,
                            oneRepMax: viewModel.estimatedRM
                        )
                    }
                    
                    // Sets/Reps/Weight Editor
                    if viewModel.selectedExercise != nil {
                        ProgramParametersSection(
                            sets: $viewModel.sets,
                            reps: $viewModel.reps,
                            weight: $viewModel.recommendedWeight,
                            rpe: $viewModel.targetRPE
                        )
                        
                        // Instructions
                        InstructionsSection(instructions: $viewModel.instructions)
                    }
                }
                .padding()
            }
            .navigationTitle("Exercise Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.saveExercise()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
}

struct ExercisePickerSection: View {
    @Binding var selectedExercise: Exercise?
    let exercises: [Exercise]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercise")
                .font(.headline)
            
            Picker("Select Exercise", selection: $selectedExercise) {
                Text("Choose exercise...").tag(nil as Exercise?)
                
                ForEach(exercises) { exercise in
                    Text(exercise.name).tag(exercise as Exercise?)
                }
            }
            .pickerStyle(.menu)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProgramParametersSection: View {
    @Binding var sets: Int
    @Binding var reps: Int
    @Binding var weight: Double
    @Binding var rpe: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Training Parameters")
                .font(.headline)
            
            // Sets
            HStack {
                Text("Sets")
                Spacer()
                Stepper("\(sets)", value: $sets, in: 1...10)
                    .labelsHidden()
                Text(sets, format: .number)
                    .frame(width: 30)
                    .font(.headline)
            }
            
            // Reps
            HStack {
                Text("Reps")
                Spacer()
                Stepper("\(reps)", value: $reps, in: 1...30)
                    .labelsHidden()
                Text(reps, format: .number)
                    .frame(width: 30)
                    .font(.headline)
            }
            
            // Weight
            HStack {
                Text("Weight (lbs)")
                Spacer()
                TextField("Weight", value: $weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Target RPE
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Target RPE")
                    Spacer()
                    Text("\(rpe)/10")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                Slider(value: Binding(
                    get: { Double(rpe) },
                    set: { rpe = Int($0) }
                ), in: 1...10, step: 1)
                .tint(.blue)
                
                Text(rpeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    var rpeDescription: String {
        switch rpe {
        case 1...3: return "Very light effort"
        case 4...6: return "Moderate effort"
        case 7...8: return "Hard effort, challenging"
        case 9...10: return "Maximum effort"
        default: return ""
        }
    }
}

struct InstructionsSection: View {
    @Binding var instructions: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Special Instructions")
                .font(.headline)
            
            TextEditor(text: $instructions)
                .frame(height: 100)
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
