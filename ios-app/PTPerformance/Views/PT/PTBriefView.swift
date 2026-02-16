//
//  PTBriefView.swift
//  PTPerformance
//
//  PT 60-Second Athlete Brief - Core PT workflow for X2Index
//  M4 Product Plan: Actionable Readiness in 60 Seconds
//
//  Features:
//  - Opens in <=2 taps from caseload
//  - Athlete header (name, sport, last session date)
//  - Readiness score card with trend and confidence
//  - "Key Changes" section with top 3 deltas (cited)
//  - "Risk Alerts" section with flagged items
//  - "Suggested Actions" section with protocol recommendations
//  - Quick action buttons: Approve Plan, Adjust Plan, Add Note
//  - Every claim shows citation count badge
//  - Uncertainty is explicit (not hidden)
//  - Critical risks require acknowledgment
//

import SwiftUI
import Supabase

struct PTBriefView: View {
    let athleteId: UUID

    @StateObject private var viewModel = PTBriefViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showAddNote = false
    @State private var showProtocolBuilder = false
    @State private var showScoreBreakdown = false
    @State private var showEvidenceDetail = false
    @State private var selectedDelta: PTBriefDelta?
    @State private var selectedRisk: PTBriefRiskAlert?

    // Responsive layout
    private var shouldUseSplitView: Bool {
        DeviceHelper.shouldUseSplitView(horizontalSizeClass: horizontalSizeClass)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.athlete == nil {
                    loadingView
                } else if let error = viewModel.errorMessage, viewModel.athlete == nil {
                    errorView(message: error)
                } else {
                    briefContent
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Athlete Brief")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showAddNote = true
                        } label: {
                            Label("Add Note", systemImage: "note.text.badge.plus")
                        }

                        Button {
                            showProtocolBuilder = true
                        } label: {
                            Label("Protocol Builder", systemImage: "slider.horizontal.3")
                        }

                        Divider()

                        Button {
                            Task {
                                await viewModel.refresh(athleteId: athleteId)
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable {
                await viewModel.refresh(athleteId: athleteId)
            }
            .task {
                await viewModel.loadBrief(athleteId: athleteId)
            }
            .sheet(isPresented: $showAddNote) {
                PTBriefAddNoteSheet(athleteId: athleteId)
            }
            .sheet(isPresented: $showProtocolBuilder) {
                ProtocolBuilderSheet(
                    athleteId: athleteId,
                    athleteName: viewModel.athlete?.fullName ?? "Athlete"
                )
            }
            .sheet(isPresented: $showScoreBreakdown) {
                if let readiness = viewModel.readinessScore {
                    ScoreBreakdownSheet(
                        readiness: readiness,
                        dailyReadiness: viewModel.latestDailyReadiness
                    )
                }
            }
            .sheet(item: $selectedDelta) { delta in
                DeltaEvidenceSheet(delta: delta)
            }
            .sheet(item: $selectedRisk) { risk in
                RiskDetailSheet(risk: risk)
            }
        }
    }

    // MARK: - Brief Content

    private var briefContent: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                // Athlete Header
                if let athlete = viewModel.athlete {
                    athleteHeader(athlete)
                }

                // Readiness Score Card
                PTBriefHeaderCard(
                    readiness: viewModel.readinessScore,
                    isLoading: viewModel.isLoadingReadiness,
                    onTapBreakdown: { showScoreBreakdown = true }
                )

                // Key Changes Section
                PTBriefDeltaSection(
                    deltas: viewModel.topChanges,
                    isLoading: viewModel.isLoadingDeltas,
                    onDeltaTap: { delta in selectedDelta = delta }
                )

                // Risk Alerts Section
                PTBriefRiskSection(
                    risks: viewModel.riskAlerts,
                    isLoading: viewModel.isLoadingRisks,
                    onRiskTap: { risk in selectedRisk = risk },
                    onAcknowledge: { risk in viewModel.acknowledgeRisk(risk) }
                )

                // Suggested Actions Section
                PTBriefActionsSection(
                    actions: viewModel.suggestedActions,
                    isLoading: viewModel.isLoadingActions,
                    onApprove: { action in viewModel.approveAction(action) },
                    onReject: { action in viewModel.rejectAction(action) },
                    onViewProtocol: { _ in showProtocolBuilder = true },
                    onOpenProtocolBuilder: { showProtocolBuilder = true }
                )

                // Quick Actions Footer
                quickActionsFooter

                // KPI Debug (development only)
                #if DEBUG
                kpiDebugView
                #endif
            }
            .padding()
        }
    }

    // MARK: - Athlete Header

    private func athleteHeader(_ athlete: Patient) -> some View {
        HStack(spacing: Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.modusCyan.opacity(0.15))
                    .frame(width: 56, height: 56)

                Text(athlete.initials)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.modusCyan)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(athlete.fullName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.modusDeepTeal)

                HStack(spacing: Spacing.sm) {
                    if let sport = athlete.sport {
                        Label(sport, systemImage: "sportscourt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let position = athlete.position {
                        Text(position)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let lastSession = viewModel.lastSessionDateFormatted {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)

                        Text("Last session: \(lastSession)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(athlete.fullName), \(athlete.sport ?? "athlete")")
    }

    // MARK: - Quick Actions Footer

    private var quickActionsFooter: some View {
        VStack(spacing: Spacing.sm) {
            // Primary action: Approve Plan
            Button(action: {
                Task {
                    await viewModel.approvePlan()
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Approve Plan")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.modusCyan, .modusTealAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.md)
            }
            .disabled(viewModel.suggestedActions.filter { $0.status == .pending }.isEmpty)
            .opacity(viewModel.suggestedActions.filter { $0.status == .pending }.isEmpty ? 0.6 : 1.0)
            .accessibilityLabel("Approve plan")
            .accessibilityHint("Approves all pending actions")

            // Secondary actions
            HStack(spacing: Spacing.sm) {
                Button(action: {
                    showProtocolBuilder = true
                }) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Adjust Plan")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(CornerRadius.md)
                }
                .accessibilityLabel("Adjust plan")
                .accessibilityHint("Opens the protocol builder")

                Button(action: {
                    showAddNote = true
                }) {
                    HStack {
                        Image(systemName: "note.text.badge.plus")
                        Text("Add Note")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(CornerRadius.md)
                }
                .accessibilityLabel("Add note")
            }
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading athlete brief...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
                .accessibilityHidden(true)

            Text("Unable to Load Brief")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task {
                    await viewModel.loadBrief(athleteId: athleteId)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - KPI Debug View (Development Only)

    #if DEBUG
    private var kpiDebugView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("KPI Metrics (Debug)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            if let duration = viewModel.loadDurationSeconds {
                HStack {
                    Text("Load time:")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(String(format: "%.2f", duration))s")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(duration <= 2.0 ? .green : (duration <= 5.0 ? .orange : .red))
                }
            }

            HStack {
                Text("Target: <60s scan time")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }
    #endif
}

// MARK: - Placeholder Sheet Views

/// Add Note Sheet — allows PT to create categorized notes for an athlete
private struct PTBriefAddNoteSheet: View {
    let athleteId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var noteText = ""
    @State private var noteCategory: NoteCategory = .clinical
    @State private var isSaving = false
    @State private var saveError: String?

    enum NoteCategory: String, CaseIterable {
        case clinical = "Clinical"
        case progress = "Progress"
        case communication = "Communication"
        case general = "General"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $noteCategory) {
                        ForEach(NoteCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Note") {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 120)
                }

                if let error = saveError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveNote() }
                    }
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
    }

    private func saveNote() async {
        isSaving = true
        saveError = nil
        do {
            let note = TherapistNoteInsert(
                id: UUID().uuidString,
                athleteId: athleteId.uuidString,
                content: noteText.trimmingCharacters(in: .whitespacesAndNewlines),
                category: noteCategory.rawValue.lowercased(),
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
            try await PTSupabaseClient.shared.client
                .from("therapist_notes")
                .insert(note)
                .execute()
            DebugLogger.shared.log("[PTBrief] Note saved for athlete \(athleteId)", level: .info)
            dismiss()
        } catch {
            saveError = "Failed to save note. Please try again."
            DebugLogger.shared.log("[PTBrief] Failed to save note: \(error)", level: .error)
        }
        isSaving = false
    }
}

/// Codable struct for inserting therapist notes into Supabase
private struct TherapistNoteInsert: Encodable {
    let id: String
    let athleteId: String
    let content: String
    let category: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case athleteId = "athlete_id"
        case content
        case category
        case createdAt = "created_at"
    }
}

/// Protocol Builder Sheet - wraps the full ProtocolBuilderView for plan assignment
private struct ProtocolBuilderSheet: View {
    let athleteId: UUID
    let athleteName: String

    var body: some View {
        ProtocolBuilderView(athleteId: athleteId, athleteName: athleteName)
    }
}

/// Score Breakdown Sheet - displays dynamic readiness component data
private struct ScoreBreakdownSheet: View {
    let readiness: PTBriefReadiness
    let dailyReadiness: DailyReadiness?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Large score display
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                            .frame(width: 150, height: 150)

                        Circle()
                            .trim(from: 0, to: readiness.score / 100)
                            .stroke(readiness.scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))

                        VStack {
                            Text("\(Int(readiness.score))")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(readiness.scoreColor)

                            Text(readiness.scoreLabel)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Readiness score \(Int(readiness.score)), \(readiness.scoreLabel)")

                    // Breakdown details
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Score Components")
                            .font(.headline)
                            .foregroundColor(.modusDeepTeal)

                        if let daily = dailyReadiness {
                            BreakdownRow(
                                icon: "bed.double.fill",
                                label: "Sleep",
                                value: formatSleepHours(daily.sleepHours),
                                weight: "30%",
                                barProgress: sleepProgress(daily.sleepHours),
                                barColor: sleepColor(daily.sleepHours)
                            )

                            BreakdownRow(
                                icon: "bolt.fill",
                                label: "Energy",
                                value: formatLevel(daily.energyLevel, max: 10),
                                weight: "25%",
                                barProgress: levelProgress(daily.energyLevel, max: 10),
                                barColor: levelColor(daily.energyLevel, max: 10, inverted: false)
                            )

                            BreakdownRow(
                                icon: "figure.walk",
                                label: "Soreness",
                                value: formatLevel(daily.sorenessLevel, max: 10),
                                weight: "25%",
                                barProgress: levelProgress(daily.sorenessLevel, max: 10),
                                barColor: levelColor(daily.sorenessLevel, max: 10, inverted: true)
                            )

                            BreakdownRow(
                                icon: "brain.head.profile",
                                label: "Stress",
                                value: formatLevel(daily.stressLevel, max: 10),
                                weight: "20%",
                                barProgress: levelProgress(daily.stressLevel, max: 10),
                                barColor: levelColor(daily.stressLevel, max: 10, inverted: true)
                            )
                        } else {
                            // Fallback when no component data is available
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.secondary)
                                Text("Detailed component data is not available for this readiness entry.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)

                    // Confidence explanation
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Confidence Level")
                                .font(.headline)
                                .foregroundColor(.modusDeepTeal)

                            Spacer()

                            Text("\(Int(readiness.confidence * 100))%")
                                .font(.headline)
                                .foregroundColor(readiness.confidence >= 0.8 ? .green : .orange)
                        }

                        Text(readiness.confidenceReason)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Based on \(readiness.citationCount) data sources")
                            .font(.caption)
                            .foregroundColor(.modusCyan)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)

                    // Trend section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Trend")
                                .font(.headline)
                                .foregroundColor(.modusDeepTeal)

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: readiness.trend.icon)
                                Text(readiness.trend.displayName)
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(readiness.trend.color)
                        }

                        let formatter = RelativeDateTimeFormatter()
                        Text("Last updated \(formatter.localizedString(for: readiness.lastUpdated, relativeTo: Date()))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Score Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Formatting Helpers

    private func formatSleepHours(_ hours: Double?) -> String {
        guard let hours = hours else { return "--" }
        return String(format: "%.1fh", hours)
    }

    private func formatLevel(_ level: Int?, max: Int) -> String {
        guard let level = level else { return "--" }
        return "\(level)/\(max)"
    }

    private func sleepProgress(_ hours: Double?) -> Double {
        guard let hours = hours else { return 0 }
        // 8 hours is considered optimal
        return min(hours / 8.0, 1.0)
    }

    private func sleepColor(_ hours: Double?) -> Color {
        guard let hours = hours else { return .gray }
        if hours >= 7.0 { return .green }
        if hours >= 5.5 { return .yellow }
        return .orange
    }

    private func levelProgress(_ level: Int?, max: Int) -> Double {
        guard let level = level else { return 0 }
        return Double(level) / Double(max)
    }

    /// Returns a color for the level bar. When `inverted` is true, higher values
    /// are worse (e.g. soreness, stress) so high = red. When false, higher is
    /// better (e.g. energy) so high = green.
    private func levelColor(_ level: Int?, max: Int, inverted: Bool) -> Color {
        guard let level = level else { return .gray }
        let ratio = Double(level) / Double(max)
        if inverted {
            if ratio <= 0.3 { return .green }
            if ratio <= 0.6 { return .yellow }
            return .orange
        } else {
            if ratio >= 0.7 { return .green }
            if ratio >= 0.4 { return .yellow }
            return .orange
        }
    }
}

/// A single row in the score breakdown showing icon, label, value, weight, and a progress bar
private struct BreakdownRow: View {
    let icon: String
    let label: String
    let value: String
    let weight: String
    let barProgress: Double
    let barColor: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(barColor)
                    .frame(width: 24)

                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text("(\(weight))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: geometry.size.width * barProgress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value), weight \(weight)")
    }
}

/// Delta Evidence Sheet
private struct DeltaEvidenceSheet: View {
    let delta: PTBriefDelta
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Delta summary
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(delta.direction.color.opacity(0.15))
                                .frame(width: 48, height: 48)

                            Image(systemName: delta.direction.icon)
                                .font(.title3)
                                .foregroundColor(delta.direction.color)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(delta.metricName)
                                .font(.title3)
                                .fontWeight(.bold)

                            Text("\(delta.previousValue) -> \(delta.currentValue)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(delta.magnitude)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(delta.direction.color)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)

                    // Source information
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Data Source")
                            .font(.headline)
                            .foregroundColor(.modusDeepTeal)

                        HStack {
                            Image(systemName: delta.sourceType.icon)
                                .foregroundColor(.modusCyan)

                            Text(delta.source)
                                .font(.subheadline)

                            Spacer()

                            Text(delta.sourceType.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)

                    // Evidence Citations
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Evidence Citations")
                                .font(.headline)
                                .foregroundColor(.modusDeepTeal)

                            Spacer()

                            Text("\(delta.citationCount) sources")
                                .font(.caption)
                                .foregroundColor(.modusCyan)
                        }

                        // Source citation
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: delta.sourceType.icon)
                                .font(.caption2)
                                .foregroundColor(.modusCyan)

                            Text(delta.source)
                                .font(.caption)
                                .foregroundColor(.primary)

                            Spacer()

                            Text(delta.sourceType.rawValue)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.tertiarySystemGroupedBackground))
                                .cornerRadius(CornerRadius.xs)
                        }
                        .padding(Spacing.xs)
                        .background(Color(.tertiarySystemGroupedBackground).opacity(0.5))
                        .cornerRadius(CornerRadius.xs)

                        // Data point details
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text("Metric: \(delta.metricName)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text("Change: \(delta.previousValue) \u{2192} \(delta.currentValue) (\(delta.magnitude))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text("Recorded: \(delta.timestamp.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Evidence Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

/// Risk Detail Sheet
private struct RiskDetailSheet: View {
    let risk: PTBriefRiskAlert
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Risk summary
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(risk.severity.color.opacity(0.15))
                                .frame(width: 48, height: 48)

                            Image(systemName: risk.severity.icon)
                                .font(.title3)
                                .foregroundColor(risk.severity.color)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(risk.title)
                                .font(.title3)
                                .fontWeight(.bold)

                            Text(risk.severity.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(risk.severity.color)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(risk.severity.color.opacity(0.05))
                    .cornerRadius(CornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .stroke(risk.severity.color.opacity(0.3), lineWidth: 1)
                    )

                    // Description
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.modusDeepTeal)

                        Text(risk.description)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)

                    // Threshold comparison
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Threshold Analysis")
                            .font(.headline)
                            .foregroundColor(.modusDeepTeal)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Threshold")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(risk.thresholdValue)
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }

                            Spacer()

                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("Current")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(risk.currentValue)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(risk.severity.color)
                            }
                        }

                        Text("Source: \(risk.source)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)

                    // Evidence Citations
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Evidence Citations")
                                .font(.headline)
                                .foregroundColor(.modusDeepTeal)

                            Spacer()

                            Text("\(risk.citationCount) sources")
                                .font(.caption)
                                .foregroundColor(.modusCyan)
                        }

                        // Source citation
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "exclamationmark.shield")
                                .font(.caption2)
                                .foregroundColor(risk.severity.color)

                            Text(risk.source)
                                .font(.caption)
                                .foregroundColor(.primary)

                            Spacer()

                            Text(risk.severity.displayName)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(risk.severity.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(risk.severity.color.opacity(0.1))
                                .cornerRadius(CornerRadius.xs)
                        }
                        .padding(Spacing.xs)
                        .background(Color(.tertiarySystemGroupedBackground).opacity(0.5))
                        .cornerRadius(CornerRadius.xs)

                        // Threshold evidence
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "gauge.with.needle")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text("Threshold: \(risk.thresholdValue)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "chart.bar")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text("Current value: \(risk.currentValue)")
                                    .font(.caption2)
                                    .foregroundColor(risk.severity.color)
                            }

                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text("Detected: \(risk.timestamp.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(CornerRadius.lg)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Risk Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PTBriefView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PTBriefView(athleteId: UUID())
                .previewDisplayName("Default")

            PTBriefView(athleteId: UUID())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif
