import Foundation
import SwiftUI
import Supabase

/// ViewModel for patient profile editing
/// Allows patients to view and edit their demographic and medical history information
@MainActor
class PatientProfileViewModel: ObservableObject {
    // MARK: - Published Properties

    // Demographic fields
    @Published var age: String = ""
    @Published var gender: String = ""
    @Published var heightInches: String = ""
    @Published var weightLbs: String = ""

    // Medical history fields (displayed as text summaries)
    @Published var injuryHistory: String = ""
    @Published var surgeryHistory: String = ""
    @Published var allergies: String = ""

    // UI State
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showingSuccessAlert = false

    // Validation errors
    @Published var ageError: String?
    @Published var heightError: String?
    @Published var weightError: String?

    private let supabase: PTSupabaseClient
    private var patientId: String?
    private var dateOfBirth: Date?

    // Gender options for picker
    let genderOptions = ["", "Male", "Female", "Other", "Prefer not to say"]

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    // MARK: - Data Loading

    /// Load patient profile data from database
    func loadProfile(patientId: String) async {
        self.patientId = patientId
        isLoading = true
        errorMessage = nil

        #if DEBUG
        print("📊 [PatientProfile] Loading profile for patient: \(patientId)")
        #endif

        do {
            let response = try await supabase.client
                .from("patients")
                .select("""
                    id,
                    date_of_birth,
                    gender,
                    height_in,
                    weight_lb,
                    medical_history,
                    medications
                """)
                .eq("id", value: patientId)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let profile = try decoder.decode(PatientProfileData.self, from: response.data)

            // Populate form fields
            populateFields(from: profile)

            #if DEBUG
            print("✅ [PatientProfile] Profile loaded successfully")
            #endif

        } catch {
            #if DEBUG
            print("❌ [PatientProfile] Error loading profile: \(error.localizedDescription)")
            #endif
            errorMessage = "Unable to load profile. Please try again."
            ErrorLogger.shared.logError(error, context: "Load Patient Profile")
        }

        isLoading = false
    }

    /// Populate form fields from database data
    private func populateFields(from profile: PatientProfileData) {
        // Calculate age from date of birth
        if let dob = profile.dateOfBirth {
            self.dateOfBirth = dob
            let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
            self.age = "\(age)"
        }

        // Set gender
        self.gender = profile.gender ?? ""

        // Set physical measurements
        if let height = profile.heightIn {
            self.heightInches = "\(height)"
        }
        if let weight = profile.weightLb {
            self.weightLbs = "\(weight)"
        }

        // Parse medical history JSON
        if let medHistory = profile.medicalHistory {
            // Extract injuries
            if let injuries = medHistory["injuries"] as? [[String: Any]] {
                self.injuryHistory = injuries.map { injury in
                    let year = injury["year"] as? Int ?? 0
                    let diagnosis = injury["diagnosis"] as? String ?? ""
                    let bodyRegion = injury["body_region"] as? String ?? ""
                    return "\(year): \(diagnosis) (\(bodyRegion))"
                }.joined(separator: "\n")
            }

            // Extract surgeries
            if let surgeries = medHistory["surgeries"] as? [[String: Any]] {
                self.surgeryHistory = surgeries.map { surgery in
                    let year = surgery["year"] as? Int ?? 0
                    let procedure = surgery["procedure"] as? String ?? ""
                    return "\(year): \(procedure)"
                }.joined(separator: "\n")
            }
        }

        // Parse medications JSON for allergies
        if let meds = profile.medications,
           let allergiesList = meds["allergies"] as? [String] {
            self.allergies = allergiesList.joined(separator: ", ")
        }
    }

    // MARK: - Validation

    /// Validate all form fields
    func validate() -> Bool {
        var isValid = true

        // Clear previous errors
        ageError = nil
        heightError = nil
        weightError = nil

        // Validate age (must be positive number)
        if !age.isEmpty {
            if let ageValue = Int(age), ageValue > 0 && ageValue < 150 {
                // Valid age
            } else {
                ageError = "Age must be between 1 and 149"
                isValid = false
            }
        }

        // Validate height (must be positive number)
        if !heightInches.isEmpty {
            if let heightValue = Double(heightInches), heightValue > 0 && heightValue < 120 {
                // Valid height
            } else {
                heightError = "Height must be between 1 and 120 inches"
                isValid = false
            }
        }

        // Validate weight (must be positive number)
        if !weightLbs.isEmpty {
            if let weightValue = Double(weightLbs), weightValue > 0 && weightValue < 1000 {
                // Valid weight
            } else {
                weightError = "Weight must be between 1 and 999 lbs"
                isValid = false
            }
        }

        return isValid
    }

    // MARK: - Data Saving

