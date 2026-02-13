// DARK MODE: See ModeThemeModifier.swift for central theme control
//
//  ROMInputCard.swift
//  PTPerformance
//
//  Clinical Assessments - UI card for inputting Range of Motion measurements
//  Allows clinicians to record joint mobility with normal range comparison
//

import SwiftUI

/// Card component for inputting ROM (Range of Motion) measurements
struct ROMInputCard: View {
    // MARK: - Bindings

    @Binding var measurement: ROMeasurement

    // MARK: - State

    @State private var selectedJoint: JointType = .shoulder
    @State private var selectedMovement: MovementType = .flexion
    @State private var selectedSide: Side = .right
    @State private var degrees: Int = 0
    @State private var painWithMovement: Bool = false
    @State private var isExpanded: Bool = false

    // MARK: - Callbacks

    var onSave: ((ROMeasurement) -> Void)?
    var onDelete: (() -> Void)?

    // MARK: - Initialization

    init(
        measurement: Binding<ROMeasurement>,
        onSave: ((ROMeasurement) -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self._measurement = measurement
        self.onSave = onSave
        self.onDelete = onDelete

        // Initialize state from measurement
        if let jointType = JointType(rawValue: measurement.wrappedValue.joint) {
            _selectedJoint = State(initialValue: jointType)
        }
        if let movementType = MovementType(rawValue: measurement.wrappedValue.movement) {
            _selectedMovement = State(initialValue: movementType)
        }
        _selectedSide = State(initialValue: measurement.wrappedValue.side)
        _degrees = State(initialValue: measurement.wrappedValue.degrees)
        _painWithMovement = State(initialValue: measurement.wrappedValue.painWithMovement ?? false)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection

            if isExpanded {
                Divider()
                    .padding(.horizontal)

                // Content sections
                VStack(alignment: .leading, spacing: Spacing.md) {
                    jointMovementSection
                    sideSelector
                    degreeInputSection
                    normalRangeDisplay
                    painToggle
                }
                .padding()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Action buttons when expanded
            if isExpanded {
                Divider()
                    .padding(.horizontal)

                actionButtons
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .adaptiveCardShadow(radius: 6, y: 3)
        .animation(.spring(response: 0.3), value: isExpanded)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("ROM measurement input for \(selectedJoint.displayName) \(selectedMovement.displayName)")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                // Icon with status color
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "ruler.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(statusColor)
                }

                // Title and summary
                VStack(alignment: .leading, spacing: 2) {
                    Text(measurement.displayTitle)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: Spacing.xxs) {
                        Text(measurement.formattedMeasurement)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(statusColor)

                        Text("/ \(measurement.formattedNormalRange)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if measurement.painWithMovement == true {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                        }
                    }
                }

                Spacer()

                // Expand/collapse indicator
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
            .padding()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Joint and Movement Section

    private var jointMovementSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Joint & Movement")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            HStack(spacing: Spacing.sm) {
                // Joint picker
                Menu {
                    ForEach(JointType.allCases) { joint in
                        Button {
                            selectedJoint = joint
                            // Reset movement to first available for this joint
                            if let firstMovement = joint.availableMovements.first {
                                selectedMovement = firstMovement
                            }
                            updateMeasurement()
                        } label: {
                            Label(joint.displayName, systemImage: selectedJoint == joint ? "checkmark" : "")
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedJoint.displayName)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                }
                .frame(maxWidth: .infinity)

                // Movement picker
                Menu {
                    ForEach(selectedJoint.availableMovements) { movement in
                        Button {
                            selectedMovement = movement
                            updateMeasurement()
                        } label: {
                            Label(movement.displayName, systemImage: selectedMovement == movement ? "checkmark" : "")
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedMovement.displayName)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Side Selector

    private var sideSelector: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Side")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            HStack(spacing: Spacing.xs) {
                ForEach(Side.allCases) { side in
                    Button {
                        selectedSide = side
                        updateMeasurement()
                    } label: {
                        Text(side.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(selectedSide == side ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.sm)
                                    .fill(selectedSide == side ? Color.modusCyan : Color(.tertiarySystemBackground))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(side.displayName) side")
                    .accessibilityAddTraits(selectedSide == side ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Degree Input Section

    private var degreeInputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Measured Degrees")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            HStack(spacing: Spacing.md) {
                // Stepper with display
                HStack(spacing: Spacing.sm) {
                    Button {
                        if degrees > 0 {
                            degrees -= 5
                            updateMeasurement()
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Decrease by 5 degrees")

                    VStack(spacing: 2) {
                        Text("\(degrees)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(statusColor)
                            .monospacedDigit()

                        Text("degrees")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(minWidth: 80)

                    Button {
                        if degrees < 180 {
                            degrees += 5
                            updateMeasurement()
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Increase by 5 degrees")
                }
                .frame(maxWidth: .infinity)

                // Slider for fine adjustment
                Slider(value: Binding(
                    get: { Double(degrees) },
                    set: { newValue in
                        degrees = Int(newValue)
                        updateMeasurement()
                    }
                ), in: 0...180, step: 1)
                .frame(maxWidth: .infinity)
                .tint(statusColor)
                .accessibilityLabel("Degree slider")
            }
        }
    }

    // MARK: - Normal Range Display

    private var normalRangeDisplay: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Normal Range Comparison")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 0) {
                // Progress bar showing where measurement falls
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.tertiarySystemBackground))

                        // Normal range indicator
                        let normalRange = currentNormalRange
                        let minPosition = CGFloat(normalRange.lowerBound) / 180.0 * geometry.size.width
                        let maxPosition = CGFloat(normalRange.upperBound) / 180.0 * geometry.size.width

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.3))
                            .frame(width: maxPosition - minPosition)
                            .offset(x: minPosition)

                        // Measurement marker
                        let markerPosition = CGFloat(degrees) / 180.0 * geometry.size.width
                        Circle()
                            .fill(statusColor)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 2)
                            )
                            .offset(x: markerPosition - 8)
                    }
                }
                .frame(height: 24)
            }

            // Range labels
            HStack {
                Text("0\u{00B0}")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                VStack(spacing: 2) {
                    Text("Normal: \(currentNormalRange.lowerBound)\u{00B0} - \(currentNormalRange.upperBound)\u{00B0}")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.green)

                    Text(limitationLabel)
                        .font(.caption)
                        .foregroundColor(statusColor)
                }

                Spacer()

                Text("180\u{00B0}")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Pain Toggle

    private var painToggle: some View {
        HStack {
            Image(systemName: painWithMovement ? "exclamationmark.triangle.fill" : "checkmark.circle")
                .foregroundColor(painWithMovement ? .orange : .green)

            Text("Pain with Movement")
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Toggle("", isOn: $painWithMovement)
                .labelsHidden()
                .onChange(of: painWithMovement) { _, _ in
                    updateMeasurement()
                }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm + 2)
                .fill(painWithMovement ? Color.orange.opacity(0.1) : Color(.tertiarySystemBackground))
        )
        .accessibilityLabel("Pain with movement toggle, currently \(painWithMovement ? "on" : "off")")
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: Spacing.sm) {
            // Delete button (if handler provided)
            if let onDelete = onDelete {
                Button {
                    onDelete()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm + 2))
                }
                .accessibilityLabel("Delete measurement")
            }

            // Save button
            if let onSave = onSave {
                Button {
                    onSave(measurement)
                    withAnimation {
                        isExpanded = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Save")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.modusCyan)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm + 2))
                }
                .accessibilityLabel("Save measurement")
            }
        }
        .padding()
    }

    // MARK: - Helper Views

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: CornerRadius.lg)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(statusColor.opacity(0.2), lineWidth: 1)
            )
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        measurement.statusColor
    }

    private var currentNormalRange: ClosedRange<Int> {
        let key = "\(selectedJoint.rawValue)_\(selectedMovement.rawValue)"
        return ROMNormalReference.normalRange(joint: selectedJoint.rawValue, movement: selectedMovement.rawValue) ?? 0...180
    }

    private var limitationLabel: String {
        if degrees > currentNormalRange.upperBound {
            return "Hypermobile"
        } else if degrees >= currentNormalRange.lowerBound {
            return "Within Normal Limits"
        } else {
            let deficit = currentNormalRange.lowerBound - degrees
            return "\(deficit)\u{00B0} below normal"
        }
    }

    // MARK: - Methods

    private func updateMeasurement() {
        let normalRange = currentNormalRange
        measurement = ROMeasurement(
            id: measurement.id,
            joint: selectedJoint.rawValue,
            movement: selectedMovement.rawValue,
            degrees: degrees,
            normalRangeMin: normalRange.lowerBound,
            normalRangeMax: normalRange.upperBound,
            side: selectedSide,
            measurementMethod: measurement.measurementMethod,
            painWithMovement: painWithMovement,
            endFeel: measurement.endFeel,
            notes: measurement.notes
        )
    }
}

