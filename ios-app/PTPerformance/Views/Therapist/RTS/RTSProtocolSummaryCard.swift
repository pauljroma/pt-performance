//
//  RTSProtocolSummaryCard.swift
//  PTPerformance
//
//  Compact summary card for displaying RTS protocol status on patient detail views.
//  Shows current phase, traffic light, progress, and quick navigation to full dashboard.
//

import SwiftUI

// MARK: - RTS Protocol Summary Card

/// Compact summary card showing RTS protocol status for a patient
/// Used in PatientDetailView to provide quick RTS overview
struct RTSProtocolSummaryCard: View {
    let patientId: UUID
    @StateObject private var viewModel = RTSProtocolViewModel()

    @State private var showRTSDashboard = false
    @State private var showProtocolEditor = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.currentProtocol == nil {
                loadingState
            } else if let rtsProtocol = viewModel.currentProtocol {
                protocolContent(rtsProtocol)
            } else {
                emptyState
            }
        }
        .task {
            await viewModel.loadData(patientId: patientId)
        }
        .sheet(isPresented: $showRTSDashboard) {
            NavigationStack {
                RTSDashboardView(patientId: patientId)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showRTSDashboard = false
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Protocol Content

    private func protocolContent(_ rtsProtocol: RTSProtocol) -> some View {
        Button {
            HapticFeedback.light()
            showRTSDashboard = true
        } label: {
            VStack(spacing: Spacing.md) {
                // Header
                HStack {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "figure.run")
                            .foregroundColor(.indigo)

                        Text("Return to Sport")
                            .font(.headline)
                    }

                    Spacer()

                    // Status badge
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(rtsProtocol.status.color)
                            .frame(width: 8, height: 8)

                        Text(rtsProtocol.status.displayName)
                            .font(.caption)
                            .foregroundColor(rtsProtocol.status.color)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(rtsProtocol.status.color.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)
                }

                Divider()

                // Phase and traffic light
                HStack(spacing: Spacing.md) {
                    // Traffic light indicator
                    RTSTrafficLightBadge(
                        level: viewModel.currentTrafficLight,
                        size: .medium
                    )

                    // Phase info
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        if let phase = viewModel.currentPhase {
                            Text(phase.phaseName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text(phase.statusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Not Started")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("Protocol created")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Readiness score
                    if let readiness = viewModel.latestReadiness {
                        VStack(spacing: 2) {
                            RTSScoreGauge(score: readiness.overallScore, size: .small)

                            Text("Ready")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Progress bar
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(Int(rtsProtocol.progressPercentage * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(viewModel.currentTrafficLight.color)
                                .frame(width: geometry.size.width * rtsProtocol.progressPercentage)
                        }
                    }
                    .frame(height: 8)
                }

                // Days and target
                HStack {
                    // Days until target
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if rtsProtocol.daysUntilTarget >= 0 {
                            Text("\(rtsProtocol.daysUntilTarget) days to target")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(abs(rtsProtocol.daysUntilTarget)) days past target")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }

                    Spacer()

                    // View details
                    HStack(spacing: Spacing.xxs) {
                        Text("View Details")
                            .font(.caption)
                            .fontWeight(.medium)

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.indigo)
                }
            }
            .padding(Spacing.md)
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.lg)
            .adaptiveShadow(Shadow.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Return to Sport protocol, \(viewModel.currentPhase?.phaseName ?? "not started"), \(viewModel.currentTrafficLight.displayName)")
        .accessibilityHint("Double tap to view full RTS dashboard")
    }

    // MARK: - Loading State

    private var loadingState: some View {
        HStack(spacing: Spacing.md) {
            ProgressView()

            Text("Loading RTS protocol...")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "figure.run")
                        .foregroundColor(.indigo)

                    Text("Return to Sport")
                        .font(.headline)
                }

                Spacer()
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("No Active Protocol")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Create an RTS protocol to track this patient's return to sport journey")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Button {
                    HapticFeedback.light()
                    showProtocolEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.indigo)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.lg)
        .adaptiveShadow(Shadow.subtle)
    }
}

// MARK: - Compact RTS Card (Alternative)

/// Even more compact RTS status for use in lists or tight layouts
struct RTSCompactStatusBadge: View {
    let trafficLight: RTSTrafficLight
    let phaseName: String
    let progressPercentage: Double

    var body: some View {
        HStack(spacing: Spacing.sm) {
            RTSTrafficLightBadge(level: trafficLight, size: .small)

            VStack(alignment: .leading, spacing: 2) {
                Text(phaseName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                ProgressView(value: progressPercentage)
                    .tint(trafficLight.color)
                    .frame(width: 60)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Preview

#if DEBUG
struct RTSProtocolSummaryCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            // With protocol
            RTSProtocolSummaryCard(patientId: UUID())

            // Compact badge
            RTSCompactStatusBadge(
                trafficLight: .yellow,
                phaseName: "Light Tossing",
                progressPercentage: 0.45
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
