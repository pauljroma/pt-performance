import SwiftUI

/// Row component for displaying individual exercise items within a block
struct BlockItemRow: View {
    @Binding var item: BlockItem
    let onSetComplete: (CompletedSet) -> Void
    let onQuickAdjustLoad: (Double) -> Void
    let onQuickAdjustReps: (Int) -> Void
    let onPainReport: (Int, String?) -> Void

    @State private var showSetDetail = false
    @State private var showPainReport = false
    @State private var currentSetNumber: Int = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise header
            HStack(spacing: 12) {
                // Exercise name and prescription
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.exerciseName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        // Sets x Reps
                        Text("\(item.prescribedSets) × \(item.prescribedReps)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        // Load
                        if let load = item.prescribedLoad {
                            Text("@ \(Int(load)) lbs")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        // RPE
                        if let rpe = item.prescribedRPE {
                            HStack(spacing: 2) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 10))
                                Text("RPE \(rpe)")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.orange)
                        }

                        // Tempo
                        if let tempo = item.tempo {
                            Text(tempo)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                        }
                    }
                }

                Spacer()

                // Progress indicator
                if item.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                } else {
                    Text("\(item.completedSets.count)/\(item.prescribedSets)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            // Completed sets list
            if !item.completedSets.isEmpty {
                VStack(spacing: 8) {
                    ForEach(item.completedSets) { completedSet in
                        SetRow(set: completedSet)
                    }
                }
            }

            // Quick action buttons
            if !item.isCompleted {
                HStack(spacing: 12) {
                    // Complete next set button
                    Button(action: completeNextSet) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Log Set \(item.completedSets.count + 1)")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }

                    // Quick adjustments
                    if item.prescribedLoad != nil {
                        QuickAdjustButton(
                            icon: "minus.circle.fill",
                            label: "-5",
                            color: .red
                        ) {
                            onQuickAdjustLoad(-5)
                        }

                        QuickAdjustButton(
                            icon: "plus.circle.fill",
                            label: "+5",
                            color: .green
                        ) {
                            onQuickAdjustLoad(5)
                        }
                    }

                    Spacer()

                    // Pain report button
                    if item.hasPainFlags {
                        Button(action: { showPainReport = true }) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                        }
                    } else {
                        Button(action: { showPainReport = true }) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Notes
            if let notes = item.notes, !notes.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(notes)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showPainReport) {
            PainReportSheet(onSubmit: { level, location in
                onPainReport(level, location)
                showPainReport = false
            })
        }
    }

    // MARK: - Actions

    private func completeNextSet() {
        let setNumber = item.completedSets.count + 1
        let reps = Int(item.prescribedReps) ?? 0

        let completedSet = CompletedSet(
            setNumber: setNumber,
            actualReps: reps,
            actualLoad: item.prescribedLoad,
            actualRPE: item.prescribedRPE,
            completedAt: Date()
        )

        onSetComplete(completedSet)
    }
}

// MARK: - Set Row

struct SetRow: View {
    let set: CompletedSet

    var body: some View {
        HStack(spacing: 12) {
            // Set number
            Text("Set \(set.setNumber)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)

            // Reps
            HStack(spacing: 4) {
                Text("\(set.actualReps)")
                    .font(.system(size: 13, weight: .bold))
                Text("reps")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            // Load
            if let load = set.actualLoad {
                HStack(spacing: 4) {
                    Text("@")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text("\(Int(load))")
                        .font(.system(size: 13, weight: .bold))
                    Text("lbs")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // RPE
            if let rpe = set.actualRPE {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                    Text("\(rpe)")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(rpeColor(rpe))
            }

            // Pain flag
            if set.hasPainFlag {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            }

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private func rpeColor(_ rpe: Int) -> Color {
        switch rpe {
        case 0...5: return .green
        case 6...7: return .orange
        case 8...9: return .red
        default: return .purple
        }
    }
}

// MARK: - Quick Adjust Button

struct QuickAdjustButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .cornerRadius(6)
        }
    }
}

// MARK: - Pain Report Sheet

struct PainReportSheet: View {
    let onSubmit: (Int, String?) -> Void

    @State private var painLevel: Double = 0
    @State private var painLocation: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pain Level")
                        .font(.system(size: 16, weight: .semibold))

                    HStack {
                        Text("0")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Slider(value: $painLevel, in: 0...10, step: 1)
                        Text("10")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    Text(painLevelDescription)
                        .font(.system(size: 14))
                        .foregroundColor(painLevelColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                        .background(painLevelColor.opacity(0.1))
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Location (Optional)")
                        .font(.system(size: 16, weight: .semibold))

                    TextField("e.g., Right knee, Lower back", text: $painLocation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                Spacer()

                Button(action: {
                    onSubmit(Int(painLevel), painLocation.isEmpty ? nil : painLocation)
                }) {
                    Text("Submit")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Report Pain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var painLevelDescription: String {
        switch Int(painLevel) {
        case 0: return "No Pain"
        case 1...3: return "Mild Discomfort"
        case 4...6: return "Moderate Pain"
        case 7...9: return "Severe Pain"
        case 10: return "Extreme Pain"
        default: return ""
        }
    }

    private var painLevelColor: Color {
        switch Int(painLevel) {
        case 0: return .green
        case 1...3: return .yellow
        case 4...6: return .orange
        default: return .red
        }
    }
}

// MARK: - Preview

struct BlockItemRow_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                BlockItemRow(
                    item: .constant(BlockItem(
                        id: UUID(),
                        blockId: UUID(),
                        exerciseId: UUID(),
                        exerciseName: "Back Squat",
                        orderIndex: 0,
                        prescribedSets: 5,
                        prescribedReps: "5",
                        prescribedLoad: 225,
                        prescribedRPE: 8,
                        tempo: "3-1-1-0",
                        completedSets: [
                            CompletedSet(setNumber: 1, actualReps: 5, actualLoad: 225, actualRPE: 7, completedAt: Date()),
                            CompletedSet(setNumber: 2, actualReps: 5, actualLoad: 225, actualRPE: 8, completedAt: Date())
                        ]
                    )),
                    onSetComplete: { _ in },
                    onQuickAdjustLoad: { _ in },
                    onQuickAdjustReps: { _ in },
                    onPainReport: { _, _ in }
                )
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
