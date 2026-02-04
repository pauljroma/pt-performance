import Foundation

/// Shared utility functions for supplement type mapping
enum SupplementMappingUtils {

    /// Map catalog category to legacy supplement category
    static func mapCatalogToSupplementCategory(_ category: SupplementCatalogCategory) -> SupplementCategory {
        switch category {
        case .performance: return .preworkout
        case .recovery: return .recovery
        case .sleep: return .sleep
        case .health: return .other
        case .vitamin: return .vitamins
        case .mineral: return .minerals
        case .protein: return .protein
        case .preworkout: return .preworkout
        case .cognitive: return .adaptogens
        case .hormonal: return .other
        case .other: return .other
        }
    }

    /// Map supplement timing to legacy time of day
    static func mapTimingToTimeOfDay(_ timing: SupplementTiming) -> TimeOfDay? {
        switch timing {
        case .morning: return .morning
        case .preWorkout: return .preWorkout
        case .postWorkout: return .postWorkout
        case .evening: return .evening
        case .beforeBed: return .beforeBed
        case .withMeals: return .withMeals
        case .betweenMeals: return .afternoon
        case .anytime: return nil
        }
    }
}
