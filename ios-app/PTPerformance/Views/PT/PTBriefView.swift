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
                ProtocolBuilderSheet(athleteId: athleteId)
            }
            .sheet(isPresented: $showScoreBreakdown) {
                if let readiness = viewModel.readinessScore {
                    ScoreBreakdownSheet(readiness: readiness)
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

/// Placeholder for Add Note Sheet
private struct PTBriefAddNoteSheet: View {
    let athleteId: UUID
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "note.text.badge.plus")
                    .font(.system(size: 64))
                    .foregroundColor(.modusCyan)

                Text("Add Note")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Note editor coming soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

/// Placeholder for Protocol Builder Sheet
private struct ProtocolBuilderSheet: View {
    let athleteId: UUID
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 64))
                    .foregroundColor(.modusCyan)

                Text("Protocol Builder")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Full protocol customization coming soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Protocol Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

/// Score Breakdown Sheet
private struct ScoreBreakdownSheet: View {
    let readiness: PTBriefReadiness
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

                    // Breakdown details
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Score Components")
                            .font(.headline)
                            .foregroundColor(.modusDeepTeal)

                        // Placeholder breakdown items
                        BreakdownRow(label: "Sleep Quality", value: "75%", weight: "30%")
                        BreakdownRow(label: "HRV Status", value: "Good", weight: "25%")
                        BreakdownRow(label: "Subjective Readiness", value: "7/10", weight: "20%")
                        BreakdownRow(label: "Recovery Status", value: "Moderate", weight: "15%")
                        BreakdownRow(label: "Training Load", value: "Optimal", weight: "10%")
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
}

private struct BreakdownRow: View {
    let label: String
    let value: String
    let weight: String

    var body: some View {
        HStack {
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
        .padding(.vertical, Spacing.xxs)
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

                    // Citation placeholder
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

                        Text("Detailed citation view coming soon. Evidence includes raw data points, timestamps, and source reliability metrics.")
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

                    // Citations
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

                        Text("Full evidence chain and clinical guidelines reference coming soon.")
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
