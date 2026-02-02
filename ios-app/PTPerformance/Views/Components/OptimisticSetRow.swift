//
//  OptimisticSetRow.swift
//  PTPerformance
//
//  ACP-516: Sub-100ms Interaction Response
//  Set row with optimistic updates for instant response
//

import SwiftUI

/// A row displaying a single set with optimistic update support
/// All interactions respond in < 100ms through immediate local state updates
struct OptimisticSetRow: View {
    let setNumber: Int
    @Binding var reps: Int
    @Binding var weight: Double
    @Binding var isCompleted: Bool
    let loadUnit: String
    let targetReps: Int
    let targetWeight: Double
    let onComplete: () -> Void

    // Local state for immediate feedback
    @State private var showingRepsEditor = false
    @State private var showingWeightEditor = false
    @State private var localReps: Int = 0
    @State private var localWeight: Double = 0
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            // Set number badge
            setNumberBadge

            // Reps input
            repsButton

            // Weight input
            weightButton

            Spacer()

            // Complete button
            completeButton
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(backgroundColor)
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(setAccessibilityLabel)
        .accessibilityHint(isCompleted ? "Set completed" : "Double tap to complete this set")
        .accessibilityAction(named: "Complete Set") {
            if !isCompleted {
                onComplete()
            }
        }
        .onAppear {
            localReps = reps
            localWeight = weight
        }
    }

    // MARK: - Accessibility

    private var setAccessibilityLabel: String {
        var label = "Set \(setNumber)"
        label += ", \(reps) reps"
        if weight > 0 {
            label += ", \(Int(weight)) \(loadUnit)"
        } else {
            label += ", bodyweight"
        }
        if isCompleted {
            label += ", completed"
        }
        return label
    }

    // MARK: - Components

    private var setNumberBadge: some View {
        Text("Set \(setNumber)")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(isCompleted ? .secondary : .primary)
            .frame(width: 50, alignment: .leading)
    }

    private var repsButton: some View {
        Button {
            // Immediate haptic response
            HapticService.light()
            showingRepsEditor = true
        } label: {
            HStack(spacing: 4) {
                Text("\(reps)")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isCompleted)
        .accessibilityLabel("\(reps) reps")
        .accessibilityHint("Double tap to edit reps")
        .accessibilityAddTraits(.isButton)
        .sheet(isPresented: $showingRepsEditor) {
            RepsEditorSheet(
                reps: $reps,
                targetReps: targetReps,
                onDismiss: { showingRepsEditor = false }
            )
            .presentationDetents([.height(300)])
        }
    }

    private var weightButton: some View {
        Button {
            // Immediate haptic response
            HapticService.light()
            showingWeightEditor = true
        } label: {
            HStack(spacing: 4) {
                if weight > 0 {
                    Text(String(format: "%.0f", weight))
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(loadUnit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("BW")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isCompleted)
        .accessibilityLabel(weight > 0 ? "\(Int(weight)) \(loadUnit)" : "Bodyweight")
        .accessibilityHint("Double tap to edit weight")
        .accessibilityAddTraits(.isButton)
        .sheet(isPresented: $showingWeightEditor) {
            WeightEditorSheet(
                weight: $weight,
                loadUnit: loadUnit,
                targetWeight: targetWeight,
                onDismiss: { showingWeightEditor = false }
            )
            .presentationDetents([.height(300)])
        }
    }

    private var completeButton: some View {
        Button {
            // Start response time measurement
            let token = ResponseTimeMonitor.shared.startInteraction(.setCompletion)

            // Immediate haptic feedback (< 5ms)
            HapticService.success()

            // Immediate visual feedback (< 5ms)
            withAnimation(.easeInOut(duration: 0.15)) {
                isCompleted = true
                isAnimating = true
            }

            // Trigger completion callback (queues background sync)
            onComplete()

            // End measurement
            ResponseTimeMonitor.shared.endInteraction(token)

            // Reset animation state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                } else {
                    Circle()
                        .strokeBorder(Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 40, height: 40)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isCompleted)
        .accessibilityLabel(isCompleted ? "Set completed" : "Complete set \(setNumber)")
        .accessibilityHint(isCompleted ? "" : "Double tap to mark this set as complete")
        .accessibilityAddTraits(.isButton)
    }

    private var backgroundColor: Color {
        if isCompleted {
            return Color.green.opacity(0.05)
        }
        return Color(.systemBackground)
    }
}

// MARK: - Reps Editor Sheet

struct RepsEditorSheet: View {
    @Binding var reps: Int
    let targetReps: Int
    let onDismiss: () -> Void

    @State private var localValue: Int = 0

    private var presetValues: [Int] {
        [targetReps - 2, targetReps - 1, targetReps, targetReps + 1, targetReps + 2].filter { $0 > 0 }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Reps Completed")
                .font(.headline)

            // Quick preset buttons
            HStack(spacing: 12) {
                ForEach(presetValues, id: \.self) { value in
                    presetButton(value: value)
                }
            }

            // Stepper for fine control
            HStack {
                Button {
                    HapticService.light()
                    localValue = max(0, localValue - 1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }

                Text("\(localValue)")
                    .font(.system(size: 48, weight: .bold))
                    .frame(width: 100)

                Button {
                    HapticService.light()
                    localValue += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }

            Button("Done") {
                // Immediate update
                HapticService.medium()
                reps = localValue
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            localValue = reps
        }
    }

    private func presetButton(value: Int) -> some View {
        Button {
            HapticService.selection()
            localValue = value
            reps = value
            onDismiss()
        } label: {
            Text("\(value)")
                .font(.headline)
                .frame(width: 50, height: 50)
                .background(value == targetReps ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(value == targetReps ? .white : .primary)
                .cornerRadius(10)
        }
    }
}

// MARK: - Weight Editor Sheet

struct WeightEditorSheet: View {
    @Binding var weight: Double
    let loadUnit: String
    let targetWeight: Double
    let onDismiss: () -> Void

    @State private var localValue: Double = 0

    // Weight increments based on load unit
    private var increment: Double {
        switch loadUnit.lowercased() {
        case "kg": return 2.5
        case "lbs": return 5.0
        default: return 5.0
        }
    }

    private var presetWeights: [Double] {
        [
            targetWeight - increment * 2,
            targetWeight - increment,
            targetWeight,
            targetWeight + increment,
            targetWeight + increment * 2
        ].filter { $0 >= 0 }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Weight Used")
                .font(.headline)

            // Quick preset buttons
            HStack(spacing: 12) {
                ForEach(presetWeights, id: \.self) { value in
                    presetButton(value: value)
                }
            }

            // Stepper for fine control
            HStack {
                Button {
                    HapticService.light()
                    localValue = max(0, localValue - increment)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                }

                VStack {
                    Text(String(format: "%.0f", localValue))
                        .font(.system(size: 48, weight: .bold))
                    Text(loadUnit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 100)

                Button {
                    HapticService.light()
                    localValue += increment
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                }
            }

            HStack(spacing: 16) {
                Button("Bodyweight") {
                    HapticService.medium()
                    weight = 0
                    onDismiss()
                }
                .buttonStyle(.bordered)

                Button("Done") {
                    HapticService.medium()
                    weight = localValue
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .onAppear {
            localValue = weight
        }
    }

    private func presetButton(value: Double) -> some View {
        Button {
            HapticService.selection()
            localValue = value
            weight = value
            onDismiss()
        } label: {
            Text(String(format: "%.0f", value))
                .font(.headline)
                .frame(width: 50, height: 50)
                .background(value == targetWeight ? Color.orange : Color.gray.opacity(0.2))
                .foregroundColor(value == targetWeight ? .white : .primary)
                .cornerRadius(10)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct OptimisticSetRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 8) {
            StatefulPreviewWrapper(false) { isCompleted in
                OptimisticSetRow(
                    setNumber: 1,
                    reps: .constant(10),
                    weight: .constant(135),
                    isCompleted: isCompleted,
                    loadUnit: "lbs",
                    targetReps: 10,
                    targetWeight: 135,
                    onComplete: {}
                )
            }

            OptimisticSetRow(
                setNumber: 2,
                reps: .constant(10),
                weight: .constant(135),
                isCompleted: .constant(true),
                loadUnit: "lbs",
                targetReps: 10,
                targetWeight: 135,
                onComplete: {}
            )

            OptimisticSetRow(
                setNumber: 3,
                reps: .constant(10),
                weight: .constant(0),
                isCompleted: .constant(false),
                loadUnit: "lbs",
                targetReps: 10,
                targetWeight: 0,
                onComplete: {}
            )
        }
        .padding()
    }
}

struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        self._value = State(wrappedValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
#endif
