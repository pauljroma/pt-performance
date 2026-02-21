//
//  TherapistIntelligenceView.swift
//  PTPerformance
//
//  Main hub for Practice Intelligence features
//  Ties together cohort analytics, program effectiveness, and reporting
//

import SwiftUI

// MARK: - Therapist Intelligence View

struct TherapistIntelligenceView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = TherapistIntelligenceViewModel()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // Navigation state
    @State private var showCohortAnalytics = false
    @State private var showProgramEffectiveness = false
    @State private var showReportBuilder = false
    @State private var showEmailHistory = false
    @State private var showClinicalDocumentation = false
    @State private var showRTSTracking = false
    @State private var showCoachingDashboard = false
    @State private var showEngagementScores = false
    @State private var showTrainingOutcomes = false
    @State private var selectedPatient: Patient?
    @State private var showAllAtRiskPatients = false
    @State private var showAllActivity = false

    // Coaching alerts state
    @State private var activeAlertCount: Int = 0
    @State private var criticalAlertCount: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Critical Alert Banner (if any exist)
                    if criticalAlertCount > 0 {
                        CriticalAlertBanner(count: criticalAlertCount) {
                            HapticFeedback.warning()
                            showCoachingDashboard = true
                        }
                    }

                    // Practice KPIs
                    kpiSection

                    // Quick Actions
                    quickActionsSection

                    // At-Risk Patients
                    AtRiskPatientsCard(
                        atRiskPatients: viewModel.atRiskPatients,
                        onSendReminder: { patient in
                            Task {
                                await viewModel.sendReminder(to: patient)
                            }
                        },
                        onViewProfile: { patient in
                            selectedPatient = patient
                        },
                        onViewAll: {
                            showAllAtRiskPatients = true
                        }
                    )

                    // Recent Activity
                    RecentActivityFeed(
                        activities: viewModel.recentActivity,
                        onActivityTap: { activity in
                            navigateToPatient(activity.patientId)
                        },
                        onViewAll: {
                            showAllActivity = true
                        }
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Practice Intelligence")
            .navigationBarTitleDisplayMode(.large)
            .refreshableWithHaptic {
                if let therapistId = appState.userId {
                    await viewModel.refresh(therapistId: therapistId)
                }
            }
            .task {
                if let therapistId = appState.userId {
                    await viewModel.loadData(therapistId: therapistId)
                    await loadCoachingAlerts(therapistId: therapistId)
                } else {
                    viewModel.errorMessage = "Unable to identify therapist. Please sign in again."
                }
            }
            // Navigation destinations
            .navigationDestination(item: $selectedPatient) { patient in
                PatientDetailView(patient: patient)
            }
            .sheet(isPresented: $showCohortAnalytics) {
                CohortAnalyticsDashboardView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showProgramEffectiveness) {
                ProgramEffectivenessView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showReportBuilder) {
                ReportBuilderSelectionView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showEmailHistory) {
                PracticeEmailHistoryView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showClinicalDocumentation) {
                NavigationStack {
                    DocumentationDashboardView()
                }
                .environmentObject(appState)
            }
            .sheet(isPresented: $showRTSTracking) {
                NavigationStack {
                    RTSPatientListView()
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showCoachingDashboard) {
                CoachingDashboardView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showEngagementScores) {
                EngagementScoreDashboardView()
            }
            .sheet(isPresented: $showTrainingOutcomes) {
                TrainingOutcomesDashboardView()
            }
            .sheet(isPresented: $showAllAtRiskPatients) {
                AllAtRiskPatientsView(
                    atRiskPatients: viewModel.atRiskPatients,
                    onSelectPatient: { patient in
                        showAllAtRiskPatients = false
                        selectedPatient = patient
                    }
                )
            }
            .sheet(isPresented: $showAllActivity) {
                AllActivityView(
                    activities: viewModel.recentActivity,
                    onSelectActivity: { activity in
                        showAllActivity = false
                        navigateToPatient(activity.patientId)
                    }
                )
            }
            .overlay {
                if viewModel.isLoading && viewModel.patients.isEmpty {
                    LoadingOverlay()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("Retry") {
                    Task {
                        if let therapistId = appState.userId {
                            await viewModel.loadData(therapistId: therapistId)
                        }
                    }
                }
                Button("Dismiss", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }

    // MARK: - KPI Section

    private var kpiSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Overview")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            PracticeKPIGrid(kpis: viewModel.practiceKPIs) { kpi in
                handleKPITap(kpi)
            }
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Intelligence Tools")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.md),
                GridItem(.flexible(), spacing: Spacing.md)
            ], spacing: Spacing.md) {
                CoachingAlertsCard(
                    alertCount: activeAlertCount,
                    criticalCount: criticalAlertCount
                ) {
                    HapticFeedback.light()
                    showCoachingDashboard = true
                }

                QuickActionCard(
                    title: "Cohort Analytics",
                    subtitle: "Analyze patient groups",
                    icon: "person.3.fill",
                    color: .blue
                ) {
                    HapticFeedback.light()
                    showCohortAnalytics = true
                }

                QuickActionCard(
                    title: "Program Effectiveness",
                    subtitle: "Track outcomes",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                ) {
                    HapticFeedback.light()
                    showProgramEffectiveness = true
                }

                QuickActionCard(
                    title: "Generate Reports",
                    subtitle: "Create patient reports",
                    icon: "doc.text.fill",
                    color: .purple
                ) {
                    HapticFeedback.light()
                    showReportBuilder = true
                }

                QuickActionCard(
                    title: "Email History",
                    subtitle: "View sent communications",
                    icon: "envelope.fill",
                    color: .orange
                ) {
                    HapticFeedback.light()
                    showEmailHistory = true
                }

                QuickActionCard(
                    title: "Clinical Documentation",
                    subtitle: "SOAP notes & assessments",
                    icon: "list.clipboard.fill",
                    color: .teal
                ) {
                    HapticFeedback.light()
                    showClinicalDocumentation = true
                }

                QuickActionCard(
                    title: "RTS Tracking",
                    subtitle: "Return-to-sport protocols",
                    icon: "figure.run",
                    color: .indigo
                ) {
                    HapticFeedback.light()
                    showRTSTracking = true
                }

                QuickActionCard(
                    title: "Engagement Scores",
                    subtitle: "Patient risk levels",
                    icon: "gauge.with.dots.needle.33percent",
                    color: .red
                ) {
                    HapticFeedback.light()
                    showEngagementScores = true
                }

                QuickActionCard(
                    title: "Training Outcomes",
                    subtitle: "Strength & adherence",
                    icon: "chart.bar.fill",
                    color: .mint
                ) {
                    HapticFeedback.light()
                    showTrainingOutcomes = true
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func handleKPITap(_ kpi: PracticeKPI) {
        HapticFeedback.light()
        switch kpi.id {
        case "active_patients":
            // Navigate to patient list - handled by tab
            break
        case "avg_adherence":
            showCohortAnalytics = true
        case "at_risk":
            showAllAtRiskPatients = true
        case "programs":
            showProgramEffectiveness = true
        default:
            break
        }
    }

    private func navigateToPatient(_ patientId: UUID) {
        if let patient = viewModel.patients.first(where: { $0.id == patientId }) {
            selectedPatient = patient
        }
    }

    private func loadCoachingAlerts(therapistId: String) async {
        do {
            let summary = try await CoachingAlertService.shared.fetchExceptionSummary(therapistId: therapistId)
            await MainActor.run {
                activeAlertCount = summary.totalActiveAlerts
                criticalAlertCount = summary.criticalCount
                // Update badge manager with alert count
                TabBarBadgeManager.shared.setIntelligenceBadge(activeAlertCount)
            }
        } catch {
            DebugLogger.shared.log("Failed to load coaching alert summary: \(error.localizedDescription)", level: .error)
        }
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }

                Spacer()

                // Title
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Subtitle
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Arrow indicator
                HStack {
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(color.opacity(0.6))
                }
            }
            .frame(minHeight: 140)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.lg)
            .adaptiveShadow(Shadow.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title): \(subtitle)")
        .accessibilityHint("Double tap to open")
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.2)

                Text("Loading intelligence data...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(Spacing.xl)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(CornerRadius.lg)
        }
    }
}

