import SwiftUI

/// Patient detail view for therapists
struct PatientDetailView: View {
    let patient: Patient

    @StateObject private var viewModel: PatientDetailViewModel
    @State private var showProgramViewer = false
    @State private var showAddNote = false
    @State private var showProgressReport = false
    @State private var showPrescribeWorkout = false
    @State private var showReportBuilder = false
    @State private var showIntakeAssessment = false
    @State private var showSOAPNote = false
    @State private var showAssessmentHistory = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    init(patient: Patient) {
        self.patient = patient
        _viewModel = StateObject(wrappedValue: PatientDetailViewModel())
    }

    var shouldUseSplitView: Bool {
        DeviceHelper.shouldUseSplitView(horizontalSizeClass: horizontalSizeClass)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView("Loading patient data...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        Task {
                            await viewModel.fetchData(for: patient.id.uuidString)
                        }
                    }
                } else {
                    // Patient header
                    PatientHeaderCard(patient: patient)

                    // High severity alert
                    if viewModel.hasHighSeverityFlags {
                        HighSeverityAlert()
                    }

                    // Section warning banners for partial loading failures
                    if let flagsError = viewModel.flagsError {
                        SectionErrorBanner(message: flagsError)
                    }
                    if let painTrendError = viewModel.painTrendError {
                        SectionErrorBanner(message: painTrendError)
                    }
                    if let adherenceError = viewModel.adherenceError {
                        SectionErrorBanner(message: adherenceError)
                    }
                    if let recentSessionsError = viewModel.recentSessionsError {
                        SectionErrorBanner(message: recentSessionsError)
                    }

                    // Flag summary
                    if !viewModel.topFlags.isEmpty {
                        FlagSummaryCard(flags: viewModel.topFlags)
                    }

                    // Pain trend chart
                    if !viewModel.painTrend.isEmpty {
                        VStack(spacing: 12) {
                            Text("Pain Trend")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            PainTrendChart(dataPoints: viewModel.painTrend, height: 180)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                        }
                    }

                    // RTS Protocol Card (if patient has active RTS protocol)
                    RTSProtocolSummaryCard(patientId: patient.id)

                    // Adherence
                    if let adherence = viewModel.adherence {
                        AdherenceCompactCard(adherence: adherence)
                    }

                    // Recent sessions
                    if !viewModel.recentSessions.isEmpty {
                        VStack(spacing: 12) {
                            Text("Recent Sessions")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(viewModel.recentSessions) { session in
                                SessionRow(session: session)
                            }
                        }
                    }

                    // Quick actions
                    QuickActionsCard(
                        onViewProgram: { showProgramViewer = true },
                        onAddNote: { showAddNote = true },
                        onPrescribeWorkout: { showPrescribeWorkout = true },
                        onGenerateReport: { showReportBuilder = true },
                        onNewAssessment: { showIntakeAssessment = true },
                        onNewSOAPNote: { showSOAPNote = true }
                    )
                }
            }
            .padding()
        }
        .navigationTitle(patient.fullName)
        .navigationBarTitleDisplayMode(shouldUseSplitView ? .inline : .large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showReportBuilder = true
                    } label: {
                        Label("Generate PDF Report", systemImage: "doc.text.fill")
                    }

                    Button {
                        showProgressReport = true
                    } label: {
                        Label("View Progress Summary", systemImage: "chart.line.uptrend.xyaxis")
                    }

                    Divider()

                    // Clinical Documentation
                    Button {
                        showIntakeAssessment = true
                    } label: {
                        Label("New Clinical Assessment", systemImage: "list.clipboard")
                    }

                    Button {
                        showSOAPNote = true
                    } label: {
                        Label("New SOAP Note", systemImage: "doc.text")
                    }

                    Button {
                        showAssessmentHistory = true
                    } label: {
                        Label("Assessment History", systemImage: "chart.xyaxis.line")
                    }

                    Divider()

                    // Quick report presets
                    ForEach(ReportPreset.allPresets.prefix(3)) { preset in
                        Button {
                            generateQuickReport(preset: preset)
                        } label: {
                            Label(preset.name, systemImage: preset.icon)
                        }
                    }
                } label: {
                    Image(systemName: "doc.text.magnifyingglass")
                }
                .accessibilityLabel("Reports Menu")
                .accessibilityHint("Access report generation options")
            }
        }
        .refreshable {
            await viewModel.fetchData(for: patient.id.uuidString)
        }
        .task {
            await viewModel.fetchData(for: patient.id.uuidString)
        }
        .sheet(isPresented: $showProgramViewer) {
            NavigationView {
                ProgramViewerView(patientId: patient.id.uuidString)
            }
        }
        .sheet(isPresented: $showAddNote) {
            NavigationView {
                NotesView(patientId: patient.id.uuidString)
            }
        }
        .sheet(isPresented: $showProgressReport) {
            NavigationView {
                PatientProgressReportView(patient: patient)
            }
        }
        .sheet(isPresented: $showPrescribeWorkout) {
            PrescribeWorkoutSheet(
                patient: patient,
                therapistId: PTSupabaseClient.shared.userId ?? "",
                onDismiss: {}
            )
        }
        .sheet(isPresented: $showReportBuilder) {
            ReportBuilderView(patient: patient)
        }
        .sheet(isPresented: $showIntakeAssessment) {
            NavigationView {
                IntakeAssessmentView(
                    patientId: patient.id,
                    therapistId: UUID(uuidString: PTSupabaseClient.shared.userId ?? "") ?? UUID()
                )
            }
        }
        .sheet(isPresented: $showSOAPNote) {
            NavigationView {
                SOAPNoteEditorView(patientId: patient.id.uuidString, sessionId: nil)
            }
        }
        .sheet(isPresented: $showAssessmentHistory) {
            NavigationView {
                AssessmentHistoryView(patientId: patient.id, patientName: patient.fullName)
            }
        }
    }

    // MARK: - Quick Report Generation

    private func generateQuickReport(preset: ReportPreset) {
        Task {
            do {
                let report = try await ReportGenerationService.shared.generateQuickReport(
                    preset: preset,
                    patient: patient
                )
                // Show report builder with the generated report
                showReportBuilder = true
            } catch {
                // Error is handled by the service
                #if DEBUG
                print("[PatientDetailView] Quick report generation failed: \(error.localizedDescription)")
                #endif
            }
        }
    }
}

