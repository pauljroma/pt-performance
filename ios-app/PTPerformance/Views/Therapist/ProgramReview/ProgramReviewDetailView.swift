//
//  ProgramReviewDetailView.swift
//  PTPerformance
//
//  ACP-395: Review and Approval Workflow
//  Detailed review interface for a single AI-generated rehabilitation program
//

import SwiftUI

// MARK: - Program Review Detail View

/// Full review interface for a single AI-generated program.
///
/// Presents a scrollable view with sections for safety contraindications,
/// program overview (edits made, evidence citations), and review actions.
/// A sticky bottom bar provides primary approve/reject/revise actions.
struct ProgramReviewDetailView: View {

    // MARK: - Properties

    let review: ProgramReview

    // MARK: - State

    @StateObject private var viewModel: ProgramReviewDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showApprovalSheet = false
    @State private var showRejectAlert = false
    @State private var showNotesSheet = false
    @State private var showDiffView = false
    @State private var rejectionReason = ""
    @State private var expandedCitations = false

    // MARK: - Initialization

    init(review: ProgramReview) {
        self.review = review
        _viewModel = StateObject(wrappedValue: ProgramReviewDetailViewModel(review: review))
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else {
                    reviewContent
                }
            }

            // Sticky bottom action bar
            if !viewModel.isLoading && viewModel.error == nil && review.status.isEditable {
                actionBar
            }
        }
        .navigationTitle("Review Program")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showNotesSheet = true
                    } label: {
                        Label("Add Notes", systemImage: "note.text")
                    }

                    if !review.editsMade.isEmpty {
                        Button {
                            showDiffView = true
                        } label: {
                            Label("View Changes", systemImage: "arrow.left.arrow.right")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showApprovalSheet) {
            ReviewApprovalSheet(
                review: review,
                onApprove: { notes in
                    Task {
                        await viewModel.approveProgram(notes: notes)
                        if viewModel.error == nil {
                            HapticFeedback.success()
                            dismiss()
                        }
                    }
                },
                onReject: { reason in
                    Task {
                        await viewModel.rejectProgram(reason: reason)
                        if viewModel.error == nil {
                            HapticFeedback.warning()
                            dismiss()
                        }
                    }
                },
                onRequestRevision: { notes in
                    Task {
                        await viewModel.requestRevision(notes: notes)
                        if viewModel.error == nil {
                            HapticFeedback.medium()
                            dismiss()
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showNotesSheet) {
            reviewNotesSheet
        }
        .sheet(isPresented: $showDiffView) {
            NavigationStack {
                ProgramDiffView(edits: review.editsMade)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showDiffView = false
                            }
                        }
                    }
            }
        }
        .alert("Reject Program", isPresented: $showRejectAlert) {
            TextField("Reason for rejection", text: $rejectionReason)
            Button("Cancel", role: .cancel) {
                rejectionReason = ""
            }
            Button("Reject", role: .destructive) {
                Task {
                    await viewModel.rejectProgram(reason: rejectionReason)
                    if viewModel.error == nil {
                        HapticFeedback.warning()
                        dismiss()
                    }
                }
            }
            .disabled(rejectionReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Please provide a reason for rejecting this program. This will be recorded for audit purposes.")
        }
        .task {
            await viewModel.startReview()
        }
    }

    // MARK: - Review Content

    private var reviewContent: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // Header card
                headerSection

                // Safety contraindications (critical first)
                if !review.contraindications.isEmpty {
                    safetySection
                }

                // Program overview (edits, notes)
                programOverviewSection

                // Evidence citations
                if !review.evidenceCitations.isEmpty {
                    evidenceSection
                }

                // Review notes (if any)
                if let notes = review.reviewNotes, !notes.isEmpty {
                    reviewNotesSection(notes)
                }

                // Rejection reason (if rejected)
                if let reason = review.rejectionReason, !reason.isEmpty {
                    rejectionReasonSection(reason)
                }

                // Spacer for bottom action bar
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Status row
                HStack {
                    Text("Program Review")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    ReviewStatusBadge(status: review.status)
                }

                // Program ID
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "doc.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)

                    Text("Program: \(review.programId.uuidString.prefix(8))...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // AI info row
                if review.aiGenerated {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("AI Model")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            HStack(spacing: Spacing.xxs) {
                                Image(systemName: "cpu")
                                    .font(.caption)
                                    .foregroundColor(DesignTokens.statusInfo)
                                Text(review.aiModel ?? "Unknown")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }

                        Spacer()

                        if let confidence = review.aiConfidenceScore {
                            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                                Text("Confidence")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                AIConfidenceBadge(score: confidence)
                            }
                        }
                    }
                }

                // Submitted time
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    Text("Submitted \(review.createdAt, format: .dateTime.month().day().year().hour().minute())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Approved time (if applicable)
                if let approvedAt = review.approvedAt {
                    HStack {
                        Image(systemName: "checkmark.seal")
                            .font(.caption)
                            .foregroundColor(DesignTokens.statusSuccess)
                            .accessibilityHidden(true)
                        Text("Approved \(approvedAt, format: .dateTime.month().day().year().hour().minute())")
                            .font(.caption)
                            .foregroundColor(DesignTokens.statusSuccess)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Safety Section

    private var safetySection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: "shield.exclamationmark")
                    .foregroundColor(DesignTokens.statusError)
                Text("Safety Review")
                    .font(.headline)
            }
            .accessibilityAddTraits(.isHeader)

            ForEach(sortedContraindications) { contraindication in
                ContraindicationBanner(contraindication: contraindication)
            }
        }
    }

    private var sortedContraindications: [ReviewContraindication] {
        review.contraindications.sorted { lhs, rhs in
            lhs.severity.sortOrder < rhs.severity.sortOrder
        }
    }

    // MARK: - Program Overview Section

    private var programOverviewSection: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(DesignTokens.statusInfo)
                    Text("Review Summary")
                        .font(.headline)
                }
                .accessibilityAddTraits(.isHeader)

                Divider()

                // Stats grid
                HStack(spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Edits Made")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text("\(review.editCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Citations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text("\(review.evidenceCitations.count)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Flags")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text("\(review.contraindications.count)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(review.hasCriticalContraindications ? DesignTokens.statusError : .primary)
                    }
                }

                // Edits link
                if !review.editsMade.isEmpty {
                    Divider()

                    Button {
                        HapticFeedback.light()
                        showDiffView = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.caption)
                            Text("View \(review.editCount) \(review.editCount == 1 ? "edit" : "edits") made")
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(DesignTokens.statusInfo)
                    }
                    .accessibilityLabel("View \(review.editCount) edits made to the program")
                }

                // Careful review warning
                if review.needsCarefulReview {
                    Divider()

                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.body)
                            .foregroundColor(DesignTokens.statusWarning)
                            .accessibilityHidden(true)

                        Text("Low AI confidence -- this program requires careful review before approval.")
                            .font(.caption)
                            .foregroundColor(DesignTokens.statusWarning)
                    }
                }
            }
        }
    }

    // MARK: - Evidence Section

    private var evidenceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Button {
                HapticFeedback.selectionChanged()
                withAnimation(.easeInOut(duration: AnimationDuration.standard)) {
                    expandedCitations.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "book.closed")
                        .foregroundColor(DesignTokens.statusInfo)
                    Text("Evidence Citations")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(review.evidenceCitations.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Image(systemName: expandedCitations ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityLabel("Evidence Citations, \(review.evidenceCitations.count) items")
            .accessibilityHint("Double tap to \(expandedCitations ? "collapse" : "expand")")
            .accessibilityAddTraits(.isHeader)

            if expandedCitations {
                ForEach(review.evidenceCitations) { citation in
                    ReviewCitationRow(citation: citation)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Review Notes Section

    private func reviewNotesSection(_ notes: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(DesignTokens.statusInfo)
                    Text("Review Notes")
                        .font(.headline)
                }
                .accessibilityAddTraits(.isHeader)

                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Rejection Reason Section

    private func rejectionReasonSection(_ reason: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "xmark.seal.fill")
                .font(.body)
                .foregroundColor(DesignTokens.statusError)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Rejection Reason")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.statusError)

                Text(reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.sm)
        .background(DesignTokens.statusError.opacity(0.08))
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(DesignTokens.statusError.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: Spacing.sm) {
                // Reject button
                Button {
                    HapticFeedback.medium()
                    showRejectAlert = true
                } label: {
                    Label("Reject", systemImage: "xmark")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.bordered)
                .tint(DesignTokens.statusError)

                // Approve button
                Button {
                    HapticFeedback.sheetPresented()
                    showApprovalSheet = true
                } label: {
                    Label("Review & Approve", systemImage: "checkmark.seal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignTokens.statusSuccess)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
            Text("Loading program details...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task {
                    await viewModel.startReview()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Notes Sheet

    private var reviewNotesSheet: some View {
        NavigationStack {
            Form {
                Section("Review Notes") {
                    TextEditor(text: $viewModel.reviewNotes)
                        .frame(minHeight: 120)
                        .accessibilityLabel("Review notes")
                }

                Section {
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "info.circle")
                            .foregroundColor(DesignTokens.statusInfo)
                            .font(.body)
                            .accessibilityHidden(true)

                        Text("Notes will be saved with the review record and visible to other therapists.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, Spacing.xxs)
                }
            }
            .navigationTitle("Review Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showNotesSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.saveNotes()
                        }
                        HapticFeedback.success()
                        showNotesSheet = false
                    }
                }
            }
        }
    }
}

// MARK: - ReviewContraindication Banner

struct ContraindicationBanner: View {
    let contraindication: ReviewContraindication

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: contraindication.severity.iconName)
                .font(.body)
                .foregroundColor(contraindication.severity.color)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack {
                    Text(contraindication.type)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(contraindication.severity.color)

                    Spacer()

                    Text(contraindication.severity.displayName.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(contraindication.severity.color.opacity(0.2))
                        .foregroundColor(contraindication.severity.color)
                        .cornerRadius(CornerRadius.xs)
                }

                Text(contraindication.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !contraindication.affectedExercises.isEmpty {
                    HStack(spacing: Spacing.xxs) {
                        Text("Affected exercises:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(contraindication.affectedExercises.count)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(contraindication.severity.color)
                    }
                }
            }
        }
        .padding(Spacing.sm)
        .background(contraindication.severity.color.opacity(0.08))
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(contraindication.severity.color.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(contraindication.severity.displayName) contraindication: \(contraindication.type). \(contraindication.description)")
    }
}

// MARK: - Review Citation Row

/// Displays a single evidence citation from the ProgramReview model.
///
/// Displays a single evidence citation from the ProgramReview model.
/// Uses `ReviewEvidenceCitation` (ACP-395 variant) with: title, authors, journal,
/// year, doi, relevanceNote, evidenceLevel, formattedAuthors.
struct ReviewCitationRow: View {
    let citation: ReviewEvidenceCitation

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Title
                Text(citation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                // Authors
                if !citation.authors.isEmpty {
                    Text(citation.formattedAuthors)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Journal and year
                HStack(spacing: Spacing.xs) {
                    if let journal = citation.journal {
                        Text(journal)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }

                    if let year = citation.year {
                        Text("(\(String(year)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Evidence level badge + DOI link
                HStack(spacing: Spacing.xs) {
                    EvidenceLevelBadge(level: citation.evidenceLevel)

                    Spacer()

                    if let doi = citation.doi, !doi.isEmpty {
                        Link(destination: URL(string: "https://doi.org/\(doi)") ?? URL(string: "https://doi.org")!) {
                            Label("DOI", systemImage: "link")
                                .font(.caption)
                        }
                    }
                }

                // Relevance note
                if let relevanceNote = citation.relevanceNote, !relevanceNote.isEmpty {
                    HStack(alignment: .top, spacing: Spacing.xxs) {
                        Image(systemName: "text.quote")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)

                        Text(relevanceNote)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .padding(.top, Spacing.xxs)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(citation.title), \(citation.formattedAuthors), Evidence level: \(citation.evidenceLevel.displayName)")
    }
}

// MARK: - Evidence Level Badge

struct EvidenceLevelBadge: View {
    let level: ReviewEvidenceLevel

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "shield.checkered")
                .font(.caption2)
            Text(level.displayName)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(badgeColor.opacity(0.12))
        .foregroundColor(badgeColor)
        .cornerRadius(CornerRadius.xs)
        .accessibilityLabel("Evidence level: \(level.displayName)")
    }

    private var badgeColor: Color {
        switch level.rank {
        case 1...2:
            return DesignTokens.statusSuccess
        case 3...4:
            return DesignTokens.statusInfo
        default:
            return DesignTokens.statusWarning
        }
    }
}

// MARK: - Detail View Model

@MainActor
class ProgramReviewDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    @Published var reviewNotes = ""

    private let review: ProgramReview
    private let reviewService = ProgramReviewService()

    init(review: ProgramReview) {
        self.review = review
        self.reviewNotes = review.reviewNotes ?? ""
    }

    func startReview() async {
        guard review.status == .pendingReview else { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await reviewService.startReview(reviewId: review.id)
        } catch {
            self.error = "Failed to start review: \(error.localizedDescription)"
        }
    }

    func approveProgram(notes: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await reviewService.approveProgram(reviewId: review.id, notes: notes.isEmpty ? nil : notes)
        } catch {
            self.error = "Failed to approve program: \(error.localizedDescription)"
            HapticFeedback.error()
        }
    }

    func rejectProgram(reason: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await reviewService.rejectProgram(reviewId: review.id, reason: reason)
        } catch {
            self.error = "Failed to reject program: \(error.localizedDescription)"
            HapticFeedback.error()
        }
    }

    func requestRevision(notes: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await reviewService.requestRevision(reviewId: review.id, notes: notes)
        } catch {
            self.error = "Failed to request revision: \(error.localizedDescription)"
            HapticFeedback.error()
        }
    }

    func saveNotes() async {
        guard !reviewNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        do {
            try await reviewService.addNote(reviewId: review.id, note: reviewNotes)
        } catch {
            self.error = "Failed to save notes: \(error.localizedDescription)"
            HapticFeedback.error()
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Review Detail - Pending") {
    NavigationStack {
        ProgramReviewDetailView(review: ProgramReview.samplePending)
    }
}

#Preview("Review Detail - Approved") {
    NavigationStack {
        ProgramReviewDetailView(review: ProgramReview.sampleApproved)
    }
}

#Preview("Review Detail - Rejected") {
    NavigationStack {
        ProgramReviewDetailView(review: ProgramReview.sampleRejected)
    }
}

#Preview("ReviewContraindication Banners") {
    VStack(spacing: Spacing.sm) {
        ContraindicationBanner(contraindication: .sampleCritical)
        ContraindicationBanner(contraindication: .sampleWarning)
        ContraindicationBanner(contraindication: .sampleInfo)
    }
    .padding()
}

#Preview("Evidence Level Badges") {
    HStack(spacing: Spacing.sm) {
        EvidenceLevelBadge(level: .systematicReview)
        EvidenceLevelBadge(level: .rct)
        EvidenceLevelBadge(level: .cohortStudy)
        EvidenceLevelBadge(level: .expertOpinion)
    }
    .padding()
}
#endif