// MARK: - Placeholder Views for Features
// Note: CohortAnalyticsDashboardView is now implemented in Views/Therapist/CohortAnalyticsDashboardView.swift

// Note: ProgramEffectivenessView is now implemented in Views/Therapist/ProgramEffectivenessView.swift

/// Placeholder for Report Builder Selection
struct ReportBuilderSelectionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPatient: Patient?

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)

                Text("Generate Reports")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Create comprehensive progress reports for your patients. Select a patient to begin.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)

                // Patient selection list would go here
                Text("Select a patient from your list to generate their report.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.md)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top, Spacing.xl)
            .navigationTitle("Generate Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// Note: EmailHistoryView (patient-specific) is in Views/Reports/EmailHistoryView.swift

/// Practice-wide email history view for therapist dashboard
struct PracticeEmailHistoryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)

                Text("Email History")
                    .font(.title)
                    .fontWeight(.bold)

                Text("View all communications sent to patients including reports, reminders, and program updates.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)

                // Sample email history placeholder
                VStack(spacing: Spacing.sm) {
                    PracticeEmailRow(
                        recipient: "John Brebbia",
                        subject: "Weekly Progress Report",
                        date: Date().addingTimeInterval(-86400)
                    )
                    PracticeEmailRow(
                        recipient: "Sarah Johnson",
                        subject: "Adherence Reminder",
                        date: Date().addingTimeInterval(-172800)
                    )
                    PracticeEmailRow(
                        recipient: "Mike Williams",
                        subject: "Program Update",
                        date: Date().addingTimeInterval(-259200)
                    )
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(CornerRadius.md)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, Spacing.xl)
            .navigationTitle("Email History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct PracticeEmailRow: View {
    let recipient: String
    let subject: String
    let date: Date

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipient)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subject)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, Spacing.xxs)
    }
}

