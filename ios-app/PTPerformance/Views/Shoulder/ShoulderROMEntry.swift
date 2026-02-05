//
//  ShoulderROMEntry.swift
//  PTPerformance
//
//  ACP-545: Shoulder ROM Entry View
//  Form for logging internal/external rotation measurements
//

import SwiftUI

/// View for entering shoulder ROM measurements
struct ShoulderROMEntry: View {
    let side: ShoulderSide
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ShoulderROMEntryViewModel()

    @State private var internalRotation: Double = 70
    @State private var externalRotation: Double = 90
    @State private var notes: String = ""
    @State private var selectedSide: ShoulderSide

    init(side: ShoulderSide, onComplete: @escaping () -> Void) {
        self.side = side
        self.onComplete = onComplete
        _selectedSide = State(initialValue: side)
    }

    var body: some View {
        Form {
            // Side Selection
            Section {
                Picker("Side", selection: $selectedSide) {
                    ForEach(ShoulderSide.allCases, id: \.self) { side in
                        Text(side.displayName).tag(side)
                    }
                }
            } header: {
                Text("Shoulder Side")
            }

            // Internal Rotation
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Internal Rotation")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(internalRotation))°")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(internalRotationColor)
                    }

                    Slider(value: $internalRotation, in: 0...120, step: 1) {
                        Text("IR")
                    } minimumValueLabel: {
                        Text("0°")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("120°")
                            .font(.caption)
                    }
                    .tint(internalRotationColor)

                    // Reference ranges
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                        Text("Normal range: 70-90°")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if internalRotation < 60 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("IR deficit detected - below 60°")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            } header: {
                Text("Internal Rotation (IR)")
            } footer: {
                Text("Measure with arm at 90° abduction, rotating hand toward the floor")
            }

            // External Rotation
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("External Rotation")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(externalRotation))°")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(externalRotationColor)
                    }

                    Slider(value: $externalRotation, in: 0...120, step: 1) {
                        Text("ER")
                    } minimumValueLabel: {
                        Text("0°")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("120°")
                            .font(.caption)
                    }
                    .tint(externalRotationColor)

                    // Reference ranges
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                        Text("Normal range: 90-100°")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("External Rotation (ER)")
            } footer: {
                Text("Measure with arm at 90° abduction, rotating hand toward the ceiling")
            }

            // Total Arc Summary
            Section {
                VStack(spacing: 16) {
                    HStack {
                        Text("Total Arc of Motion")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(totalArc))°")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(totalArcColor)
                    }

                    // Visual representation
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(internalRotationColor.opacity(0.7))
                            .frame(width: irWidthPercentage, height: 30)
                            .overlay(
                                Text("IR \(Int(internalRotation))°")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            )

                        Rectangle()
                            .fill(externalRotationColor.opacity(0.7))
                            .frame(width: erWidthPercentage, height: 30)
                            .overlay(
                                Text("ER \(Int(externalRotation))°")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            )
                    }
                    .cornerRadius(6)

                    // Reference
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                        Text("Target total arc: 160-180°")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Summary")
            }

            // Side-to-Side Comparison (if data exists)
            if let comparison = viewModel.oppositesSideData {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Opposite Side (\(comparison.side.displayName))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("IR: \(Int(comparison.internalRotation))°")
                                Text("ER: \(Int(comparison.externalRotation))°")
                                Text("Total: \(Int(comparison.totalArc))°")
                            }
                            .font(.caption)

                            Spacer()

                            VStack(alignment: .trailing) {
                                differenceText(current: internalRotation, opposite: comparison.internalRotation, label: "IR")
                                differenceText(current: externalRotation, opposite: comparison.externalRotation, label: "ER")
                                differenceText(current: totalArc, opposite: comparison.totalArc, label: "Total")
                            }
                            .font(.caption)
                        }

                        // GIRD warning
                        if internalRotation < comparison.internalRotation - 18 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Possible GIRD: >18° IR difference from opposite side")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.top, 4)
                        }
                    }
                } header: {
                    Text("Side-to-Side Comparison")
                }
            }

            // Notes
            Section {
                TextField("Optional notes", text: $notes, axis: .vertical)
                    .lineLimit(3...5)
            } header: {
                Text("Notes")
            }
        }
        .navigationTitle("Log ROM")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await saveMeasurement()
                    }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Save")
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .task {
            await viewModel.loadOppositeSideData(side: selectedSide)
        }
        .onChange(of: selectedSide) { _, newSide in
            Task {
                await viewModel.loadOppositeSideData(side: newSide)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Failed to save measurement")
        }
    }

    // MARK: - Computed Properties

    private var totalArc: Double {
        internalRotation + externalRotation
    }

    private var internalRotationColor: Color {
        if internalRotation < 50 { return .red }
        if internalRotation < 60 { return .orange }
        if internalRotation < 70 { return .yellow }
        return .green
    }

    private var externalRotationColor: Color {
        if externalRotation < 70 { return .orange }
        if externalRotation < 90 { return .yellow }
        return .green
    }

    private var totalArcColor: Color {
        if totalArc < 140 { return .red }
        if totalArc < 160 { return .orange }
        if totalArc < 180 { return .blue }
        return .green
    }

    private var irWidthPercentage: CGFloat {
        CGFloat(internalRotation / 240) * 300  // Scale to fit container
    }

    private var erWidthPercentage: CGFloat {
        CGFloat(externalRotation / 240) * 300  // Scale to fit container
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func differenceText(current: Double, opposite: Double, label: String) -> some View {
        let diff = current - opposite
        let color: Color = abs(diff) > 15 ? .orange : (diff >= 0 ? .green : .secondary)

        HStack(spacing: 2) {
            Text(label + ":")
            if diff >= 0 {
                Text("+\(Int(diff))°")
            } else {
                Text("\(Int(diff))°")
            }
        }
        .foregroundColor(color)
    }

    // MARK: - Actions

    private func saveMeasurement() async {
        await viewModel.saveMeasurement(
            side: selectedSide,
            internalRotation: internalRotation,
            externalRotation: externalRotation,
            notes: notes.isEmpty ? nil : notes
        )

        if !viewModel.showError {
            onComplete()
            dismiss()
        }
    }
}

