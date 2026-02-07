//
//  RTSClearanceView.swift
//  PTPerformance
//
//  Clearance document creation and viewing for Return-to-Sport protocols
//  Supports creating, editing, and signing clearance documents
//

import SwiftUI

// MARK: - RTS Clearance View

/// Clearance document creation and viewing
struct RTSClearanceView: View {
    let clearance: RTSClearance?  // nil for new clearance
    let protocolId: UUID
    @StateObject private var viewModel = RTSClearanceViewModel()

    @Environment(\.dismiss) private var dismiss

    @State private var showSignConfirmation = false
    @State private var showDiscardConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header with status
                clearanceHeader

                // Clearance type selector
                if viewModel.canEdit {
                    clearanceTypeSelector
                }

                // Traffic light level selector
                trafficLightSelector

                // Assessment summary
                assessmentSection

                // Recommendations
                recommendationsSection

                // Restrictions (optional)
                restrictionsSection

                // Physician signature toggle
                if viewModel.canEdit {
                    physicianSignatureToggle
                }

                // Signature section
                if viewModel.isSigned {
                    signatureSection
                }

                // Action buttons
                actionButtons
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(clearance == nil ? "New Clearance" : "Clearance Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.canEdit && viewModel.hasChanges {
                    Button("Cancel") {
                        showDiscardConfirmation = true
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.canEdit {
                    Button("Save") {
                        saveDocument()
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
        }
        .alert("Sign Clearance", isPresented: $showSignConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign & Lock") {
                signDocument()
            }
        } message: {
            Text("Signing this clearance document will lock it for editing. This action cannot be undone.")
        }
        .alert("Discard Changes?", isPresented: $showDiscardConfirmation) {
            Button("Keep Editing", role: .cancel) { }
            Button("Discard", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("You have unsaved changes that will be lost.")
        }
        .onAppear {
            viewModel.configure(clearance: clearance, protocolId: protocolId)
        }
    }

    // MARK: - Clearance Header

    private var clearanceHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: viewModel.clearanceType.icon)
                        .foregroundColor(viewModel.clearanceType.color)

                    Text(viewModel.clearanceType.displayName)
                        .font(.headline)
                }

                Text(viewModel.status.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status badge
            HStack(spacing: 4) {
                Image(systemName: viewModel.status.icon)
                Text(viewModel.status.displayName)
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(viewModel.status.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(viewModel.status.color.opacity(0.15))
            .cornerRadius(CornerRadius.sm)
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Clearance Type Selector

    private var clearanceTypeSelector: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Clearance Type")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: Spacing.sm) {
                ForEach(RTSClearanceType.allCases, id: \.self) { type in
                    Button {
                        HapticFeedback.selectionChanged()
                        viewModel.clearanceType = type
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: type.icon)
                                .foregroundColor(type.color)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)

                                Text(type.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if viewModel.clearanceType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(viewModel.clearanceType == type
                                    ? Color.blue.opacity(0.1)
                                    : Color(.systemBackground)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(viewModel.clearanceType == type ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Traffic Light Selector

    private var trafficLightSelector: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Clearance Level")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: Spacing.md) {
                ForEach(RTSTrafficLight.allCases, id: \.self) { level in
                    Button {
                        if viewModel.canEdit {
                            HapticFeedback.selectionChanged()
                            viewModel.clearanceLevel = level
                        }
                    } label: {
                        VStack(spacing: Spacing.xs) {
                            ZStack {
                                Circle()
                                    .fill(level.color.opacity(viewModel.clearanceLevel == level ? 1.0 : 0.3))
                                    .frame(width: 48, height: 48)

                                if viewModel.clearanceLevel == level {
                                    Image(systemName: "checkmark")
                                        .font(.body)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }

                            Text(level.displayName)
                                .font(.caption)
                                .foregroundColor(viewModel.clearanceLevel == level ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!viewModel.canEdit)
                }
            }
            .padding(Spacing.md)
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.lg)
        }
    }

    // MARK: - Assessment Section

    private var assessmentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Assessment Summary")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if viewModel.canEdit {
                TextEditor(text: $viewModel.assessmentSummary)
                    .font(.body)
                    .frame(minHeight: 120)
                    .padding(Spacing.sm)
                    .background(Color(.systemBackground))
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .overlay(placeholderOverlay("Summarize the assessment findings..."), alignment: .topLeading)
            } else {
                Text(viewModel.assessmentSummary)
                    .font(.body)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(CornerRadius.md)
            }
        }
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recommendations")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if viewModel.canEdit {
                TextEditor(text: $viewModel.recommendations)
                    .font(.body)
                    .frame(minHeight: 100)
                    .padding(Spacing.sm)
                    .background(Color(.systemBackground))
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .overlay(placeholderOverlay("Enter recommendations for the patient..."), alignment: .topLeading)
            } else {
                Text(viewModel.recommendations)
                    .font(.body)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(CornerRadius.md)
            }
        }
    }

