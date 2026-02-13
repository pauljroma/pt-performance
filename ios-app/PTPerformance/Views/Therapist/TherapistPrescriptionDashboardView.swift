// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  TherapistPrescriptionDashboardView.swift
//  PTPerformance
//
//  Dashboard for therapists to track patient prescription compliance
//  Shows active prescriptions, compliance rates, and quick actions
//

import SwiftUI

// MARK: - Therapist Prescription Dashboard View

struct TherapistPrescriptionDashboardView: View {
    @StateObject private var viewModel = TherapistPrescriptionDashboardViewModel()
    @EnvironmentObject var appState: AppState

    @State private var showFilters = false
    @State private var selectedPrescription: PrescriptionWithPatient?
    @State private var showExtendSheet = false
    @State private var prescriptionToExtend: WorkoutPrescription?
    @State private var showCancelConfirmation = false
    @State private var prescriptionToCancel: UUID?
    @State private var selectedTab: DashboardTab = .active

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    enum DashboardTab: String, CaseIterable, Identifiable {
        case active = "Active"
        case overdue = "Overdue"
        case completed = "Completed"
        case all = "All"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .active: return "doc.badge.clock"
            case .overdue: return "exclamationmark.triangle"
            case .completed: return "checkmark.circle"
            case .all: return "list.bullet"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.prescriptions.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage, viewModel.prescriptions.isEmpty {
                    errorView(error)
                } else {
                    mainContent
                }
            }
            .navigationTitle("Prescriptions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterButton
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search patients or prescriptions")
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showFilters) {
                filterSheet
            }
            .sheet(isPresented: $showExtendSheet) {
                if let prescription = prescriptionToExtend {
                    ExtendDueDateSheet(
                        prescription: prescription,
                        onExtend: { newDate in
                            Task {
                                _ = await viewModel.extendDueDate(for: prescription.id, newDueDate: newDate)
                                showExtendSheet = false
                                prescriptionToExtend = nil
                            }
                        },
                        onCancel: {
                            showExtendSheet = false
                            prescriptionToExtend = nil
                        }
                    )
                }
            }
            .alert("Cancel Prescription", isPresented: $showCancelConfirmation) {
                Button("Keep", role: .cancel) {
                    prescriptionToCancel = nil
                }
                Button("Cancel Prescription", role: .destructive) {
                    if let id = prescriptionToCancel {
                        Task {
                            _ = await viewModel.cancelPrescription(id)
                            prescriptionToCancel = nil
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to cancel this prescription? The patient will no longer see it in their assigned workouts.")
            }
            .task {
                await loadData()
            }
            .onAppear {
                if let therapistId = appState.userId {
                    viewModel.startAutoRefresh(therapistId: therapistId)
                }
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stats overview
                statsSection

                // Tab selector
                tabSelector

                // Content based on selected tab
                tabContent
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Compliance rate header
            complianceRateCard

            // Quick stats
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    PrescriptionStatsCard(
                        title: "Active",
                        count: viewModel.activePrescriptions.count,
                        icon: "doc.badge.clock",
                        color: .blue,
                        subtitle: "in progress"
                    )

                    PrescriptionStatsCard(
                        title: "Overdue",
                        count: viewModel.overduePrescriptions.count,
                        icon: "exclamationmark.triangle.fill",
                        color: .red,
                        subtitle: "need attention"
                    )

                    PrescriptionStatsCard(
                        title: "Due Today",
                        count: viewModel.prescriptionsDueToday.count,
                        icon: "calendar",
                        color: .orange,
                        subtitle: "upcoming"
                    )

                    PrescriptionStatsCard(
                        title: "Completed",
                        count: viewModel.recentlyCompletedPrescriptions.count,
                        icon: "checkmark.circle.fill",
                        color: .green,
                        subtitle: "this week"
                    )
                }
                .padding(.horizontal)
            }
        }
    }