/// View showing all at-risk patients
struct AllAtRiskPatientsView: View {
    let atRiskPatients: [AtRiskPatient]
    var onSelectPatient: ((Patient) -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(atRiskPatients) { atRiskPatient in
                    Button(action: {
                        onSelectPatient?(atRiskPatient.patient)
                    }) {
                        HStack(spacing: Spacing.md) {
                            RiskLevelIndicator(level: atRiskPatient.riskLevel)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(atRiskPatient.patient.fullName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)

                                HStack(spacing: Spacing.sm) {
                                    AdherenceBadge(percentage: atRiskPatient.adherencePercentage)

                                    Text("\(atRiskPatient.daysSinceLastActivity) days inactive")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("At-Risk Patients (\(atRiskPatients.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

/// View showing all activity
struct AllActivityView: View {
    let activities: [RecentActivityEvent]
    var onSelectActivity: ((RecentActivityEvent) -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(activities) { activity in
                    Button(action: {
                        onSelectActivity?(activity)
                    }) {
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(activity.eventType.color.opacity(0.2))
                                    .frame(width: 36, height: 36)

                                Image(systemName: activity.eventType.icon)
                                    .font(.subheadline)
                                    .foregroundColor(activity.eventType.color)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(activity.patientName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)

                                Text(activity.eventType.displayName)
                                    .font(.caption)
                                    .foregroundColor(activity.eventType.color)

                                if let details = activity.details {
                                    Text(details)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()

                            Text(activity.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("All Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Coaching Alerts Card

/// Quick action card specifically for coaching alerts with badge support
struct CoachingAlertsCard: View {
    let alertCount: Int
    let criticalCount: Int
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var badgeColor: Color {
        criticalCount > 0 ? .red : .orange
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Icon with badge
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.8), Color.orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: "bell.badge.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }

                    // Alert count badge
                    if alertCount > 0 {
                        Text("\(alertCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(badgeColor)
                            .clipShape(Capsule())
                            .offset(x: 8, y: -4)
                    }
                }

                Spacer()

                // Title
                Text("Coaching Alerts")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Subtitle
                Text(subtitleText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Arrow indicator
                HStack {
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(.orange.opacity(0.6))
                }
            }
            .frame(minHeight: 140)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.lg)
            .adaptiveShadow(Shadow.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Coaching Alerts: \(subtitleText)")
        .accessibilityHint("Double tap to view all alerts")
    }

    private var subtitleText: String {
        if alertCount == 0 {
            return "No active alerts"
        } else if criticalCount > 0 {
            return "\(criticalCount) critical"
        } else {
            return "\(alertCount) active"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct TherapistIntelligenceView_Previews: PreviewProvider {
    static var previews: some View {
        TherapistIntelligenceView()
            .environmentObject(AppState())
    }
}
#endif
