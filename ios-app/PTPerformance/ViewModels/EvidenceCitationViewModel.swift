//
//  EvidenceCitationViewModel.swift
//  PTPerformance
//
//  X2Index Command Center - M2: Evidence Citation System
//  ViewModel for managing citation display and state
//
//  Features:
//  - Load citations for a claim
//  - Group by source type
//  - Calculate aggregate confidence
//  - Handle loading/error states
//

import SwiftUI
import Combine

// MARK: - View State

enum CitationViewState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case error(String)

    static func == (lhs: CitationViewState, rhs: CitationViewState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.loaded, .loaded), (.empty, .empty):
            return true
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

// MARK: - Evidence Citation ViewModel

/// ViewModel for displaying and managing evidence citations
@MainActor
final class EvidenceCitationViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var citations: [EvidenceCitation] = []
    @Published private(set) var groupedCitations: [CitationGroup] = []
    @Published private(set) var overallConfidence: ConfidenceGrade = .low
    @Published private(set) var state: CitationViewState = .idle
    @Published private(set) var citationCount: Int = 0
    @Published var selectedCitation: EvidenceCitation?
    @Published var expandedSourceTypes: Set<CitationSourceType> = []

    // MARK: - Properties

    let claimId: UUID
    private let citationService: CitationService

    // MARK: - Computed Properties

    /// Whether citations are currently loading
    var isLoading: Bool {
        state == .loading
    }

    /// Whether there are any citations
    var hasCitations: Bool {
        !citations.isEmpty
    }

    /// Unique source types present in citations
    var sourceTypes: [CitationSourceType] {
        Array(Set(citations.map { $0.sourceType }))
            .sorted { $0.reliabilityWeight > $1.reliabilityWeight }
    }

    /// Total citation count for display
    var displayCount: String {
        switch citationCount {
        case 0:
            return "No sources"
        case 1:
            return "1 source"
        default:
            return "\(citationCount) sources"
        }
    }

    /// Summary text for PT Brief display
    var summaryText: String {
        guard hasCitations else {
            return "No evidence sources available"
        }

        let typeNames = sourceTypes.prefix(3).map { $0.displayName }
        let typeSummary = typeNames.joined(separator: ", ")

        if sourceTypes.count > 3 {
            return "\(citationCount) sources from \(typeSummary), and more"
        } else {
            return "\(citationCount) sources from \(typeSummary)"
        }
    }

    // MARK: - Initialization

    init(claimId: UUID, citationService: CitationService = .shared) {
        self.claimId = claimId
        self.citationService = citationService
    }

    // MARK: - Public Methods

    /// Load citations for the claim
    func loadCitations() async {
        guard state != .loading else { return }

        state = .loading

        do {
            let fetchedCitations = try await citationService.fetchCitations(for: claimId)

            if fetchedCitations.isEmpty {
                citations = []
                groupedCitations = []
                citationCount = 0
                overallConfidence = .low
                state = .empty
            } else {
                citations = fetchedCitations
                groupedCitations = try await citationService.getGroupedCitations(for: claimId)
                citationCount = fetchedCitations.count
                overallConfidence = citationService.getOverallConfidence(for: fetchedCitations)
                state = .loaded

                // Auto-expand first group
                if let firstGroup = groupedCitations.first {
                    expandedSourceTypes.insert(firstGroup.sourceType)
                }
            }

            DebugLogger.shared.log(
                "Loaded \(citations.count) citations for claim \(claimId)",
                level: .success
            )
        } catch {
            state = .error(error.localizedDescription)
            ErrorLogger.shared.logError(error, context: "EvidenceCitationViewModel.loadCitations")
        }
    }

    /// Refresh citations (force reload)
    func refresh() async {
        citationService.clearCache(for: claimId)
        await loadCitations()
    }

    /// Load citation count only (lightweight)
    func loadCitationCount() async {
        citationCount = await citationService.getCitationCount(for: claimId)
    }

    /// Toggle expansion for a source type
    func toggleExpansion(for sourceType: CitationSourceType) {
        HapticService.selection()

        if expandedSourceTypes.contains(sourceType) {
            expandedSourceTypes.remove(sourceType)
        } else {
            expandedSourceTypes.insert(sourceType)
        }
    }

    /// Select a citation for detail view
    func selectCitation(_ citation: EvidenceCitation) {
        HapticService.selection()
        selectedCitation = citation
    }

    /// Clear selection
    func clearSelection() {
        selectedCitation = nil
    }

    /// Check if a source type is expanded
    func isExpanded(_ sourceType: CitationSourceType) -> Bool {
        expandedSourceTypes.contains(sourceType)
    }

    /// Get citations for a specific source type
    func citations(for sourceType: CitationSourceType) -> [EvidenceCitation] {
        citations.filter { $0.sourceType == sourceType }
    }

    /// Get the highest confidence citation
    func highestConfidenceCitation() -> EvidenceCitation? {
        citations.max { $0.confidence.numericValue < $1.confidence.numericValue }
    }

    /// Get the most recent citation
    func mostRecentCitation() -> EvidenceCitation? {
        citations.max { $0.timestamp < $1.timestamp }
    }

    // MARK: - Error Handling

    /// Retry after error
    func retry() async {
        state = .idle
        await loadCitations()
    }

    /// Error message for display
    var errorMessage: String? {
        if case .error(let message) = state {
            return message
        }
        return nil
    }
}

// MARK: - Preview Support

#if DEBUG
extension EvidenceCitationViewModel {
    /// Create a preview view model with sample data
    static func preview(withCitations: Bool = true) -> EvidenceCitationViewModel {
        let viewModel = EvidenceCitationViewModel(
            claimId: CitationService.sampleClaimId,
            citationService: .preview
        )

        if withCitations {
            viewModel.citations = EvidenceCitation.sampleCitations
            viewModel.citationCount = EvidenceCitation.sampleCitations.count
            viewModel.overallConfidence = .good
            viewModel.state = .loaded

            viewModel.groupedCitations = [
                CitationGroup(
                    sourceType: .healthKit,
                    citations: [EvidenceCitation.sampleHealthKitCitation]
                ),
                CitationGroup(
                    sourceType: .whoop,
                    citations: [EvidenceCitation.sampleWhoopCitation]
                ),
                CitationGroup(
                    sourceType: .labResult,
                    citations: [EvidenceCitation.sampleLabCitation]
                ),
                CitationGroup(
                    sourceType: .checkIn,
                    citations: [EvidenceCitation.sampleCheckInCitation]
                ),
                CitationGroup(
                    sourceType: .workout,
                    citations: [EvidenceCitation.sampleWorkoutCitation]
                )
            ]

            viewModel.expandedSourceTypes.insert(.healthKit)
        } else {
            viewModel.state = .empty
        }

        return viewModel
    }

    /// Create a loading state preview
    static var loadingPreview: EvidenceCitationViewModel {
        let viewModel = EvidenceCitationViewModel(
            claimId: UUID(),
            citationService: .preview
        )
        viewModel.state = .loading
        return viewModel
    }

    /// Create an error state preview
    static var errorPreview: EvidenceCitationViewModel {
        let viewModel = EvidenceCitationViewModel(
            claimId: UUID(),
            citationService: .preview
        )
        viewModel.state = .error("Unable to load citations. Please try again.")
        return viewModel
    }
}
#endif