    /// Save updated profile to database
    func saveProfile() async {
        guard let patientId = patientId else {
            errorMessage = "Patient ID not found"
            return
        }

        // Validate before saving
        guard validate() else {
            errorMessage = "Please fix validation errors before saving"
            return
        }

        isSaving = true
        errorMessage = nil
        successMessage = nil

        #if DEBUG
        print("💾 [PatientProfile] Saving profile for patient: \(patientId)")
        #endif

        do {
            // Calculate date of birth from age if age was changed
            var updatedDOB: Date? = dateOfBirth
            if let ageValue = Int(age), !age.isEmpty {
                let calendar = Calendar.current
                updatedDOB = calendar.date(byAdding: .year, value: -ageValue, to: Date())
            }

            // Prepare update data
            var updateData: [String: Any] = [:]

            if !gender.isEmpty {
                updateData["gender"] = gender
            }

            if let heightValue = Double(heightInches), !heightInches.isEmpty {
                updateData["height_in"] = heightValue
            }

            if let weightValue = Double(weightLbs), !weightLbs.isEmpty {
                updateData["weight_lb"] = weightValue
            }

            if let dob = updatedDOB {
                let formatter = ISO8601DateFormatter()
                updateData["date_of_birth"] = formatter.string(from: dob)
            }

            // Update medical history JSON
            var medicalHistoryJSON: [String: Any] = [:]

            // Parse injury history from text
            if !injuryHistory.isEmpty {
                let injuries = injuryHistory.components(separatedBy: "\n")
                    .filter { !$0.isEmpty }
                    .map { line -> [String: Any] in
                        // Simple parsing - in production, you'd want a better UI for this
                        return ["notes": line]
                    }
                medicalHistoryJSON["injuries"] = injuries
            } else {
                medicalHistoryJSON["injuries"] = []
            }

            // Parse surgery history from text
            if !surgeryHistory.isEmpty {
                let surgeries = surgeryHistory.components(separatedBy: "\n")
                    .filter { !$0.isEmpty }
                    .map { line -> [String: Any] in
                        return ["notes": line]
                    }
                medicalHistoryJSON["surgeries"] = surgeries
            } else {
                medicalHistoryJSON["surgeries"] = []
            }

            medicalHistoryJSON["chronic_conditions"] = []
            updateData["medical_history"] = medicalHistoryJSON

            // Update medications JSON with allergies
            var medicationsJSON: [String: Any] = ["current": []]
            if !allergies.isEmpty {
                let allergyList = allergies.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                medicationsJSON["allergies"] = allergyList
            } else {
                medicationsJSON["allergies"] = []
            }
            updateData["medications"] = medicationsJSON

            // Convert to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: updateData)

            // Execute update
            try await supabase.client
                .from("patients")
                .update(jsonData)
                .eq("id", value: patientId)
                .execute()

            #if DEBUG
            print("✅ [PatientProfile] Profile saved successfully")
            #endif
            successMessage = "Profile updated successfully"
            showingSuccessAlert = true

            // Reload to confirm changes
            await loadProfile(patientId: patientId)

        } catch {
            #if DEBUG
            print("❌ [PatientProfile] Error saving profile: \(error.localizedDescription)")
            #endif
            errorMessage = "Failed to save profile. Please try again."
            ErrorLogger.shared.logError(error, context: "Save Patient Profile")
        }

        isSaving = false
    }

    // MARK: - Helper Methods

    /// Clear success message
    func clearSuccessMessage() {
        successMessage = nil
        showingSuccessAlert = false
    }
}

// MARK: - Data Models

/// Patient profile data from database
struct PatientProfileData: Codable {
    let id: String
    let dateOfBirth: Date?
    let gender: String?
    let heightIn: Double?
    let weightLb: Double?
    let medicalHistory: [String: Any]?
    let medications: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case id
        case dateOfBirth = "date_of_birth"
        case gender
        case heightIn = "height_in"
        case weightLb = "weight_lb"
        case medicalHistory = "medical_history"
        case medications
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        dateOfBirth = try container.decodeIfPresent(Date.self, forKey: .dateOfBirth)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        heightIn = try container.decodeIfPresent(Double.self, forKey: .heightIn)
        weightLb = try container.decodeIfPresent(Double.self, forKey: .weightLb)

        // Decode JSONB fields as dictionaries
        if let medHistoryData = try? container.decodeIfPresent(Data.self, forKey: .medicalHistory) {
            medicalHistory = try? JSONSerialization.jsonObject(with: medHistoryData) as? [String: Any]
        } else {
            medicalHistory = nil
        }

        if let medsData = try? container.decodeIfPresent(Data.self, forKey: .medications) {
            medications = try? JSONSerialization.jsonObject(with: medsData) as? [String: Any]
        } else {
            medications = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(dateOfBirth, forKey: .dateOfBirth)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(heightIn, forKey: .heightIn)
        try container.encodeIfPresent(weightLb, forKey: .weightLb)

        // Encode JSONB fields as Data
        if let medicalHistory = medicalHistory {
            let data = try JSONSerialization.data(withJSONObject: medicalHistory)
            try container.encode(data, forKey: .medicalHistory)
        }

        if let medications = medications {
            let data = try JSONSerialization.data(withJSONObject: medications)
            try container.encode(data, forKey: .medications)
        }
    }
}
