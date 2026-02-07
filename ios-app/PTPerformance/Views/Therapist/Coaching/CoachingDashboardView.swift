//
//  CoachingDashboardView.swift
//  PTPerformance
//
//  Exception-based coaching dashboard for therapists.
//  Surfaces patients who need attention based on pain, adherence, and missed sessions.
//

import SwiftUI

// MARK: - Exception Filter

enum CoachingExceptionFilter: String, CaseIterable {
    case all = "All"
    case pain = "Pain"
    case adherence = "Adherence"
    case missedSessions = "Missed Sessions"

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .pain: return "waveform.path.ecg"
        case .adherence: return "chart.line.downtrend.xyaxis"
        case .missedSessions: return "calendar.badge.exclamationmark"
        }
    }

    var color: Color {
        switch self {
        case .all: return .blue
        case .pain: return .red
        case .adherence: return .orange
        case .missedSessions: return .purple
        }
    }
}

// MARK: - Patient Exception (View-local model)

struct PatientException: Identifiable {
    let id: UUID
    let patient: Patient
    let exceptionType: ExceptionType
    let severity: Severity
    let message: String
    let daysSinceLastSession: Int
    let painTrend: TrendDirection?
    let adherenceTrend: TrendDirection?
    let currentPain: Double?
    let currentAdherence: Double?
    let createdAt: Date

    enum ExceptionType: String {
        case painSpike = "Pain Spike"
        case painElevated = "Elevated Pain"
        case lowAdherence = "Low Adherence"
        case decliningAdherence = "Declining Adherence"
        case missedSession = "Missed Session"
        case inactivity = "Inactivity"

        var icon: String {
            switch self {
            case .painSpike: return "bolt.fill"
            case .painElevated: return "waveform.path.ecg"
            case .lowAdherence: return "chart.line.downtrend.xyaxis"
            case .decliningAdherence: return "arrow.down.right"
            case .missedSession: return "calendar.badge.exclamationmark"
            case .inactivity: return "moon.zzz.fill"
            }
        }

        var color: Color {
            switch self {
            case .painSpike, .painElevated: return .red
            case .lowAdherence, .decliningAdherence: return .orange
            case .missedSession, .inactivity: return .purple
            }
        }

        var filterCategory: CoachingExceptionFilter {
            switch self {
            case .painSpike, .painElevated: return .pain
            case .lowAdherence, .decliningAdherence: return .adherence
            case .missedSession, .inactivity: return .missedSessions
            }
        }
    }

    enum Severity: Int, Comparable {
        case low = 1
        case medium = 2
        case high = 3
        case critical = 4

        static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }

        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
    }

    enum TrendDirection {
        case up
        case down
        case stable

        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .stable: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return .red
            case .down: return .green
            case .stable: return .gray
            }
        }
    }
}

// MARK: - ViewModel (View-local)

@MainActor
final class CoachingDashboardViewModel: ObservableObject {
    @Published var exceptions: [PatientException] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: CoachingExceptionFilter = .all

    private let supabase = PTSupabaseClient.shared

    // MARK: - Computed Properties

    var filteredExceptions: [PatientException] {
        guard selectedFilter != .all else {
            return exceptions.sorted { $0.severity > $1.severity }
        }

        return exceptions
            .filter { $0.exceptionType.filterCategory == selectedFilter }
            .sorted { $0.severity > $1.severity }
    }

    var criticalAlerts: [PatientException] {
        exceptions.filter { $0.severity == .critical }
    }

    var alertCounts: (pain: Int, adherence: Int, missed: Int) {
        let pain = exceptions.filter { $0.exceptionType.filterCategory == .pain }.count
        let adherence = exceptions.filter { $0.exceptionType.filterCategory == .adherence }.count
        let missed = exceptions.filter { $0.exceptionType.filterCategory == .missedSessions }.count
        return (pain, adherence, missed)
    }

    var totalExceptions: Int {
        exceptions.count
    }

    // MARK: - Data Loading

