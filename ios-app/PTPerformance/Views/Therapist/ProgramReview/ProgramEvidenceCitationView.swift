// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  EvidenceCitationView.swift
//  PTPerformance
//
//  ACP-395: PT Review Workflow - Evidence Citation View
//  Displays research citations supporting an AI-generated exercise program.
//
//  Features:
//  - Citations grouped by exercise or topic with collapsible sections
//  - Evidence level badges (color-coded by research quality)
//  - Evidence summary header with citation counts
//  - DOI link support for tapping through to original research
//  - Empty state handling
//

import SwiftUI

// MARK: - Evidence Citation View

/// Displays research citations supporting an AI-generated program for PT review.
///
/// Shows citations grouped by exercise or topic, each with evidence level badges,
/// author lists, journal information, and relevance notes explaining why the
/// citation supports the exercise choice.
struct ProgramEvidenceCitationView: View {

    // MARK: - Properties

    let citations: [String: [ReviewEvidenceCitation]]
    var onOpenDOI: ((String) -> Void)?

    // MARK: - State

    @State private var expandedSections: Set<String> = []

    // MARK: - Body

    var body: some View {
        Group {
            if allCitations.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        evidenceSummaryHeader

                        ForEach(sortedGroupKeys, id: \.self) { groupKey in
                            if let groupCitations = citations[groupKey] {
                                citationGroupSection(
                                    title: groupKey,
                                    citations: groupCitations
                                )
                            }
                        }
                    }
                    .padding(Spacing.md)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            // Expand first section by default
            if let firstKey = sortedGroupKeys.first {
                expandedSections.insert(firstKey)
            }
        }
    }

    // MARK: - Computed Properties

    private var allCitations: [ReviewEvidenceCitation] {
        citations.values.flatMap { $0 }
    }

    private var sortedGroupKeys: [String] {
        citations.keys.sorted()
    }

    private var systematicReviewCount: Int {
        allCitations.filter { $0.evidenceLevel == .systematicReview }.count
    }

    private var rctCount: Int {
        allCitations.filter { $0.evidenceLevel == .rct }.count
    }

    // MARK: - Evidence Summary Header

    private var evidenceSummaryHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title3)
                    .foregroundColor(.modusCyan)
                    .accessibilityHidden(true)

                Text("Evidence Summary")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
            }

            HStack(spacing: Spacing.md) {
                summaryStatPill(
                    count: allCitations.count,
                    label: "Citation\(allCitations.count == 1 ? "" : "s")",
                    icon: "book.fill",
                    color: .modusCyan
                )

                if systematicReviewCount > 0 {
                    summaryStatPill(
                        count: systematicReviewCount,
                        label: "Systematic Review\(systematicReviewCount == 1 ? "" : "s")",
                        icon: "checkmark.seal.fill",
                        color: .green
                    )
                }

                if rctCount > 0 {
                    summaryStatPill(
                        count: rctCount,
                        label: "RCT\(rctCount == 1 ? "" : "s")",
                        icon: "checkmark.seal.fill",
                        color: .green
                    )
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Evidence summary: \(allCitations.count) citations, \(systematicReviewCount) systematic reviews, \(rctCount) randomized controlled trials")
    }

    // MARK: - Summary Stat Pill

    private func summaryStatPill(
        count: Int,
        label: String,
        icon: String,
        color: Color
    ) -> some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.caption2)
                .accessibilityHidden(true)

            Text("\(count) \(label)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(color.opacity(0.12))
        .cornerRadius(CornerRadius.xs)
    }

    // MARK: - Citation Group Section

    private func citationGroupSection(
        title: String,
        citations: [ReviewEvidenceCitation]
    ) -> some View {
        let isExpanded = expandedSections.contains(title)

        return VStack(alignment: .leading, spacing: 0) {
            // Section header (tappable to expand/collapse)
            Button {
                HapticFeedback.light()
                withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                    if isExpanded {
                        expandedSections.remove(title)
                    } else {
                        expandedSections.insert(title)
                    }
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.subheadline)
                        .foregroundColor(.modusCyan)
                        .frame(width: 28)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("\(citations.count) citation\(citations.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Highest evidence level badge in this group
                    if let highestLevel = citations.map(\.evidenceLevel).sorted(by: { $0.sortOrder < $1.sortOrder }).first {
                        evidenceLevelBadge(highestLevel)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(Spacing.md)
                .background(Color(.secondarySystemGroupedBackground))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title), \(citations.count) citations")
            .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand")
            .accessibilityAddTraits(.isHeader)

            // Expanded citations
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(citations.enumerated()), id: \.element.id) { index, citation in
                        citationCard(citation)

                        if index < citations.count - 1 {
                            Divider()
                                .padding(.leading, Spacing.xl + Spacing.md)
                        }
                    }
                }
                .background(Color(.tertiarySystemGroupedBackground))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cornerRadius(CornerRadius.md)
        .animation(.easeInOut(duration: AnimationDuration.standard), value: isExpanded)
    }

    // MARK: - Citation Card

    private func citationCard(_ citation: ReviewEvidenceCitation) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Title (tappable if DOI exists)
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "book.fill")
                    .font(.caption)
                    .foregroundColor(citation.evidenceLevel.color)
                    .frame(width: 20, alignment: .center)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    // Title - tappable for DOI
                    if let doi = citation.doi {
                        Button {
                            HapticFeedback.light()
                            onOpenDOI?(doi)
                        } label: {
                            Text(citation.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.modusCyan)
                                .multilineTextAlignment(.leading)
                        }
                        .accessibilityLabel("\(citation.title). Tap to open DOI link.")
                        .accessibilityAddTraits(.isLink)
                    } else {
                        Text(citation.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }

                    // Authors
                    Text(formattedAuthors(citation.authors))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Journal & Year
                    HStack(spacing: Spacing.xxs) {
                        if let journal = citation.journal {
                            Text(journal)
                                .font(.caption)
                                .italic()
                                .foregroundColor(.secondary)
                        }

                        if let year = citation.year {
                            Text("(\(String(year)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Evidence level badge
                evidenceLevelBadge(citation.evidenceLevel)
            }

            // Relevance note
            if let relevanceNote = citation.relevanceNote, !relevanceNote.isEmpty {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                        .frame(width: 20, alignment: .center)
                        .accessibilityHidden(true)

                    Text(relevanceNote)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.sm)
                .background(Color.yellow.opacity(0.08))
                .cornerRadius(CornerRadius.sm)
            }
        }
        .padding(Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(citationAccessibilityLabel(citation))
    }

    // MARK: - Evidence Level Badge

    private func evidenceLevelBadge(_ level: ReviewEvidenceLevel) -> some View {
        Text(level.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 3)
            .background(level.color)
            .cornerRadius(CornerRadius.xs)
            .accessibilityLabel("Evidence level: \(level.displayName)")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text("No Evidence Citations Available")
                .font(.headline)
                .foregroundColor(.primary)

            Text("No evidence citations have been linked to this program yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No evidence citations available")
    }

    // MARK: - Helpers

    /// Formats author list with "et al." truncation for more than 3 authors.
    private func formattedAuthors(_ authors: [String]) -> String {
        switch authors.count {
        case 0:
            return "Unknown authors"
        case 1:
            return authors[0]
        case 2:
            return "\(authors[0]) & \(authors[1])"
        case 3:
            return "\(authors[0]), \(authors[1]) & \(authors[2])"
        default:
            return "\(authors[0]), \(authors[1]), \(authors[2]) et al."
        }
    }

    private func citationAccessibilityLabel(_ citation: ReviewEvidenceCitation) -> String {
        var label = citation.title
        label += ". By \(formattedAuthors(citation.authors))"
        if let journal = citation.journal {
            label += ". \(journal)"
        }
        if let year = citation.year {
            label += ", \(year)"
        }
        label += ". Evidence level: \(citation.evidenceLevel.displayName)"
        if let relevanceNote = citation.relevanceNote {
            label += ". \(relevanceNote)"
        }
        if citation.doi != nil {
            label += ". DOI link available."
        }
        return label
    }
}

