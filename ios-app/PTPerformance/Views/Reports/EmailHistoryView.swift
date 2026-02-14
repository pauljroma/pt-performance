//
//  EmailHistoryView.swift
//  PTPerformance
//
//  View for displaying email history sent to a patient
//  Includes status indicators, filtering, and resend options
//

import SwiftUI

// MARK: - Email History View

struct EmailHistoryView: View {
    let patient: Patient

    @State private var emailHistory: [EmailHistoryItem] = []
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var filter = EmailHistoryFilter()
    @State private var showFilterSheet = false
    @State private var resendingEmailId: UUID?
    @State private var showResendError = false
    @State private var resendErrorMessage = ""
    @State private var showResendSuccess = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = loadError {
                    errorView(error)
                } else if filteredHistory.isEmpty {
                    emptyView
                } else {
                    emailListView
                }
            }
            .navigationTitle("Email History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    filterButton
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                EmailHistoryFilterSheet(filter: $filter)
            }
            .alert("Resend Failed", isPresented: $showResendError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resendErrorMessage)
            }
            .alert("Email Resent", isPresented: $showResendSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The email has been resent successfully.")
            }
            .task {
                await loadEmailHistory()
            }
            .refreshable {
                await loadEmailHistory()
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredHistory: [EmailHistoryItem] {
        if filter.hasActiveFilters {
            return emailHistory.filter { filter.matches($0) }
        }
        return emailHistory
    }

    // MARK: - Views

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
            Text("Loading email history...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text("Failed to load email history")
                .font(.headline)

            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await loadEmailHistory()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text(filter.hasActiveFilters ? "No Matching Emails" : "No Emails Sent")
                .font(.title2)
                .fontWeight(.semibold)

            Text(filter.hasActiveFilters
                 ? "Try adjusting your filters"
                 : "Emails you send to this patient will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if filter.hasActiveFilters {
                Button("Clear Filters") {
                    filter = EmailHistoryFilter()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emailListView: some View {
        List {
            // Active filter indicator
            if filter.hasActiveFilters {
                activeFiltersSection
            }

            // Email list
            ForEach(filteredHistory) { item in
                EmailHistoryRow(
                    item: item,
                    isResending: resendingEmailId == item.id,
                    onResend: {
                        Task {
                            await resendEmail(item)
                        }
                    }
                )
            }
        }
        .listStyle(.insetGrouped)
    }

    private var activeFiltersSection: some View {
        Section {
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .foregroundColor(.blue)

                Text("Filters active")
                    .font(.subheadline)

                Spacer()

                Button("Clear") {
                    filter = EmailHistoryFilter()
                    HapticFeedback.light()
                }
                .font(.subheadline)
            }
        }
    }

    private var filterButton: some View {
        Button {
            showFilterSheet = true
        } label: {
            Image(systemName: filter.hasActiveFilters
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel(filter.hasActiveFilters ? "Filters active" : "Filter")
    }

    // MARK: - Actions

    private func loadEmailHistory() async {
        isLoading = true
        loadError = nil

        do {
            if filter.hasActiveFilters {
                emailHistory = try await EmailDeliveryService.shared.getEmailHistory(
                    patientId: patient.id,
                    filter: filter
                )
            } else {
                emailHistory = try await EmailDeliveryService.shared.getEmailHistory(
                    patientId: patient.id
                )
            }
            isLoading = false
        } catch {
            loadError = error.localizedDescription
            isLoading = false
        }
    }

    private func resendEmail(_ item: EmailHistoryItem) async {
        resendingEmailId = item.id

        do {
            _ = try await EmailDeliveryService.shared.resendEmail(emailId: item.id)
            resendingEmailId = nil
            showResendSuccess = true
            HapticFeedback.success()

            // Refresh list
            await loadEmailHistory()
        } catch {
            resendingEmailId = nil
            resendErrorMessage = error.localizedDescription
            showResendError = true
            HapticFeedback.error()
        }
    }
}

// MARK: - Email History Row

struct EmailHistoryRow: View {
    let item: EmailHistoryItem
    let isResending: Bool
    let onResend: () -> Void

    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header with status
            HStack(spacing: Spacing.sm) {
                statusBadge

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.subject)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text(item.recipientEmail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(item.shortDateDisplay)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Expandable details
            if showDetails {
                detailsView
            }

            // Action buttons for failed emails
            if item.status.canResend {
                resendButton
            }
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showDetails.toggle()
            }
            HapticFeedback.light()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.subject), to \(item.recipientEmail), status: \(item.status.displayName)")
        .accessibilityHint("Tap to \(showDetails ? "hide" : "show") details")
    }

    private var statusBadge: some View {
        Image(systemName: item.status.icon)
            .font(.title3)
            .foregroundColor(statusColor)
            .frame(width: 32, height: 32)
            .background(statusColor.opacity(0.15))
            .cornerRadius(CornerRadius.sm)
    }

    private var statusColor: Color {
        switch item.status.color {
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "blue": return .blue
        default: return .gray
        }
    }

    private var detailsView: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider()

            // Report type
            detailRow(label: "Report", value: item.reportType.capitalized)

            // Status with timestamp
            if let sentAt = item.sentAt {
                detailRow(label: "Sent", value: formatDateTime(sentAt))
            }

            if let deliveredAt = item.deliveredAt {
                detailRow(label: "Delivered", value: formatDateTime(deliveredAt))
            }

            if let openedAt = item.openedAt {
                detailRow(label: "Opened", value: formatDateTime(openedAt))
            }

            if let failedAt = item.failedAt {
                detailRow(label: "Failed", value: formatDateTime(failedAt))
            }

            // Error message
            if let error = item.errorMessage {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Error")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // CC recipients
            if let ccEmails = item.ccEmails, !ccEmails.isEmpty {
                detailRow(label: "CC", value: ccEmails.joined(separator: ", "))
            }

            // Message preview
            Text("Message Preview")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, Spacing.xs)

            Text(item.body)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(3)
                .padding(Spacing.xs)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(CornerRadius.xs)
        }
        .padding(.top, Spacing.xs)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)

            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }

    private var resendButton: some View {
        Button {
            onResend()
        } label: {
            HStack {
                if isResending {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "arrow.clockwise")
                }

                Text(isResending ? "Resending..." : "Resend Email")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(CornerRadius.sm)
        }
        .disabled(isResending)
        .accessibilityLabel("Resend this email")
    }

    private static let shortDateShortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private func formatDateTime(_ date: Date) -> String {
        Self.shortDateShortTimeFormatter.string(from: date)
    }
}