// MARK: - Patient Header Card

struct PatientHeaderCard: View {
    let patient: Patient

    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 100, height: 100)
                .overlay(
                    Text(patient.firstName.prefix(1) + patient.lastName.prefix(1))
                        .font(.largeTitle)
                        .foregroundColor(.white)
                )

            // Name and info
            VStack(spacing: 8) {
                Text(patient.fullName)
                    .font(.title2)
                    .bold()

                if let sport = patient.sport, let position = patient.position {
                    Label("\(sport) - \(position)", systemImage: "sportscourt")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let injury = patient.injuryType {
                    Label(injury, systemImage: "cross.case")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let targetLevel = patient.targetLevel {
                    Label("Target: \(targetLevel)", systemImage: "target")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - High Severity Alert

struct HighSeverityAlert: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.red)

            VStack(alignment: .leading, spacing: 4) {
                Text("High Risk Alert")
                    .font(.headline)
                    .foregroundColor(.red)

                Text("This patient has high severity flags requiring immediate attention")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red, lineWidth: 2)
        )
    }
}

// MARK: - Flag Summary Card

struct FlagSummaryCard: View {
    let flags: [PatientFlag]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Active Flags")
                    .font(.headline)

                Spacer()

                Text("\(flags.count)")
                    .font(.headline)
                    .foregroundColor(.orange)
            }

            ForEach(flags) { flag in
                FlagRow(flag: flag)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct FlagRow: View {
    let flag: PatientFlag

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: severityIcon)
                .foregroundColor(severityColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(flag.flagType)
                    .font(.subheadline)
                    .bold()

                Text(flag.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(flag.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }

    private var severityIcon: String {
        switch flag.severity {
        case "HIGH": return "exclamationmark.triangle.fill"
        case "MEDIUM": return "exclamationmark.circle.fill"
        default: return "info.circle.fill"
        }
    }

    private var severityColor: Color {
        switch flag.severity {
        case "HIGH": return .red
        case "MEDIUM": return .orange
        default: return .yellow
        }
    }
}

// MARK: - Section Error Banner

struct SectionErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(.orange)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Quick Actions Card

struct QuickActionsCard: View {
    let onViewProgram: () -> Void
    let onAddNote: () -> Void
    let onPrescribeWorkout: () -> Void
    var onGenerateReport: (() -> Void)? = nil
    var onNewAssessment: (() -> Void)? = nil
    var onNewSOAPNote: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ActionButton(
                    title: "View Program",
                    icon: "doc.text.fill",
                    color: .blue,
                    action: onViewProgram
                )

                ActionButton(
                    title: "Add Note",
                    icon: "note.text.badge.plus",
                    color: .green,
                    action: onAddNote
                )

                ActionButton(
                    title: "Prescribe Workout",
                    icon: "dumbbell.fill",
                    color: .orange,
                    action: onPrescribeWorkout
                )

                if let onGenerateReport = onGenerateReport {
                    ActionButton(
                        title: "Generate Report",
                        icon: "doc.richtext",
                        color: .purple,
                        action: onGenerateReport
                    )
                }

                if let onNewAssessment = onNewAssessment {
                    ActionButton(
                        title: "New Assessment",
                        icon: "list.clipboard",
                        color: .teal,
                        action: onNewAssessment
                    )
                }

                if let onNewSOAPNote = onNewSOAPNote {
                    ActionButton(
                        title: "SOAP Note",
                        icon: "doc.text",
                        color: .indigo,
                        action: onNewSOAPNote
                    )
                }
            }
        }
    }
}

struct ActionButton: View {
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
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PatientDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PatientDetailView(patient: Patient(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                therapistId: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
                firstName: "John",
                lastName: "Brebbia",
                email: "john@example.com",
                sport: "Baseball",
                position: "Pitcher",
                injuryType: "Elbow UCL",
                targetLevel: "MLB",
                profileImageUrl: nil,
                createdAt: Date(),
                flagCount: 2,
                highSeverityFlagCount: 1,
                adherencePercentage: 85.5,
                lastSessionDate: Date()
            ))
        }
    }
}
#endif
