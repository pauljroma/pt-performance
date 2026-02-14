//
//  X2CommandCenterView.swift
//  PTPerformance
//
//  Phase 3 Integration - X2Index Command Center
//  Unified entry point for all X2Index features:
//  - PT Brief (existing)
//  - Active Escalations (new)
//  - Pending Conflicts (new)
//  - Recent Reports (new)
//  - Quick Actions grid
//

import SwiftUI

// MARK: - X2 Command Center View

/// Unified command center for therapists with all X2Index features
struct X2CommandCenterView: View {

    // MARK: - Environment & State

    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = X2CommandCenterViewModel()
    @State private var selectedSection: CommandCenterSection = .overview
    @State private var showPTBrief = false
    @State private var showEscalationDetail = false
    @State private var showConflictResolution = false
    @State private var showReportGenerator = false
    @State private var showPatientPicker = false
    @State private var showTrendAnalysis = false
    @State private var selectedEscalation: SafetyIncident?
    @State private var selectedConflict: ConflictGroup?
    @State private var selectedPatient: Patient?

    // MARK: - Section Enum

    enum CommandCenterSection: String, CaseIterable {
        case overview = "Overview"
        case escalations = "Escalations"
        case conflicts = "Conflicts"
        case reports = "Reports"

        var icon: String {
            switch self {
            case .overview: return "square.grid.2x2"
            case .escalations: return "exclamationmark.shield"
            case .conflicts: return "arrow.triangle.2.circlepath"
            case .reports: return "doc.text.fill"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section picker
                sectionPicker
                    .padding(.horizontal)
                    .padding(.top, Spacing.xs)

                // Content
                ZStack {
                    if viewModel.isLoading && !viewModel.hasLoaded {
                        loadingView
                    } else {
                        sectionContent
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("X2 Command Center")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarMenu
                }
            }
            .refreshable {
                HapticService.light()
                await viewModel.refresh()
            }
            .task {
                if let therapistId = appState.userId {
                    await viewModel.load(therapistId: therapistId)
                }
            }
            .sheet(isPresented: $showPTBrief) {
                if let patient = selectedPatient {
                    PTBriefView(athleteId: patient.id)
                }
            }
            .sheet(item: $selectedEscalation) { incident in
                SafetyIncidentDetailSheet(incident: incident, onDismiss: {
                    selectedEscalation = nil
                    Task { await viewModel.refresh() }
                })
            }
            .sheet(item: $selectedConflict) { conflict in
                ConflictGroupResolutionSheet(conflict: conflict, onDismiss: {
                    selectedConflict = nil
                    Task { await viewModel.refresh() }
                })
            }
            .sheet(isPresented: $showReportGenerator) {
                WeeklyReportGeneratorSheet()
            }
            .sheet(isPresented: $showPatientPicker) {
                PatientPickerSheet(onSelect: { patient in
                    selectedPatient = patient
                    showPatientPicker = false
                    showPTBrief = true
                })
            }
            .sheet(isPresented: $showTrendAnalysis) {
                NavigationStack {
                    if let patient = selectedPatient {
                        HistoricalTrendsView(patientId: patient.id)
                    } else if let userIdString = appState.userId,
                              let userId = UUID(uuidString: userIdString) {
                        HistoricalTrendsView(patientId: userId)
                    } else {
                        PatientPickerSheet(onSelect: { patient in
                            selectedPatient = patient
                            showTrendAnalysis = false
                            // Re-open with selected patient
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showTrendAnalysis = true
                            }
                        })
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unexpected error occurred")
            }
        }
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(CommandCenterSection.allCases, id: \.self) { section in
                    sectionButton(section)
                }
            }
            .padding(.vertical, Spacing.xs)
        }
    }

    private func sectionButton(_ section: CommandCenterSection) -> some View {
        let isSelected = selectedSection == section
        let badgeCount = viewModel.badgeCount(for: section)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                HapticService.selection()
                selectedSection = section
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: section.icon)
                    .font(.system(size: 14, weight: .medium))

