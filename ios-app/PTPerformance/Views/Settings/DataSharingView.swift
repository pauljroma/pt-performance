// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  DataSharingView.swift
//  PTPerformance
//
//  ACP-1061: Secure Therapist-Patient Sharing - Client-side UI
//  Shows who has access to the user's data with revoke and time-limit options
//

import SwiftUI
import Supabase

// MARK: - Data Sharing View

/// View showing which therapists have access to the patient's data,
/// with options to revoke access and configure time-limited sharing.
struct DataSharingView: View {

    @StateObject private var viewModel = DataSharingViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // Header explanation
            overviewSection

            // Active sharing
            if !viewModel.activeShares.isEmpty {
                activeSharingSection
            }

            // No active shares
            if viewModel.activeShares.isEmpty && !viewModel.isLoading {
                noSharesSection
            }

            // Sharing audit trail
            if !viewModel.auditTrail.isEmpty {
                auditTrailSection
            }
        }
        .navigationTitle("Data Sharing")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSharingData()
        }
        .refreshable {
            await viewModel.loadSharingData()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading sharing data...")
            }
        }
        .alert("Revoke Access?", isPresented: $viewModel.showRevokeConfirmation) {
            Button("Revoke", role: .destructive) {
                Task {
                    await viewModel.confirmRevoke()
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelRevoke()
            }
        } message: {
            if let therapist = viewModel.therapistToRevoke {
                Text("This will immediately remove \(therapist.therapistName)'s access to your health and workout data. They will no longer be able to view your progress.")
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "person.2.circle.fill")
                        .foregroundColor(.modusCyan)
                        .font(.title2)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Who Can See Your Data")
                            .font(.headline)
                        Text("Manage therapist access to your health and workout data")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                    Text("You control who has access. Revoke at any time. All sharing changes are logged for your records.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, Spacing.xs)
        }
    }

    // MARK: - Active Sharing Section

    private var activeSharingSection: some View {
        Section {
            ForEach(viewModel.activeShares) { share in
                TherapistShareRow(
                    share: share,
                    onRevoke: {
                        viewModel.requestRevoke(share: share)
                    }
                )
            }
        } header: {
            HStack {
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .foregroundColor(.modusCyan)
                Text("Active Access (\(viewModel.activeShares.count))")
            }
            .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - No Shares Section

    private var noSharesSection: some View {
        Section {
            VStack(spacing: Spacing.md) {
                Image(systemName: "lock.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text("No Active Sharing")
                    .font(.headline)

                Text("No therapists currently have access to your data. Link with a therapist to enable data sharing.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - Audit Trail Section

    private var auditTrailSection: some View {
        Section {
            ForEach(viewModel.auditTrail) { entry in
                AuditTrailRow(entry: entry)
            }
        } header: {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.modusCyan)
                Text("Sharing History")
            }
            .accessibilityAddTraits(.isHeader)
        } footer: {
            Text("Shows recent changes to who can access your data.")
        }
    }
}

// MARK: - Therapist Share Row

private struct TherapistShareRow: View {
    let share: TherapistShare
    let onRevoke: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Therapist info
            HStack(spacing: Spacing.sm) {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.modusCyan)
                    .font(.title2)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(share.therapistName)
                        .font(.body)
                        .fontWeight(.medium)

                    Text("Access level: \(share.accessLevel.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Active indicator
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                    .accessibilityLabel("Active")
            }

            // Access details
            HStack(spacing: Spacing.md) {
                Label(share.grantedDateText, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let expiresText = share.expiresDateText {
                    Label(expiresText, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            // Revoke button
            Button(role: .destructive) {
                onRevoke()
            } label: {
                HStack {
                    Image(systemName: "xmark.shield")
                    Text("Revoke Access")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xs)
                .background(DesignTokens.statusError.opacity(0.1))
                .foregroundStyle(DesignTokens.statusError)
                .cornerRadius(CornerRadius.sm)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Revoke access for \(share.therapistName)")
            .accessibilityHint("Immediately removes this therapist's access to your data")
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Audit Trail Row

private struct AuditTrailRow: View {
    let entry: SharingAuditEntry

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: entry.action.icon)
                .foregroundStyle(entry.action.color)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(entry.description)
                    .font(.subheadline)
                Text(entry.dateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.description). \(entry.dateText)")
    }
}

// MARK: - Data Models

/// Represents active data sharing with a therapist
struct TherapistShare: Identifiable {
    let id: String
    let therapistId: String
    let therapistName: String
    let accessLevel: SharingAccessLevel
    let grantedAt: Date
    let expiresAt: Date?

    /// Cached DateFormatter for medium-date display
    private static let mediumDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var grantedDateText: String {
        return "Since \(Self.mediumDateFormatter.string(from: grantedAt))"
    }

    var expiresDateText: String? {
        guard let expiresAt = expiresAt else { return nil }
        return "Expires \(Self.mediumDateFormatter.string(from: expiresAt))"
    }
}

/// Access level for sharing
enum SharingAccessLevel: String {
    case readOnly = "read_only"
    case readWrite = "read_write"
    case full = "full"

    var displayName: String {
        switch self {
        case .readOnly: return "View Only"
        case .readWrite: return "View & Edit"
        case .full: return "Full Access"
        }
    }
}

/// An entry in the sharing audit trail
struct SharingAuditEntry: Identifiable {
    let id: String
    let action: SharingAction
    let therapistName: String
    let date: Date
    let description: String

    /// Cached RelativeDateTimeFormatter for audit trail timestamps
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var dateText: String {
        return Self.relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }
}

/// Types of sharing actions for the audit trail
enum SharingAction {
    case granted
    case revoked
    case expired
    case modified

    var icon: String {
        switch self {
        case .granted: return "plus.circle.fill"
        case .revoked: return "minus.circle.fill"
        case .expired: return "clock.badge.xmark"
        case .modified: return "pencil.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .granted: return .green
        case .revoked: return .red
        case .expired: return .orange
        case .modified: return .modusCyan
        }
    }
}

// MARK: - View Model

@MainActor
final class DataSharingViewModel: ObservableObject {

    @Published var activeShares: [TherapistShare] = []
    @Published var auditTrail: [SharingAuditEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showRevokeConfirmation = false
    @Published var therapistToRevoke: TherapistShare?

    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    // MARK: - Codable Response Types

    private struct TherapistLinkRow: Codable {
        let therapist_id: UUID
        let linked_at: Date?
        let sharing_expires_at: Date?
        let access_level: String?
    }

    private struct TherapistNameRow: Codable {
        let id: UUID
        let first_name: String
        let last_name: String
    }

    private struct SharingAuditRow: Codable {
        let id: UUID
        let action: String
        let therapist_name: String?
        let created_at: Date
        let description: String?
    }

    // MARK: - Data Loading

    func loadSharingData() async {
        isLoading = true
        defer { isLoading = false }

        guard let patientId = supabase.userId else {
            errorMessage = "Please sign in to view sharing settings."
            return
        }

        do {
            try await loadActiveShares(patientId: patientId)
            try await loadAuditTrail(patientId: patientId)
        } catch {
            logger.log("[DataSharingVM] Failed to load sharing data: \(error.localizedDescription)", level: .error)
            errorMessage = "Could not load sharing data. Please try again."
        }
    }

    private func loadActiveShares(patientId: String) async throws {
        // Query the patient's therapist links
        let links: [TherapistLinkRow] = try await supabase.client
            .from("patients")
            .select("therapist_id, linked_at, sharing_expires_at, access_level")
            .eq("id", value: patientId)
            .execute()
            .value

        var shares: [TherapistShare] = []

        for link in links {
            guard let therapistId = Optional(link.therapist_id) else { continue }

            // Fetch therapist name
            let therapists: [TherapistNameRow] = try await supabase.client
                .from("therapists")
                .select("id, first_name, last_name")
                .eq("id", value: therapistId.uuidString)
                .execute()
                .value

            if let therapist = therapists.first {
                let share = TherapistShare(
                    id: therapist.id.uuidString,
                    therapistId: therapist.id.uuidString,
                    therapistName: "\(therapist.first_name) \(therapist.last_name)",
                    accessLevel: SharingAccessLevel(rawValue: link.access_level ?? "read_only") ?? .readOnly,
                    grantedAt: link.linked_at ?? Date(),
                    expiresAt: link.sharing_expires_at
                )
                shares.append(share)
            }
        }

        activeShares = shares
    }

    private func loadAuditTrail(patientId: String) async throws {
        // Try to load audit trail - table may not exist yet, which is fine
        do {
            let rows: [SharingAuditRow] = try await supabase.client
                .from("sharing_audit_log")
                .select()
                .eq("patient_id", value: patientId)
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value

            auditTrail = rows.map { row in
                let action: SharingAction
                switch row.action {
                case "granted": action = .granted
                case "revoked": action = .revoked
                case "expired": action = .expired
                case "modified": action = .modified
                default: action = .modified
                }

                return SharingAuditEntry(
                    id: row.id.uuidString,
                    action: action,
                    therapistName: row.therapist_name ?? "Unknown",
                    date: row.created_at,
                    description: row.description ?? "\(row.action.capitalized) access for \(row.therapist_name ?? "therapist")"
                )
            }
        } catch {
            // Audit trail table may not exist yet - this is expected
            logger.log("[DataSharingVM] Audit trail not available: \(error.localizedDescription)", level: .diagnostic)
            auditTrail = []
        }
    }

    // MARK: - Revoke Access

    func requestRevoke(share: TherapistShare) {
        therapistToRevoke = share
        showRevokeConfirmation = true
    }

    func cancelRevoke() {
        therapistToRevoke = nil
        showRevokeConfirmation = false
    }

    func confirmRevoke() async {
        guard let share = therapistToRevoke else { return }

        do {
            guard let patientId = supabase.userId else {
                errorMessage = "Please sign in to manage sharing."
                return
            }

            // Call edge function to revoke therapist access
            let bodyData = try JSONEncoder().encode([
                "patient_id": patientId,
                "therapist_id": share.therapistId
            ])

            try await supabase.client.functions.invoke(
                "revoke-therapist-access",
                options: FunctionInvokeOptions(body: bodyData)
            )

            // Remove from local state
            activeShares.removeAll { $0.id == share.id }

            // Add to audit trail locally
            let auditEntry = SharingAuditEntry(
                id: UUID().uuidString,
                action: .revoked,
                therapistName: share.therapistName,
                date: Date(),
                description: "Revoked access for \(share.therapistName)"
            )
            auditTrail.insert(auditEntry, at: 0)

            logger.log("[DataSharingVM] Revoked access for therapist \(share.therapistId)", level: .success)

        } catch {
            logger.log("[DataSharingVM] Failed to revoke access: \(error.localizedDescription)", level: .error)
            errorMessage = "Could not revoke access. Please try again."
        }

        therapistToRevoke = nil
        showRevokeConfirmation = false
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DataSharingView()
    }
}
