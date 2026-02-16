// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  ProgramEffectivenessView.swift
//  PTPerformance
//
//  Main view for Program Effectiveness Analytics
//  Helps therapists understand which programs produce the best patient outcomes
//

import SwiftUI
import Charts

// MARK: - Program Effectiveness View

struct ProgramEffectivenessView: View {
    @StateObject private var viewModel = ProgramEffectivenessViewModel()
    @EnvironmentObject var appState: AppState

    @State private var selectedTab: EffectivenessTab = .overview
    @State private var showFilters = false
    @State private var showProgramDetail = false
    @State private var showComparisonMode = false

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    enum EffectivenessTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case programs = "Programs"
        case compare = "Compare"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .overview: return "chart.pie.fill"
            case .programs: return "list.bullet.rectangle"
            case .compare: return "arrow.left.arrow.right"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.programMetrics.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage, viewModel.programMetrics.isEmpty {
                    errorView(error)
                } else if viewModel.hasInsufficientData {
                    ContentUnavailableView(
                        "Not Enough Data",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Program effectiveness data will appear after patients complete more sessions.")
                    )
                } else {
                    mainContent
                }
            }
            .navigationTitle("Program Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterButton
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search programs")
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showFilters) {
                filterSheet
            }
            .sheet(item: $viewModel.selectedProgram) { program in
                NavigationStack {
                    ProgramEffectivenessDetailView(
                        program: program,
                        viewModel: viewModel
                    )
                }
            }
            .sheet(isPresented: $viewModel.showComparisonSheet) {
                NavigationStack {
                    ProgramComparisonSheet(viewModel: viewModel)
                }
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
                // Summary stats
                summarySection

                // Tab selector
                tabSelector

                // Content based on selected tab
                tabContent
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Overall effectiveness header
            effectivenessHeaderCard

            // Quick stats
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    EffectivenessStatsCard(
                        title: "Programs",
                        value: "\(viewModel.summaryStats.totalPrograms)",
                        icon: "doc.richtext",
                        color: .modusCyan,
                        subtitle: "total"
                    )

                    EffectivenessStatsCard(
                        title: "Completion",
                        value: viewModel.summaryStats.formattedCompletionRate,
                        icon: "checkmark.circle.fill",
                        color: .green,
                        subtitle: "average"
                    )

                    EffectivenessStatsCard(
                        title: "Patients",
                        value: "\(viewModel.summaryStats.totalPatients)",
                        icon: "person.2.fill",
                        color: .purple,
                        subtitle: "enrolled"
                    )

                    EffectivenessStatsCard(
                        title: "Attention",
                        value: "\(viewModel.programsNeedingAttention.count)",
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        subtitle: "programs"
                    )
                }
                .padding(.horizontal)
            }
        }
    }

    private var effectivenessHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Effectiveness")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(viewModel.summaryStats.averageEffectiveness * 100))")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(effectivenessColor)

                        Text("%")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(effectivenessColor)
                    }
                }

                Spacer()

                // Effectiveness gauge
                effectivenessGauge
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(effectivenessColor)
                        .frame(width: geometry.size.width * min(viewModel.summaryStats.averageEffectiveness, 1.0), height: 8)
                }
            }
            .frame(height: 8)

            // Top performers label
            if !viewModel.topPrograms.isEmpty {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text("Top: \(viewModel.topPrograms.first?.programName ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.medium)
        .padding(.horizontal)
    }

    private var effectivenessGauge: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 8)
                .frame(width: 70, height: 70)

            Circle()
                .trim(from: 0, to: min(viewModel.summaryStats.averageEffectiveness, 1.0))
                .stroke(effectivenessColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 70, height: 70)
                .rotationEffect(.degrees(-90))

            Image(systemName: effectivenessIcon)
                .font(.title2)
                .foregroundColor(effectivenessColor)
        }
    }

    private var effectivenessColor: Color {
        switch viewModel.summaryStats.averageEffectiveness {
        case 0.8...: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }

    private var effectivenessIcon: String {
        switch viewModel.summaryStats.averageEffectiveness {
        case 0.8...: return "star.fill"
        case 0.6..<0.8: return "hand.thumbsup.fill"
        case 0.4..<0.6: return "minus.circle.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(EffectivenessTab.allCases) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal)
        }
    }

    private func tabButton(_ tab: EffectivenessTab) -> some View {
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
            }
            .padding(.horizontal, 14)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? tabColor(for: tab) : Color(.secondarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func tabColor(for tab: EffectivenessTab) -> Color {
        switch tab {
        case .overview: return .blue
        case .programs: return .purple
        case .compare: return .green
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            overviewContent
        case .programs:
            programsListContent
        case .compare:
            compareContent
        }
    }

    private var overviewContent: some View {
        VStack(spacing: 16) {
            // Top performing programs
            if !viewModel.topPrograms.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Top Performing Programs")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)

                    ForEach(viewModel.topPrograms) { program in
                        TopProgramCard(program: program) {
                            viewModel.selectProgram(program)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Programs needing attention
            if !viewModel.programsNeedingAttention.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Needs Attention")
                            .font(.headline)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(.horizontal)

                    ForEach(viewModel.programsNeedingAttention) { program in
                        AttentionProgramCard(program: program) {
                            viewModel.selectProgram(program)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Effectiveness distribution chart
            if !viewModel.programMetrics.isEmpty {
                effectivenessDistributionChart
            }
        }
    }

    private var effectivenessDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Effectiveness Distribution")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(EffectivenessRating.allCases, id: \.self) { rating in
                    let count = viewModel.programMetrics.filter { $0.effectivenessRating == rating }.count
                    BarMark(
                        x: .value("Rating", rating.displayName),
                        y: .value("Count", count)
                    )
                    .foregroundStyle(rating.color)
                    .cornerRadius(CornerRadius.xs)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.lg)
            .padding(.horizontal)
        }
    }

    private var programsListContent: some View {
        LazyVStack(spacing: 12) {
            if viewModel.filteredPrograms.isEmpty {
                emptyProgramsState
            } else {
                ForEach(viewModel.filteredPrograms) { program in
                    ProgramMetricsCard(program: program) {
                        viewModel.selectProgram(program)
                    } onAnalytics: {
                        viewModel.selectProgram(program)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var compareContent: some View {
        VStack(spacing: 16) {
            // Instructions
            if viewModel.selectedProgramsForComparison.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.left.arrow.right.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("Compare Programs")
                        .font(.headline)

                    Text("Select 2-3 programs below to compare their effectiveness side-by-side")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 20)
            }

            // Selected programs for comparison
            if !viewModel.selectedProgramsForComparison.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Selected for Comparison")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Clear") {
                            viewModel.clearComparisonSelection()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.selectedProgramsForComparison) { program in
                                SelectedComparisonChip(program: program) {
                                    viewModel.toggleProgramForComparison(program)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Compare button
                    Button {
                        viewModel.showComparisonSheet = true
                        Task {
                            await viewModel.loadComparison()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                            Text("Compare Programs")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(viewModel.canCompare ? Color.modusCyan : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(CornerRadius.md)
                    }
                    .disabled(!viewModel.canCompare)
                    .padding(.horizontal)
                }
            }

            // Programs to select
            VStack(alignment: .leading, spacing: 8) {
                Text("Available Programs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                ForEach(viewModel.availableForComparison) { program in
                    ComparisonSelectableCard(
                        program: program,
                        isSelected: viewModel.selectedProgramsForComparison.contains(where: { $0.id == program.id })
                    ) {
                        viewModel.toggleProgramForComparison(program)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var emptyProgramsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Programs Found")
                .font(.headline)

            Text("No programs match your current filters.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.selectedTypeFilter != nil || viewModel.selectedRatingFilter != nil {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
                .font(.subheadline)
                .foregroundColor(.modusCyan)
            }
        }
        .padding(.vertical, 60)
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
                        .fill(Color.modusCyan)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .accessibilityLabel("Filters")
        .accessibilityHint(hasActiveFilters ? "Filters are active" : "Open filter options")
    }

    private var hasActiveFilters: Bool {
        viewModel.selectedTypeFilter != nil || viewModel.selectedRatingFilter != nil
    }

    // MARK: - Filter Sheet

    private var filterSheet: some View {
        NavigationStack {
            Form {
                Section("Program Type") {
                    Picker("Type", selection: $viewModel.selectedTypeFilter) {
                        Text("All Types").tag(nil as ProgramType?)
                        ForEach(ProgramType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.displayName)
                            }
                            .tag(type as ProgramType?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Effectiveness Rating") {
                    Picker("Rating", selection: $viewModel.selectedRatingFilter) {
                        Text("All Ratings").tag(nil as EffectivenessRating?)
                        ForEach(EffectivenessRating.allCases, id: \.self) { rating in
                            HStack {
                                Image(systemName: rating.icon)
                                    .foregroundColor(rating.color)
                                Text(rating.displayName)
                            }
                            .tag(rating as EffectivenessRating?)
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

            Text("Loading analytics...")
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
                .padding(.horizontal, Spacing.xl)

            Button {
                Task { await loadData() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.headline)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(Color.modusCyan)
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
        await viewModel.loadProgramMetrics(therapistId: therapistId)
    }

    private func refreshData() async {
        guard let therapistId = appState.userId else { return }
        await viewModel.refresh(therapistId: therapistId)
    }
}

// MARK: - Supporting Views

private struct EffectivenessStatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 100)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }
}

private struct TopProgramCard: View {
    let program: ProgramMetrics
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Rank badge
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "star.fill")
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(program.programName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Label(program.formattedCompletionRate, systemImage: "checkmark.circle")
                        Label(String(format: "%.0f%%", program.effectivenessScore * 100), systemImage: "star")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct AttentionProgramCard: View {
    let program: ProgramMetrics
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(program.programName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Label(program.formattedCompletionRate, systemImage: "checkmark.circle")
                        Label("\(program.droppedEnrollments) dropped", systemImage: "person.badge.minus")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct ProgramMetricsCard: View {
    let program: ProgramMetrics
    let onTap: () -> Void
    let onAnalytics: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(program.programName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack(spacing: 4) {
                            Image(systemName: program.resolvedProgramType.icon)
                                .font(.caption2)
                            Text(program.resolvedProgramType.displayName)
                                .font(.caption2)
                        }
                        .foregroundColor(program.resolvedProgramType.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(program.resolvedProgramType.color.opacity(0.15))
                        .cornerRadius(CornerRadius.xs)
                    }

                    Spacer()

                    // Effectiveness badge
                    EffectivenessScoreBadge(rating: program.effectivenessRating, score: program.effectivenessScore)
                }

                // Metrics
                HStack(spacing: 16) {
                    MetricPill(label: "Completion", value: program.formattedCompletionRate, color: .green)
                    MetricPill(label: "Adherence", value: program.formattedAdherence, color: .modusCyan)
                    MetricPill(label: "Patients", value: "\(program.totalEnrollments)", color: .purple)
                }

                // Actions
                HStack {
                    Button {
                        onAnalytics()
                    } label: {
                        HStack {
                            Image(systemName: "chart.bar.xaxis")
                            Text("Analytics")
                        }
                        .font(.caption)
                        .foregroundColor(.modusCyan)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
            .adaptiveShadow(Shadow.subtle)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EffectivenessScoreBadge: View {
    let rating: EffectivenessRating
    let score: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: rating.icon)
                .font(.caption2)
            Text(String(format: "%.0f%%", score * 100))
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(rating.color)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(rating.color.opacity(0.15))
        .cornerRadius(CornerRadius.sm)
    }
}

private struct MetricPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

private struct SelectedComparisonChip: View {
    let program: ProgramMetrics
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(program.programName)
                .font(.caption)
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.modusCyan)
        .cornerRadius(CornerRadius.lg)
    }
}

private struct ComparisonSelectableCard: View {
    let program: ProgramMetrics
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .modusCyan : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(program.programName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text("\(program.totalEnrollments) patients")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                EffectivenessScoreBadge(rating: program.effectivenessRating, score: program.effectivenessScore)
            }
            .padding()
            .background(isSelected ? Color.modusCyan.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? Color.modusCyan : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct ProgramEffectivenessView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramEffectivenessView()
            .environmentObject(AppState())
    }
}
#endif