                Text(section.rawValue)
                    .font(.subheadline.weight(.medium))

                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.red)
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.modusCyan : Color(.tertiarySystemFill))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(section.rawValue), \(badgeCount) items")
        .accessibilityHint("Double tap to view \(section.rawValue.lowercased())")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Section Content

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .overview:
            overviewContent
        case .escalations:
            escalationsContent
        case .conflicts:
            conflictsContent
        case .reports:
            reportsContent
        }
    }

    // MARK: - Overview Content

    private var overviewContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Active Escalations Summary
                if !viewModel.activeEscalations.isEmpty {
                    activeEscalationsCard
                }

                // Pending Conflicts Summary
                if !viewModel.pendingConflicts.isEmpty {
                    pendingConflictsCard
                }

                // Recent Reports Summary
                if !viewModel.recentReports.isEmpty {
                    recentReportsCard
                }

                // Quick Actions Grid
                quickActionsGrid

                // Empty state if nothing active
                if viewModel.activeEscalations.isEmpty &&
                   viewModel.pendingConflicts.isEmpty &&
                   viewModel.recentReports.isEmpty {
                    CommandCenterEmptyState(
                        icon: "checkmark.seal.fill",
                        title: "All Clear",
                        message: "No active escalations, conflicts, or pending items. Your caseload is healthy."
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Active Escalations Card

    private var activeEscalationsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Label("Active Escalations", systemImage: "exclamationmark.shield.fill")
                    .font(.headline)
                    .foregroundColor(.red)

                Spacer()

                Text("\(viewModel.activeEscalations.count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .clipShape(Capsule())
            }

            ForEach(viewModel.activeEscalations.prefix(3)) { escalation in
                EscalationMiniCard(escalation: escalation) {
                    HapticService.medium()
                    selectedEscalation = escalation
                }
            }

            if viewModel.activeEscalations.count > 3 {
                Button {
                    withAnimation {
                        selectedSection = .escalations
                    }
                } label: {
                    Text("View all \(viewModel.activeEscalations.count) escalations")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.modusCyan)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Pending Conflicts Card

    private var pendingConflictsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Label("Data Conflicts", systemImage: "arrow.triangle.2.circlepath")
                    .font(.headline)
                    .foregroundColor(.orange)

                Spacer()

                Text("\(viewModel.pendingConflicts.count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }

            ForEach(viewModel.pendingConflicts.prefix(3)) { conflict in
                ConflictMiniCard(conflict: conflict) {
                    HapticService.medium()
                    selectedConflict = conflict
                }
            }

            if viewModel.pendingConflicts.count > 3 {
                Button {
                    withAnimation {
                        selectedSection = .conflicts
                    }
                } label: {
                    Text("View all \(viewModel.pendingConflicts.count) conflicts")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.modusCyan)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Recent Reports Card

    private var recentReportsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Label("Recent Reports", systemImage: "doc.text.fill")
                    .font(.headline)
                    .foregroundColor(.blue)

                Spacer()

                Button {
                    showReportGenerator = true
                } label: {
                    Label("New", systemImage: "plus")
                        .font(.subheadline.weight(.medium))
                }
            }

            ForEach(viewModel.recentReports.prefix(3)) { report in
                ReportMiniCard(report: report)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Quick Actions Grid

    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm)
            ], spacing: Spacing.sm) {
                CommandCenterQuickAction(
                    icon: "clock.badge.fill",
                    title: "60s Brief",
                    subtitle: "Quick patient scan",
                    color: .modusCyan
                ) {
                    HapticService.light()
                    showPatientPicker = true
                }

                CommandCenterQuickAction(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Trend Analysis",
                    subtitle: "Historical data",
                    color: .purple
                ) {
                    HapticService.light()
                    showTrendAnalysis = true
                }

                CommandCenterQuickAction(
                    icon: "doc.badge.plus",
                    title: "Weekly Report",
                    subtitle: "Generate summary",
                    color: .blue
                ) {
                    HapticService.light()
                    showReportGenerator = true
                }

                CommandCenterQuickAction(
                    icon: "shield.checkered",
                    title: "Safety Review",
                    subtitle: "Check all alerts",
                    color: .red
                ) {
                    HapticService.light()
                    selectedSection = .escalations
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Escalations Content

    private var escalationsContent: some View {
        Group {
            if viewModel.activeEscalations.isEmpty {
                CommandCenterEmptyState(
                    icon: "checkmark.shield.fill",
                    title: "No Active Escalations",
                    message: "All safety incidents have been resolved. Great work keeping your patients safe!"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.activeEscalations) { escalation in
                            EscalationCard(escalation: escalation) {
                                HapticService.medium()
                                selectedEscalation = escalation
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .scale(scale: 0.9))
                            ))
                        }
                    }
                    .padding()
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.activeEscalations.count)
                }
            }
        }
    }

    // MARK: - Conflicts Content

    private var conflictsContent: some View {
        Group {
            if viewModel.pendingConflicts.isEmpty {
                CommandCenterEmptyState(
                    icon: "checkmark.circle.fill",
                    title: "No Data Conflicts",
                    message: "All data sources are in agreement. Timeline data is consistent."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.pendingConflicts) { conflict in
                            ConflictGroupCard(conflict: conflict) {
                                HapticService.medium()
                                selectedConflict = conflict
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .scale(scale: 0.9))
                            ))
                        }
                    }
                    .padding()
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.pendingConflicts.count)
                }
            }
        }
    }

    // MARK: - Reports Content

    private var reportsContent: some View {
        Group {
            if viewModel.recentReports.isEmpty {
                CommandCenterEmptyState(
                    icon: "doc.text",
                    title: "No Recent Reports",
                    message: "Generate your first weekly report to track patient progress over time.",
                    actionTitle: "Generate Report",
                    action: {
                        showReportGenerator = true
                    }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Report generation button
                        Button {
                            HapticService.light()
                            showReportGenerator = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                    .font(.title3)
                                Text("Generate New Report")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundColor(.modusCyan)
                            .padding()
                            .background(Color.modusCyan.opacity(0.1))
                            .cornerRadius(CornerRadius.md)
                        }

                        ForEach(viewModel.recentReports) { report in
                            ReportCard(report: report)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading Command Center...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar Menu

    private var toolbarMenu: some View {
        Menu {
            Button {
                Task { await viewModel.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }

            Divider()

            Button {
                showReportGenerator = true
            } label: {
                Label("Generate Report", systemImage: "doc.badge.plus")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

// MARK: - Supporting Views

/// Empty state for command center sections
struct CommandCenterEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text(title)
                .font(.title2.weight(.bold))

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.modusCyan)
                        .cornerRadius(CornerRadius.md)
                }
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Quick action button for command center
struct CommandCenterQuickAction: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Escalation Cards

struct EscalationMiniCard: View {
    let escalation: SafetyIncident
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: escalation.severity.icon)
                    .foregroundColor(Color(escalation.severity.colorName))
                    .font(.body)

                VStack(alignment: .leading, spacing: 2) {
                    Text(escalation.incidentType.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)

                    Text(escalation.ageString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(.plain)
    }
}

struct EscalationCard: View {
    let escalation: SafetyIncident
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: escalation.severity.icon)
                        .foregroundColor(Color(escalation.severity.colorName))
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(escalation.incidentType.displayName)
                            .font(.headline)

                        Text(escalation.severity.displayName)
                            .font(.caption)
                            .foregroundColor(Color(escalation.severity.colorName))
                    }

                    Spacer()

                    Text(escalation.ageString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(escalation.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    if escalation.isEscalated {
                        Label("Escalated", systemImage: "arrow.up.circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    Text("Tap to review")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color(escalation.severity.colorName).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Conflict Cards

struct ConflictMiniCard: View {
    let conflict: ConflictGroup
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: conflict.conflictType.iconName)
                    .foregroundColor(conflict.conflictType.color)
                    .font(.body)

                VStack(alignment: .leading, spacing: 2) {
                    Text(conflict.conflictType.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)

                    Text("\(conflict.eventIds.count) events involved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(.plain)
    }
}

struct ConflictGroupCard: View {
    let conflict: ConflictGroup
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: conflict.conflictType.iconName)
                        .foregroundColor(conflict.conflictType.color)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(conflict.conflictType.displayName)
                            .font(.headline)

                        Text("\(conflict.eventIds.count) events involved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(conflict.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(conflict.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    Spacer()

                    Text("Tap to resolve")
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(conflict.conflictType.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Report Cards

struct ReportMiniCard: View {
    let report: WeeklyReportSummary

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "doc.text.fill")
                .foregroundColor(.blue)
                .font(.body)

            VStack(alignment: .leading, spacing: 2) {
                Text(report.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Text(report.dateRange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if report.isReady {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

struct ReportCard: View {
    let report: WeeklyReportSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(report.title)
                        .font(.headline)

                    Text(report.dateRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if report.isReady {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    ProgressView()
                }
            }

            if let highlights = report.highlights {
                Text(highlights)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Text("\(report.patientCount) patients")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    // Share action
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Preview

#if DEBUG
struct X2CommandCenterView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default preview with demo data
            X2CommandCenterView()
                .environmentObject(AppState.preview)
                .environment(\.useDemoData, true)
                .previewDisplayName("Demo Data")

            // Empty state preview
            X2CommandCenterView()
                .environmentObject(AppState.preview)
                .previewDisplayName("Default")
        }
    }
}

#Preview("X2 Command Center - Demo Data") {
    X2CommandCenterView()
        .environmentObject(AppState.preview)
        .demoMode()
}

#Preview("X2 Command Center - Patient Role") {
    X2CommandCenterView()
        .environmentObject(AppState.patientPreview)
        .demoMode()
}
#endif
