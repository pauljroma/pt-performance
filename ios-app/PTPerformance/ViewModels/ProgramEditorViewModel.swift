//
//  ProgramEditorViewModel.swift
//  PTPerformance
//
//  ViewModel for exercise editing with strength calculations
//

import Foundation
import SwiftUI

@MainActor
class ProgramEditorViewModel: ObservableObject {
    let patientId: UUID
    let exerciseId: UUID?
    
    @Published var selectedExercise: Exercise?
    @Published var estimatedRM: Double?
    @Published var sets: Int = 3 {
        didSet { updateRecommendedWeight() }
    }
    @Published var reps: Int = 10 {
        didSet { updateRecommendedWeight() }
    }
    @Published var recommendedWeight: Double = 0
    @Published var targetRPE: Int = 7
    @Published var instructions: String = ""
    @Published var availableExercises: [Exercise] = []
    
    private let rmCalculator = RMCalculator()
    
    init(patientId: UUID, exerciseId: UUID?) {
        self.patientId = patientId
        self.exerciseId = exerciseId
    }
    
    var canSave: Bool {
        selectedExercise != nil && sets > 0 && reps > 0
    }
    
    func loadData() async {
        // Load available exercises
        availableExercises = Exercise.sampleExercises
        
        // If editing existing, load it
        if let exerciseId = exerciseId {
            // TODO: Load from Supabase
        }
        
        // Load patient history for selected exercise
        if let exercise = selectedExercise {
            await loadPatientHistory(for: exercise)
        }
    }
    
    func loadPatientHistory(for exercise: Exercise) async {
        // Fetch patient's exercise history from Supabase
        // TODO: Implement Supabase query
        /*
        do {
            let response = try await supabase
                .from("exercise_logs")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .eq("exercise_id", value: exercise.id.uuidString)
                .order("created_at", ascending: false)
                .limit(10)
                .execute()
            
            let logs = try JSONDecoder().decode([ExerciseLog].self, from: response.data)
            
            if !logs.isEmpty {
                estimatedRM = rmCalculator.estimate1RM(from: logs)
                updateRecommendedWeight()
            }
        } catch {
            print("Error loading history: \(error)")
        }
        */
        
        // For demo: use sample estimated RM
        estimatedRM = 185.0
        updateRecommendedWeight()
    }
    
    func updateRecommendedWeight() {
        guard let rm = estimatedRM else { return }
        
        // Recommend based on rep range
        // Strength: 1-5 reps = 85% 1RM
        // Hypertrophy: 6-12 reps = 70% 1RM
        // Endurance: 13+ reps = 50% 1RM
        
        if reps <= 5 {
            recommendedWeight = rm * 0.85
        } else if reps <= 12 {
            recommendedWeight = rm * 0.70
        } else {
            recommendedWeight = rm * 0.50
        }
    }
    
    func saveExercise() async {
        guard let exercise = selectedExercise else { return }

        print("Saving exercise: \(exercise.exercise_name ?? "Unknown")")
        print("Sets: \(sets), Reps: \(reps), Weight: \(recommendedWeight) lbs")
        print("Target RPE: \(targetRPE)")
        
        // TODO: Save to Supabase
        /*
        do {
            let exerciseData: [String: Any] = [
                "exercise_id": exercise.id.uuidString,
                "patient_id": patientId.uuidString,
                "sets": sets,
                "reps": reps,
                "weight": recommendedWeight,
                "target_rpe": targetRPE,
                "instructions": instructions
            ]
            
            let response = try await supabase
                .from("program_exercises")
                .insert(exerciseData)
                .execute()
        } catch {
            print("Error saving: \(error)")
        }
        */
    }
}
