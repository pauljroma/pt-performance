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
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?

    private let rmCalculator = RMCalculator()
    private let supabase: PTSupabaseClient
    private let logger = DebugLogger.shared

    init(patientId: UUID, exerciseId: UUID?, supabase: PTSupabaseClient = .shared) {
        self.patientId = patientId
        self.exerciseId = exerciseId
        self.supabase = supabase
    }
    
    var canSave: Bool {
        selectedExercise != nil && sets > 0 && reps > 0
    }
    
    func loadData() async {
        isLoading = true
        error = nil

        do {
            // Load available exercises from database
            logger.log("📥 Loading available exercises", level: .diagnostic)
            let response = try await supabase.client
                .from("exercises")
                .select()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            availableExercises = try decoder.decode([Exercise].self, from: response.data)

            logger.log("✅ Loaded \(availableExercises.count) exercises", level: .success)

            // If editing existing exercise, load it
            if let exerciseId = exerciseId {
                logger.log("📥 Loading exercise \(exerciseId)", level: .diagnostic)
                let exerciseResponse = try await supabase.client
                    .from("program_exercises")
                    .select()
                    .eq("id", value: exerciseId.uuidString)
                    .single()
                    .execute()

                let programExercise = try decoder.decode(ProgramExercise.self, from: exerciseResponse.data)

                // Find matching exercise in available exercises
                selectedExercise = availableExercises.first { $0.id == programExercise.exerciseId }
                sets = programExercise.sets ?? 3
                reps = programExercise.reps ?? 10
                targetRPE = programExercise.targetRPE ?? 7
                instructions = programExercise.instructions ?? ""

                logger.log("✅ Loaded exercise data", level: .success)
            }

            // Load patient history for selected exercise
            if let exercise = selectedExercise {
                await loadPatientHistory(for: exercise)
            }

        } catch {
            logger.log("❌ Error loading data: \(error)", level: .error)
            self.error = error.localizedDescription
            // Fallback to sample data
            availableExercises = Exercise.sampleExercises
        }

        isLoading = false
    }
    
    func loadPatientHistory(for exercise: Exercise) async {
        logger.log("📥 Loading patient history for \(exercise.exercise_name ?? "exercise")", level: .diagnostic)

        do {
            let response = try await supabase.client
                .from("exercise_logs")
                .select()
                .eq("patient_id", value: patientId.uuidString)
                .eq("exercise_id", value: exercise.id.uuidString)
                .order("created_at", ascending: false)
                .limit(10)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let logs = try decoder.decode([ExerciseLog].self, from: response.data)

            if !logs.isEmpty {
                // Calculate estimated 1RM from recent logs
                estimatedRM = rmCalculator.estimate1RM(from: logs)
                logger.log("✅ Estimated 1RM: \(estimatedRM ?? 0) lbs", level: .success)
                updateRecommendedWeight()
            } else {
                logger.log("ℹ️ No history found, using default estimated RM", level: .info)
                estimatedRM = 185.0
                updateRecommendedWeight()
            }
        } catch {
            logger.log("❌ Error loading history: \(error)", level: .error)
            // Fallback to default estimated RM
            estimatedRM = 185.0
            updateRecommendedWeight()
        }
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
    
    func saveExercise() async throws {
        guard let exercise = selectedExercise else {
            throw ProgramEditorError.noExerciseSelected
        }

        isSaving = true
        error = nil

        logger.log("💾 Saving exercise: \(exercise.exercise_name ?? "Unknown")", level: .diagnostic)
        logger.log("   Sets: \(sets), Reps: \(reps), Weight: \(recommendedWeight) lbs, RPE: \(targetRPE)", level: .diagnostic)

        do {
            let exerciseData = SaveExerciseInput(
                exerciseId: exercise.id.uuidString,
                patientId: patientId.uuidString,
                sets: sets,
                reps: reps,
                weight: recommendedWeight,
                targetRPE: targetRPE,
                instructions: instructions.isEmpty ? nil : instructions
            )

            if let existingId = exerciseId {
                // Update existing exercise
                logger.log("🔄 Updating existing program exercise", level: .diagnostic)
                try await supabase.client
                    .from("program_exercises")
                    .update(exerciseData)
                    .eq("id", value: existingId.uuidString)
                    .execute()

                logger.log("✅ Exercise updated successfully", level: .success)
            } else {
                // Insert new exercise
                logger.log("➕ Inserting new program exercise", level: .diagnostic)
                try await supabase.client
                    .from("program_exercises")
                    .insert(exerciseData)
                    .execute()

                logger.log("✅ Exercise saved successfully", level: .success)
            }

            isSaving = false
        } catch {
            logger.log("❌ Error saving exercise: \(error)", level: .error)
            self.error = error.localizedDescription
            isSaving = false
            throw error
        }
    }
}

// MARK: - Supporting Types

enum ProgramEditorError: LocalizedError {
    case noExerciseSelected

    var errorDescription: String? {
        switch self {
        case .noExerciseSelected:
            return "Please select an exercise before saving"
        }
    }
}

struct SaveExerciseInput: Codable {
    let exerciseId: String
    let patientId: String
    let sets: Int
    let reps: Int
    let weight: Double
    let targetRPE: Int
    let instructions: String?

    enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case patientId = "patient_id"
        case sets
        case reps
        case weight
        case targetRPE = "target_rpe"
        case instructions
    }
}

struct ProgramExercise: Codable {
    let id: UUID
    let exerciseId: UUID
    let sets: Int?
    let reps: Int?
    let targetRPE: Int?
    let instructions: String?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseId = "exercise_id"
        case sets
        case reps
        case targetRPE = "target_rpe"
        case instructions
    }
}