    func loadData(therapistId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Load patients
            let response = try await supabase.client
                .from("patients")
                .select()
                .eq("therapist_id", value: therapistId)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let patients = try decoder.decode([Patient].self, from: response.data)

            // Generate exceptions from patient data
            exceptions = generateExceptions(from: patients)

        } catch {
            ErrorLogger.shared.logError(error, context: "CoachingDashboardViewModel.loadData")
            errorMessage = "Failed to load coaching data. Please try again."
        }
    }

    func refresh(therapistId: String) async {
        await loadData(therapistId: therapistId)
    }

    // MARK: - Exception Generation

    private func generateExceptions(from patients: [Patient]) -> [PatientException] {
        var exceptions: [PatientException] = []

        for patient in patients {
            let adherence = patient.adherencePercentage ?? 100
            let daysSince = patient.daysSinceLastSession

            // Check for pain-related exceptions
            // In production, this would query actual pain logs
            if patient.hasHighSeverityFlags {
                exceptions.append(PatientException(
                    id: UUID(),
                    patient: patient,
                    exceptionType: .painSpike,
                    severity: .critical,
                    message: "Patient reported severe pain during last session",
                    daysSinceLastSession: daysSince,
                    painTrend: .up,
                    adherenceTrend: nil,
                    currentPain: 8.0,
                    currentAdherence: adherence,
                    createdAt: Date().addingTimeInterval(-Double.random(in: 3600...86400))
                ))
            }

            // Check for adherence exceptions
            if adherence < 30 {
                exceptions.append(PatientException(
                    id: UUID(),
                    patient: patient,
                    exceptionType: .lowAdherence,
                    severity: .critical,
                    message: "Adherence has dropped to \(Int(adherence))%",
                    daysSinceLastSession: daysSince,
                    painTrend: nil,
                    adherenceTrend: .down,
                    currentPain: nil,
                    currentAdherence: adherence,
                    createdAt: Date().addingTimeInterval(-Double.random(in: 3600...172800))
                ))
            } else if adherence < 50 {
                exceptions.append(PatientException(
                    id: UUID(),
                    patient: patient,
                    exceptionType: .decliningAdherence,
                    severity: .high,
                    message: "Adherence below 50% this week",
                    daysSinceLastSession: daysSince,
                    painTrend: nil,
                    adherenceTrend: .down,
                    currentPain: nil,
                    currentAdherence: adherence,
                    createdAt: Date().addingTimeInterval(-Double.random(in: 3600...172800))
                ))
            }

            // Check for missed session exceptions
            if daysSince > 14 {
                exceptions.append(PatientException(
                    id: UUID(),
                    patient: patient,
                    exceptionType: .inactivity,
                    severity: .critical,
                    message: "No activity for \(daysSince) days",
                    daysSinceLastSession: daysSince,
                    painTrend: nil,
                    adherenceTrend: nil,
                    currentPain: nil,
                    currentAdherence: adherence,
                    createdAt: Date().addingTimeInterval(-Double.random(in: 3600...172800))
                ))
            } else if daysSince > 7 {
                exceptions.append(PatientException(
                    id: UUID(),
                    patient: patient,
                    exceptionType: .missedSession,
                    severity: .medium,
                    message: "Missed scheduled sessions this week",
                    daysSinceLastSession: daysSince,
                    painTrend: nil,
                    adherenceTrend: nil,
                    currentPain: nil,
                    currentAdherence: adherence,
                    createdAt: Date().addingTimeInterval(-Double.random(in: 3600...172800))
                ))
            }
        }

        return exceptions.sorted { $0.severity > $1.severity }
    }

    // MARK: - Actions

    func dismissException(_ exception: PatientException) {
        exceptions.removeAll { $0.id == exception.id }
        HapticFeedback.light()
    }

    func markAsReviewed(_ exception: PatientException) {
        // In production, this would update the database
        HapticFeedback.success()
    }
}

// MARK: - CoachingDashboardView