    private var complianceRateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Compliance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(viewModel.overallComplianceRate))")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(complianceColor)

                        Text("%")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(complianceColor)
                    }
                }

                Spacer()

                // Compliance gauge
                complianceGauge
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(complianceColor)
                        .frame(width: geometry.size.width * min(viewModel.overallComplianceRate / 100, 1.0), height: 8)
                }
            }
            .frame(height: 8)

            // Last updated
            if let lastRefresh = viewModel.lastRefreshDate {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                    Text("Updated \(lastRefresh, style: .relative) ago")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
        .padding(.horizontal)
    }

    private var complianceGauge: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 8)
                .frame(width: 70, height: 70)

            Circle()
                .trim(from: 0, to: min(viewModel.overallComplianceRate / 100, 1.0))
                .stroke(complianceColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 70, height: 70)
                .rotationEffect(.degrees(-90))

            Image(systemName: complianceIcon)
                .font(.title2)
                .foregroundColor(complianceColor)
        }
    }

    private var complianceColor: Color {
        switch viewModel.overallComplianceRate {
        case 80...: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }

    private var complianceIcon: String {
        switch viewModel.overallComplianceRate {
        case 80...: return "checkmark.circle.fill"
        case 50..<80: return "exclamationmark.circle.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DashboardTab.allCases) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal)
        }
    }

    private func tabButton(_ tab: DashboardTab) -> some View {
        let count = tabCount(for: tab)
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
            HapticFeedback.selectionChanged()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.caption)

                Text(tab.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color(.systemGray5))
                        .cornerRadius(CornerRadius.sm)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? tabColor(for: tab) : Color(.secondarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func tabCount(for tab: DashboardTab) -> Int {
        switch tab {
        case .active: return viewModel.activePrescriptions.count
        case .overdue: return viewModel.overduePrescriptions.count
        case .completed: return viewModel.recentlyCompletedPrescriptions.count
        case .all: return viewModel.prescriptions.count
        }
    }

    private func tabColor(for tab: DashboardTab) -> Color {
        switch tab {
        case .active: return .blue
        case .overdue: return .red
        case .completed: return .green
        case .all: return .purple
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        let items = prescriptionsForTab

        if items.isEmpty {
            emptyStateForTab
        } else {
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
                    PrescriptionComplianceCard(
                        item: item,
                        onRemind: {
                            Task {
                                _ = await viewModel.sendReminder(for: item.prescription)
                            }
                        },
                        onCancel: {
                            prescriptionToCancel = item.prescription.id
                            showCancelConfirmation = true
                        },
                        onExtend: {
                            prescriptionToExtend = item.prescription
                            showExtendSheet = true
                        },
                        onTap: {
                            selectedPrescription = item
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private var prescriptionsForTab: [PrescriptionWithPatient] {
        switch selectedTab {
        case .active:
            return viewModel.activePrescriptions
        case .overdue:
            return viewModel.overduePrescriptions
        case .completed:
            return viewModel.recentlyCompletedPrescriptions
        case .all:
            return viewModel.filteredPrescriptions
        }
    }

    private var emptyStateForTab: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(emptyStateTitle)
                .font(.headline)

            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyStateIcon: String {
        switch selectedTab {
        case .active: return "doc.badge.clock"
        case .overdue: return "checkmark.circle"
        case .completed: return "doc.badge.plus"
        case .all: return "doc"
        }
    }

    private var emptyStateTitle: String {
        switch selectedTab {
        case .active: return "No Active Prescriptions"
        case .overdue: return "No Overdue Prescriptions"
        case .completed: return "No Recent Completions"
        case .all: return "No Prescriptions"
        }
    }

    private var emptyStateMessage: String {
        switch selectedTab {
        case .active: return "All prescribed workouts have been completed or are not yet due."
        case .overdue: return "Great! All your patients are on track with their prescriptions."
        case .completed: return "No prescriptions have been completed in the last 7 days."
        case .all: return "You haven't prescribed any workouts yet. Start by prescribing a workout to a patient."
        }
    }

    // MARK: - Filter Button

    private var filterButton: some View {
        Button {
            showFilters = true
            HapticFeedback.light()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                if hasActiveFilters {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .accessibilityLabel("Filters")
        .accessibilityHint(hasActiveFilters ? "Filters are active" : "Open filter options")
    }

    private var hasActiveFilters: Bool {
        viewModel.selectedStatusFilter != .all ||
        viewModel.selectedDateRange != .all ||
        viewModel.selectedPatientId != nil
    }

    // MARK: - Filter Sheet

    private var filterSheet: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Picker("Status", selection: $viewModel.selectedStatusFilter) {
                        ForEach(TherapistPrescriptionDashboardViewModel.StatusFilter.allCases) { filter in
                            HStack {
                                Image(systemName: filter.icon)
                                    .foregroundColor(filter.color)
                                Text(filter.rawValue)
                            }
                            .tag(filter)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Date Range") {
                    Picker("Date Range", selection: $viewModel.selectedDateRange) {
                        ForEach(TherapistPrescriptionDashboardViewModel.DateRangeFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Patient") {
                    Picker("Patient", selection: $viewModel.selectedPatientId) {
                        Text("All Patients").tag(nil as UUID?)
                        ForEach(viewModel.patients) { patient in
                            Text(patient.fullName).tag(patient.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    Button("Clear All Filters") {
                        viewModel.clearFilters()
                        HapticFeedback.light()
                    }
                    .foregroundColor(.red)
                    .disabled(!hasActiveFilters)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showFilters = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Loading & Error Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading prescriptions...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Load")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task { await loadData() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.md)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Methods

    private func loadData() async {
        guard let therapistId = appState.userId else {
            viewModel.errorMessage = "Unable to verify your account. Please sign in again."
            return
        }
        await viewModel.loadPrescriptions(therapistId: therapistId)
    }

    private func refreshData() async {
        guard let therapistId = appState.userId else { return }
        await viewModel.refresh(therapistId: therapistId)
    }
}

// MARK: - Extend Due Date Sheet

private struct ExtendDueDateSheet: View {
    let prescription: WorkoutPrescription
    let onExtend: (Date) -> Void
    let onCancel: () -> Void

    @State private var newDueDate: Date

    init(prescription: WorkoutPrescription, onExtend: @escaping (Date) -> Void, onCancel: @escaping () -> Void) {
        self.prescription = prescription
        self.onExtend = onExtend
        self.onCancel = onCancel
        self._newDueDate = State(initialValue: prescription.dueDate ?? Date().addingTimeInterval(86400 * 7))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(prescription.name)
                        .font(.headline)

                    if let currentDue = prescription.dueDate {
                        HStack {
                            Text("Current Due Date")
                            Spacer()
                            Text(currentDue, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("New Due Date") {
                    DatePicker(
                        "New Due Date",
                        selection: $newDueDate,
                        in: Date()...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                }

                Section {
                    Button {
                        HapticFeedback.medium()
                        onExtend(newDueDate)
                    } label: {
                        HStack {
                            Spacer()
                            Text("Extend Due Date")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                } footer: {
                    Text("The patient will be notified of the new due date.")
                }
            }
            .navigationTitle("Extend Due Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Preview

#if DEBUG
struct TherapistPrescriptionDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        TherapistPrescriptionDashboardView()
            .environmentObject(AppState())
    }
}
#endif