    // MARK: - Restrictions Section

    private var restrictionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Restrictions")
                    .font(.headline)

                Text("(Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityAddTraits(.isHeader)

            if viewModel.canEdit {
                TextEditor(text: $viewModel.restrictions)
                    .font(.body)
                    .frame(minHeight: 80)
                    .padding(Spacing.sm)
                    .background(Color(.systemBackground))
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .overlay(placeholderOverlay("List any activity restrictions..."), alignment: .topLeading)
            } else if !viewModel.restrictions.isEmpty {
                Text(viewModel.restrictions)
                    .font(.body)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(CornerRadius.md)
            }
        }
    }

    // MARK: - Physician Signature Toggle

    private var physicianSignatureToggle: some View {
        Toggle(isOn: $viewModel.requiresPhysicianSignature) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Requires Physician Co-Signature")
                    .font(.subheadline)

                Text("Enable if this clearance needs physician approval")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Signature Section

    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Signatures")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: Spacing.sm) {
                // Primary signature
                HStack {
                    Image(systemName: "signature")
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Signed by Therapist")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if let date = viewModel.signedAt {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }
                .padding(Spacing.md)
                .background(Color.green.opacity(0.1))
                .cornerRadius(CornerRadius.md)

                // Co-signature (if required)
                if viewModel.requiresPhysicianSignature {
                    if let coSignedAt = viewModel.coSignedAt {
                        HStack {
                            Image(systemName: "signature")
                                .foregroundColor(.purple)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Co-Signed by Physician")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text(coSignedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                        }
                        .padding(Spacing.md)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(CornerRadius.md)
                    } else {
                        HStack {
                            Image(systemName: "clock.badge.exclamationmark")
                                .foregroundColor(.orange)

                            Text("Awaiting physician co-signature")
                                .font(.subheadline)
                                .foregroundColor(.orange)

                            Spacer()
                        }
                        .padding(Spacing.md)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(CornerRadius.md)
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            // Sign button (when status is complete)
            if viewModel.canSign {
                Button {
                    showSignConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "signature")
                        Text("Sign Clearance")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.blue)
                    .cornerRadius(CornerRadius.lg)
                }
            }

            // Mark as complete (when draft)
            if viewModel.status == .draft && viewModel.isValid {
                Button {
                    markAsComplete()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Mark as Complete")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(CornerRadius.lg)
                }
            }
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func placeholderOverlay(_ text: String) -> some View {
        if viewModel.assessmentSummary.isEmpty && text.contains("assessment") ||
           viewModel.recommendations.isEmpty && text.contains("recommendations") ||
           viewModel.restrictions.isEmpty && text.contains("restrictions") {
            Text(text)
                .font(.body)
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.horizontal, Spacing.sm + 5)
                .padding(.vertical, Spacing.sm + 8)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Actions

    private func saveDocument() {
        HapticFeedback.light()
        Task {
            await viewModel.save()
            if viewModel.errorMessage == nil {
                dismiss()
            }
        }
    }

    private func markAsComplete() {
        HapticFeedback.medium()
        Task {
            await viewModel.markAsComplete()
        }
    }

    private func signDocument() {
        HapticFeedback.success()
        Task {
            await viewModel.sign()
        }
    }
}

// MARK: - RTS Clearance ViewModel

/// ViewModel for managing clearance document state
@MainActor
class RTSClearanceViewModel: ObservableObject {
    @Published var clearanceType: RTSClearanceType = .phaseClearance
    @Published var clearanceLevel: RTSTrafficLight = .yellow
    @Published var status: RTSClearanceStatus = .draft
    @Published var assessmentSummary: String = ""
    @Published var recommendations: String = ""
    @Published var restrictions: String = ""
    @Published var requiresPhysicianSignature: Bool = false
    @Published var signedAt: Date?
    @Published var coSignedAt: Date?

    @Published var isSaving = false
    @Published var errorMessage: String?

    private var clearanceId: UUID?
    private var protocolId: UUID?
    private var originalClearance: RTSClearance?

    private let rtsService = RTSService.shared

    // MARK: - Computed Properties

    var canEdit: Bool {
        status == .draft
    }

    var canSign: Bool {
        status == .complete
    }

    var isSigned: Bool {
        status == .signed || status == .coSigned
    }

    var isValid: Bool {
        !assessmentSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !recommendations.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasChanges: Bool {
        guard let original = originalClearance else {
            return !assessmentSummary.isEmpty || !recommendations.isEmpty || !restrictions.isEmpty
        }

        return clearanceType != original.clearanceType ||
               clearanceLevel != original.clearanceLevel ||
               assessmentSummary != original.assessmentSummary ||
               recommendations != original.recommendations ||
               restrictions != (original.restrictions ?? "") ||
               requiresPhysicianSignature != original.requiresPhysicianSignature
    }

    // MARK: - Methods

    func configure(clearance: RTSClearance?, protocolId: UUID) {
        self.protocolId = protocolId
        self.originalClearance = clearance

        if let clearance = clearance {
            self.clearanceId = clearance.id
            self.clearanceType = clearance.clearanceType
            self.clearanceLevel = clearance.clearanceLevel
            self.status = clearance.status
            self.assessmentSummary = clearance.assessmentSummary
            self.recommendations = clearance.recommendations
            self.restrictions = clearance.restrictions ?? ""
            self.requiresPhysicianSignature = clearance.requiresPhysicianSignature
            self.signedAt = clearance.signedAt
            self.coSignedAt = clearance.coSignedAt
        }
    }

    func save() async {
        guard let protocolId = protocolId else { return }

        isSaving = true
        errorMessage = nil

        do {
            let input = RTSClearanceInput(
                protocolId: protocolId.uuidString,
                clearanceType: clearanceType.rawValue,
                clearanceLevel: clearanceLevel.rawValue,
                status: status.rawValue,
                assessmentSummary: assessmentSummary,
                recommendations: recommendations,
                restrictions: restrictions.isEmpty ? nil : restrictions,
                requiresPhysicianSignature: requiresPhysicianSignature
            )

            if let existingId = clearanceId {
                let updated = try await rtsService.updateClearance(id: existingId, input: input)
                originalClearance = updated
            } else {
                let created = try await rtsService.createClearance(input: input)
                clearanceId = created.id
                originalClearance = created
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    func markAsComplete() async {
        guard let id = clearanceId else {
            await save()
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let updated = try await rtsService.completeClearance(id: id)
            status = updated.status
            originalClearance = updated
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    func sign() async {
        guard let id = clearanceId else { return }

        isSaving = true
        errorMessage = nil

        do {
            // Get current user ID (would come from auth)
            let signerId = UUID() // Placeholder

            let updated = try await rtsService.signClearance(id: id, signedBy: signerId)
            status = updated.status
            signedAt = updated.signedAt
            originalClearance = updated
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}

// MARK: - Preview

#if DEBUG
struct RTSClearanceView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // New clearance
            NavigationStack {
                RTSClearanceView(
                    clearance: nil,
                    protocolId: UUID()
                )
            }
            .previewDisplayName("New Clearance")

            // Existing draft
            NavigationStack {
                RTSClearanceView(
                    clearance: RTSClearance.draftSample,
                    protocolId: UUID()
                )
            }
            .previewDisplayName("Draft Clearance")

            // Signed clearance
            NavigationStack {
                RTSClearanceView(
                    clearance: RTSClearance.signedSample,
                    protocolId: UUID()
                )
            }
            .previewDisplayName("Signed Clearance")
        }
    }
}
#endif