// MARK: - ViewModel

@MainActor
class ShoulderROMEntryViewModel: ObservableObject {
    @Published var isSaving = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var oppositesSideData: ShoulderROMMeasurement?

    private let service = ShoulderHealthService.shared
    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    func loadOppositeSideData(side: ShoulderSide) async {
        guard let patientId = supabase.userId else { return }

        let oppositeSide: ShoulderSide
        switch side {
        case .left: oppositeSide = .right
        case .right: oppositeSide = .left
        case .dominant: oppositeSide = .nonDominant
        case .nonDominant: oppositeSide = .dominant
        }

        do {
            let measurements = try await service.fetchROMMeasurements(
                patientId: patientId,
                side: oppositeSide,
                limit: 1
            )
            oppositesSideData = measurements.first
        } catch {
            logger.error("ROM ENTRY", "Failed to load opposite side data: \(error)")
        }
    }

    func saveMeasurement(
        side: ShoulderSide,
        internalRotation: Double,
        externalRotation: Double,
        notes: String?
    ) async {
        guard let patientIdString = supabase.userId,
              let patientId = UUID(uuidString: patientIdString) else {
            errorMessage = "Unable to identify user"
            showError = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let dto = CreateShoulderROMDTO(
                patientId: patientId,
                side: side,
                internalRotation: internalRotation,
                externalRotation: externalRotation,
                notes: notes
            )

            _ = try await service.createROMMeasurement(dto)
            logger.success("ROM ENTRY", "Saved ROM measurement successfully")
        } catch {
            logger.error("ROM ENTRY", "Failed to save: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ShoulderROMEntry(side: .right) {
            print("Completed")
        }
    }
}
