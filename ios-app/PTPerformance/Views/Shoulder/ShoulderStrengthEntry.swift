//
//  ShoulderStrengthEntry.swift
//  PTPerformance
//
//  ACP-545: Shoulder Strength Entry View
//  Form for logging internal/external rotation strength measurements
//

import SwiftUI

/// View for entering shoulder strength measurements
struct ShoulderStrengthEntry: View {
    let side: ShoulderSide
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ShoulderStrengthEntryViewModel()

    @State private var internalRotationStrength: Double = 30
    @State private var externalRotationStrength: Double = 21
    @State private var selectedUnit: StrengthUnit = .pounds
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

            // Unit Selection
            Section {
                Picker("Unit", selection: $selectedUnit) {
                    ForEach(StrengthUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Measurement Unit")
            }

            // Internal Rotation Strength
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Internal Rotation Strength")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(internalRotationStrength)) \(selectedUnit.displayName)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Slider(value: $internalRotationStrength, in: 0...100, step: 1) {
                        Text("IR Strength")
                    } minimumValueLabel: {
                        Text("0")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("100")
                            .font(.caption)
                    }
                    .tint(.blue)
                }
            } header: {
                Text("IR Strength")
            } footer: {
                Text("Measure with dynamometer or cable resistance at 90° position")
            }

            // External Rotation Strength
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("External Rotation Strength")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(externalRotationStrength)) \(selectedUnit.displayName)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Slider(value: $externalRotationStrength, in: 0...100, step: 1) {
                        Text("ER Strength")
                    } minimumValueLabel: {
                        Text("0")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("100")
                            .font(.caption)
                    }
                    .tint(.orange)
                }
            } header: {
                Text("ER Strength")
            } footer: {
                Text("Measure with dynamometer or cable resistance at 90° position")
            }

            // ER:IR Ratio Section
            Section {
                VStack(spacing: 20) {
                    // Ratio Display
                    HStack {
                        Text("ER:IR Ratio")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(erIrRatio))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(ratioCategory.color)
                    }

                    // Visual gauge
                    ratioGauge

                    // Target range info
                    HStack(spacing: 16) {
                        VStack(alignment: .center) {
                            Text("<60%")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text("Low")
                                .font(.caption2)
                        }

                        VStack(alignment: .center) {
                            Text("66-75%")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text("Target")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }

                        VStack(alignment: .center) {
                            Text(">85%")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("High")
                                .font(.caption2)
                        }
                    }

                    // Status message
                    HStack {
                        Image(systemName: ratioCategory == .optimal ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(ratioCategory.color)
                        Text(ratioCategory.displayName)
                            .font(.subheadline)
                            .foregroundColor(ratioCategory.color)
                    }
                }
            } header: {
                Text("Strength Balance")
            } footer: {
                Text("Healthy ER:IR ratio is typically 66-75% for overhead athletes")
            }

            // Alerts based on ratio
            if ratioCategory == .low || ratioCategory == .belowTarget {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Low ER:IR Ratio Detected")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Text("Your external rotator strength is low relative to internal rotation. This imbalance may increase injury risk.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recommended exercises:")
                                .font(.caption)
                                .fontWeight(.medium)

                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption2)
                                Text("Side-lying external rotation")
                                    .font(.caption)
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption2)
                                Text("Prone Y-T-W exercises")
                                    .font(.caption)
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption2)
                                Text("Cable external rotation at 90°")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.blue)
                    }
                } header: {
                    Text("Recommendations")
                }
            }

            // Previous measurements comparison
            if let previous = viewModel.previousMeasurement {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Previous: \(previous.measuredAt, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("IR: \(Int(previous.internalRotationStrength)) \(previous.unit.displayName)")
                                Text("ER: \(Int(previous.externalRotationStrength)) \(previous.unit.displayName)")
                                Text("Ratio: \(Int(previous.erIrRatio))%")
                            }
                            .font(.caption)

                            Spacer()

                            VStack(alignment: .trailing) {
                                changeIndicator(current: internalRotationStrength, previous: previous.internalRotationStrength)
                                changeIndicator(current: externalRotationStrength, previous: previous.externalRotationStrength)
                                changeIndicator(current: erIrRatio, previous: previous.erIrRatio, isPercentage: true)
                            }
                            .font(.caption)
                        }
                    }
                } header: {
                    Text("Comparison to Last Measurement")
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
        .navigationTitle("Log Strength")
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
            await viewModel.loadPreviousMeasurement(side: selectedSide)
        }
        .onChange(of: selectedSide) { _, newSide in
            Task {
                await viewModel.loadPreviousMeasurement(side: newSide)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Failed to save measurement")
        }
    }

    // MARK: - Computed Properties

    private var erIrRatio: Double {
        guard internalRotationStrength > 0 else { return 0 }
        return (externalRotationStrength / internalRotationStrength) * 100
    }

    private var ratioCategory: StrengthRatioCategory {
        if erIrRatio < 60 { return .low }
        if erIrRatio < 66 { return .belowTarget }
        if erIrRatio <= 75 { return .optimal }
        if erIrRatio <= 85 { return .aboveTarget }
        return .high
    }

    // MARK: - Subviews

    private var ratioGauge: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 24)

                // Colored segments
                HStack(spacing: 0) {
                    // Low (<60)
                    Rectangle()
                        .fill(Color.red.opacity(0.6))
                        .frame(width: geometry.size.width * 0.3)

                    // Below target (60-66)
                    Rectangle()
                        .fill(Color.orange.opacity(0.6))
                        .frame(width: geometry.size.width * 0.06)

                    // Optimal (66-75)
                    Rectangle()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: geometry.size.width * 0.09)

                    // Above target (75-85)
                    Rectangle()
                        .fill(Color.yellow.opacity(0.6))
                        .frame(width: geometry.size.width * 0.10)

                    // High (>85)
                    Rectangle()
                        .fill(Color.orange.opacity(0.6))
                        .frame(width: geometry.size.width * 0.45)
                }
                .frame(height: 24)
                .cornerRadius(6)

                // Current value indicator
                let normalizedRatio = min(max(erIrRatio, 0), 100)
                let indicatorPosition = (normalizedRatio / 100) * geometry.size.width

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 4, height: 32)
                    .shadow(radius: 2)
                    .offset(x: indicatorPosition - 2)
            }
        }
        .frame(height: 32)
    }

    private func changeIndicator(current: Double, previous: Double, isPercentage: Bool = false) -> some View {
        let diff = current - previous
        let color: Color
        let symbol: String

        if diff > 0 {
            color = .green
            symbol = "arrow.up"
        } else if diff < 0 {
            color = .red
            symbol = "arrow.down"
        } else {
            color = .secondary
            symbol = "minus"
        }

        return HStack(spacing: 2) {
            Image(systemName: symbol)
                .font(.caption2)
            if isPercentage {
                Text("\(abs(Int(diff)))%")
            } else {
                Text("\(abs(Int(diff)))")
            }
        }
        .foregroundColor(color)
    }

    // MARK: - Actions

    private func saveMeasurement() async {
        await viewModel.saveMeasurement(
            side: selectedSide,
            internalRotationStrength: internalRotationStrength,
            externalRotationStrength: externalRotationStrength,
            unit: selectedUnit,
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
class ShoulderStrengthEntryViewModel: ObservableObject {
    @Published var isSaving = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var previousMeasurement: ShoulderStrengthMeasurement?

    private let service = ShoulderHealthService.shared
    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    func loadPreviousMeasurement(side: ShoulderSide) async {
        guard let patientId = supabase.userId else { return }

        do {
            let measurements = try await service.fetchStrengthMeasurements(
                patientId: patientId,
                side: side,
                limit: 1
            )
            previousMeasurement = measurements.first
        } catch {
            logger.error("STRENGTH ENTRY", "Failed to load previous measurement: \(error)")
        }
    }

    func saveMeasurement(
        side: ShoulderSide,
        internalRotationStrength: Double,
        externalRotationStrength: Double,
        unit: StrengthUnit,
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
            let dto = CreateShoulderStrengthDTO(
                patientId: patientId,
                side: side,
                internalRotationStrength: internalRotationStrength,
                externalRotationStrength: externalRotationStrength,
                unit: unit,
                notes: notes
            )

            _ = try await service.createStrengthMeasurement(dto)
            logger.success("STRENGTH ENTRY", "Saved strength measurement successfully")
        } catch {
            logger.error("STRENGTH ENTRY", "Failed to save: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ShoulderStrengthEntry(side: .right) {
            print("Completed")
        }
    }
}
