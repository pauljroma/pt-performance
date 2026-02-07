//
//  DocumentationDashboardView.swift
//  PTPerformance
//
//  Documentation dashboard providing overview of all clinical documentation
//

import SwiftUI

/// Main documentation dashboard showing pending drafts, recent notes, and quick actions
struct DocumentationDashboardView: View {
    @StateObject private var viewModel = DocumentationDashboardViewModel()
    @State private var showNewNoteSheet = false
    @State private var showPatientFilter = false
    @State private var selectedPatientId: String?
    @State private var selectedDraft: DraftNote?
    @State private var selectedNote: RecentNote?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.pendingDrafts.isEmpty {
                ProgressView("Loading documentation...")
            } else {
                dashboardContent
            }
        }
        .navigationTitle("Documentation")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showPatientFilter = true
                    } label: {
                        Label(
                            selectedPatientId == nil ? "Filter by Patient" : "Change Filter",
                            systemImage: "line.3.horizontal.decrease.circle"
                        )
                    }

                    if selectedPatientId != nil {
                        Button(role: .destructive) {
                            selectedPatientId = nil
                            Task {
                                await viewModel.loadDashboard(patientId: nil)
                            }
                        } label: {
                            Label("Clear Filter", systemImage: "xmark.circle")
                        }
                    }
                } label: {
                    Image(systemName: selectedPatientId == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewNoteSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewNoteSheet) {
            NewDocumentationSheet { noteType, patientId in
                navigateToNote(type: noteType, patientId: patientId)
            }
        }
        .sheet(isPresented: $showPatientFilter) {
            PatientFilterSheet(selectedPatientId: $selectedPatientId) {
                Task {
                    await viewModel.loadDashboard(patientId: selectedPatientId)
                }
            }
        }
        .sheet(item: $selectedDraft) { draft in
            NavigationView {
                SOAPNoteEditorView(patientId: draft.patientId, sessionId: draft.sessionId)
            }
        }
        .sheet(item: $selectedNote) { note in
            NavigationView {
                if note.type == "soap" {
                    SOAPNoteEditorView(patientId: note.patientId, sessionId: note.sessionId)
                } else {
                    VisitSummaryView(sessionId: note.sessionId ?? UUID(), patientId: note.patientId)
                }
            }
        }
        .refreshable {
            await viewModel.loadDashboard(patientId: selectedPatientId)
        }
        .task {
            await viewModel.loadDashboard(patientId: selectedPatientId)
        }
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Filter indicator
                if selectedPatientId != nil, let patient = viewModel.selectedPatient {
                    filterIndicator(patient: patient)
                }

                // Quick Actions
                quickActionsSection

                // Pending Drafts Widget
                pendingDraftsWidget

                // Recent Notes Widget
                recentNotesWidget

                // Statistics
                statisticsSection
            }
            .padding()
        }
    }

    // MARK: - Filter Indicator

    private func filterIndicator(patient: PatientInfo) -> some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(.blue)

            Text("Showing: \(patient.fullName)")
                .font(.subheadline)

            Spacer()

            Button {
                selectedPatientId = nil
                Task {
                    await viewModel.loadDashboard(patientId: nil)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    DocQuickActionButton(
                        title: "New SOAP Note",
                        icon: "doc.text.fill",
                        color: .blue
                    ) {
                        showNewNoteSheet = true
                    }

                    DocQuickActionButton(
                        title: "Visit Summary",
                        icon: "list.clipboard.fill",
                        color: .green
                    ) {
                        showNewNoteSheet = true
                    }

                    DocQuickActionButton(
                        title: "Progress Note",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .orange
                    ) {
                        showNewNoteSheet = true
                    }

                    DocQuickActionButton(
                        title: "Templates",
                        icon: "doc.on.doc.fill",
                        color: .purple
                    ) {
                        // Navigate to templates
                    }
                }
            }
        }
    }

    // MARK: - Pending Drafts Widget

    private var pendingDraftsWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Pending Drafts", systemImage: "doc.badge.ellipsis")
                    .font(.headline)

                Spacer()

                if viewModel.pendingDrafts.count > 0 {
                    Text("\(viewModel.pendingDrafts.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }

            if viewModel.pendingDrafts.isEmpty {
                EmptyWidgetView(
                    icon: "checkmark.circle",
                    message: "No pending drafts",
                    color: .green
                )
            } else {
                ForEach(viewModel.pendingDrafts) { draft in
                    DraftNoteRow(draft: draft) {
                        selectedDraft = draft
                    }
                }

                if viewModel.pendingDrafts.count > 3 {
                    Button {
                        // Navigate to all drafts
                    } label: {
                        HStack {
                            Text("View All Drafts")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Recent Notes Widget

    private var recentNotesWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent Notes", systemImage: "clock.arrow.circlepath")
                    .font(.headline)

                Spacer()

                Button("See All") {
                    // Navigate to all notes
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            if viewModel.recentNotes.isEmpty {
                EmptyWidgetView(
                    icon: "doc.text",
                    message: "No recent documentation",
                    color: .secondary
                )
            } else {
                ForEach(viewModel.recentNotes) { note in
                    RecentNoteRow(note: note) {
                        selectedNote = note
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("This Week", systemImage: "chart.bar.fill")
                .font(.headline)

            HStack(spacing: 0) {
                StatWidget(
                    value: "\(viewModel.notesThisWeek)",
                    label: "Notes",
                    icon: "doc.text.fill",
                    color: .blue
                )

                Divider()

                StatWidget(
                    value: "\(viewModel.sessionsDocumented)",
                    label: "Sessions",
                    icon: "calendar.badge.checkmark",
                    color: .green
                )

                Divider()

                StatWidget(
                    value: "\(viewModel.patientsDocumented)",
                    label: "Patients",
                    icon: "person.2.fill",
                    color: .purple
                )

                Divider()

                StatWidget(
                    value: "\(viewModel.pendingSignatures)",
                    label: "Pending Sign",
                    icon: "signature",
                    color: .orange
                )
            }
            .frame(height: 80)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Navigation

    private func navigateToNote(type: DocumentationType, patientId: String) {
        // Handle navigation based on note type
    }
}

// MARK: - Doc Quick Action Button

private struct DocQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 90, height: 80)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty Widget View

struct EmptyWidgetView: View {
    let icon: String
    let message: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(8)
    }
}

// MARK: - Draft Note Row

struct DraftNoteRow: View {
    let draft: DraftNote
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(draft.patientName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text(draft.noteType.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(draft.lastModified, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Completion indicator
                CircularProgressView(progress: draft.completionPercent)
                    .frame(width: 36, height: 36)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.semibold)
        }
    }

    private var progressColor: Color {
        if progress < 0.5 {
            return .orange
        } else if progress < 1.0 {
            return .blue
        } else {
            return .green
        }
    }
}

// MARK: - Recent Note Row

struct RecentNoteRow: View {
    let note: RecentNote
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                // Type icon
                Image(systemName: note.typeIcon)
                    .foregroundColor(note.typeColor)
                    .frame(width: 32, height: 32)
                    .background(note.typeColor.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(note.patientName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(note.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status
                if note.isSigned {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                } else {
                    Text("Draft")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(4)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Widget

struct StatWidget: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - New Documentation Sheet

struct NewDocumentationSheet: View {
    let onSelect: (DocumentationType, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: DocumentationType = .soapNote
    @State private var patients: [PatientInfo] = []
    @State private var selectedPatient: PatientInfo?
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            Form {
                Section("Documentation Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(DocumentationType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Patient") {
                    if isLoading {
                        ProgressView("Loading patients...")
                    } else {
                        Picker("Select Patient", selection: $selectedPatient) {
                            Text("Choose a patient").tag(nil as PatientInfo?)
                            ForEach(patients) { patient in
                                Text(patient.fullName).tag(patient as PatientInfo?)
                            }
                        }
                    }
                }

                Section {
                    Button("Create Documentation") {
                        if let patient = selectedPatient {
                            onSelect(selectedType, patient.id)
                            dismiss()
                        }
                    }
                    .disabled(selectedPatient == nil)
                }
            }
            .navigationTitle("New Documentation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadPatients()
            }
        }
    }

    private func loadPatients() async {
        isLoading = true
        do {
            let response: [PatientInfo] = try await PTSupabaseClient.shared.client
                .from("patients")
                .select("id, first_name, last_name")
                .order("last_name", ascending: true)
                .execute()
                .value
            patients = response
        } catch {
            // Handle error
        }
        isLoading = false
    }
}

// MARK: - Patient Filter Sheet

struct PatientFilterSheet: View {
    @Binding var selectedPatientId: String?
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var patients: [PatientInfo] = []
    @State private var searchQuery = ""
    @State private var isLoading = true

    var filteredPatients: [PatientInfo] {
        if searchQuery.isEmpty {
            return patients
        }
        return patients.filter { $0.fullName.localizedCaseInsensitiveContains(searchQuery) }
    }

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading patients...")
                } else {
                    List(filteredPatients) { patient in
                        Button {
                            selectedPatientId = patient.id
                            onApply()
                            dismiss()
                        } label: {
                            HStack {
                                Text(patient.fullName)
                                    .foregroundColor(.primary)

                                Spacer()

                                if selectedPatientId == patient.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter by Patient")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchQuery, prompt: "Search patients")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadPatients()
            }
        }
    }

    private func loadPatients() async {
        isLoading = true
        do {
            let response: [PatientInfo] = try await PTSupabaseClient.shared.client
                .from("patients")
                .select("id, first_name, last_name")
                .order("last_name", ascending: true)
                .execute()
                .value
            patients = response
        } catch {
            // Handle error
        }
        isLoading = false
    }
}

// MARK: - Documentation Dashboard ViewModel

@MainActor
class DocumentationDashboardViewModel: ObservableObject {
    @Published var pendingDrafts: [DraftNote] = []
    @Published var recentNotes: [RecentNote] = []
    @Published var selectedPatient: PatientInfo?
    @Published var notesThisWeek: Int = 0
    @Published var sessionsDocumented: Int = 0
    @Published var patientsDocumented: Int = 0
    @Published var pendingSignatures: Int = 0

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func loadDashboard(patientId: String?) async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch pending drafts
            var draftsQuery = PTSupabaseClient.shared.client
                .from("soap_notes")
                .select("*, patients(first_name, last_name)")
                .eq("status", value: "draft")

            if let patientId = patientId {
                draftsQuery = draftsQuery.eq("patient_id", value: patientId)
            }

            let draftsResponse: [DraftNoteResponse] = try await draftsQuery
                .order("updated_at", ascending: false)
                .limit(5)
                .execute()
                .value

            pendingDrafts = draftsResponse.map { resp in
                DraftNote(
                    id: resp.id,
                    patientId: resp.patientId,
                    patientName: resp.patient?.fullName ?? "Unknown",
                    noteType: "SOAP Note",
                    lastModified: resp.updatedAt ?? resp.createdAt,
                    completionPercent: calculateCompletion(resp),
                    sessionId: resp.sessionId != nil ? UUID(uuidString: resp.sessionId!) : nil
                )
            }

            // Fetch recent notes
            var recentQuery = PTSupabaseClient.shared.client
                .from("soap_notes")
                .select("*, patients(first_name, last_name)")

            if let patientId = patientId {
                recentQuery = recentQuery.eq("patient_id", value: patientId)
            }

            let recentResponse: [RecentNoteResponse] = try await recentQuery
                .order("created_at", ascending: false)
                .limit(10)
                .execute()
                .value

            recentNotes = recentResponse.map { resp in
                RecentNote(
                    id: resp.id,
                    patientId: resp.patientId,
                    patientName: resp.patient?.fullName ?? "Unknown",
                    type: "soap",
                    createdAt: resp.createdAt,
                    isSigned: resp.status == "signed",
                    sessionId: resp.sessionId != nil ? UUID(uuidString: resp.sessionId!) : nil
                )
            }

            // Fetch selected patient info if filtered
            if let patientId = patientId {
                let patient: PatientInfo = try await PTSupabaseClient.shared.client
                    .from("patients")
                    .select("id, first_name, last_name")
                    .eq("id", value: patientId)
                    .single()
                    .execute()
                    .value
                selectedPatient = patient
            } else {
                selectedPatient = nil
            }

            // Calculate statistics
            await calculateStatistics(patientId: patientId)

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func calculateCompletion(_ note: DraftNoteResponse) -> Double {
        var sections = 0.0
        var completed = 0.0

        if note.subjective != nil && !note.subjective!.isEmpty { completed += 1 }
        sections += 1

        if note.objective != nil && !note.objective!.isEmpty { completed += 1 }
        sections += 1

        if note.assessment != nil && !note.assessment!.isEmpty { completed += 1 }
        sections += 1

        if note.plan != nil && !note.plan!.isEmpty { completed += 1 }
        sections += 1

        return completed / sections
    }

    private func calculateStatistics(patientId: String?) async {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        do {
            // Notes this week
            var notesQuery = PTSupabaseClient.shared.client
                .from("soap_notes")
                .select("id", head: false)
                .gte("created_at", value: ISO8601DateFormatter().string(from: weekAgo))

            if let patientId = patientId {
                notesQuery = notesQuery.eq("patient_id", value: patientId)
            }

            let notesCount: [IdOnly] = try await notesQuery.execute().value
            notesThisWeek = notesCount.count

            // Pending signatures
            var pendingQuery = PTSupabaseClient.shared.client
                .from("soap_notes")
                .select("id", head: false)
                .eq("status", value: "draft")

            if let patientId = patientId {
                pendingQuery = pendingQuery.eq("patient_id", value: patientId)
            }

            let pendingCount: [IdOnly] = try await pendingQuery.execute().value
            pendingSignatures = pendingCount.count

            // Unique patients documented
            var patientsQuery = PTSupabaseClient.shared.client
                .from("soap_notes")
                .select("patient_id")
                .gte("created_at", value: ISO8601DateFormatter().string(from: weekAgo))

            if let patientId = patientId {
                patientsQuery = patientsQuery.eq("patient_id", value: patientId)
            }

            let patientsResult: [PatientIdOnly] = try await patientsQuery.execute().value
            patientsDocumented = Set(patientsResult.map { $0.patientId }).count

            sessionsDocumented = notesThisWeek

        } catch {
            // Use default values on error
        }
    }
}

// MARK: - Supporting Models

struct DraftNote: Identifiable {
    let id: UUID
    let patientId: String
    let patientName: String
    let noteType: String
    let lastModified: Date
    let completionPercent: Double
    let sessionId: UUID?
}

struct RecentNote: Identifiable {
    let id: UUID
    let patientId: String
    let patientName: String
    let type: String
    let createdAt: Date
    let isSigned: Bool
    let sessionId: UUID?

    var typeIcon: String {
        switch type {
        case "soap": return "doc.text.fill"
        case "progress": return "chart.line.uptrend.xyaxis"
        case "evaluation": return "clipboard.fill"
        default: return "note.text"
        }
    }

    var typeColor: Color {
        switch type {
        case "soap": return .blue
        case "progress": return .green
        case "evaluation": return .purple
        default: return .gray
        }
    }
}

struct PatientInfo: Codable, Identifiable, Hashable {
    let id: String
    let firstName: String
    let lastName: String

    var fullName: String { "\(firstName) \(lastName)" }

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

enum DocumentationType: String, CaseIterable {
    case soapNote = "soap_note"
    case progressNote = "progress_note"
    case evaluationNote = "evaluation_note"
    case visitSummary = "visit_summary"

    var displayName: String {
        switch self {
        case .soapNote: return "SOAP Note"
        case .progressNote: return "Progress Note"
        case .evaluationNote: return "Evaluation Note"
        case .visitSummary: return "Visit Summary"
        }
    }

    var icon: String {
        switch self {
        case .soapNote: return "doc.text.fill"
        case .progressNote: return "chart.line.uptrend.xyaxis"
        case .evaluationNote: return "clipboard.fill"
        case .visitSummary: return "list.clipboard.fill"
        }
    }
}

// Response models for API
struct DraftNoteResponse: Codable {
    let id: UUID
    let patientId: String
    let sessionId: String?
    let subjective: String?
    let objective: String?
    let assessment: String?
    let plan: String?
    let status: String
    let createdAt: Date
    let updatedAt: Date?
    let patient: PatientNameResponse?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case sessionId = "session_id"
        case subjective, objective, assessment, plan, status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case patient = "patients"
    }
}

struct RecentNoteResponse: Codable {
    let id: UUID
    let patientId: String
    let sessionId: String?
    let status: String
    let createdAt: Date
    let patient: PatientNameResponse?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case sessionId = "session_id"
        case status
        case createdAt = "created_at"
        case patient = "patients"
    }
}

struct PatientNameResponse: Codable {
    let firstName: String
    let lastName: String

    var fullName: String { "\(firstName) \(lastName)" }

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct IdOnly: Codable {
    let id: UUID
}

struct PatientIdOnly: Codable {
    let patientId: String

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
    }
}

// MARK: - Preview

#if DEBUG
struct DocumentationDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DocumentationDashboardView()
        }
        .preferredColorScheme(.light)

        NavigationView {
            DocumentationDashboardView()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
