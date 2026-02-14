//
//  ModeSwitchingPanel.swift
//  PTPerformance
//
//  Created by Claude (BUILD 115) on 2026-01-02.
//  Therapist admin panel for changing patient modes
//

import SwiftUI

struct ModeSwitchingPanel: View {
    let patientId: String
    @StateObject private var viewModel: ModeSwitchingViewModel

    init(patientId: String) {
        self.patientId = patientId
        _viewModel = StateObject(wrappedValue: ModeSwitchingViewModel(patientId: patientId))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "switch.2")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("Patient Mode")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()
            }

            // Current Mode Display
            currentModeSection

            // Mode Change Section
            if viewModel.canChangeMode {
                changeModeSectionView
            }

            // Mode History
            modeHistorySection
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
        .task {
            async let a: () = viewModel.loadPatientMode()
            async let b: () = viewModel.loadModeHistory()
            _ = await (a, b)
        }
        .alert("Change Mode", isPresented: $viewModel.showingConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.showingConfirmation = false
            }
            Button("Confirm") {
                Task {
                    await viewModel.confirmModeChange()
                }
            }
        } message: {
            Text("Change \(viewModel.patientName ?? "patient") from \(viewModel.currentMode.displayName) to \(viewModel.selectedMode.displayName)?")
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") {
                viewModel.showingError = false
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Current Mode Section
    private var currentModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Mode")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: viewModel.currentMode.iconName)
                    .font(.title)
                    .foregroundColor(colorForMode(viewModel.currentMode))

                VStack(alignment: .leading) {
                    Text(viewModel.currentMode.displayName)
                        .font(.headline)

                    Text(viewModel.currentMode.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorForMode(viewModel.currentMode).opacity(0.1))
            )

            if let changedAt = viewModel.modeChangedAt {
                Text("Last changed: \(changedAt, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Change Mode Section
    private var changeModeSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Change Mode")
                .font(.headline)

            // Mode Picker
            Picker("Select Mode", selection: $viewModel.selectedMode) {
                ForEach(Mode.allCases, id: \.self) { mode in
                    HStack {
                        Image(systemName: mode.iconName)
                        Text(mode.displayName)
                    }
                    .tag(mode)
                }
            }
            .pickerStyle(.segmented)

            // Reason Text Field
            TextField("Reason for change (optional)", text: $viewModel.reasonForChange, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)

            // Change Button
            Button(action: {
                viewModel.showingConfirmation = true
            }) {
                if viewModel.isChangingMode {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Text("Change Mode")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedMode == viewModel.currentMode || viewModel.isChangingMode)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Mode History Section
    private var modeHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mode History")
                .font(.headline)

            if viewModel.modeHistory.isEmpty {
                Text("No mode changes yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.modeHistory.prefix(5)) { entry in
                    modeHistoryRow(entry)
                }
            }
        }
    }

    private func modeHistoryRow(_ entry: ModeHistoryEntry) -> some View {
        HStack(spacing: 12) {
            // Change indicator
            VStack {
                if let previousMode = entry.previousMode {
                    Image(systemName: previousMode.iconName)
                        .font(.caption)
                        .foregroundColor(colorForMode(previousMode))
                }

                Image(systemName: "arrow.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Image(systemName: entry.newMode.iconName)
                    .font(.caption)
                    .foregroundColor(colorForMode(entry.newMode))
            }

            VStack(alignment: .leading, spacing: 2) {
                if let previousMode = entry.previousMode {
                    Text("\(previousMode.displayName) → \(entry.newMode.displayName)")
                        .font(.caption)
                        .fontWeight(.medium)
                } else {
                    Text("Set to \(entry.newMode.displayName)")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                if let reason = entry.reason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text(entry.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helper
    private func colorForMode(_ mode: Mode) -> Color {
        let theme = ModeTheme.theme(for: mode)
        return theme.primaryColor
    }
}

// MARK: - Preview
#Preview {
    ModeSwitchingPanel(patientId: "test-patient-id")
        .padding()
}