// MARK: - ReviewEvidenceLevel View Helpers

/// Extension providing sort order and color for evidence level ranking.
/// The core enum lives in ProgramReview.swift; these are view-layer additions.
extension ReviewEvidenceLevel {
    /// Sort order for ranking evidence quality (lower = higher quality).
    var sortOrder: Int {
        switch self {
        case .systematicReview: return 0
        case .rct: return 1
        case .cohortStudy: return 2
        case .clinicalGuideline: return 3
        case .caseStudy: return 4
        case .expertOpinion: return 5
        }
    }

    /// Color for evidence level badge display.
    var color: Color {
        switch self {
        case .systematicReview, .rct: return DesignTokens.statusSuccess
        case .cohortStudy, .clinicalGuideline: return DesignTokens.statusInfo
        case .caseStudy, .expertOpinion: return DesignTokens.statusWarning
        }
    }
}

// MARK: - Preview

#if DEBUG

// Sample data for previews
private extension ReviewEvidenceCitation {
    static let sampleGroupedCitations: [String: [ReviewEvidenceCitation]] = [
        "Nordic Hamstring Curls": [
            ReviewEvidenceCitation(
                title: "Eccentric training for prevention of hamstring injuries in elite soccer",
                authors: ["Petersen J", "Thorborg K", "Nielsen MB", "Budtz-Jorgensen E", "Holmich P"],
                journal: "British Journal of Sports Medicine",
                year: 2011,
                doi: "10.1136/bjsm.2010.078691",
                relevanceNote: "RCT demonstrating 65% reduction in new hamstring injuries and 85% reduction in recurrent injuries with Nordic hamstring curls.",
                evidenceLevel: .rct
            ),
            ReviewEvidenceCitation(
                title: "Effectiveness of the Nordic hamstring exercise for injury prevention: a systematic review and meta-analysis",
                authors: ["Al Attar WSA", "Soomro N", "Sinclair PJ", "Pappas E", "Sanders RH"],
                journal: "Sports Medicine",
                year: 2017,
                doi: "10.1007/s40279-016-0645-6",
                relevanceNote: "Meta-analysis of 8,459 athletes showing NHE reduces hamstring injuries by 51% overall.",
                evidenceLevel: .systematicReview
            ),
        ],
        "Hip Strengthening": [
            ReviewEvidenceCitation(
                title: "Hip abductor strengthening in patients with patellofemoral pain syndrome",
                authors: ["Khayambashi K", "Mohammadkhani Z", "Ghaznavi K"],
                journal: "Journal of Athletic Training",
                year: 2012,
                doi: "10.4085/1062-6050-47.2.08",
                relevanceNote: "Demonstrated significant improvement in pain and function with targeted hip abductor exercises.",
                evidenceLevel: .rct
            ),
        ],
        "Plyometric Progression": [
            ReviewEvidenceCitation(
                title: "Return to sport after ACL reconstruction: expert opinion recommendations",
                authors: ["Dingenen B", "Gokeler A"],
                journal: "Journal of Orthopaedic & Sports Physical Therapy",
                year: 2017,
                doi: nil,
                relevanceNote: "Clinical guideline supporting progressive plyometric loading in late-stage ACL rehabilitation.",
                evidenceLevel: .expertOpinion
            ),
            ReviewEvidenceCitation(
                title: "Progressive plyometric training in ACL rehabilitation: a cohort analysis",
                authors: ["Davies GJ", "Riemann BL", "Manske R"],
                journal: "International Journal of Sports Physical Therapy",
                year: 2015,
                doi: "10.26603/ijspt20150721",
                relevanceNote: "Cohort study showing improved limb symmetry index with structured plyometric progression.",
                evidenceLevel: .cohortStudy
            ),
        ],
    ]
}

#Preview("Evidence Citations - Populated") {
    NavigationStack {
        ProgramEvidenceCitationView(
            citations: ReviewEvidenceCitation.sampleGroupedCitations,
            onOpenDOI: { doi in
                print("Open DOI: \(doi)")
            }
        )
        .navigationTitle("Evidence")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Evidence Citations - Empty") {
    NavigationStack {
        ProgramEvidenceCitationView(
            citations: [:]
        )
        .navigationTitle("Evidence")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