// MARK: - Compact ROM Card

/// Compact display-only version of ROM measurement
struct ROMInputCardCompact: View {
    let measurement: ROMeasurement
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: Spacing.sm) {
                // Status indicator
                Circle()
                    .fill(measurement.statusColor)
                    .frame(width: 8, height: 8)

                // Measurement info
                VStack(alignment: .leading, spacing: 2) {
                    Text(measurement.displayTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)

                    HStack(spacing: Spacing.xxs) {
                        Text(measurement.formattedMeasurement)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(measurement.statusColor)

                        Text("Normal: \(measurement.formattedNormalRange)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Pain indicator
                if measurement.painWithMovement == true {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm + 2)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("ROM Input Card") {
    ScrollView {
        VStack(spacing: 20) {
            ROMInputCard(
                measurement: .constant(ROMeasurement.sample),
                onSave: { measurement in
                    print("Saved: \(measurement)")
                },
                onDelete: {
                    print("Deleted")
                }
            )

            ROMInputCard(
                measurement: .constant(ROMeasurement.normalSample)
            )

            ROMInputCard(
                measurement: .constant(ROMeasurement.severeLimitationSample)
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Compact ROM Card") {
    VStack(spacing: Spacing.sm) {
        ROMInputCardCompact(
            measurement: ROMeasurement.sample,
            onTap: { print("Tapped") }
        )

        ROMInputCardCompact(
            measurement: ROMeasurement.normalSample
        )

        ROMInputCardCompact(
            measurement: ROMeasurement.severeLimitationSample
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Dark Mode") {
    VStack(spacing: 20) {
        ROMInputCard(
            measurement: .constant(ROMeasurement.sample)
        )

        ROMInputCardCompact(
            measurement: ROMeasurement.sample
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
#endif
