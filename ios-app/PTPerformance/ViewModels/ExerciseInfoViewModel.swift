import Foundation
import SwiftUI
import Supabase

// MARK: - BUILD 296: Exercise Info ViewModel (ACP-587)

/// Template detail for exercise info sheet
struct ExerciseTemplateDetail: Codable {
    let id: UUID
    let exerciseName: String
    let videoUrl: String?
    let videoThumbnailUrl: String?
    let techniqueCues: TechniqueCues?
    let commonMistakes: String?
    let safetyNotes: String?
    let category: String?
    let bodyRegion: String?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseName = "exercise_name"
        case videoUrl = "video_url"
        case videoThumbnailUrl = "video_thumbnail_url"
        case techniqueCues = "technique_cues"
        case commonMistakes = "common_mistakes"
        case safetyNotes = "safety_notes"
        case category
        case bodyRegion = "body_region"
    }
}

@MainActor
class ExerciseInfoViewModel: ObservableObject {
    @Published var template: ExerciseTemplateDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase: PTSupabaseClient

    init(supabase: PTSupabaseClient = .shared) {
        self.supabase = supabase
    }

    /// Fetch exercise template details by ID
    func fetchTemplate(id: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await supabase.client
                .from("exercise_templates")
                .select("""
                    id,
                    exercise_name,
                    video_url,
                    video_thumbnail_url,
                    technique_cues,
                    common_mistakes,
                    safety_notes,
                    category,
                    body_region
                """)
                .eq("id", value: id)
                .single()
                .execute()

            let decoder = JSONDecoder()
            template = try decoder.decode(ExerciseTemplateDetail.self, from: response.data)
            isLoading = false
        } catch {
            errorMessage = "Unable to load exercise details. Please try again."
            isLoading = false
        }
    }

    /// BUILD 354: Fetch exercise template details by name (fuzzy match)
    /// Used when exercise_template_id is not available (e.g., from workout templates)
    func fetchTemplateByName(_ name: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Try exact match first, then fuzzy match
            let response = try await supabase.client
                .from("exercise_templates")
                .select("""
                    id,
                    exercise_name,
                    video_url,
                    video_thumbnail_url,
                    technique_cues,
                    common_mistakes,
                    safety_notes,
                    category,
                    body_region
                """)
                .ilike("exercise_name", pattern: "%\(name)%")
                .limit(1)
                .execute()

            let decoder = JSONDecoder()
            let results = try decoder.decode([ExerciseTemplateDetail].self, from: response.data)
            template = results.first
            isLoading = false
        } catch {
            errorMessage = "Unable to load exercise details. Please try again."
            isLoading = false
        }
    }
}