// MARK: - Email History Filter Sheet

struct EmailHistoryFilterSheet: View {
    @Binding var filter: EmailHistoryFilter

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Date range
                Section("Date Range") {
                    DatePicker(
                        "From",
                        selection: Binding(
                            get: { filter.startDate ?? Date().addingTimeInterval(-30 * 24 * 60 * 60) },
                            set: { filter.startDate = $0 }
                        ),
                        displayedComponents: .date
                    )

                    DatePicker(
                        "To",
                        selection: Binding(
                            get: { filter.endDate ?? Date() },
                            set: { filter.endDate = $0 }
                        ),
                        displayedComponents: .date
                    )

                    if filter.startDate != nil || filter.endDate != nil {
                        Button("Clear Date Range") {
                            filter.startDate = nil
                            filter.endDate = nil
                        }
                        .foregroundColor(.red)
                    }
                }

                // Status filter
                Section("Status") {
                    ForEach(EmailDeliveryStatus.allCases, id: \.rawValue) { status in
                        Button {
                            if filter.statusFilter == status {
                                filter.statusFilter = nil
                            } else {
                                filter.statusFilter = status
                            }
                        } label: {
                            HStack {
                                Image(systemName: status.icon)
                                    .foregroundColor(statusColor(for: status))

                                Text(status.displayName)
                                    .foregroundColor(.primary)

                                Spacer()

                                if filter.statusFilter == status {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                // Search text
                Section("Search") {
                    TextField("Search by email or subject", text: $filter.searchText)
                        .autocorrectionDisabled()
                }

                // Clear all
                if filter.hasActiveFilters {
                    Section {
                        Button("Clear All Filters", role: .destructive) {
                            filter = EmailHistoryFilter()
                        }
                    }
                }
            }
            .navigationTitle("Filter Emails")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func statusColor(for status: EmailDeliveryStatus) -> Color {
        switch status.color {
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "blue": return .blue
        default: return .gray
        }
    }
}

// MARK: - Email History Button

/// Button to open email history from patient detail view
struct EmailHistoryButton: View {
    let patient: Patient

    @State private var showHistory = false

    var body: some View {
        Button {
            showHistory = true
            HapticFeedback.light()
        } label: {
            Label("Email History", systemImage: "envelope.badge.shield.half.filled")
        }
        .sheet(isPresented: $showHistory) {
            EmailHistoryView(patient: patient)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct EmailHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        EmailHistoryView(patient: Patient.samplePatients[0])
    }
}
#endif