struct CoachingDashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = CoachingDashboardViewModel()
    @State private var selectedPatient: Patient?
    @State private var selectedException: PatientException?
    @State private var showPreferences = false
    @State private var showPainAlerts = false
    @State private var showAdherenceDashboard = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.exceptions.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage, viewModel.exceptions.isEmpty {
                    errorView(message: error)
                } else if viewModel.exceptions.isEmpty {
                    emptyStateView
                } else {
                    mainContent
                }
            }
            .navigationTitle("Coaching Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticFeedback.light()
                        showPreferences = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .refreshable {
                if let therapistId = appState.userId {
                    await viewModel.refresh(therapistId: therapistId)
                }
            }
            .task {
                if let therapistId = appState.userId {
                    await viewModel.loadData(therapistId: therapistId)
                } else {
                    viewModel.errorMessage = "Unable to identify therapist. Please sign in again."
                }
            }
            .navigationDestination(item: $selectedPatient) { patient in
                PatientDetailView(patient: patient)
            }
            .sheet(item: $selectedException) { exception in
                AlertDetailSheet(exception: exception) { action in
                    handleAlertAction(action, for: exception)
                }
            }
            .sheet(isPresented: $showPreferences) {
                CoachingPreferencesView()
            }
            .sheet(isPresented: $showPainAlerts) {
                PainAlertsView(
                    exceptions: viewModel.exceptions.filter { $0.exceptionType.filterCategory == .pain },
                    onSelectPatient: { patient in
                        showPainAlerts = false
                        selectedPatient = patient
                    }
                )
            }
            .sheet(isPresented: $showAdherenceDashboard) {
                AdherenceDashboardView()
                    .environmentObject(appState)
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                // Summary Header
                summaryHeader

                // Critical Alert Banner (if any)
                if let criticalAlert = viewModel.criticalAlerts.first {
                    AlertBannerView(
                        exception: criticalAlert,
                        onTap: {
                            selectedException = criticalAlert
                        },
                        onDismiss: {
                            viewModel.dismissException(criticalAlert)
                        }
                    )
                    .padding(.horizontal)
                }

                // Filter Tabs
                filterTabs
                    .padding(.horizontal)

                // Patient Exception List
                if viewModel.filteredExceptions.isEmpty {
                    filterEmptyState
                } else {
                    ForEach(viewModel.filteredExceptions) { exception in
                        PatientExceptionCard(
                            exception: exception,
                            onTap: {
                                selectedException = exception
                            },
                            onNavigate: {
                                selectedPatient = exception.patient
                            }
                        )
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(spacing: Spacing.md) {
            // Total exceptions count
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Patients Needing Attention")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("\(viewModel.totalExceptions) exception\(viewModel.totalExceptions == 1 ? "" : "s") found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Critical count badge
                if !viewModel.criticalAlerts.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text("\(viewModel.criticalAlerts.count)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .cornerRadius(CornerRadius.sm)
                }
            }

            // Category breakdown
            HStack(spacing: Spacing.md) {
                categoryButton(
                    title: "Pain",
                    count: viewModel.alertCounts.pain,
                    color: .red,
                    icon: "waveform.path.ecg"
                ) {
                    showPainAlerts = true
                }

                categoryButton(
                    title: "Adherence",
                    count: viewModel.alertCounts.adherence,
                    color: .orange,
                    icon: "chart.line.downtrend.xyaxis"
                ) {
                    showAdherenceDashboard = true
                }

                categoryButton(
                    title: "Missed",
                    count: viewModel.alertCounts.missed,
                    color: .purple,
                    icon: "calendar.badge.exclamationmark"
                ) {
                    viewModel.selectedFilter = .missedSessions
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
        .padding(.horizontal)
    }

    private func categoryButton(title: String, count: Int, color: Color, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }

                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(CoachingExceptionFilter.allCases, id: \.self) { filter in
                    let count = filterCount(for: filter)

                    FilterChip(
                        label: "\(filter.rawValue) (\(count))",
                        icon: filter.icon,
                        color: filter.color,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        HapticFeedback.selectionChanged()
                        withAnimation(.easeInOut(duration: AnimationDuration.quick)) {
                            viewModel.selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func filterCount(for filter: CoachingExceptionFilter) -> Int {
        if filter == .all {
            return viewModel.totalExceptions
        }
        return viewModel.exceptions.filter { $0.exceptionType.filterCategory == filter }.count
    }

    // MARK: - Empty States

    private var emptyStateView: some View {
        EmptyStateView(
            title: "All Patients on Track",
            message: "Great work! No patients currently need coaching attention. Check back later for updates.",
            icon: "checkmark.shield.fill",
            iconColor: .green,
            action: nil
        )
    }

    private var filterEmptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("No \(viewModel.selectedFilter.rawValue) Exceptions")
                .font(.headline)

            Text("All patients are meeting expectations in this category.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal)
    }

    // MARK: - Loading & Error Views

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading coaching data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text("Error")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task {
                    if let therapistId = appState.userId {
                        await viewModel.loadData(therapistId: therapistId)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Actions

    private func handleAlertAction(_ action: AlertDetailSheet.AlertAction, for exception: PatientException) {
        switch action {
        case .viewPatient:
            selectedException = nil
            selectedPatient = exception.patient
        case .sendMessage:
            // In production, open messaging interface
            HapticFeedback.success()
        case .scheduleCall:
            // In production, open scheduling interface
            HapticFeedback.success()
        case .dismiss:
            viewModel.dismissException(exception)
        case .markReviewed:
            viewModel.markAsReviewed(exception)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CoachingDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        CoachingDashboardView()
            .environmentObject(AppState())
    }
}
#endif
