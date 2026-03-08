import SwiftUI

/// ViewModel for Supplement Stacks View
@MainActor
final class SupplementStacksViewModel: ObservableObject {
    @Published var stacks: [SupplementStack] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: StackCategory?
    @Published var isLoading = false
    @Published var error: String?

    private let service = SupplementService.shared

    var filteredStacks: [SupplementStack] {
        var results = stacks

        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(searchLower) ||
                $0.description.lowercased().contains(searchLower)
            }
        }

        if let category = selectedCategory {
            results = results.filter { mapGoalToCategory($0.goal) == category }
        }

        return results
    }

    var stacksByCategory: [(StackCategory, [SupplementStack])] {
        let grouped = filteredStacks.safeGrouped(by: { mapGoalToCategory($0.goal) })
        return grouped.sorted { $0.key.displayName < $1.key.displayName }
    }

    private func mapGoalToCategory(_ goal: SupplementStackGoal) -> StackCategory {
        switch goal {
        case .muscleBuilding: return .performance
        case .fatLoss: return .performance
        case .recovery: return .recovery
        case .sleep: return .sleep
        case .energy: return .performance
        case .cognitive: return .focus
        case .longevity: return .longevity
        case .general: return .health
        case .athlete: return .performance
        case .pitcher: return .performance
        }
    }

    func loadData() async {
        isLoading = true
        error = nil

        await service.fetchStacks()
        stacks = service.stacks

        if let serviceError = service.error {
            error = serviceError.localizedDescription
        }

        isLoading = false
    }

    func addStackToRoutine(_ stack: SupplementStack) async {
        do {
            try await service.addStackToRoutine(stack)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// Category for supplement stacks
enum StackCategory: String, Codable, CaseIterable, Identifiable {
    case sleep
    case performance
    case recovery
    case longevity
    case focus
    case health
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sleep: return "Sleep"
        case .performance: return "Performance"
        case .recovery: return "Recovery"
        case .longevity: return "Longevity"
        case .focus: return "Focus"
        case .health: return "General Health"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .sleep: return "moon.fill"
        case .performance: return "bolt.fill"
        case .recovery: return "heart.fill"
        case .longevity: return "leaf.fill"
        case .focus: return "brain.head.profile"
        case .health: return "cross.fill"
        case .custom: return "slider.horizontal.3"
        }
    }

    var color: Color {
        switch self {
        case .sleep: return .purple
        case .performance: return .orange
        case .recovery: return .modusTealAccent
        case .longevity: return .green
        case .focus: return .blue
        case .health: return .modusCyan
        case .custom: return .gray
        }
    }
}
