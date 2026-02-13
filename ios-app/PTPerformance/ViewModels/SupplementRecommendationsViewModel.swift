import Foundation
import SwiftUI

@MainActor
final class SupplementRecommendationsViewModel: ObservableObject {
    @Published var selectedGoals: Set<SupplementGoal> = []
    @Published var recommendations: SupplementRecommendationResponse?
    @Published var isLoading = false
    @Published var error: String?

    private let service = SupplementService.shared

    func toggleGoal(_ goal: SupplementGoal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }

    func getRecommendations() async {
        isLoading = true
        error = nil

        await service.getAIRecommendations()

        if let serviceError = service.error {
            error = serviceError.localizedDescription
        } else {
            recommendations = service.aiRecommendations
        }

        isLoading = false
    }

    func refreshRecommendations() async {
        isLoading = true
        error = nil

        await service.refreshAIRecommendations()

        if let serviceError = service.error {
            error = serviceError.localizedDescription
        } else {
            recommendations = service.aiRecommendations
        }

        isLoading = false
    }

    func addToStack(_ recommendation: AISupplementRecommendation) async {
        do {
            try await service.addRecommendedSupplement(recommendation)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
